extends SceneTree

func _initialize() -> void:
	await process_frame
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	var world = scene.get_node("StarterVillage")
	var baseline := OS.get_environment("STALL_BASELINE") == "1"
	var failures := 0
	for stall in [[11, 5, 3], [11, -5, 3], [-12, 5, 1], [-12, -5, 1]]:
		var roofs := 0
		var obstacles := 0
		var walkable := 0
		for x in range(-1, 2):
			for z in range(-1, 2):
				var p: Vector2i = world._lw(stall[0], stall[1], stall[2], x, z)
				roofs += int(world.w.getb(p.x, 3, p.y) in [20, 21, 22, 23, 24])
				obstacles += int(world.w.getb(p.x, 0, p.y) != 0)
				walkable += int(world.walkable(p.x + 0.5, p.y + 0.5))
		print("Plaza spot ", stall, ": ", roofs, " roof blocks, ", obstacles, " obstacles, ", walkable, " walkable")
		if stall[0] == -12 and stall[1] == -5:
			failures += int(roofs != 0 or obstacles != 3 or walkable != 6)
		elif baseline:
			failures += int(roofs != 9 or obstacles == 0)
		else:
			failures += int(roofs != 0 or obstacles != 0 or walkable != 9)
	var potion := scene.find_child("PotionStall", true, false)
	print("Potion merchant stall present: ", potion != null)
	failures += int(potion == null)
	print("STALL REMOVAL ", "PASS" if failures == 0 else "FAIL")
	if OS.get_environment("STALL_RENDER") != "":
		var camera := Camera3D.new()
		scene.add_child(camera)
		scene.get_node("CameraRig").process_mode = Node.PROCESS_MODE_DISABLED
		scene.get_node("HUD").hide()
		camera.position = Vector3(7, 24, 17)
		camera.look_at(Vector3(0, 0, 0))
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 19.5
		camera.make_current()
		for frame in 24:
			await process_frame
		root.get_texture().get_image().save_png(OS.get_environment("STALL_RENDER"))
	quit(1 if failures else 0)
