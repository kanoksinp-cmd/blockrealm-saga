extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 var started:=Time.get_ticks_msec()
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 for i in 5:await process_frame
 var vb=scene.get_node("StarterVillage")
 var total:=0
 var nodes:=0
 for root_name in ["GuildProps","BlacksmithWorkshop"]:
  var root_node=vb.get_node(root_name)
  var vertices:=0
  var count:=0
  for node in root_node.find_children("*","MeshInstance3D",true,false):
   count+=1
   if node.mesh:
    for surface in node.mesh.get_surface_count():
     var arrays=node.mesh.surface_get_arrays(surface)
     if arrays.size()>0 and arrays[Mesh.ARRAY_VERTEX]!=null:vertices+=arrays[Mesh.ARRAY_VERTEX].size()
  print("PROFILE ",root_name," meshes=",count," vertices=",vertices)
  total+=vertices;nodes+=count
 print("PROFILE_TOTAL meshes=",nodes," vertices=",total," staticMB=",roundi(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576)," readyMS=",Time.get_ticks_msec()-started)
 quit()
