extends SceneTree
var failures:int=0
var checks:int=0
func _initialize():call_deferred("run")
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+message)
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_physics_process(false);g.persistence_enabled=false;g.test_mode=true;g.sound.volume=0;g.start_run()
 var w=g.weapon_system
 check(w.passive_data.size()==9 and not w.weapon_data.has("blades"),"one new passive, retired blades absent")
 for key in GameIcons.entries():
  var row:Dictionary=GameIcons.entries()[key]
  check(ResourceLoader.exists(row.asset),"catalog asset "+key)
  if row.origin=="Clockwork Raven":
   var img:Image=GameIcons.texture(key).get_image();img.convert(Image.FORMAT_RGBA8)
   var raw:PackedByteArray=img.get_data()
   for p in range(0,raw.size(),4):
    if raw[p+3]==0:raw[p]=0;raw[p+1]=0;raw[p+2]=0
   var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(raw)
   check(hash.finish().hex_encode()==row.pixel_sha256,"exact source pixels, not stale atlas "+key)
 for id in w.weapon_data:check(w.weapon_data[id].icon==GameIcons.path("weapon:"+id),"weapon catalog "+id)
 for id in w.passive_data:check(w.passive_data[id].icon==GameIcons.path("passive:"+id),"passive catalog "+id)
 check(w.weapon_data.axe.icon=="res://assets/v18/axe.png","approved axe preserved")
 check(w.levels=={"bolt":1},"starting build preserved")
 g.mastery.enabled=true;g.mastery.bonuses={"regen":.5}
 for rank in range(1,9):
  w.passives.clear()
  for n in rank:check(w.apply_upgrade("regeneration"),"acquisition advances exactly one level")
  check(int(w.passives.regeneration)==rank,"rank "+str(rank))
  check(absf(g.mastery.regeneration_rate()-(.5+.2*rank))<.00001,"additive rate "+str(rank))
  g.player.hp=10
  for frame in 300:g.mastery.tick(1.0/60,0)
  check(absf(g.player.hp-(10+5*(.5+.2*rank)))<.0001,"fractional healing over 300 frames "+str(rank))
  g.player.hp=99.99;g.mastery.tick(1,0);check(g.player.hp==g.player.max_hp,"health cap")
  g.player.down=true;var before:float=g.player.hp;g.mastery.tick(5,0);check(g.player.hp==before,"no healing downed");g.player.down=false
 check(not w.apply_upgrade("regeneration"),"cannot exceed eight")
 w.passives={"boots":1,"heart":1,"ward":1,"cadence":1}
 check(not w.apply_upgrade("regeneration"),"four passive slots respected")
 w.passives={"regeneration":1,"heart":1,"ward":1,"cadence":1};check(w.apply_upgrade("regeneration"),"owned upgrade allowed at full slots")
 w.levels={"bolt":8};w.passives={"regeneration":1};g.chests.chest={"id":19}
 var receipt:Dictionary=g.chests.award(g,100)
 check(receipt.item=="Regeneração" and receipt.before==1 and receipt.after==2,"chest upgrades equipped regeneration")
 check(receipt.icon==w.passive_data.regeneration.icon,"same chest icon")
 g.mastery.enabled=false;check(absf(g.mastery.regeneration_rate()-.4)<.00001,"run passive works without permanent bonuses")
 g.coop.active=true;g.coop.hosting=false;g.player.hp=10;g.mastery.tick(5,0);check(g.player.hp==10,"clients cannot authorize healing");g.coop.active=false
 g.start_run();check(g.mastery.regeneration_rate()==0 and w.passives.is_empty(),"restart clears run passive, no accumulation")
 check(g.ui.ui_theme.default_font==GameFonts.interface_font(),"simple interface font")
 check(g.ui.time_text.get_theme_font("font")==GameFonts.timer_font(),"gothic match timer only")
 check(GameFonts.interface_font()!=GameFonts.timer_font(),"separate font resources")
 for c in "0123456789:":check(GameFonts.timer_font().has_char(c.unicode_at(0)),"timer glyph "+c)
 check(g.ui._clock(125)=="02:05","timer minutes and seconds")
 check(g.ui.loadout.font==GameFonts.interface_font(),"functional font in batched HUD build")
 check(GameIcons.texture("status:poison")==GameIcons.texture("status:poison"),"icons cached")
 g.queue_free();await process_frame;await create_timer(.3).timeout
 print("CONTENT19_"+("PASS" if failures==0 else "FAIL")+" checks="+str(checks));quit(int(failures>0))
