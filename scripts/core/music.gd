class_name GameMusic
extends Node
var game
var player:AudioStreamPlayer
var volume:float=.35:
 set(value):
  volume=clampf(value,0,1)
  if volume==0:
   gain=0
   if player!=null:player.volume_db=-80
var gain:float=0
var duck_remaining:float=0
var duration:float=0
var suppress_test_audio:bool=false
var shutting_down:bool=false
func setup(owner_game):game=owner_game
func _ready():
 player=AudioStreamPlayer.new();player.name="MainMusic";add_child(player)
 var track:AudioStreamMP3=load("res://assets/audio/gothic_piano.mp3")
 track.loop=true;track.loop_offset=0;duration=track.get_length()
 player.stream=track;player.volume_db=-80
 suppress_test_audio="--self-test" in OS.get_cmdline_user_args()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--profile-slot=cooptest"):suppress_test_audio=true
 if not suppress_test_audio:player.play()
 game.sound.important_cue.connect(duck)
func duck():duck_remaining=.6
func _process(delta:float):
 if player==null:return
 if shutting_down:return
 if suppress_test_audio:return
 duck_remaining=maxf(0,duck_remaining-delta)
 var position:float=fposmod(player.get_playback_position(),maxf(1,duration))
 var envelope:float=minf(clampf(position/.6,0,1),clampf((duration-position)/.6,0,1))
 var in_match:bool=game.state in ["running","paused","upgrading"]
 var target:float=volume*.22*(1.0 if in_match else .7)*(.4 if duck_remaining>0 else 1.0)
 gain=lerpf(gain,target,1-exp(-delta*5))
 player.volume_db=linear_to_db(maxf(.0001,gain*envelope)) if volume>0 else -80
 player.stream_paused=suppress_test_audio or (volume<=0 and gain<.0001)
func shutdown():
 shutting_down=true
 if player!=null:player.stop();player.stream=null
func _exit_tree():shutdown()
