class_name RunMastery
extends RefCounted
var game
var enabled:bool=true
var damage_multiplier:float=1
var interval_multiplier:float=1
var last_stand_spent:bool=false
var gold_fraction:float=0
var gold_bonus:int=0
var bonuses:Dictionary={}
var ranks:Dictionary={}
func setup(owner_game):game=owner_game
func rank(id:String)->int:return int(ranks.get(id,0)) if enabled else 0
func value(id:String)->float:return float(bonuses.get(id,0)) if enabled else 0.0
func begin(use_skills:bool=true):
 enabled=use_skills;bonuses.clear();ranks.clear();gold_fraction=float(game.profile.data.gold_remainder);gold_bonus=0;last_stand_spent=false
 for d in game.skills.definitions:ranks[d.id]=game.skills.rank(d.id);bonuses[d.id]=game.skills.value(d.id)
 game.player.max_hp=100*(1+value("health"));game.player.hp=game.player.max_hp
 game.player.speed=96*(1+value("move"));game.player.pickup_radius=42*(1+value("pickup"));game.player.armor=0
 game.player.damage_reduction=value("armor");game.player.movement_multiplier=1;game.player.time_since_damage=0
 damage_multiplier=1+value("damage");interval_multiplier=1-value("cooldown")
func tick(delta:float,_distance_moved:float):
 if not game.player.down and game.player.hp>0:game.player.hp=minf(game.player.max_hp,game.player.hp+delta*value("regen"))
func hit(enemy,amount:float,force:Vector2):enemy.take_damage(amount*damage_multiplier,force)
func can_revive()->bool:return rank("revive")>0 and not last_stand_spent
func use_revive()->bool:
 if not can_revive() or not (game.player.down or game.player.hp<=0):return false
 last_stand_spent=true;game.player.down=false;game.player.hp=game.player.max_hp*.4;game.player.clear_status();game.player.invulnerable=2;game.player.revive_remaining=.45
 return true
func save_from_death()->bool:
 if not can_revive() or game.coop.active:return false
 game.show_revive_offer();return true
func on_gold(amount:int):
 gold_fraction+=amount*value("gold")
 var extra:int=floori(gold_fraction+.0000001);gold_fraction=maxf(0,gold_fraction-extra);gold_bonus+=extra
func passive_limit()->int:return 4
func coin_speed_multiplier()->float:return 1.0
