extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.sound.volume=0
	var checks=0
	for dimensions in [Vector2i(1280,720),Vector2i(1024,768),Vector2i(1920,800)]:
		root.size=dimensions
		game.ui.render("title")
		await process_frame
		await process_frame
		var footer=game.ui.menu.get_node("Footer")
		var layout=game.ui.menu.get_node("TitleLayout")
		assert(footer.get_global_rect().position.y >= 0)
		checks+=1
		var stack:Array=[layout]
		while not stack.is_empty():
			var node=stack.pop_back()
			if node is Button:
				assert(not node.get_global_rect().intersects(footer.get_global_rect()))
				checks+=1
			stack.append_array(node.get_children())
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://test_output/title_%dx%d.png"%[dimensions.x,dimensions.y])
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("LAYOUT_PASS checks=",checks)
	quit()
