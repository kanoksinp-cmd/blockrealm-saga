extends SceneTree
func _initialize() -> void:call_deferred("run")
func frames(n:=6) -> void:
 for i in n:await process_frame
func run() -> void:
 await process_frame
 var g=root.get_node("Game")
 g.new_character("MemoryQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);current_scene=main
 await frames()
 var p=get_first_node_in_group("player");p.set_process(false);p.set_physics_process(false)
 var world=main.get_node("StarterVillage")
 print("MEM town ",int(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576),"MB nodes=",get_node_count())
 var zones=load("res://scripts/world/zones.gd")
 for area in ["verdant","desert","frost","ember","verdant"]:
  var c:Vector2=zones.CENTER[area]
  await p.warp({"to":area,"dest":Vector3(c.x,0,c.y)})
  for monster in get_nodes_in_group("monster"):monster.set_process(false);monster.set_physics_process(false)
  await frames()
  print("MEM ",area," ",int(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576),"MB nodes=",get_node_count()," worlds=",world.worlds.size()," monsters=",get_nodes_in_group("monster").size())
 quit()
