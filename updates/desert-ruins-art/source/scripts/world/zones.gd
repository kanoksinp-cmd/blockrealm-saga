class_name Zones
extends RefCounted









const T: = preload("res://scripts/voxel/pixel_tex.gd")

const GRASS: = 1
const DIRT: = 2
const STONE: = 3
const COBBLE: = 4
const BRICK: = 5
const PLANKS: = 6
const LOG: = 7
const LEAVES: = 8
const PINE: = 10
const PATH: = 11
const GRAVEL: = 12
const WATER: = 13
const GOLD: = 26
const GLOW: = 29
const IRON: = 30
const SAND: = 32
const DARK_PLANKS: = 34
const BARREL: = 36
const VOID: = 40
const STONE_TILE: = 41
const SNOW: = 43
const SNOW_BLOCK: = 44
const ICE: = 45
const PACKED_ICE: = 46
const SANDSTONE: = 47
const CARVED: = 48
const BASALT: = 49
const MAGMA: = 50
const ASH: = 51
const OBSIDIAN: = 52
const MOSSY: = 53
const MOSSY_BRICK: = 54
const JUNGLE: = 55
const CACTUS: = 56
const JADE: = 57
const BONE: = 58
const RED_SAND: = 60
const DARK_GRASS: = 61
const GOLD_TILE: = 62
const CRYSTAL: = 63


const CENTER: = { "chivalry_d": Vector2i(2600, 400), "abyss_d": Vector2i(3000, 400), "valhalla_d": Vector2i(3400, 400), "verdant": Vector2i(1000, 0), "desert": Vector2i(1400, 0), "frost": Vector2i(1800, 0), "ember": Vector2i(2200, 0),
	"verdant_d": Vector2i(1000, 400), "desert_d": Vector2i(1400, 400), "frost_d": Vector2i(1800, 400), "ember_d": Vector2i(2200, 400) }
const FIELD_HALF: = 100
const GROUND: = { "verdant": T.DARK_GRASS, "desert": T.SAND, "frost": T.SNOW, "ember": T.ASH }

const LEVELS: = { "chivalry_d": "Lv 61-74", "abyss_d": "Lv 75-87", "valhalla_d": "Lv 88-99", "verdant": "Lv 21-32", "desert": "Lv 29-40", "frost": "Lv 37-55", "ember": "Lv 46-56",
	"verdant_d": "Lv 29-35", "desert_d": "Lv 37-43", "frost_d": "Lv 45-52", "ember_d": "Lv 54-60" }

const ROOMS: = [[Vector2i(0, 50), Vector2i(14, 12)], [Vector2i(-32, 22), Vector2i(18, 14)], [Vector2i(28, 8), Vector2i(18, 16)],
	[Vector2i(-24, -20), Vector2i(18, 16)], [Vector2i(8, -50), Vector2i(26, 20)]]

var area: String
var w: BlockWorld
var rng: = RandomNumberGenerator.new()
var c: = Vector2i.ZERO
var nav_block: Array[Vector2i] = []
var lights: Array[Vector3] = []
var light_color: = Color(1.0, 0.7, 0.4)
var npcs: Array = []
var _keep: Array[Rect2] = []
var _trees: Array[Vector2] = []


func _init(a: String, bw: BlockWorld) -> void:
	area = a
	w = bw
	c = CENTER[a]
	rng.seed = a.hash()


static func is_field(a: String) -> bool:
	return GROUND.has(a)


static func is_dungeon(a: String) -> bool:
	return a.ends_with("_d") and CENTER.has(a)


func build() -> void:
	if is_field(area):
		w.round_area = Rect2(Vector2(c) - Vector2.ONE * (FIELD_HALF - 2), Vector2.ONE * (FIELD_HALF - 2) * 2)
	match area:
		"verdant":
			_verdant()
		"desert":
			_desert()
		"frost":
			_frost()
		"ember":
			_ember()
		_:
			_dungeon()




func sb(x: int, y: int, z: int, id: int) -> void:
	w.setb(c.x + x, y, c.y + z, id)


func gb(x: int, y: int, z: int) -> int:
	return w.getb(c.x + x, y, c.y + z)


func decal(x: int, z: int, id: int) -> void:
	w.decal(c.x + x, c.y + z, id)


func plant(x: int, z: int, tile: int) -> void:
	if gb(x, 0, z) == 0 and w.getb(c.x + x, -1, c.y + z) != WATER and w.getb(c.x + x, -1, c.y + z) != MAGMA:
		w.plant(c.x + x, c.y + z, tile)


func fill(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, id: int) -> void:
	w.fill(c.x + x0, y0, c.y + z0, c.x + x1, y1, c.y + z1, id)


func block_nav(x: int, z: int) -> void:
	nav_block.append(Vector2i(c.x + x, c.y + z))


func keep(r: Rect2) -> void:
	_keep.append(r)


