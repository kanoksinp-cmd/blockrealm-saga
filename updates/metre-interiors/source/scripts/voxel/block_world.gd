class_name BlockWorld
extends RefCounted




const CHUNK: = 16

const STRUCTURE_GRID: = 0.2
const T: = preload("res://scripts/voxel/pixel_tex.gd")


const BLOCKS: = {
	1: [T.GRASS_TOP, T.GRASS_SIDE, T.DIRT],
	2: [T.DIRT, T.DIRT, T.DIRT],
	3: [T.STONE, T.STONE, T.STONE],
	4: [T.COBBLE, T.COBBLE, T.COBBLE],
	5: [T.STONE_BRICK, T.STONE_BRICK, T.STONE_BRICK],
	6: [T.PLANKS, T.PLANKS, T.PLANKS],
	7: [T.LOG_TOP, T.LOG_SIDE, T.LOG_TOP],
	8: [T.LEAVES, T.LEAVES, T.LEAVES],
	9: [T.LEAVES_AUTUMN, T.LEAVES_AUTUMN, T.LEAVES_AUTUMN],
	10: [T.PINE_LEAVES, T.PINE_LEAVES, T.PINE_LEAVES],
	11: [T.PATH, T.PATH, T.DIRT],
	12: [T.GRAVEL, T.GRAVEL, T.GRAVEL],
	13: [T.WATER, T.WATER, T.WATER],
	14: [T.PLASTER, T.PLASTER, T.PLASTER],
	15: [T.ROOF_RED, T.ROOF_RED, T.ROOF_RED],
	16: [T.ROOF_ORANGE, T.ROOF_ORANGE, T.ROOF_ORANGE],
	17: [T.ROOF_BROWN, T.ROOF_BROWN, T.ROOF_BROWN],
	18: [T.GLASS, T.GLASS, T.GLASS],
	19: [T.FARMLAND, T.DIRT, T.DIRT],
	20: [T.WOOL_RED, T.WOOL_RED, T.WOOL_RED],
	21: [T.WOOL_WHITE, T.WOOL_WHITE, T.WOOL_WHITE],
	22: [T.WOOL_YELLOW, T.WOOL_YELLOW, T.WOOL_YELLOW],
	23: [T.WOOL_GREEN, T.WOOL_GREEN, T.WOOL_GREEN],
	24: [T.WOOL_BLUE, T.WOOL_BLUE, T.WOOL_BLUE],
	25: [T.HAY_TOP, T.HAY_SIDE, T.HAY_TOP],
	26: [T.GOLD, T.GOLD, T.GOLD],
	27: [T.TIMBER, T.TIMBER, T.TIMBER],
	28: [T.TIMBER, T.DOOR, T.TIMBER],
	29: [T.GLOW, T.GLOW, T.GLOW],
	30: [T.IRON, T.IRON, T.IRON],
	31: [T.PLAZA, T.PLAZA, T.PLAZA],
	32: [T.SAND, T.SAND, T.SAND],
	33: [T.TIMBER, T.DOOR_TOP, T.TIMBER],
	34: [T.DARK_PLANKS, T.DARK_PLANKS, T.DARK_PLANKS],
	35: [T.PLANKS, T.BOOKSHELF, T.PLANKS],
	36: [T.BARREL_TOP, T.BARREL_SIDE, T.BARREL_TOP],
	37: [T.RUG_RED, T.RUG_RED, T.RUG_RED],
	38: [T.RUG_GREEN, T.RUG_GREEN, T.RUG_GREEN],
	39: [T.SLATE, T.SLATE, T.SLATE],
	40: [T.VOID, T.VOID, T.VOID],
	41: [T.STONE_TILE, T.STONE_TILE, T.STONE_TILE],
	42: [T.BANNER, T.BANNER, T.BANNER],
	43: [T.SNOW, T.SNOW_SIDE, T.DIRT],
	44: [T.SNOW, T.SNOW, T.SNOW],
	45: [T.ICE, T.ICE, T.ICE],
	46: [T.PACKED_ICE, T.PACKED_ICE, T.PACKED_ICE],
	47: [T.SANDSTONE, T.SANDSTONE, T.SANDSTONE],
	48: [T.SANDSTONE, T.SANDSTONE_CARVED, T.SANDSTONE],
	49: [T.BASALT, T.BASALT, T.BASALT],
	50: [T.MAGMA, T.MAGMA, T.MAGMA],
	51: [T.ASH, T.ASH, T.ASH],
	52: [T.OBSIDIAN, T.OBSIDIAN, T.OBSIDIAN],
	53: [T.MOSSY_STONE, T.MOSSY_STONE, T.STONE],
	54: [T.MOSSY_BRICK, T.MOSSY_BRICK, T.STONE_BRICK],
	55: [T.JUNGLE_LEAVES, T.JUNGLE_LEAVES, T.JUNGLE_LEAVES],
	56: [T.CACTUS_TOP, T.CACTUS_SIDE, T.CACTUS_TOP],
	57: [T.JADE, T.JADE, T.JADE],
	58: [T.BONE, T.BONE, T.BONE],
	59: [T.CHERRY_LEAVES, T.CHERRY_LEAVES, T.CHERRY_LEAVES],
	60: [T.RED_SAND, T.RED_SAND, T.RED_SAND],
	61: [T.DARK_GRASS, T.DIRT, T.DIRT],
	62: [T.GOLD_TILE, T.GOLD_TILE, T.GOLD_TILE],
	63: [T.CRYSTAL_BLUE, T.CRYSTAL_BLUE, T.CRYSTAL_BLUE],
}


