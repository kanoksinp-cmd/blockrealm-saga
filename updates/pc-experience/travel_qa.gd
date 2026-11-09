extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=6) -> void:
 for i in n:await process_frame
func _initialize() -> void:
 await process_frame
 var g=root.get_node("Game")
 g.new_character("TravelQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames(15)
 Engine.max_fps=0
 var ui=g.ui
 var player=get_first_node_in_group("player")
 ui._pc_index_map()
 var checked:=0
 for entry in ui.pc_map_entries:
  if entry.kind==2 and entry.get("id","")=="gold_ore":
   ui._pc_travel(entry)
   check(player._auto_gather_area==entry.area,"selected resource map "+entry.area)
   player._stop_all();g.auto_on=false;checked+=1
 check(checked>=2,"both gold ore source maps exercised")
 check(not player.start_resource_trip("gold_ore","invalid_area"),"invalid source is rejected")
 check(player.start_resource_trip("gold_ore"),"default one-argument gather route still works")
 player._stop_all();g.auto_on=false
 root.min_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
 for factor in [1.0,1.5]:
  root.content_scale_factor=factor
  await frames()
  for window in [ui._inv,ui._wmap,ui.pc_tools,ui.pc_log]:
   window.panel.show();await frames(10)
   var rect=window.panel.get_global_rect();var vp=root.get_visible_rect().size
   check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=vp.x+2 and rect.end.y<=vp.y+2,"popup fits viewport "+str(factor)+" "+str(rect)+" "+str(vp))
   window.panel.hide()
 print("PC TRAVEL / POPUP ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)
