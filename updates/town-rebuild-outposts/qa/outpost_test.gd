extends SceneTree
func _initialize():
	await process_frame
	var Game = root.get_node("Game")
	Game.slot = 0; Game.new_character("Out", load("res://scripts/voxel/avatar.gd").default_appearance())
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main); current_scene = main
	for i in 3: await process_frame
	var vb = main.get_node("StarterVillage")
	var VB = vb.get_script()
	var areas := ["verdant","desert","frost","ember","verdant_d","desert_d","frost_d","ember_d","chivalry_d","abyss_d","valhalla_d"]
	var ok := 0
	for a in areas:
		var t := Time.get_ticks_msec()
		vb.ensure_area(a)
		var root3: Node = vb.get_node_or_null("Area_" + a)
		var roles := {}
		var npos := {}
		for n in root3.get_children():
			if n.get("role") in ["smith", "shop"] and String(n.get("npc_name")) in ["Wandering Smith Garrick", "Peddler Lina"]:
				roles[n.role] = true; npos[n.role] = n.position
		var entry: Vector2 = VB.area_entry(a)
		var reach := true
		for r in npos:
			var path: PackedVector3Array = vb.find_path(Vector3(entry.x, 0, entry.y), npos[r])
			if path.size() < 2 and Vector2(npos[r].x, npos[r].z).distance_to(entry) > 2.0: reach = false
		var good: bool = roles.size() == 2 and reach
		if good: ok += 1
		print("%s: npcs=%s reachable=%s dist=%.1f ms=%d" % [a, roles.keys(), reach, (Vector2(npos.get("smith", Vector3()).x, npos.get("smith", Vector3()).z)).distance_to(entry), Time.get_ticks_msec() - t])
	print("OUTPOSTS_OK=", ok, "/", areas.size())
	quit()
