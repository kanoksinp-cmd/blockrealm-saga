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

