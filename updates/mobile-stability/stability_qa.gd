extends SceneTree
func _initialize() -> void:call_deferred("run")
func frames(n:=5) -> void:
 for i in n:await process_frame
func freeze() -> void:
 for monster in get_nodes_in_group("monster"):monster.set_process(false);monster.set_physics_process(false)
func run() -> void:
 await process_frame
 var g=root.get_node("Game")
 g.new_character("StabilityQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames()
 var p=get_first_node_in_group("player");p.set_process(false);p.set_physics_process(false)
 var vb=scene.get_node("StarterVillage")
 var zones=load("res://scripts/world/zones.gd")
 var monster_type=load("res://scripts/monsters/monster.gd")
 var mobile:bool=OS.get_environment("BR_MOBILE")=="1"
 var sequence:Array=["verdant","desert","verdant","frost","ember","verdant","desert","verdant"] if mobile else ["verdant","desert"]
 var starting_hp:int=-1
 var ore_key:Vector3
 var saved_ore
 var warm_memory:float=0.0
 for index in sequence.size():
  var area:String=sequence[index]
  var c:Vector2=zones.CENTER[area]
  await p.warp({"to":area,"dest":Vector3(c.x,0,c.y)})
  freeze();await frames()
  if mobile:
   assert(vb.worlds.size()==1 and vb.worlds.has(area),"old region retained")
   assert(vb.navs.size()==1 and vb.navs.has(area),"old navigation retained")
   for mon in get_nodes_in_group("monster"):assert(String(mon.get_meta("area","town")) in ["town",area],"retired monsters retained")
  if area=="verdant":
   var alive
   var dead
   var matches:=0
   for mon in get_nodes_in_group("monster"):
    if mon.display_name=="Ashfang Rex":alive=mon;matches+=1
    if mon.display_name=="Mossjaw Rex":dead=mon;matches+=1
   assert(matches==2,"duplicate/missing bosses")
   if index==0:
    alive.hp=alive.max_hp-123;alive.stolen=true;starting_hp=alive.hp
    dead._enter(monster_type.State.DEAD);dead._state_t=10.0;dead.hp=0;dead.collision_layer=0;dead.model.visible=false
    for node in get_nodes_in_group("gather_node"):
     if node.kind=="ore" and vb.area_at(node.global_position)==area:
      ore_key=node.position;saved_ore=node;node.charges=0;node._respawn_t=600.0;node._set_depleted(true);node.set_process(false);break
    assert(saved_ore!=null)
   else:
    assert(alive.hp==starting_hp and alive.stolen,"revisit reset boss HP/stolen state")
    assert(not dead.is_alive() and dead.hp==0 and dead._state_t>=10.0 and dead._state_t<20.0,"revisit bypassed boss respawn timer")
    var matched:=false
    for node in get_nodes_in_group("gather_node"):
     if node.kind=="ore" and node.position.is_equal_approx(ore_key):
      assert(node.charges==0 and node._respawn_t>300.0,"revisit refreshed depleted ore")
      node.set_process(false);matched=true
    assert(matched,"resource placement changed")
  if index==5:warm_memory=Performance.get_monitor(Performance.MEMORY_STATIC)
  if index==7:assert(Performance.get_monitor(Performance.MEMORY_STATIC)<warm_memory+32*1048576,"memory grew after warm repeated route")
  print("PASS_TRANSITION ",area," memoryMB=",roundi(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576)," worlds=",vb.worlds.size()," nodes=",get_node_count())
 if mobile:
  g.save_point=Vector3(1088.5,0.1,0.5)
  await p.warp({"to":"desert","dest":Vector3(1400.5,0,-88.5)})
  freeze();await frames()
  assert(not vb.built.has("verdant"))
  p._die();await p._respawn();freeze();await frames()
  assert(not p._dead and p.area=="verdant" and vb.built.has("verdant") and g.hp==g.max_hp(),"respawn failed to rebuild released save-point map")
  # A depleted vein whose normal timer elapsed while unloaded must regrow.
  await p.warp({"to":"desert","dest":Vector3(1400.5,0,-88.5)})
  for key in vb._mobile_resources["verdant"]:
   if vb._mobile_resources["verdant"][key].charges<=0:
    vb._mobile_resources["verdant"][key].time=Time.get_ticks_msec()-700000
  await p.warp({"to":"verdant","dest":Vector3(1088.5,0,0.5)})
  freeze();await frames()
  var restored:=false
  for node in get_nodes_in_group("gather_node"):
   if node.kind=="ore" and node.position.is_equal_approx(ore_key):
    assert(node.charges==node.max_charges,"elapsed ore respawn timer was lost")
    restored=true
  assert(restored)
  await p.warp({"to":"town","dest":Vector3(0,0,10)})
  await frames()
  assert(vb.worlds.is_empty() and vb.navs.is_empty(),"town return kept distant geometry")
  print("PASS_RESPAWN unloaded save-point region restored; town releases all region caches")
 else:
  assert(vb.worlds.size()==2,"desktop region caching changed")
  print("PASS_PC desktop region cache retained")
 print("PASS_STABILITY mobile=",mobile," repeated travel, bounded memory, boss HP/death and resource depletion retained")
 quit()
