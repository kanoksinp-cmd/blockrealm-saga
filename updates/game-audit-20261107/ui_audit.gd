extends SceneTree
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void:call_deferred("run")
func frames(n:=6) -> void:
 for i in n:await process_frame
func verify(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func run() -> void:
 await process_frame
 var g=root.get_node("Game")
 g.new_character("Audit",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames()
 var ui=g.ui
 var mobile:bool=OS.get_environment("BR_MOBILE")=="1"
 verify(ui._menu.get_child_count()==6,"classic six menu buttons")
 verify((ui.get("_touch_ready")==true)==mobile,"correct device UI")
 root.min_size=Vector2i.ZERO
 var sizes:Array=[Vector2i(1055,488),Vector2i(844,450),Vector2i(488,1055)] if mobile else [Vector2i(1280,720)]
 for size in sizes:
  root.size=size;await frames();ui.layout_defaults();await frames()
  for key in ["_status","_inv","_skills","_quests","_settings","_autoset","_smith","_shop","_guild","_party","_wmap"]:
   var window=ui.get(key)
   ui.toggle(window.panel);await frames()
   verify(window.panel.visible,"cannot open "+key)
   if mobile:
    ui._fit_windows();await frames()
    var rect:Rect2=window.panel.get_global_rect()
    verify(Rect2(Vector2.ZERO,root.get_visible_rect().size).grow(1).encloses(rect),"modal clipped %s %s %s"%[key,size,rect])
    verify(window.panel.scale==Vector2.ONE,"scaled touch text "+key)
    verify(ui._mobile_hud._ui_blocked,"world input active under modal "+key)
   window.panel.hide();await frames()
  if mobile:verify(not ui._mobile_hud._ui_blocked,"world input stayed blocked")
  print("PASS_UI_SIZE ",size," checks=",checks)
 for bus in ["Master","Music","SFX","Ambient"]:verify(AudioServer.get_bus_index(bus)>=0,"missing audio bus "+bus)
 print("AUDIT_UI mobile=",mobile," checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)
