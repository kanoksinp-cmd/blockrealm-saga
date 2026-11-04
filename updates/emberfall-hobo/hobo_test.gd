extends SceneTree
var failed := false

func verify(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failed = true



func _initialize() -> void:
	await process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	var world = main.get_node("StarterVillage")
	var spawner = main.get_node("Monsters")
	verify(not spawner.get_children().any(func(m): return m.display_name == "Hobo"), "No Hobo in town")
	world.ensure_area("ember")
	var pack: Array = spawner.get_children().filter(func(m): return m.display_name == "Hobo")
	verify(pack.size() == 4, "Four monsters spawn in Emberfall")
	world.ensure_area("ember")
	verify(spawner.get_children().filter(func(m): return m.display_name == "Hobo").size() == 4, "Map revisit does not duplicate spawns")
	for m in pack:
		var pos: Vector3 = m.global_position
		verify(m.get_meta("area") == "ember" and world.area_at(pos) == "ember", "Correct area")
		verify(world.walkable(pos.x, pos.z), "Walkable spawn at %s" % pos)
		verify(m.level == 53 and m.hp == m.max_hp and m.exp_reward > 0, "Stats and EXP")
		verify(m._rig.legs.size() == 4 and m._rig.tails.size() == 1 and m._jaw != null, "Model rig")
		for drop in m.drops:
			verify(not load("res://scripts/game/items.gd").info(drop[0]).is_empty(), "Drop exists: " + drop[0])
		print("Hobo spawn ", pos, ", HP ", m.hp, ", EXP ", m.exp_reward)
	var first = pack[0]
	first._enter(first.State.ATTACK)
	first._state_t = 0.4
	first._animate(0.2)
	verify(first._jaw.rotation.x > 0.5, "Jaw opens for attack")
	first._state_t = 0.65
	first._animate(0.2)
	verify(first._jaw.rotation.x < 0.12, "Jaw closes after hit")
	first.take_damage(first.max_hp + first.def + 1)
	verify(not first.is_alive(), "Monster dies")
	first._respawn()
	verify(first.is_alive() and first.hp == first.max_hp and first.global_position.distance_to(first.home) < 3.0, "Monster respawns at home")
	print("HOBO FAIL" if failed else "HOBO PASS")
	quit(1 if failed else 0)
