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
	var items := load("res://scripts/game/items.gd")
	var arsenal := load("res://scripts/voxel/forge_arsenal.gd")
	var test_jobs := {"mace":"acolyte", "axe":"merchant", "staff":"mage", "dagger":"thief",
		"sword":"swordsman", "greatsword":"swordsman", "katar":"thief"}
	check(game.ARSENAL_RECIPES.size() == 12, "Twelve unique recipes")
	for recipe in game.ARSENAL_RECIPES:
		var id: String = recipe.id
		var spec: Dictionary = items.info(id)
		var look: Dictionary = avatar.default_appearance()
		look.job = test_jobs[spec.wtype]
		game.slot = 0
		game.new_character("ForgeQA", look)
		game.job_id = look.job
		game.appearance.job = look.job
		game.job_tier = 2
		game.job_branch = "a"
		game.zeny = 350000
		for mat in recipe.mats:
			game.add_item(mat, int(recipe.mats[mat]))
		game.base_level = int(spec.equip_lv) - 1
		check(not game.can_craft(recipe), "Level gates crafting " + id)
		game.add_item(id, 1)
		check(not game.equip_item(id), "Level gates equipping " + id)
		game.remove_item(id, 1)
		game.base_level += 1
		var fake: Dictionary = recipe.duplicate(true)
		fake.zeny = 1
		check(not game.can_craft(fake), "Requires the real recipe " + id)
		check(recipe in game.crafting_recipes("weapons", spec.wtype), "Correct smithy filter " + id)
		check(recipe not in game.crafting_recipes("armor"), "Weapon isn't in armor list")
		check(game.craft(recipe) and game.count(id) == 1 and game.zeny == 350000 - recipe.zeny, "Recipe grants item " + id)
		for mat in recipe.mats:
			check(game.count(mat) == 0, "Consumed " + mat)
		var valid_job: String = game.job_id
		game.job_id = "archer" if spec.wtype != "dagger" else "acolyte"
		check(not game.equip_item(id) and game.count(id) == 1, "Class gate preserves inventory " + id)
		game.job_id = valid_job
		check(game.equip_item(id) and game.equip.weapon == id and game.weapon_atk() == spec.atk, "Real weapon stats " + id)
		var rig_root := Node3D.new()
		root.add_child(rig_root)
		var rig: Dictionary = avatar.assemble(rig_root, game.dressed_appearance())
		var mesh := rig.weapon.get_node_or_null(id) as MeshInstance3D
		check(mesh != null and mesh.mesh.get_surface_count() == 1, "Distinct model at weapon grip " + id)
		check(items.icon(id).get_width() == 45 and arsenal.has(id), "Inventory artwork " + id)
		check(("Base Lv %d+" % spec.equip_lv) in items.stat_text(id), "Tooltip shows required level " + id)
		rig_root.free()
		game.save_game()
		check(game.load_game(0) and game.equip.weapon == id, "Equipped weapon survives reload " + id)
		print(id, " LV ", spec.equip_lv, " ATK ", spec.atk)
	print("ARSENAL ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
