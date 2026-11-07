class_name PixelTex
extends RefCounted



const TILE: = 16
const GRID: = 12

enum {
	GRASS_TOP, GRASS_SIDE, DIRT, STONE, COBBLE, STONE_BRICK, PLANKS, LOG_SIDE,
	LOG_TOP, LEAVES, LEAVES_AUTUMN, PATH, GRAVEL, WATER, PLASTER, ROOF_RED,
	ROOF_ORANGE, ROOF_BROWN, GLASS, FARMLAND, WOOL_RED, WOOL_WHITE, WOOL_YELLOW, WOOL_GREEN,
	WOOL_BLUE, HAY_TOP, HAY_SIDE, GOLD, TIMBER, DOOR, WHEAT, FLOWER,
	TALL_GRASS, CABBAGE, GLOW, PINE_LEAVES, IRON, SAND, PLAZA, DOOR_TOP,
	FLOWER_RED, CARROT, DARK_PLANKS, BOOKSHELF, BARREL_SIDE, BARREL_TOP, RUG_RED, RUG_GREEN,
	SLATE, VOID, STONE_TILE, BANNER,

	SNOW, SNOW_SIDE, ICE, PACKED_ICE, SANDSTONE, SANDSTONE_CARVED, BASALT, MAGMA,
	ASH, OBSIDIAN, MOSSY_STONE, MOSSY_BRICK, JUNGLE_LEAVES, CACTUS_SIDE, CACTUS_TOP, JADE,
	BONE, CHERRY_LEAVES, RED_SAND, DEAD_BUSH, FERN, FROST_GRASS, GLOW_SHROOM, FIRE_FLOWER,
	VINE, DARK_GRASS, GOLD_TILE, CRYSTAL_BLUE,
}

static var _atlas: ImageTexture
static var _solid_mat: ShaderMaterial
static var _plant_mat: ShaderMaterial
static var _seed: = 1



static func h(x: int, y: int, s: int) -> float:
	var n: = sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 37.719) * 43758.5453
	return n - floor(n)


static func jit(c: Color, x: int, y: int, s: int, amt: = 0.06) -> Color:
	var d: = (h(x, y, s) - 0.5) * 2.0 * amt
	return Color(clampf(c.r + d, 0, 1), clampf(c.g + d, 0, 1), clampf(c.b + d, 0, 1), c.a)



static func atlas() -> ImageTexture:
	if _atlas:
		return _atlas
	var img: = Image.create(TILE * GRID, TILE * GRID, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1, 1))
	for t in GRID * GRID:
		var ox: = (t % GRID) * TILE
		var oy: = (t / GRID) * TILE
		for y in TILE:
			for x in TILE:
				img.set_pixel(ox + x, oy + y, _paint(t, x, y))
	_atlas = ImageTexture.create_from_image(img)
	return _atlas


static func tile_coord(t: int) -> Vector2:
	return Vector2(t % GRID, t / GRID)


static func _cobble(x: int, y: int, s: int, base: Color) -> Color:

	var best: = 99.0
	var second: = 99.0
	var cell: = 0
	for i in 7:
		var cx: = h(i, 1, s) * 16.0
		var cy: = h(i, 2, s) * 16.0
		for ox in [-16.0, 0.0, 16.0]:
			for oy in [-16.0, 0.0, 16.0]:
				var d: = Vector2(x + 0.5 - cx - ox, y + 0.5 - cy - oy).length()
				if d < best:
					second = best
					best = d
					cell = i
				elif d < second:
					second = d
	if second - best < 1.1:
		return base.darkened(0.42)
	var c: = base.darkened(h(cell, 9, s) * 0.25)
	if best < 2.0:
		c = c.lightened(0.08)
	return jit(c, x, y, s, 0.04)


