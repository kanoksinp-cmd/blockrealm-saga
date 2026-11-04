@tool
class_name VillageBuilder
extends Node3D
## Starter town "Aldenvale" built from 1 m pixel-textured blocks (block-game style):
## a rectangular stone-brick town wall with crenellations, square corner towers and
## red / white banners, three gatehouses, a grid of cobblestone streets, grass
## plots with half-timbered houses (steep brown roofs), fenced farm plots, lamp
## posts, a central plaza with a fountain and a great castle against the north wall.
## Outside: farms, forest, rocks, drifting clouds.
## Tick `rebuild` or change `seed_value` in the Inspector to regenerate.

const VillagerScript := preload("res://scripts/world/villager.gd")

@export var seed_value: int = 7:
	set(v):
		seed_value = v
		if is_inside_tree():
			build()
@export var rebuild: bool = false:
	set(v):
		if v and is_inside_tree():
			build()
@export var villager_count: int = 26

# block ids (see BlockWorld.BLOCKS)
const GRASS := 1
const DIRT := 2
const STONE := 3
const COBBLE := 4
const BRICK := 5
const PLANKS := 6
const LOG := 7
const LEAVES := 8
const LEAVES_A := 9
const PINE := 10
const PATH := 11
const GRAVEL := 12
const WATER := 13
const PLASTER := 14
const ROOF_RED := 15
const ROOF_ORANGE := 16
const ROOF_BROWN := 17
const GLASS := 18
const FARM := 19
const WOOL_RED := 20
const WOOL_Y := 22
const WOOL_G := 23
const WOOL_B := 24
const HAY := 25
const GOLD := 26
const TIMBER := 27
const DOOR := 28
const GLOW := 29
const IRON := 30
const PLAZA := 31
const DOOR_TOP := 33
const DARK_PLANKS := 34
const BOOKSHELF := 35
const BARREL := 36
const RUG_RED := 37
const RUG_GREEN := 38
const SLATE := 39
const VOID := 40
const STONE_TILE := 41
const BANNER := 42

# town wall rectangle (outer edge, inclusive)
const X0 := -36
const X1 := 36
const Z0 := -46
const Z1 := 36
const WALL_T := 3
const WALL_H := 7
# castle (inside, against the north wall)
const CX0 := -17
const CX1 := 17
const CZ0 := -43
const CZ1 := -19

const DETAIL_GRID := 0.2
const DETAIL_UNITS := 5
var fine: RefCounted
var w: BlockWorld
var _rng := RandomNumberGenerator.new()
var _trees: Array[Vector2] = []
var _field_rects: Array[Rect2i] = []
var lamp_points: Array[Vector3] = []
var _lamp_cells: Array[Vector2i] = []
const STREET_LAMP_SPOTS := [Vector2i(3, 24), Vector2i(-4, 24), Vector2i(3, 12), Vector2i(-4, 12), Vector2i(3, -11), Vector2i(-4, -11),
		Vector2i(-23, 3), Vector2i(23, -3), Vector2i(-23, -12), Vector2i(23, 15), Vector2i(-17, 20), Vector2i(17, 20),
		Vector2i(-30, -3), Vector2i(30, 3), Vector2i(-10, -17), Vector2i(10, -17), Vector2i(-23, 30), Vector2i(23, 30)]
var astar: AStarGrid2D
static var current: VillageBuilder
const NAV_HALF := 200

## Separate "maps" (RO-style): walking into a warp moves you between areas.
## Guild interiors sit east of the town; the four regions and their dungeons
## lie far away (see Zones) and are only built when first visited.
const AREAS := {"chivalry_d": Rect2(2530,330,140,140), "abyss_d": Rect2(2930,330,140,140), "valhalla_d": Rect2(3330,330,140,140),"smithy": Rect2(140,64,40,36),"guild1": Rect2(136, -26, 58, 50), "guild2": Rect2(136, 16, 54, 46),
	"verdant": Rect2(880, -120, 240, 240), "desert": Rect2(1280, -120, 240, 240),
	"frost": Rect2(1680, -120, 240, 240), "ember": Rect2(2080, -120, 240, 240),
	"verdant_d": Rect2(930, 330, 140, 140), "desert_d": Rect2(1330, 330, 140, 140),
	"frost_d": Rect2(1730, 330, 140, 140), "ember_d": Rect2(2130, 330, 140, 140)}
const AREA_NAMES := {"chivalry_d":"Fallen Chivalry", "abyss_d":"Abyss Sanctuary", "valhalla_d":"Valhalla Ruins","smithy": "Doran's Smithy","town": "Aldenvale", "guild1": "Adventurers' Guild", "guild2": "Guild Master's Hall",
	"verdant": "Verdant Ruins", "desert": "Sunscorch Desert", "frost": "Frostpeak Glacier", "ember": "Emberfall Volcano",
	"verdant_d": "Overgrown Temple", "desert_d": "Tomb of the Sun King", "frost_d": "Frozen Hollow", "ember_d": "Magma Core"}
const WARPS := [
	{"area":"ember_d","pos":Vector2(2208.5,342.5),"r":1.2,"to":"chivalry_d","dest":Vector3(2600.5,0,449),"yaw":3.14},
	{"area":"chivalry_d","pos":Vector2(2600.5,454),"r":1.2,"to":"ember_d","dest":Vector3(2208.5,0,346.5),"yaw":0.0},
	{"area":"chivalry_d","pos":Vector2(2608.5,342.5),"r":1.2,"to":"abyss_d","dest":Vector3(3000.5,0,449),"yaw":3.14},
	{"area":"abyss_d","pos":Vector2(3000.5,454),"r":1.2,"to":"chivalry_d","dest":Vector3(2608.5,0,346.5),"yaw":0.0},
	{"area":"abyss_d","pos":Vector2(3008.5,342.5),"r":1.2,"to":"valhalla_d","dest":Vector3(3400.5,0,449),"yaw":3.14},
	{"area":"valhalla_d","pos":Vector2(3400.5,454),"r":1.2,"to":"abyss_d","dest":Vector3(3008.5,0,346.5),"yaw":0.0},
	{"area":"town", "pos":Vector2(18.0,9.6), "r":1.0, "to":"smithy", "dest":Vector3(160.5,0,85.5), "yaw":3.14},
	{"area":"smithy", "pos":Vector2(160.5,88.5), "r":1.1, "to":"town", "dest":Vector3(18.0,0,12.0), "yaw":0.0},
	{"area": "town", "pos": Vector2(-11.0, -2.6), "r": 1.0, "to": "guild1", "dest": Vector3(164.5, 0, 6.4), "yaw": 3.14},
	{"area": "guild1", "pos": Vector2(164.5, 9.5), "r": 1.2, "to": "town", "dest": Vector3(-11.0, 0, -0.3), "yaw": 0.0},
	{"area": "guild1", "pos": Vector2(178.0, -1.0), "r": 1.0, "to": "guild2", "dest": Vector3(156.5, 0, 44.5), "yaw": 1.57},
	{"area": "guild2", "pos": Vector2(152.5, 44.5), "r": 1.0, "to": "guild1", "dest": Vector3(175.5, 0, 0.6), "yaw": -1.57},
	# town fields <-> regions
	{"area": "town", "pos": Vector2(-114.5, 0.5), "r": 1.3, "to": "verdant", "dest": Vector3(1088.5, 0, 0.5), "yaw": -1.57},
	{"area": "verdant", "pos": Vector2(1093.5, 0.5), "r": 1.3, "to": "town", "dest": Vector3(-109.5, 0, 0.5), "yaw": 1.57},
	{"area": "town", "pos": Vector2(0.5, 114.5), "r": 1.3, "to": "desert", "dest": Vector3(1400.5, 0, -88.5), "yaw": 0.0},
	{"area": "desert", "pos": Vector2(1400.5, -93.5), "r": 1.3, "to": "town", "dest": Vector3(0.5, 0, 109.5), "yaw": 3.14},
	{"area": "town", "pos": Vector2(114.5, 0.5), "r": 1.3, "to": "frost", "dest": Vector3(1711.5, 0, 0.5), "yaw": 1.57},
	{"area": "frost", "pos": Vector2(1706.5, 0.5), "r": 1.3, "to": "town", "dest": Vector3(109.5, 0, 0.5), "yaw": -1.57},
	{"area": "verdant", "pos": Vector2(1055.5, -93.5), "r": 1.3, "to": "ember", "dest": Vector3(2111.5, 0, 30.5), "yaw": 1.57},
	{"area": "ember", "pos": Vector2(2106.5, 30.5), "r": 1.3, "to": "verdant", "dest": Vector3(1055.5, 0, -88.5), "yaw": 3.14},
	{"area": "frost", "pos": Vector2(1800.5, -93.5), "r": 1.3, "to": "ember", "dest": Vector3(2230.5, 0, 88.5), "yaw": 3.14},
	{"area": "ember", "pos": Vector2(2230.5, 93.5), "r": 1.3, "to": "frost", "dest": Vector3(1800.5, 0, -88.5), "yaw": 0.0},
	# dungeon entrances
	{"area": "verdant", "pos": Vector2(945.5, -51.0), "r": 1.2, "to": "verdant_d", "dest": Vector3(1000.5, 0, 449.0), "yaw": 3.14},
	{"area": "verdant_d", "pos": Vector2(1000.5, 454.0), "r": 1.2, "to": "verdant", "dest": Vector3(945.5, 0, -46.5), "yaw": 0.0},
	{"area": "desert", "pos": Vector2(1400.5, 44.0), "r": 1.2, "to": "desert_d", "dest": Vector3(1400.5, 0, 449.0), "yaw": 3.14},
	{"area": "desert_d", "pos": Vector2(1400.5, 454.0), "r": 1.2, "to": "desert", "dest": Vector3(1400.5, 0, 39.5), "yaw": 3.14},
	{"area": "frost", "pos": Vector2(1860.5, -51.0), "r": 1.2, "to": "frost_d", "dest": Vector3(1800.5, 0, 449.0), "yaw": 3.14},
	{"area": "frost_d", "pos": Vector2(1800.5, 454.0), "r": 1.2, "to": "frost", "dest": Vector3(1860.5, 0, -46.5), "yaw": 0.0},
	{"area": "ember", "pos": Vector2(2210.5, -41.5), "r": 1.2, "to": "ember_d", "dest": Vector3(2200.5, 0, 449.0), "yaw": 3.14},
	{"area": "ember_d", "pos": Vector2(2200.5, 454.0), "r": 1.2, "to": "ember", "dest": Vector3(2210.5, 0, -37.0), "yaw": 0.0},
]


