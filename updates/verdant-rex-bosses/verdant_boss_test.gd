extends SceneTree
var failures := 0

func verify(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	await process_frame
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	var world = main.get_node("StarterVillage")
	var spawner = main.get_node("Monsters")
	var is_rex := func(m): return m.display_name in ["Ashfang Rex", "Mossjaw Rex"]
	verify(not spawner.get_children().any(is_rex), "No new bosses in town")
	world.ensure_area("verdant")
	world.ensure_area("verdant")
	var bosses: Array = spawner.get_children().filter(is_rex)
	verify(bosses.size() == 2, "Two bosses total after revisit")
	var specs := {"Ashfang Rex": 70, "Mossjaw Rex": 60}
	for boss_name in specs:
		var matches: Array = bosses.filter(func(m): return m.display_name == boss_name)
		verify(matches.size() == 1, "Exactly one " + boss_name)
		if matches.size() != 1:
			continue
		var m = matches[0]
		var pos: Vector3 = m.global_position
		verify(m.level == specs[boss_name] and m.has_meta("boss") and m.get_meta("area") == "verdant", "Boss identity")
		verify(world.area_at(pos) == "verdant" and world.walkable(pos.x, pos.z), "Boss appears on Verdant ground")
		for x in range(-3, 4):
			for z in range(-3, 4):
				verify(world.walkable(pos.x + x, pos.z + z), "Lair floor clear near %s" % pos)
		verify(m._rig.legs.size() == 2 and m._rig.arms.size() == 2 and m._tail_end != null, "Biped and tail rig")
		m._enter(m.State.ATTACK)
		m._state_t = m.attack_time * 0.37
		m._animate(0.24)
		verify(m._jaw.rotation.x > 0.6, "Jaw opens in windup")
		m._state_t = m.hit_time
		m._animate(0.24)
		verify(m._jaw.rotation.x < 0.15, "Jaw closes at bite")
		print(boss_name, " Lv", m.level, ", HP ", m.max_hp, ", EXP ", m.exp_reward, ", respawn ", m.respawn_time, "s at ", pos)
		m.take_damage(m.max_hp + m.def + 1)
		verify(not m.is_alive(), "Death via damage")
		m._respawn()
		verify(m.is_alive() and m.hp == m.max_hp and m.global_position.distance_to(pos) < 3.0, "Boss respawns near its lair")
	if bosses.size() == 2:
		verify(bosses[0].home.distance_to(bosses[1].home) > bosses[0].leash_range + bosses[1].leash_range, "Bosses cannot roam into each other's lair")
	verify(spawner.get_children().any(func(m): return m.display_name == "Great Moss Toad"), "Great Moss Toad still present")
	print("VERDANT BOSSES ", "PASS" if failures == 0 else "FAIL")
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)
