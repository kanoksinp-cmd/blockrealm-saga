extends Node3D
var checks=0
var failed=0
func check(ok:bool,msg:String):
	checks+=1
	if not ok:failed+=1;push_error(msg)
func _ready():call_deferred("run")
func run():
	Game.slot=4;Game.appearance=Avatar.default_appearance();Game.job_id="swordsman";Game.appearance.job="swordsman";Game.equip=Game._empty_equip();Game.inventory={};Game.base_level=25;Game.refine={}
	check(Game.HAT_RECIPES.size()==21,"21 headwear recipes")
	var seen:Dictionary={}
	for category in ["weapons","hats","armor","accessories","materials"]:
		for recipe in Game.crafting_recipes(category):
			check(not seen.has(recipe.id),"recipe listed in just one category "+recipe.id);seen[recipe.id]=true
			var it:=Items.info(recipe.id)
			if category=="weapons":check(it.type=="weapon","weapon category")
			if category=="hats":check(it.type=="armor" and it.slot=="head","headwear category")
			if category=="accessories":check(it.slot=="accessory","accessory category")
	for recipe in Game.crafting_recipes("weapons","bow"):check(Items.weapon_type(recipe.id)=="bow","bow subcategory")
	for recipe in Game.HAT_RECIPES:
		check(seen.has(recipe.id),"new hat discoverable in crafting")
		for id in recipe.mats:Game.inventory[id]=int(recipe.mats[id])+1
		Game.zeny=int(recipe.zeny)+100
		check(Game.craft(recipe) and Game.count(recipe.id)>0,"hat actually crafts")
		check(Game.equip_item(recipe.id) and Game.equip.head==recipe.id,"hat can be equipped")
		var model=KnightModel.new();model.appearance=Game.dressed_appearance();add_child(model)
		check(model.head.find_child(String(Items.info(recipe.id).look.model),true,false)!=null,"hat attached to head joint")
		check(ItemModels.mesh(recipe.id)!=null,"new hat inventory/drop 3D mesh")
		model.free()
	for id in ["potion_red","potion_blue","iron_sword","crystal_sword"]:
		var mesh=ItemModels.mesh(id)
		check(mesh!=null and mesh.get_aabb().size.z>.12,"new true-3D item body "+id)
	check(Items.info("potion_red").heal_hp==70 and Items.info("potion_blue").heal_sp==40,"potion effects unchanged")
	Game.equip.head="hat_indigo_wizard_hat";Game.equip.garment="travel_cape";Game.refine["travel_cape"]=5
	var plain=KnightModel.new();plain.appearance=Game.dressed_appearance();add_child(plain)
	var wind=plain.get_node_or_null("CapeWind");check(wind!=null,"equipped cape receives wind")
	if wind:
		check(wind.cloth_materials.size()>0,"cloth shaders installed")
		check(wind.cloth_materials.size()>=2,"refine aura deforms with the cape")
		wind._process(.5);check(wind.cloth_materials[0].get_shader_parameter("wind_time")>.4,"idle clock animates cape")
		check(wind.cloth_materials[0].get_shader_parameter("cape_top")>wind.cloth_materials[0].get_shader_parameter("cape_bottom"),"top anchor and weighted hem")
		check(plain.find_child("g_cape",true,false).mesh.surface_get_array_len(0)>100,"cape has flexible vertex grid")
	Game.equip.weapon="iron_sword";var sword=Avatar.assemble(Node3D.new(),Game.dressed_appearance())
	check(sword.weapon.get_child(0).name=="basic_iron_sword","starter sword visual replaced")
	sword.hips.get_parent().free()
	var npc=NPC.new();npc.npc_name="Merchant Toma";npc.role="shop";npc.position=Vector3(2,0,0);add_child(npc)
	check(npc.get_node_or_null("PotionStall")!=null,"merchant has medicine stall")
	check(npc.talk_spot.distance_to(npc.global_position)>2 and npc.reach>=3,"counter has accessible approach point")
	check(npc.get_children().filter(func(c):return c is CollisionShape3D).size()==2,"stall collision remains clickable NPC")
	Game.save_game();var chosen=Game.equip.head;Game.equip.head="";check(Game.load_game(4) and Game.equip.head==chosen,"headgear saves normally")
	var ui=load("res://scripts/ui/ro_ui.gd").new();add_child(ui)
	for tab in [1,8,9,10,2,7,6]:ui._smith_tab=tab;ui._fill_smith()
	check(ui._smith_tabs.size()==8,"categorized crafting UI builds")
	ui.open_smith("Blacksmith Doran",4);check(ui._smith_tab==1 and ui._craft_weapon_kind=="bow","legacy bow action routes to new category")
	# In-engine preview of headgear, wind cape and medicine counter.
	ui.hide();plain.position=Vector3(-2.0,0,0)
	var rear=KnightModel.new();rear.appearance=plain.appearance;add_child(rear);rear.position=Vector3(-.7,0,0);rear.rotation.y=PI-.3
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("24353b");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=.7;env.environment=e;add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-25,0);sun.light_energy=1.0;add_child(sun)
	var camera=Camera3D.new();add_child(camera);camera.position=Vector3(4,3.7,7);camera.look_at(Vector3(.6,1,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=7;camera.make_current()
	if DisplayServer.get_name()!="headless":
		for i in range(30):await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://town_update_game_preview.png")
		ui.show();ui.open_smith("Blacksmith Doran",8)
		for i in range(4):await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://crafting_categories_preview.png")
	print("TOWN_UPDATE_QA: %d checks, %d failures" % [checks,failed])
	get_tree().quit(1 if failed else 0)
