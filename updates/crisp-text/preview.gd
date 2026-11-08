extends SceneTree
func _initialize() -> void:call_deferred("run")
func frames(n:=6) -> void:
 for i in n:await process_frame
func shot(name:String) -> void:
 await frames(6)
 RenderingServer.viewport_set_update_mode(root.get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join(name+".png"))
func run() -> void:
 await process_frame
 var g=root.get_node("Game")
 g.new_character("NovaMoon32",load("res://scripts/voxel/avatar.gd").default_appearance())
 g.base_level=49;g.job_id="swordsman";g.job_tier=4;g.job="Rune Knight";g.job_level=29;g.world_hour=11
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames()
 var ui=g.ui
 root.min_size=Vector2i.ZERO;root.size=Vector2i(844,390)
 ui.layout_defaults();await frames()
 await shot("hud")
 ui.open_smith("Blacksmith Doran",7);await frames()
 await shot("craft")
 ui._smith.panel.hide()
 ui.dialog("ช่างตีเหล็กโดแรน","เลือกบริการที่ต้องการ · คราฟอุปกรณ์และชุดแฟชั่น\nรวบรวมแร่ทองคำเพื่อสร้างอาวุธ พร้อมออกผจญภัย!",["ตีบวก","คราฟอาวุธ","คราฟหมวก","คราฟเกราะ","ชุดแฟชั่น","ปิด"],Callable())
 await frames();await shot("dialog")
 for name in ["ui_font","ui_font_bold","ui_font_title"]:
  var font=load("res://assets/fonts/"+name+".tres").base_font
  print("FONT_LOADED ",name," ",font.resource_path," oversampling=",font.oversampling," hinting=",font.hinting)
 print("PREVIEW_MEMORY staticMB=",roundi(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576)," textureMB=",roundi(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576))
 print("PASS_TEXT_PREVIEW mobile HUD, craft list and Thai dialogue")
 quit()
