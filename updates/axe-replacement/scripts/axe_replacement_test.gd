extends Node3D
var failures=0
var checks=0
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures+=1;push_error(msg)
func _ready():call_deferred("run")
func run():
	Game.slot=4;Game.job_id="merchant";Game.appearance=Avatar.default_appearance();Game.appearance.job="merchant";Game.equip=Game._empty_equip()
	var ids=["hand_axe","battle_axe","frost_axe","arcane_axe"]
	var expected=[[27,800,80],[46,3400,100],[96,11000,110],[140,32000,110]]
	for i in range(4):
		var id: String=ids[i];var info=Items.info(id)
		check([info.atk,info.price,info.weight]==expected[i],"original stats preserved "+id)
		check(info.model=="reforged_"+id,"replacement mapping "+id)
		check(ResourceLoader.exists("res://assets/models/arcane/"+info.model+".glb"),"mesh resource exists")
		Game.equip.weapon=id;Game.refine[id]=5
		var look=Game.dressed_appearance()
		check(look.weapon_model==info.model and look.glow_w==5,"existing equipment and refine preserved")
		var model=KnightModel.new();model.appearance=look;add_child(model)
		check(model.sword.get_child(0).name==info.model,"new mesh actually assembled "+id)
		check(model.sword.find_children("*","MeshInstance3D",true,false).size()==1,"optimized single-mesh 3D axe")
		check(model.skill_attack("spin"),"axe attack animation starts")
		for n in range(40):model._process(.03)
		check(not model.is_attacking(),"axe attack finishes")
		check(Items.icon(id)!=null,"inventory icon loads")
		model.free()
	var rig:Dictionary={"arm_r":Node3D.new()};add_child(rig.arm_r)
	var starter=Avatar.attach_weapon(rig,"merchant")
	check(starter.get_child(0).name=="reforged_hand_axe","starter preview does not use old sprite")
	Game.save_game();Game.equip.weapon="";check(Game.load_game(4) and Game.equip.weapon=="arcane_axe","existing save ID retained")
	print("AXE_QA: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

