extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	await process_frame
	root.size = Vector2i(1055, 488)
	root.mode = Window.MODE_WINDOWED
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for i in 5:
		await process_frame
	var player = get_first_node_in_group("player")
	player.set_process(false)
	player.set_physics_process(false)
	var monster = get_first_node_in_group("monster")
	player.attack_target = monster
	for i in 15:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW"))
	print("PASS rendered mobile preview")
	quit()
