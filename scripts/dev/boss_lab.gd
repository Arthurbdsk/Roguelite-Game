extends CanvasLayer
var show_spawn_sectors:bool=false
var game
var active:bool=false
var running_test:bool=false
var survival_mode:bool=false
var original_profile:GameProfile
var original_persistence:bool
var original_time:float=1
var panel:PanelContainer
var badge:Label
const ENCOUNTERS:Dictionary={"executioner":["Carrasco | 5 min",300,"5"],"demon1":["Demônio | Fase 1",600,"10"],"demon2":["Demônio | Fase 2",600,"10"],"guardian":["Guardião | 15 min",900,"15"],"horror":["Abominação | Forma 1",1200,"20"],"true":["True Form",1200,"20"]}
var presets:Dictionary={}
var encounter:String="executioner"
var map_id:String="courtyard"
var participants:int=1
var applied_participants:int=1
var hordes:bool=false
var build:Dictionary={}
var frozen:bool=false
var repeat_attack:String=""
var status:String=""
var show_colliders:bool=false
var collider_overlay:Node2D
var online_builds:Dictionary={}
var network_revision:int=0
var accepted_revisions:Dictionary={}
var applying_network:bool=false
func setup(owner_game):
 game=owner_game;layer=60
 collider_overlay=load("res://scripts/dev/collision_overlay.gd").new();collider_overlay.lab=self;game.add_child(collider_overlay)
 presets=JSON.parse_string(FileAccess.get_file_as_string("res://data/dev/presets.json"));load_preset("5")
 badge=Label.new();badge.text="MODO DEV";badge.position=Vector2(276,30);badge.add_theme_font_override("font",GameFonts.interface_font());badge.add_theme_font_size_override("font_size",12);badge.add_theme_color_override("font_color",Color("ffd278"));add_child(badge);badge.hide()
 panel=preload("res://scripts/dev/boss_panel.gd").new();panel.theme=game.ui.ui_theme;add_child(panel);panel.setup(self);panel.hide()

func enter()->bool:
 if active:return true
 if game.coop.active or game.state not in ["title","hub"]:return false
 original_profile=game.profile;original_persistence=game.persistence_enabled;original_time=Engine.time_scale
 var temporary=load("res://scripts/dev/temporary_profile.gd").new()
 temporary.data=original_profile.data.duplicate(true);game.profile=temporary;game.persistence_enabled=false
 active=true;badge.show();apply_build();return true
func toggle():
 if not enter():return
 panel.visible=not panel.visible
 if panel.visible:panel.rebuild()
func end_test():
 if not active:return
 clear_player_effects()
 if game.coop.active:
  if is_host():broadcast({"type":"dev_exit"})
  game.coop.ended=true;game.coop.leave()
 game.player.dev_invulnerable=false;game.weapon_system.attacks_enabled=true;game.clear_run();game.profile=original_profile;game.persistence_enabled=original_persistence;game.dev_boss_test=false
 game.player.game=game;game.weapon_system.game=game;game.mastery.setup(game);game.mastery.begin();Engine.time_scale=original_time
 active=false;running_test=false;panel.hide();badge.hide();game.apply_settings();game.show_title()
func _exit_tree():
 if active:Engine.time_scale=original_time

func is_host()->bool:
 if game.coop.active:return game.coop.hosting
 if not game.coop.connection.code.is_empty():return game.coop.connection.peer_id==game.coop.connection.host_id
 return true
func load_preset(id:String):
 if not presets.has(id):return
 build=presets[id].duplicate(true);build.merge({"permanent":false,"invulnerable":true,"attacks":true})
func validated_build(raw:Dictionary)->Dictionary:
 if not raw.get("weapons") is Dictionary or not raw.get("passives") is Dictionary:return {}
 if raw.weapons.size()>6 or raw.passives.size()>4:return {}
 var result:Dictionary={"level":clampi(int(raw.get("level",1)),1,999),"permanent":raw.get("permanent",false)==true,"invulnerable":raw.get("invulnerable",true)==true,"attacks":raw.get("attacks",true)==true,"weapons":{},"passives":{}}
 for category in ["weapons","passives"]:
  var definitions:Dictionary=game.weapon_system.weapon_data if category=="weapons" else game.weapon_system.passive_data
  for id in raw[category]:
   if category=="weapons" and id=="blades":continue
   if not definitions.has(id) or not (raw[category][id] is float or raw[category][id] is int):return {}
   result[category][id]=clampi(int(raw[category][id]),1,8)
 return result
