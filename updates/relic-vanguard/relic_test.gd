extends SceneTree
var failures := 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _initialize() -> void:
	await process_frame
	var game = root.get_node("Game")
	var avatar := load("res://scripts/voxel/avatar.gd")
	var relic := load("res://scripts/voxel/relic_fashion.gd")
	var items := load("res://scripts/game/items.gd")
	var look: Dictionary = avatar.default_appearance()
	look.job = "archer"
	game.slot = 0
	game.new_character("Relic QA", look)
	game.zeny = 600000
	var attack: int = game.atk()
	var item_weapon = game.equip.get("weapon")
	var ids: Array = relic.TINTS.keys()
	check(ids.size() == 12 and game.FASHION_ORDER.slice(0, 12) == ids, "All twelve at top of fashion catalog")
	for id in ids:
		var recipe: Dictionary = game.FASHIONS[id].recipe
		for job in ["novice", "swordsman", "archer", "mage", "acolyte", "merchant", "thief"]:
			check(game.FASHIONS[id].jobs.is_empty(), "Available to " + job)
		check(not game.set_fashion(id), "Locked before crafting " + id)
		for mat in recipe.mats:
			game.add_item(mat, int(recipe.mats[mat]))
		var zeny: int = game.zeny
		check(game.craft(recipe) and game.zeny == zeny - 12000, "Crafts whole set once " + id)
		check(not game.can_craft(recipe) and game.owns_fashion(id), "No repeat charge " + id)
		check(game.set_fashion(id) and game.atk() == attack and game.equip.get("weapon") == item_weapon, "Only appearance changes " + id)
		var body := Node3D.new()
		root.add_child(body)
		var rig: Dictionary = avatar.assemble(body, game.dressed_appearance(), true)
		var weapon := body.find_child("RelicWeapon", true, false)
		check(body.find_child("relic_helm", true, false) != null and body.find_child("relic_body", true, false) != null, "Full armor " + id)
		check(weapon != null and weapon.get_parent() == rig.weapon and weapon.get_child_count() >= 3, "Matching weapon follows rig " + id)
		check((body.find_child("RelicShield", true, false) != null) == (relic.TINTS[id][8] == "shield"), "Offhand matches " + id)
		for child in rig.weapon.find_children("*", "MeshInstance3D", true, false):
			check(child.visible == weapon.is_ancestor_of(child), "Only skin visible " + id)
		var icon: Texture2D = items.icon(recipe.id)
		check(icon.get_size() == Vector2(96, 128), "Outfit portrait " + id)
		body.free()
		print("PASS ", id)
	game.save_game()
	check(game.load_game(0) and game.worn_fashion() == ids.back(), "Worn set survives reload")
	check(game.fashion_unlocks.size() == 12, "All crafted sets survive reload")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 3:
		await process_frame
	var hud = main.get_node("HUD")
	hud._open_mage_fashion()
	check("Crimson Bastion" in hud._dialog_text.text, "Latest collection first in inventory")
	hud._dialog_buttons.get_child(3).pressed.emit()
	check("Cinder Ranger" in hud._dialog_text.text, "Next page reachable")
	hud._open_mage_fashion(5)
	check("Celestial Falcon" in hud._dialog_text.text, "Last Relic set reachable")
	hud._dialog_buttons.get_child(0).pressed.emit()
	check("Evergreen Giftkeeper" in hud._dialog_name.text, "Number selects correct outfit")
	hud._dialog_buttons.get_child(0).pressed.emit()
	check(game.worn_fashion() == "evergreen_giftkeeper", "Wear from details")
	hud._smith_tab = 7
	hud._fill_smith()
	var labels: Array = hud._smith_list.find_children("*", "Label", true, false)
	check(labels.any(func(n): return "Crimson Bastion" in n.text) and labels.any(func(n): return "Celestial Falcon" in n.text), "All Relic recipes appear in Doran's menu")
	check(game.set_fashion("") and game.worn_fashion() == "", "Unequip")
	print("RELIC COLLECTION ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
