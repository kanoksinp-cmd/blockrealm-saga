extends SceneTree
func _initialize():
	await process_frame
	root.transparent_bg = true
	var Avatar = load("res://scripts/voxel/avatar.gd")
	var world := Node3D.new(); root.add_child(world)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR; e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.78, 0.85); e.ambient_light_energy = 0.9; env.environment = e; world.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-30, 35, 0); sun.light_energy = 1.15; world.add_child(sun)
	var cam := Camera3D.new(); world.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL; cam.size = 2.6
	cam.position = Vector3(0, 1.15, 6); cam.look_at(Vector3(0, 1.1, 0))
	var holder := Node3D.new(); world.add_child(holder)
	for id in ["pumpkin_reaper", "bone_oracle", "hollow_scarecrow"]:
		for c in holder.get_children(): c.free()
		var a = Avatar.default_appearance(); a.fashion = id
		var n := Node3D.new(); holder.add_child(n); n.rotation_degrees.y = -28
		Avatar.assemble(n, a, false)
		for k in 4: await process_frame
		root.get_texture().get_image().save_png("/tmp/portrait_%s.png" % id)
	quit()
