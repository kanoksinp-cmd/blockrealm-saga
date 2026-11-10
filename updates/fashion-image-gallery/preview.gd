extends SceneTree
func frames(n:=6) -> void:
 for i in n:await process_frame
func shot(name:String) -> void:
 await frames(10)
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE").path_join(name+".png"))
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(390,844) if OS.get_environment("BR_MOBILE")=="1" else Vector2i(1280,720)
 var game=root.get_node("Game")
 game.new_character("NovaMoon32",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames(15)
 var ui=game.ui
 ui._open_mage_fashion();await shot("gallery")
 var gallery=ui._fashion_gallery
 gallery.show_detail("celestial_falcon");await shot("detail")
 for panel in ui._popups:panel.hide()
 var player=get_first_node_in_group("player")
 var vendor=get_nodes_in_group("npc").filter(func(n):return n.npc_name=="Blacksmith Doran")[0]
 player.global_position=vendor.global_position+Vector3(1,0,0)
 ui.open_smith("Blacksmith Doran",7);await shot("smith-gallery")
 gallery.show_detail("crimson_bastion");await shot("craft-detail")
 print("FASHION PREVIEW DONE")
 scene.queue_free();await frames();quit()
