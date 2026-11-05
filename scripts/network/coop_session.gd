class_name CoopSession
extends Node

var game
var connection: RoomConnection
var actors: Dictionary = {}
var rules: CoopRules = preload("res://data/network/coop.tres")
var inputs := CoopInputAuthority.new()
var revives := ReviveAuthority.new()
var active: bool = false
var hosting: bool = false
var initial_size: int = 1
var lobby_map:String="courtyard"
var lobby_challenge:int=0
var room_run: String = ""
var message: String = ""
var local_name: String = ""
var sequence: int = 0
var send_clock: float = 0
var world_clock: float = 0
var ended: bool = false
var menu_open: bool = false
var original_player: Sentinel
var original_weapons: WeaponSystem
var original_mastery: RunMastery
var sent_entities: Dictionary = {}
var replicas: Dictionary = {}
var destinations: Dictionary = {}
var last_personal: Dictionary = {}
var last_health: Dictionary = {}
var received_revives: Dictionary = {}
var last_progress: String = ""
var received_personal: Dictionary = {}
var local_input_override: Dictionary = {}
var snapshot_count: int = 0
var bytes_sent: int = 0
var outbox: Array[Dictionary] = []
var team_hud
const COLORS := [Color("83c4bd"), Color("dfb969"), Color("ad8eac"), Color("dc7b5d")]

func setup(owner_game) -> void:
 game = owner_game
 connection = RoomConnection.new()
 add_child(connection)
 connection.message_received.connect(receive)
 connection.connection_failed.connect(connection_lost)
 revives.rules = rules
 original_player = game.player
 original_weapons = game.weapon_system
 original_mastery = game.mastery

func connect_room(create: bool, name_value: String, code: String = "") -> void:
 message = "Conectando..."
 connection.connect_room(create, name_value, code, game.profile.data.upgrade_ranks,game.profile.data.challenge_active,game.profile.data.gold_remainder,game.dev_tools!=null and game.dev_tools.active)
 game.ui.render("online")

func receive(packet: Dictionary) -> void:
 match packet.get("type", ""):
  "joined", "lobby":
   lobby_map=packet.get("map",lobby_map)
   lobby_challenge=clampi(int(packet.get("challenge",0)),0,5)
   game.state = "lobby"
   hosting = connection.peer_id == connection.host_id
   message = ""
   game.ui.render("lobby")
  "error":
   message = packet.get("reason", "Falha na sala.")
   game.ui.render("lobby" if not connection.code.is_empty() else "online")
  "prepare":
   game.selected_map=packet.get("map","courtyard");game.arena.apply_map(game.selected_map)
   connection.send_message({"type":"loaded"})
  "start": begin(packet)
  "left":
   remove_actor(packet.id)
   game.campaign.check_votes()
  "closed": connection_lost(packet.reason)
  "action":
   if hosting and active and actors.has(packet.from) and packet.get("data") is Dictionary:
    var data: Dictionary = packet.data
    if data.has("endless_vote"):
     if data.endless_vote is bool:game.campaign.accept_vote(packet.from,data.endless_vote)
     return
    if data.has("dev"):
     if game.dev_tools!=null and game.dev_tools.active:game.dev_tools.receive_request(packet.from,data.dev)
     return
    var accepted: bool = inputs.accept(packet.from, data, world_clock)
    if accepted and data.get("self_revive",false)==true:perform_self_revive(packet.from)
    if accepted and data.has("choice") and (data.get("generation") is int or data.get("generation") is float):
     actors[packet.from].choose(str(data.choice), int(data.get("generation", -1)))
  "delta":
   if active and not hosting: apply_delta(packet.data)
  "event":
   if active and not hosting: apply_event(packet.data)
  "events":
   if active and not hosting:
    for data in packet.data:
     if data is Dictionary: apply_event(data)

func begin(packet: Dictionary) -> void:
 game.selected_map=packet.get("map",game.selected_map)
 game.start_run()
 game.run_challenge=clampi(int(packet.get("challenge",0)),0,5)
 room_run = packet.run
 game.run_id = room_run
 initial_size = packet.players.size()
 active = true
 ended = false
 menu_open = false
 actors.clear()
 replicas.clear()
 destinations.clear()
 sent_entities.clear()
 last_personal.clear()
 last_health.clear()
 received_revives.clear()
 last_progress = ""
 outbox.clear()
 received_personal.clear()
 inputs = CoopInputAuthority.new()
 inputs.timeout = rules.input_timeout
 revives = ReviveAuthority.new()
 revives.rules = rules
 world_clock = 0
 sequence = 0
 send_clock = 0
 for index in packet.players.size():
  var metadata: Dictionary = packet.players[index]
  var actor := CoopActor.new()
  actor.setup(game, self, metadata, metadata.id == connection.peer_id)
  actor.player.position = Vector2(900 + index * 22, 630)
  actor.player.marker_color = COLORS[index]
  actors[metadata.id] = actor
 if actors.has(connection.host_id):game.run_challenge=mini(game.run_challenge,actors[connection.host_id].skills.rank("challenge"))
 game.player = actors[connection.peer_id].player
 game.weapon_system = actors[connection.peer_id].weapon_system
 game.mastery = actors[connection.peer_id].mastery
 game.ui.render("running")
 team_hud = CoopHUD.new()
 game.ui.root.add_child(team_hud)
 game.ui.root.move_child(team_hud, game.ui.menu.get_index())
 team_hud.session = self
 if game.dev_tools!=null and game.dev_tools.active:game.dev_tools.coop_ready()
 if hosting: broadcast_state(true)

