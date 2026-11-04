extends SceneTree

func _initialize() -> void:
	await process_frame
	var world := Node3D.new()
	root.add_child(world)
	var lights := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#182321")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#f0f1de")
	environment.ambient_light_energy = 0.7
	lights.environment = environment
	world.add_child(lights)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-32, -33, 0)
	key.light_energy = 1.12
	world.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-26, 152, 0)
	rim.light_color = Color("#b8e2a6")
	rim.light_energy = 0.45
	world.add_child(rim)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.0
	var rex := load("res://scripts/monsters/verdant_rex.gd")
	for ash in [true, false]:
		var monster = rex.new(ash)
		monster.size = 1.25 if ash else 1.08
		world.add_child(monster)
		monster.set_physics_process(false)
		monster.model.rotation = Vector3.ZERO
		monster._jaw.rotation.x = 0.44
		camera.position = Vector3(5.6, 2.9, 3.9) if ash else Vector3(4.1, 3.1, 4.5)
		camera.look_at(Vector3(0, 1.2, -0.25))
		for frame in 9:
			await process_frame
		root.get_texture().get_image().save_png(OS.get_environment("BOSS_OUT").path_join(monster.species + ".png"))
		monster.free()
	quit()
