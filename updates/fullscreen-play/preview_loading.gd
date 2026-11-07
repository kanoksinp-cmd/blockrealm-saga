extends SceneTree
func _initialize() -> void: call_deferred("check")
func check() -> void:
	await process_frame
	root.mode = Window.MODE_WINDOWED
	root.min_size = Vector2i.ZERO
	var overlay = load("res://scripts/ui/game_loading.gd").new()
	root.add_child(overlay)
	overlay._build_ui()
	overlay._update(63, "กำลังเตรียมโลกและตัวละคร...")
	for entry in [[Vector2i(1440, 900), "loading-pc"], [Vector2i(800, 600), "loading-window"], [Vector2i(1055, 488), "loading-phone"]]:
		root.size = entry[0]
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join(entry[1] + ".png"))
		assert(overlay._bar.get_global_rect().end.x <= root.get_visible_rect().size.x)
	print("PASS_LOADING_RENDER three viewport sizes")
	overlay.queue_free()
	await process_frame
	var transition = load("res://scripts/ui/game_loading.gd").new()
	root.add_child(transition)
	transition.start("res://scenes/main.tscn")
	await scene_changed
	assert(current_scene.name == "Main")
	await process_frame
	assert(transition._bar.value == 100)
	await create_timer(0.5).timeout
	assert(not is_instance_valid(transition))
	print("PASS_LOADING_TRANSITION full progress and overlay cleanup")
	quit()
