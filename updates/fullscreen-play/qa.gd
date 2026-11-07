extends SceneTree
func _initialize() -> void: call_deferred("check")
func frames(count := 5) -> void:
	for i in count: await process_frame
func check() -> void:
	await process_frame
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames()
	var ui = root.get_node("Game").ui
	ui.layout_defaults()
	await frames()
	var mobile := OS.get_environment("BR_MOBILE") == "1"
	if mobile:
		assert(ui.get_script().resource_path == "res://scripts/ui/ro_ui_mobile.gd")
		assert(ui._menu.get_child_count() == 4)
		assert(is_equal_approx(ui._info_panel.scale.x, 0.86))
		assert(not ui._menu.get_child(0).visible)
		assert(ui._party_collapsed)
		var rect: Rect2 = ui._tracker.panel.get_global_rect()
		assert(rect.size.y < 110, "tracker too tall " + str(rect))
		assert(rect.position.x > root.get_visible_rect().size.x * 0.7)
		assert(rect.end.x <= root.get_visible_rect().size.x)
		assert(rect.end.y <= ui._mobile_hud.pad_top() + 4, "tracker touches skills " + str(rect))
		ui._qauto_btn.set_pressed_no_signal(false)
		ui._qauto_btn.pressed.emit() # No invalid callback on the new toggle button.
		ui._qauto_btn.button_pressed = true
		await frames(3)
		assert(ui._tracker.panel.get_global_rect().size.y < 110)
		ui._qauto_btn.button_pressed = false
	else:
		assert(ui.get_script().resource_path == "res://scripts/ui/ro_ui.gd")
		assert(ui._menu.get_child_count() == 6, "PC must retain six classic icon buttons")
		assert(ui.get("_modern_ready") == null)
		assert(is_equal_approx(ui._info_panel.scale.x, 1.0))
	ui.toggle(ui._inv.panel)
	await frames()
	assert(ui._inv.panel.visible)
	ui._inv.panel.hide()
	if mobile: assert(not ui._mobile_hud._ui_blocked)
	var hub = root.get_node_or_null("AudioHub")
	assert(hub != null)
	for bus in ["Master", "Music", "SFX", "Ambient"]:
		assert(AudioServer.get_bus_index(bus) >= 0)
	assert(ResourceLoader.exists("res://assets/audio/music/town.ogg"))
	assert(ResourceLoader.exists("res://assets/audio/sfx/ui_click.wav"))
	print("PASS_LAYOUT_AUDIO mobile=", mobile)
	quit()