static func area_at(p: Vector3) -> String:
	for k in AREAS:
		if (AREAS[k] as Rect2).has_point(Vector2(p.x, p.z)):
			return k
	return "town"


## First warp to take when walking from area `a` to area `b` (breadth-first over WARPS).
static func warp_towards(a: String, b: String) -> Dictionary:
	if a == b:
		return {}
	var first := {a: {}}
	var queue := [a]
	while queue.size() > 0:
		var cur: String = queue.pop_front()
		for wp in WARPS:
			if wp.area != cur or first.has(wp.to):
				continue
			first[wp.to] = wp if cur == a else first[cur]
			if wp.to == b:
				return first[b]
			queue.append(wp.to)
	return {}


## Areas whose blocks, nav grid and monsters exist already.
var built := {"smithy": true,"town": true, "guild1": true, "guild2": true}
var navs := {}
var worlds := {}
const TOWN_GATES := [Vector2i(-114, 0), Vector2i(0, 114), Vector2i(114, 0)]


func _ready() -> void:
	build()


## Builds a region / dungeon map the first time it is needed (before warping in).
func ensure_area(a: String) -> void:
	if built.has(a) or not AREAS.has(a):
		return
	built[a] = true
	var t0 := Time.get_ticks_msec()
	var bw := BlockWorld.new()
	bw.round_natural = true
	if Zones.is_field(a):
		bw.plane_tile = Zones.GROUND[a]
	var z := Zones.new(a, bw)
	z.build()
	worlds[a] = bw
	var root := Node3D.new()
	root.name = "Area_" + a
	add_child(root)
	var col := Node3D.new()
	col.name = "Colliders"
	root.add_child(col)
	var r: Rect2 = AREAS[a]
	var ctr := r.get_center()
	if Zones.is_field(a):
		root.add_child(BlockWorld.ground_plane(r.size.x * 0.5 - 6.0, Zones.GROUND[a], ctr))
	else:
		root.add_child(BlockWorld.ground_plane(r.size.x * 0.5, PixelTex.VOID, ctr))
	LP.box_collider(col, Vector3(r.size.x, 1, r.size.y), Transform3D(Basis(), Vector3(ctr.x, -0.5, ctr.y)))
	bw.build(root, col)
	# nav grid for this map
	var g := AStarGrid2D.new()
	g.region = Rect2i(r)
	g.cell_size = Vector2(1, 1)
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	g.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	g.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	g.update()
	for p: Vector3i in bw.blocks:
		if p.y < 0 or p.y > 1 or bw.no_collide.has(bw.blocks[p]):
			continue
		var cc := Vector2i(p.x, p.z)
		if g.is_in_boundsv(cc):
			g.set_point_solid(cc, true)
	for cc in z.nav_block:
		if g.is_in_boundsv(cc):
			g.set_point_solid(cc, true)
	if Zones.is_dungeon(a):
		# outside the rooms is solid rock
		for x in range(int(r.position.x), int(r.end.x)):
			for zz in range(int(r.position.y), int(r.end.y)):
				if bw.getb(x, -1, zz) == 0:
					g.set_point_solid(Vector2i(x, zz), true)
	navs[a] = g
	# torches
	if not Engine.is_editor_hint():
		for lp in z.lights:
			var l := OmniLight3D.new()
			l.light_color = z.light_color
			l.omni_range = 11.0
			l.light_energy = 1.3
			l.position = lp
			root.add_child(l)
		for d in z.npcs:
			var n: Node = NPCScript.new()
			n.npc_name = d[0]
			n.role = d[1]
			n.position = d[2]
			root.add_child(n)
			n.model.rotation.y = d[3]
		var sp := get_tree().get_first_node_in_group("spawner")
		if sp and sp.has_method("spawn_area"):
			sp.spawn_area(a)
		Gathering.populate(self, a, root)
	print("area %s built: %d blocks in %d ms" % [a, bw.blocks.size(), Time.get_ticks_msec() - t0])


func _grid(x: float, z: float) -> AStarGrid2D:
	var a := area_at(Vector3(x, 0, z))
	return navs.get(a, astar)


func build() -> void:
	for c in get_children():
		remove_child(c)
		c.free()
	lamp_points.clear();_lamp_cells.clear()
	_rng.seed = seed_value
	_trees.clear()
	_field_rects.clear()
	w = BlockWorld.new()
	w.plane_tile = PixelTex.GRASS_TOP
	fine = load("res://scripts/voxel/micro_voxel.gd").new()
	fine.cell_size = DETAIL_GRID
	fine.render_only = true

	_outside_roads()
	_streets()
	_town_wall()
	_castle()
	_plaza()
	_town_plots()
	_lamps()
	_fields()
	_region_gates()
	_forest()
	_details()
	_fishing_pond()
	GuildHall.build_floor1(self)
	GuildHall.build_floor2(self)
	preload("res://scripts/world/smithy.gd").build(self)

	var static_root := Node3D.new()
	static_root.name = "Blocks"
	add_child(static_root)
	var col := Node3D.new()
	col.name = "Colliders"
	add_child(col)
	static_root.add_child(BlockWorld.ground_plane())
	LP.box_collider(col, Vector3(600, 1, 600), Transform3D(Basis(), Vector3(0, -0.5, 0)))
	w.build(static_root, col)
	var detail_root := Node3D.new()
	detail_root.name = "TenCentimeterDetails"
	static_root.add_child(detail_root)
	fine.build(detail_root, col)
	_build_nav()
	current = self
	GuildHall.build_props(self, self)
	preload("res://scripts/world/smithy.gd").props(self)
	preload("res://scripts/world/structure_grid.gd").apply(get_node_or_null("GuildProps"))
	preload("res://scripts/world/structure_grid.gd").apply(get_node_or_null("BlacksmithWorkshop"))
	_warp_fx()
	_round_fountain()
	_fountain_fx()
	_clouds()
	_animals()
	_villagers()
	_npcs()
	Gathering.populate(self, "town", self)
	if not Engine.is_editor_hint():
		var amb := Ambience.new()
		amb.name = "Ambience"
		add_child(amb)


# ======================================================================
# helpers
static func _d(x: int, z: int) -> float:
	return Vector2(x + 0.5, z + 0.5).length()


## Wings only lift you off outside the town walls (fields, regions, dungeons),
## never inside the town or its buildings.
static func flight_zone(p: Vector3) -> bool:
	var a := area_at(p)
	if a in ["smithy", "guild1", "guild2"]:
		return false
	if a == "town":
		return not inside_town(p.x, p.z, 3.0)
	return true


static func inside_town(x: float, z: float, margin := 0.0) -> bool:
	return x >= X0 - margin and x <= X1 + margin and z >= Z0 - margin and z <= Z1 + margin


## local (lx, lz) of a structure -> world block, `facing`: 0 front +Z, 1 +X, 2 -Z, 3 -X
func _lw(cx: int, cz: int, facing: int, ax: int, az: int) -> Vector2i:
	match facing:
		1:
			return Vector2i(cx + az, cz - ax)
		2:
			return Vector2i(cx - ax, cz - az)
		3:
			return Vector2i(cx - az, cz + ax)
	return Vector2i(cx + ax, cz + az)


func _fill(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, id: int) -> void:
	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			for z in range(z0, z1 + 1):
				w.setb(x, y, z, id)


func _decal_rect(x0: int, z0: int, x1: int, z1: int, id: int) -> void:
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			w.decal(x, z, id)


## weathered stone: mostly stone bricks with a little cobble / plain stone mixed in
func _wall_block(x: int, y: int, z: int) -> int:
	var h := PixelTex.h(x * 7 + y * 3, z * 5 - y, 77)
	if y <= 1 and h > 0.55:
		return COBBLE
	if h > 0.93:
		return STONE
	if h > 0.86:
		return COBBLE
	return BRICK


# ======================================================================
# roads
func _outside_roads() -> void:
	for z in range(Z1, 112):
		for x in range(-2, 2):
			w.decal(x, z, PATH)
	for x in range(-80, 80):
		for z in range(58, 61):
			w.decal(x, z, PATH)
	for x in range(X1, 112):
		for z in range(-1, 2):
			w.decal(x, z, PATH)
			w.decal(-x, z, PATH)


