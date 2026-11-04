extends SceneTree
func _initialize():call_deferred("run")
func run():
 var path:String="user://migration_v4_fixture.json"
 var p:=GameProfile.new(path);p.data.version=3;p.data.gold=100;p.data.skill_ranks={"edge":2,"armor":2,"critical":1};assert(p.save())
 var loaded:=GameProfile.new(path);assert(loaded.load_profile());assert(loaded.data.version==4)
 assert(loaded.data.gold==208 and loaded.data.upgrade_ranks.damage==2)
 assert(loaded.data.upgrade_spent.damage==36 and FileAccess.file_exists(path+".pre_upgrades_v4.bak"))
 var again:=GameProfile.new(path);assert(again.load_profile());assert(again.data.gold==208)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.profile=again;assert(g.skills.definitions.size()==16);g.state="tree"
 assert(g.skills.purchase("damage",2));assert(not g.skills.purchase("damage",2));assert(g.profile.data.gold==158)
 var revision:int=g.profile.data.upgrade_revision;assert(g.skills.refund_total()==86)
 assert(g.skills.refund(revision));assert(not g.skills.refund(revision));assert(g.profile.data.gold==244)
 assert(g.profile.data.upgrade_ranks.is_empty());g.queue_free();await process_frame;await create_timer(.3).timeout
 again.data.gold_remainder=.75;assert(again.save())
 var carry:=GameProfile.new(path);assert(carry.load_profile() and is_equal_approx(carry.data.gold_remainder,.75))
 var invalid_path:String="user://permanent_invalid9.json"
 var invalid_file:=FileAccess.open(invalid_path,FileAccess.WRITE);invalid_file.store_string('{"version":999}');invalid_file.close()
 var invalid:=GameProfile.new(invalid_path);assert(not invalid.load_profile() and not invalid.save())
 assert(FileAccess.get_file_as_string(invalid_path)=='{"version":999}')
 print("PERMANENT_DATA9_PASS 16 definitions, backup, one-time migration, exact ledger refund, stale click rejected");quit()