func live_players() -> Array:
 var result: Array = []
 for actor in actors.values():
  if not actor.down:
   result.append(actor.player)
 return result

func nearest_player(at: Vector2):
 var best = null
 var distance: float = INF
 for player in live_players():
  var candidate: float = player.position.distance_squared_to(at)
  if candidate < distance:
   distance = candidate
   best = player
 return best

func local_action(movement: Vector2) -> Dictionary:
 if not local_input_override.is_empty(): return local_input_override.duplicate(true)
 return {"movement": Vector2.ZERO if menu_open else movement, "revive": Input.is_action_pressed("revive") and not menu_open,"self_revive":Input.is_physical_key_pressed(KEY_R) and not menu_open}

func tick(delta: float, movement: Vector2) -> void:
 if ended: return
 world_clock += delta
 var action := local_action(movement)
 if hosting:
  host_tick(delta, action)
  flush_events()
 else:
  client_tick(delta, action)
 if game.shake_time > 0:
  game.shake_time = maxf(0, game.shake_time - delta)
  game.camera.offset = Vector2(randf_range(-2,2), randf_range(-2,2)) if game.profile.data.settings.shake else Vector2.ZERO
 else: game.camera.offset = Vector2.ZERO
 if active and is_instance_valid(team_hud): team_hud.queue_redraw()

func host_tick(delta: float, local: Dictionary) -> void:
 if game.state != "running": return
 game.elapsed += delta
 game.horde_progress.tick()
 game.campaign.tick()
 game.navigation.tick(delta)
 var local_actor: CoopActor = actors[connection.peer_id]
 var actions: Dictionary = {}
 for id in actors:
  var actor: CoopActor = actors[id]
  var action: Dictionary = local if id == connection.peer_id else inputs.current(id, world_clock)
  actions[id] = action
  if actor.down and action.get("self_revive",false):perform_self_revive(id)
  if actor.down:
   actor.player.tick_visual(delta);continue
  var before: Vector2 = actor.player.position
  actor.player.movement_multiplier = game.boss_arena.slow_multiplier(before)
  if action.revive:game.chests.try_open(actor.player)
  actor.player.tick(delta, action.movement)
  actor.mastery.tick(delta, before.distance_to(actor.player.position) if action.movement.length_squared() > 0 else 0)
 game.player = local_actor.player
 game.slime_families.tick(delta)
 game.special_events.tick(delta)
 game.chests.tick(delta)
 game.director.tick(delta)
 if ended: return
 game.gold_loot.tick(delta)
 game.food_index.tick(delta)
 game.rebuild_grid()
 for enemy in game.enemies.duplicate():
  if not is_instance_valid(enemy) or not enemy.alive: continue
  var target = nearest_player(enemy.position)
  if target != null:
   game.player = target
   enemy.tick(delta)
 game.player = local_actor.player
 game.rebuild_grid()
 for id in actors:
  var actor: CoopActor = actors[id]
  if not actor.down:
   actor.weapon_system.update_combat(delta, not actions[id].revive)
 game.update_pickups(delta)
 game.enemy_projectiles.tick(delta)
 game.update_hazards(delta)
 game.specials.tick(delta)
 game.boss_arena.tick(delta)
 game.late_arena.tick(delta)
 if ended: return
 game.update_event(delta)
 for number in game.numbers:
  number.life -= delta
  number.at.y -= delta * 14
 game.numbers = game.numbers.filter(func(number): return number.life > 0)
 game.banner_time -= delta
 if game.banner_time <= 0: game.banner = ""
 var states: Dictionary = actor_states()
 var results: Array[Dictionary] = revives.update(delta, states, actions)
 for result in results:
  var target: CoopActor = actors[result.target]
  target.down = false
  target.player.down = false
  target.player.hp = result.hp
  target.player.invulnerable = result.invulnerability
  target.player.sprite.rotation = 0
  target.player.revive_remaining=.45
  publish({"type": "revive", "event": result})
 if revives.all_down(actor_states()) and not actors.values().any(func(a):return a.mastery.can_revive()): finish(false); return
 for id in actors:
  var health: Array = [actors[id].player.hp, actors[id].down, actors[id].player.invulnerable > 0]
  if last_health.get(id) != health:
   last_health[id] = health
   publish({"type": "health", "id": id, "hp": health[0], "down": health[1], "invulnerable": actors[id].player.invulnerable})
  var personal: Dictionary = actors[id].personal()
  var serialized: String = JSON.stringify(personal)
  if last_personal.get(id) != serialized:
   last_personal[id] = serialized
   if id != connection.peer_id: publish({"type": "personal", "data": personal}, id)
 var progress := {"gold": game.gold, "earned": game.earned, "kills": game.kills, "elapsed": game.elapsed, "wave": game.director.wave_number()}
 var progress_key: String = "%d:%d:%d" % [game.gold, game.earned, game.kills]
 if progress_key != last_progress:
  last_progress = progress_key
  publish({"type": "progress", "data": progress})
 game.player = local_actor.player
 game.mastery = local_actor.mastery
 game.weapon_system = local_actor.weapon_system
 game.level = local_actor.level
 game.xp = local_actor.xp
 game.xp_needed = local_actor.xp_needed
 if local_actor.down and menu_open: close_menu()
 update_camera()
 game.ui.update_hud(game.snapshot())
 game.queue_redraw()
 send_clock -= delta
 if send_clock <= 0:
  flush_events()
  broadcast_state()
  send_clock = maxf(0.05, rules.state_interval)