static func _paint(t: int, x: int, y: int) -> Color:
	match t:
		GRASS_TOP:
			var c: = Color(0.33, 0.55, 0.22)
			if h(x, y, 3) > 0.86:
				c = Color(0.27, 0.46, 0.18)
			elif h(x, y, 4) > 0.9:
				c = Color(0.4, 0.62, 0.27)
			return jit(c, x, y, 1, 0.04)
		GRASS_SIDE:
			var depth: = 3 + int(h(x, 0, 5) * 3.0)
			if y < depth:
				return jit(Color(0.33, 0.55, 0.22), x, y, 2, 0.05)
			return _paint(DIRT, x, y)
		DIRT:
			var c: = Color(0.5, 0.36, 0.24)
			if h(x, y, 6) > 0.82:
				c = Color(0.4, 0.28, 0.18)
			elif h(x, y, 7) > 0.9:
				c = Color(0.6, 0.45, 0.32)
			return jit(c, x, y, 8, 0.03)
		STONE:
			var c: = Color(0.53, 0.53, 0.54)
			if h(x / 2, y / 2, 9) > 0.8:
				c = Color(0.45, 0.45, 0.47)
			return jit(c, x, y, 10, 0.04)
		COBBLE:
			return _cobble(x, y, 11, Color(0.58, 0.58, 0.58))
		STONE_BRICK:
			var row: = y / 4
			var off: = 4 if row % 2 == 1 else 0
			if y % 4 == 3 or (x + off) % 8 == 7:
				return Color(0.36, 0.36, 0.37)
			var c: = Color(0.62, 0.61, 0.6).darkened(h((x + off) / 8, row, 12) * 0.12)
			return jit(c, x, y, 13, 0.035)
		PLANKS:
			var row: = y / 4
			var off: = 5 if row % 2 == 1 else 0
			if y % 4 == 3 or (x + off) % 16 == 0:
				return Color(0.42, 0.29, 0.16)
			var c: = Color(0.7, 0.53, 0.32).darkened(h(row, 0, 14) * 0.1)
			if h(x, y, 15) > 0.85:
				c = c.darkened(0.12)
			return c
		LOG_SIDE:
			var c: = Color(0.42, 0.3, 0.19)
			if x % 4 == 0 or h(x, y / 3, 16) > 0.8:
				c = Color(0.32, 0.22, 0.13)
			return jit(c, x, y, 17, 0.03)
		LOG_TOP:
			var d: = Vector2(x - 7.5, y - 7.5).length()
			if d > 6.8:
				return Color(0.36, 0.25, 0.15)
			var ring: = int(d) % 2
			return jit(Color(0.72, 0.56, 0.35) if ring == 0 else Color(0.62, 0.46, 0.28), x, y, 18, 0.03)
		LEAVES:
			var c: = Color(0.25, 0.5, 0.17)
			var r: = h(x, y, 19)
			if r > 0.85:
				c = Color(0.15, 0.33, 0.1)
			elif r < 0.15:
				c = Color(0.33, 0.6, 0.22)
			return c
		LEAVES_AUTUMN:
			var c: = Color(0.86, 0.55, 0.15)
			var r: = h(x, y, 20)
			if r > 0.85:
				c = Color(0.6, 0.3, 0.08)
			elif r < 0.2:
				c = Color(0.95, 0.75, 0.25)
			return c
		PINE_LEAVES:
			var c: = Color(0.16, 0.36, 0.22)
			var r: = h(x, y, 21)
			if r > 0.8:
				c = Color(0.1, 0.24, 0.15)
			elif r < 0.15:
				c = Color(0.22, 0.45, 0.28)
			return c
		PATH:
			var c: = Color(0.68, 0.56, 0.36)
			if h(x, y, 22) > 0.85:
				c = Color(0.58, 0.46, 0.29)
			return jit(c, x, y, 23, 0.035)
		PLAZA:
			if x % 8 == 0 or y % 8 == 0:
				return Color(0.55, 0.52, 0.46)
			var c: = Color(0.78, 0.74, 0.64).darkened(h(x / 8, y / 8, 24) * 0.1)
			return jit(c, x, y, 25, 0.025)
		GRAVEL:
			var r: = h(x, y, 26)
			var c: = Color(0.55, 0.53, 0.5)
			if r > 0.7:
				c = Color(0.42, 0.4, 0.38)
			elif r < 0.25:
				c = Color(0.66, 0.63, 0.6)
			return c
		WATER:
			var c: = Color(0.22, 0.45, 0.85)
			if (x + y * 2 + int(h(y, 0, 27) * 6.0)) % 9 == 0:
				c = Color(0.4, 0.62, 0.95)
			return jit(c, x, y, 28, 0.025)
		PLASTER:
			var c: = Color(0.9, 0.87, 0.79)
			if h(x, y, 29) > 0.9:
				c = Color(0.82, 0.78, 0.7)
			return jit(c, x, y, 30, 0.015)
		ROOF_RED, ROOF_ORANGE, ROOF_BROWN:
			var base: = Color(0.72, 0.24, 0.17)
			if t == ROOF_ORANGE:
				base = Color(0.85, 0.47, 0.2)
			elif t == ROOF_BROWN:
				base = Color(0.5, 0.33, 0.22)
			var row: = y / 4
			var off: = 4 if row % 2 == 1 else 0
			if y % 4 == 3:
				return base.darkened(0.35)
			if (x + off) % 8 == 0:
				return base.darkened(0.22)
			return jit(base.lightened(0.06 * (2 - y % 4)), x, y, 31, 0.03)
		GLASS:
			if x == 0 or y == 0 or x == 15 or y == 15 or x == 7 or y == 7:
				return Color(0.42, 0.3, 0.19)
			if x == y or x == y + 1:
				return Color(0.62, 0.75, 0.85)
			return Color(0.2, 0.3, 0.4)
		FARMLAND:
			var c: = Color(0.36, 0.24, 0.15)
			if y % 4 == 0:
				c = Color(0.26, 0.17, 0.1)
			return jit(c, x, y, 32, 0.03)
		WOOL_RED, WOOL_WHITE, WOOL_YELLOW, WOOL_GREEN, WOOL_BLUE:
			var cols: = { WOOL_RED: Color(0.75, 0.18, 0.16), WOOL_WHITE: Color(0.92, 0.9, 0.86),
				WOOL_YELLOW: Color(0.95, 0.75, 0.2), WOOL_GREEN: Color(0.3, 0.6, 0.3), WOOL_BLUE: Color(0.25, 0.42, 0.75) }
			var c: Color = cols[t]
			if (x + y) % 3 == 0:
				c = c.darkened(0.08)
			return jit(c, x, y, 33, 0.03)
		HAY_TOP:
			return jit(Color(0.85, 0.7, 0.3) if (x + y) % 2 == 0 else Color(0.75, 0.6, 0.22), x, y, 34, 0.04)
		HAY_SIDE:
			if y == 4 or y == 11:
				return Color(0.55, 0.25, 0.12)
			return jit(Color(0.85, 0.7, 0.3) if x % 2 == 0 else Color(0.76, 0.6, 0.24), x, y, 35, 0.04)
		GOLD:
			var c: = Color(0.95, 0.78, 0.25)
			if x == 0 or y == 0:
				c = Color(1.0, 0.92, 0.55)
			elif x == 15 or y == 15:
				c = Color(0.75, 0.55, 0.15)
			return jit(c, x, y, 36, 0.04)
		TIMBER:
			var c: = Color(0.32, 0.21, 0.13)
			if h(x, y / 4, 37) > 0.8:
				c = Color(0.25, 0.16, 0.1)
			return jit(c, x, y, 38, 0.025)
		DOOR, DOOR_TOP:
			if x == 0 or x == 15 or (t == DOOR_TOP and y == 0):
				return Color(0.3, 0.2, 0.12)
			if t == DOOR and x == 12 and y == 4:
				return Color(0.9, 0.75, 0.3)
			if t == DOOR_TOP and y > 3 and y < 11 and x > 3 and x < 12:
				return Color(0.2, 0.25, 0.32) if not (x == 7 or x == 8 or y == 7) else Color(0.3, 0.2, 0.12)
			var c: = Color(0.55, 0.38, 0.22)
			if x % 5 == 0:
				c = Color(0.45, 0.3, 0.17)
			return jit(c, x, y, 39, 0.03)
		GLOW:
			if x == 0 or y == 0 or x == 15 or y == 15:
				return Color(0.25, 0.22, 0.2)
			var d: = Vector2(x - 7.5, y - 7.5).length()
			return Color(1.0, 0.9 - d * 0.03, 0.55 - d * 0.04)
		IRON:
			var c: = Color(0.32, 0.33, 0.36)
			if (x == 2 or x == 13) and (y == 2 or y == 13):
				c = Color(0.55, 0.56, 0.6)
			return jit(c, x, y, 40, 0.03)
		SAND:
			var c: = Color(0.86, 0.78, 0.56)
			if h(x, y, 40) > 0.9:
				c = Color(0.78, 0.68, 0.46)
			return jit(c, x, y, 41, 0.04)
		WHEAT:
			if x % 3 == 1 and y > 3:
				return Color(0.55, 0.62, 0.22) if y > 9 else Color(0.85, 0.72, 0.3)
			if x % 3 == 1 and y <= 3 and y > 0:
				return Color(0.92, 0.8, 0.4)
			return Color(0, 0, 0, 0)
		FLOWER, FLOWER_RED:
			var petal: = Color(0.98, 0.85, 0.2) if t == FLOWER else Color(0.9, 0.2, 0.2)
			var d: = Vector2(x - 7.5, y - 5.5).length()
			if d < 2.6:
				return Color(0.4, 0.25, 0.1) if d < 1.0 else petal
			if (x == 7 or x == 8) and y > 7:
				return Color(0.25, 0.55, 0.2)
			if y == 11 and (x == 5 or x == 6 or x == 9 or x == 10):
				return Color(0.3, 0.62, 0.22)
			return Color(0, 0, 0, 0)
		TALL_GRASS:
			var bh: = 6 + int(h(x, 0, 42) * 9.0)
			if x % 2 == 0 and 15 - y < bh:
				return jit(Color(0.35, 0.6, 0.22), x, y, 43, 0.06)
			return Color(0, 0, 0, 0)
		CABBAGE, CARROT:
			if t == CARROT:
				if x % 4 == 1 and y > 6:
					return Color(0.3, 0.6, 0.22)
				if x % 4 == 1 and y > 12:
					return Color(0.95, 0.55, 0.15)
				return Color(0, 0, 0, 0)
			var d: = Vector2(x - 7.5, y - 11.0).length()
			if d < 5.0:
				return jit(Color(0.42, 0.7, 0.3) if d < 2.5 else Color(0.3, 0.55, 0.2), x, y, 44, 0.05)
			return Color(0, 0, 0, 0)
		DARK_PLANKS:
			var c: = Color(0.36, 0.23, 0.14)
			if y % 4 == 0:
				c = Color(0.24, 0.15, 0.09)
			elif (x + (y / 4) * 5) % 8 == 0:
				c = Color(0.27, 0.17, 0.1)
			return jit(c, x, y, 50, 0.04)
		BOOKSHELF:
			if y == 0 or y == 7 or y == 8 or y == 15 or x == 0 or x == 15:
				return Color(0.42, 0.28, 0.16)
			var book: = int(h(x / 2, y / 8, 51) * 6.0)
			var cols: = [Color(0.62, 0.18, 0.16), Color(0.2, 0.36, 0.6), Color(0.25, 0.48, 0.25), Color(0.75, 0.6, 0.25),
				Color(0.45, 0.25, 0.5), Color(0.8, 0.75, 0.62)]
			var c: Color = cols[book]
			if x % 2 == 1 and h(x, y / 8, 52) > 0.7:
				c = c.darkened(0.3)
			if (y == 1 or y == 9) and h(x, y, 53) > 0.6:
				return Color(0.2, 0.13, 0.08)
			return jit(c, x, y, 54, 0.04)
		BARREL_SIDE:
			if y == 2 or y == 3 or y == 12 or y == 13:
				return Color(0.3, 0.3, 0.32) if y % 2 == 0 else Color(0.42, 0.42, 0.45)
			var c: = Color(0.55, 0.36, 0.2)
			if x % 4 == 0:
				c = Color(0.38, 0.24, 0.13)
			return jit(c, x, y, 55, 0.04)
		BARREL_TOP:
			var d: = Vector2(x - 7.5, y - 7.5).length()
			if d > 7.0:
				return Color(0.3, 0.3, 0.32)
			if d > 6.0:
				return Color(0.4, 0.26, 0.15)
			return jit(Color(0.58, 0.4, 0.23) if (x + 1) % 5 else Color(0.45, 0.3, 0.17), x, y, 56, 0.03)
		RUG_RED, RUG_GREEN:
			var base: = Color(0.55, 0.13, 0.12) if t == RUG_RED else Color(0.2, 0.36, 0.26)
			var trim: = Color(0.86, 0.68, 0.3)
			var e: = mini(mini(x, 15 - x), mini(y, 15 - y))
			if e == 1:
				return trim
			var dd: = absi(x - 7) + absi(y - 7)
			if dd == 4 or dd == 5:
				return trim.darkened(0.15)
			if (x + y) % 4 == 0 and e > 2:
				return base.lightened(0.08)
			return jit(base, x, y, 57, 0.04)
		SLATE:
			var c: = Color(0.36, 0.4, 0.48)
			if y % 4 == 3:
				c = Color(0.24, 0.27, 0.33)
			elif (x + (y / 4) * 3) % 6 == 0:
				c = Color(0.28, 0.31, 0.38)
			return jit(c, x, y, 58, 0.05)
		VOID:
			return jit(Color(0.06, 0.055, 0.07), x, y, 59, 0.02)
		STONE_TILE:
			var c: = Color(0.62, 0.6, 0.56) if ((x / 8) + (y / 8)) % 2 == 0 else Color(0.5, 0.48, 0.45)
			if x % 8 == 0 or y % 8 == 0:
				c = Color(0.35, 0.33, 0.31)
			return jit(c, x, y, 60, 0.03)
		BANNER:
			var c: = Color(0.16, 0.38, 0.28)
			if x == 0 or x == 15:
				return Color(0.8, 0.62, 0.25)
			var dd: = absi(x - 7) + absi(y - 7)
			if dd <= 4:
				return Color(0.95, 0.78, 0.32) if dd != 2 else Color(0.7, 0.5, 0.18)
			return jit(c, x, y, 61, 0.04)
		SNOW:
			var c: = Color(0.7, 0.74, 0.8)
			if h(x, y, 70) > 0.8:
				c = Color(0.6, 0.65, 0.75)
			elif h(x, y, 71) > 0.92:
				c = Color(0.85, 0.88, 0.92)
			return jit(c, x, y, 72, 0.02)
		SNOW_SIDE:
			var depth: = 3 + int(h(x, 0, 73) * 3.0)
			if y < depth:
				return _paint(SNOW, x, y)
			return _paint(DIRT, x, y).lerp(Color(0.55, 0.5, 0.5), 0.2)
		ICE:
			var c: = Color(0.62, 0.82, 0.98)
			if (x + y) % 11 == 0 or (x - y + 16) % 13 == 0:
				c = Color(0.85, 0.95, 1.0)
			elif h(x / 3, y / 3, 74) > 0.75:
				c = Color(0.52, 0.74, 0.94)
			return jit(c, x, y, 75, 0.02)
		PACKED_ICE:
			var c: = Color(0.55, 0.72, 0.92)
			if h(x, y, 76) > 0.85:
				c = Color(0.72, 0.85, 0.98)
			if y % 5 == 4:
				c = c.darkened(0.08)
			return jit(c, x, y, 77, 0.03)
		SANDSTONE:
			var c: = Color(0.86, 0.74, 0.5)
			if y % 5 == 4:
				c = Color(0.76, 0.62, 0.4)
			elif h(x, y, 78) > 0.88:
				c = Color(0.92, 0.82, 0.6)
			return jit(c, x, y, 79, 0.03)
		SANDSTONE_CARVED:
			var c: = Color(0.84, 0.71, 0.47)
			if x == 0 or x == 15 or y == 0 or y == 15:
				return Color(0.66, 0.52, 0.32)
			var d: = absi(x - 7) + absi(y - 7)
			if d == 4 or (d < 2):
				return Color(0.62, 0.42, 0.22)
			if (x == 3 or x == 12) and y > 2 and y < 13:
				return Color(0.7, 0.56, 0.36)
			return jit(c, x, y, 80, 0.03)
		BASALT:
			var c: = Color(0.2, 0.19, 0.21)
			if x % 5 == 0:
				c = Color(0.13, 0.12, 0.14)
			elif h(x, y, 81) > 0.85:
				c = Color(0.28, 0.27, 0.3)
			return jit(c, x, y, 82, 0.03)
		MAGMA:
			var v: = sin(float(x) * 0.8 + float(y) * 0.5) + sin(float(y) * 1.1 - float(x) * 0.3) + h(x / 2, y / 2, 83)
			if v > 1.2:
				return Color(1.0, 0.86, 0.3)
			if v > 0.2:
				return Color(1.0, 0.5, 0.1)
			if v > -0.6:
				return Color(0.85, 0.22, 0.05)
			return Color(0.35, 0.08, 0.04)
		ASH:
			var c: = Color(0.34, 0.32, 0.32)
			if h(x, y, 84) > 0.82:
				c = Color(0.26, 0.24, 0.25)
			elif h(x, y, 85) > 0.985:
				c = Color(0.85, 0.35, 0.15)
			return jit(c, x, y, 86, 0.03)
		OBSIDIAN:
			var c: = Color(0.1, 0.07, 0.14)
			if h(x, y, 87) > 0.9:
				c = Color(0.35, 0.22, 0.5)
			elif (x + y * 2) % 9 == 0:
				c = Color(0.16, 0.1, 0.22)
			return jit(c, x, y, 88, 0.02)
		MOSSY_STONE:
			var st: = _paint(STONE, x, y)
			var m: = h(x / 2, y / 2, 89) + (0.35 if y < 6 else 0.0)
			if m > 0.75:
				return jit(Color(0.3, 0.5, 0.22), x, y, 90, 0.05)
			return st
		MOSSY_BRICK:
			var br: = _paint(STONE_BRICK, x, y)
			if h(x / 2, y / 3, 91) > 0.62:
				return jit(Color(0.32, 0.52, 0.24), x, y, 92, 0.05)
			return br
		JUNGLE_LEAVES:
			var c: = Color(0.16, 0.48, 0.2)
			var r: = h(x, y, 93)
			if r > 0.82:
				c = Color(0.08, 0.3, 0.12)
			elif r < 0.12:
				c = Color(0.3, 0.66, 0.26)
			elif h(x / 4, y / 4, 94) > 0.85:
				c = Color(0.9, 0.35, 0.55)
			return c
		CACTUS_SIDE:
			var c: = Color(0.3, 0.6, 0.25)
			if x % 4 == 0:
				c = Color(0.2, 0.45, 0.18)
			if x % 4 == 2 and y % 4 == 1:
				return Color(0.95, 0.92, 0.75)
			return jit(c, x, y, 95, 0.03)
		CACTUS_TOP:
			var d: = Vector2(x - 7.5, y - 7.5).length()
			if d < 2.5:
				return Color(0.95, 0.5, 0.65)
			return jit(Color(0.34, 0.64, 0.28) if d < 6 else Color(0.22, 0.48, 0.2), x, y, 96, 0.03)
		JADE:
			var c: = Color(0.25, 0.75, 0.55)
			if (x + y) % 7 == 0:
				c = Color(0.55, 0.95, 0.78)
			elif h(x / 2, y / 2, 97) > 0.7:
				c = Color(0.18, 0.58, 0.42)
			return jit(c, x, y, 98, 0.02)
		BONE:
			var c: = Color(0.9, 0.87, 0.78)
			if y % 6 == 5 or (x % 8 == 3 and y % 6 > 1):
				c = Color(0.75, 0.71, 0.62)
			return jit(c, x, y, 99, 0.03)
		CHERRY_LEAVES:
			var c: = Color(0.97, 0.7, 0.8)
			var r: = h(x, y, 100)
			if r > 0.82:
				c = Color(0.88, 0.52, 0.66)
			elif r < 0.14:
				c = Color(1.0, 0.86, 0.9)
			return c
		RED_SAND:
			return jit(Color(0.82, 0.55, 0.36) if h(x, y, 101) < 0.86 else Color(0.7, 0.44, 0.28), x, y, 102, 0.04)
		DEAD_BUSH:
			var cx: = 7.5 + sin(float(y) * 0.9) * 2.5
			if y > 4 and absf(x - cx) < 0.8:
				return Color(0.55, 0.38, 0.2)
			if y > 2 and y < 11 and (absi(x - y) == 2 or absi(15 - x - y) == 2):
				return Color(0.6, 0.42, 0.22)
			return Color(0, 0, 0, 0)
		FERN:
			var cx2: = 7.5
			var t2: = absf(x - cx2)
			if y > 3 and t2 <= (15 - y) * 0.55 and (x + y) % 2 == 0:
				return jit(Color(0.2, 0.55, 0.22), x, y, 103, 0.06)
			return Color(0, 0, 0, 0)
		FROST_GRASS:
			var bh: = 4 + int(h(x, 0, 104) * 7.0)
			var lean: = int((15 - y) * (h(x, 1, 104) - 0.5) * 0.5)
			if (x - lean) % 3 == 0 and 15 - y < bh and h(x, 2, 104) > 0.25:
				return Color(0.88, 0.94, 1.0) if 15 - y > bh - 2 else Color(0.55, 0.7, 0.68)
			return Color(0, 0, 0, 0)
		GLOW_SHROOM:
			if y >= 6 and y <= 9 and absf(x - 7.5) <= 5.5 - (9 - y) * 0.8:
				return Color(0.4, 1.0, 0.85) if (x + y) % 4 else Color(0.85, 1.0, 0.95)
			if y > 9 and x >= 7 and x <= 8:
				return Color(0.8, 0.85, 0.75)
			return Color(0, 0, 0, 0)
		FIRE_FLOWER:
			var d: = Vector2(x - 7.5, y - 6.0).length()
			if d < 2.0:
				return Color(1.0, 0.95, 0.4)
			if d < 4.2 and (x + y) % 2 == 0:
				return Color(1.0, 0.4, 0.1)
			if y > 8 and x >= 7 and x <= 8:
				return Color(0.25, 0.2, 0.15)
			return Color(0, 0, 0, 0)
		VINE:
			var vx: = 4 + int(h(0, y / 3, 105) * 8.0)
			if absi(x - vx) <= 1 or (h(x, y, 106) > 0.8 and absi(x - vx) <= 3):
				return jit(Color(0.22, 0.5, 0.2), x, y, 107, 0.06)
			return Color(0, 0, 0, 0)
		DARK_GRASS:
			var c: = Color(0.2, 0.4, 0.16)
			if h(x, y, 108) > 0.84:
				c = Color(0.14, 0.3, 0.11)
			elif h(x, y, 109) > 0.92:
				c = Color(0.3, 0.5, 0.2)
			return jit(c, x, y, 110, 0.04)
		GOLD_TILE:
			var c: = Color(0.92, 0.72, 0.25)
			if x % 8 == 0 or y % 8 == 0:
				c = Color(0.6, 0.42, 0.12)
			elif (x % 8) + (y % 8) < 4:
				c = Color(1.0, 0.9, 0.5)
			return jit(c, x, y, 111, 0.02)
		CRYSTAL_BLUE:
			var c: = Color(0.4, 0.7, 1.0)
			var d: = absi(x - 7) + absi(y - 7)
			if d % 5 == 0:
				c = Color(0.85, 0.95, 1.0)
			elif d % 5 == 3:
				c = Color(0.25, 0.45, 0.85)
			return c
	return Color(1, 0, 1)