func kept(x: float, z: float, pad: = 0.0) -> bool:
	for r in _keep:
		if r.grow(pad).has_point(Vector2(x, z)):
			return true
	return false


func noise2(x: float, z: float, s: int) -> float:

	var xi: = floori(x)
	var zi: = floori(z)
	var fx: = x - xi
	var fz: = z - zi
	var a: = PixelTex.h(xi, zi, s)
	var b: = PixelTex.h(xi + 1, zi, s)
	var cc: = PixelTex.h(xi, zi + 1, s)
	var d: = PixelTex.h(xi + 1, zi + 1, s)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	return lerpf(lerpf(a, b, fx), lerpf(cc, d, fx), fz)



func terrain(hm: Dictionary, top: int, side: int) -> void:
	for p: Vector2i in hm:
		var h: int = hm[p]
		if h <= 0:
			continue
		var low: = h
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			low = mini(low, int(hm.get(p + d, 0)))
		for y in range(maxi(0, low - 1), h):
			sb(p.x, y, p.y, top if y == h - 1 else side)
			w.round_cells[Vector3i(c.x + p.x, y, c.y + p.y)] = true



func border(top: int, side: int, base: = 3, extra: = 7, seed: = 5) -> void:
	var hm: = { }
	var H: = FIELD_HALF + 12
	for x in range(- H, H + 1):
		for z in range(- H, H + 1):
			var d: = maxf(absf(x), absf(z)) + (noise2(x * 0.12, z * 0.12, seed) - 0.5) * 9.0
			if d < FIELD_HALF - 2:
				continue
			var h: = int(clampf((d - (FIELD_HALF - 2)) * 0.9 + base + noise2(x * 0.3, z * 0.3, seed + 1) * extra, 1, base + extra + 6))
			hm[Vector2i(x, z)] = h

	for g in _gates():
		for dx in range(-4, 5):
			for dz in range(-4, 5):
				hm.erase(Vector2i(g.x + dx, g.y + dz))
	terrain(hm, top, side)



func _gates() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for wp in VillageBuilder.WARPS:
		if wp.area == area:
			var p: = Vector2i(roundi(float(wp.pos.x)) - c.x, roundi(float(wp.pos.y)) - c.y)
			if maxi(absi(p.x), absi(p.y)) > FIELD_HALF - 15:
				out.append(p)
	return out



func path(pts: Array, tile: int, width: = 1) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b2: Vector2 = pts[i + 1]
		var n: = int(a.distance_to(b2))
		for k in n + 1:
			var p: = a.lerp(b2, float(k) / maxf(1.0, float(n)))
			var side: = Vector2(- (b2 - a).y, (b2 - a).x).normalized()
			p += side * (noise2(p.x * 0.08, p.y * 0.08, 77) - 0.5) * 6.0
			for dx in range(- width, width + 1):
				for dz in range(- width, width + 1):
					var q: = Vector2i(roundi(p.x) + dx, roundi(p.y) + dz)
					if gb(q.x, -1, q.y) != WATER:
						decal(q.x, q.y, tile)
			keep(Rect2(p - Vector2(width + 1.5, width + 1.5), Vector2(width * 2 + 3, width * 2 + 3)))



func gateway(p: Vector2i, pillar: int, cap: int, along_x: bool) -> void:
	for s in [-1, 1]:
		var px: int = p.x + (s * 3 if along_x else 0)
		var pz: int = p.y + (0 if along_x else s * 3)
		fill(px, 0, pz, px, 4, pz, pillar)
		sb(px, 5, pz, cap)
	for k in range(-3, 4):
		sb(p.x + (k if along_x else 0), 5, p.y + (0 if along_x else k), cap)
	sb(p.x, 6, p.y, GLOW)
	keep(Rect2(Vector2(p) - Vector2(6, 6), Vector2(12, 12)))


func pond(cx: int, cz: int, rx: float, rz: float, edge: = 0, tile: = WATER) -> void:
	for x in range(cx - int(rx) - 2, cx + int(rx) + 3):
		for z in range(cz - int(rz) - 2, cz + int(rz) + 3):
			var d: = Vector2((x - cx) / rx, (z - cz) / rz).length() + (noise2(x * 0.3, z * 0.3, 31) - 0.5) * 0.3
			if d < 1.0:
				decal(x, z, tile)
				if tile == WATER or tile == MAGMA:
					block_nav(x, z)
			elif d < 1.25 and edge != 0:
				decal(x, z, edge)
	keep(Rect2(cx - rx - 2, cz - rz - 2, rx * 2 + 4, rz * 2 + 4))


