extends SceneTree
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void:call_deferred("run")
func verify(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures.append(label);print("FAIL ",label)
func run() -> void:
 await process_frame
 var g=root.get_node("Game")
 g.new_character("Audit",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 for i in 5:await process_frame
 for mon in get_nodes_in_group("monster"):mon.set_process(false);mon.set_physics_process(false)
 var player=get_first_node_in_group("player")
 player.set_process(false);player.set_physics_process(false)
 # A queued/cast skill must check affordability at execution time, not just on selection.
 g.skill_levels={"bash":1};g.skill_ready_at={};g.sp=0
 var before=g.sp
 player._release_skill("bash")
 verify(g.sp>=0 and g.sp==before,"queued skill spent unavailable SP")
 # Verify normal casts still pay exactly once and respect cooldown/changed Zeny.
 player.model._attack_t=-1.0;g.sp=g.max_sp();g.skill_ready_at={}
 var skilldb=load("res://scripts/game/skill_db.gd")
 before=g.sp
 player._release_skill("bash")
 verify(g.sp==before-skilldb.sp_cost("bash",1),"valid skill cost")
 before=g.sp;player._release_skill("bash")
 verify(g.sp==before,"cooldown allowed duplicate payment")
 player.model._attack_t=-1.0;g.skill_levels["mammonite"]=1;g.zeny=0;g.sp=g.max_sp()
 before=g.sp;player._start_skill("mammonite")
 verify(g.sp==before and g.zeny==0,"pending skill spent unavailable Zeny")
 # Public selection -> walking pending -> spend SP on self-buff -> arrival.
 player.model._attack_t=-1.0;g.skill_levels={"bash":1,"endure":1};g.skill_ready_at={};g.zeny=300
 g.sp=skilldb.sp_cost("bash",1)+skilldb.sp_cost("endure",1)-1
 var target=get_first_node_in_group("monster")
 target.global_position=player.global_position+Vector3(12,0,0);player.attack_target=target
 player.use_skill("bash")
 verify(player._pending_skill=="bash","public skill selection did not become pending")
 player.use_skill("endure")
 verify(g.sp<skilldb.sp_cost("bash",1),"test buff did not consume SP")
 player.model._attack_t=-1.0;target.global_position=player.global_position+Vector3(1,0,0)
 before=g.sp;player._physics_process(1.0/60.0)
 verify(g.sp==before and g.sp>=0 and player._pending_skill=="","arrival bypassed updated SP check")
 player.model._attack_t=0.0
 # Repeated death/respawn must have just one weapon-sync subscription.
 for i in 3:
  player._die();player._respawn()
  verify(not player._dead and g.hp==g.max_hp() and g.sp==g.max_sp(),"respawn state")
 var count:=0
 for connection in g.changed.get_connections():
  if connection.callable==Callable(player,"_sync_weapon"):count+=1
 verify(count==1,"duplicate respawn weapon subscriptions")
 # Fully restored SP/HP should not consume recovery-only items.
 g.inventory={"potion_blue":3,"potion_red":3};g.hp=g.max_hp();g.sp=g.max_sp()
 verify(not g.use_item("potion_blue") and g.count("potion_blue")==3,"blue potion wasted at full SP")
 verify(not g.use_item("potion_red") and g.count("potion_red")==3,"red potion wasted at full HP")
 g.inventory["potion_blue"]=3
 g.sp=0
 verify(g.use_item("potion_blue") and g.sp>0 and g.count("potion_blue")==2,"SP potion recovery")
 print("AUDIT_LIFECYCLE checks=",checks," failures=",failures)
 quit(0 if failures.is_empty() else 1)