func prepare_player(config:Dictionary,actor=null):
 var owner=game if actor==null else actor
 owner.weapon_system.reset();owner.mastery.begin(config.permanent)
 owner.weapon_system.levels=config.weapons.duplicate(true)
 for id in config.passives:
  for rank_index in int(config.passives[id]):owner.weapon_system.apply_upgrade(id)
 owner.player.dev_invulnerable=config.invulnerable;owner.player.invulnerable=0;owner.player.clear_status();owner.player.down=false;owner.player.hp=owner.player.max_hp
 owner.weapon_system.attacks_enabled=config.attacks
 owner.level=int(config.level);owner.xp=0;owner.xp_needed=6+(owner.level-1)*5
 if actor!=null:
  actor.down=false;actor.offers.clear()
  if actor.id==game.coop.connection.peer_id:game.level=actor.level;game.xp=actor.xp;game.xp_needed=actor.xp_needed
func valid_point(origin:Vector2,radius:float)->Vector2:
 for i in 160:
  var point:Vector2=origin if i==0 else origin+Vector2.from_angle(i*2.4)*(20+int(i/8)*16)
  if game.arena.safe_position(point,radius) and game.navigation.reachable(point,radius):return point
 return Vector2.INF
func start_encounter()->bool:
 survival_mode=false
 if not active and not enter():return false
 if game.state=="lobby":status="Inicie a sala antes de escolher o encontro.";return false
 if not is_host() or not ENCOUNTERS.has(encounter) or map_id not in ["courtyard","library","fields"]:return false
 var checked:Dictionary=validated_build(build)
 if checked.is_empty():status="Build inválida: máximo de seis armas e quatro passivas.";return false
 build=checked;applied_participants=participants;frozen=false;repeat_attack=""
 if game.coop.active:
  online_builds[game.coop.connection.peer_id]=build.duplicate(true)
  for id in game.coop.actors:
   if not online_builds.has(id):status="Aguarde a configuração de todos os jogadores.";return false
 game.selected_map=map_id
 if not game.coop.active:game.start_run()
 else:game.clear_run();game.arena.apply_map(map_id);game.coop.sent_entities.clear();game.coop.ended=false
 game.persistence_enabled=false;game.dev_boss_test=true;game.dev_boss_kind=encounter;game.run_challenge=0
 if build.permanent:
  var requested:int=game.coop.lobby_challenge if game.coop.active else int(game.profile.data.challenge_active)
  game.run_challenge=clampi(requested,0,game.skills.rank("challenge"))
 game.elapsed=float(ENCOUNTERS[encounter][1]);game.state="running"
 game.director.elite_spawned=true;game.director.wave_index=int(game.elapsed/60)-3;game.director.queue.clear()
 game.director.phase="preparing" if hordes else "complete";game.director.preparation_left=2.5
 if game.coop.active:
  var index:int=0
  for id in game.coop.actors:
   var actor=game.coop.actors[id];prepare_player(online_builds.get(id,build),actor)
   actor.player.position=valid_point(Vector2(700+index*22,630),10);index+=1
 else:prepare_player(build);game.player.position=valid_point(Vector2(700,630),10)
 if encounter in ["demon1","demon2"]:
  game.boss_arena.begin_portal();game.boss_arena.tick(game.boss_balance.portal_duration()+.01)
 elif encounter=="executioner":
  var at:Vector2=valid_point(Vector2(920,630),32)
  if at==Vector2.INF:return false
  game.spawn_enemy("executioner",at)
 else:
  if not game.late_arena.begin_encounter("guardian" if encounter=="guardian" else "horror"):return false
  game.late_arena.tick(1.3)
 if encounter in ["demon2","true"]:game.boss.take_damage(game.boss.hp/maxf(.01,1-game.horde_progress.resistance())+.01);game.boss.tick(1.7)
 game.ui.render("running");game.ui.update_hud(game.snapshot());running_test=true;panel.rebuild();status="Encontro iniciado. Sem progresso permanente."
 if game.coop.active:
  broadcast({"type":"dev_start","data":{"encounter":encounter,"map":map_id,"participants":participants,"hordes":hordes,"time":Engine.time_scale,"challenge":game.run_challenge,"builds":online_builds}})
  game.coop.broadcast_state(true)
 return true