const FACES: = [
	[Vector3i(0, 0, 1), [Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 0, 1), Vector3(0, 0, 1)], 0.86, 1],
	[Vector3i(0, 0, -1), [Vector3(1, 1, 0), Vector3(0, 1, 0), Vector3(0, 0, 0), Vector3(1, 0, 0)], 0.86, 1],
	[Vector3i(1, 0, 0), [Vector3(1, 1, 1), Vector3(1, 1, 0), Vector3(1, 0, 0), Vector3(1, 0, 1)], 0.74, 1],
	[Vector3i(-1, 0, 0), [Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(0, 0, 1), Vector3(0, 0, 0)], 0.74, 1],
	[Vector3i(0, 1, 0), [Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(0, 1, 1)], 1.0, 0],
	[Vector3i(0, -1, 0), [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, 0)], 0.6, 2],
]
const UVS: = [Vector2(0.0005, 0.0005), Vector2(0.9995, 0.0005), Vector2(0.9995, 0.9995), Vector2(0.0005, 0.9995)]

var cell_size: = 1.0
var render_only: = false
var hidden_render: = { }
var _micro_roofs: RefCounted


var round_natural: = false
var _rounded: RefCounted

var _blobs: RefCounted
const BLOB_GRID: = 0.4
var _rounding_done: = false

var round_cells: = { }

var round_area: = Rect2()

const ROUND_RADIUS: = {
	1: 2.5, 2: 2.5, 3: 2.5, 12: 2.5, 32: 3.0, 43: 2.5, 44: 3.0, 45: 2.0, 46: 2.0, 49: 2.0, 51: 3.0, 52: 2.0,
	53: 2.5, 60: 2.5, 61: 2.5, 7: 2.5, 56: 2.5,
	8: 3.5, 9: 3.5, 10: 3.0, 55: 3.5, 59: 3.5,
}


var plane_tile: = -1
var _tops: = { }
var blocks: = { }
var plants: = { }
var no_collide: = { 8: true, 9: true, 10: true, 55: true, 59: true }


func setb(x: int, y: int, z: int, id: int) -> void:
	if id == 0:
		blocks.erase(Vector3i(x, y, z))
	else:
		blocks[Vector3i(x, y, z)] = id


func getb(x: int, y: int, z: int) -> int:
	return blocks.get(Vector3i(x, y, z), 0)


func fill(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, id: int) -> void:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		for y in range(mini(y0, y1), maxi(y0, y1) + 1):
			for z in range(mini(z0, z1), maxi(z0, z1) + 1):
				setb(x, y, z, id)


func decal(x: int, z: int, id: int) -> void:
	setb(x, -1, z, id)


func plant(x: int, z: int, tile: int, y: = 0) -> void:
	if getb(x, y, z) == 0:
		plants[Vector3i(x, y, z)] = tile



