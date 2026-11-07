extends RefCounted
## Static, chunk-batched ruins. The central court stays at the existing floor level.
static func decorate(z) -> void:
	var desert: bool = z.area == "desert"
	var goals := [Vector2(-40, -42), Vector2(43, 28), Vector2(-40, 42)] if desert else [Vector2(8, 38), Vector2(52, -12)]
	var plots: Array[Rect2] = []
	for goal in goals:
		var choices: Array = []
		for x in range(-72, 73, 8):
			for y in range(-72, 73, 8):
				choices.append([Vector2(x, y).distance_squared_to(goal), Vector2i(x, y)])
		choices.sort_custom(func(a, b): return a[0] < b[0])
		for choice in choices:
			var p: Vector2i = choice[1]
			if not _fits(z, p): continue
			var bounds := Rect2(Vector2(p) - Vector2(9, 8), Vector2(19, 17))
			z.keep(bounds.grow(3))
			_court(z, p, desert)
			plots.append(Rect2(bounds.position + Vector2(z.c), bounds.size))
			break
	z.w.set_meta("ruin_plots", plots)

static func _fits(z, p: Vector2i) -> bool:
	var bounds := Rect2(Vector2(p) - Vector2(10, 9), Vector2(21, 19))
	for keep: Rect2 in z._keep:
		if bounds.intersects(keep.grow(2)): return false
	for monster in load("res://scripts/monsters/spawner.gd").ZONES:
		if String(monster.get("area", "town")) != z.area: continue
		for spot in monster.get("spots", [[monster.pos, monster.r]]):
			var center: Vector2 = spot[0] - Vector2(z.c)
			if center.distance_to(center.clamp(bounds.position, bounds.end)) < float(spot[1]) + 5.0: return false
	for x in range(p.x - 9, p.x + 10):
		for y in range(p.y - 8, p.y + 9):
			if z.gb(x, 0, y) != 0 or z.gb(x, -1, y) in [13, 45, 50]: return false
	return true

static func _court(z, p: Vector2i, desert: bool) -> void:
	var stone := 5 if desert else 54
	var trim := 47 if desert else 53
	# Worn paving, small dark mortar accents, and an open four-block-wide approach.
	for x in range(-8, 9):
		for y in range(-7, 8):
			if maxi(absi(x), absi(y)) <= 5 or posmod(x * 97 + y * 53 + x * y * 17, 23) != 0:
				z.decal(p.x + x, p.y + y, trim if absi(x) == 8 or absi(y) == 7 else stone)
	# Two stepped side terraces frame a clear, level central passage.
	for side in [-1, 1]:
		for tier in 3:
			for x in range(5 + tier, 9):
				for y in range(-6 + tier, 5 - tier):
					z.sb(p.x + side * x, tier, p.y + y, trim if tier == 2 else stone)
		for y in range(-6, 4):
			var height := 4 + posmod(y * 7 + side, 3)
			for h in height:
				z.sb(p.x + side * 8, h, p.y + y, trim if h == height - 1 else stone)
		# Broken columns with sandstone/mossy capstones.
		for y in [-5, 3]:
			var height := 6 if y == -5 else 4
			for h in height:
				z.sb(p.x + side * 6, h, p.y + y, trim if h % 3 == 2 else stone)
			z.sb(p.x + side * 6 + side, height - 1, p.y + y, trim)
	# A partially collapsed rear wall with a broad opening in its centre.
	for x in range(-8, 9):
		if absi(x) <= 2: continue
		var height := 2 + posmod(x * 13, 4)
		for h in height:
			z.sb(p.x + x, h, p.y - 7, trim if h == height - 1 else stone)
	for side in [-1, 1]:
		z.sb(p.x + side * 4, 0, p.y + 5, stone)
		z.sb(p.x + side * 5, 0, p.y + 6, trim)
