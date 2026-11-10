extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=3) -> void:
 for i in n:await process_frame
func _initialize() -> void:
 await process_frame
 var game=root.get_node("Game")
 game.new_character("SkillQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames(12)
 var player=get_first_node_in_group("player")
 check(is_instance_valid(player),"player available")
 var db=load("res://scripts/game/skill_db.gd")
 var accents=load("res://scripts/combat/skill_power.gd")
 var bank=db.get_script_constant_map().SKILLS
 var active:=0
 var types:={}
 for id in bank:
  if not db.is_active(id):continue
  active+=1
  types[String(db.info(id).type)]=true
  game.skill_levels[id]=1
  player.set_meta("skill_accent_release",-1000);player.set_meta("skill_accent_impact",-1000)
  player._skill_accent(id,player.global_position,1.0,"release")
  var all=get_nodes_in_group("skill_power_accents")
  check(not all.is_empty(),"active skill release: "+id)
  for node in all:node.free()
  player._skill_accent(id,player.global_position,1.0,"impact")
  for node in get_nodes_in_group("skill_power_accents"):node.free()
 print("ACTIVE SKILLS ",active," TYPES ",types.keys())
 var hp=game.hp;var sp=game.sp;var gold=game.zeny
 for el in accents.PALETTE:
  player.set_meta("skill_accent_impact",-1000)
  var node=accents.emit(player,player.global_position,el,"aoe_target",2.0,3.0)
  check(is_instance_valid(node),"element emitted: "+el)
  if not is_instance_valid(node):continue
  node.set_process(false);node._process(0.09)
  check(node.layers.size()==2,"two draw batches for "+el)
  check(node.scale.x<=3.01,"shockwave stays within declared radius")
  node._process(0.6)
  await process_frame
 await frames()
 check(game.hp==hp and game.sp==sp and game.zeny==gold,"visuals do not mutate combat or currency")
 for i in 40:
  player.set_meta("skill_accent_impact",-1000)
  accents.emit(player,player.global_position,"fire","aoe_self",2.0,3.0)
 var cap=7 if root.get_node("Settings").is_mobile() else 18
 check(get_nodes_in_group("skill_power_accents").size()<=cap,"concurrent budget enforced")
 await create_timer(1.0).timeout
 check(get_nodes_in_group("skill_power_accents").is_empty(),"effects free after expiry")
 player.set_meta("skill_accent_impact",-1000)
 var one=accents.emit(player,player.global_position,"wind","bolt",1.0,1.0)
 check(accents.emit(player,player.global_position,"wind","bolt",1.0,1.0)==null,"burst coalescing")
 if is_instance_valid(one):one.free()
 # Original projectile travel and exactly-once hit callback survive decoration.
 var hits:=[0]
 load("res://scripts/combat/fx.gd").projectile(player,player.global_position+Vector3.UP,player.global_position+Vector3(2,1,0),"fire",func():hits[0]+=1,true)
 await create_timer(0.65).timeout
 check(hits[0]==1,"projectile hit exactly once")
 print("SKILL POWER ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)