func _streets() -> void:
	var road := COBBLE
	# ring road just inside the wall
	_decal_rect(X0 + WALL_T, Z0 + WALL_T, X1 - WALL_T, Z1 - WALL_T, road)
	_decal_rect(X0 + WALL_T + 2, Z0 + WALL_T + 2, X1 - WALL_T - 2, Z1 - WALL_T - 2, 0)
	# grand avenue from the south gate to the castle, main east-west street
	_decal_rect(-2, CZ1, 1, Z1, road)
	_decal_rect(X0, -1, X1, 1, road)
	# side streets
	_decal_rect(-21, -16, -19, Z1 - WALL_T, road)
	_decal_rect(19, -16, 21, Z1 - WALL_T, road)
	_decal_rect(X0 + WALL_T, -16, X1 - WALL_T, -14, road)
	_decal_rect(X0 + WALL_T, 17, X1 - WALL_T, 19, road)
	# gravel curbs along every street edge (gives the plots a raised look)
	var curb := []
	for x in range(X0 + WALL_T, X1 - WALL_T + 1):
		for z in range(Z0 + WALL_T, Z1 - WALL_T + 1):
			if w.getb(x, -1, z) != 0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if w.getb(x + d.x, -1, z + d.y) == road:
					curb.append(Vector2i(x, z))
					break
	for p in curb:
		w.decal(p.x, p.y, GRAVEL)


# ======================================================================
# town wall, towers, gates, banners
func _town_wall() -> void:
	for x in range(X0, X1 + 1):
		for z in range(Z0, Z1 + 1):
			var dx := mini(x - X0, X1 - x)
			var dz := mini(z - Z0, Z1 - z)
			var depth := mini(dx, dz)
			if depth >= WALL_T:
				continue
			for y in WALL_H:
				w.setb(x, y, z, _wall_block(x, y, z))
			# crenellations on the outer and inner rim, walkway between
			if (depth == 0 or depth == WALL_T - 1) and posmod(x + z, 2) == 0:
				w.setb(x, WALL_H, z, BRICK)
			# arrow slits
			if depth == 0 and y_slit(x, z):
				w.setb(x, 4, z, IRON)
	# towers: corners + mid-points of the long sides
	for p in [Vector2i(X0, Z0), Vector2i(X1, Z0), Vector2i(X0, Z1), Vector2i(X1, Z1)]:
		_sq_tower(p.x, p.y, 4, 13, true)
	for p in [Vector2i(X0, -24), Vector2i(X1, -24), Vector2i(X0, 20), Vector2i(X1, 20), Vector2i(-18, Z1), Vector2i(18, Z1)]:
		_sq_tower(p.x, p.y, 3, 10, false)
	# gatehouses: south (avenue), east + west (main street)
	_gate(Vector2i(0, Z1), true)
	_gate(Vector2i(X1, 0), false)
	_gate(Vector2i(X0, 0), false)


func y_slit(x: int, z: int) -> bool:
	return posmod(x + z, 6) == 0


## Square tower centred on (cx, cz), half-size r, height h, crenellated, optional banner.
func _sq_tower(cx: int, cz: int, r: int, h: int, banner: bool) -> void:
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var rim := absi(dx) == r or absi(dz) == r
			for y in h:
				if rim or y == h - 1 or y == 0:
					w.setb(cx + dx, y, cz + dz, _wall_block(cx + dx, y, cz + dz))
			# corbel ring one block below the top, crenels on top
			if rim:
				if posmod(dx + dz, 2) == 0:
					w.setb(cx + dx, h, cz + dz, BRICK)
				if (dx == 0 or dz == 0) and posmod(h, 2) == 1:
					pass
	# windows on each face
	for y in [3, 7]:
		if y < h - 2:
			for s in [-1, 1]:
				w.setb(cx + s * r, y, cz, GLASS)
				w.setb(cx, y, cz + s * r, GLASS)
	if banner:
		_flag(cx, h, cz)


## A tapered metal pole and a real subdivided cloth surface on each tower.
func _flag(x: int, y: int, z: int) -> void:
	var flag := Node3D.new()
	flag.set_script(preload("res://scripts/world/town_flag.gd"))
	flag.name = "TownFlag_%d_%d_%d" % [x,y,z]
	flag.position = Vector3(x+0.5,y,z+0.5)
	flag.rotation.y = -0.3
	add_child(flag)


func _gate(c: Vector2i, north_south: bool) -> void:
	# punch the opening (4 wide, 5 tall) through the wall
	for a in range(-2, 2):
		for b in range(-4, 5):
			for y in 5:
				var p := Vector2i(c.x + a, c.y + b) if north_south else Vector2i(c.x + b, c.y + a)
				w.setb(p.x, y, p.y, 0)
	# portcullis teeth + timber lintel
	for a in range(-2, 2):
		var p := Vector2i(c.x + a, c.y) if north_south else Vector2i(c.x, c.y + a)
		w.setb(p.x, 4, p.y, IRON)
		var o := Vector2i(c.x + a, c.y + 1) if north_south else Vector2i(c.x + 1, c.y + a)
		w.setb(o.x, 4, o.y, TIMBER)
	# flanking towers
	for s in [-1, 1]:
		var t := Vector2i(c.x + s * 5, c.y) if north_south else Vector2i(c.x, c.y + s * 5)
		_sq_tower(t.x, t.y, 2, 11, north_south and s == 1)
	# arch block over the gate (raised walkway between the towers)
	for a in range(-3, 3):
		for b in range(-1, 2):
			var p := Vector2i(c.x + a, c.y + b) if north_south else Vector2i(c.x + b, c.y + a)
			w.setb(p.x, WALL_H, p.y, BRICK)
			if b != 0 and posmod(a, 2) == 0:
				w.setb(p.x, WALL_H + 1, p.y, BRICK)


# ======================================================================
# castle
func _castle() -> void:
	_decal_rect(CX0, CZ0, CX1, CZ1, COBBLE)
	for x in range(CX0, CX1 + 1):
		for z in range(CZ0, CZ1 + 1):
			var edge := x <= CX0 + 1 or x >= CX1 - 1 or z <= CZ0 + 1 or z >= CZ1 - 1
			if not edge:
				continue
			for y in 8:
				w.setb(x, y, z, _wall_block(x, y, z))
			var outer := x == CX0 or x == CX1 or z == CZ0 or z == CZ1
			var inner := x == CX0 + 1 or x == CX1 - 1 or z == CZ0 + 1 or z == CZ1 - 1
			if (outer or inner) and posmod(x + z, 2) == 0:
				w.setb(x, 8, z, BRICK)
	# corner towers
	for p in [Vector2i(CX0, CZ0), Vector2i(CX1, CZ0), Vector2i(CX0, CZ1), Vector2i(CX1, CZ1)]:
		_sq_tower(p.x, p.y, 3, 13, p.y == CZ1)
	# gatehouse on the south wall with a wide stair-like approach
	for x in range(-2, 2):
		for z in range(CZ1 - 2, CZ1 + 1):
			for y in 5:
				w.setb(x, y, z, 0)
	for x in range(-2, 2):
		w.setb(x, 5, CZ1, IRON)
	for s in [-1, 1]:
		_sq_tower(s * 4 - (1 if s < 0 else 0), CZ1, 2, 12, false)
	for x in range(-6, 6):
		for z in range(CZ1 + 1, CZ1 + 4):
			w.decal(x, z, BRICK)
	for x in [-4, 3]:
		w.setb(x, 0, CZ1 + 2, LOG)
		w.setb(x, 1, CZ1 + 2, GLOW)
		lamp_points.append(Vector3(x + 0.5, 1.5, CZ1 + 2.5))
	# keep: big stone hall with corner turrets
	var kx0 := -8
	var kx1 := 7
	var kz0 := -38
	var kz1 := -26
	for x in range(kx0, kx1 + 1):
		for z in range(kz0, kz1 + 1):
			var rim := x == kx0 or x == kx1 or z == kz0 or z == kz1
			for y in 13:
				if rim or y == 12:
					w.setb(x, y, z, _wall_block(x, y, z))
			if rim and posmod(x + z, 2) == 0:
				w.setb(x, 13, z, BRICK)
	for x in [-2, -1, 0, 1]:
		w.setb(x, 0, kz1, DOOR if x == -1 or x == 0 else TIMBER)
		w.setb(x, 1, kz1, DOOR_TOP if x == -1 or x == 0 else TIMBER)
		w.setb(x, 2, kz1, TIMBER)
	for x in [-6, -4, 3, 5]:
		for y in [4, 5, 8, 9]:
			w.setb(x, y, kz1, GLASS)
	for z in [-35, -32, -29]:
		for y in [4, 5, 8, 9]:
			w.setb(kx0, y, z, GLASS)
			w.setb(kx1, y, z, GLASS)
	for p in [Vector2i(kx0, kz0), Vector2i(kx1, kz0), Vector2i(kx0, kz1), Vector2i(kx1, kz1)]:
		_sq_tower(p.x, p.y, 2, 17, p.y == kz1)
	# great tower in the middle of the keep
	_sq_tower(-1, -33, 3, 22, true)
	# side hall with a blue roof (east of the keep)
	var hx0 := 9
	var hx1 := 14
	var hz0 := -37
	var hz1 := -27
	for x in range(hx0, hx1 + 1):
		for z in range(hz0, hz1 + 1):
			var rim := x == hx0 or x == hx1 or z == hz0 or z == hz1
			if rim:
				for y in 10:
					w.setb(x, y, z, _wall_block(x, y, z) if y < 9 else TIMBER)
	for z in range(hz0 + 2, hz1 - 1, 3):
		for y in [3, 4, 6, 7]:
			w.setb(hx1, y, z, GLASS)
	var k := 0
	while hx0 - 1 + k <= hx1 + 1 - k:
		for z in range(hz0 - 1, hz1 + 2):
			w.setb(hx0 - 1 + k, 10 + k, z, WOOL_B)
			w.setb(hx1 + 1 - k, 10 + k, z, WOOL_B)
		for z in [hz0, hz1]:
			for x in range(hx0 + k, hx1 - k + 1):
				w.setb(x, 10 + k, z, BRICK)
		k += 1
	# west yard: well, hay, training dummies
	for p in [Vector2i(-13, -24), Vector2i(-12, -24), Vector2i(-13, -23)]:
		w.setb(p.x, 0, p.y, HAY)
	w.setb(-13, 1, -24, HAY)
	for p in [Vector2i(-13, -35), Vector2i(-13, -31)]:
		w.setb(p.x, 0, p.y, LOG)
		w.setb(p.x, 1, p.y, HAY)
	for x in range(-14, -10):
		for z in range(-41, -39):
			w.setb(x, 0, z, COBBLE)
	w.decal(-13, -40, WATER)
	w.decal(-12, -40, WATER)
	for p in [Vector2i(-14, -41), Vector2i(-11, -41)]:
		for y in range(1, 3):
			w.setb(p.x, y, p.y, LOG)
	_fill(-14, 3, -41, -11, 3, -40, PLANKS)


