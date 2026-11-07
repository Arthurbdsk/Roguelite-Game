extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 if not ok:errors+=1;printerr("FAIL "+message)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.start_run();g.weapon_system.attacks_enabled=false
 var before:float=g.elapsed;g.gold=37
 g.mobile.interact_held=true;g.mobile.direction=Vector2.RIGHT
 g.mobile_suspend(false);g.simulate(10,Vector2.RIGHT)
 check(g.state=="paused" and g.elapsed==before,"background pauses solo simulated clock")
 check(not g.mobile.interact_held and g.mobile.direction==Vector2.ZERO,"background clears held controls")
 g.mobile_resume();check(g.state=="paused" and not g.mobile_backgrounded,"resume does not unexpectedly resume combat")
 check(g.gold==37 and not g.run_settled,"resume does not settle or duplicate rewards")
 g.mobile_back();check(g.state=="running","Android Back resumes paused solo")
 g.mobile_back();check(g.state=="paused","Android Back opens pause")
 g.open_mobile_panel("build");check(g.ui.screen=="mobile_build" and g.state=="paused","build uses same solo pause")
 g.mobile_back();check(g.ui.screen=="running" and g.state=="running","Back from build resumes")
 g.state="title";g.ui.render("online");await process_frame
 var field=g.ui.menu.find_child("MobileName",true,false);field.grab_focus();g.mobile_back();check(g.ui.screen=="online" and not field.has_focus(),"Back dismisses text entry first")
 g.coop.connection.connected=true;g.coop.connection.code="ABC123";g.state="lobby";g.mobile_suspend(true)
 check(g.state=="online" and not g.coop.connection.connected and g.coop.connection.code.is_empty(),"background also releases lobby and pending room")
 g.mobile_resume()
 var p:=GameProfile.new("user://mobile_lifecycle_fixture.json");p.data.gold=123;p.data.upgrade_ranks={"damage":2};check(p.save(),"private progress written")
 var q:=GameProfile.new(p.path);check(q.load_profile() and q.data.gold==123 and q.data.upgrade_ranks.damage==2,"progress survives process-style reload")
 check(OS.get_user_data_dir().contains("Hordas Android"),"desktop mobile preview also isolated from PC save")
 check(ProjectSettings.get_setting("network/compatible_game_version")=="0.20.0","explicit frozen PC compatibility")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("MOBILE_LIFECYCLE_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