func apply_build()->bool:
 var checked:Dictionary=validated_build(build)
 if checked.is_empty():status="Build inválida ou espaços excedidos.";return false
 build=checked
 if game.coop.active:
  online_builds[game.coop.connection.peer_id]=build.duplicate(true)
  if is_host():prepare_player(build,game.coop.actors[game.coop.connection.peer_id])
  else:send_build();return true
 else:prepare_player(build)
 status="Build aplicada.";return true
func heal():
 if game.coop.active and not is_host():request({"kind":"heal"});return
 if game.coop.active:
  var actor=game.coop.actors[game.coop.connection.peer_id];actor.player.hp=actor.player.max_hp;actor.player.down=false;actor.down=false
 else:game.player.hp=game.player.max_hp;game.player.down=false
func set_time(value:float):
 if active and is_host() and value in [.5,1.0,2.0]:Engine.time_scale=value;sync_controls()
func attacks()->Array:
 if not is_instance_valid(game.boss):return []
 if game.boss.is_executioner:return ["execute","charge"]
 if game.boss.data.id=="guardian":return ["cross","feathers","light_ring"]
 if game.boss.data.id=="horror":return FinalPatterns.IDS+(["fire","moving_ring","light_bands","dash","columns","ice_sectors"] if game.boss.form==2 else ["fire","summon","ice","columns","dash","ice_sectors","light_bands"])
 return ["fire","summon","charge","lightning","ice","ring"]
func force_attack(id:String,repeat_only:bool=false)->bool:
 if not active or not is_host() or not id in attacks() or not game.boss.alive:return false
 if game.boss is LateBoss:game.boss.isolated_attack=true;game.boss.queued_combination=""
 game.boss.dev_repeat=id if repeat_only else "";game.boss.dev_next_attack=id
 if game.boss.state=="chase":game.boss.attack_time=0
 repeat_attack=game.boss.dev_repeat;sync_controls();return true
func force_combination(first:String,second:String)->bool:
 if not active or not is_host() or not game.boss is LateBoss or not game.boss.alive:return false
 if not game.late_arena.patterns.config.combination_pairs.any(func(pair):return pair[0]==first and pair[1]==second):return false
 if not force_attack(first):return false
 game.boss.queued_combination=second;status="Combinação: "+first+" + "+second;return true
func normal_sequence():
 if not is_host() or not is_instance_valid(game.boss):return
 if game.boss is LateBoss:game.boss.isolated_attack=false;game.boss.queued_combination=""
 game.boss.dev_repeat="";game.boss.dev_next_attack="";repeat_attack="";sync_controls()
func freeze(value:bool):
 if not is_host() or not is_instance_valid(game.boss):return
 frozen=value;game.boss.dev_frozen=value;sync_controls()
func health_percent(percent:float):
 if is_host() and is_instance_valid(game.boss) and game.boss.alive:game.boss.hp=maxf(1,game.boss.max_hp*clampf(percent,.01,100)/100)
func next_phase()->bool:
 if not is_host() or not is_instance_valid(game.boss) or not game.boss.targetable:return false
 var boss=game.boss
 if boss.is_executioner:boss.hp=boss.max_hp*.49;return true
 if boss.data.id=="guardian" or boss.form!=1:return false
 boss.take_damage(boss.hp/maxf(.01,1-game.horde_progress.resistance())+.001);return true
func complete(_won:bool):
 running_test=false
 if not active or not is_host():return
 if game.coop.active:broadcast({"type":"dev_done","clock":game.elapsed})
 clear_player_effects()
 var clock:float=game.elapsed;game.clear_run();game.elapsed=clock;game.state="dev_complete";game.ui.render("running");status="Teste concluído. Reinicie ou escolha outro encontro."
func boss_info()->String:
 var scale:Dictionary=game.enemy_scale()
 var result:String="Escala simulada: %d | Vida %d%% | Dano %d%% | Movimento %d%% | Quantidade %d%%\nSimular escala não testa conexões reais. Desafio ativo: %d.\n"%[applied_participants if running_test else participants,scale.health*100,scale.damage*100,scale.speed*100,scale.count*100,game.run_challenge]
 if not is_instance_valid(game.boss):return result+status
 var boss=game.boss;var summons:int=game.boss_arena.summons.size()+game.late_arena.chain.count(boss.serial)+game.enemies.filter(func(e):return e is HazardTarget and e.owner_boss==boss.serial).size() if is_host() else boss.dev_summons_alive
 result+="Padrões: %d | Projéteis: %d/%d | Filas por limite: %d\n"%[game.late_arena.patterns.jobs.size(),game.late_arena.patterns.shots.size(),game.late_arena.patterns.config.max_projectiles,game.late_arena.patterns.blocked]
 if not game.late_arena.patterns.wait_reason.is_empty():result+=game.late_arena.patterns.wait_reason+"\n"
 return result+"Vida: %.1f / %.1f | Fase: %d | Estado: %s\nPreparação: %s | Próximo ataque: %.2f s | Invocações: %d\nDano-base do inimigo: %.2f | Movimento: %.2f px/s"%[boss.hp,boss.max_hp,boss.phase if boss.is_executioner else boss.form,boss.state,boss.attack_name,maxf(0,boss.attack_time),summons,boss.data.damage, movement_speed(boss)]+"\n"+damage_summary(boss)+" | Congelado: "+("sim" if boss.dev_frozen else "não")+" | Repetir: "+boss.dev_repeat

