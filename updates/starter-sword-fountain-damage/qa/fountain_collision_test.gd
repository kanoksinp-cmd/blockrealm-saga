extends SceneTree
func _initialize():
	await process_frame
	var Game = root.get_node("Game")
	Game.slot = 0; Game.new_character("F", load("res://scripts/voxel/avatar.gd").default_appearance())
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main); current_scene = main
	for i in 3: await process_frame
	var vb = main.get_node("StarterVillage")
	var space = main.get_world_3d().direct_space_state
	for z in range(-5, 5):
		var line := ""
		for x in range(-5, 5):
			var q := PhysicsRayQueryParameters3D.create(Vector3(x + 0.5, 3, z + 0.5), Vector3(x + 0.5, 0.05, z + 0.5))
			var hit = space.intersect_ray(q)
			var solid_phys: bool = hit and hit.position.y > 0.3
			var walk: bool = vb.walkable(x + 0.5, z + 0.5)
			line += ("#" if solid_phys else ".") + ("w" if walk else "x") + " "
		print(line)
	quit()
