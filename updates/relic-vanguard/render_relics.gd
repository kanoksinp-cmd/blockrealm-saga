extends SceneTree

func _initialize() -> void:
	await process_frame
	root.transparent_bg = true
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var light := Environment.new()
	light.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	light.ambient_light_color = Color("#dce6ff")
	light.ambient_light_energy = 0.75
	env.environment = light
	world.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-34, 26, 0)
	key.light_energy = 1.25
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-22, -62, 0)
	fill.light_color = Color("#b7e8ff")
	fill.light_energy = 0.24
	world.add_child(fill)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.9
	camera.position = Vector3(0, 1.12, 12)
	camera.look_at(Vector3(0, 1.12, 0))
	var avatar := load("res://scripts/voxel/avatar.gd")
	var relic := load("res://scripts/voxel/relic_fashion.gd")
	var centers := {}
	var i := 0
	for id in relic.TINTS:
		var d: Array = relic.TINTS[id]
		var model := Node3D.new()
		world.add_child(model)
		model.position = Vector3((float(i % 4) - 1.5) * 3.25, (1 - floori(i / 4.0)) * 2.78, 0)
		model.rotation_degrees.y = -24.0
		var look: Dictionary = avatar.default_appearance()
		look.fashion = id
		look.weapon_sprite = "bow" if d[7] == "bow" else "none"
		var rig: Dictionary = avatar.assemble(model, look, true)
		rig.arm_r.rotation_degrees = Vector3(-24, 0, -24)
		rig.arm_l.rotation_degrees = Vector3(-22, 0, 18)
		rig.weapon.rotation_degrees = Vector3(9, 0, 55 if d[7] in ["sword", "rapier", "saw", "hammer", "axe"] else 17)
		if d[7] == "bow":
			rig.weapon.rotation_degrees = Vector3(25, 15, -24)
		var center := camera.unproject_position(model.position + Vector3(0, 1.12, 0))
		centers[id] = [center.x, center.y]
		i += 1
	for frame in 14:
		await process_frame
	var output := OS.get_environment("RELIC_OUT")
	root.get_texture().get_image().save_png(output.path_join("render_grid.png"))
	FileAccess.open(output.path_join("centers.json"), FileAccess.WRITE).store_string(JSON.stringify(centers))
	quit()
