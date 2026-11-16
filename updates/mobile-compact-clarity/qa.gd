extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=5) -> void:
 for i in n:await process_frame
func overlaps(a:Control,b:Control) -> bool:
 return a.visible and b.visible and a.get_global_rect().grow(-1).intersects(b.get_global_rect().grow(-1))
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.size=Vector2i(1055,488)
 var game=root.get_node("Game");game.new_character("CompactQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(15)
 var settings=root.get_node("Settings");var ui=game.ui;var hud=ui._mobile_hud
 settings.set_value("ui_scale",1.5);check(is_equal_approx(float(settings.g("ui_scale")),1.1),"oversized legacy mobile setting is clamped")
 settings.set_value("ui_scale",0.75);check(is_equal_approx(float(settings.g("ui_scale")),0.95),"undersized touch setting is clamped")
 for css in [Vector2i(844,390),Vector2i(667,320),Vector2i(932,430),Vector2i(1024,768)]:
  root.size=Vector2i(Vector2(css)*1.25)
  for scale in [0.95,1.0,1.1]:
   settings.set_value("ui_scale",scale);settings._mobile_viewport();await frames(7);ui.layout_defaults();await frames()
   var vp=root.get_visible_rect().size
   var physical_factor=minf(float(css.x)/vp.x,float(css.y)/vp.y)
   check(not overlaps(ui._pro_header,ui._pro_toolbar),"header and menu separated "+str(css)+str(scale))
   check(not overlaps(ui._map_panel,ui._pro_toolbar),"map and menu separated "+str(css)+str(scale))
   var buttons=hud._skill_btns+hud._item_btns+[hud._attack,hud._auto,hud._page_btn,hud._chat_btn]
   for i in buttons.size():
    var rect=buttons[i].get_global_rect()
    check(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=vp.x+1 and rect.end.y<=vp.y+1,"action within viewport")
    check(buttons[i].size.x*physical_factor>=44,"touch remains at least 44 CSS pixels after sharp rendering")
    for j in range(i+1,buttons.size()):check(not overlaps(buttons[i],buttons[j]),"actions do not overlap")
    check(not overlaps(ui._pro_quest,buttons[i]),"quest avoids actions")
    check(not overlaps(ui._clock,buttons[i]),"clock avoids actions")
   for popup in [ui._inv.panel,ui._skills.panel,ui._smith.panel,ui._wmap.panel,ui._settings.panel]:
    popup.show();await frames();ui._fit_windows();await frames()
    var rect=popup.get_global_rect();check(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=vp.x+2 and rect.end.y<=vp.y+2,"popup fits scaled mobile viewport")
    popup.hide();await frames(2)
 settings.set_value("ui_scale",1.0)
 check(Engine.max_fps==30,"mobile frame limit preserved")
 print("COMPACT CLARITY ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)
