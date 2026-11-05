extends SceneTree
class Connection extends RoomConnection:
 func send_message(_packet:Dictionary)->bool:return true
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.sound.volume=0;g.coop.connection.queue_free();g.coop.connection=Connection.new();g.coop.add_child(g.coop.connection);g.coop.connection.peer_id="a";g.coop.connection.host_id="a";g.coop.hosting=true
 g.coop.begin({"run":"vote13","players":[{"id":"a","name":"A","skills":{}},{"id":"b","name":"B","skills":{}},{"id":"c","name":"C","skills":{}},{"id":"d","name":"D","skills":{}}]})
 g.campaign.offer_endless();g.campaign.accept_vote("a",true);g.campaign.accept_vote("forged",true);g.campaign.accept_vote("b",true);assert(g.campaign.deciding)
 g.campaign.accept_vote("b",false);assert(g.campaign.deciding)
 g.campaign.accept_vote("c",false);assert(g.coop.ended and g.ui.previous_data.won)
 g.queue_free();await process_frame;await create_timer(.2).timeout;print("VOTING13_PASS connected members only, one vote per member, no single-host override, explicit no settles victory");quit()