func build(parent: Node3D, collide_root: Node3D) -> void:
	_prepare_micro_roofs()
	_prepare_rounding()
	_prepare_tops()
	var chunks: = { }
	for p: Vector3i in blocks:
		var id: int = blocks[p]
		var def: Array = BLOCKS.get(id, [T.STONE, T.STONE, T.STONE])
		var key: = Vector2i(floori(float(p.x) / CHUNK), floori(float(p.z) / CHUNK))
		if not chunks.has(key):
			chunks[key] = _new_chunk()
		var ch: Dictionary = chunks[key]
		var solid: = not render_only and not no_collide.has(id) and p.y >= 0
		for f in FACES:
			var n: Vector3i = f[0]
			if p.y < 0 and n.y != 1:
				continue
			if p.y == 0 and n.y == -1:
				continue
			var nb: int = blocks.get(p + n, 0)
			if nb != 0 and not (nb == 13 and id != 13) and not (p.y < 0 and hidden_render.has(p + n)):
				continue
			var cols: Array = _corner_colors(p) if (n.y == 1 and _tops.has(p)) else []
			_emit(ch, Vector3(p), f, def[f[3]], solid, not hidden_render.has(p), cols)
	for p: Vector3i in plants:
		var key: = Vector2i(floori(float(p.x) / CHUNK), floori(float(p.z) / CHUNK))
		if not chunks.has(key):
			chunks[key] = _new_chunk()
		_emit_plant(chunks[key], Vector3(p), plants[p])

	for key in chunks:
		var ch: Dictionary = chunks[key]
		if (ch.v as PackedVector3Array).size() > 0:
			parent.add_child(_mesh_node(ch.v, ch.n, ch.uv, ch.uv2, ch.c, PixelTex.solid_material(), "Chunk%d_%d" % [key.x, key.y]))
		if (ch.pv as PackedVector3Array).size() > 0:
			var pm: = _mesh_node(ch.pv, ch.pn, ch.puv, ch.puv2, ch.pc, PixelTex.plant_material(), "Plants%d_%d" % [key.x, key.y])
			pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(pm)
		if (ch.col as PackedVector3Array).size() > 0:
			var body: = StaticBody3D.new()
			var cs: = CollisionShape3D.new()
			var shape: = ConcavePolygonShape3D.new()
			shape.set_faces(ch.col)
			cs.shape = shape
			body.add_child(cs)
			collide_root.add_child(body)

	if _micro_roofs != null and not _micro_roofs.columns.is_empty():
		var roof_root: = Node3D.new()
		roof_root.name = "TenCentimeterRoofs"
		parent.add_child(roof_root)
		_micro_roofs.build(roof_root, collide_root)
	for fine_grid in [_rounded, _blobs]:
		if fine_grid != null and not fine_grid.columns.is_empty():
			var round_root: = Node3D.new()
			round_root.name = "RoundedNature"
			parent.add_child(round_root)
			fine_grid.build(round_root, collide_root)



func _prepare_micro_roofs() -> void:
	if _micro_roofs != null or not is_equal_approx(cell_size, 1.0):
		return
	_micro_roofs = load("res://scripts/voxel/micro_voxel.gd").new()
	var roof_ids: = [15, 16, 17, 39]
	for p: Vector3i in blocks:
		var id: int = blocks[p]
		if hidden_render.has(p):
			continue
		var trim: = false
		if id in [7, 27] and p.y >= 4:
			for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
				if blocks.get(p + d, 0) in roof_ids:
					trim = true
		if id not in roof_ids and not trim:
			continue
		var uphill: = Vector3i.ZERO
		for d: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			if blocks.get(p + d + Vector3i.UP, 0) == id:
				uphill = d
				break
		hidden_render[p] = true
		var units: = roundi(1.0 / STRUCTURE_GRID)
		for x in units:
			for z in units:
				var rise: = units - 1
				if uphill.x != 0:
					rise = x if uphill.x > 0 else units - 1 - x
				elif uphill.z != 0:
					rise = z if uphill.z > 0 else units - 1 - z
				_micro_roofs.column(p.x * units + x, p.z * units + z, p.y * units, p.y * units + rise, id)


func _ensure_rounded() -> void:
	if _rounded == null:
		_rounded = load("res://scripts/voxel/micro_voxel.gd").new()




func round_blob(center: Vector3, radius: Vector3, id: int, cells: Array, ragged: = -1) -> void:
	if not round_natural:
		return
	if _blobs == null:
		_blobs = load("res://scripts/voxel/micro_voxel.gd").new()
		_blobs.cell_size = BLOB_GRID
	for p: Vector3i in cells:
		hidden_render[p] = true
	var g: = BLOB_GRID
	for ix in range(floori((center.x - radius.x) / g), ceili((center.x + radius.x) / g)):
		for iz in range(floori((center.z - radius.z) / g), ceili((center.z + radius.z) / g)):
			var dx: = ((ix + 0.5) * g - center.x) / radius.x
			var dz: = ((iz + 0.5) * g - center.z) / radius.z
			var horizontal: = dx * dx + dz * dz
			if horizontal >= 1.0:
				continue
			var half: = radius.y * sqrt(1.0 - horizontal)
			var bottom: = maxi(0, ceili((center.y - half) / g - 0.5))
			var top: = floori((center.y + half) / g - 0.5)

			var leafy: = id in [8, 9, 10, 55, 59] if ragged < 0 else ragged > 0
			if leafy:
				var k: = PixelTex.h(ix, iz, 91)
				if k > 0.82:
					top -= 1
				elif k < 0.08:
					top += 1
			if top >= bottom:
				_blobs.column(ix, iz, bottom, top, id, true)


