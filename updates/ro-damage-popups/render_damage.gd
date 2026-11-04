extends SceneTree

func _initialize() -> void:
	await process_frame
	root.get_node("Settings").set_value("damage_numbers", true)
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var environment := WorldEnvironment.new()
	var light := Environment.new()
	light.background_mode = Environment.BG_COLOR
	light.background_color = Color("#252c27")
	light.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	light.ambient_light_color = Color("#c9e9dc")
	light.ambient_light_energy = 0.67
	environment.environment = light
	world.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-43, 30, 0)
	key.light_energy = 1.25
	world.add_child(key)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 3, 8)
	camera.look_at(Vector3(0, 0.95, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.6
	var fx := load("res://scripts/combat/fx.gd")
	var slime := load("res://scripts/monsters/slime.gd")
	var colors := [Color("#78b94c"), Color("#58a4dc"), Color("#ca5b3e"), Color("#b584d7")]
	for i in 4:
		var m = slime.new()
		m.position = Vector3((i - 1.5) * 1.75, 0, 0)
		m.color = colors[i]
		m.max_hp = 4000
		world.add_child(m)
		m.set_physics_process(false)
		var pos: Vector3 = m.global_position + Vector3(0, 1.35, 0)
		match i:
			0: fx.popup(m, pos, "328", Color.WHITE)
			1: fx.popup(m, pos, "1248!", Color("#ffd640"))
			2: fx.popup(m, pos, "162", Color("#ff553f"))
			3: fx.popup(m, pos, "Miss", Color.LIGHT_GRAY)
	await create_timer(0.16).timeout
	root.get_texture().get_image().save_png(OS.get_environment("RO_DAMAGE_OUT").path_join("damage_full.png"))
	quit()