const SHADER_CODE = "\nshader_type spatial;\nrender_mode %s, diffuse_lambert, specular_disabled;\nuniform sampler2D atlas : source_color, filter_nearest, repeat_disable;\nuniform float grid = 8.0;\nuniform vec2 masonry_tile;\nuniform vec2 moss_masonry_tile;\nuniform float hd = 1.0;\n// see-through: blocks between the camera and the player are dithered away\nuniform vec3 player_pos = vec3(0.0, -1000.0, 0.0);\nuniform vec3 cam_pos = vec3(0.0, 0.0, 0.0);\nuniform float xray_radius = 2.6;\n// animation / time of day\nuniform vec2 water_tile = vec2(-1.0);\nuniform vec2 glow_tile = vec2(-1.0);\nuniform vec2 glass_tile = vec2(-1.0);\nuniform float night = 0.0;\nuniform float wind = 1.0;\nuniform vec2 lava_tile = vec2(-1.0);\nuniform vec2 leaf_tile = vec2(-1.0);\nuniform vec2 tgrass_tile = vec2(-1.0);\nuniform vec2 grass_tile = vec2(-1.0);\nuniform vec2 grass_side_tile = vec2(-1.0);\n// seasons only colour the home region (x0, z0, x1, z1)\nuniform vec4 season_rect = vec4(-210.0, -210.0, 210.0, 210.0);\nuniform vec3 leaf_tint = vec3(1.0);\nuniform vec3 grass_tint = vec3(1.0);\nuniform float snow = 0.0;\n// walkable ground is drawn as 0.5 m pixels\nuniform vec2 ground_tiles[24];\nuniform float ground_kind[24];\nuniform int ground_count = 0;\nuniform float ground_detail_on = 1.0;\nuniform float ground_pixel = 0.5;\nuniform vec3 sun_dir = vec3(-0.45, 0.78, -0.43);\nvarying vec3 wpos;\nvarying float wup;\nvarying vec3 wnrm;\n\n// ---- noise for water / lava\nfloat n_hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123); }\nvec2 n_hash2(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }\nfloat n_value(vec2 p) {\n\tvec2 i = floor(p);\n\tvec2 f = fract(p);\n\tvec2 u = f * f * (3.0 - 2.0 * f);\n\treturn mix(mix(n_hash(i), n_hash(i + vec2(1.0, 0.0)), u.x), mix(n_hash(i + vec2(0.0, 1.0)), n_hash(i + vec2(1.0, 1.0)), u.x), u.y);\n}\nfloat n_fbm(vec2 p) {\n\tfloat v = 0.0;\n\tfloat a = 0.5;\n\tmat2 r = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));\n\tfor (int i = 0; i < 4; i++) {\n\t\tv += a * n_value(p);\n\t\tp = r * p * 2.03 + vec2(1.7, 9.2);\n\t\ta *= 0.5;\n\t}\n\treturn v;\n}\n// distance to the nearest / second nearest moving cell centre (crust plates)\nvec2 n_voronoi(vec2 p, float t) {\n\tvec2 i = floor(p);\n\tvec2 f = fract(p);\n\tfloat d1 = 8.0;\n\tfloat d2 = 8.0;\n\tfor (int y = -1; y <= 1; y++) {\n\t\tfor (int x = -1; x <= 1; x++) {\n\t\t\tvec2 g = vec2(float(x), float(y));\n\t\t\tvec2 o = n_hash2(i + g);\n\t\t\to = 0.5 + 0.38 * sin(t + 6.2831 * o);\n\t\t\tfloat d = length(g + o - f);\n\t\t\tif (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }\n\t\t}\n\t}\n\treturn vec2(d1, d2);\n}\n// flowing surface coordinates: flat faces flow across, walls (falls) flow down\nvec2 flow_uv(vec3 p, vec3 nrm) {\n\tif (abs(nrm.y) > 0.5) { return p.xz; }\n\treturn vec2(p.x + p.z, p.y);\n}\nvec3 water_color(vec3 p, vec3 nrm, vec3 view_w, float t) {\n\tbool fall = abs(nrm.y) < 0.5;\n\tvec2 uv = flow_uv(p, nrm);\n\tvec2 drift = fall ? vec2(0.0, t * 1.6) : vec2(t * 0.11, t * 0.07);\n\t// two wave layers crossing each other\n\tfloat w1 = n_fbm(uv * 0.55 + drift);\n\tfloat w2 = n_fbm(uv * 1.35 - drift.yx * 1.3 + vec2(3.1, 7.7));\n\tfloat h = w1 * 0.6 + w2 * 0.4;\n\tfloat e = 0.08;\n\tfloat hx = n_fbm((uv + vec2(e, 0.0)) * 0.55 + drift) * 0.6 + n_fbm((uv + vec2(e, 0.0)) * 1.35 - drift.yx * 1.3 + vec2(3.1, 7.7)) * 0.4;\n\tfloat hz = n_fbm((uv + vec2(0.0, e)) * 0.55 + drift) * 0.6 + n_fbm((uv + vec2(0.0, e)) * 1.35 - drift.yx * 1.3 + vec2(3.1, 7.7)) * 0.4;\n\tvec3 n = normalize(vec3((h - hx) * 3.2, 1.0, (h - hz) * 3.2));\n\tvec3 deep = vec3(0.025, 0.13, 0.22);\n\tvec3 shallow = vec3(0.07, 0.3, 0.42);\n\tvec3 col = mix(deep, shallow, smoothstep(0.3, 0.75, h));\n\t// light ripples (sun caustics) moving over the surface\n\tfloat c1 = abs(sin((n_fbm(uv * 1.9 + drift * 1.7) * 6.2831) * 2.0));\n\tfloat caus = pow(1.0 - c1, 10.0);\n\tcol += vec3(0.5, 0.75, 0.8) * caus * 0.14;\n\t// sky reflection grows at grazing angles\n\tfloat fres = pow(1.0 - clamp(dot(n, view_w), 0.0, 1.0), 3.0);\n\tcol = mix(col, vec3(0.55, 0.7, 0.82), fres * 0.4);\n\t// sun glints\n\tvec3 r = reflect(-normalize(sun_dir), n);\n\tfloat glint = pow(max(dot(r, view_w), 0.0), 90.0);\n\tcol += vec3(1.0, 0.97, 0.88) * glint * 1.4 * (1.0 - night);\n\tif (fall) {\n\t\t// white streaks in a waterfall\n\t\tfloat streak = smoothstep(0.62, 0.9, n_fbm(vec2(uv.x * 4.0, uv.y * 0.6 + t * 2.4)));\n\t\tcol = mix(col, vec3(0.85, 0.93, 1.0), streak * 0.6);\n\t}\n\treturn col;\n}\nvec3 lava_color(vec3 p, vec3 nrm, float t, out float heat) {\n\tbool fall = abs(nrm.y) < 0.5;\n\tvec2 uv = flow_uv(p, nrm);\n\tvec2 drift = fall ? vec2(0.0, t * 0.55) : vec2(t * 0.045, t * 0.03);\n\t// domain-warped flow so the molten rock slowly churns\n\tvec2 q = vec2(n_fbm(uv * 0.35 + drift), n_fbm(uv * 0.35 - drift + vec2(5.2, 1.3)));\n\tfloat f = n_fbm(uv * 0.7 + q * 2.2 + drift * 1.5);\n\t// cooling crust plates drifting on top, glowing seams between them\n\tvec2 v = n_voronoi(uv * 0.9 + q * 1.2 + drift * 2.0, t * 0.35);\n\tfloat seam = 1.0 - smoothstep(0.015, 0.11, v.y - v.x);\n\tfloat crust = smoothstep(0.34, 0.56, f) * (1.0 - seam);\n\t// molten rock between the plates: red to orange, cracks orange-yellow\n\theat = mix(0.55 + 0.35 * smoothstep(0.2, 0.45, 0.45 - f + 0.2), 0.0, crust) + seam * 0.55 * (1.0 - crust * 0.5);\n\theat *= 0.9 + 0.1 * sin(t * 2.1 + f * 8.0 + uv.x * 0.4);\n\tvec3 col = mix(vec3(0.62, 0.07, 0.01), vec3(1.0, 0.38, 0.04), smoothstep(0.45, 0.9, heat));\n\tcol = mix(col, vec3(1.0, 0.72, 0.22), smoothstep(0.95, 1.25, heat));\n\tvec3 rock = vec3(0.1, 0.05, 0.045) + vec3(0.1, 0.035, 0.0) * n_value(uv * 6.0);\n\tcol = mix(col, rock, crust);\n\treturn col;\n}\n\n// ---- ground surface detail (world space, seamless): grass blades, pebbles,\n// paving stones, sand ripples, snow sparkle, gravel, furrows, ice cracks.\nvec3 n_vor_id(vec2 p) {\n\tvec2 i = floor(p);\n\tvec2 f = fract(p);\n\tfloat d1 = 8.0;\n\tfloat d2 = 8.0;\n\tfloat id = 0.0;\n\tfor (int y = -1; y <= 1; y++) {\n\t\tfor (int x = -1; x <= 1; x++) {\n\t\t\tvec2 g = vec2(float(x), float(y));\n\t\t\tvec2 o = 0.15 + 0.7 * n_hash2(i + g);\n\t\t\tfloat d = length(g + o - f);\n\t\t\tif (d < d1) { d2 = d1; d1 = d; id = n_hash(i + g); } else if (d < d2) { d2 = d; }\n\t\t}\n\t}\n\treturn vec3(d1, d2, id);\n}\nvec3 ground_detail(vec3 base, float kind, vec2 p, vec3 view_w) {\n\tvec3 c = base;\n\tif (kind < 0.5) {\n\t\treturn c;\n\t} else if (kind < 1.5) {\n\t\t// grass: short slanted blades on a 6 cm grid, darker clumps, rare tiny flowers\n\t\tvec2 g = p * 16.0;\n\t\tvec2 cell = floor(g);\n\t\tfloat r = n_hash(cell);\n\t\tvec2 f = fract(g) - 0.5;\n\t\tfloat ang = 1.1 + n_value(p * 0.6) * 1.4 + (r - 0.5) * 0.9;\n\t\tvec2 dir = vec2(cos(ang), sin(ang));\n\t\tfloat along = dot(f, dir);\n\t\tfloat across = dot(f, vec2(-dir.y, dir.x));\n\t\tfloat blade = step(abs(across), 0.1) * step(abs(along), 0.44) * step(0.3, r);\n\t\tfloat tip = smoothstep(-0.44, 0.44, along);\n\t\tc *= mix(0.9, mix(0.82, 1.2, tip), blade);\n\t\tfloat clump = smoothstep(0.5, 0.78, n_value(p * 1.6 + vec2(3.0, 9.0)));\n\t\tc *= 1.0 - 0.16 * clump;\n\t\tvec2 fp = p * 4.0;\n\t\tfloat fl = n_hash(floor(fp) + vec2(17.0, 5.0));\n\t\tif (fl > 0.982 && length(fract(fp) - 0.5) < 0.1) {\n\t\t\tc = fl > 0.992 ? vec3(0.98, 0.96, 0.9) : vec3(1.0, 0.86, 0.35);\n\t\t}\n\t} else if (kind < 2.5) {\n\t\t// dirt / path: scattered pebbles with a dark rim, packed-earth speckle\n\t\tvec3 v = n_vor_id(p * 5.5);\n\t\tfloat peb = step(0.68, v.z) * (1.0 - smoothstep(0.2, 0.3, v.x));\n\t\tfloat rim = step(0.68, v.z) * smoothstep(0.17, 0.24, v.x) * (1.0 - smoothstep(0.26, 0.32, v.x));\n\t\tc *= 0.94 + 0.12 * n_hash(floor(p * 22.0));\n\t\tc = mix(c, c * vec3(1.18, 1.16, 1.12) + 0.03, peb);\n\t\tc *= 1.0 - 0.25 * rim;\n\t\tc *= 0.92 + 0.08 * smoothstep(0.3, 0.7, n_value(p * 3.0));\n\t} else if (kind < 3.5) {\n\t\t// sand: wind ripples bent by noise, fine grains\n\t\tfloat w = n_value(p * 0.5) * 5.0;\n\t\tfloat rip = sin((p.x * 0.8 + p.y * 0.6) * 11.0 + w);\n\t\tc *= 0.94 + 0.1 * smoothstep(-0.2, 1.0, rip);\n\t\tc *= 0.96 + 0.08 * n_hash(floor(p * 30.0));\n\t} else if (kind < 4.5) {\n\t\t// paving: irregular stones with mortar joints and a soft top-light bevel\n\t\tvec3 v = n_vor_id(p * 2.4);\n\t\tfloat joint = 1.0 - smoothstep(0.025, 0.07, v.y - v.x);\n\t\tfloat tint = 0.88 + 0.2 * v.z;\n\t\tc *= tint;\n\t\tc *= 0.95 + 0.07 * n_hash(floor(p * 26.0));\n\t\tc *= 1.0 + 0.08 * (1.0 - smoothstep(0.0, 0.35, v.x));\n\t\tc = mix(c, base * 0.66, joint);\n\t} else if (kind < 5.5) {\n\t\t// snow: soft drifts and glittering sparkles that catch the sun\n\t\tc *= 0.96 + 0.06 * n_value(p * 1.2);\n\t\tfloat sp = n_hash(floor(p * 36.0) + floor(view_w.xz * 3.0));\n\t\tif (sp > 0.994) { c += vec3(0.35, 0.38, 0.42) * (1.0 - night); }\n\t} else if (kind < 6.5) {\n\t\t// gravel / rough stone: dense small stones of mixed shades\n\t\tvec3 v = n_vor_id(p * 8.0);\n\t\tfloat edge = 1.0 - smoothstep(0.02, 0.1, v.y - v.x);\n\t\tc *= 0.82 + 0.3 * v.z;\n\t\tc *= 1.0 - 0.3 * edge;\n\t} else if (kind < 7.5) {\n\t\t// farmland: furrows\n\t\tfloat fur = sin(p.y * 6.2831 * 2.5);\n\t\tc *= 0.86 + 0.16 * smoothstep(-0.6, 0.6, fur);\n\t\tc *= 0.95 + 0.08 * n_hash(floor(p * 20.0));\n\t} else {\n\t\t// ice: pale cracks and a cold sheen\n\t\tvec3 v = n_vor_id(p * 1.4);\n\t\tfloat crack = 1.0 - smoothstep(0.0, 0.025, v.y - v.x);\n\t\tc = mix(c, vec3(0.92, 0.97, 1.0), crack * 0.6);\n\t\tfloat fres = pow(1.0 - clamp(view_w.y, 0.0, 1.0), 3.0);\n\t\tc += vec3(0.15, 0.2, 0.25) * fres;\n\t}\n\treturn c;\n}\n\nfloat bayer4(vec2 p) {\n\tint x = int(mod(p.x, 4.0));\n\tint y = int(mod(p.y, 4.0));\n\tint i = x + y * 4;\n\tint m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);\n\treturn (float(m[i]) + 0.5) / 16.0;\n}\n\n// ---- HD: each 16x16 tile pixel is drawn as 4x4 sub-pixels (64 per block side):\n// rounded shape corners, ink on colour edges and a fine grain instead of big specks.\nfloat hd_lum(vec3 c) { return dot(c, vec3(0.3, 0.59, 0.11)); }\nfloat hd_hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }\nvec4 hd_tap(vec2 tile, vec2 lp) {\n\treturn texture(atlas, (tile + (mod(lp, 16.0) + 0.5) / 16.0) / grid);\n}\nvec3 hd_pixel(vec2 tile, vec2 local, vec4 C) {\n\tvec2 tl = local * 16.0;\n\tvec2 lp = floor(tl);\n\tvec2 sub = min(floor(fract(tl) * 4.0), vec2(3.0));\n\tvec4 nN = hd_tap(tile, lp + vec2(0.0, -1.0));\n\tvec4 nS = hd_tap(tile, lp + vec2(0.0, 1.0));\n\tvec4 nW = hd_tap(tile, lp + vec2(-1.0, 0.0));\n\tvec4 nE = hd_tap(tile, lp + vec2(1.0, 0.0));\n\tvec3 col = C.rgb;\n\tfloat near = 0.05;\n\tfloat far = 0.13;\n\tfloat grain = 0.015;\n\tif (sub.x + sub.y <= 1.0 && distance(nW.rgb, nN.rgb) < near && distance(nW.rgb, C.rgb) > far && nW.a > 0.5) { col = nW.rgb; }\n\telse if ((3.0 - sub.x) + sub.y <= 1.0 && distance(nE.rgb, nN.rgb) < near && distance(nE.rgb, C.rgb) > far && nE.a > 0.5) { col = nE.rgb; }\n\telse if (sub.x + (3.0 - sub.y) <= 1.0 && distance(nW.rgb, nS.rgb) < near && distance(nW.rgb, C.rgb) > far && nW.a > 0.5) { col = nW.rgb; }\n\telse if ((3.0 - sub.x) + (3.0 - sub.y) <= 1.0 && distance(nE.rgb, nS.rgb) < near && distance(nE.rgb, C.rgb) > far && nE.a > 0.5) { col = nE.rgb; }\n\telse {\n\t\tfloat dmax = max(max(distance(nN.rgb, C.rgb), distance(nS.rgb, C.rgb)), max(distance(nW.rgb, C.rgb), distance(nE.rgb, C.rgb)));\n\t\tif (dmax < 0.1) {\n\t\t\tvec2 t = (sub + 0.5) / 4.0 - 0.5;\n\t\t\tvec3 lean = mix(mix(C.rgb, nW.rgb, max(-t.x, 0.0)), nE.rgb, max(t.x, 0.0));\n\t\t\tlean = mix(mix(lean, nN.rgb, max(-t.y, 0.0)), nS.rgb, max(t.y, 0.0));\n\t\t\tcol = mix(lean, (nN.rgb + nS.rgb + nW.rgb + nE.rgb) * 0.25, 0.25);\n\t\t\tgrain = dmax > 0.012 ? 0.045 : 0.015;\n\t\t}\n\t\tfloat l = hd_lum(C.rgb);\n\t\tfloat ink = 1.0;\n\t\tif (sub.x >= 3.0 && hd_lum(nE.rgb) - l > 0.07 && nE.a > 0.5) { ink = 0.84; }\n\t\tif (sub.x <= 0.0 && hd_lum(nW.rgb) - l > 0.07 && nW.a > 0.5) { ink = 0.84; }\n\t\tif (sub.y >= 3.0 && hd_lum(nS.rgb) - l > 0.07 && nS.a > 0.5) { ink = 0.84; }\n\t\tif (sub.y <= 0.0 && hd_lum(nN.rgb) - l > 0.07 && nN.a > 0.5) { ink = 0.84; }\n\t\tif (ink > 0.9 && sub.y <= 0.0 && l - hd_lum(nN.rgb) > 0.07) { ink = 1.07; }\n\t\tcol *= ink;\n\t}\n\treturn col * (1.0 + (hd_hash(lp * 4.0 + sub + tile * 64.0) - 0.5) * 2.0 * grain);\n}\n\nvoid vertex() {\n\twpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;\n\twnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);\n\twup = wnrm.y;\n\t%s\n}\n\nvoid fragment() {\n\tvec3 target = player_pos + vec3(0.0, 0.9, 0.0);\n\tvec3 d = target - cam_pos;\n\tfloat L = length(d);\n\tif (player_pos.y > -999.0 && L > 0.1 && wpos.y > player_pos.y + 0.08) {\n\t\tvec3 dir = d / L;\n\t\tvec3 rel = wpos - cam_pos;\n\t\tfloat t = dot(rel, dir);\n\t\tif (t > 0.0 && t < L - 0.6) {\n\t\t\tfloat dist = length(rel - dir * t);\n\t\t\tfloat r = xray_radius * (0.65 + 0.35 * t / L);\n\t\t\tfloat keep = smoothstep(r * 0.38, r, dist);\n\t\t\tif (keep < bayer4(FRAGCOORD.xy)) {\n\t\t\t\tdiscard;\n\t\t\t}\n\t\t}\n\t}\n\tvec2 local = fract(UV);\n\tbool is_water = distance(UV2, water_tile) < 0.01;\n\tbool is_lava = distance(UV2, lava_tile) < 0.01;\n\tif (is_water) {\n\t\tlocal = fract(UV + vec2(TIME * 0.12, TIME * 0.21));\n\t} else if (is_lava) {\n\t\tlocal = fract(UV + vec2(TIME * 0.03, TIME * 0.05));\n\t}\n\tvec4 c = texture(atlas, (UV2 + local) / grid);\n\tbool is_ground = false;\n\tfloat gkind = 0.0;\n\tif (wup > 0.7 && !is_water && !is_lava) {\n\t\tfor (int gi = 0; gi < 24; gi++) {\n\t\t\tif (gi >= ground_count) { break; }\n\t\t\tif (distance(UV2, ground_tiles[gi]) < 0.01) { is_ground = true; gkind = ground_kind[gi]; break; }\n\t\t}\n\t}\n\tfloat lava_heat = 0.0;\n\tvec3 view_w = normalize(CAMERA_POSITION_WORLD - wpos);\n\tbool moss_masonry = distance(UV2, moss_masonry_tile) < 0.01;\n\tbool masonry = distance(UV2, masonry_tile) < 0.01 || moss_masonry;\n\tif (is_ground && masonry) {\n\t\t// World-space ashlar: broad blocks, thin joints, no subpixel texture shimmer.\n\t\tvec2 paving = wpos.xz * vec2(1.0, 1.6);\n\t\tpaving.x += mod(floor(paving.y), 2.0) * 0.5;\n\t\tvec2 f = fract(paving);\n\t\tfloat edge = min(min(f.x, 1.0-f.x), min(f.y, 1.0-f.y));\n\t\tvec3 stone = moss_masonry ? vec3(0.32,0.39,0.29) : vec3(0.39,0.43,0.44);\n\t\tc.rgb = stone * (0.88 + 0.18 * n_hash(floor(paving)));\n\t\tc.rgb *= mix(0.62, 1.0, smoothstep(0.018, 0.065, edge));\n\t\tc.rgb += vec3(0.025) * (1.0-smoothstep(0.05,0.14,edge));\n\t} else if (is_ground) {\n\t\t// smooth ground: the mesher stores colours blended between neighbouring\n\t\t// blocks in COLOR (alpha 0.5 marks them); otherwise use the tile's average.\n\t\tvec3 base;\n\t\tvec3 own = vec3(0.0);\n\t\tfor (int k = 0; k < 4; k++) {\n\t\t\tvec2 px = vec2(mod(float(k), 2.0) * 8.0 + 3.5, floor(float(k) / 2.0) * 8.0 + 3.5);\n\t\t\town += texture(atlas, (UV2 + px / 16.0) / grid).rgb;\n\t\t}\n\t\town *= 0.25;\n\t\tbase = COLOR.a < 0.75 ? COLOR.rgb : own;\n\t\t// detail fades where this block's colour blends into a different neighbour,\n\t\t// so two ground types meet softly instead of along the block grid\n\t\tfloat dmask = ground_detail_on * (1.0 - smoothstep(0.025, 0.11, distance(base, own)));\n\t\t// soft, seamless variation in world space (no grid)\n\t\tfloat big = n_fbm(wpos.xz * 0.13);\n\t\tfloat mid = n_fbm(wpos.xz * 0.55 + vec2(13.1, 7.3));\n\t\tfloat small = n_value(wpos.xz * 2.2);\n\t\t// darker, slightly cooler patches and lighter warm patches, all soft\n\t\tfloat lum = dot(base, vec3(0.3, 0.59, 0.11));\n\t\tbase = mix(base, vec3(lum), 0.12);\n\t\tvec3 dark = base * vec3(0.66, 0.72, 0.74);\n\t\tvec3 light = base * vec3(1.06, 1.04, 0.96);\n\t\tc.rgb = mix(dark, light, smoothstep(0.3, 0.7, big * 0.65 + mid * 0.35)) * (0.94 + 0.12 * small);\n\t\tif (dmask > 0.0) {\n\t\t\tc.rgb = mix(c.rgb, ground_detail(c.rgb, gkind, wpos.xz, view_w), dmask);\n\t\t}\n\t} else if (is_water) {\n\t\tc.rgb = water_color(wpos, wnrm, view_w, TIME);\n\t} else if (is_lava) {\n\t\tc.rgb = lava_color(wpos, wnrm, TIME, lava_heat);\n\t} else if (hd > 0.5) {\n\t\tc.rgb = clamp(hd_pixel(UV2, local, c), 0.0, 1.0);\n\t}\n\t%s\n\tif (is_ground && gkind > 2.5 && gkind < 3.5 && wpos.x > 1300.0 && wpos.x < 1500.0 && abs(wpos.z) < 110.0) {\n\t\tc.rgb = mix(c.rgb, vec3(0.65, 0.50, 0.30), 0.14) * 0.92;\n\t}\n\tvec3 alb = is_ground ? c.rgb : c.rgb * COLOR.rgb;\n\tbool home = wpos.x > season_rect.x && wpos.z > season_rect.y && wpos.x < season_rect.z && wpos.z < season_rect.w;\n\tif (home) {\n\t\tif (distance(UV2, leaf_tile) < 0.01) {\n\t\t\talb *= leaf_tint;\n\t\t} else if (distance(UV2, grass_tile) < 0.01 || distance(UV2, tgrass_tile) < 0.01 || (distance(UV2, grass_side_tile) < 0.01 && local.y < 0.35)) {\n\t\t\talb *= grass_tint;\n\t\t}\n\t\tif (snow > 0.0 && wup > 0.5 && !is_water) {\n\t\t\tfloat n = fract(sin(dot(floor(wpos.xz * 4.0), vec2(12.9898, 78.233))) * 43758.5453);\n\t\t\talb = mix(alb, vec3(0.74, 0.77, 0.84) * (0.8 + 0.2 * n), snow * step(0.15, n + snow * 0.6));\n\t\t}\n\t}\n\tALBEDO = alb;\n\tROUGHNESS = 1.0;\n\tif (is_lava) {\n\t\tEMISSION = c.rgb * (0.1 + 1.05 * lava_heat);\n\t}\n\tif (night > 0.0) {\n\t\tif (distance(UV2, glow_tile) < 0.01) {\n\t\t\tEMISSION = c.rgb * 1.6 * night;\n\t\t} else if (distance(UV2, glass_tile) < 0.01) {\n\t\t\tEMISSION = vec3(1.0, 0.75, 0.35) * 0.55 * night * step(0.5, fract(sin(dot(floor(wpos.xz), vec2(12.9, 78.2))) * 43758.5));\n\t\t}\n\t}\n}\n"
































































































































































































































































































































































































