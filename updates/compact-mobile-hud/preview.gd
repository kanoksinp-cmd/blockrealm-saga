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
 g.base_level=60
 g.job_id="swordsman"
 g.job="Rune Knight"
 g.job_tier=4
 g.zeny=39090
 g.hp=g.max_hp()
 g.sp=g.max_sp()
 g.hotbar=["bash","endure","double_strafe","magnum_break","","","","","","","","","","","",""]
 var scene=load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 current_scene=scene
 await frames(15)
 var ui=g.ui
 ui._pro_quest_title.text="บท 9 · เตรียมพร้อมสู่เลเวล 62"
 ui.layout_defaults()
 await shot("portrait-hud")
 ui._wmap.panel.show()
 ui._fit_windows()
 await shot("portrait-map")
 ui._wmap.panel.hide()
 ui._inv.panel.show()
 ui._fit_windows()
 await shot("portrait-inventory")
 ui._inv.panel.hide()
 ui.toggle(ui._pro_menu.panel)
 ui._fit_windows()
 await shot("portrait-menu")
 print("PRO MOBILE PREVIEWS DONE")
 scene.queue_free()
 await frames()
 quit()
