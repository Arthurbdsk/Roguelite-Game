extends SceneTree
class AcceptedConnection extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.sound.volume=0;g.set_physics_process(false)
 g.profile.data.upgrade_ranks={"challenge":5,"gold":5,"revive":1};g.profile.data.challenge_active=5
 g.coop.connection.queue_free();g.coop.connection=AcceptedConnection.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"upgrades9","challenge":5,"players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{"damage":999,"experience":5,"gold":1,"revive":1}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 g.director.phase="complete"
 var s:Dictionary=g.enemy_scale();assert(is_equal_approx(s.health,2.5*1.25));assert(is_equal_approx(s.damage,2.5*1.25));assert(is_equal_approx(s.count,3.4*1.25));assert(is_equal_approx(s.speed,1.6))
 var count:int=0
 for amount in g.wave_composition({"ghoul":12}).values():count+=amount
 assert(count==51)
 assert(g.coop.actors.b.mastery.damage_multiplier==1.25)
 for i in 20:g.coop.on_gold(1)
 assert(g.coop.actors.a.mastery.gold_bonus==5 and g.coop.actors.b.mastery.gold_bonus==1)
 for id in g.coop.actors:g.coop.mark_down(id)
 g.coop.host_tick(.01,{"movement":Vector2.ZERO,"revive":false});assert(not g.coop.ended)
 g.coop.receive({"type":"action","from":"b","data":{"sequence":77,"movement":[0,0],"self_revive":true}})
 g.coop.receive({"type":"action","from":"b","data":{"sequence":78,"movement":[0,0],"self_revive":false}})
 assert(not g.coop.perform_self_revive("b"));assert(g.coop.actors.b.player.hp==40 and g.coop.actors.b.player.invulnerable==2)
 assert(g.coop.actors.a.mastery.can_revive())
 g.coop.actors.b.player.position=g.coop.actors.a.player.position+Vector2(10,0)
 var before:bool=g.coop.actors.a.mastery.last_stand_spent
 var states:Dictionary=g.coop.actor_states()
 var events:Array=g.coop.revives.update(6,states,{"b":{"movement":Vector2.ZERO,"revive":true}})
 assert(not events.is_empty() and not before and not g.coop.actors.a.mastery.last_stand_spent)
 assert(g.coop.perform_self_revive("a"));assert(g.coop.actors.a.player.hp==40)
 g.coop.mark_down("a");g.coop.mark_down("b");g.coop.host_tick(.01,{"movement":Vector2.ZERO,"revive":false});assert(g.coop.ended)
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("PERMANENT_COOP9_PASS challenge once, rank clamp, per-owner gold, all-down offer, host revive once, ally revive preserves benefit");quit()
