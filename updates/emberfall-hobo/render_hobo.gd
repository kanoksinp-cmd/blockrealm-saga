extends SceneTree

func _initialize() -> void:
	await process_frame
	var world := Node3D.new()
	root.add_child(world)
	var lights := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#15121d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#ffd9c3")
	environment.ambient_light_energy = 0.64
	lights.environment = environment
	world.add_child(lights)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-36, -36, 0)
	key.light_energy = 1.17
	world.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-38, 144, 0)
	rim.light_color = Color("#ff8954")
	rim.light_energy = 0.68
	world.add_child(rim)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.02
	cam.position = Vector3(4.6, 2.6, 3.5)
	cam.look_at(Vector3(0, 0.6, -0.1))
	var m = load("res://scripts/monsters/hobo.gd").new()
	world.add_child(m)
	m.set_physics_process(false)
	m.model.rotation = Vector3.ZERO
	m._jaw.rotation.x = 0.27
	for frame in 12:
		await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("HOBO_OUT").path_join("hobo_preview.png"))
	quit()
