extends SceneTree
func frames(n:=6) -> void:
 for i in n: await process_frame
func shot(name: String) -> void:
 await frames(8)
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE").path_join(name+".png"))
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO
 root.mode=Window.MODE_WINDOWED
 root.size=Vector2i(390,844)
 var g=root.get_node("Game")
 g.new_character("NovaMoon32",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 current_scene=scene
 await frames(15)
 var ui=g.ui
 ui.layout_defaults()
 await shot("portrait-hud")
 ui._wmap.panel.show()
 ui._fit_windows()
 await shot("portrait-map")
 ui._wmap.panel.hide()
 ui._inv.panel.show()
 ui._fit_windows()
 await shot("portrait-inventory")
 scene.queue_free()
 await frames()
 var create=load("res://scripts/ui/char_create.gd").new()
 root.add_child(create)
 current_scene=create
 await frames(15)
 create._show_create()
 create._layout_mobile_screen()
 await shot("portrait-create")
 create._show_title()
 create._layout_mobile_screen()
 await shot("portrait-select")
 create.queue_free()
 await frames()
 print("PORTRAIT CAPTURES DONE")
 quit()
