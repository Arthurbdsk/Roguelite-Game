extends SceneTree
var g
func _initialize():call_deferred("run")
func capture(file:String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test_output/"+file+".png")
func run():
	g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
	g.sound.volume=0;g.start_run();g.director.phase="complete";g.banner=""
	g.player.position=Vector2(900,630)
	for i in 4:
		var e=g.spawn_enemy(["necromancer","beast","plague","shadow"][i],Vector2(735+i*110,600))
		e.sprite.frame=1
	g.specials.flask(Vector2(955,600),Vector2(950,690));g.specials.tick(1.1)
	g.player.apply_poison(10,2);g.ui.update_hud(g.snapshot())
	await capture("features_enemies")
	g.profile.data.skill_ranks.pact=1
	g.weapon_system.levels={"sword":4,"lightning":2,"clock":1}
	g.weapon_system.passives={"crown":1,"magnet":2,"boots":2,"ward":2}
	g.player.max_hp=125;g.player.hp=100;g.player.speed=132;g.player.armor=4;g.player.pickup_radius=114
	var choices:Array=[]
	for id in ["clock","lightning","sword"]:
		var n:int=g.weapon_system.levels[id]
		choices.append({"id":id,"name":g.weapon_system.weapon_data[id].display_name,"description":g.weapon_system.upgrade_values(id,n),"detail":"Nível %d → %d"%[n,n+1],"icon":g.weapon_system.weapon_data[id].icon})
	g.state="upgrading";g.ui.render("upgrading",{"offers":choices})
	await capture("features_build")
	var panel=g.ui.menu.find_child("BuildPanel",true,false)
	for child in panel.get_children():
		if child is Control:assert(child.get_global_rect().end.y<=333,"full build panel stays inside viewport")
	var list=g.ui.menu.find_child("UpgradeList",true,false)
	for option in list.get_children():
		assert(option.get_global_rect().end.y<=333,"upgrade option stays inside viewport")
		var pending:Array=[option]
		while not pending.is_empty():
			var child=pending.pop_back()
			if child is Label:assert(option.get_global_rect().encloses(child.get_global_rect()),"description stays inside option")
			pending.append_array(child.get_children())
	g.start_run();g.director.phase="boss";g.boss_arena.begin_portal();g.boss_arena.tick(4)
	g.boss.take_damage(100000);g.boss.tick(1.7)
	g.player.position=Vector2(900,700);g.boss_arena.cast("ice",g.boss,Vector2.DOWN,2)
	g.ui.update_hud(g.snapshot());await capture("features_boss_ice")
	g.boss_arena.clear_for_transform();g.boss_arena.cast("ring",g.boss,Vector2.DOWN,2)
	await capture("features_boss_ring")
	g.queue_free();await process_frame;await create_timer(.5).timeout
	print("FEATURE_RENDER_PASS full build layout, enemies and phase-two areas");quit()