func actor_states() -> Dictionary:
 var result: Dictionary = {}
 for id in actors:
  var player: Sentinel = actors[id].player
  result[id] = {"position": player.position, "hp": player.hp, "max_hp": player.max_hp, "down": actors[id].down, "damage_revision": player.damage_revision}
 return result

func nearby_body(id: String) -> String:
 if not actors.has(id) or actors[id].down: return ""
 if revives.interactions.has(id): return revives.interactions[id].target
 var best: String = ""
 var distance: float = rules.revive_range
 for other in actors:
  if not actors[other].down: continue
  var candidate: float = actors[id].player.position.distance_to(actors[other].player.position)
  if candidate < distance or (is_equal_approx(candidate, distance) and (best.is_empty() or str(other) < best)):
   distance = candidate
   best = other
 return best

func mark_down(id: String) -> void:
 if not hosting or not actors.has(id) or actors[id].down: return
 actors[id].down = true
 actors[id].player.down = true
 actors[id].player.hp = 0
 actors[id].player.clear_status()
 actors[id].player.velocity = Vector2.ZERO
 actors[id].player.sprite.rotation = 0
 actors[id].player.visual_clock=0
 actors[id].player.tick_visual(0)
 actors[id].weapon_system.ground.reset();actors[id].weapon_system.arsenal.reset()
 actors[id].weapon_system.beams.clear()
 actors[id].weapon_system.lightning_fx.clear()
 actors[id].weapon_system.projectiles.clear()
 actors[id].weapon_system.slashes.clear()
 actors[id].weapon_system.orbit_positions.clear()
 actors[id].weapon_system.queue_redraw()
 revives.interactions.erase(id)

func share_xp(amount: float) -> void:
 if game.dev_tools!=null and game.dev_tools.active:return
 for actor in actors.values(): actor.award_xp(amount)

func on_gold(amount: int,bonus_eligible:bool=true) -> void:
 if not bonus_eligible:return
 for actor in actors.values():
  actor.mastery.on_gold(amount)

func open_upgrades() -> void:
 if not active or ended or actors[connection.peer_id].down: return
 var offers: Array = actors[connection.peer_id].offers if hosting else received_personal.get("offers", [])
 if offers.is_empty(): return
 menu_open = true
 game.ui.render("upgrading", {"offers": offers})

func choose(id: String) -> void:
 if not active or ended: return
 if hosting:
  actors[connection.peer_id].choose(id, actors[connection.peer_id].generation)
 else:
  sequence += 1
  connection.send_message({"type": "action", "data": {"sequence": sequence, "movement": [0,0], "revive": false, "choice": id, "generation": received_personal.get("generation", -1)}})
 close_menu()

func close_menu() -> void:
 menu_open = false
 game.ui.render("running")

func publish(data: Dictionary, target: String = "") -> void:
 outbox.append({"data": CoopWire.encode(data), "to": target})
 if ended: flush_events()

func flush_events() -> void:
 if outbox.is_empty(): return
 var batch: Array[Dictionary] = []
 var byte_count: int = 32
 for entry in outbox:
  var entry_bytes: int = JSON.stringify(entry).to_utf8_buffer().size() + 1
  if not batch.is_empty() and byte_count + entry_bytes > 61440: break
  batch.append(entry)
  byte_count += entry_bytes
 if connection.send_message({"type": "events", "data": batch}): outbox = outbox.slice(batch.size())

