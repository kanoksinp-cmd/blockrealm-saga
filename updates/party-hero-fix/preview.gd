extends SceneTree
func frames(n:=8) -> void:
 for i in n:await process_frame
func shot(name:String) -> void:
 await frames()
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE").path_join(name+".png"))
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(390,844) if OS.get_environment("BR_MOBILE")=="1" else Vector2i(1280,720)
 var game=root.get_node("Game")
 game.new_character("NovaMoon32",load("res://scripts/voxel/avatar.gd").default_appearance())
 game.base_level=64;game.job="Rune Knight";game.job_level=35;game.guild_member=true;game.guild_rank=2;game.guild_points=63
 game.stats={"STR":59.0,"AGI":53.0,"VIT":37.0,"INT":6.0,"DEX":5.0,"LUK":13.0};game.stat_points=1
 var fashion=game.FASHIONS.eternal_armor
 game.zeny=50000
 for item in fashion.recipe.mats:game.add_item(item,int(fashion.recipe.mats[item]),true)
 game.craft(fashion.recipe);game.set_fashion("eternal_armor")
 game.hp=game.max_hp();game.sp=game.max_sp()
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames(15)
 var ui=game.ui
 ui._status.panel.show();ui._refresh_status();await frames()
 if ui._mobile:ui._fit_windows()
 ui._status_spin=false;ui._status_yaw=0.35;ui._status_update_preview()
 await shot("character-card-front")
 ui._status_yaw=2.25;ui._status_update_preview()
 await shot("character-card-turned")
 print("CHARACTER PREVIEW DONE")
 scene.queue_free();await frames();quit()