# ======================================================================
# plaza with fountain
func _plaza() -> void:
	_decal_rect(-9, -8, 8, 8, PLAZA)
	for x in range(-5, 5):
		for z in range(-5, 5):
			var d := _d(x, z)
			if d >= 3.6 and d < 4.6:
				w.setb(x, 0, z, BRICK)
			elif d < 3.6:
				w.decal(x, z, WATER)
	_fill(-1, 0, -1, 0, 2, 0, BRICK)
	for x in range(-2, 2):
		for z in range(-2, 2):
			var inner := x >= -1 and x <= 0 and z >= -1 and z <= 0
			w.setb(x, 3, z, WATER if inner else BRICK)
	w.setb(0, 4, 0, WATER)
	w.setb(-1, 4, -1, WATER)
	# the blocks above stay for collision / pathing, but the fountain you see is
	# the round one built in _round_fountain()
	for x in range(-5, 5):
		for z in range(-5, 5):
			var d := _d(x, z)
			if d < 4.6:
				w.hidden_render[Vector3i(x, -1 if d < 3.6 else 0, z)] = true
	for x in range(-2, 2):
		for z in range(-2, 2):
			for y in range(0, 5):
				if w.getb(x, y, z) != 0:
					w.hidden_render[Vector3i(x, y, z)] = true


# ======================================================================
# plots: houses, farms, gardens
func _town_plots() -> void:
	# [centre x, centre z, facing, width, depth, two_storey]
	var houses := [
		[-27, -9, 1, 7, 6, true], [14, -9, 0, 8, 6, false], [27, -9, 3, 7, 6, true],
		[-27, -36, 1, 7, 6, false], [26, -36, 3, 7, 6, false],
		[-13, 12, 1, 7, 6, false],

		[-27, 26, 1, 7, 6, true], [9, 25, 0, 7, 6, false], [15, 28, 3, 6, 6, true], [27, 26, 3, 7, 6, false],
		[-8, 28, 0, 6, 5, false],
		[-27, 11, 1, 6, 5, false],
	]
	for h in houses:
		_house(h[0], h[1], h[2], h[3], h[4], h[5])
	# The enclosed smithy is built after the town plots.
	_town_farm(Rect2i(22, 4, 10, 10), PixelTex.CABBAGE)
	_town_farm(Rect2i(-18, 21, 7, 9), PixelTex.WHEAT)
	_town_farm(Rect2i(-32, -28, 12, 8), PixelTex.CARROT)
	_town_farm(Rect2i(20, -28, 12, 8), PixelTex.WHEAT)
	# garden trees / hedges inside the walls
	for p in [Vector2i(-30, 2), Vector2i(-25, 15), Vector2i(31, 15), Vector2i(6, -11),
			Vector2i(-6, -11), Vector2i(31, 31), Vector2i(-31, 31), Vector2i(24, -12), Vector2i(-24, -12)]:
		if w.getb(p.x, 0, p.y) == 0 and w.getb(p.x, -1, p.y) == 0:
			_oak(p.x, p.y, LEAVES)
	for z in range(10, 15):
		for x in [-17, 17]:
			if w.getb(x, 0, z) == 0:
				w.setb(x, 0, z, LEAVES)
	# the Adventurers' Guild (north-west of the plaza)
	GuildHall.build_exterior(self)


func _town_farm(r: Rect2i, crop: int) -> void:
	for x in range(r.position.x, r.end.x):
		for z in range(r.position.y, r.end.y):
			var edge := x == r.position.x or x == r.end.x - 1 or z == r.position.y or z == r.end.y - 1
			if edge:
				# low fence: log posts with planks between them
				w.setb(x, 0, z, LOG if (x + z) % 3 == 0 else PLANKS)
			elif (x - r.position.x) % 4 == 2:
				w.decal(x, z, WATER)
			else:
				w.decal(x, z, FARM)
				w.plant(x, z, crop)
	# gate in the fence facing the nearest street
	var gx := r.position.x + r.size.x / 2
	w.setb(gx, 0, r.end.y - 1, 0)
	w.setb(gx, 0, r.position.y, 0)


## Half-timbered house: cobble footing, plaster walls with log posts and a timber
## band, steep brown gable roof with overhang, chimney, door facing `facing`.
func _house(cx: int, cz: int, facing: int, hw: int, hd: int, two: bool) -> void:
	var ox := hw / 2
	var oz := hd / 2
	var wall_h := 6 if two else 4
	var put := func(lx: int, y: int, lz: int, id: int) -> void:
		var p := _lw(cx, cz, facing, lx - ox, lz - oz)
		w.setb(p.x, y, p.y, id)
	for lx in hw:
		for lz in hd:
			var p := _lw(cx, cz, facing, lx - ox, lz - oz)
			w.decal(p.x, p.y, PLANKS)
			var edge := lx == 0 or lx == hw - 1 or lz == 0 or lz == hd - 1
			if not edge:
				continue
			var corner := (lx == 0 or lx == hw - 1) and (lz == 0 or lz == hd - 1)
			for y in wall_h:
				var id := PLASTER
				if y == 0:
					id = COBBLE
				elif corner:
					id = LOG
				elif y == 3 and two:
					id = TIMBER
				elif (lz == hd - 1 or lz == 0) and lx % 3 == 0:
					id = LOG
				put.call(lx, y, lz, id)
	# windows (front, back, sides) and door
	var mid := hw / 2
	for lx in range(1, hw - 1):
		if lx % 3 == 0:
			continue
		if lx != mid and lx != mid - 1:
			put.call(lx, 2, hd - 1, GLASS)
		put.call(lx, 2, 0, GLASS)
		if two:
			put.call(lx, 5, hd - 1, GLASS)
			put.call(lx, 5, 0, GLASS)
	for lz in range(1, hd - 1):
		if lz % 2 == 1:
			put.call(0, 2, lz, GLASS)
			put.call(hw - 1, 2, lz, GLASS)
	put.call(mid, 1, hd - 1, DOOR)
	put.call(mid, 2, hd - 1, DOOR_TOP)
	put.call(mid, 0, hd - 1, PLANKS)
	# door step
	var step := _lw(cx, cz, facing, mid - ox, hd - oz)
	w.decal(step.x, step.y, PLANKS)
	# steep gable roof, ridge along local X, 1 block overhang all round
	var k := 0
	while true:
		var z0 := -1 + k
		var z1 := hd - k
		if z0 > z1:
			break
		var y := wall_h + k
		for lx in range(-1, hw + 1):
			var trim := lx == -1 or lx == hw
			put.call(lx, y, z0, LOG if trim else ROOF_BROWN)
			put.call(lx, y, z1, LOG if trim else ROOF_BROWN)
			if z1 - z0 <= 1:
				for zz in range(z0, z1 + 1):
					put.call(lx, y, zz, PLANKS if trim else ROOF_BROWN)
		# gable ends: planks with a small attic window
		for lx in [0, hw - 1]:
			for zz in range(z0 + 1, z1):
				put.call(lx, y, zz, GLASS if zz == oz and k == 1 else PLANKS)
		k += 1
	# chimney
	for y in range(wall_h - 1, wall_h + k + 1):
		put.call(1, y, 1, COBBLE)
	# barrels / hay / woodpile beside the house
	put.call(hw, 0, hd - 2, HAY if _rng.randf() < 0.5 else LOG)
	if _rng.randf() < 0.5:
		put.call(-1, 0, 1, PLANKS)


	# Compressed 20 cm facade cells. Keep door/window images at their original size.
	var units := DETAIL_UNITS
	for lx in range(-1, hw + 1):
		for lz in range(-1, hd + 1):
			var world := _lw(cx, cz, facing, lx - ox, lz - oz)
			for y in range(wall_h + k + 1):
				var id := w.getb(world.x, y, world.y)
				if id in [COBBLE, PLASTER, LOG, TIMBER, PLANKS, ROOF_BROWN]:
					w.hidden_render[Vector3i(world.x, y, world.y)] = true
					if y < wall_h or (lx == 1 and lz == 1):
						fine.fill(world.x * units, y * units, world.y * units, (world.x + 1) * units - 1, (y + 1) * units - 1, (world.y + 1) * units - 1, id)
	# Each roof rise is 0.2 m; no change to the house's metre-scale footprint.
	for sx in range(-units, (hw + 1) * units):
		for sz in range(-units, (hd + 1) * units):
			var rise := mini(sz + units, (hd + 1) * units - 1 - sz)
			var local := Vector2((sx + 0.5) * DETAIL_GRID - ox, (sz + 0.5) * DETAIL_GRID - oz)
			var rotated := local.rotated(-facing * PI * 0.5)
			var shift := Vector2(0.5, 0.5) - Vector2(0.5, 0.5).rotated(-facing * PI * 0.5)
			var pos := Vector2(cx, cz) + rotated + shift
			var fx := floori(pos.x * units + 0.001)
			var fz := floori(pos.y * units + 0.001)
			fine.setb(fx, wall_h * units + rise, fz, TIMBER if sx < 0 or sx >= hw * units else ROOF_BROWN)
			if (sx >= 0 and sx < units or sx >= (hw - 1) * units and sx < hw * units) and sz >= 0 and sz < hd * units:
				var sy := wall_h * units
				while sy < wall_h * units + rise:
					var end := mini(wall_h * units + rise - 1, (floori(float(sy) / units) + 1) * units - 1)
					if w.getb(floori(pos.x), floori(float(sy) / units), floori(pos.y)) != GLASS:
						fine.column(fx, fz, sy, end, PLANKS)
					sy = end + 1


