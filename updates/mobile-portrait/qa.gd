extends SceneTree
var failures := 0
func frames(n := 6) -> void:
 for i in n: await process_frame
func check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  push_error(label)
func bounds(c: Control, vp: Vector2, label: String) -> void:
 var rect := c.get_global_rect()
 check(rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= vp.x+2 and rect.end.y <= vp.y+2, label+": "+str(rect)+" vp="+str(vp))
func _initialize() -> void:
 await process_frame
 var g=root.get_node("Game")
 g.new_character("PortraitTest",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 current_scene=scene
 await frames(12)
 var ui=g.ui
 root.min_size=Vector2i.ZERO
 root.mode=Window.MODE_WINDOWED
 for dimensions in [Vector2i(390,844),Vector2i(360,640),Vector2i(430,932),Vector2i(768,1024),Vector2i(844,390)]:
  root.size=dimensions
  await frames(12)
  ui.layout_defaults()
  await frames(8)
  var vp=root.get_visible_rect().size
  print("LAYOUT ",dimensions," logical=",vp," info=",ui._info_panel.get_global_rect()," tracker=",ui._tracker.panel.get_global_rect())
  for control in [ui._info_panel,ui._map_panel,ui._menu,ui._pills,ui._tracker.panel,ui._clock]: bounds(control,vp,"HUD")
  var hud=ui._mobile_hud
  for button in hud._skill_btns+[hud._attack,hud._auto,hud._page_btn,hud._chat_btn]: bounds(button,vp,"touch button")
  if vp.y > vp.x:
   check(hud._joy_rest.distance_to(hud._attack.center())>130,"joystick separated from attack")
   for key in ["_inv","_skills","_settings","_quests","_wmap","_shop","_smith","_dialog","_status","_guild","_party","_autoset"]:
    var window=ui.get(key)
    if key=="_smith": ui.open_smith("Test smith")
    if key=="_shop": ui.open_shop("Test shop",["potion_red","potion_blue"],true)
    window.panel.show()
    ui._fit_windows()
    await frames(10)
    ui._fit_windows()
    await frames(8)
    bounds(window.panel,vp,"window "+key)
    window.panel.hide()
   ui.dialog("Test NPC","ทดสอบหน้าจอแนวตั้ง",["หนึ่ง","สอง","สาม","สี่"],func(_i):pass)
   await frames(8)
   ui._fit_windows()
   await frames(6)
   bounds(ui._dialog.panel,vp,"NPC dialog")
   ui._dialog.panel.hide()
  if OS.get_environment("BR_CAPTURE")!="":
   RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE").path_join("hud_%dx%d.png"%[dimensions.x,dimensions.y]))
 scene.queue_free()
 await frames(3)
 print("PORTRAIT UI ","PASS" if failures==0 else "FAIL "+str(failures))
 quit(1 if failures else 0)
