extends SceneTree
var ui
var output: String
func _initialize() -> void:
	call_deferred("check")
func frames(count := 5) -> void:
	for i in count: await process_frame
func shot(name: String) -> void:
	await frames(5)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	print("PREVIEW ", name, " vp=", root.get_visible_rect().size)
func check() -> void:
	await process_frame
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(3)
	root.mode = Window.MODE_WINDOWED
	root.min_size = Vector2i(0, 0)
	root.size = Vector2i(1055, 488)
	await frames(4)
	ui = root.get_node("Game").ui
	output = OS.get_environment("BR_PREVIEW_DIR")
	DirAccess.make_dir_recursive_absolute(output)
	var player := get_first_node_in_group("player")
	player.set_process(false)
	player.set_physics_process(false)
	ui.layout_defaults()
	await shot("01-hud")
	for entry in [["02-character", ui._status], ["03-inventory", ui._inv], ["04-skills", ui._skills], ["05-quests", ui._quests], ["06-map", ui._wmap], ["07-settings", ui._settings], ["08-party", ui._party], ["09-guild", ui._guild]]:
		ui.toggle(entry[1].panel)
		await shot(entry[0])
		entry[1].panel.hide()
	ui.open_smith("Blacksmith Doran")
	await shot("10-smith")
	ui.open_shop("Potion Merchant", ["potion_red", "potion_blue"], true)
	await shot("11-shop")
	ui.dialog("ช่างตีเหล็กโดแรน", "เลือกบริการที่ต้องการได้เลย\nตีบวกอุปกรณ์หรือคราฟจากวัตถุดิบที่รวบรวมมา", ["ตีบวก", "คราฟอาวุธ", "คราฟหมวก", "คราฟเกราะ", "คราฟปีก", "ชุดแฟชั่น", "ซื้อหิน", "ปิด"], Callable())
	await shot("12-npc")
	ui._dialog.panel.hide()
	ui._show_chat()
	await shot("13-chat")
	print("PASS rendered previews")
	quit()
