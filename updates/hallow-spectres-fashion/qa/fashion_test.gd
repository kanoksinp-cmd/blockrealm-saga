extends SceneTree
var fails := 0
func ok(c: bool, msg: String) -> void:
	if not c: fails += 1; print("FAIL ", msg)
	else: print("ok   ", msg)
func _initialize():
	await process_frame
	var Game = root.get_node("Game"); var Items = load("res://scripts/game/items.gd")
	var Avatar = load("res://scripts/voxel/avatar.gd")
	for job in ["swordsman", "archer", "mage", "acolyte", "merchant", "thief"]:
		Game.slot = 0
		var a = Avatar.default_appearance(); a.job = job
		Game.new_character("T_" + job, a)
		var base_atk: int = Game.atk(); var base_str: int = Game.st("STR"); var base_hp: int = Game.max_hp(); var base_flee: int = Game.flee()
		var r: Dictionary = Game.FASHIONS.pumpkin_reaper.recipe
		ok(not Game.can_craft(r), job + ": cannot craft without materials")
		ok(not Game.set_fashion("pumpkin_reaper"), job + ": cannot wear before crafting")
		Game.zeny = 100000
		for fid in ["pumpkin_reaper", "bone_oracle", "hollow_scarecrow"]:
			var rr: Dictionary = Game.FASHIONS[fid].recipe
			for m in rr.mats: Game.add_item(m, int(rr.mats[m]))
			ok(Game.can_craft(rr), job + ": can craft " + fid)
			var z0: int = Game.zeny
			ok(Game.craft(rr) and Game.owns_fashion(fid) and Game.zeny == z0 - int(rr.zeny), job + ": crafted " + fid + " and paid")
			ok(not Game.can_craft(rr), job + ": no second craft of " + fid)
			var fake := rr.duplicate(true); fake.zeny = 1
			ok(not Game.can_craft(fake), job + ": tampered recipe rejected")
		ok(Game.set_fashion("pumpkin_reaper") and Game.worn_fashion() == "pumpkin_reaper", job + ": wear pumpkin")
		ok(Game.st("STR") == base_str + 3 and Game.max_hp() > base_hp and Game.atk() > base_atk, job + ": pumpkin bonus STR+3 ATK HP (%d->%d atk)" % [base_atk, Game.atk()])
		ok(Game.set_fashion("hollow_scarecrow") and Game.flee() == base_flee + 8 + 3, job + ": scarecrow FLEE+8 (+AGI3)")
		ok(Game.st("STR") == base_str, job + ": pumpkin bonus removed when switching")
		ok(Game.dressed_appearance().fashion == "hollow_scarecrow", job + ": dressed appearance keeps fashion")
		Game.save_game()
		ok(Game.load_game(0) and Game.worn_fashion() == "hollow_scarecrow" and Game.fashion_unlocks.size() == 3, job + ": save/load keeps unlocks & worn")
		ok(Game.set_fashion("forest_mage") == (job == "mage" and false), job + ": forest mage still needs its own craft (mage only)")
		var model := Node3D.new(); root.add_child(model)
		var rig: Dictionary = Avatar.assemble(model, Game.dressed_appearance())
		var vis := 0; var fashion_parts := 0
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			if mi.visible: vis += 1
			if mi.name in ["sack", "brim", "cone1"]: fashion_parts += 1
		ok(fashion_parts == 3 and rig.has("weapon"), job + ": scarecrow model parts attached (%d visible meshes), weapon kept" % vis)
		model.free()
		Game.set_fashion("")
		ok(Game.st("STR") == base_str and Game.flee() == base_flee, job + ": unequip restores stats")
	# old save: unknown unlock is dropped, fashion not owned is stripped
	Game.fashion_unlocks = ["bogus", "bone_oracle", "bone_oracle"]; Game.appearance.fashion = "pumpkin_reaper"; Game.save_game()
	Game.load_game(0)
	ok(Game.fashion_unlocks == ["bone_oracle"] and Game.appearance.fashion == "", "load sanitizes unlocks and unowned worn fashion")
	print("stat text: ", Items.stat_text("pumpkin_reaper_fashion"), " | ", Items.stat_text("bone_oracle_fashion"), " | ", Items.stat_text("hollow_scarecrow_fashion"))
	print("FAILS=", fails)
	quit()