func finish(won: bool) -> void:
 won=won or game.campaign.cleared
 if game.dev_tools!=null and game.dev_tools.active:
  if hosting:game.dev_tools.complete(won)
  return
 if ended: return
 var result := {"gold_fractions":{},"gold_bonuses":{},"won": won, "elapsed": game.elapsed, "kills": game.kills, "gold": game.gold, "earned": game.earned, "wave": game.director.wave_number()}
 for id in actors:
  result.gold_bonuses[id]=actors[id].mastery.gold_bonus;result.gold_fractions[id]=actors[id].mastery.gold_fraction
 if hosting: publish({"type": "end", "data": result})
 if hosting: flush_events()
 settle(result)

func settle(result: Dictionary) -> void:
 if ended: return
 result=result.duplicate(true);result.won=bool(result.get("won",false)) or game.campaign.cleared
 game.chests.reset();game.special_events.stop()
 ended = true
 if is_instance_valid(team_hud): team_hud.hide()
 game.state = "result"
 for actor in actors.values():
  actor.player.clear_status();actor.weapon_system.ground.reset();actor.weapon_system.arsenal.reset()
 game.slime_families.reset()
 game.run_settled = true
 game.boss_arena.stop_combat()
 game.late_arena.reset()
 game.camera.position = Vector2.ZERO
 result=result.duplicate(true)
 var personal_bonus:int=actors[connection.peer_id].mastery.gold_bonus if hosting else int(received_personal.get("gold_bonus",0))
 result.gold+=int(result.get("gold_bonuses",{}).get(connection.peer_id,personal_bonus))
 var paid: int = 0
 if game.persistence_enabled:
  paid = game.profile.reward(float(result.elapsed), int(result.kills), bool(result.won), int(result.earned), int(result.gold), room_run, int(result.wave),float(result.get("gold_fractions",{}).get(connection.peer_id,actors[connection.peer_id].mastery.gold_fraction if hosting else received_personal.get("gold_remainder",0))))
 game.ui.render("result", {"won": result.won, "elapsed": result.elapsed, "kills": result.kills, "gold": result.gold, "earned": paid, "total_gold": game.profile.data.gold, "wave": result.wave, "level": game.level})
 game.sound.play_cue("victory" if result.won else "defeat")

func remove_actor(id: String) -> void:
 if not actors.has(id): return
 var actor: CoopActor = actors[id]
 actors.erase(id)
 inputs.remove(id)
 revives.interactions.erase(id)
 actor.player.queue_free()
 actor.weapon_system.queue_free()
 actor.release()
 game.announce("%s desconectou." % actor.display_name, 3)

func connection_lost(reason: String) -> void:
 if active and not ended:
  settle({"won": false, "elapsed": game.elapsed, "kills": game.kills, "gold": game.gold, "earned": game.earned, "wave": game.director.wave_number()})
 leave()
 message = reason
 game.state = "online"
 game.ui.render("online")
 if game.dev_tools!=null and game.dev_tools.active:game.dev_tools.end_test()

func leave() -> void:
 if active and not ended: finish(false)
 active = false
 connection.close()
 if is_instance_valid(team_hud): team_hud.queue_free()
 for actor in actors.values():
  if actor.player != original_player: actor.player.queue_free()
  if actor.weapon_system != original_weapons: actor.weapon_system.queue_free()
  actor.release()
 actors.clear()
 replicas.clear()
 destinations.clear()
 game.player = original_player
 game.weapon_system = original_weapons
 game.mastery = original_mastery
 original_player.game = game
 original_player.display_name = ""
 original_player.marker_color = COLORS[0]
 original_player.down = false
 original_player.sprite.rotation = 0
 original_weapons.game = game
 original_mastery.game = game
 game.camera.position = Vector2.ZERO
 game.clear_run()
 game.show_title()

func _exit_tree() -> void:
 for actor in actors.values(): actor.release()

func update_camera() -> void:
 var local: CoopActor = actors[connection.peer_id]
 if local.down:
  var target = nearest_player(local.player.position)
  if target != null: game.camera.global_position = target.position
 else: game.camera.position = Vector2.ZERO

