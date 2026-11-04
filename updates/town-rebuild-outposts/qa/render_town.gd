extends SceneTree
func _initialize():
	await process_frame
	var Game = root.get_node("Game")
	var a = load("res://scripts/voxel/avatar.gd").default_appearance()
	Game.slot = 0; Game.new_character("Cam", a)
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main); current_scene = main
	for i in 5: await process_frame
	for c in main.get_children():
		if c is CanvasLayer: c.visible = false
	var hud = main.get_node_or_null("HUD"); if hud: hud.visible = false
	var cam := Camera3D.new(); main.add_child(cam); cam.current = true; cam.fov = 50; cam.far = 400
	var shots := [
		["fountain", Vector3(0, 11, 14), Vector3(0, 0, 0)],
		["smithy", Vector3(10, 9, 26), Vector3(18, 5, 4)],
		["guild", Vector3(-2, 14, 22), Vector3(-11, 10, -8)],
		["houses", Vector3(-14, 14, 4), Vector3(-27, 3, -9)],
		["houses2", Vector3(10, 12, 42), Vector3(12, 3, 26)],
	]
	for sh in shots:
		cam.position = sh[1]; cam.look_at(sh[2])
		for i in 6: await process_frame
		root.get_texture().get_image().save_png("/tmp/town_%s.png" % sh[0])
	quit()