static func set_xray(player: Vector3, cam: Vector3) -> void:
	for m in [solid_material(), plant_material()]:
		m.set_shader_parameter("player_pos", player)
		m.set_shader_parameter("cam_pos", cam)


static func solid_material() -> ShaderMaterial:
	if _solid_mat == null:
		var sh: = Shader.new()
		sh.code = SHADER_CODE % ["cull_back", "", ""]
		_solid_mat = ShaderMaterial.new()
		_solid_mat.shader = sh
		_solid_mat.set_shader_parameter("atlas", atlas())
		_solid_mat.set_shader_parameter("grid", float(GRID))
		_set_tiles(_solid_mat)
	return _solid_mat


static func plant_material() -> ShaderMaterial:
	if _plant_mat == null:
		var sh: = Shader.new()
		sh.code = SHADER_CODE % ["cull_disabled", "float k = clamp(wpos.y, 0.0, 1.2); VERTEX += vec3(sin(TIME * 1.7 + wpos.x * 0.6 + wpos.z * 0.4), 0.0, cos(TIME * 1.3 + wpos.z * 0.7 + wpos.x * 0.3)) * 0.09 * k * k * wind;", "if (c.a < 0.5) { discard; }"]
		_plant_mat = ShaderMaterial.new()
		_plant_mat.shader = sh
		_plant_mat.set_shader_parameter("atlas", atlas())
		_plant_mat.set_shader_parameter("grid", float(GRID))
		_set_tiles(_plant_mat)
	return _plant_mat