func broadcast_state(force: bool = false) -> void:
 if connection.socket != null and connection.socket.get_current_outbound_buffered_amount() > 262144: return
 var entities: Dictionary = {}
 var visible_enemies: Array = game.enemies.duplicate()
 for death in game.boss_arena.deaths+game.late_arena.deaths:
  if is_instance_valid(death.boss) and not visible_enemies.has(death.boss): visible_enemies.append(death.boss)
 for enemy in visible_enemies:
  if not is_instance_valid(enemy): continue
  entities["e" + str(enemy.serial)] = {"kind": "enemy", "species": enemy.data.id, "position": enemy.position, "hp": enemy.hp, "max_hp": enemy.max_hp, "frame": enemy.sprite.frame, "flip": enemy.sprite.flip_h, "state": enemy.state, "charge_direction": enemy.charge_direction, "targetable": enemy.targetable, "visible": enemy.sprite.visible, "sprite_position": enemy.sprite.position, "alpha": enemy.sprite.modulate.a,"meals":enemy.meals if enemy is Devourer else 0,"enemy_damage":enemy.data.damage,"body_radius":enemy.radius,"body_scale":enemy.sprite.scale.x}
  entities["e" + str(enemy.serial)].merge({"locked_target":enemy.locked_target if enemy is LateBoss else Vector2.ZERO,"attack_time":enemy.attack_time,"summons_alive":game.boss_arena.summons.size()+game.late_arena.chain.count(enemy.serial) if enemy is HordeBoss else 0,"dev_frozen":enemy.dev_frozen if enemy is HordeBoss else false,"dev_repeat":enemy.dev_repeat if enemy is HordeBoss else "","form":enemy.form if enemy is HordeBoss else 1,"frozen":enemy.frozen_remaining,"slow":enemy.slow_remaining,"state_time": enemy.state_time, "elite": enemy.elite, "attack_name": enemy.attack_name if enemy is HordeBoss else "", "phase": enemy.phase if enemy is HordeBoss else 1,"ambush_at":enemy.ambush_at if enemy is SpecialEnemy else Vector2.ZERO})
 for id in actors:
  var actor: CoopActor = actors[id]
  entities[id] = {"kind": "player", "position": actor.player.position, "hp": actor.player.hp, "max_hp": actor.player.max_hp, "speed": actor.player.speed, "down": actor.down, "frame": actor.player.sprite.frame, "flip": actor.player.sprite.flip_h, "invulnerable": actor.player.invulnerable,"poison":actor.player.poison_remaining,"root":actor.player.root_remaining}
 for coin in game.gold_loot.coins:
  entities["c" + str(coin.id)] = {"kind": "coin", "at": coin.at, "born": snappedf(game.elapsed-coin.age,.01), "value": coin.value, "attracted": coin.attracted}
 for item in game.pickups:
  entities["x" + str(item.get("id", 0))] = {"kind": "xp", "at": item.at, "xp": item.xp}
 var changes: Array = []
 var removals: Array = []
 var next_entities: Dictionary = {}
 for id in entities:
  # Compare native values, then encode the completed packet once.
  var wire: Dictionary = entities[id]
  var changed := {"id": id}
  for key in wire:
   if force or not sent_entities.has(id) or sent_entities[id].get(key) != wire[key]: changed[key] = wire[key]
  if changed.size() > 1: changes.append(changed)
  next_entities[id] = wire
 for id in sent_entities.keys():
  if not entities.has(id): removals.append(id)
 var weapon_fx: Dictionary = {}
 for id in actors:
  var weapons: WeaponSystem = actors[id].weapon_system
  var shots: Array = []
  for shot in weapons.projectiles: shots.append({"position": shot.position, "velocity": shot.velocity})
  weapon_fx[id] = {"projectiles": shots, "slashes": weapons.slashes, "orbit_positions": weapons.orbit_positions,"lightning_fx":weapons.lightning_fx,"beams":weapons.beams,"pools":weapons.ground.pools,"arsenal_shots":weapons.arsenal.shots,"arsenal_zones":weapons.arsenal.zones,"blade_points":weapons.arsenal.blade_points}
 var data := {"reward_chest":game.chests.chest,"event_status":{"active":game.special_events.active,"age":game.special_events.age,"pending":game.special_events.pending.size()},"campaign_cleared":game.campaign.cleared,"endless":game.campaign.endless,"final_jobs":game.late_arena.patterns.jobs,"final_shots":game.late_arena.patterns.shots,"final_marks":game.late_arena.patterns.marks,"hordes_completed":game.horde_progress.completed,"chain_seeds":game.late_arena.seed_pending,"chain_stats":game.late_arena.chain.snapshot(),"late_areas":game.late_arena.areas,"late_shots":game.late_arena.shots,"changes": changes, "removals": removals, "elapsed": game.elapsed, "gold": game.gold, "kills": game.kills, "earned": game.earned, "wave": game.director.wave_number(), "pressure": "TESTE DEV" if game.dev_tools!=null and game.dev_tools.active else game.director.pressure(), "banner": game.banner, "arrows": game.enemy_projectiles.arrows, "hazards": game.hazards, "areas": game.boss_arena.areas, "summons": game.boss_arena.pending_summons, "swings": game.boss_arena.swings, "portal_age": game.boss_arena.portal_age, "stage": game.boss_arena.stage, "weapons": weapon_fx, "revives": revives.interactions, "event_claimed": game.event_claimed, "event_progress": game.event_progress, "numbers": game.numbers,"split_pending":game.slime_families.pending,"special_marks":game.specials.marks,"special_areas":game.specials.areas,"special_bolts":game.specials.bolts}
 var packet := {"type": "delta", "data": CoopWire.encode(data)}
 bytes_sent += JSON.stringify(packet).length()
 snapshot_count += 1
 if connection.send_message(packet): sent_entities = next_entities

