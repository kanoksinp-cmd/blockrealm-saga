extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=4) -> void:
 for i in n:await process_frame
func _initialize() -> void:
 await process_frame
 var game=root.get_node("Game");var avatar=load("res://scripts/voxel/avatar.gd")
 game.slot=0;game.new_character("Armored Hero",avatar.default_appearance())
 game.job_id="swordsman";game.job_tier=4;game.job_level=20;game.job="Rune Knight";game.base_level=64;game.appearance.job="swordsman";game.fashion_unlocks=["eternal_armor"];game.appearance.fashion="eternal_armor";game.equip.weapon="steel_broadsword";game.refine["steel_broadsword"]=3;game.save_game()
 var expected=game.dressed_appearance();var shrine=game.save_point
 game.slot=1;game.new_character("Forest Caster",avatar.default_appearance());game.job_id="mage";game.appearance.job="mage";game.fashion_unlocks=["forest_mage"];game.appearance.fashion="forest_mage";game.equip.weapon="ember_staff";game.save_game()
 var active=game.appearance.duplicate(true)
 var summary=game.save_summary(0)
 check(summary.preview_appearance==expected,"slot summary includes exact worn fashion, equipment and refine")
 check(game.appearance==active and game.slot==1,"reading another slot does not change active character")
 var title=load("res://scenes/character_create.tscn").instantiate();root.add_child(title);current_scene=title;await frames(8)
 title._select_slot(0);await frames()
 check(title._preview.appearance==expected,"actual selection preview uses current worn gear")
 title._select_slot(1);await frames()
 check(title._preview.appearance.fashion=="forest_mage","switching slots shows each slot's fashion")
 check(game.appearance==active and game.slot==1,"preview switching never mutates live save state")
 title.queue_free();current_scene=null;await frames()
 check(game.load_game(0),"load original slot")
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(12)
 var player=get_first_node_in_group("player");player.set_physics_process(false);player.set_process(false)
 var nav=player._nav();var spot=nav.safe_position(Vector3(24.25,0,23.75),"town",10)
 check(spot!=Vector3.INF,"town test point is clear")
 player.global_position=spot+Vector3(0,0.15,0);player.model.rotation.y=1.23
 game.save_game();var record=game.resume_checkpoint()
 check(not record.is_empty() and record.position.distance_to(player.global_position)<0.01,"save captures latest exact position")
 check(absf(record.yaw-1.23)<0.01,"heading persisted")
 check(game.save_point==shrine,"respawn shrine remains unchanged")
 var cfg=ConfigFile.new();cfg.load(game.slot_path(0));check(cfg.get_value("char","auto_cfg").has("_resume_checkpoint"),"checkpoint written into saved account-compatible dictionary")
 # Cloud serialization and restore use the existing production store and schema.
 var store=load("res://scripts/game/account_save_store.gd")
 var prefix=store.prefix("resume_cloud_qa");DirAccess.make_dir_recursive_absolute(prefix)
 DirAccess.copy_absolute(game.slot_path(0),prefix+"save_1.cfg")
 var payload=JSON.parse_string(JSON.stringify(store.capture("resume_cloud_qa")))
 check(store.valid(payload),"existing cloud schema accepts resume metadata")
 check(store.install("resume_cloud_restore_qa",payload),"cloud JSON bundle installs successfully")
 cfg=ConfigFile.new();cfg.load(store.prefix("resume_cloud_restore_qa")+"save_1.cfg")
 var xyz=cfg.get_value("char","auto_cfg")["_resume_checkpoint"].position
 check(Vector3(xyz[0],xyz[1],xyz[2]).distance_to(record.position)<0.001,"cross-device JSON round trip preserves coordinates")
 scene.queue_free();current_scene=null;await frames(8)
 game.load_game(1);check(game.resume_checkpoint().is_empty(),"checkpoint never leaks into another character")
 game.load_game(0)
 scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(12)
 player=get_first_node_in_group("player");player.set_physics_process(false);player.set_process(false)
 print("RESUME TOWN expected=",record," actual=",player.global_position," stored=",game.auto_cfg.get("_resume_checkpoint")," restoring=",player._restoring_resume)
 check(Vector2(player.global_position.x-record.position.x,player.global_position.z-record.position.z).length()<0.05 and absf(player.global_position.y-record.position.y)<0.3,"fresh scene resumes town coordinates")
 check(absf(player.model.rotation.y-record.yaw)<0.01,"fresh scene resumes heading")
 check(not player._restoring_resume,"restoration releases player controls")
 # Warping commits a different map immediately; next scene must build it before entry.
 await player.warp({"to":"desert_d","dest":Vector3(1400.5,0,449.0),"yaw":2.0})
 var dungeon=game.resume_checkpoint();check(dungeon.get("area")=="desert_d","map transition immediately persists dungeon checkpoint")
 scene.queue_free();current_scene=null;await frames(8)
 game.load_game(0)
 scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(15)
 player=get_first_node_in_group("player");player.set_physics_process(false);player.set_process(false);nav=player._nav()
 check(player.area=="desert_d" and nav.built.has("desert_d"),"resume builds destination dungeon before controls resume")
 check(player.global_position.distance_to(dungeon.position)<1.0 and nav.playable_floor(player.global_position),"dungeon resume lands on playable floor")
 check(get_nodes_in_group("monster").any(func(m):return m.get_meta("area","")=="desert_d"),"dungeon monsters spawn on resumed map")
 game.auto_cfg["_resume_checkpoint"]={"version":1,"position":[1331.0,0.15,331.0],"area":"desert_d","yaw":0.0}
 player._restoring_resume=true;player._restore_resume_checkpoint()
 check(nav.playable_floor(player.global_position),"unsafe black-surround checkpoint recovers onto a playable floor")
 # An invalid or interrupted warp checkpoint must not overwrite the last valid one.
 var saved=game.auto_cfg["_resume_checkpoint"].duplicate(true);player._warping=true;player.global_position+=Vector3(2,0,1);game.save_game();check(game.auto_cfg["_resume_checkpoint"]==saved,"interrupted warp preserves last checkpoint");player._warping=false
 game.auto_cfg["_resume_checkpoint"]={"version":1,"position":[99999,0,99999],"area":"town","yaw":0};check(game.resume_checkpoint().is_empty(),"out-of-map checkpoint rejected")
 game.auto_cfg["_resume_checkpoint"]={"version":1,"position":[NAN,0,0],"area":"town","yaw":0};check(game.resume_checkpoint().is_empty(),"nonfinite checkpoint rejected")
 scene.queue_free();current_scene=null;await frames(8)
 game.slot=2;game.new_character("Fresh Hero",avatar.default_appearance());check(game.resume_checkpoint().is_empty(),"new character has no inherited checkpoint")
 print("RESUME FASHION ","PASS" if failures==0 else "FAIL "+str(failures))
 quit(1 if failures else 0)
