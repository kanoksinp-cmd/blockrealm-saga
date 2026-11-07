extends SceneTree
func _initialize() -> void: call_deferred("check")
func frames(n: int) -> void:
	for i in n: await process_frame
func check() -> void:
	await process_frame
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(5)
	root.mode = Window.MODE_WINDOWED
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1055,488)
	var player = get_first_node_in_group("player")
	player.set_process(false)
	player.set_physics_process(false)
	var rig = get_first_node_in_group("camera_rig")
	rig.distance = 27.0
	rig._dist_goal = 27.0
	rig.pitch_deg = -48
	rig.yaw_deg = -15
	var village = scene.get_node("StarterVillage")
	for area in ["desert", "verdant"]:
		village.ensure_area(area)
		var plots: Array = village.worlds[area].get_meta("ruin_plots")
		var center: Vector2 = plots[0].get_center()
		player.global_position = Vector3(center.x,0.2,center.y+1)
		rig.snap()
		await frames(10)
		var day = get_first_node_in_group("daynight")
		day.hour = 10.5
		day.set_process(false)
		day._apply(2.0)
		await frames(6)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join(area+"-mobile.png"))
		print("PASS_RENDER ",area)
	# Verify camera-to-player cutaway on the actual rendered world material.
	var settings_for_cutaway = root.get_node("Settings")
	settings_for_cutaway._mobile = true
	var pixel = load("res://scripts/voxel/pixel_tex.gd")
	rig.set_process(false)
	var wall := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(7, 6, 1)
	wall.mesh = mesh
	wall.material_override = pixel.solid_material()
	scene.add_child(wall)
	wall.global_position = player.global_position + Vector3(0, 2.5, 2)
	for enabled in [false, true]:
		settings_for_cutaway.data.xray = enabled
		rig._apply()
		var target: Vector3 = pixel.solid_material().get_shader_parameter("player_pos")
		assert(target.y > -999 if enabled else target.y < -999)
		await frames(3)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join("cutaway-" + str(enabled) + ".png"))
	wall.queue_free()
	print("PASS_CUTAWAY mobile toggle updates solid and plant materials")
	# Exercise all element meshes, particles and their cleanup without changing damage.
	var effects = load("res://scripts/combat/element_fx.gd")
	var settings = root.get_node("Settings")
	for mobile in [false,true]:
		settings._mobile = mobile
		for element in effects.ELEMENTS:
			effects.circle(player,element,player.global_position,1.5,0.5)
			effects.impact(player,element,player.global_position+Vector3(3,0,0),1.2)
		await frames(5)
		var holders := get_nodes_in_group("readable_impacts")
		assert(holders.size() <= 24)
		if mobile:
			for holder in holders:
				for node in holder.get_children():
					if node is CPUParticles3D: assert(node.amount <= 40)
		await create_timer(3.0).timeout
		assert(get_nodes_in_group("readable_impacts").is_empty())
		assert(get_nodes_in_group("readable_circles").is_empty())
	print("PASS_FX all elements, both profiles and timer cleanup")
	quit()
