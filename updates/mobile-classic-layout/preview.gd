extends SceneTree
func _initialize() -> void: call_deferred("check")
func frames(n:=5) -> void:
	for i in n: await process_frame
func shot(name: String) -> void:
	await frames(5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join(name+".png"))
func check() -> void:
	await process_frame
	var game = root.get_node("Game")
	game.party = load("res://scripts/game/party.gd").candidates().slice(0,3)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames()
	root.mode = Window.MODE_WINDOWED
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1055,488)
	await frames()
	var ui = game.ui
	ui.layout_defaults()
	await frames()
	print("METRICS vp=",root.get_visible_rect().size," info=",ui._info_panel.get_global_rect()," menu=",ui._menu.get_global_rect()," tracker=",ui._tracker.panel.get_global_rect()," party=",ui._party_frame.get_global_rect())
	assert(ui._menu.get_child_count()==6)
	for button in ui._menu.get_children(): assert(button.get_global_rect().size.y >= 54)
	assert(not ui._menu.get_global_rect().intersects(ui._info_panel.get_global_rect()))
	assert(ui._tracker.panel.get_global_rect().end.y < ui._mobile_hud.pad_top())
	await shot("01-mobile-classic")
	for entry in [["02-bag",ui._inv],["03-character",ui._status],["04-skills",ui._skills],["05-settings",ui._settings]]:
		ui.toggle(entry[1].panel)
		await frames(10)
		assert(ui._mobile_hud._ui_blocked)
		var rect: Rect2 = entry[1].panel.get_global_rect()
		assert(rect.end.x <= root.get_visible_rect().size.x+1, "window width "+str(rect))
		assert(rect.end.y <= root.get_visible_rect().size.y+1, "window height "+str(rect))
		assert(entry[1].panel.scale==Vector2.ONE)
		await shot(entry[0])
		entry[1].panel.hide()
		await frames()
		assert(not ui._mobile_hud._ui_blocked)
	ui.dialog("ช่างตีเหล็กโดแรน","เลือกบริการที่ต้องการ\nตีบวกอุปกรณ์และคราฟจากวัตถุดิบที่สะสม",["ตีบวก","คราฟอาวุธ","คราฟหมวก","คราฟเกราะ","คราฟปีก","ชุดแฟชั่น","ซื้อหิน","ปิด"],Callable())
	await frames(10)
	await shot("06-npc")
	assert(ui._dialog_buttons.get_child_count()==8)
	ui._dialog.panel.hide()
	ui._mobile_hud._toggle_chat()
	await frames()
	await shot("07-chat")
	ui._mobile_hud._toggle_chat()
	root.size=Vector2i(844,450)
	await frames()
	ui.layout_defaults()
	await frames()
	await shot("08-compact")
	assert(not ui._menu.get_global_rect().intersects(ui._info_panel.get_global_rect()))
	print("PASS_CLASSIC_MOBILE six menus, dock, modal blocking, unscaled scroll windows, dialogue and chat")
	quit()
