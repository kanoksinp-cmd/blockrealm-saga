extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var player = get_first_node_in_group("player")
	player.set_process(false)
	player.set_physics_process(false)
	var panel = null
	for child in scene.get_node("HUD").get_children()[0].get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("target_profile.gd"):
			panel = child
	assert(panel != null)
	assert(not panel.visible)
	var monsters = get_nodes_in_group("monster")
	assert(monsters.size() > 1)
	var monster = monsters[0]
	player.attack_target = monster
	panel._process(0)
	assert(panel.visible and panel.target == monster)
	assert(panel.holder.get_child_count() > 0)
	monster.hp = maxi(1, monster.max_hp / 2)
	panel._process(0)
	assert(int(panel.health.value) == monster.hp)
	player.attack_target = monsters[1]
	panel._process(0)
	assert(panel.target == monsters[1])
	player.attack_target = null
	panel._process(0)
	assert(not panel.visible)
	player.attack_target = monster
	monster.hp = 0
	monster.state = 4 # Monster.State.DEAD, as set by the combat death path.
	panel._process(0)
	assert(not panel.visible)
	print("PASS: target portrait, HP updates, target switch, cleared and dead targets")
	quit()