# ======================================================================
# lamp posts along the streets
func _lamps() -> void:
	var lamp_scene=preload("res://scripts/world/hanging_lantern_post.gd")
	for cell in STREET_LAMP_SPOTS:
		if w.getb(cell.x,0,cell.y)!=0:continue
		var post:=lamp_scene.make()
		add_child(post);post.position=Vector3(cell.x+.5,0,cell.y+.5)
		post.rotation.y=atan2(float(cell.y),float(-cell.x))
		_lamp_cells.append(cell)
		lamp_points.append(post.transform*lamp_scene.LIGHT_POSITION)


# ======================================================================
# farms outside the walls
func _fields() -> void:
	_field(Rect2i(-30, 44, 16, 11), PixelTex.WHEAT)
	_field(Rect2i(-30, 64, 16, 11), PixelTex.CARROT)
	_field(Rect2i(14, 44, 16, 11), PixelTex.CABBAGE)
	_field(Rect2i(14, 64, 16, 11), PixelTex.WHEAT)
	_field(Rect2i(-62, 18, 12, 9), PixelTex.FLOWER)
	_field(Rect2i(50, 18, 12, 9), PixelTex.CABBAGE)


func _field(r: Rect2i, crop: int) -> void:
	_field_rects.append(r.grow(2))
	var mid := r.position.y + r.size.y / 2
	for x in range(r.position.x, r.end.x):
		for z in range(r.position.y, r.end.y):
			if z == mid:
				w.decal(x, z, WATER)
			else:
				w.decal(x, z, FARM)
				if _rng.randf() < 0.92:
					w.plant(x, z, crop)
	for x in [r.position.x - 1, r.end.x]:
		for z in [r.position.y - 1, r.end.y]:
			w.setb(x, 0, z, LOG)


## Stone arches at the three road ends leading out to the regions.
func _region_gates() -> void:
	for g in TOWN_GATES:
		var along_x := absi(g.y) > absi(g.x)
		for side in [-1, 1]:
			var px: int = g.x + (side * 3 if along_x else 0)
			var pz: int = g.y + (0 if along_x else side * 3)
			for y in 5:
				w.setb(px, y, pz, BRICK if y % 2 else COBBLE)
			w.setb(px, 5, pz, GLOW)
		for k in range(-3, 4):
			w.setb(g.x + (k if along_x else 0), 6, g.y + (0 if along_x else k), BRICK)
		for k in range(-2, 3):
			for j in range(-3, 4):
				w.decal(g.x + (k if along_x else j), g.y + (j if along_x else k), PATH)


# ======================================================================
# forest
func _free(p: Vector2, gap := 4.0) -> bool:
	if inside_town(p.x, p.y, 6.0):
		return false
	for g in TOWN_GATES:
		if p.distance_to(Vector2(g)) < 8.0:
			return false
	if absf(p.x) < 4.0 and p.y > 30.0:
		return false
	if absf(p.y - 59.0) < 3.5:
		return false
	if absf(p.y) < 3.5:
		return false
	for r in _field_rects:
		if r.has_point(Vector2i(floori(p.x), floori(p.y))):
			return false
	for t in _trees:
		if p.distance_to(t) < gap:
			return false
	return true


func _forest() -> void:
	var placed := 0
	var tries := 0
	while placed < 230 and tries < 6000:
		tries += 1
		var p := Vector2(_rng.randf_range(-110, 110), _rng.randf_range(-115, 110)).floor()
		if p.length() > 118.0 or not _free(p):
			continue
		# keep the monster meadows a bit clearer
		if p.distance_to(Vector2(54, -6)) < 9.0 or p.distance_to(Vector2(-55, 4)) < 10.0 or p.distance_to(Vector2(58, -38)) < 9.0:
			continue
		_trees.append(p)
		placed += 1
		var roll := _rng.randf()
		if roll < 0.22:
			_pine(int(p.x), int(p.y))
		else:
			_oak(int(p.x), int(p.y), LEAVES_A if roll > 0.85 else LEAVES)


func _leaf(x: int, y: int, z: int, id: int) -> void:
	if w.getb(x, y, z) == 0:
		w.setb(x, y, z, id)


func _oak(x: int, z: int, leaf: int) -> void:
	var hgt := 4 + _rng.randi() % 2
	_fine_trunk(x, z, hgt)
	var center := Vector3(x + 0.5, hgt - 0.1, z + 0.5)
	_fine_crown(center, Vector3(2.25, 1.8, 2.1), leaf)
	_fine_crown(center + Vector3(1.1, -0.5, 0.3), Vector3(1.4, 1.25, 1.4), leaf)
	_fine_crown(center + Vector3(-0.8, -0.35, -0.7), Vector3(1.5, 1.3, 1.35), leaf)


func _fine_trunk(x: int, z: int, height: int) -> void:
	for y in height:
		w.setb(x, y, z, LOG)
		w.hidden_render[Vector3i(x, y, z)] = true
	var u := DETAIL_UNITS
	# Preserve trunk thickness (40 cm), made from 20 cm cells.
	fine.fill(x*u+1, 0, z*u+1, x*u+3, height*u-1, z*u+3, LOG)
	for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		for step in range(1, 4):
			var xx: int = x*u+2+d.x*step
			var zz: int = z*u+2+d.y*step
			fine.fill(xx,0,zz,xx+1,maxi(0,3-step/2),zz+1,LOG)
			var yy := height*u-7+step
			fine.fill(xx,yy,zz,xx+1,yy+1,zz+1,LOG)


func _fine_crown(center: Vector3, radius: Vector3, leaf: int) -> void:
	var u := DETAIL_UNITS
	# Solve the ellipsoid per X/Z column instead of allocating all interior cubes.
	for ix in range(floori((center.x-radius.x)*u), ceili((center.x+radius.x)*u)):
		for iz in range(floori((center.z-radius.z)*u), ceili((center.z+radius.z)*u)):
			var xx := (ix+0.5)*DETAIL_GRID
			var zz := (iz+0.5)*DETAIL_GRID
			var dx := (xx-center.x)/radius.x
			var dz := (zz-center.z)/radius.z
			var horizontal := dx*dx+dz*dz
			if horizontal >= 1.0:
				continue
			var half_height := radius.y*sqrt(1.0-horizontal)
			var bottom := ceili((center.y-half_height)*u-0.5)
			var top := floori((center.y+half_height)*u-0.5)
			# Small deterministic irregularities on the leaf silhouette.
			if PixelTex.h(ix,iz,73) > 0.8:
				top -= 1
			var cursor := bottom
			while cursor <= top:
				var coarse_y := floori(float(cursor)/u)
				var end := mini(top,(coarse_y+1)*u-1)
				if w.getb(floori(xx),coarse_y,floori(zz)) == 0:
					fine.column(ix,iz,cursor,end,leaf,true)
				cursor = end+1


func _pine(x: int, z: int) -> void:
	var hgt := 6 + _rng.randi() % 3
	_fine_trunk(x, z, hgt)
	for layer in range(4, hgt * 2 + 3):
		var height := layer * 0.5
		var radius := maxf(0.3, (hgt + 1 - height) * 0.34)
		radius += 0.2 if layer % 3 == 0 else 0.0
		_fine_crown(Vector3(x + 0.5, height, z + 0.5), Vector3(radius, 0.4, radius), PINE)


# ======================================================================
# small details: grass, flowers, rocks
func _details() -> void:
	var n := 0
	var tries := 0
	while n < 2600 and tries < 20000:
		tries += 1
		var x := _rng.randi_range(-105, 105)
		var z := _rng.randi_range(-105, 105)
		if inside_town(x, z, 1.0) or w.getb(x, -1, z) != 0 or w.getb(x, 0, z) != 0:
			continue
		var roll := _rng.randf()
		var tile := PixelTex.TALL_GRASS
		if roll > 0.9:
			tile = PixelTex.FLOWER
		elif roll > 0.82:
			tile = PixelTex.FLOWER_RED
		w.plant(x, z, tile)
		n += 1
	# a few flowers inside the plots too
	for i in 320:
		var x := _rng.randi_range(X0 + 4, X1 - 4)
		var z := _rng.randi_range(Z0 + 4, Z1 - 4)
		if x >= CX0 - 1 and x <= CX1 + 1 and z <= CZ1 + 4:
			continue
		if w.getb(x, -1, z) == 0 and w.getb(x, 0, z) == 0:
			w.plant(x, z, [PixelTex.TALL_GRASS, PixelTex.FLOWER, PixelTex.FLOWER_RED][i % 3])
	for i in 30:
		var p := Vector2(_rng.randf_range(-95, 95), _rng.randf_range(-95, 95))
		if not _free(p.floor(), 2.0):
			continue
		var x := floori(p.x)
		var z := floori(p.y)
		w.setb(x, 0, z, COBBLE if i % 2 else STONE)
		if _rng.randf() < 0.5:
			w.setb(x + 1, 0, z, STONE)
		if _rng.randf() < 0.3:
			w.setb(x, 1, z, COBBLE)