func apply_event(data: Dictionary) -> void:
 if str(data.get("type","")).begins_with("dev_"):
  if game.dev_tools!=null and game.dev_tools.active:game.dev_tools.receive_event(data)
  return
 match data.get("type", ""):
  "reward_chest":game.chests.show_receipt(data.data)
  "campaign_won":game.campaign.remember_clear()
  "endless_offer":game.campaign.remember_clear();game.campaign.deciding=true;game.state="endless_choice";game.ui.render("endless_choice")
  "endless_continue":game.campaign.deciding=false;game.campaign.endless=true;game.state="running";game.ui.render("running")
  "gold_pickup":
   game.sound.play_cue("gold")
   if game.gold_loot.feedback.size() < 12: game.gold_loot.feedback.append({"at": CoopWire.vector(data.at) - Vector2(0,26), "life": 0.55, "amount": int(data.amount)})
  "personal":
   received_personal = data.data
   var actor: CoopActor = actors[connection.peer_id]
   actor.level = int(data.data.level)
   actor.xp = float(data.data.xp)
   actor.xp_needed = int(data.data.xp_needed)
   actor.weapon_system.levels = data.data.levels
   actor.weapon_system.passives = data.data.passives
   for key in data.data.stats:actor.player.set(key,data.data.stats[key])
   game.level = actor.level
   game.xp = actor.xp
   game.xp_needed = actor.xp_needed
  "progress":
   game.gold = int(data.data.gold)
   game.earned = int(data.data.earned)
   game.kills = int(data.data.kills)
  "health":
   if actors.has(data.id):
    if data.id == connection.peer_id and data.hp < actors[data.id].player.hp:
     game.sound.play_cue("hurt")
     game.shake_time = 0.16
    actors[data.id].player.hurt_remaining=.2 if data.hp<actors[data.id].player.hp else actors[data.id].player.hurt_remaining
    actors[data.id].player.hp = data.hp
    actors[data.id].down = data.down
    actors[data.id].player.down = data.down
    actors[data.id].player.invulnerable = data.invulnerable
    if data.id == connection.peer_id and data.down and menu_open: close_menu()
  "revive":
   var event: Dictionary = data.event
   var event_key: int = int(event.id)
   if received_revives.has(event_key): return
   received_revives[event_key] = true
   if actors.has(event.target):
    actors[event.target].down = false
    actors[event.target].player.down = false
    actors[event.target].player.revive_remaining = .45
    actors[event.target].player.hp = event.hp
    actors[event.target].player.invulnerable = event.invulnerability
  "end": settle(data.data)