static var _avg: = { }


static func tile_avg(t: int) -> Color:
	if _avg.has(t):
		return _avg[t]
	var r: = 0.0
	var g: = 0.0
	var b: = 0.0
	for y in TILE:
		for x in TILE:
			var c: = _paint(t, x, y)
			r += c.r
			g += c.g
			b += c.b
	var n: = float(TILE * TILE)
	var out: = Color(r / n, g / n, b / n, 0.5)
	_avg[t] = out
	return out



const GROUND_TILES: = [GRASS_TOP, DIRT, PATH, GRAVEL, SAND, PLAZA, COBBLE, STONE_TILE, STONE, FARMLAND,
	SNOW, ICE, PACKED_ICE, SANDSTONE, BASALT, ASH, OBSIDIAN, MOSSY_STONE, RED_SAND, DARK_GRASS, SLATE, STONE_BRICK, MOSSY_BRICK]




const GROUND_KIND: = { GRASS_TOP: 1, DARK_GRASS: 1, DIRT: 2, PATH: 2, SAND: 3, RED_SAND: 3, ASH: 3,
	PLAZA: 4, COBBLE: 4, STONE_TILE: 4, STONE_BRICK: 4, MOSSY_BRICK: 4, SLATE: 4, SANDSTONE: 4,
	SNOW: 5, GRAVEL: 6, STONE: 6, BASALT: 6, MOSSY_STONE: 6, OBSIDIAN: 6, FARMLAND: 7, ICE: 8, PACKED_ICE: 8 }


