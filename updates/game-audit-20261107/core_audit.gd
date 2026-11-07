extends SceneTree
var checks := 0
var failures: Array[String] = []
var g
var items
var skills
var story
var side
var gather
var spawner
func _initialize() -> void: call_deferred("run")
func verify(ok: bool,label: String) -> void:
 checks+=1
 if not ok:
  failures.append(label)
  print("FAIL ",label)
func reset() -> void:
 g.new_character("Audit",load("res://scripts/voxel/avatar.gd").default_appearance())
func run() -> void:
 await process_frame
 g=root.get_node("Game")
 items=load("res://scripts/game/items.gd")
 skills=load("res://scripts/game/skill_db.gd")
 story=load("res://scripts/game/quest_db.gd")
 side=load("res://scripts/game/side_quests.gd")
 gather=load("res://scripts/world/gathering.gd")
 spawner=load("res://scripts/monsters/spawner.gd")
 reset()
 # Full career paths, every branch and allocation mode.
 for job in skills.JOB_SKILLS:
  for branch in ["a","b"]:
   for mode in ["balanced","attack","support"]:
    reset()
    g.job_id=job;g.job_branch=branch;g.base_level=99;g.past_job_levels=[10]
    for tier in range(1,6):
     g.job_tier=tier;g.job_level=skills.JOB_MAX[tier]
     g.sync_skill_budget();g.allocate_build(mode)
     verify(g.skill_points==0,"unspent skill budget %s/%s/%s/tier%d"%[job,branch,mode,tier])
     for id in g.skill_levels:verify(g.slv(id)<=int(skills.info(id).max),"skill cap "+id)
     verify(g.advance_block()!="" if tier==5 else g.advance_block()=="","job advance gate")
     verify(skills.tier_name(job,tier,branch)!="?","missing job name")
     g.past_job_levels.append(g.job_level)
 print("PASS_PHASE careers checks=",checks)
 reset()
 for level in range(1,99):verify(g.exp_required(level+1)>g.exp_required(level),"EXP curve "+str(level))
 g.add_exp(2000000000)
 verify(g.base_level==99 and g.base_exp==0,"base level cap")
 verify(g.job_level==10 and g.job_exp==0,"novice job cap")
 verify(not g.advance_job("invalid"),"reject invalid promotion")
 g.allocate_build("balanced")
 verify(g.advance_job("mage"),"novice to mage")
 verify(g.job_tier==1 and g.job_level==1,"promotion reset")
 for id in skills.SKILLS:
  var s=skills.info(id)
  verify(int(s.max)>0,"invalid skill max "+id)
  for dep in s.get("req",{}):verify(not skills.info(dep).is_empty(),"missing skill prerequisite "+id+":"+dep)
  for level in [1,int(s.max)]:
   verify(skills.sp_cost(id,level)>=0 and skills.cooldown(id,level)>=0,"negative skill cost "+id)
 print("PASS_PHASE levels and skills checks=",checks)
 # Every drop/recipe references a real item and recipe materials have a gameplay source.
 var drops: Dictionary={}
 var names: Dictionary={}
 for zone in spawner.ZONES:
  verify(not names.has(zone.name),"duplicate monster name "+zone.name)
  names[zone.name]=true
  verify(zone.lv>=1 and zone.lv<=99 and zone.count>=1,"bad monster values "+zone.name)
  for drop in zone.get("drops",[]):
   verify(items.DB.has(drop[0]),"unknown drop "+str(drop[0]))
   verify(drop[1]>0 and drop[1]<=1,"drop chance "+zone.name)
   drops[drop[0]]=true
 var recipes:Array=[]
 for category in ["weapons","hats","armor","accessories","materials"]:recipes.append_array(g.crafting_recipes(category))
 recipes.append_array(g.WING_RECIPES);recipes.append_array(g.fashion_recipes())
 var recipe_products:Dictionary={}
 for recipe in recipes:recipe_products[recipe.id]=true
 for recipe in recipes:
  verify(items.DB.has(recipe.id),"unknown recipe product "+recipe.id)
  verify(int(recipe.zeny)>=0 and not recipe.mats.is_empty(),"invalid recipe "+recipe.id)
  for material in recipe.mats:
   verify(items.DB.has(material),"unknown material "+material)
   verify(int(recipe.mats[material])>0,"nonpositive material cost")
   verify(drops.has(material) or not gather.sources(material).is_empty() or recipe_products.has(material),"unobtainable material "+recipe.id+":"+material)
  reset();g.base_level=99;g.job_id="mage";g.job_tier=5;g.zeny=10000000;g.inventory=recipe.mats.duplicate()
  verify(g.can_craft(recipe),"fully supplied recipe blocked "+recipe.id)
  var before=g.zeny
  verify(g.craft(recipe),"craft failed "+recipe.id)
  verify(g.zeny==before-int(recipe.zeny),"wrong craft charge "+recipe.id)
  for material in recipe.mats:verify(g.count(material)==0,"wrong material use "+recipe.id)
  var fashion=g.fashion_for_recipe(recipe.id)
  verify(g.owns_fashion(fashion) if fashion!="" else g.count(recipe.id)==1,"craft output missing "+recipe.id)
  verify(not g.craft(recipe),"duplicate unsupplied craft "+recipe.id)
 print("PASS_PHASE monsters/recipes count=",recipes.size()," checks=",checks)
 reset()
 verify(story.STEPS[-1].goal.need==80,"story endpoint")
 var ids:Dictionary={}
 for quest in story.STEPS:
  verify(not ids.has(quest.id),"duplicate main quest "+quest.id);ids[quest.id]=true
  if quest.goal.type=="kill":verify(names.has(quest.goal.target),"missing story monster "+quest.goal.target)
 for quest in side.TASKS:
  verify(names.has(quest.target),"missing side monster "+quest.target)
  g.quests={};g.start_quest(quest.id,quest.title,quest.target,quest.need,quest.giver)
  for i in quest.need:g.on_kill(quest.target)
  verify(g.quests[quest.id].state=="done","quest kill count "+quest.id)
  verify(side.claim(quest.id),"quest claim "+quest.id)
  var before=g.zeny
  verify(not side.claim(quest.id) and g.zeny==before,"double quest reward "+quest.id)
 print("PASS_PHASE quests checks=",checks)
 reset()
 # Full five-slot JSON/cloud round trip in isolated test storage.
 var store=load("res://scripts/game/account_save_store.gd")
 for slot in range(5):
  g.slot=slot;g.player_name="Audit"+str(slot);g.base_level=10+slot;g.inventory={"potion_red":slot+1,"gold_ore":slot+2};g.save_point=Vector3(slot*3,.1,slot*4);g.save_game()
 var payload=store.sanitize(JSON.parse_string(JSON.stringify(store.capture(""))))
 verify(store.valid(payload),"captured bundle validation")
 verify(store.install("qa_audit",payload),"cloud bundle install")
 var roundtrip=store.capture("qa_audit")
 for slot in range(5):
  var expected:Dictionary=payload.slots[slot].duplicate(true)
  var restored:Dictionary=JSON.parse_string(JSON.stringify(roundtrip.slots[slot]))
  var point:Array=expected.save_point
  var back:Array=restored.save_point
  for axis in 3:verify(is_equal_approx(float(point[axis]),float(back[axis])),"save point roundtrip")
  expected.erase("save_point");restored.erase("save_point")
  verify(expected==restored,"cloud slot roundtrip "+str(slot))
 verify(not store.install("../invalid",payload),"unsafe account id")
 for slot in range(5):
  verify(g.load_game(slot),"slot load "+str(slot))
  verify(g.player_name=="Audit"+str(slot) and g.base_level==10+slot and g.count("gold_ore")==slot+2,"slot contamination "+str(slot))
 print("PASS_PHASE save checks=",checks)
 print("AUDIT_CORE checks=",checks," failures=",failures.size())
 var file=FileAccess.open("user://audit_core.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures},"  "));file.close()
 quit(0 if failures.is_empty() else 1)
