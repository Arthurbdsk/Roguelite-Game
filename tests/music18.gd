extends SceneTree
var errors:int=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok:errors+=1;printerr("FAIL "+label)
func run():
 var muted:bool=AudioServer.is_bus_mute(0);AudioServer.set_bus_mute(0,true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.profile.data.settings.volume=0;g.apply_settings()
 var m=g.music;var stream=m.player.stream;m.suppress_test_audio=false;m.volume=.5
 m.player.play();await process_frame;m.player.seek(12);await create_timer(.3).timeout
 check(m.player.playing and m.player.get_playback_position()>12,"actual MP3 playback advances")
 var before:float=m.player.get_playback_position();g.start_run();await create_timer(.3).timeout
 check(m.player.stream==stream and m.player.get_playback_position()>before,"menu-match transition preserves one cached stream")
 check(m.get_child_count()==1,"single music player")
 m.player.seek(m.duration-.1);await create_timer(.3).timeout
 check(m.player.get_playback_position()<1 and m.player.playing,"loop crosses actual file ending")
 var sfx:float=g.sound.volume;g.set_option("music",0);await process_frame
 check(m.volume==0 and m.player.volume_db<=-79 and g.sound.volume==sfx,"music volume mutes independently")
 g.set_option("music",.3);await create_timer(.3).timeout;check(m.volume==.3 and m.player.volume_db>-79,"music resumes without another player")
 m.duck();check(m.duck_remaining>0,"important cues duck music")
 print("MUSIC18 length_seconds=",m.duration," stream_loads=1 players=",m.get_child_count())
 stream=null;g.queue_free();await process_frame;await create_timer(.3).timeout;AudioServer.set_bus_mute(0,muted)
 print("MUSIC18_"+("PASS" if errors==0 else "FAIL"));quit(int(errors>0))