# ======================================================================
# clouds (flat blocky, drifting)
func _clouds() -> void:
	var layer := Node3D.new()
	layer.name = "Clouds"
	add_child(layer)
	if not Engine.is_editor_hint():
		layer.set_script(preload("res://scripts/world/cloud_layer.gd"))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.82)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 34:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(_rng.randi_range(8, 24), 3, _rng.randi_range(6, 16))
		mi.mesh = bm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(_rng.randf_range(-200, 200), 52, _rng.randf_range(-200, 200)).floor()
		layer.add_child(mi)


# ======================================================================
# animals: horses and sheep grazing in the plots and outside the walls
static var _horse: BoxModel
static var _sheep: BoxModel


static func _horse_model() -> BoxModel:
	if _horse:
		return _horse
	var coat := Color(0.55, 0.36, 0.22)
	var mane := Color(0.2, 0.14, 0.1)
	var m := BoxModel.new(0.07)
	m.add("body", Vector3i(6, 6, 12), BoxModel.flat(coat, 81))
	m.add("neck", Vector3i(4, 7, 4), func(f, u, v, w2, h):
		if f == BoxModel.BACK or f == BoxModel.TOP:
			return mane
		return BoxModel.noise(coat, u, v, 82))
	m.add("head", Vector3i(4, 4, 7), func(f, u, v, w2, h):
		if (f == BoxModel.SIDE_PX or f == BoxModel.SIDE_NX) and v == 1 and (u == 4 or u == 2):
			return Color(0.08, 0.06, 0.05)
		if f == BoxModel.FRONT:
			return coat.darkened(0.2)
		return BoxModel.noise(coat, u, v, 83))
	m.add("leg", Vector3i(2, 8, 2), func(f, u, v, w2, h): return Color(0.25, 0.2, 0.17) if v >= 6 else BoxModel.noise(coat, u, v, 84))
	m.add("tail", Vector3i(2, 6, 2), BoxModel.flat(mane, 85))
	m.bake()
	_horse = m
	return m


static func _sheep_model() -> BoxModel:
	if _sheep:
		return _sheep
	var wool := Color(0.93, 0.92, 0.88)
	var m := BoxModel.new(0.07)
	m.add("body", Vector3i(8, 7, 11), BoxModel.flat(wool, 86, 0.06))
	m.add("head", Vector3i(5, 5, 5), func(f, u, v, w2, h):
		if f == BoxModel.FRONT:
			if v == 2 and (u == 1 or u == 3):
				return Color(0.1, 0.08, 0.08)
			return Color(0.85, 0.72, 0.62)
		return BoxModel.noise(wool, u, v, 87))
	m.add("leg", Vector3i(2, 5, 2), BoxModel.flat(Color(0.85, 0.72, 0.62), 88))
	m.bake()
	_sheep = m
	return m


func _animals() -> void:
	var root := Node3D.new()
	root.name = "Animals"
	add_child(root)
	var spots := [["horse", Vector2(28, -31), 0.5], ["horse", Vector2(-27, -31), 2.2], ["horse", Vector2(8, 30), -1.0],
		["sheep", Vector2(-9, 20), 1.0], ["sheep", Vector2(-6, 22), 2.5], ["horse", Vector2(-12, -28), 1.6],
		["sheep", Vector2(45, 30), 0.3], ["sheep", Vector2(48, 32), 2.0], ["sheep", Vector2(-44, 35), 1.2],
		["horse", Vector2(-40, 48), 2.9], ["sheep", Vector2(-38, 30), 0.8]]
	for s in spots:
		var n := Node3D.new()
		n.position = Vector3(s[1].x + 0.5, 0, s[1].y + 0.5)
		n.rotation.y = s[2]
		root.add_child(n)
		if s[0] == "horse":
			var m := _horse_model()
			for p in [Vector3(2, 4, 4.5), Vector3(-2, 4, 4.5), Vector3(2, 4, -4.5), Vector3(-2, 4, -4.5)]:
				m.part(n, "leg", p)
			m.part(n, "body", Vector3(0, 11, 0))
			m.part(n, "neck", Vector3(0, 15, 6), Vector3(-25, 0, 0))
			m.part(n, "head", Vector3(0, 18.5, 8.5), Vector3(20, 0, 0))
			m.part(n, "tail", Vector3(0, 10, -6.5), Vector3(20, 0, 0))
		else:
			var m := _sheep_model()
			for p in [Vector3(2.5, 2.5, 3.5), Vector3(-2.5, 2.5, 3.5), Vector3(2.5, 2.5, -3.5), Vector3(-2.5, 2.5, -3.5)]:
				m.part(n, "leg", p)
			m.part(n, "body", Vector3(0, 8, 0))
			m.part(n, "head", Vector3(0, 9.5, 6.5))


# ======================================================================
# villagers
func _villagers() -> void:
	var root := Node3D.new()
	root.name = "Villagers"
	add_child(root)
	for i in villager_count:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(5.0, 7.5)
		_make_villager(root, Vector3(cos(a) * r, 0, sin(a) * r), _rng.randf() * TAU, i, true)
	# plaza onlookers and gate guards
	for s in [[Vector3(9.2, 0, 5.5), Vector3(11, 0, 5.5)], [Vector3(9.2, 0, -4.5), Vector3(11, 0, -4.5)],
			[Vector3(-9.8, 0, 5.5), Vector3(-12, 0, 5.5)], [Vector3(-9.8, 0, -4.5), Vector3(-12, 0, -4.5)],
			[Vector3(-3.5, 0, 33.0), Vector3(-3.5, 0, 40)], [Vector3(3.5, 0, -16.5), Vector3(3.5, 0, -10)]]:
		_make_villager(root, s[0], LP.yaw_to(s[1] - s[0]), int(s[0].x * 7 + s[0].z), false)


func _make_villager(parent: Node3D, pos: Vector3, yaw: float, i: int, wander: bool) -> void:
	var v := Node3D.new()
	v.name = "Villager"
	if wander and not Engine.is_editor_hint():
		v.set_script(VillagerScript)
		v.set("inner_radius", 5.0)
		v.set("outer_radius", 7.5)
	v.position = pos
	v.rotation.y = yaw
	parent.add_child(v)
	Skins.build_villager(v, absi(i))


# ======================================================================
# story NPCs (clickable)
const NPCScript := preload("res://scripts/npc/npc.gd")


func _npcs() -> void:
	if Engine.is_editor_hint():
		return
	var root := Node3D.new()
	root.name = "NPCs"
	add_child(root)
	for d in [
		["Merchant Toma", "shop", 5, Vector3(8.5, 0, 3.0), -1.57],
		["Captain Aldric", "quest", 6, Vector3(4.5, 0, 30.5), 3.14],
		["Old Sage Bren", "sage", 4, Vector3(-5.5, 0, -16.0), 0.0],
		["Guide Lumi", "helper", 2, Vector3(-3.5, 0, 9.5), 1.57],
		["Blacksmith Doran", "smith", 3, Vector3(160.5, 0, 84.0), 0.0],
		["Warp Crystal", "warp", 0, Vector3(9.5, 0, 11.5), 0.0],
	]:
		var n: Node = NPCScript.new()
		n.npc_name = d[0]
		n.role = d[1]
		n.skin = d[2]
		n.position = d[3]
		root.add_child(n)
		n.model.rotation.y = d[4]
	for d in GuildHall.npc_defs():
		var n: Node = NPCScript.new()
		n.npc_name = d[0]
		n.role = d[1]
		if d[2] is Dictionary:
			n.look = d[2].look
			n.gear = d[2].gear
		n.position = d[3]
		if d.size() > 5:
			n.talk_spot = d[5]
			n.reach = 3.1
		root.add_child(n)
		n.model.rotation.y = d[4]