func apply_delta(raw: Dictionary) -> void:
 if ended: return
 var data: Dictionary = CoopWire.decode(raw)
 for update in data.changes:
  var id: String = update.id
  if not replicas.has(id): replicas[id] = {}
  replicas[id].merge(update, true)
 for id in data.removals:
  if replicas.has(id) and replicas[id].get("node") != null:
   var node = replicas[id].node
   game.enemies.erase(node)
   node.queue_free()
  replicas.erase(id)
  destinations.erase(id)
 game.gold_loot.coins.clear()
 game.pickups.clear()
 for id in replicas:
  var state: Dictionary = replicas[id]
  match state.get("kind", ""):
   "player":
    if not actors.has(id): continue
    var actor: CoopActor = actors[id]
    destinations[id] = state.position
    actor.player.hp = state.hp
    actor.player.max_hp = state.max_hp
    actor.player.poison_remaining = state.poison
    actor.player.root_remaining = state.root
    actor.player.speed = state.speed
    actor.down = state.down
    actor.player.down = state.down
    actor.player.sprite.frame = int(state.frame)
    if int(state.frame) in range(10,16):actor.player.swing_remaining=(16-int(state.frame))*.05
    if int(state.frame) in [8,9]:actor.player.anticipation_remaining=.12 if int(state.frame)==8 else .06
    actor.player.sprite.flip_h = state.flip
    actor.player.invulnerable = state.invulnerable
    actor.player.sprite.rotation = 0
    actor.player.queue_redraw()
   "enemy":
    var enemy = state.get("node")
    if not is_instance_valid(enemy):
     enemy = game.spawn_enemy(state.species, state.position, state.elite)
     state.node = enemy
    destinations[id] = state.position
    enemy.hp = state.hp
    enemy.max_hp = state.max_hp
    enemy.data.damage=state.enemy_damage
    if enemy is Devourer:enemy.meals=int(state.meals)
    enemy.radius=float(state.get("body_radius",enemy.radius));enemy.sprite.scale=Vector2.ONE*float(state.get("body_scale",1))
    enemy.state = state.state
    if enemy is LateBoss:enemy.locked_target=state.get("locked_target",Vector2.ZERO)
    if enemy is SpecialEnemy:enemy.ambush_at=state.ambush_at
    enemy.state_time = state.state_time
    enemy.attack_time=state.attack_time
    enemy.frozen_remaining=state.frozen
    enemy.slow_remaining=state.slow
    enemy.charge_direction = state.charge_direction
    enemy.targetable = state.targetable
    enemy.sprite.frame = int(state.frame)
    enemy.sprite.flip_h = state.flip
    enemy.sprite.visible = state.visible
    enemy.sprite.position = state.sprite_position
    enemy.sprite.modulate.a = state.alpha
    if enemy is HordeBoss:
     enemy.dev_summons_alive=int(state.get("summons_alive",0))
     enemy.dev_frozen=state.get("dev_frozen",false);enemy.dev_repeat=state.get("dev_repeat","")
     enemy.combat_enabled = state.targetable
     enemy.attack_name = state.attack_name
     enemy.phase = int(state.phase)
     enemy.form = int(state.form)
     enemy.apply_visual_form()
    enemy.queue_redraw()
   "coin": game.gold_loot.coins.append({"at": state.at, "age": maxf(0,data.elapsed-state.born), "value": state.value})
   "xp": game.pickups.append({"at": state.at, "xp": state.xp})
 game.special_events.active=str(data.get("event_status",{}).get("active",""));game.special_events.age=float(data.get("event_status",{}).get("age",0));game.special_events.remote_pending=int(data.get("event_status",{}).get("pending",0))
 game.special_events.members.clear()
 for e in game.enemies:
  if e.data.id in ["slime_king","event_blue","event_small"]:game.special_events.members.append(weakref(e))
 game.chests.chest=data.get("reward_chest",{});game.chests.queue_redraw()
 game.campaign.cleared=data.get("campaign_cleared",false);game.campaign.endless=data.get("endless",false)
 game.elapsed = data.elapsed
 game.horde_progress.completed=int(data.get("hordes_completed",0))
 game.late_arena.patterns.jobs.assign(data.get("final_jobs",[]));game.late_arena.patterns.shots.assign(data.get("final_shots",[]));game.late_arena.patterns.marks.assign(data.get("final_marks",[]))
 game.late_arena.seed_pending.assign(data.get("chain_seeds",[]))
 game.late_arena.areas.assign(data.get("late_areas",[]));game.late_arena.shots.assign(data.get("late_shots",[]))
 game.gold = int(data.gold)
 game.kills = int(data.kills)
 game.earned = int(data.earned)
 game.director.wave_index = int(data.wave) - 1
 game.banner = data.banner
 game.event_claimed = data.event_claimed
 game.event_progress = data.event_progress
 game.numbers.assign(data.numbers)
 game.slime_families.pending.assign(data.split_pending)
 game.slime_families.queue_redraw()
 game.specials.marks.assign(data.special_marks)
 game.specials.areas.assign(data.special_areas)
 game.specials.bolts.assign(data.special_bolts)
 game.specials.queue_redraw()
 game.enemy_projectiles.arrows.assign(data.arrows)
 game.hazards.assign(data.hazards)
 game.boss_arena.areas.assign(data.areas)
 game.boss_arena.pending_summons.assign(data.summons)
 game.boss_arena.swings.assign(data.swings)
 game.boss_arena.stage = data.stage
 game.boss_arena.portal_age = data.portal_age
 revives.interactions = data.revives
 for id in data.weapons:
  if not actors.has(id): continue
  var weapons: WeaponSystem = actors[id].weapon_system
  weapons.arsenal.shots.assign(data.weapons[id].arsenal_shots)
  weapons.arsenal.zones.assign(data.weapons[id].arsenal_zones)
  weapons.arsenal.blade_points.assign(data.weapons[id].blade_points)
  weapons.arsenal.queue_redraw()
  weapons.ground.pools.assign(data.weapons[id].pools)
  weapons.ground.queue_redraw()
  weapons.beams.assign(data.weapons[id].beams)
  weapons.lightning_fx.assign(data.weapons[id].lightning_fx)
  weapons.projectiles.assign(data.weapons[id].projectiles)
  weapons.slashes.assign(data.weapons[id].slashes)
  weapons.orbit_positions.assign(data.weapons[id].orbit_positions)
  weapons.queue_redraw()
 game.gold_loot.queue_redraw()
 game.enemy_projectiles.queue_redraw()
 game.boss_arena.queue_redraw()
 game.queue_redraw()
 var hud: Dictionary = game.snapshot()
 hud.pressure = data.pressure
 game.ui.update_hud(hud)

