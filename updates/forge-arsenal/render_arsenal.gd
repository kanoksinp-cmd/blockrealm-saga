extends SceneTree

func _initialize() -> void:
	await process_frame
	root.transparent_bg = true
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var lighting := Environment.new()
	lighting.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lighting.ambient_light_color = Color("#dce8ff")
	lighting.ambient_light_energy = 0.78
	env.environment = lighting
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.25
	light.rotation_degrees = Vector3(-30, 30, 0)
	world.add_child(light)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 4.65
	cam.position = Vector3(0, 0, 9)
	var data := load("res://scripts/voxel/forge_arsenal.gd")
	var coords := {}
	var i := 0
	for id in data.SPRITES:
		var mesh: MeshInstance3D = data.model(id)
		var holder := Node3D.new()
		world.add_child(holder)
		var center := mesh.mesh.get_aabb().get_center()
		holder.add_child(mesh)
		mesh.position = -center
		holder.position = Vector3((float(i % 6) - 2.5) * 1.38, 1.04 if i < 6 else -1.04, 0)
		holder.rotation_degrees = Vector3(9, -25, 16)
		var p := cam.unproject_position(holder.position)
		coords[id] = [p.x, p.y]
		i += 1
	for frame in 8:
		await process_frame
	var output := OS.get_environment("ARSENAL_OUT")
	root.get_texture().get_image().save_png(output.path_join("arsenal_grid.png"))
	FileAccess.open(output.path_join("centers.json"), FileAccess.WRITE).store_string(JSON.stringify(coords))
	quit()
