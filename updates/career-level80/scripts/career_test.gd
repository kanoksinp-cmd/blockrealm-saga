extends Node
var checks=0
var failures=0
func check(ok: bool, label: String):
	checks+=1
	if not ok:failures+=1;push_error(label)
func _ready():call_deferred("run")
func run():
	var g=get_tree().root.get_node("Game")
	g.slot=4
	g.story_step=0;g.bonus_skill_points=0
	for job in SkillDB.JOB_SKILLS:
		for br in ["a","b"]:
			g.job_id=job;g.job_branch=br;g.base_level=99
			g.skill_levels={};g.past_job_levels=[10]
			for tier in range(1,6):
				g.job_tier=tier;g.job_level=SkillDB.JOB_MAX[tier]
				g.sync_skill_budget()
				check(g.skill_points>=0,"nonnegative budget")
				g.allocate_build("balanced")
				check(g.skill_points==0,"all available points spendable %s %s %d" % [job,br,tier])
				for id in g.skill_levels:
					check(g.slv(id)<=int(SkillDB.info(id).max),"rank cap")
				check((g.advance_block()!="") if tier==5 else (g.advance_block()==""),"promotion gating")
				check(SkillDB.tier_name(job,tier,br)!="?","valid title")
				g.past_job_levels.append(g.job_level)
			check(SkillDB.tier_skills(job,4,br).size()==3 and SkillDB.tier_skills(job,5,br).size()==3,"advanced skill lists")
	g.job_id="mage";g.job_branch="a";g.job_tier=3;g.job_level=40;g.base_level=44
	check(g.advance_block()!="","tier 4 base level gate")
	g.base_level=45;check(g.advance_block()=="","tier 4 ready")
	check(g.advance_job() and g.job_tier==4 and g.job_level==1,"actual promotion resets job level")
	g.job_tier=4;g.job_level=30;g.base_level=64;check(g.advance_block()!="","tier 5 base gate")
	g.base_level=65;check(g.advance_job() and g.job_tier==5,"actual tier 5 promotion")
	for lv in range(1,99):check(g.exp_required(lv+1)>g.exp_required(lv),"monotonic exp")
	g.base_level=60
	check(g.monster_exp_multiplier(60)==1.0,"same level full exp")
	check(g.monster_exp_multiplier(30)==0.1,"weak enemy penalty")
	check(g.monster_exp_multiplier(65)>1.0,"challenging enemy bonus")
	check(Story.STEPS[-1].goal.need==80,"story ends at 80")
	var ids={}
	for task in Story.STEPS:
		check(not ids.has(task.id),"unique story IDs");ids[task.id]=true
		check(task.chapter<Story.CHAPTERS.size(),"valid chapter")
		if task.goal.type=="kill":check(preload("res://scripts/monsters/spawner.gd").ZONES.any(func(z):return z.name==task.goal.target),"spawn exists: "+task.goal.target)
	for task in SideQuests.TASKS:
		check(preload("res://scripts/monsters/spawner.gd").ZONES.any(func(z):return z.name==task.target),"side target exists")
		g.quests={};g.start_quest(task.id,task.title,task.target,task.need,task.giver)
		for n in range(task.need):g.on_kill(task.target)
		check(g.quests[task.id].state=="done","side kill completion")
		check(SideQuests.claim(task.id),"side claim")
		var gold=g.zeny
		check(not SideQuests.claim(task.id) and g.zeny==gold,"no double reward")
	g.story_step=0;g.quests={};Story.complete();check(g.story_step==0,"unaccepted story cannot complete")
	g.save_game();var saved_tier=g.job_tier;var saved_lv=g.base_level
	g.job_tier=0;g.base_level=1
	check(g.load_game(4) and g.job_tier==saved_tier and g.base_level==saved_lv,"save round trip")
	var ui=load("res://scripts/ui/ro_ui.gd").new();add_child(ui)
	g.job_id="swordsman";g.job_branch="a";g.job_tier=5;g.job_level=30;g.job="Dragon Knight";g.skill_levels={};g.sync_skill_budget();g.allocate_build("attack")
	for tier in range(6):
		ui._skill_tab=tier;ui._refresh_skills()
		check(ui._skill_tabs.size()==6,"all tiers rendered")
	ui._skill_tab=5;ui._refresh_skills();ui._skills.panel.show()
	if DisplayServer.get_name()!="headless":
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://career_preview.png")
	print("CAREER QA: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