## Glowing rune circles + name tags on every warp.
func _warp_fx() -> void:
	if Engine.is_editor_hint():
		return
	for wp in WARPS:
		var root := Node3D.new()
		root.position = Vector3(wp.pos.x, 0.06, wp.pos.y)
		add_child(root)
		for k in 2:
			var mi := MeshInstance3D.new()
			var t := TorusMesh.new()
			t.inner_radius = [0.62, 0.36][k]
			t.outer_radius = [0.72, 0.42][k]
			t.rings = 24
			t.ring_segments = 3
			mi.mesh = t
			mi.scale = Vector3(1, 0.06, 1)
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.albedo_color = Color(0.45, 0.8, 1.0, 0.75)
			mi.material_override = m
			root.add_child(mi)
			var tw := mi.create_tween().set_loops()
			tw.tween_property(mi, "rotation:y", TAU * (1 if k == 0 else -1), 6.0).from(0.0)
		var p := CPUParticles3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE * 0.06
		var pm := StandardMaterial3D.new()
		pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pm.vertex_color_use_as_albedo = true
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm.material = pm
		p.mesh = bm
		p.amount = 14
		p.lifetime = 1.4
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.5
		p.direction = Vector3.UP
		p.spread = 10.0
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 0.4
		p.initial_velocity_max = 0.9
		var g := Gradient.new()
		g.set_color(0, Color(0.7, 0.95, 1.0, 1.0))
		g.set_color(1, Color(0.45, 0.8, 1.0, 0.0))
		p.color_ramp = g
		root.add_child(p)
		var l := Label3D.new()
		l.text = tr(AREA_NAMES[wp.to])
		l.font = load("res://assets/fonts/ui_font_bold.tres")
		l.font_size = 34
		l.outline_size = 10
		l.modulate = Color(0.05, 0.1, 0.2)
		l.outline_modulate = Color(0.85, 0.95, 1.0)
		l.pixel_size = 0.005
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.position = Vector3(0, 1.6, 0)
		root.add_child(l)
		root.set_meta("warp_label", l)


# ======================================================================
# navigation grid (1 m cells) for click-to-walk and auto pathing
func _build_nav() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(-NAV_HALF, -NAV_HALF, NAV_HALF * 2, NAV_HALF * 2)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for p: Vector3i in w.blocks:
		# Black cutaway surrounds are not playable floor, even though the
		# shared physics ground extends underneath them.
		if p.y == -1 and w.blocks[p] == VOID:
			var outside := Vector2i(p.x, p.z)
			if astar.is_in_boundsv(outside):
				astar.set_point_solid(outside, true)
		if p.y < 0 or p.y > 1:
			continue
		if w.no_collide.has(w.blocks[p]):
			continue
		var c := Vector2i(p.x, p.z)
		if astar.is_in_boundsv(c):
			astar.set_point_solid(c, true)
	for c in _pond_cells + _lamp_cells:
		if astar.is_in_boundsv(c):
			astar.set_point_solid(c, true)
	for r in GuildHall.prop_solids():
		for x in range(r.position.x, r.end.x):
			for z in range(r.position.y, r.end.y):
				astar.set_point_solid(Vector2i(x, z), true)


func walkable(x: float, z: float) -> bool:
	var c := Vector2i(floori(x), floori(z))
	var g := _grid(x, z)
	return g != null and g.is_in_boundsv(c) and not g.is_point_solid(c)


## Actual map footprint, separate from walls/props that may temporarily overlap
## a character's capsule. The black room surrounds never count as floor.
func playable_floor(p: Vector3) -> bool:
	var a := area_at(p)
	var g := _grid(p.x, p.z)
	var cell := Vector2i(floori(p.x), floori(p.z))
	if g == null or not g.is_in_boundsv(cell):
		return false
	var bw: BlockWorld = worlds.get(a, w)
	if bw == null:
		return true # Navigation-only test worlds.
	var tile := bw.getb(cell.x, -1, cell.y)
	if tile == VOID:
		return false
	if a in ["smithy", "guild1", "guild2"] or Zones.is_dungeon(a):
		return tile != 0
	return true


## Snap formation/arrival/recovery positions to a clear cell in the same map.
## Return INF rather than ever putting a character on a black surround.
func safe_position(p: Vector3, required_area: String, radius := 16) -> Vector3:
	# Most formation positions are already safe. Preserve their fractional
	# coordinates instead of scanning rings and snapping to a new cell every tick.
	if area_at(p) == required_area and playable_floor(p):
		var grid := _grid(p.x, p.z)
		var clear := true
		for off in [Vector2(-0.43, -0.43), Vector2(0.43, -0.43), Vector2(-0.43, 0.43), Vector2(0.43, 0.43)]:
			var q := Vector2i(floori(p.x + off.x), floori(p.z + off.y))
			if not grid.is_in_boundsv(q) or grid.is_point_solid(q):
				clear = false
				break
		if clear:
			return Vector3(p.x, 0, p.z)
	var cell := Vector2i(floori(p.x), floori(p.z))
	var best := Vector3.INF
	var best_distance := INF
	for r in range(radius + 1):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var candidate := Vector3(cell.x + dx + 0.5, 0, cell.y + dz + 0.5)
				if area_at(candidate) != required_area or not playable_floor(candidate):
					continue
				var clear := true
				for off in [Vector2.ZERO, Vector2(-0.43, -0.43), Vector2(0.43, -0.43), Vector2(-0.43, 0.43), Vector2(0.43, 0.43)]:
					if not walkable(candidate.x + off.x, candidate.z + off.y):
						clear = false
						break
				if clear:
					var distance := Vector2(candidate.x - p.x, candidate.z - p.z).length_squared()
					if distance < best_distance:
						best_distance = distance
						best = candidate
		if best != Vector3.INF and r * r > best_distance + 2.0:
			break
	return best


func _free_cell(c: Vector2i) -> Vector2i:
	var g := _grid(c.x, c.y)
	if g == null:
		return c
	if g.is_in_boundsv(c) and not g.is_point_solid(c):
		return c
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var q := c + Vector2i(dx, dz)
				if g.is_in_boundsv(q) and not g.is_point_solid(q):
					return q
	return c


## Straight walk possible between a and b (samples the grid, with body width).
func line_clear(a: Vector3, b: Vector3) -> bool:
	var grid := _grid(a.x, a.z)
	if grid == null or grid != _grid(b.x, b.z):
		return false
	var d := Vector2(b.x - a.x, b.z - a.z)
	var L := d.length()
	if L < 0.01:
		return true
	var dir := d / L
	var side := Vector2(-dir.y, dir.x) * 0.43
	var offsets := [Vector2.ZERO, side, -side, dir * 0.43, -dir * 0.43, Vector2(0.31, 0.31), Vector2(-0.31, 0.31), Vector2(0.31, -0.31), Vector2(-0.31, -0.31)]
	var steps := int(L / 0.15) + 1
	for i in steps + 1:
		var p := Vector2(a.x, a.z) + dir * (L * i / steps)
		for o in offsets:
			var cell := Vector2i(floori(p.x + o.x), floori(p.y + o.y))
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):
				return false
	return true


## World-space path (y = 0) from a to b, smoothed. Empty if unreachable.
func find_path(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	var g := _grid(a.x, a.z)
	if g == null or g != _grid(b.x, b.z):
		return out
	var ca := _free_cell(Vector2i(floori(a.x), floori(a.z)))
	var cb := _free_cell(Vector2i(floori(b.x), floori(b.z)))
	if not g.is_in_boundsv(ca) or not g.is_in_boundsv(cb):
		return out
	var ids := g.get_id_path(ca, cb, true)
	if ids.is_empty():
		return out
	# string pulling: keep only the corners we cannot see past
	var pts: Array[Vector3] = []
	for c in ids:
		pts.append(Vector3(c.x + 0.5, 0, c.y + 0.5))
	var cur := Vector3(a.x, 0, a.z)
	var i := 0
	while i < pts.size():
		# Bound smoothing work near corners on long paths.
		var j := mini(i + 16, pts.size() - 1)
		while j > i and not line_clear(cur, pts[j]):
			j -= 1
		out.append(pts[j])
		cur = pts[j]
		i = j + 1
	if cb == Vector2i(floori(b.x), floori(b.z)) and line_clear(cur, b):
		out.append(Vector3(b.x, 0, b.z))
	return out


# ======================================================================
# fountain: spray particles + ripples
func _fountain_fx() -> void:
	if Engine.is_editor_hint():
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 0.88, 1.0, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	var spray := CPUParticles3D.new()
	spray.name = "FountainSpray"
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.12)
	box.material = mat
	spray.mesh = box
	spray.amount = 90
	spray.lifetime = 1.4
	spray.position = Vector3(0, 4.6, 0)
	spray.direction = Vector3(0, 1, 0)
	spray.spread = 28.0
	spray.initial_velocity_min = 2.6
	spray.initial_velocity_max = 3.6
	spray.gravity = Vector3(0, -6.5, 0)
	spray.scale_amount_min = 0.6
	spray.scale_amount_max = 1.2
	var grad := Gradient.new()
	grad.set_color(0, Color(0.85, 0.95, 1.0, 0.95))
	grad.set_color(1, Color(0.5, 0.75, 1.0, 0.0))
	spray.color_ramp = grad
	add_child(spray)
	# four little spouts falling from the upper basin into the pool
	for d in [Vector3(1.6, 3.4, 0), Vector3(-1.6, 3.4, 0), Vector3(0, 3.4, 1.6), Vector3(0, 3.4, -1.6)]:
		var sp := CPUParticles3D.new()
		sp.mesh = box
		sp.amount = 24
		sp.lifetime = 0.7
		sp.position = d
		sp.direction = Vector3(d.x, 0.3, d.z).normalized()
		sp.spread = 8.0
		sp.initial_velocity_min = 1.0
		sp.initial_velocity_max = 1.4
		sp.gravity = Vector3(0, -9.0, 0)
		sp.color_ramp = grad
		add_child(sp)
	# ripples on the pool
	var rip := CPUParticles3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.35
	ring.outer_radius = 0.42
	ring.rings = 12
	ring.ring_segments = 3
	var rmat := mat.duplicate() as StandardMaterial3D
	ring.material = rmat
	rip.mesh = ring
	rip.amount = 10
	rip.lifetime = 1.6
	rip.position = Vector3(0, 0.6, 0)
	rip.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	rip.emission_ring_axis = Vector3.UP
	rip.emission_ring_height = 0.0
	rip.emission_ring_radius = 3.0
	rip.emission_ring_inner_radius = 2.0
	rip.gravity = Vector3.ZERO
	rip.initial_velocity_min = 0.0
	rip.initial_velocity_max = 0.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 0.3))
	sc.add_point(Vector2(1, 1.6))
	rip.scale_amount_curve = sc
	rip.color_ramp = grad
	add_child(rip)