func _process(_delta:float):
 if is_instance_valid(collider_overlay):collider_overlay.visible=active and show_colliders;collider_overlay.queue_redraw()
 if active:badge.position=Vector2(276,30) if game.ui.hud.visible else Vector2(540,6)
 if active and running_test and is_host() and game.state=="running" and not survival_mode and not is_instance_valid(game.boss):complete(true)

func set_player_flag(key:String,value:bool):
 if key not in ["invulnerable","attacks"]:return
 build[key]=value
 if game.coop.active and not is_host():request({"kind":"flags","invulnerable":build.invulnerable,"attacks":build.attacks});return
 var owner=game.coop.actors[game.coop.connection.peer_id] if game.coop.active else game
 if key=="invulnerable":owner.player.dev_invulnerable=value;owner.player.invulnerable=0
 else:owner.weapon_system.attacks_enabled=value
func open_dev_room():
 if not active:return
 if game.state not in ["title","hub","online","lobby"]:status="Encerre o encontro antes de abrir uma sala.";return
 panel.hide();game.open_online()
func send_build():
 if not game.coop.active:return
 request({"kind":"build","build":build})

func movement_speed(boss)->float:
 if boss is LateBoss:return boss.data.speed
 return (game.boss_balance.executioner_speed if boss.is_executioner else game.boss_balance.demon_speed)*game.balance.enemy_speed_multiplier*game.enemy_scale().speed*(1.06 if boss.is_executioner and boss.phase>=2 else 1)
func damage_summary(boss)->String:
 var scale:float=game.enemy_scale().damage
 if boss is LateBoss:
  if boss.data.id=="guardian":return "Feixes / penas / anel: %.2f de dano"%game.late_arena.damage("cross",boss)
  return "Fogo: %.2f | Energia: %.2f | Dash: %.2f"%[game.late_arena.damage("fire",boss),game.late_arena.damage("column",boss),game.late_arena.damage("dash",boss)]
 if boss.is_executioner:return "Golpe: %.2f | Investida: %.2f"%[game.boss_balance.executioner_swing_damage*scale,game.boss_balance.executioner_charge_damage*scale]
 return "Fogo: %.2f | Raio: %.2f | Investida: %.2f"%[game.boss_balance.fire_damage*scale*boss.damage_scale(),game.boss_balance.lightning_damage*scale*boss.damage_scale(),game.boss_balance.demon_charge_damage*scale*boss.damage_scale()]

func broadcast(data:Dictionary):
 if game.coop.active and is_host():game.coop.publish(data);game.coop.flush_events()
func sync_controls():
 broadcast({"type":"dev_controls","time":Engine.time_scale,"frozen":frozen,"repeat":repeat_attack})
func request(data:Dictionary):
 if not game.coop.active:return
 network_revision+=1;data=data.duplicate(true);data.revision=network_revision
 if is_host():receive_request(game.coop.connection.peer_id,data)
 else:game.coop.connection.send_message({"type":"action","data":{"dev":data}})
func coop_ready():
 game.persistence_enabled=false;game.dev_boss_test=true;running_test=false;game.state="dev_preparing";game.director.phase="complete"
 accepted_revisions.clear();online_builds.clear()
 for actor in game.coop.actors.values():actor.player.dev_invulnerable=true;actor.weapon_system.attacks_enabled=false
 if is_host():online_builds[game.coop.connection.peer_id]=validated_build(build)
 else:send_build()
 status="Configure sua build. O host inicia o encontro pelo F8."
