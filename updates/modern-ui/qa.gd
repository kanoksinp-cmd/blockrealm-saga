extends SceneTree
var ui
func _initialize() -> void:
	call_deferred("check")
func settle() -> void:
	for i in 4: await process_frame
func fits(panel: Control) -> void:
	ui._fit_windows()
	await settle()
	var vp := root.get_visible_rect()
	var rect := panel.get_global_rect()
	assert(rect.position.x >= 0 and rect.position.y >= 0, "negative " + panel.name)
	assert(rect.end.x <= vp.end.x + 2 and rect.end.y <= vp.end.y + 2, "overflow " + panel.name + " " + str(rect) + " viewport " + str(vp))
func check() -> void:
	await process_frame
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle()
	ui = root.get_node("Game").ui
	assert(ui._modern_ready)
	var pl := get_first_node_in_group("player")
	pl.set_process(false)
	pl.set_physics_process(false)
	for win in [ui._status, ui._inv, ui._skills, ui._quests, ui._wmap, ui._party, ui._guild, ui._settings, ui._autoset, ui._menu_box]:
		ui.toggle(win.panel)
		await fits(win.panel)
		if ui._mobile:
			assert(ui._mobile_hud._ui_blocked and not ui._mobile_hud._pad.visible)
		win.panel.hide()
		await settle()
		if ui._mobile: assert(not ui._mobile_hud._ui_blocked)
	print("PASS window bounds + input lock")
	ui._status.panel.show()
	ui._character_tabs.current_tab = 2
	await settle()
	assert(ui._fashion_list.get_child_count() > 0)
	ui._inv.panel.show()
	await settle()
	assert(not ui._status.panel.visible)
	ui._bag_search.text = "no_matching_item_qax"
	ui._refresh_inventory()
	assert(ui._inv_grid.get_child_count() == 1)
	ui._bag_search.text = ""
	ui._refresh_inventory()
	print("PASS single modal + fashion + search")
	ui.open_shop("QA", ["potion_red", "potion_blue"], true)
	await fits(ui._shop.panel)
	var game := root.get_node("Game")
	game.zeny = 100000
	var count: int = game.count("potion_red")
	var price: int = game.buy_price("potion_red")
	ui._trade_shop_item("potion_red", 2)
	assert(game.count("potion_red") == count + 2 and game.zeny == 100000 - 2 * price)
	print("PASS real shop transaction")
	ui._shop_buy = false
	ui._shop_selected = "potion_red"
	ui._fill_shop()
	var before_sell: int = game.count("potion_red")
	ui._request_shop_trade()
	assert(ui._dialog.panel.visible)
	ui._dialog_buttons.get_child(1).pressed.emit()
	assert(game.count("potion_red") == before_sell and ui._shop.panel.visible)
	ui._request_shop_trade()
	ui._dialog_buttons.get_child(0).pressed.emit()
	assert(game.count("potion_red") == before_sell - 1)
	print("PASS sell confirmation / cancel")
	for tab in [0, 1, 2, 6, 7, 8, 9, 10]:
		ui.open_smith("QA", 0)
		ui._smith_tab = tab
		ui._fill_smith()
		await fits(ui._smith.panel)
	print("PASS all smith categories")
	ui.open_smith("QA", 0)
	var equipment: String = game.equip.weapon
	game.add_item(game.refine_stone(equipment), 20)
	var before: int = game.refine_lv(equipment)
	var money_before: int = game.zeny
	var cost: int = game.refine_cost(equipment)
	ui._begin_refine("weapon")
	ui._begin_refine("weapon")
	assert(not paused)
	assert(game.refine_lv(equipment) == before + 1)
	assert(game.zeny == money_before - cost)
	await create_timer(1.4).timeout
	for child in ui.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("refine_popup.gd"):
			assert(child.done)
			child.close()
	assert(not ui._refine_busy)
	print("PASS refine commits once + result + no world pause")
	ui.dialog("NPC", "บทสนทนายาวที่ต้องไม่ล้นขอบจอ\n".repeat(8), ["ตีบวก", "อาวุธ", "หมวก", "เกราะ", "ปีก", "แฟชั่น", "ซื้อหิน", "ปิด"], Callable())
	await fits(ui._dialog.panel)
	assert(ui._dialog_buttons.columns == 3)
	ui._wmap.panel.show()
	ui._fill_worldmap()
	await settle()
	var p := Vector3(12, 0, 35)
	var restored: Vector3 = ui._wmap_to_world(ui._world_to_wmap(p))
	assert(p.distance_to(restored) < 0.01)
	print("PASS dialog choices + map projection")
	root.size = Vector2i(720, 480)
	await settle()
	ui.layout_defaults()
	for win in [ui._status, ui._inv, ui._skills, ui._wmap, ui._smith, ui._shop, ui._quests]:
		win.panel.show()
		await fits(win.panel)
		win.panel.hide()
	print("PASS narrow landscape responsive bounds")
	if ui._mobile:
		ui._wmap.panel.show()
		ui._mobile_hud._joy_idx = 1
		ui._mobile_hud._touches[1] = {"mode":"joy"}
		ui._wmap.panel.hide()
		assert(ui._mobile_hud._joy_idx == -1 and ui._mobile_hud._touches.is_empty())
	print("PASS_UI_REDESIGN mobile=", ui._mobile)
	quit()
