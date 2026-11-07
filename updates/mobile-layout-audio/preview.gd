extends SceneTree
func _initialize() -> void: call_deferred("check")
func frames(count := 5) -> void:
	for i in count: await process_frame
func check() -> void:
	await process_frame
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames()
	root.mode = Window.MODE_WINDOWED
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1055, 488)
	await frames()
	var ui = root.get_node("Game").ui
	ui.layout_defaults()
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW"))
	print("PASS rendered phone HUD")
	quit()