static func _set_tiles(m: ShaderMaterial) -> void:
	m.set_shader_parameter("masonry_tile", tile_coord(STONE_BRICK))
	m.set_shader_parameter("moss_masonry_tile", tile_coord(MOSSY_BRICK))
	var gt: = PackedVector2Array()
	var gk: = PackedFloat32Array()
	for t in GROUND_TILES:
		gt.append(tile_coord(t))
		gk.append(float(GROUND_KIND.get(t, 0)))
	m.set_shader_parameter("ground_tiles", gt)
	m.set_shader_parameter("ground_kind", gk)
	m.set_shader_parameter("ground_count", gt.size())
	m.set_shader_parameter("water_tile", tile_coord(WATER))
	m.set_shader_parameter("glow_tile", tile_coord(GLOW))
	m.set_shader_parameter("glass_tile", tile_coord(GLASS))
	m.set_shader_parameter("lava_tile", tile_coord(MAGMA))
	m.set_shader_parameter("leaf_tile", tile_coord(LEAVES))
	m.set_shader_parameter("tgrass_tile", tile_coord(TALL_GRASS))
	m.set_shader_parameter("grass_tile", tile_coord(GRASS_TOP))
	m.set_shader_parameter("grass_side_tile", tile_coord(GRASS_SIDE))



static func set_sun(dir: Vector3) -> void:
	if dir.length() < 0.01:
		return
	for m in [solid_material(), plant_material()]:
		m.set_shader_parameter("sun_dir", dir.normalized())



static func set_night(k: float) -> void:
	for m in [solid_material(), plant_material()]:
		m.set_shader_parameter("night", k)



static func set_season(leaf: Color, grass: Color, snow_k: float) -> void:
	for m in [solid_material(), plant_material()]:
		m.set_shader_parameter("leaf_tint", Vector3(leaf.r, leaf.g, leaf.b))
		m.set_shader_parameter("grass_tint", Vector3(grass.r, grass.g, grass.b))
		m.set_shader_parameter("snow", snow_k)
