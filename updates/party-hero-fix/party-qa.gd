extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=3) -> void:
 for i in n:await process_frame
func _initialize() -> void:
 await process_frame
 var game=root.get_node("Game")
 var avatar=load("res://scripts/voxel/avatar.gd")
 game.new_character("PartyQA",avatar.default_appearance());game.base_level=64;game.hp=game.max_hp()
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(15)
 var player=get_first_node_in_group("player");player.set_physics_process(false);player.set_process(false)
 var base=player.global_position
 var monster=load("res://scripts/monsters/monster.gd").new();monster.max_hp=1000000;monster.flee=0;monster.def=0;scene.add_child(monster);monster.global_position=base+Vector3(1.5,0,0);monster.set_physics_process(false)
 var party=load("res://scripts/characters/party_member.gd")
 var rng=RandomNumberGenerator.new();rng.seed=19
 for job in ["swordsman","merchant","thief","archer","mage","acolyte"]:
  var m=party.new();m.info={"name":"Test "+job,"job":job,"look":avatar.random_appearance(rng,{"job":job})};scene.add_child(m);m.global_position=base;m.set_physics_process(false);m.target=monster;m._skill_cd=0.0
  var before=monster.hp
  m._physics_process(0.016)
  check(not m._party_skill_queued.is_empty(),job+" automatic AI starts explicit skill")
  check(not m._party_skill_queued.is_empty(),job+" queues skill until impact")
  check(monster.hp==before,job+" no early damage before animation hit")
  check(not m._try_party_skill(),job+" cannot duplicate busy skill")
  await create_timer(2.5).timeout
  check(m._party_skill_queued.is_empty(),job+" animation reaches impact")
  check(monster.hp<before,job+" skill deals damage")
  check(m._skill_cd>0.0,job+" preserves cooldown")
  var after=monster.hp;m._on_hit();await create_timer(0.55).timeout
  check(monster.hp==after,job+" no duplicate hit after consumption")
  m._skill_cd=0.0;monster.global_position=base+Vector3(30,0,0)
  check(not m._try_party_skill(),job+" respects range")
  monster.global_position=base+Vector3(1.5,0,0);m._dead_t=0.0
  check(not m._try_party_skill(),job+" no skill while knocked out")
  m._dead_t=-1.0
  if job=="acolyte":
   game.hp=int(game.max_hp()*0.3);m._heal_cd=0.0;var health=game.hp;m._try_heal(player)
   check(game.hp>health and m._heal_cd>0.0,"healer restores leader HP and cooldown")
   health=game.hp;m._try_heal(player);check(game.hp==health,"heal cooldown prevents spam")
  m.free();await frames()
 print("PARTY SKILLS ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)
