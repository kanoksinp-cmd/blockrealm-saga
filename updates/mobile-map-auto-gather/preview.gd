extends SceneTree
func _initialize() -> void: call_deferred("check")
func frames(n:=5) -> void:
	for i in n: await process_frame
func check() -> void:
	await process_frame
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await frames()
	root.mode=Window.MODE_WINDOWED
	root.min_size=Vector2i.ZERO
	root.size=Vector2i(1055,488)
	await frames()
	var ui=root.get_node("Game").ui
	ui.toggle(ui._wmap.panel)
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join("mobile-map-local.png"))
	ui._wmap_world=true
	ui._fill_worldmap()
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join("mobile-map-world.png"))
	root.size=Vector2i(844,450)
	await frames(8)
	ui._fit_windows()
	await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join("mobile-map-compact.png"))
	print("PASS_RENDER map local/world/compact")
	quit()
