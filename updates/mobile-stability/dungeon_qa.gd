extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);current_scene=main
 for i in 5:await process_frame
 var p=get_first_node_in_group("player");p.set_process(false);p.set_physics_process(false)
 var vb=main.get_node("StarterVillage")
 for area in ["desert_d","chivalry_d","desert_d"]:
  var c:Vector2=vb.AREAS[area].get_center()
  await p.warp({"to":area,"dest":Vector3(c.x,0,c.y)})
  for monster in get_nodes_in_group("monster"):monster.set_process(false);monster.set_physics_process(false)
  for i in 5:await process_frame
  assert(vb.worlds.size()==1 and vb.worlds.has(area) and vb.navs.has(area))
  for npc in vb.get_node("Area_"+area).find_children("*","CharacterBody3D",true,false):
   if npc.get("role")!=null:assert(npc.role not in ["shop","smith"])
  print("PASS_DUNGEON_STREAM ",area)
 quit()