func scatter_plants(tiles: Array, count: int, spread: = FIELD_HALF - 4) -> void:
	var n: = 0
	var tries: = 0
	while n < count and tries < count * 5:
		tries += 1
		var x: = rng.randi_range(- spread, spread)
		var z: = rng.randi_range(- spread, spread)
		if gb(x, 0, z) != 0 or w.getb(c.x + x, -1, c.y + z) != 0:
			continue
		plant(x, z, tiles[rng.randi() % tiles.size()])
		n += 1


func _free(x: float, z: float, gap: float) -> bool:
	if maxf(absf(x), absf(z)) > FIELD_HALF - 6 or kept(x, z, 1.0):
		return false
	for t in _trees:
		if t.distance_to(Vector2(x, z)) < gap:
			return false
	return true


func scatter(count: int, gap: float, fn: Callable, spread: = FIELD_HALF - 6) -> void:
	var n: = 0
	var tries: = 0
	while n < count and tries < count * 12:
		tries += 1
		var x: = rng.randi_range(- spread, spread)
		var z: = rng.randi_range(- spread, spread)
		if not _free(x, z, gap):
			continue
		_trees.append(Vector2(x, z))
		fn.call(x, z)
		n += 1


func leaf(x: int, y: int, z: int, id: int) -> void:
	if gb(x, y, z) == 0:
		sb(x, y, z, id)


func blob(x: int, y: int, z: int, r: float, id: int, squash: = 1.0) -> void:
	var ri: = int(ceil(r))
	var placed: Array = []
	for dx in range(- ri, ri + 1):
		for dy in range(- ri, ri + 1):
			for dz in range(- ri, ri + 1):
				if Vector3(dx, dy / squash, dz).length() <= r + (PixelTex.h(x + dx, z + dz, y + dy) - 0.5) * 0.6:
					if gb(x + dx, y + dy, z + dz) == 0:
						sb(x + dx, y + dy, z + dz, id)
						placed.append(Vector3i(c.x + x + dx, y + dy, c.y + z + dz))

	w.round_blob(Vector3(c.x + x + 0.5, y + 0.5, c.y + z + 0.5), Vector3(r + 0.3, (r + 0.3) * squash, r + 0.3), id, placed)



func _keep_spawns() -> void:
	var zones: Array = load("res://scripts/monsters/spawner.gd").ZONES
	for z in zones:
		if String(z.get("area", "town")) != area:
			continue
		var spots: Array = z.get("spots", [[z.pos, z.r]])
		for s in spots:
			var p: Vector2 = s[0] - Vector2(c)
			var r: = float(s[1]) * (0.55 if z.get("boss", false) else 0.45)
			keep(Rect2(p - Vector2(r, r), Vector2(r * 2, r * 2)))


