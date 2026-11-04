extends SceneTree

func _initialize() -> void:
	await process_frame
	root.transparent_bg = true
	var avatar := load("res://scripts/voxel/avatar.gd")
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var lighting := Environment.new()
	lighting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lighting.ambient_light_color = Color(0.83, 0.92, 1.0)
	lighting.ambient_light_energy = 0.85
	environment.environment = lighting
	world.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32, 27, 0)
	key.light_energy = 1.28
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, -70, 0)
	fill.light_color = Color("#6ecde8")
	fill.light_energy = 0.28
	world.add_child(fill)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.08
	camera.position = Vector3(0, 1.6, 6)
	camera.look_at(Vector3(0, 1.13, 0))
	var appearance: Dictionary = avatar.default_appearance()
	appearance.fashion = "eternal_armor"
	var model := Node3D.new()
	world.add_child(model)
	avatar.assemble(model, appearance, false)
	for angle in [-13, 25, 166]:
		model.rotation_degrees.y = angle
		for frame in 6:
			await process_frame
		root.get_texture().get_image().save_png(OS.get_environment("ETERNAL_OUT").path_join("armor_%s.png" % angle))
	quit()
