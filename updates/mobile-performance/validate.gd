extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	await process_frame
	var settings = root.get_node("Settings")
	var mobile := OS.get_environment("BR_MOBILE") == "1"
	assert(settings.is_mobile() == mobile)
	settings.data["shadows"] = 2
	settings.data["msaa"] = 2
	settings.data["render_scale"] = 0.75
	settings.apply()
	assert(settings.g("shadows") == (0 if mobile else 2))
	assert(settings.g("msaa") == (0 if mobile else 2))
	assert(settings.data["shadows"] == 2)
	assert(settings.data["render_scale"] == 0.75)
	assert(Engine.max_fps == (30 if mobile else 0))
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	var monster := Node3D.new()
	monster.add_to_group("monster")
	world.add_child(monster)
	var script = load("res://scripts/combat/hp_bar_3d.gd")
	var bar = script.new()
	monster.add_child(bar)
	bar.set_ratio(0.5)
	cam.rotation.y = 1.2
	bar._process(0.1)
	assert(is_equal_approx(bar.global_basis.x.length(), 0.62 if mobile else 1.0))
	assert(is_equal_approx(bar._fg.scale.x, 0.5))
	var hero := Node3D.new()
	world.add_child(hero)
	var hero_bar = script.new()
	hero.add_child(hero_bar)
	hero_bar._process(0.1)
	assert(is_equal_approx(hero_bar.global_basis.x.length(), 1.0))
	var particles := CPUParticles3D.new()
	particles.amount = 100
	world.add_child(particles)
	var light := OmniLight3D.new()
	light.shadow_enabled = true
	world.add_child(light)
	await process_frame
	assert(particles.amount == (32 if mobile else 100))
	assert(light.shadow_enabled == not mobile)
	var icon = load(ProjectSettings.get_setting("application/config/icon")) as Texture2D
	assert(icon != null and icon.get_width() == 512)
	icon.get_image().save_png(OS.get_environment("BR_ICON_OUT"))
	# Load the current title scene as a regression against unrelated packed content.
	world.queue_free()
	await process_frame
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for i in 12:
		await process_frame
	print("PASS mobile=", mobile, " HP, settings, particles, icon, current scene")
	quit()