func receive_request(sender:String,raw):
 if not active or not is_host() or not game.coop.actors.has(sender) or not raw is Dictionary:return
 var revision:int=int(raw.get("revision",0))
 if revision<=int(accepted_revisions.get(sender,0)):return
 var actor=game.coop.actors[sender]
 match raw.get("kind",""):
  "build":
   if not raw.get("build") is Dictionary:return
   var checked:Dictionary=validated_build(raw.build)
   if checked.is_empty():return
   online_builds[sender]=checked;prepare_player(checked,actor)
   game.coop.publish({"type":"dev_build_applied","data":checked},sender);game.coop.flush_events()
  "flags":
   if not online_builds.has(sender):return
   var inv:bool=raw.get("invulnerable",false)==true;var attacks_on:bool=raw.get("attacks",true)==true
   online_builds[sender].invulnerable=inv;online_builds[sender].attacks=attacks_on
   actor.player.dev_invulnerable=inv;actor.player.invulnerable=0;actor.weapon_system.attacks_enabled=attacks_on
   game.coop.publish({"type":"dev_flags_applied","invulnerable":inv,"attacks":attacks_on},sender);game.coop.flush_events()
  "heal":
   actor.player.hp=actor.player.max_hp;actor.player.down=false;actor.down=false
   game.coop.publish({"type":"health","id":sender,"hp":actor.player.hp,"down":false,"invulnerable":false});game.coop.flush_events()
  _:return
 accepted_revisions[sender]=revision
func receive_event(data:Dictionary):
 match data.type:
  "dev_survival":
   survival_mode=true
   game.clear_run();game.coop.replicas.clear();game.coop.destinations.clear();game.elapsed=float(data.clock);game.campaign.endless=data.endless;game.campaign.cleared=data.endless;game.state="running";game.dev_boss_test=true;running_test=true;game.ui.render("running")
  "dev_start":
   var config:Dictionary=data.data;encounter=config.encounter;map_id=config.map;participants=int(config.participants);applied_participants=participants;hordes=config.hordes;online_builds=config.builds
   game.clear_run();game.coop.replicas.clear();game.coop.destinations.clear();game.arena.apply_map(map_id);game.selected_map=map_id
   game.state="running";game.elapsed=float(ENCOUNTERS[encounter][1]);game.dev_boss_test=true;game.persistence_enabled=false;game.run_challenge=clampi(int(config.get("challenge",0)),0,5);game.director.phase="complete"
   for id in game.coop.actors:
    if online_builds.has(id):prepare_player(online_builds[id],game.coop.actors[id])
   running_test=true;Engine.time_scale=float(config.time);game.ui.render("running");status="Encontro controlado pelo host.";panel.rebuild()
  "dev_controls":Engine.time_scale=float(data.time);frozen=data.frozen;repeat_attack=data.repeat
  "dev_build_applied":build=data.data.duplicate(true);prepare_player(build,game.coop.actors[game.coop.connection.peer_id]);status="Build validada pelo host."
  "dev_flags_applied":
   var owner=game.coop.actors[game.coop.connection.peer_id]
   owner.player.dev_invulnerable=data.invulnerable;owner.weapon_system.attacks_enabled=data.attacks
  "dev_done":
   running_test=false;clear_player_effects();game.clear_run();game.coop.replicas.clear();game.coop.destinations.clear();game.elapsed=float(data.clock);game.state="dev_complete";status="Teste concluído. Aguarde o host reiniciar."
  "dev_exit":
   game.coop.ended=true;game.coop.leave();end_test()

func launch_argument(id:String):
 if not ENCOUNTERS.has(id) or not enter():return
 encounter=id;map_id=game.selected_map;load_preset(ENCOUNTERS[id][2]);start_encounter();panel.hide()

func clear_player_effects():
 var systems:Array=[game.weapon_system]
 if game.coop.active:
  systems.clear()
  for actor in game.coop.actors.values():systems.append(actor.weapon_system);actor.player.clear_status()
 else:game.player.clear_status()
 for weapons in systems:
  weapons.projectiles.clear();weapons.slashes.clear();weapons.orbit_positions.clear();weapons.orbit_hits.clear();weapons.lightning_fx.clear();weapons.beams.clear()
  weapons.ground.reset();weapons.arsenal.reset();weapons.queue_redraw()

