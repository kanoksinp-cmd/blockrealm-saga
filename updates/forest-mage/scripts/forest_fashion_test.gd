extends Node3D
var checks=0
var failed=0
func check(ok: bool, msg: String):
	checks+=1
	if not ok:failed+=1;push_error(msg)
func _ready():call_deferred("run")
func run():
	Game.slot=4;Game.appearance=Avatar.default_appearance();Game.appearance.job="mage";Game.job_id="mage";Game.job="Mage"
	Game.equip=Game._empty_equip();Game.base_level=20
	Game.fashion_unlocks=[];Game.inventory={};Game.zeny=0
	var recipe: Dictionary=Game.FOREST_MAGE_RECIPE
	check(not Game.set_mage_fashion("forest_mage"),"cannot wear before crafting")
	check(not Game.craft(recipe) and not Game.owns_mage_fashion(),"missing resources prevent unlock")
	for id in recipe.mats:Game.inventory[id]=int(recipe.mats[id])+1
	Game.zeny=int(recipe.zeny)-1
	check(not Game.craft(recipe),"insufficient Zeny blocks crafting")
	Game.zeny=int(recipe.zeny);Game.job_id="swordsman"
	check(not Game.craft(recipe),"nonmage cannot craft")
	Game.job_id="mage"
	var cheap=recipe.duplicate(true);cheap.zeny=0
	check(not Game.craft(cheap),"altered recipe rejected")
	check(Game.craft(recipe) and Game.owns_mage_fashion(),"craft permanently unlocks fashion")
	check(Game.zeny==0,"exact currency deducted")
	for id in recipe.mats:check(Game.count(id)==1,"exact material deduction "+id)
	check(Game.count("forest_mage_fashion")==0,"permanent unlock does not clutter inventory")
	for id in recipe.mats:Game.inventory[id]=99
	Game.zeny=99999;var mats_before=Game.inventory.duplicate(true)
	check(not Game.craft(recipe) and Game.zeny==99999 and Game.inventory==mats_before,"duplicate craft never consumes resources")
	Game.save_game()
	Game.slot=3;Game.new_character("QA fresh",Avatar.default_appearance())
	check(not Game.owns_mage_fashion(),"new character has no unlock")
	check(Game.load_game(4) and Game.owns_mage_fashion(),"crafted unlock persists per character")
	var legacy=ConfigFile.new();legacy.load(Game.slot_path(4));legacy.erase_section_key("char","fashion_unlocks")
	var legacy_look=legacy.get_value("char","appearance");legacy_look.fashion="forest_mage";legacy.set_value("char","appearance",legacy_look);legacy.save(Game.slot_path(2))
	check(Game.load_game(2) and not Game.owns_mage_fashion() and Game.appearance.get("fashion", "")=="","old free fashion save must craft first")
	check(Game.load_game(4) and Game.owns_mage_fashion(),"switching slots restores original ownership")
	var stats_before=[Game.atk(),Game.def(),Game.max_hp(),Game.max_sp(),Game.inventory.duplicate(true),Game.zeny,Game.equip.duplicate(true)]
	check(Game.set_mage_fashion("forest_mage"),"mage can equip")
	check([Game.atk(),Game.def(),Game.max_hp(),Game.max_sp(),Game.inventory,Game.zeny,Game.equip]==stats_before,"cosmetics never alter stats or inventory")
	check(not Game.set_mage_fashion("unknown"),"unknown fashion rejected")
	Game.job_id="swordsman";check(not Game.set_mage_fashion("forest_mage"),"other class rejected")
	Game.job_id="mage";Game.save_game();Game.appearance.fashion="";check(Game.load_game(4) and Game.appearance.fashion=="forest_mage","saved fashion survives load")
	var net=get_node("/root/Net")
	var info=net._clean_info({"look":Game.appearance,"job":"mage"})
	check(info.look.get("fashion", "")=="forest_mage","fashion travels through network look sanitizer")
	var model=KnightModel.new();add_child(model)
	check(model.weapon_kind=="staff","fashion staff has casting pose")
	for part in ["head","torso","arm_l","arm_r","leg_l","leg_r"]:
		var holder: Node3D=model.get(part)
		check(holder.get_child_count()>1,"mesh attached to "+part)
	var pets=model.get_node_or_null("ForestSpirits")
	check(pets!=null,"both spirits present")
	var players=pets.find_children("*","AnimationPlayer",true,false)
	check(players.size()>0,"pet animation imported")
	for ap in players:check(ap.is_playing(),"pet animation autoplays")
	model.set_moving(true);model._process(.1);check(abs(model.leg_l.rotation.x)>.01,"walk animates dressed legs")
	model.set_moving(false);check(model.skill_attack("cast_bolt"),"cast animation works")
	for i in range(80):model._process(.02)
	check(Game.set_mage_fashion(""),"unequip succeeds")
	check(not Game.appearance.has("weapon_model"),"original equipped weapon stays untouched")
	check(Game.set_mage_fashion("forest_mage"),"reequip succeeds")
	var ui=load("res://scripts/ui/ro_ui.gd").new();add_child(ui)
	ui._smith_tab=7;ui._fill_smith()
	check(ui._smith_tabs.size()==8,"fashion recipe tab exists")
	ui._inv.panel.show();ui._open_mage_fashion()
	check(ui._dialog.panel.visible,"wardrobe menu opens")
	ui._dialog.panel.hide();ui._inv.panel.hide()
	# Clean display stage for reviewing the real in-game imported model.
	var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("202d28");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("e1ebd9");env.ambient_light_energy=.8;world.environment=env;add_child(world)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-35,0);sun.light_energy=1.2;add_child(sun)
	var camera=Camera3D.new();add_child(camera);camera.position=Vector3(2.1,1.8,4.3);camera.look_at(Vector3(0,1.05,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=3.1;camera.make_current()
	ui.hide()
	if DisplayServer.get_name()!="headless":
		for i in range(8):await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://forest_mage_game_preview.png")
	print("FOREST_FASHION_QA: %d checks, %d failures" % [checks,failed])
	get_tree().quit(1 if failed else 0)