const _LEAF_IDS: = [8, 9, 10, 55, 59]


func _rounding_solid(p: Vector3i) -> bool:
	if p.y < 0:
		return true
	var nb: int = blocks.get(p, 0)
	if nb != 0:
		return nb != 13

	for k in [1, 2]:
		var above: int = blocks.get(p + Vector3i(0, k, 0), 0)
		if above != 0 and above != 13 and above not in _LEAF_IDS:
			return true
	return false



func _prepare_rounding() -> void:
	if not round_natural or _rounding_done or not is_equal_approx(cell_size, 1.0):
		return
	_rounding_done = true
	_ensure_rounded()
	var units: = roundi(1.0 / STRUCTURE_GRID)
	var dirs: = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, -1, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
	var todo: = []
	for p: Vector3i in blocks:
		var id: int = blocks[p]
		if p.y < 0 or hidden_render.has(p) or not (ROUND_RADIUS.has(id) or round_cells.has(p)):
			continue
		if round_area.has_area() and not round_area.has_point(Vector2(p.x, p.z)):
			continue
		var open: = []
		for d: Vector3i in dirs:
			open.append(not _rounding_solid(p + d))

		if id not in _LEAF_IDS:
			open[3] = false

		var axes: = int(open[0] or open[1]) + int(open[2] or open[3]) + int(open[4] or open[5])
		if axes < 2:
			continue
		todo.append([p, id, open])
	for item in todo:
		var p: Vector3i = item[0]
		var id: int = item[1]
		var open: Array = item[2]
		var r: float = ROUND_RADIUS.get(id, 2.5)

		if (open[0] and open[1]) or (open[2] and open[3]) or (open[4] and open[5]):
			r = minf(r, 2.5)
		var limit: = r - 0.5
		hidden_render[p] = true
		var lo: = r
		var hi: = float(units) - r
		for i in units:
			for k in units:
				var cx: = i + 0.5
				var cz: = k + 0.5
				var ox: = maxf(cx - hi if open[0] else 0.0, lo - cx if open[1] else 0.0)
				var oz: = maxf(cz - hi if open[4] else 0.0, lo - cz if open[5] else 0.0)
				ox = maxf(ox, 0.0)
				oz = maxf(oz, 0.0)
				var run_start: = -1
				for j in units + 1:
					var keep: = false
					if j < units:
						var cy: = j + 0.5
						var oy: = maxf(maxf(cy - hi if open[2] else 0.0, lo - cy if open[3] else 0.0), 0.0)
						keep = ox * ox + oy * oy + oz * oz <= limit * limit
					if keep and run_start < 0:
						run_start = j
					elif not keep and run_start >= 0:
						_rounded.add_run(p.x * units + i, p.z * units + k, p.y * units + run_start, p.y * units + j - 1, id)
						run_start = -1
	_rounded.finalize()


func _new_chunk() -> Dictionary:
	return {
		"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(),
		"uv2": PackedVector2Array(), "c": PackedColorArray(), "col": PackedVector3Array(),
		"pv": PackedVector3Array(), "pn": PackedVector3Array(), "puv": PackedVector2Array(),
		"puv2": PackedVector2Array(), "pc": PackedColorArray(),
	}




func _prepare_tops() -> void:
	_tops.clear()
	var ground: = { }
	for t in PixelTex.GROUND_TILES:
		ground[t] = true
	for p: Vector3i in blocks:
		var def: Array = BLOCKS.get(blocks[p], [])
		if def.is_empty() or not ground.has(def[0]):
			continue
		var above: int = blocks.get(p + Vector3i.UP, 0)
		if above != 0 and above != 13 and not hidden_render.has(p + Vector3i.UP):
			continue
		_tops[p] = PixelTex.tile_avg(def[0])


func _top_color(p: Vector3i) -> Variant:
	if _tops.has(p):
		return _tops[p]

	if p.y == -1 and plane_tile >= 0 and not blocks.has(p):
		return PixelTex.tile_avg(plane_tile)
	return null


