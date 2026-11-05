class_name LateBoss
extends HordeBoss
var locked_target:Vector2
var entry_age:float=0
var isolated_attack:bool=false
var queued_combination:String=""
func setup(owner_game,stats:EnemyData,_elite:bool=false):
 super.setup(owner_game,stats,false)
 var ratio:float=game.campaign.config.guardian_health_ratio_to_demon_phase2 if stats.id=="guardian" else game.campaign.config.horror_health_ratio_to_demon_phase2
 max_hp=game.boss_balance.demon_health()*game.boss_balance.second_health_multiplier*game.balance.enemy_health_multiplier*ratio
 hp=max_hp;state="chase";attack_time=1.5
 data.speed=game.boss_balance.demon_speed*(.8 if stats.id=="guardian" else float(game.campaign.config.horror_speed_ratio_to_demon))*game.balance.enemy_speed_multiplier*game.enemy_scale().speed
 if stats.id=="horror":data.damage=game.enemy_data.demon.damage*game.boss_balance.second_damage_multiplier*float(game.campaign.config.horror_damage_ratio_to_demon_phase2)*game.enemy_scale().damage
func apply_visual_form():
 var shown:int=1 if form==1 or (state=="transform" and state_time<.8) else 2
 if visual_form==shown:return
 visual_form=shown
 var path:String="res://assets/v10/guardian.png" if data.id=="guardian" else ("res://assets/v10/horror.png" if shown==1 else "res://assets/v10/true_form.png")
 sprite.texture=load(path);sprite.hframes=32;sprite.position.y=-sprite.texture.get_height()*.5+4
 if data.id=="horror" and shown==1:sprite.position.y=-14
func enable_combat():
 super.enable_combat()
 if data.id=="horror" and form==1:sprite.position.y=-14
func tick(delta:float):
 if dev_frozen or not alive or not combat_enabled:return
 tick_control(delta);clock+=delta;state_time+=delta;attack_time-=delta;hit_flash=maxf(0,hit_flash-delta)
 if state=="transform":
  apply_visual_form();sprite.frame=26+mini(3,int(fmod(state_time,.8)*5))
  if state_time>=1.6:state="chase";state_time=0;targetable=true;attack_time=1;game.announce("TRUE FORM",3)
  return
 var movement:=Vector2.ZERO
 var direction:Vector2=(game.player.position-position).normalized()
 if state=="chase":
  movement=game.navigation.steer(self,direction*data.speed)
  if attack_time<=0 and dev_attack_ready():
   var chosen:String=choose_attack()
   if not chosen.is_empty():begin_attack(chosen);movement=Vector2.ZERO
   else:attack_time=.15
 elif state=="windup" and state_time>=warning_duration():execute_attack()
 elif state=="charge":
  var speed:float=game.boss_balance.demon_charge_speed*game.balance.enemy_speed_multiplier*game.enemy_scale().speed
  movement=charge_direction*speed
  if state_time>=.9 or position.distance_to(locked_target)<12:finish_attack();movement=Vector2.ZERO
 elif state=="recovery" and state_time>=float(game.campaign.config.recovery):state="chase";state_time=0
 if slow_remaining>0:movement*=slow_factor
 var before:Vector2=position;velocity=movement;move_body()
 if state=="charge":
  var victim=game.projectile_victim(before,position,radius)
  if victim!=null and not charge_hit:charge_hit=true;victim.take_damage(game.late_arena.damage("dash",self),before)
  if is_on_wall():finish_attack()
 if hit_flash>0:sprite.frame=24+int(hit_flash<.04)
 elif state=="windup":sprite.frame=12+mini(3,int(state_time/warning_duration()*4))
 elif state=="recovery":sprite.frame=16+mini(7,int(state_time/maxf(.01,float(game.campaign.config.recovery))*8))
 else:sprite.frame=4+int(clock*9)%8 if movement.length()>2 else int(clock*4)%4
 sprite.flip_h=charge_direction.x<0 if state in ["windup","charge"] else direction.x<0
 sprite.modulate=Color(1.5,1.5,1.5) if hit_flash>0 else Color.WHITE
 queue_redraw()
func begin_attack(id:String):
 attack_name=id;state="windup";state_time=0
 var players:Array=game.team_players()
 var target=players[randi()%players.size()] if not players.is_empty() else game.player
 locked_target=target.position;charge_direction=(locked_target-position).normalized()
func warning_duration()->float:return float(game.campaign.config.warning)
func choose_attack()->String:
 if not dev_next_attack.is_empty():
  var selected:String=dev_next_attack;dev_next_attack="";return selected
 if not dev_repeat.is_empty():return dev_repeat
 var order:Array=["cross","feathers","light_ring"] if data.id=="guardian" else ["fire","summon","ice","columns","dash","ice_sectors","light_bands"]
 if data.id=="horror":order+=["spiral","rings","spears","orbs"]
 if form==2:order=["fire","moving_ring","light_bands","dash","columns","ice_sectors"]
 if form==2:order+=FinalPatterns.IDS
 var chosen:String=order[attack_index%order.size()]
 if chosen!="dash" and not game.late_arena.can_cast(chosen):return ""
 attack_index+=1;return chosen
func execute_attack():
 if attack_name=="dash":state="charge";state_time=0;charge_hit=false
 elif attack_name in FinalPatterns.IDS:
  var second:String=queued_combination
  if second.is_empty() and form==2 and not isolated_attack:
   for pair in game.late_arena.patterns.config.combination_pairs:
    if pair[0]==attack_name:second=pair[1];break
  if game.late_arena.patterns.request(attack_name,self,second):queued_combination="";isolated_attack=not dev_repeat.is_empty();finish_attack()
  else:state_time=maxf(0,warning_duration()-.15)
 else:game.late_arena.cast(attack_name,self);finish_attack()
func finish_attack():
 state="recovery";state_time=0
 attack_time=float(game.campaign.config.guardian_interval if data.id=="guardian" else (game.campaign.config.true_interval if form==2 else game.campaign.config.horror_interval))
func take_damage(amount:float,_force:Vector2=Vector2.ZERO):
 if not alive or not combat_enabled or not targetable:return
 amount=received_damage(amount);hp=maxf(0,hp-amount);hit_flash=.08;game.add_damage_number(position-Vector2(0,45),amount)
 if hp>0:return
 if data.id=="horror" and form==1:
  dev_repeat="";dev_next_attack=""
  form=2;max_hp=(max_hp-horde_health_bonus)*float(game.campaign.config.true_health_ratio)+horde_health_bonus;hp=max_hp;state="transform";state_time=0;targetable=false;velocity=Vector2.ZERO
  game.late_arena.clear_attacks(self);game.announce("TRUE FORM",3);return
 if death_paid:return
 death_paid=true;alive=false;targetable=false;state="death";velocity=Vector2.ZERO;game.enemy_killed(self)
func _draw():
 draw_rect(Rect2(-radius,-2,radius*2,6),Color(0,0,0,.35))
 if state=="windup" and attack_name=="dash":draw_line(Vector2.ZERO,locked_target-position,Color("f0c77d"),2)

func dev_attack_ready()->bool:
 var requested:String=dev_next_attack if not dev_next_attack.is_empty() else dev_repeat
 if not requested.is_empty():return (game.late_arena.patterns.idle() if requested=="dash" else game.late_arena.can_cast(requested))
 return game.late_arena.patterns.idle() and game.late_arena.patterns.cooldown<=0
