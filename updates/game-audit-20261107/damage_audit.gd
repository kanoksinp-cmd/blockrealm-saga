extends SceneTree
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	await process_frame
	var fx := load("res://scripts/combat/fx.gd")
	var settings := root.get_node("Settings")
	settings.set_value("damage_numbers", true)
	var scene := Node3D.new()
	root.add_child(scene)
	current_scene = scene
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(0, 2, 7)
	camera.look_at(Vector3.ZERO)
	var target = load("res://scripts/monsters/slime.gd").new()
	target.max_hp = 6000
	target.def = 15
	scene.add_child(target)
	target.set_physics_process(false)
	target.take_damage(243)
	target.take_damage(1219, null, true)
	fx.popup(target, Vector3(0, 1, 0), "Miss", Color.LIGHT_GRAY)
	var layer := scene.get_node("CombatDamagePopups")
	var items := layer.get_children()
	check(items.size() == 3, "three separate hits")
	if items.size() == 3:
		check(items[0]._text == "228" and items[0]._ink == Color("#fffdf4"), "normal hit shows damage after DEF")
		check(items[1]._text == "1204" and items[1]._crit and items[1]._burst_outer.size() > 0, "critical has burst")
		check(items[2]._text == "MISS", "classic miss")
		check(items.map(func(n): return n.lane) == [0, 1, 2], "hits spread across lanes")
	check(target.hp == 4568, "combat HP subtraction matches displayed values")
	fx.popup(target, Vector3(1, 1, 0), "128", Color(1.0, 0.3, 0.25))
	fx.popup(target, Vector3(-1, 1, 0), "12", Color(0.6, 0.95, 0.3))
	check(layer.get_child(3)._ink == Color("#ff615d"), "incoming damage red")
	check(layer.get_child(4)._ink == Color("#a4ec66"), "poison green")
	settings.set_value("damage_numbers", false)
	fx.popup(target, Vector3.ZERO, "Miss", Color.WHITE)
	fx.popup(target, Vector3.ZERO, "200!", Color.WHITE)
	check(layer.get_child_count() == 5, "damage toggle disables all combat popups")
	fx.popup(target, Vector3.ZERO, "+30 EXP", Color.WHITE)
	check(scene.get_children().any(func(n): return n is Label3D and "EXP" in n.text), "noncombat label still exists")
	await create_timer(load("res://scripts/combat/damage_popup.gd").DURATION + 0.2).timeout
	check(layer.get_child_count() == 0, "expired combat popups free themselves")
	print("RO DAMAGE ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