## Top-down colour map for the minimap / world map (1 px = 1 m), centred on 0,0.
func minimap_image(half := 64) -> Image:
	return _minimap(w, Vector2i.ZERO, half, half, PixelTex.GRASS_TOP)


## Same for a region / dungeon map (built on demand).
func minimap_image_area(a: String) -> Image:
	ensure_area(a)
	var r: Rect2 = AREAS[a]
	var c := Vector2i(r.get_center())
	var tile: int = Zones.GROUND.get(a, PixelTex.VOID)
	return _minimap(worlds.get(a, w), c, int(r.size.x * 0.5), int(r.size.y * 0.5), tile)


func _minimap(bw: BlockWorld, c: Vector2i, hx: int, hz: int, ground: int) -> Image:
	var atlas := PixelTex.atlas().get_image()
	var avg := {}
	var top := {}
	for p: Vector3i in bw.blocks:
		if absi(p.x - c.x) > hx or absi(p.z - c.y) > hz:
			continue
		var k := Vector2i(p.x, p.z)
		if not top.has(k) or top[k].x < p.y:
			top[k] = Vector2i(p.y, bw.blocks[p])
	var img := Image.create(hx * 2, hz * 2, false, Image.FORMAT_RGBA8)
	for z in range(-hz, hz):
		for x in range(-hx, hx):
			var t = top.get(Vector2i(c.x + x, c.y + z))
			var id: int = 0 if t == null else t.y
			var tile: int = ground if id == 0 else BlockWorld.BLOCKS[id][0]
			if not avg.has(tile):
				var t2 := PixelTex.tile_coord(tile) * PixelTex.TILE
				var col := Color(0, 0, 0)
				for py in PixelTex.TILE:
					for px in PixelTex.TILE:
						col += atlas.get_pixel(int(t2.x) + px, int(t2.y) + py)
				avg[tile] = col / float(PixelTex.TILE * PixelTex.TILE)
			var cc: Color = avg[tile]
			# simple height shading so walls / roofs / trees read on the map
			if t != null and t.x > 0:
				cc = cc.lightened(minf(0.04 * t.x, 0.25))
			img.set_pixel(x + hx, z + hz, cc)
	return img

# ======================================================================
# round fountain (lathe meshes: pool rim, column + upper basin, spout) + water discs
const FOUNTAIN_SEG := 56


func _round_fountain() -> void:
	var root := Node3D.new()
	root.name = "RoundFountain"
	add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = _fountain_stone_tex()
	stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	stone.roughness = 0.95
	stone.cull_mode = BaseMaterial3D.CULL_DISABLED
	var trim := stone.duplicate() as StandardMaterial3D
	trim.albedo_color = Color(0.86, 0.84, 0.8)
	# pool rim: inner wall up, flat top, outer wall down
	_lathe(root, [Vector2(3.72, 0.0), Vector2(3.72, 0.78), Vector2(3.84, 0.9), Vector2(4.58, 0.9), Vector2(4.72, 0.78), Vector2(4.72, 0.0)], stone)
	# column + upper basin (top to bottom along the outside)
	_lathe(root, [Vector2(0.0, 3.06), Vector2(1.72, 3.06), Vector2(1.72, 3.3), Vector2(1.99, 3.32), Vector2(2.02, 3.14),
		Vector2(1.35, 2.8), Vector2(0.6, 2.5), Vector2(0.5, 2.4), Vector2(0.5, 1.9), Vector2(0.64, 1.78), Vector2(0.5, 1.66),
		Vector2(0.56, 0.42), Vector2(0.8, 0.3), Vector2(0.8, 0.0)], stone)
	# spout in the middle of the basin
	_lathe(root, [Vector2(0.0, 4.5), Vector2(0.2, 4.38), Vector2(0.13, 4.16), Vector2(0.38, 3.94), Vector2(0.26, 3.8), Vector2(0.3, 3.06)], trim)
	# water: pool and basin (drawn with the animated water of the block shader)
	_water_disc(root, 3.73, 0.56)
	_water_disc(root, 1.73, 3.18)


## Revolve a (radius, height) profile around the Y axis.
func _lathe(parent: Node3D, prof: Array, mat: Material) -> void:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var run := 0.0
	for i in prof.size() - 1:
		var a: Vector2 = prof[i]
		var b: Vector2 = prof[i + 1]
		var d := b - a
		var n2 := Vector2(-d.y, d.x).normalized()
		var len := d.length()
		for k in FOUNTAIN_SEG:
			var t0 := TAU * k / FOUNTAIN_SEG
			var t1 := TAU * (k + 1) / FOUNTAIN_SEG
			var c0 := Vector2(cos(t0), sin(t0))
			var c1 := Vector2(cos(t1), sin(t1))
			var p00 := Vector3(c0.x * a.x, a.y, c0.y * a.x)
			var p01 := Vector3(c1.x * a.x, a.y, c1.y * a.x)
			var p10 := Vector3(c0.x * b.x, b.y, c0.y * b.x)
			var p11 := Vector3(c1.x * b.x, b.y, c1.y * b.x)
			var n0 := Vector3(c0.x * n2.x, n2.y, c0.y * n2.x)
			var n1 := Vector3(c1.x * n2.x, n2.y, c1.y * n2.x)
			var r := maxf(maxf(a.x, b.x), 0.3)
			var u0 := t0 * r
			var u1 := t1 * r
			for q in [[p00, n0, Vector2(u0, run)], [p10, n0, Vector2(u0, run + len)], [p11, n1, Vector2(u1, run + len)],
					[p00, n0, Vector2(u0, run)], [p11, n1, Vector2(u1, run + len)], [p01, n1, Vector2(u1, run)]]:
				v.append(q[0])
				n.append(q[1])
				uv.append(q[2])
		run += len
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_TEX_UV] = uv
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	parent.add_child(mi)


func _water_disc(parent: Node3D, radius: float, y: float) -> void:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var c := PackedColorArray()
	var t2 := PixelTex.tile_coord(PixelTex.WATER)
	for k in FOUNTAIN_SEG:
		var t0 := TAU * k / FOUNTAIN_SEG
		var t1 := TAU * (k + 1) / FOUNTAIN_SEG
		for p in [Vector3.ZERO, Vector3(cos(t0) * radius, 0, sin(t0) * radius), Vector3(cos(t1) * radius, 0, sin(t1) * radius)]:
			v.append(p + Vector3(0, y, 0))
			n.append(Vector3.UP)
			uv.append(Vector2(p.x, p.z))
			uv2.append(t2)
			c.append(Color(1, 1, 1))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_TEX_UV2] = uv2
	arr[Mesh.ARRAY_COLOR] = c
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = "FountainWater"
	mi.mesh = m
	mi.material_override = PixelTex.solid_material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


## Light carved stone in brick courses, 32 px per metre (pixel-art like the blocks).
static func _fountain_stone_tex() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base := Color(0.8, 0.78, 0.72)
	for y in 32:
		for x in 32:
			var row := y / 8
			var off := 8 if row % 2 == 1 else 0
			var mortar := y % 8 == 7 or (x + off) % 16 == 15
			var col := base.darkened(0.32) if mortar else PixelTex.jit(base.darkened(PixelTex.h((x + off) / 16 + row * 7, row, 3) * 0.12), x, y, 11, 0.04)
			if not mortar and y % 8 == 0:
				col = col.lightened(0.08)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


# ======================================================================
# a fishing pond in the meadow outside the town walls
var _pond_cells: Array[Vector2i] = []


func _fishing_pond() -> void:
	var rx := 7.0
	var rz := 5.0
	var cands: Array[Vector2i] = []
	for rr in [62, 72, 82, 92]:
		for k in 24:
			var a := TAU * k / 24.0
			cands.append(Vector2i(roundi(cos(a) * rr), roundi(sin(a) * rr)))
	for ctr in cands:
		var clear := true
		for x in range(ctr.x - 11, ctr.x + 12):
			for z in range(ctr.y - 9, ctr.y + 10):
				var dt := w.getb(x, -1, z)
				if dt != 0 and dt != GRASS and dt != 61:
					clear = false
				for y in range(0, 3):
					if w.getb(x, y, z) != 0:
						clear = false
			if not clear:
				break
		if not clear:
			continue
		for x in range(ctr.x - 9, ctr.x + 10):
			for z in range(ctr.y - 7, ctr.y + 8):
				var d := Vector2((x - ctr.x) / rx, (z - ctr.y) / rz).length() + (PixelTex.h(x, z, 77) - 0.5) * 0.25
				if d < 1.0:
					w.decal(x, z, WATER)
					_pond_cells.append(Vector2i(x, z))
				elif d < 1.28:
					w.decal(x, z, 32)
		# clear any trees growing right at the shore
		for x in range(ctr.x - 11, ctr.x + 12):
			for z in range(ctr.y - 9, ctr.y + 10):
				for y in range(0, 12):
					if w.getb(x, y, z) in [LOG, LEAVES, LEAVES_A, PINE]:
						w.setb(x, y, z, 0)
		print("town fishing pond at ", ctr)
		return
	print("town fishing pond: no free spot found")
