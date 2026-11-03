extends Node3D
class LampVillage extends VillageBuilder:
	func _ready():pass
var checks=0
var failed=0
func check(ok:bool,msg:String):
	checks+=1
	if not ok:failed+=1;push_error(msg)
func _ready():call_deferred("run")
func run():
	var village=LampVillage.new();add_child(village);village.w=BlockWorld.new()
	village._lamps()
	check(village.get_child_count()==18,"all 18 street posts replaced")
	check(village.lamp_points.size()==18,"18 registered light positions")
	for i in 18:
		var post=village.get_child(i)
		check(post.get_meta("street_lantern",false),"new street lantern instance")
		var marker=post.find_child("LightCenter",true,false)
		check(marker!=null,"exported lantern light marker exists")
		if marker:check(marker.global_position.distance_to(village.lamp_points[i])<.01,"rotated light aligns with hanging cage")
		check(post.get_child(post.get_child_count()-1) is CollisionShape3D,"solid lantern base")
		var c=VillageBuilder.STREET_LAMP_SPOTS[i]
		for y in 3:check(village.w.getb(c.x,y,c.y)==0,"old block pole removed")
	village._build_nav()
	for c in village._lamp_cells:check(village.astar.is_point_solid(c),"NPCs route around new bases")
	VillageBuilder.current=village
	var player=Node3D.new();add_child(player);player.add_to_group("player")
	var cycle=load("res://scripts/world/day_night.gd").new();add_child(cycle);cycle.set_process(false)
	cycle.hour=22.;cycle._apply();cycle._place_lamps()
	for lamp in cycle._lights:
		check(lamp.visible and lamp.light_energy>1.,"night lamps illuminate")
		check(village.lamp_points.has(lamp.global_position),"pooled lights use new cage positions")
	cycle.hour=12.;cycle._apply()
	for lamp in cycle._lights:check(not lamp.visible and is_zero_approx(lamp.light_energy),"day lamps switch off")
	var real_town=LampVillage.new();add_child(real_town);real_town.w=BlockWorld.new()
	real_town.fine=load("res://scripts/voxel/micro_voxel.gd").new();real_town.fine.cell_size=.2
	real_town._rng.seed=7
	real_town._outside_roads();real_town._streets();real_town._town_wall();real_town._castle();real_town._plaza();real_town._town_plots();real_town._lamps()
	print("ACTUAL TOWN LAMPS: ",real_town._lamp_cells.size()," cells: ",real_town._lamp_cells)
	check(real_town._lamp_cells.size()>0,"street lamps spawn in actual town")
	for c in VillageBuilder.STREET_LAMP_SPOTS:
		check(real_town._lamp_cells.has(c) == (real_town.w.getb(c.x,0,c.y)==0),"all original eligible street lamp sites replaced")
	VillageBuilder.current=null
	print("LANTERN CHECKS: ",checks," FAILED: ",failed)
	get_tree().quit(1 if failed else 0)
