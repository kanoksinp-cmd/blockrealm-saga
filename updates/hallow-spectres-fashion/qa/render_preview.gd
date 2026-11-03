extends SceneTree
func _initialize():
	await process_frame
	var Avatar = load("res://scripts/voxel/avatar.gd")
	var world := Node3D.new(); root.add_child(world)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.13, 0.14, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.75, 0.75, 0.8); e.ambient_light_energy = 0.9
	env.environment = e; world.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 25, 0); sun.light_energy = 1.2; world.add_child(sun)
	var cam := Camera3D.new(); world.add_child(cam)
	var mode := OS.get_environment("VIEW")
	cam.position = Vector3(0, 1.0, 3.6) if mode != "back" else Vector3(0, 1.0, -3.6)
	cam.look_at(Vector3(0, 0.85, 0)); cam.fov = 40
	var looks := [["", "swordsman"], ["pumpkin_reaper", "swordsman"], ["bone_oracle", "mage"], ["hollow_scarecrow", "archer"]]
	for i in looks.size():
		var a = Avatar.default_appearance(); a.job = looks[i][1]; a.fashion = looks[i][0]
		var n := Node3D.new(); world.add_child(n); n.position = Vector3((i - 1.5) * 1.05, 0, 0)
		if mode == "back": n.rotation_degrees.y = 180
		elif mode == "side": n.rotation_degrees.y = 55
		Avatar.assemble(n, a)
	for k in 8: await process_frame
	var img := root.get_texture().get_image()
	img.save_png("/tmp/render_%s.png" % (mode if mode != "" else "front"))
	quit()