func start_survival(infinite:bool=false):
 if not is_host():return
 if not active and not enter():return
 if not start_encounter():return
 survival_mode=true;clear_player_effects();game.clear_run();game.state="running";game.elapsed=1200 if infinite else 0
 game.dev_boss_test=true;game.persistence_enabled=false;game.director.phase="active";game.director.elite_spawned=true
 game.campaign.cleared=infinite;game.campaign.endless=infinite;game.horde_progress.tick();running_test=true;game.ui.render("running");game.ui.update_hud(game.snapshot())
 broadcast({"type":"dev_survival","clock":game.elapsed,"endless":infinite})
func set_survival_time(seconds:float):
 if not active or not is_host():return
 game.elapsed=maxf(0,seconds);game.horde_progress.tick();game.ui.update_hud(game.snapshot())
 game.special_events.next_check=maxf(float(game.special_events.config.start),(floorf(game.elapsed/60)+1)*60)
 game.chests.next_check=maxf(float(game.chests.config.first),(floorf(game.elapsed/30)+1)*30)
func force_event(kind:String):
 if not active or not is_host():return
 if not running_test:start_survival()
 if game.enemies.any(func(e):return e is HordeBoss):status="Inicie o teste contínuo para forçar eventos.";return
 status="Evento iniciado" if game.special_events.start(kind) else "Evento aguardando espaço livre"
func force_chest():
 if not active or not is_host():return
 if not running_test:start_survival()
 status="Baú gerado" if game.chests.spawn_chest() else "Não há espaço ou já existe um baú fechado"
func survival_info()->String:
 var ev=game.special_events
 return "Tempo %.1fs | Estágio %d | Resistência %.0f%% | Vida adicional +%.0f\nGeração %.1f/min | Vivos %d/%d | Dívida %.1f | Adiamentos %d\nEvento: %s | Cerco restante %.1fs | Família viva %d | Lotes pendentes %d\nBaús %d gerados / %d abertos | Tentativas %d"%[game.elapsed,game.horde_progress.stage(),100*game.horde_progress.resistance(),game.horde_progress.stage()*game.balance.horde_health_step,game.director.rate(),game.enemies.size(),game.balance.max_enemies,game.director.debt,game.director.deferred+ev.deferred,ev.active,maxf(0,45-ev.age) if ev.active=="siege" else 0,ev.members.size() if ev.active=="king" else 0,ev.pending.size()+game.slime_families.pending.size(),game.chests.generated,game.chests.opened,game.chests.attempts]

func performance_info()->String:
 var net=game.coop.connection
 var metrics:Dictionary=net.metrics
 var c=game.consumables
 var consumable_info:String="Consumíveis: %d/%d | Chance %.1f%% | Próxima tentativa %.1fs\nRelógio %.1fs | Cristais pendentes %d\n"%[c.items.size(),c.config.limit,c.chance()*100,maxf(0,c.next_check-game.elapsed),c.freeze_left,c.magnet_jobs.size()]
 consumable_info+="Setores: %s\nBloqueios: %s\n"%[str(game.director.sector_counts),str(game.director.blocked_reasons)]
 return consumable_info+"FPS %.1f | Corpos %d | Pares locais %d | Maior célula %d\nNavegação: consultas %d | Adiadas %d | Campos %d\nRede: protocolo 2 / WebSocket TCP | RTT %.0f ms | Jitter %.0f ms\nEnviados %d bytes | Recebidos %d bytes | Fila %d bytes / %d ms\nCodificação %d µs | Decodificação %d µs | Snapshot há %d ms\nTempos de simulação (microssegundos): %s"%[Engine.get_frames_per_second(),game.enemies.size(),game.crowd_pairs,game.crowded_cell_peak,game.navigation.queries,game.navigation.deferred,game.navigation.field_builds,metrics.rtt_ms,metrics.jitter_ms,metrics.tx_bytes,metrics.rx_bytes,metrics.queue_bytes,metrics.queue_age_ms,metrics.serialize_us,metrics.decode_us,Time.get_ticks_msec()-net.last_snapshot_ms if net.last_snapshot_ms>0 else 0,str(game.perf_us)]

func force_consumable(kind:String):
 if not active or not is_host():return
 if not running_test:start_survival()
 status="Consumível gerado" if game.consumables.spawn_item(kind) else "Limite de dois itens ou falta de espaço"

func force_variant(kind:String):
 if not active or not is_host() or not game.variant_data.has(kind):return
 if not running_test:start_survival()
 var at:Vector2=game.free_enemy_position(game.player.position+Vector2(100,0),game.enemy_data[kind].radius)
 if at!=Vector2.INF:
  game.spawn_enemy(kind,at);status=game.enemy_data[kind].title+" gerado"
 else:status="Sem espaço livre"
