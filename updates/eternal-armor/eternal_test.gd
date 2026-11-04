extends SceneTree

func check(passed: bool, label: String) -> void:
	if not passed:
		push_error(label)
		quit(1)
		assert(passed, label)

func _initialize() -> void:
	await process_frame
	var game = root.get_node("Game")
	var avatar := load("res://scripts/voxel/avatar.gd")
	var items := load("res://scripts/game/items.gd")
	var recipe: Dictionary = game.FASHIONS.eternal_armor.recipe
	for job in ["novice", "swordsman", "archer", "mage", "acolyte", "merchant", "thief"]:
		var appearance: Dictionary = avatar.default_appearance()
		appearance.job = job
		game.slot = 0
		game.new_character("EternalQA", appearance)
		check(not game.set_fashion("eternal_armor"), "Fashion must be locked before crafting")
		game.zeny = 20000
		for mat in recipe.mats:
			game.add_item(mat, int(recipe.mats[mat]))
		var attack: int = game.atk()
		check(game.craft(recipe), "Craft for " + job)
		check(game.zeny == 5000 and not game.can_craft(recipe), "Charge only once")
		check(game.set_fashion("eternal_armor"), "Equip for " + job)
		check(game.atk() == attack, "Cosmetic should not affect attack")
		game.save_game()
		check(game.load_game(0) and game.worn_fashion() == "eternal_armor", "Worn fashion survives reload")
		var model := Node3D.new()
		root.add_child(model)
		avatar.assemble(model, game.dressed_appearance())
		for part in ["eternal_helm", "eternal_wing_left", "eternal_wing_right"]:
			check(model.find_child(part, true, false) != null, part + " is attached")
		model.free()
		check(game.set_fashion("") and game.worn_fashion() == "", "Unequip")
	var icon: Texture2D = items.flat_icon("eternal_armor_fashion")
	check(icon.get_size() == Vector2(96, 128), "Full outfit portrait loads")
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 3:
		await process_frame
	var hud = main.get_node("HUD")
	hud._open_mage_fashion()
	var names: Array = hud._dialog_buttons.get_children().map(func(button): return button.text)
	check(names.any(func(label): return "Eternal Armor" in label), "Inventory shows the fashion")
	hud._fashion_detail("eternal_armor")
	hud._dialog_buttons.get_child(0).pressed.emit()
	check(game.worn_fashion() == "eternal_armor", "Equip through inventory")
	hud._smith_tab = 7
	hud._fill_smith()
	check(hud._smith_list.find_children("*", "Label", true, false).any(func(label): return "Eternal Armor" in label.text), "Doran lists Eternal Armor")
	print("ETERNAL ARMOR PASS")
	quit()