func client_tick(delta: float, action: Dictionary) -> void:
 if game.state=="running":game.chests.visual_tick(delta)
 send_clock -= delta
 if send_clock <= 0:
  sequence += 1
  connection.send_message({"type": "action", "data": {"sequence": sequence, "movement": CoopWire.encode(action.movement), "revive": action.revive,"self_revive":action.get("self_revive",false)}})
  send_clock = maxf(0.025, rules.input_interval)
 var local: CoopActor = actors[connection.peer_id]
 if not local.down:
  local.player.movement_multiplier = game.boss_arena.slow_multiplier(local.player.position)
  var movement:Vector2=action.movement if local.player.root_remaining<=0 else Vector2.ZERO
  local.player.tick(delta, movement)
  if destinations.has(local.id): destinations[local.id] += movement.limit_length() * local.player.speed * local.player.movement_multiplier * delta
 for id in destinations:
  var node = actors[id].player if actors.has(id) else replicas[id].get("node")
  if not is_instance_valid(node): continue
  node.position = node.position.lerp(destinations[id], minf(1, delta * rules.interpolation_rate))
  if actors.has(id) and id!=connection.peer_id and node.position.distance_to(destinations[id])<.25 and node.sprite.frame in range(16,24):node.sprite.frame=0
 for actor in actors.values():
  actor.player.sprite.modulate.a = 0.55 if actor.player.invulnerable > 0 and int(world_clock * 10) % 2 == 0 else 1.0
 for arrow in game.enemy_projectiles.arrows: arrow.at += arrow.velocity * delta
 game.late_arena.visual_tick(delta)
 for area in game.boss_arena.areas:
  area.age += delta
  if area.kind=="ring":area.at=area.ring_center+Vector2.from_angle(area.ring_angle)*maxf(0,game.boss_balance.ring_radius-maxf(0,area.age-area.warning)*game.boss_balance.ring_speed)
 for batch in game.slime_families.pending:batch.age+=delta
 game.slime_families.queue_redraw()
 for mark in game.specials.marks:mark.age+=delta
 for area in game.specials.areas:area.age+=delta
 for bolt in game.specials.bolts:bolt.at+=bolt.velocity*delta
 game.specials.queue_redraw()
 for hazard in game.hazards: hazard.age += delta
 for mark in game.boss_arena.pending_summons: mark.age += delta
 if game.boss_arena.stage == "portal": game.boss_arena.portal_age += delta
 for coin in game.gold_loot.coins: coin.age += delta
 for effect in game.gold_loot.feedback:
  effect.life -= delta
  effect.at.y -= delta * 13
 game.gold_loot.feedback = game.gold_loot.feedback.filter(func(effect): return effect.life > 0)
 for actor in actors.values():
  for shot in actor.weapon_system.arsenal.shots:
   shot.age+=delta
   var speed:float=float(shot.get("speed_factor",1));var travel:float=shot.age*speed
   if shot.kind=="axe":shot.at=shot.origin+shot.direction*170*travel+Vector2(0,180*travel*(travel-shot.flight))
   else:shot.at+=shot.direction*250*delta*speed if shot.leg==0 else (actor.player.position-shot.at).normalized()*300*delta*speed
  for zone in actor.weapon_system.arsenal.zones:zone.age+=delta
  actor.weapon_system.arsenal.queue_redraw()
  for beam in actor.weapon_system.beams:beam.life-=delta
  actor.weapon_system.beams=actor.weapon_system.beams.filter(func(b):return b.life>0)
  for fx in actor.weapon_system.lightning_fx:fx.life-=delta
  actor.weapon_system.lightning_fx=actor.weapon_system.lightning_fx.filter(func(f):return f.life>0)
  for pool in actor.weapon_system.ground.pools:pool.age+=delta
  actor.weapon_system.ground.pools=actor.weapon_system.ground.pools.filter(func(p):return p.age<p.flight+p.duration)
  actor.weapon_system.ground.queue_redraw()
  for shot in actor.weapon_system.projectiles: shot.position += shot.velocity * delta
  for slash in actor.weapon_system.slashes: slash.remaining = maxf(0, slash.remaining - delta)
  actor.weapon_system.queue_redraw()
 game.enemy_projectiles.queue_redraw()
 game.boss_arena.queue_redraw()
 game.gold_loot.queue_redraw()
 update_camera()

func perform_self_revive(id:String)->bool:
 if not hosting or ended or not actors.has(id):return false
 var actor:CoopActor=actors[id]
 if not actor.down or not actor.mastery.use_revive():return false
 actor.down=false
 for rescuer in revives.interactions.keys():
  if revives.interactions[rescuer].target==id:revives.interactions.erase(rescuer)
 revives.sequence+=1
 publish({"type":"revive","event":{"id":revives.sequence,"target":id,"rescuer":id,"hp":actor.player.hp,"invulnerability":2}})
 return true
func request_self_revive():
 if hosting:perform_self_revive(connection.peer_id)
 else:
  sequence+=1;connection.send_message({"type":"action","data":{"sequence":sequence,"movement":[0,0],"revive":false,"self_revive":true}})
func local_gold_bonus()->int:
 if not active or not actors.has(connection.peer_id):return 0
 return actors[connection.peer_id].mastery.gold_bonus if hosting else int(received_personal.get("gold_bonus",0))
