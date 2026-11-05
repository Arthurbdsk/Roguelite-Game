extends SceneTree
func _initialize():call_deferred("run")
func run():
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false)
 var p=GameProfile.new("user://price12_fixture.json");p.data.gold=20000;p.data.upgrade_ranks={"damage":2};p.data.upgrade_spent={"damage":36};assert(p.save())
 var loaded=GameProfile.new(p.path);assert(loaded.load_profile());g.profile=loaded;g.state="tree"
 assert(g.skills.rank("damage")==2 and g.skills.refund_total()==36)
 assert(g.skills.purchase("damage",2));assert(g.profile.data.gold==19600 and g.profile.data.upgrade_spent.damage==436)
 assert(not g.skills.purchase("damage",2));assert(g.skills.purchase("armor",0));assert(g.profile.data.upgrade_spent.armor==325)
 assert(g.skills.state("revive").cost==10000 and g.skills.state("amount").cost==325)
 var rev:int=g.profile.data.upgrade_revision;assert(g.skills.refund_total()==761)
 assert(g.skills.refund(rev));assert(not g.skills.refund(rev));assert(g.profile.data.gold==20036)
 var again=GameProfile.new(p.path);assert(again.load_profile() and again.data.gold==20036 and again.data.upgrade_ranks.values().all(func(n):return n==0))
 # The old tree migration keeps the historical catalog, regardless of current prices.
 p=GameProfile.new("user://price12_legacy.json");p.data.version=3;p.data.gold=100;p.data.skill_ranks={"edge":2,"armor":2,"critical":1};assert(p.save())
 var migrated=GameProfile.new(p.path);assert(migrated.load_profile() and migrated.data.gold==208 and migrated.data.upgrade_spent.damage==36)
 var twice=GameProfile.new(p.path);assert(twice.load_profile() and twice.data.gold==208)
 g.queue_free();await process_frame;await create_timer(.2).timeout
 print("PRICES12_PASS new prices, actual historical ledger, no retroactive charge, stale clicks/refunds rejected, persistence and one-time legacy migration");quit()