func _corner_colors(p: Vector3i) -> Array:

	var out: = []
	for off in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
		var r: = 0.0
		var g: = 0.0
		var b: = 0.0
		var n: = 0
		for dx in [-1, 0]:
			for dz in [-1, 0]:
				var q: = Vector3i(p.x + off.x + dx, p.y, p.z + off.y + dz)
				var c = _top_color(q)
				if c != null:
					r += c.r
					g += c.g
					b += c.b
					n += 1
		out.append(Color(r / n, g / n, b / n, 0.5) if n > 0 else _tops[p])
	return out


func _emit(ch: Dictionary, base: Vector3, f: Array, tile: int, solid: bool, visible_face: = true, cols: Array = []) -> void:
	var corners: Array = f[1]
	var nrm: = Vector3(f[0])
	var shade: float = f[2]
	var t2: = PixelTex.tile_coord(tile)
	var col: = Color(shade, shade, shade)
	var q: = [(base + corners[0]) * cell_size, (base + corners[1]) * cell_size, (base + corners[2]) * cell_size, (base + corners[3]) * cell_size]
	# Interiors have metre-scale texture cells; outdoor art keeps its original density.
	var at := base * cell_size
	var metre := (at.x >= 136.0 and at.x < 194.0 and at.z >= -26.0 and at.z < 62.0) or (at.x >= 140.0 and at.x < 180.0 and at.z >= 64.0 and at.z < 100.0)
	var texture_grid := 1.0 if metre else STRUCTURE_GRID
	for i in [0, 1, 2, 0, 2, 3]:
		if visible_face:
			ch.v.append(q[i])
			ch.n.append(nrm)
			var repeat_scale: = cell_size / texture_grid if tile not in [T.DOOR, T.DOOR_TOP, T.BOOKSHELF, T.GLASS, T.BANNER] else 1.0
			ch.uv.append(UVS[i] * repeat_scale)
			ch.uv2.append(t2)
			ch.c.append(cols[i] if not cols.is_empty() else col)
		if solid:
			ch.col.append(q[i])


func _emit_plant(ch: Dictionary, base: Vector3, tile: int) -> void:
	var t2: = PixelTex.tile_coord(tile)
	var j: = Vector3(PixelTex.h(int(base.x), int(base.z), 5) * 0.3 - 0.15, 0, PixelTex.h(int(base.z), int(base.x), 6) * 0.3 - 0.15)
	var quads: = [
		[Vector3(0.15, 1, 0.15), Vector3(0.85, 1, 0.85), Vector3(0.85, 0, 0.85), Vector3(0.15, 0, 0.15)],
		[Vector3(0.85, 1, 0.15), Vector3(0.15, 1, 0.85), Vector3(0.15, 0, 0.85), Vector3(0.85, 0, 0.15)],
	]
	for qd in quads:
		var q: = [base + j + qd[0], base + j + qd[1], base + j + qd[2], base + j + qd[3]]
		for i in [0, 1, 2, 0, 2, 3]:
			ch.pv.append(q[i])
			ch.pn.append(Vector3.UP)
			ch.puv.append(UVS[i])
			ch.puv2.append(t2)
			ch.pc.append(Color(0.95, 0.95, 0.95))


func _mesh_node(v: PackedVector3Array, n: PackedVector3Array, uv: PackedVector2Array, uv2: PackedVector2Array,
		c: PackedColorArray, mat: Material, node_name: String) -> MeshInstance3D:
	var arr: = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_TEX_UV2] = uv2
	arr[Mesh.ARRAY_COLOR] = c
	var m: = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi: = MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = m
	mi.material_override = mat
	return mi



static func ground_plane(size: = 300.0, tile: = T.GRASS_TOP, center: = Vector2.ZERO) -> MeshInstance3D:
	var t2: = PixelTex.tile_coord(tile)
	var y: = -0.04
	var cx: = center.x
	var cz: = center.y
	var q: = [Vector3(cx - size, y, cz - size), Vector3(cx + size, y, cz - size), Vector3(cx + size, y, cz + size), Vector3(cx - size, y, cz + size)]
	var v: = PackedVector3Array()
	var uv: = PackedVector2Array()
	var uv2: = PackedVector2Array()
	var n: = PackedVector3Array()
	var c: = PackedColorArray()
	for i in [0, 1, 2, 0, 2, 3]:
		v.append(q[i])
		uv.append(Vector2(q[i].x, q[i].z) / STRUCTURE_GRID)
		uv2.append(t2)
		n.append(Vector3.UP)
		c.append(PixelTex.tile_avg(tile) if tile in PixelTex.GROUND_TILES else Color(1, 1, 1))
	var arr: = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_TEX_UV2] = uv2
	arr[Mesh.ARRAY_COLOR] = c
	var m: = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi: = MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = m
	mi.material_override = PixelTex.solid_material()
	return mi
