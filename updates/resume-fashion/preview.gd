extends SceneTree
func frames(n:=6) -> void:
 for i in n:await process_frame
func shot(name:String) -> void:
 await frames();RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE").path_join(name+".png"))
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(390,844) if OS.get_environment("BR_MOBILE")=="1" else Vector2i(1280,720)
 var game=root.get_node("Game");var avatar=load("res://scripts/voxel/avatar.gd")
 game.slot=0;game.new_character("NovaMoon32",avatar.default_appearance());game.job_id="swordsman";game.job_tier=4;game.job="Rune Knight";game.base_level=64;game.appearance.job="swordsman";game.fashion_unlocks=["eternal_armor"];game.appearance.fashion="eternal_armor";game.equip.weapon="steel_broadsword";game.refine["steel_broadsword"]=3;game.save_game()
 game.slot=1;game.new_character("Forest Mage",avatar.default_appearance());game.job_id="mage";game.job_tier=3;game.job="High Wizard";game.base_level=60;game.appearance.job="mage";game.fashion_unlocks=["forest_mage"];game.appearance.fashion="forest_mage";game.equip.weapon="ember_staff";game.save_game()
 var scene=load("res://scenes/character_create.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(12)
 scene._select_slot(0);await shot("select-eternal-armor")
 scene._select_slot(1);await shot("select-forest-mage")
 print("SELECTION PREVIEW DONE")
 scene.queue_free();await frames();quit()