func _warp_keeper(p: Vector2i) -> void:
	npcs.append(["Warp Crystal", "warp", Vector3(c.x + p.x + 0.5, 0, c.y + p.y + 0.5), 0.0])
	keep(Rect2(Vector2(p) - Vector2(3, 3), Vector2(6, 6)))
	for d in [Vector2i(-2, -2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(2, 2)]:
		sb(p.x + d.x, 0, p.y + d.y, STONE_TILE)
		sb(p.x + d.x, 1, p.y + d.y, GLOW)




func _verdant() -> void:
	_keep_spawns()
	var gates: = _gates()
	for g in gates:
		gateway(g, MOSSY, MOSSY_BRICK, absi(g.y) > absi(g.x))
	_warp_keeper(Vector2i(84, 8))
	var temple: = Vector2i(-55, -62)
	path([Vector2(92, 0), Vector2(60, 10), Vector2(20, -10), Vector2(-20, -25), Vector2(-55, -50)], MOSSY)
	path([Vector2(20, -10), Vector2(40, -50), Vector2(55, -90)], MOSSY)
	path([Vector2(-20, -25), Vector2(-30, 20), Vector2(-60, 55)], MOSSY)
	border(GRASS, MOSSY, 3, 6, 11)
	pond(30, 62, 9, 6, MOSSY)
	pond(-80, 20, 6, 9, MOSSY)
	pond(70, -40, 7, 5, MOSSY)
	_temple(temple)

	var rc: = Vector2i(-55, -10)
	for side in 4:
		for k in range(-11, 12):
			var x: = rc.x + (k if side < 2 else (-11 if side == 2 else 11))
			var z: = rc.y + ((-11 if side == 0 else 11) if side < 2 else k)
			if absi(k) < 3 and side % 2 == 0:
				continue
			var hh: = int(noise2(x * 0.4, z * 0.4, 21) * 4.5)
			for y in hh:
				sb(x, y, z, MOSSY_BRICK if (x + y + z) % 3 else MOSSY)
	for p in [Vector2i(-62, -17), Vector2i(-48, -17), Vector2i(-62, -3), Vector2i(-48, -3)]:
		fill(p.x, 0, p.y, p.x, 3 + rng.randi() % 3, p.y, MOSSY)
	for p in [Vector2i(-55, -10)]:
		fill(p.x - 1, 0, p.y - 1, p.x + 1, 0, p.y + 1, MOSSY_BRICK)
		fill(p.x, 1, p.y, p.x, 3, p.y, JADE)

	preload("res://scripts/world/ruins_art.gd").decorate(self)
	scatter(26, 7.0, func (x: int, z: int) -> void:
		var hh: = 2 + rng.randi() % 5
		for y in hh:
			sb(x, y, z, MOSSY if y % 2 else MOSSY_BRICK)
		if rng.randf() < 0.4:
			sb(x + 1, 0, z, MOSSY_BRICK))

	scatter(230, 4.0, func (x: int, z: int) -> void: _jungle_tree(x, z))
	scatter(70, 3.0, func (x: int, z: int) -> void: blob(x, 0, z, 1.4 + rng.randf(), JUNGLE, 0.7))
	scatter_plants([T.FERN, T.FERN, T.TALL_GRASS, T.VINE, T.GLOW_SHROOM, T.FLOWER_RED, T.FLOWER], 1500)


func _jungle_tree(x: int, z: int) -> void:
	var hh: = 6 + rng.randi() % 5
	for y in hh:
		sb(x, y, z, LOG)
	if hh > 8:
		for d in [Vector2i(1, 0), Vector2i(0, 1)]:
			sb(x + d.x, 0, z + d.y, LOG)
	blob(x, hh, z, 2.6 + rng.randf() * 0.8, JUNGLE, 0.6)
	if rng.randf() < 0.5:
		blob(x + rng.randi_range(-2, 2), hh - 2, z + rng.randi_range(-2, 2), 1.6, JUNGLE, 0.7)


func _temple(p: Vector2i) -> void:
	keep(Rect2(Vector2(p) - Vector2(11, 11), Vector2(22, 24)))
	for tier in 5:
		var r: = 9 - tier * 2
		for x in range(- r, r + 1):
			for z in range(- r, r + 1):
				if absi(x) == r or absi(z) == r or tier == 4:
					fill(p.x + x, tier * 2, p.y + z, p.x + x, tier * 2 + 1, p.y + z, MOSSY_BRICK if (x + z + tier) % 4 else MOSSY)

	for y in 3:
		for x in range(-1, 2):
			sb(p.x + x, y, p.y + 9, VOID)
	for x in [-2, 2]:
		fill(p.x + x, 0, p.y + 10, p.x + x, 3, p.y + 10, JADE)
	sb(p.x, 3, p.y + 10, GLOW)
	for x in range(-2, 3):
		decal(p.x + x, p.y + 11, STONE_TILE)
		decal(p.x + x, p.y + 12, STONE_TILE)
	fill(p.x - 1, 10, p.y - 1, p.x + 1, 11, p.y + 1, JADE)




func _desert() -> void:
	_keep_spawns()
	for g in _gates():
		gateway(g, SANDSTONE, CARVED, absi(g.y) > absi(g.x))
	_warp_keeper(Vector2i(8, -84))
	path([Vector2(0, -92), Vector2(0, -60), Vector2(-10, -20), Vector2(0, 40)], SANDSTONE)
	path([Vector2(-10, -20), Vector2(40, 30), Vector2(65, 62)], SANDSTONE)
	border(SAND, SANDSTONE, 3, 7, 13)
	pond(-18, -2, 7, 5, GRASS)
	for p in [Vector2i(-25, -6), Vector2i(-12, 4), Vector2i(-24, 3), Vector2i(-10, -8)]:
		_palm(p.x, p.y)
	_pyramid(Vector2i(0, 62))

	var sk: = Vector2i(30, -10)
	keep(Rect2(Vector2(sk) - Vector2(4, 10), Vector2(8, 22)))
	for i in 6:
		var z: = sk.y - 6 + i * 2
		for s in [-1, 1]:
			for y in range(0, 5):
				var x: int = sk.x + s * (3 - int(y / 3)) if y < 4 else sk.x + s * 1
				sb(x, y, z, BONE)
		sb(sk.x, 4, z, BONE)
	fill(sk.x - 2, 0, sk.y + 7, sk.x + 2, 3, sk.y + 10, BONE)
	sb(sk.x - 1, 2, sk.y + 10, VOID)
	sb(sk.x + 1, 2, sk.y + 10, VOID)

	preload("res://scripts/world/ruins_art.gd").decorate(self)
	scatter(22, 12.0, func (x: int, z: int) -> void:
		var r: = 2.0 + rng.randf() * 3.5
		var hh: = 4 + rng.randi() % 8
		var hm: = { }
		for dx in range(- int(r) - 1, int(r) + 2):
			for dz in range(- int(r) - 1, int(r) + 2):
				var d: = Vector2(dx, dz).length() + (noise2((x + dx) * 0.5, (z + dz) * 0.5, 41) - 0.5) * 1.5
				if d <= r:
					hm[Vector2i(x + dx, z + dz)] = hh - (1 if d > r - 1 else 0)
		terrain(hm, RED_SAND, SANDSTONE))

	scatter(40, 6.0, func (x: int, z: int) -> void: blob(x, -1, z, 2.2 + rng.randf() * 1.8, SAND, 0.45))

	scatter(70, 3.5, func (x: int, z: int) -> void:
		var hh: = 2 + rng.randi() % 3
		for y in hh:
			sb(x, y, z, CACTUS)
		if hh >= 3 and rng.randf() < 0.6:
			var s: = 1 if rng.randf() < 0.5 else -1
			sb(x + s, 1, z, CACTUS)
			sb(x + s, 2, z, CACTUS))
	scatter_plants([T.DEAD_BUSH, T.DEAD_BUSH, T.TALL_GRASS], 500)


func _palm(x: int, z: int) -> void:
	var hh: = 6 + rng.randi() % 3
	var lean: = rng.randi_range(-1, 1)
	var tx: = x
	for y in hh:
		if y == hh / 2:
			tx += lean
		sb(tx, y, z, LOG)
	var fronds: Array = []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		for k in range(1, 4):
			leaf(tx + d.x * k, hh - (1 if k == 3 else 0), z + d.y * k, JUNGLE)
			fronds.append(Vector3i(c.x + tx + d.x * k, hh - (1 if k == 3 else 0), c.y + z + d.y * k))
	leaf(tx, hh, z, JUNGLE)
	fronds.append(Vector3i(c.x + tx, hh, c.y + z))

	var top: = Vector3(c.x + tx + 0.5, hh + 0.55, c.y + z + 0.5)
	w.round_blob(top, Vector3(0.75, 0.45, 0.75), JUNGLE, fronds)
	for i in 6:
		var ang: = TAU * i / 6.0 + float(hh) * 0.4
		var dir: = Vector3(cos(ang), 0, sin(ang))
		for k in range(1, 5):
			var along: = 0.65 * k
			var p: = top + dir * along + Vector3(0, -0.06 * k * k, 0)
			var wide: = 0.42 - 0.07 * k
			w.round_blob(p, Vector3(maxf(0.25, wide + absf(dir.x) * 0.25), 0.16, maxf(0.25, wide + absf(dir.z) * 0.25)), JUNGLE, [], 0)


func _pyramid(p: Vector2i) -> void:
	keep(Rect2(Vector2(p) - Vector2(17, 20), Vector2(34, 36)))
	for tier in 14:
		var r: = 15 - tier
		for x in range(- r, r + 1):
			for z in range(- r, r + 1):
				if absi(x) == r or absi(z) == r or tier == 13:
					sb(p.x + x, tier, p.y + z, GOLD_TILE if tier >= 12 else (CARVED if tier % 4 == 3 else SANDSTONE))

	for y in 4:
		for x in range(-1, 2):
			for z in range(0, 3):
				var gz: = p.y - 15 + z
				if gb(p.x + x, y, gz) != 0:
					sb(p.x + x, y, gz, VOID)
	for x in [-2, 2]:
		fill(p.x + x, 0, p.y - 16, p.x + x, 4, p.y - 16, CARVED)
	sb(p.x, 5, p.y - 16, GOLD_TILE)
	for x in range(-3, 4):
		for z in range(-21, -16):
			decal(p.x + x, p.y + z, SANDSTONE)




func _frost() -> void:
	_keep_spawns()
	for g in _gates():
		gateway(g, PACKED_ICE, SNOW_BLOCK, absi(g.y) > absi(g.x))
	_warp_keeper(Vector2i(-84, 8))
	path([Vector2(-92, 0), Vector2(-50, -5), Vector2(0, -20), Vector2(55, -45)], PACKED_ICE)
	path([Vector2(0, -20), Vector2(0, -90)], PACKED_ICE)
	path([Vector2(-50, -5), Vector2(10, 40), Vector2(60, 62)], PACKED_ICE)
	border(SNOW, STONE, 4, 9, 17)
	pond(-10, 20, 14, 9, SNOW_BLOCK, ICE)
	for x in range(-24, 5):
		for z in range(11, 30):
			nav_block.erase(Vector2i(c.x + x, c.y + z))
	_cave_hill(Vector2i(60, -64))

	scatter(30, 8.0, func (x: int, z: int) -> void:
		var hh: = 5 + rng.randi() % 10
		for y in hh:
			sb(x, y, z, PACKED_ICE if y < hh - 2 else ICE)
		if hh > 8:
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				for y in hh / 2:
					sb(x + d.x, y, z + d.y, PACKED_ICE))

	scatter(130, 4.5, func (x: int, z: int) -> void: _snow_pine(x, z))
	scatter(40, 5.0, func (x: int, z: int) -> void:
		blob(x, 0, z, 1.3 + rng.randf(), STONE, 0.8)
		blob(x, 1, z, 1.2, SNOW_BLOCK, 0.4))
	scatter_plants([T.FROST_GRASS, T.FROST_GRASS, T.DEAD_BUSH], 700)


func _snow_pine(x: int, z: int) -> void:
	var hh: = 6 + rng.randi() % 4
	for y in hh:
		sb(x, y, z, LOG)
	var cells: Array = []
	for y in range(2, hh + 1):
		var r: = 2 if (hh - y) % 3 == 2 and y < hh - 2 else (1 if y < hh else 0)
		for dx in range(- r, r + 1):
			for dz in range(- r, r + 1):
				if r == 2 and absi(dx) == 2 and absi(dz) == 2:
					continue
				leaf(x + dx, y, z + dz, PINE if (y + dx + dz) % 3 else SNOW_BLOCK)
				cells.append(Vector3i(c.x + x + dx, y, c.y + z + dz))
	leaf(x, hh + 1, z, SNOW_BLOCK)
	cells.append(Vector3i(c.x + x, hh + 1, c.y + z))

	var base: = Vector3(c.x + x + 0.5, 0, c.y + z + 0.5)
	for t in range(0, (hh - 1) * 2):
		var y: = 2.0 + t * 0.5
		var rr: = maxf(0.35, (hh + 1.2 - y) * 0.42) + (0.25 if t % 3 == 0 else 0.0)
		w.round_blob(base + Vector3(0, y + 0.2, 0), Vector3(rr * 0.72, 0.16, rr * 0.72), SNOW_BLOCK, [], 0)
		w.round_blob(base + Vector3(0, y, 0), Vector3(rr, 0.38, rr), PINE, [], 1)
	w.round_blob(base + Vector3(0, hh + 1.3, 0), Vector3(0.3, 0.45, 0.3), SNOW_BLOCK, [], 0)
	if w.round_natural:
		for p: Vector3i in cells:
			w.hidden_render[p] = true


func _cave_hill(p: Vector2i) -> void:
	keep(Rect2(Vector2(p) - Vector2(13, 13), Vector2(26, 30)))
	var hm: = { }
	for dx in range(-12, 13):
		for dz in range(-12, 13):
			var d: = Vector2(dx, dz).length() + (noise2((p.x + dx) * 0.3, (p.y + dz) * 0.3, 51) - 0.5) * 2.0
			if d < 12:
				hm[Vector2i(p.x + dx, p.y + dz)] = int(clampf((12 - d) * 0.9, 1, 10))
	terrain(hm, SNOW, STONE)

	for y in 4:
		for x in range(-2, 3):
			for z in range(5, 13):
				if gb(p.x + x, y, p.y + z) != 0:
					sb(p.x + x, y, p.y + z, VOID if z < 9 else 0)
	for x in [-3, 3]:
		fill(p.x + x, 0, p.y + 11, p.x + x, 3, p.y + 11, PACKED_ICE)
	sb(p.x, 4, p.y + 11, CRYSTAL)




func _ember() -> void:
	_keep_spawns()
	for g in _gates():
		gateway(g, BASALT, OBSIDIAN, absi(g.y) > absi(g.x))
	_warp_keeper(Vector2i(-84, 38))
	path([Vector2(-92, 30), Vector2(-40, 20), Vector2(10, -10), Vector2(10, -28)], BASALT)
	path([Vector2(30, 92), Vector2(25, 40), Vector2(10, -10)], BASALT)
	path([Vector2(-40, 20), Vector2(-60, -40), Vector2(-70, -68)], BASALT)
	border(BASALT, BASALT, 4, 8, 23)
	_volcano(Vector2i(10, -60))

	for river in [[Vector2(-15, -40), Vector2(-30, 0), Vector2(-75, 10)], [Vector2(30, -40), Vector2(60, 10), Vector2(80, 60)]]:
		for i in river.size() - 1:
			var a: Vector2 = river[i]
			var b2: Vector2 = river[i + 1]
			var n: = int(a.distance_to(b2))
			for k in n + 1:
				var p: = a.lerp(b2, float(k) / n)
				p += Vector2(- (b2 - a).y, (b2 - a).x).normalized() * (noise2(p.x * 0.1, p.y * 0.1, 61) - 0.5) * 8.0
				var wdt: = 1.5 + noise2(p.x * 0.2, p.y * 0.2, 62) * 1.5
				for dx in range(-3, 4):
					for dz in range(-3, 4):
						var q: = Vector2i(roundi(p.x) + dx, roundi(p.y) + dz)
						var dd: = Vector2(dx, dz).length()
						if kept(q.x, q.y) and dd > 0.5:
							continue
						if dd <= wdt:
							decal(q.x, q.y, MAGMA)
							block_nav(q.x, q.y)
						elif dd <= wdt + 1.2 and w.getb(c.x + q.x, -1, c.y + q.y) != MAGMA:
							decal(q.x, q.y, OBSIDIAN)

	for p in nav_block.duplicate():
		var l: = Vector2(p.x - c.x, p.y - c.y)
		if kept(l.x, l.y):
			decal(int(l.x), int(l.y), DARK_PLANKS)
			nav_block.erase(p)

	scatter(40, 6.0, func (x: int, z: int) -> void:
		var hh: = 3 + rng.randi() % 8
		var r: = rng.randi() % 2
		for dx in range(- r, r + 1):
			for dz in range(- r, r + 1):
				fill(x + dx, 0, z + dz, x + dx, hh - absi(dx) - absi(dz), z + dz, BASALT)
		if rng.randf() < 0.3:
			sb(x, hh + 1, z, MAGMA))
	scatter(30, 5.0, func (x: int, z: int) -> void:
		var hh: = 2 + rng.randi() % 4
		for y in hh:
			sb(x, y, z, OBSIDIAN))
	scatter(45, 5.0, func (x: int, z: int) -> void:
		var hh: = 3 + rng.randi() % 4
		for y in hh:
			sb(x, y, z, LOG)
		sb(x + 1, hh - 1, z, LOG)
		sb(x - 1, hh - 2, z, LOG))
	scatter_plants([T.DEAD_BUSH, T.FIRE_FLOWER, T.DEAD_BUSH], 500)


func _volcano(p: Vector2i) -> void:
	keep(Rect2(Vector2(p) - Vector2(28, 28), Vector2(56, 60)))
	var hm: = { }
	var R: = 26.0
	for dx in range(-27, 28):
		for dz in range(-27, 28):
			var d: = Vector2(dx, dz).length() + (noise2((p.x + dx) * 0.25, (p.y + dz) * 0.25, 71) - 0.5) * 3.0
			if d < R:
				var hh: = int((R - d) * 0.75)
				if d < 5.0:
					hh = int((R - 5.0) * 0.75) - 2
				hm[Vector2i(p.x + dx, p.y + dz)] = clampi(hh, 1, 18)

	for dz in range(16, 28):
		for dx in range(-2, 3):
			hm.erase(Vector2i(p.x + dx, p.y + dz))
	terrain(hm, BASALT, BASALT)
	for dx in range(-5, 6):
		for dz in range(-5, 6):
			if Vector2(dx, dz).length() < 4.5:
				var k: = Vector2i(p.x + dx, p.y + dz)
				sb(k.x, int(hm.get(k, 1)) - 1, k.y, MAGMA)

	for ang in [0.6, 2.2, 3.9]:
		for r in range(5, 24):
			var x: = p.x + roundi(cos(ang) * r)
			var z: = p.y + roundi(sin(ang) * r)
			var k: = Vector2i(x, z)
			if hm.has(k):
				sb(x, int(hm[k]) - 1, z, MAGMA)

	for y in 5:
		for s in [-3, 3]:
			sb(p.x + s, y, p.y + 17, OBSIDIAN)
	for x in range(-3, 4):
		sb(p.x + x, 5, p.y + 17, OBSIDIAN)
	for x in range(-2, 3):
		for y in 4:
			sb(p.x + x, y, p.y + 16, VOID)
	sb(p.x, 6, p.y + 17, MAGMA)




const DTHEME: = {
	"chivalry_d": { "floor": STONE_TILE, "floor2": GOLD_TILE, "wall": BRICK, "wall2": COBBLE, "pillar": IRON, "light": Color(0.6, 0.75, 1.0) },
	"abyss_d": { "floor": BASALT, "floor2": OBSIDIAN, "wall": OBSIDIAN, "wall2": MOSSY_BRICK, "pillar": CRYSTAL, "light": Color(0.75, 0.35, 1.0) },
	"valhalla_d": { "floor": SNOW_BLOCK, "floor2": GOLD_TILE, "wall": STONE_TILE, "wall2": CARVED, "pillar": GOLD, "light": Color(1.0, 0.8, 0.5) },
	"verdant_d": { "floor": MOSSY, "floor2": STONE_TILE, "wall": MOSSY_BRICK, "wall2": MOSSY, "pillar": JADE, "light": Color(0.5, 1.0, 0.6) },
	"desert_d": { "floor": SANDSTONE, "floor2": GOLD_TILE, "wall": CARVED, "wall2": SANDSTONE, "pillar": GOLD_TILE, "light": Color(1.0, 0.75, 0.4) },
	"frost_d": { "floor": PACKED_ICE, "floor2": SNOW_BLOCK, "wall": ICE, "wall2": PACKED_ICE, "pillar": CRYSTAL, "light": Color(0.55, 0.8, 1.0) },
	"ember_d": { "floor": ASH, "floor2": BASALT, "wall": BASALT, "wall2": MAGMA, "pillar": OBSIDIAN, "light": Color(1.0, 0.5, 0.2) },
}


func _dungeon() -> void:
	var th: Dictionary = DTHEME[area]
	light_color = th.light
	var floor: = { }
	for i in ROOMS.size():
		var r: Array = ROOMS[i]
		var rc: Vector2i = r[0]
		var rs: Vector2i = r[1]
		for x in range(rc.x - rs.x / 2, rc.x + rs.x / 2):
			for z in range(rc.y - rs.y / 2, rc.y + rs.y / 2):
				floor[Vector2i(x, z)] = 1 if i < ROOMS.size() - 1 else 2
		if i > 0:
			var a: Vector2i = (ROOMS[i - 1] as Array)[0]
			var b2: Vector2i = rc
			var corner: = Vector2i(b2.x, a.y)
			for seg in [[a, corner], [corner, b2]]:
				var s0: Vector2i = seg[0]
				var s1: Vector2i = seg[1]
				var n: = maxi(absi(s1.x - s0.x), absi(s1.y - s0.y))
				for k in n + 1:
					var p: = Vector2(s0).lerp(Vector2(s1), float(k) / maxf(1.0, n))
					for dx in range(-2, 2):
						for dz in range(-2, 2):
							var q: = Vector2i(roundi(p.x) + dx, roundi(p.y) + dz)
							if not floor.has(q):
								floor[q] = 3
	for p: Vector2i in floor:
		var kind: int = floor[p]
		var t: int = th.floor
		if kind == 2 and (p.x + p.y) % 6 == 0:
			t = th.floor2
		elif kind == 3:
			t = th.floor2 if (p.x * 3 + p.y) % 7 == 0 else th.floor
		elif PixelTex.h(p.x, p.y, 5) > 0.88:
			t = th.floor2
		decal(p.x, p.y, t)

	var walls: = { }
	for p: Vector2i in floor:
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var q: = p + Vector2i(dx, dz)
				if not floor.has(q):
					walls[q] = true
	var torch_i: = 0
	for q: Vector2i in walls:
		var hh: = 4
		for y in hh:
			var wid: int = th.wall if (q.x + q.y + y) % 5 else th.wall2
			if area == "ember_d" and wid == MAGMA and (q.x * 7 + q.y) % 3 != 0:
				wid = OBSIDIAN
			sb(q.x, y, q.y, wid)
		torch_i += 1
		if torch_i % 11 == 0:
			sb(q.x, 2, q.y, GLOW)

	for i in ROOMS.size():
		var r: Array = ROOMS[i]
		var rc: Vector2i = r[0]
		var rs: Vector2i = r[1]
		lights.append(Vector3(c.x + rc.x + 0.5, 3.0, c.y + rc.y + 0.5))
		for s in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			var p: = rc + Vector2i(s.x * (rs.x / 2 - 3), s.y * (rs.y / 2 - 3))
			fill(p.x, 0, p.y, p.x, 3, p.y, th.pillar)
			sb(p.x, 4, p.y, GLOW)
		_dungeon_props(rc, rs, i == ROOMS.size() - 1)

	var br: Vector2i = (ROOMS[ROOMS.size() - 1] as Array)[0]
	for x in range(-4, 5):
		for z in range(-4, 5):
			if Vector2(x, z).length() < 4.5:
				decal(br.x + x, br.y - 3 + z, th.floor2)


func _dungeon_props(rc: Vector2i, rs: Vector2i, boss: bool) -> void:
	var n: = 4 if not boss else 6
	for k in n:
		var x: = rc.x + rng.randi_range(- rs.x / 2 + 2, rs.x / 2 - 3)
		var z: = rc.y + rng.randi_range(- rs.y / 2 + 2, rs.y / 2 - 3)
		if absi(x - rc.x) < 4 and absi(z - rc.y) < 4:
			continue
		match area:
			"verdant_d":
				if rng.randf() < 0.5:
					plant(x, z, T.GLOW_SHROOM)
					plant(x + 1, z, T.FERN)
				else:
					sb(x, 0, z, MOSSY)
					plant(x + 1, z + 1, T.VINE)
			"desert_d":
				if rng.randf() < 0.5:
					fill(x, 0, z, x + 1, 0, z + 2, CARVED)
					sb(x, 1, z, GOLD_TILE)
				else:
					sb(x, 0, z, BARREL)
			"frost_d":
				var hh: = 1 + rng.randi() % 3
				for y in hh:
					sb(x, y, z, CRYSTAL if y == hh - 1 else PACKED_ICE)
			"ember_d":
				if rng.randf() < 0.6:
					for dx in range(0, 2):
						for dz in range(0, 2):
							decal(x + dx, z + dz, MAGMA)
							block_nav(x + dx, z + dz)
				else:
					fill(x, 0, z, x, 1 + rng.randi() % 2, z, OBSIDIAN)
