extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 for i in 6:await process_frame
 var vb=scene.get_node("StarterVillage")
 var player=scene.get_node("Player");player.set_process(false);player.set_physics_process(false)
 var rooms:Array=["guild1","guild2","smithy"]
 var navigation:Dictionary={}
 for area in rooms:
  var rect:Rect2=vb.AREAS[area]
  var cells:Array=[]
  for x in range(int(rect.position.x),int(rect.end.x)):
   for z in range(int(rect.position.y),int(rect.end.y)):cells.append(vb.walkable(x+0.5,z+0.5))
  navigation[area]=cells
 var file=FileAccess.open(OS.get_environment("BR_NAV_FILE"),FileAccess.WRITE);file.store_string(JSON.stringify(navigation));file.close()
 if OS.get_environment("BR_BASELINE")=="1":print("PASS_BASELINE navigation recorded");quit();return
 var groups:=0
 var meshes:=0
 for name in ["GuildProps","BlacksmithWorkshop"]:
  var root_node=vb.get_node(name)
  assert(root_node.get_meta("metre_removed_meshes",0)>100)
  for group in root_node.get_children():
   if not str(group.name).begins_with("Metre_"):continue
   groups+=1
   assert(group.get_meta("voxel_size")==1.0)
   for node in group.get_children():
    meshes+=1
    assert(node.mesh is ArrayMesh and node.mesh.get_surface_count()==1)
    var vertices:PackedVector3Array=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    for vertex in vertices:assert(vertex.is_equal_approx(vertex.round()),"interior geometry is finer than a metre")
 assert(groups==3 and meshes<=6,"furniture was not batched per room")
 var bw=load("res://scripts/voxel/block_world.gd").new()
 var pixel=load("res://scripts/voxel/pixel_tex.gd")
 for point in [Vector3(150,0,0),Vector3(160,0,80),Vector3(0,0,0)]:
  var chunk=bw._new_chunk();bw._emit(chunk,point,bw.FACES[4],pixel.STONE_TILE,false)
  var size:float=chunk.uv[2].x-chunk.uv[0].x
  assert(absf(size-(5.0 if point.x==0 else 1.0))<0.01,"incorrect floor/wall texture density")
 assert(get_nodes_in_group("smith_workers").size()==3,"workers were removed")
 player.global_position=Vector3(160,0,80)
 for worker in get_nodes_in_group("smith_workers"):worker._process(3.0);assert(worker.timer>=3.0)
 var checks:=0
 for wp in vb.WARPS:
  if wp.area not in rooms:continue
  assert(vb.walkable(wp.pos.x,wp.pos.y),"blocked exit portal")
  assert(vb.playable_floor(wp.dest),"arrival floor removed")
  var arrival:=Vector3.ZERO
  for previous in vb.WARPS:
   if previous.to==wp.area:arrival=previous.dest;break
  assert(vb.find_path(arrival,Vector3(wp.pos.x,0,wp.pos.y)).size()>0,"no route across interior to exit")
  checks+=1
 var npc_count:=0
 for npc in get_nodes_in_group("npc"):
  if vb.area_at(npc.global_position) not in rooms:continue
  npc_count+=1
  assert(vb.playable_floor(npc.global_position),"NPC standing floor removed")
 assert(npc_count>=10,"interior NPCs missing")
 var ui=root.get_node("Game").ui
 ui.open_smith("Blacksmith Doran");assert(ui._smith.panel.visible);ui._smith.panel.hide()
 ui.open_guild_board(0);assert(ui._guild.panel.visible);ui._guild.panel.hide()
 for destination in ["guild1","guild2","smithy","town"]:
  var point:Vector3=Vector3(0,0,10)
  for wp in vb.WARPS:
   if wp.to==destination:point=wp.dest;break
  await player.warp({"to":destination,"dest":point})
  assert(player.area==destination)
 print("PASS_METRE_INTERIORS groups=",groups," static_meshes=",meshes," portal_routes=",checks," npcs=",npc_count," one-metre vertices/textures, workers, smith/guild windows and warps")
 quit()
