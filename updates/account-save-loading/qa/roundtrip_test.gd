extends SceneTree
func _initialize():
	await process_frame
	var Game = root.get_node("Game"); var Store = load("res://scripts/game/account_save_store.gd")
	Game.slot = 0; Game.new_character("Test", load("res://scripts/voxel/avatar.gd").default_appearance()); Game.base_level = 50; Game.zeny = 79275; Game.save_game()
	var parsed = JSON.parse_string(JSON.stringify(Store.capture("")))
	var a = Store.sanitize(parsed)
	print("last ", parsed.last_slot, " vs ", a.last_slot)
	for k in parsed.slots[0]:
		if JSON.stringify(parsed.slots[0][k]) != JSON.stringify(a.slots[0][k]): print("DIFF ", k, " ", JSON.stringify(parsed.slots[0][k]).left(60), " -> ", JSON.stringify(a.slots[0][k]).left(60))
	quit()
