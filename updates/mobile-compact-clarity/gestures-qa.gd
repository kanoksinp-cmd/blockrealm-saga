extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=6) -> void:
 for i in n:await process_frame
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.size=Vector2i(844,390)
 var game=root.get_node("Game");game.new_character("TouchQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(15)
 var ui=game.ui;var hud=ui._mobile_hud
 for dimensions in [Vector2i(844,390),Vector2i(932,430),Vector2i(667,320),Vector2i(740,360),Vector2i(1024,768),Vector2i(390,844),Vector2i(844,390)]:
  root.size=dimensions;root.get_node("Settings")._mobile_viewport();await frames(8);ui.layout_defaults();await frames()
  var vp=root.get_visible_rect().size
  check(vp.x>vp.y,"landscape logical canvas after resize "+str(dimensions))
  if dimensions.x<dimensions.y:continue
  var factor=minf(float(dimensions.x)/vp.x,float(dimensions.y)/vp.y)
  for button in hud._skill_btns+hud._item_btns+[hud._attack,hud._page_btn,hud._auto]:
   var rect=button.get_global_rect()
   check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=vp.x+1 and rect.end.y<=vp.y+1,"touch control within frame "+str(dimensions))
   check(button.size.x*factor>=44,"touch target at least 44 screen pixels "+str(dimensions))
  ui._wmap.panel.show();ui._fit_windows();await frames()
  var rect=ui._wmap.panel.get_global_rect()
  check(rect.position.x>=0 and rect.end.x<=vp.x+2 and rect.end.y<=vp.y+2,"map popup fits "+str(dimensions))
  check(absf(ui._wmap_img.size.x*ui._wmap_img.scale.x-ui._touch_map_view.size.x)<2,"map fills its view "+str(dimensions))
  ui._wmap.panel.hide();await frames()
 # Simultaneous fingers: joystick remains active while a second finger presses an action.
 var press=InputEventScreenTouch.new();press.index=11;press.pressed=true;press.position=hud._joy_rest;hud._gui_input(press)
 check(hud._joy_idx==11,"joystick claims first finger")
 var action=InputEventScreenTouch.new();action.index=12;action.pressed=true;action.position=Vector2(30,30);hud._page_btn._gui_input(action)
 check(hud._joy_idx==11 and hud._page_btn._down==12,"independent second-finger button")
 hud.relayout(root.get_visible_rect().size)
 check(hud._joy_idx==-1 and hud._page_btn._down==-1 and hud._touches.is_empty(),"resize cancels held fingers without stuck inputs")
 ui._wmap.panel.show();await frames();check(hud._ui_blocked,"modal blocks world touches");ui._wmap.panel.hide();await frames();check(not hud._ui_blocked,"closing modal restores touches")
 print("LANDSCAPE TOUCH ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)
