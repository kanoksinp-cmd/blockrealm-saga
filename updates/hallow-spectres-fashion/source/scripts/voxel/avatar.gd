class_name Avatar
extends RefCounted
## Player character customisation: option tables (gender, job, hair, face,
## colours, outfit, accessories) and the blocky model built from them.
##
## An "appearance" is a plain Dictionary (saved to disk as-is):
## {gender, job, hair, face, skin, hair_color, eye_color, outfit, outfit_color,
##  accent_color, acc: Array[String]}

const PX := 0.055
const F := BoxModel.FRONT
const BK := BoxModel.BACK
const SPX := BoxModel.SIDE_PX
const SNX := BoxModel.SIDE_NX
const TP := BoxModel.TOP
const BT := BoxModel.BOTTOM

# ------------------------------------------------------------------ option tables
const GENDERS := ["male", "female"]

## main = stat used for attack power. anim: slash / shoot / cast.
const JOBS := {
	"swordsman": {"name": "Swordsman", "weapon": "iron_sword", "sprite": "iron_sword", "anim": "slash", "range": 1.9, "main": "STR",
		"stats": {"STR": 8, "AGI": 5, "VIT": 7, "INT": 2, "DEX": 5, "LUK": 3},
		"skills": ["Bash", "Whirl Slash"],
		"desc": "A brave front-line fighter with high HP.\nStrong melee attacks and tough defence."},
	"archer": {"name": "Archer", "weapon": "hunting_bow", "sprite": "bow", "anim": "shoot", "range": 7.0, "main": "DEX",
		"stats": {"STR": 3, "AGI": 7, "VIT": 4, "INT": 3, "DEX": 9, "LUK": 4},
		"skills": ["Double Strafe", "Arrow Shower"],
		"desc": "Shoots arrows from long range.\nHigh accuracy (DEX) and attack speed."},
	"mage": {"name": "Mage", "weapon": "oak_staff", "sprite": "staff", "anim": "cast", "range": 6.0, "main": "INT",
		"stats": {"STR": 2, "AGI": 4, "VIT": 3, "INT": 10, "DEX": 7, "LUK": 4},
		"skills": ["Fire Bolt", "Frost Nova"],
		"desc": "Casts magic bolts from afar.\nPowerful (INT) but fragile - keep your distance!"},
	"acolyte": {"name": "Acolyte", "weapon": "iron_mace", "sprite": "mace", "anim": "slash", "range": 1.9, "main": "STR",
		"stats": {"STR": 5, "AGI": 4, "VIT": 6, "INT": 8, "DEX": 4, "LUK": 3},
		"skills": ["Holy Light", "Magnus Burst"],
		"desc": "A servant of the gods with a sturdy mace.\nLots of SP; recovers HP and SP faster."},
	"merchant": {"name": "Merchant", "weapon": "hand_axe", "sprite": "axe", "anim": "slash", "range": 1.9, "main": "STR",
		"stats": {"STR": 8, "AGI": 3, "VIT": 8, "INT": 2, "DEX": 6, "LUK": 3},
		"skills": ["Mammonite", "Cart Revolution"],
		"desc": "A tough trader who swings a heavy axe.\nCarries more weight and sells loot for more Zeny."},
	"thief": {"name": "Thief", "weapon": "steel_dagger", "sprite": "dagger", "anim": "slash", "range": 1.7, "main": "STR",
		"stats": {"STR": 5, "AGI": 10, "VIT": 4, "INT": 2, "DEX": 6, "LUK": 3},
		"skills": ["Envenom", "Shadow Spin"],
		"desc": "Fast and evasive with a sharp dagger.\nVery high attack speed (AGI) and dodge."},
}
## Everyone starts as a Novice (not in JOB_ORDER: it can't be picked as a job).
const NOVICE := {"name": "Novice", "weapon": "worn_knife", "sprite": "dagger", "anim": "slash", "range": 1.8, "main": "STR",
	"stats": {"STR": 5, "AGI": 5, "VIT": 5, "INT": 5, "DEX": 5, "LUK": 5},
	"skills": ["Basic Training", "Field Dressing"],
	"desc": "A fresh adventurer. Reach Job Lv 10 to choose a job."}
const JOB_ORDER := ["swordsman", "archer", "mage", "acolyte", "merchant", "thief"]

const HAIRSTYLES := ["Short", "Spiky", "Messy", "Bob", "Long", "Ponytail", "Twin Tails", "Buzz Cut", "Bun"]
## per style: rows of hair on the side near the face, side further back, back of the head
const HAIR_SIDE := [[2, 4, 5], [2, 4, 5], [3, 5, 6], [6, 7, 7], [7, 7, 7], [2, 4, 5], [2, 5, 6], [1, 2, 3], [2, 4, 6]]
const FACES := ["Friendly", "Big Eyes", "Determined", "Calm", "Cheerful", "Freckles"]
const OUTFITS := ["Adventurer", "Leather Armor", "Mage Robe", "Squire Plate", "Ranger", "Priest Robe", "Merchant", "Shadow Garb"]
const ACCESSORIES := ["cape", "scarf", "satchel", "glasses", "headband", "elf_ears", "flower", "hat"]
const ACC_NAMES := {"cape": "Cape", "scarf": "Scarf", "satchel": "Satchel", "glasses": "Glasses",
	"headband": "Headband", "elf_ears": "Elf Ears", "flower": "Flower Pin", "hat": "Feather Hat"}

const SKIN_TONES := [Color(1.0, 0.87, 0.77), Color(0.96, 0.8, 0.66), Color(0.92, 0.73, 0.58), Color(0.84, 0.63, 0.47),
	Color(0.71, 0.51, 0.36), Color(0.56, 0.39, 0.27), Color(0.42, 0.29, 0.2), Color(0.76, 0.84, 0.96)]
const HAIR_COLORS := [Color(0.36, 0.23, 0.14), Color(0.52, 0.34, 0.2), Color(0.66, 0.32, 0.16), Color(0.13, 0.12, 0.14),
	Color(0.94, 0.8, 0.45), Color(0.93, 0.91, 0.86), Color(0.78, 0.2, 0.15), Color(0.62, 0.64, 0.7),
	Color(0.3, 0.45, 0.85), Color(0.35, 0.62, 0.36), Color(0.95, 0.55, 0.72), Color(0.55, 0.35, 0.78)]
const EYE_COLORS := [Color(0.4, 0.23, 0.12), Color(0.2, 0.55, 0.98), Color(0.22, 0.66, 0.3), Color(0.88, 0.6, 0.12),
	Color(0.48, 0.53, 0.6), Color(0.6, 0.35, 0.88), Color(0.82, 0.15, 0.2), Color(0.1, 0.66, 0.66)]
const CLOTH_COLORS := [Color(0.38, 0.5, 0.26), Color(0.24, 0.42, 0.3), Color(0.18, 0.5, 0.52), Color(0.22, 0.3, 0.56),
	Color(0.36, 0.57, 0.82), Color(0.46, 0.3, 0.62), Color(0.72, 0.18, 0.2), Color(0.88, 0.47, 0.16),
	Color(0.82, 0.64, 0.2), Color(0.52, 0.34, 0.2), Color(0.2, 0.2, 0.24), Color(0.92, 0.89, 0.8)]

const SHIRT := Color(0.9, 0.86, 0.74)
const LEATHER := Color(0.5, 0.33, 0.2)
const LEATHER_D := Color(0.36, 0.23, 0.14)
const GOLD := Color(0.95, 0.76, 0.28)
const PLATE := Color(0.78, 0.8, 0.85)
const PLATE_D := Color(0.56, 0.58, 0.65)
const PLATE_L := Color(0.92, 0.94, 0.97)
const MAIL := Color(0.52, 0.52, 0.56)
const MAIL_D := Color(0.4, 0.4, 0.44)
const WHITE := Color(0.94, 0.93, 0.89)
const DARK := Color(0.19, 0.19, 0.23)

static var _models := {}


static func default_appearance() -> Dictionary:
	return {"gender": "male", "job": "swordsman", "hair": 2, "face": 0, "skin": 1, "hair_color": 1, "eye_color": 0,
		"outfit": 0, "outfit_color": 0, "accent_color": 1, "acc": ["cape"], "fashion": ""}


static func random_appearance(rng: RandomNumberGenerator, keep := {}) -> Dictionary:
	var a := default_appearance()
	a.gender = keep.get("gender", GENDERS[rng.randi() % 2])
	a.job = keep.get("job", JOB_ORDER[rng.randi() % JOB_ORDER.size()])
	a.hair = rng.randi() % HAIRSTYLES.size()
	a.face = rng.randi() % FACES.size()
	a.skin = rng.randi() % (SKIN_TONES.size() - 1)
	a.hair_color = rng.randi() % HAIR_COLORS.size()
	a.eye_color = rng.randi() % EYE_COLORS.size()
	a.outfit = rng.randi() % OUTFITS.size()
	a.outfit_color = rng.randi() % CLOTH_COLORS.size()
	a.accent_color = rng.randi() % CLOTH_COLORS.size()
	var acc: Array = []
	for id in ACCESSORIES:
		if rng.randf() < 0.22:
			acc.append(id)
	a.acc = acc
	return a


static func job(id: String) -> Dictionary:
	if id == "novice":
		return NOVICE
	return JOBS.get(id, JOBS.swordsman)


static func is_job(id: String) -> bool:
	return id == "novice" or JOBS.has(id)


static func has(a: Dictionary, acc: String) -> bool:
	return acc in a.get("acc", [])


# ------------------------------------------------------------------ painters
static func n(c: Color, u: int, v: int, s: int, amt := 0.04) -> Color:
	return BoxModel.noise(c, u, v, s, amt)


## front-of-head hair mask
static func _front_hair(style: int, u: int, v: int) -> bool:
	match style:
		0, 5:
			return v <= 1 or (v == 2 and (u == 0 or u == 7))
		1:
			return v <= 1 or (v == 2 and u in [0, 2, 5, 7])
		2:
			return v <= 1 or (v == 2 and not (u in [2, 5])) or (v == 3 and (u == 0 or u == 7))
		3:
			return v <= 1 or (v <= 6 and (u == 0 or u == 7))
		4:
			return v <= 1 or (v == 2 and u in [0, 1, 6, 7]) or (u == 0 or u == 7)
		6:
			return v <= 1 or (v == 2 and u in [0, 1, 6, 7])
		7:
			return v == 0
	return v <= 1 or (v == 2 and (u == 0 or u == 7))


static func _face(a: Dictionary, u: int, v: int, skin: Color, eye: Color, hair: Color) -> Color:
	var female: bool = a.gender == "female"
	var mouth := Color(0.86, 0.42, 0.46) if female else skin.darkened(0.35).lerp(Color(0.55, 0.25, 0.22), 0.4)
	var white := Color(0.97, 0.97, 0.97)
	var line := Color(0.17, 0.12, 0.12)
	var blush := skin.lerp(Color(0.98, 0.5, 0.55), 0.45)
	var f: int = a.face
	if female and v == 3 and (u == 1 or u == 6) and f in [0, 1, 2, 5]:
		return line
	match f:
		0, 5:
			if v == 4:
				if u == 1 or u == 6:
					return white
				if u == 2 or u == 5:
					return eye
			if f == 5 and v == 5 and (u == 1 or u == 6):
				return skin.darkened(0.2)
			if v == 6 and (u == 3 or u == 4):
				return mouth
		1:
			if (v == 4 or v == 5) and (u in [1, 2, 5, 6]):
				if v == 4 and (u == 1 or u == 5):
					return white
				return eye.darkened(0.1) if v == 5 else eye
			if v == 6 and u == 4:
				return mouth
			if v == 6 and u == 3:
				return mouth.lightened(0.15)
		2:
			if v == 3 and u in [1, 2, 5, 6]:
				return hair.darkened(0.3)
			if v == 4:
				if u == 1 or u == 6:
					return white
				if u == 2 or u == 5:
					return eye
			if v == 6 and u in [3, 4]:
				return line.lerp(mouth, 0.3)
		3:
			if v == 4 and u in [1, 2, 5, 6]:
				return line
			if v == 5 and (u == 1 or u == 6):
				return blush
			if v == 6 and u in [3, 4]:
				return mouth
		4:
			if (u == 1 and v == 5) or (u == 2 and v == 4) or (u == 5 and v == 4) or (u == 6 and v == 5):
				return line
			if v == 5 and (u == 0 or u == 7):
				return blush
			if v == 6 and u in [3, 4]:
				return Color(0.6, 0.16, 0.2)
	if v == 5 and (u == 3 or u == 4):
		return skin.darkened(0.07)
	return skin


static func _head_painter(a: Dictionary) -> Callable:
	var skin: Color = SKIN_TONES[a.skin]
	var hair: Color = HAIR_COLORS[a.hair_color]
	var eye: Color = EYE_COLORS[a.eye_color]
	var style: int = a.hair
	var sides: Array = HAIR_SIDE[style]
	return func(f, u, v, w, h) -> Color:
		var hc := n(hair, u, v, 31 + f)
		if f == TP:
			return hc.lightened(0.08) if (u + v) % 5 == 0 else hc
		if f == BT:
			return skin.darkened(0.12)
		if f == BK:
			return hc if v <= sides[2] else skin.darkened(0.06)
		if f == SPX or f == SNX:
			var d: int = u if f == SPX else w - 1 - u      # 0 = front edge
			if v <= 1 or (d <= 2 and v <= sides[0]) or (d >= 3 and v <= sides[1]):
				return hc
			if d >= 3 and d <= 4 and v >= 3 and v <= 5:
				return skin.darkened(0.1 if v == 4 else 0.05)
			return skin
		# front
		if _front_hair(style, u, v):
			if v == 0 and (u == 2 or u == 3):
				return hc.lightened(0.15)
			return hc
		return _face(a, u, v, skin, eye, hair)


# ------------------------------------------------------------------ HD (1/64) head art
## Hair drawn at sub-pixel scale: flowing strands with shine and shadow.
static func _strand(hair: Color, f: int, u: int, v: int) -> Color:
	var k := (u * 2 + (v * 9 / 10 if f % 2 == 0 else -(v * 9 / 10)) + ((u / 5) * 7 % 3)) % 12
	if k < 0:
		k += 12
	if k < 2:
		return hair.darkened(0.2)
	if k >= 5 and k < 7:
		return hair.lightened(0.13)
	return hair


const _SIDES := [0, 1, 2, 3]


static func _hd_hair(hair: Color, coarse: Callable) -> Callable:
	var cache := {}
	return func(f, u, v, w, h) -> Color:
		var key: int = f * 4096 + (u / BoxModel.HD) * 64 + v / BoxModel.HD
		if not cache.has(key):
			cache[key] = coarse.call(f, u / BoxModel.HD, v / BoxModel.HD, w / BoxModel.HD, h / BoxModel.HD)
		return _strand(cache[key], f, u, v)


static func _cdist(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)


static func _hairy(f: int, u: int, v: int, c: Color, style: int, hair: Color, skin: Color) -> bool:
	if f == TP:
		return true
	if f == BT:
		return false
	if f == F:
		return _front_hair(style, u, v)
	return _cdist(c, hair) < _cdist(c, skin)


## The head at 32x32 per face: strands of hair with a jagged fringe, and a
## proper face (lashes, irises with shine, brows, nose, mouth, blush).
static func _hd_head(a: Dictionary, coarse: Callable) -> Callable:
	var skin: Color = SKIN_TONES[a.skin]
	var hair: Color = HAIR_COLORS[a.hair_color]
	var eye: Color = EYE_COLORS[a.eye_color]
	var style: int = a.hair
	var K := BoxModel.HD
	var cache := {}
	var cell := func(f: int, cu: int, cv: int, w: int, h: int) -> Array:
		var key := f * 4096 + cu * 64 + cv
		if not cache.has(key):
			var cc: Color = coarse.call(f, cu, cv, w, h)
			cache[key] = [cc, _hairy(f, cu, cv, cc, style, hair, skin)]
		return cache[key]
	return func(f, u, v, w, h) -> Color:
		var cu: int = u / K
		var cv: int = v / K
		var here: Array = cell.call(f, cu, cv, w / K, h / K)
		var c: Color = here[0]
		var hairy: bool = here[1]
		if f != F or not hairy:
			# fringe tips hang a little below the coarse hairline
			if cv > 0:
				if cell.call(f, cu, cv - 1, w / K, h / K)[1] and f != TP and f != BT:
					var tip := int(2.6 * absf(sin(float(u) * 0.55 + style * 1.7)))
					if v % K < tip:
						return _strand(hair, f, u, v).darkened(0.08)
					if v % K < tip + 1:
						return skin.darkened(0.14) if not hairy else c
		if hairy:
			if f == TP:
				return PixelTex.jit(c.lightened(0.04 if (u + v) % 7 == 0 else 0.0), u, v, 95, 0.03)
			return _strand(hair, f, u, v)
		if f != F:
			return PixelTex.jit(c, u, v, 96, 0.012)
		var px := _hd_face(a, u, v, skin, eye, hair)
		return px
	

static func _hd_face(a: Dictionary, u: int, v: int, skin: Color, eye: Color, hair: Color) -> Color:
	var female: bool = a.gender == "female"
	var fs: int = a.face
	var mouth := Color(0.86, 0.42, 0.46) if female else skin.darkened(0.35).lerp(Color(0.55, 0.25, 0.22), 0.4)
	var line := Color(0.17, 0.12, 0.12)
	var white := Color(0.97, 0.97, 0.97)
	var blush := skin.lerp(Color(0.98, 0.5, 0.55), 0.4)
	var brow := hair.darkened(0.35)
	var base := skin.darkened(0.035 * absf(u - 15.5) / 16.0)
	var side := 0 if u < 16 else 1
	var x := u if side == 0 else 31 - u       # mirror: x is distance from the face edge
	# brows
	if fs == 2:
		if v == 12 + (x - 5) / 3 and x >= 5 and x <= 12:
			return brow
		if v == 13 + (x - 5) / 3 and x >= 5 and x <= 11:
			return brow.lightened(0.1)
	elif fs != 4 and (v == 12 or (v == 11 and x >= 7 and x <= 9)) and x >= 6 and x <= 11 and not (v == 12 and (x == 7 or x == 8 or x == 9) and v == 11):
		if v == 12 and x >= 6 and x <= 11:
			return brow.lightened(0.12)
		if v == 11:
			return brow.lightened(0.12)
	# eyes
	match fs:
		3:   # calm: closed, gently curved
			if (v == 18 and x >= 6 and x <= 11) or (v == 17 and (x == 5 or x == 12)):
				return line
			if female and v == 17 and x == 4:
				return line
		4:   # cheerful: ^ ^
			if (v == 18 - mini(x - 5, 11 - x + 1) and x >= 5 and x <= 12 and v >= 15):
				return line
		_:
			var top := 15
			var bot := 20
			var x0 := 5
			var x1 := 11
			if fs == 1:
				top = 14; bot = 21; x0 = 5; x1 = 12
			elif fs == 2:
				top = 16; bot = 19
			if v >= top - 1 and v <= bot and x >= x0 - 1 and x <= x1:
				if v == top - 1:
					if x >= x0 and x <= x1 - 1:
						return line
					if female and x == x0 - 1:
						return line
					return base
				if x == x0 - 1:
					return line if (female and v == top) else base
				if x < x0:
					return base
				# iris sits toward the nose (inner side)
				var ix0 := x1 - (4 if fs == 1 else 3)
				if x >= ix0:
					var t := float(v - top) / float(bot - top)
					var ic := eye.darkened(0.35).lerp(eye.lightened(0.2), t)
					if x >= ix0 + 1 and x <= ix0 + 2 and v >= top + 1 and v <= bot - 1 and fs != 2:
						ic = Color(0.1, 0.08, 0.1)
					if x == ix0 and v == top + 1:
						ic = Color(1, 1, 1)
					if fs == 1 and x == ix0 + 3 and v == bot - 1:
						ic = Color(1, 1, 1).lerp(eye, 0.3)
					return ic
				if v == bot:
					return white.darkened(0.08)
				return white
			if v == bot + 1 and x >= x0 and x <= x1:
				return base.darkened(0.08)
	# freckles
	if fs == 5 and v >= 21 and v <= 23 and ((x == 5 and v == 21) or (x == 8 and v == 22) or (x == 6 and v == 23) or (x == 10 and v == 21)):
		return skin.darkened(0.22)
	# blush
	if (female or fs == 3 or fs == 4) and v >= 21 and v <= 22 and x >= 3 and x <= 7:
		return base.lerp(blush, 0.7 if v == 21 else 0.45)
	# nose
	if (u == 15 or u == 16) and v == 22:
		return base.darkened(0.1 if u == 16 else 0.05)
	if u == 16 and v == 21:
		return base.darkened(0.04)
	# mouth
	match fs:
		1:
			if v == 25 and (u == 14 or u == 17):
				return line.lerp(mouth, 0.4)
			if v == 26 and (u == 15 or u == 16):
				return line.lerp(mouth, 0.4)
		2:
			if v == 26 and u >= 13 and u <= 18:
				return line.lerp(mouth, 0.35)
		4:
			if v == 24 and u >= 12 and u <= 19:
				return line
			if v >= 25 and v <= 27 and u >= 13 + (v - 25) and u <= 18 - (v - 25):
				return Color(0.55, 0.14, 0.18) if v < 27 else Color(0.92, 0.5, 0.55)
		_:
			if v == 25 and u >= 13 and u <= 18:
				return mouth.darkened(0.15) if (u == 13 or u == 18) else mouth.darkened(0.3)
			if v == 26 and u >= 14 and u <= 17:
				return mouth
			if v == 27 and (u == 15 or u == 16):
				return mouth.lightened(0.25)
	# soft shading towards the jaw
	if v >= 28:
		base = base.darkened(0.03 * (v - 27))
	return PixelTex.jit(base, u, v, 97, 0.008)


## Returns [body, arm, leg, hem] painters (hem may be null) for the outfit.
static func _outfit_painters(a: Dictionary) -> Array:
	var P: Color = CLOTH_COLORS[a.outfit_color]
	var skin: Color = SKIN_TONES[a.skin]
	var female: bool = a.gender == "female"
	var body: Callable
	var arm: Callable
	var leg: Callable
	var hem = null
	match int(a.outfit):
		0:   # adventurer: cream shirt, coloured jerkin, leather belt / bracers / boots
			body = func(f, u, v, w, h) -> Color:
				if v == 8:
					return GOLD if f == F and (u == 3 or u == 4) else n(LEATHER_D, u, v, 2)
				if v >= 9:
					return n(P.darkened(0.08), u, v, 3)
				if f == F and (u == 3 or u == 4):
					return SHIRT.darkened(0.12) if u == 3 and v % 2 == 1 and v > 0 else SHIRT
				if f == F and (u == 2 or u == 5):
					return n(P.darkened(0.18), u, v, 4)
				if f == TP:
					return SHIRT if u >= 2 and u <= 5 else P
				return n(P, u, v, 5)
			arm = func(f, u, v, w, h) -> Color:
				if f == TP:
					return SHIRT
				if f == BT or v >= 10:
					return skin
				if v >= 7:
					return n(LEATHER if v != 7 else LEATHER.lightened(0.1), u, v, 6)
				return n(SHIRT, u, v, 7, 0.03)
			leg = func(f, u, v, w, h) -> Color:
				if f == BT or v == 11:
					return LEATHER_D.darkened(0.3)
				if v == 7:
					return LEATHER.lightened(0.12)
				if v >= 8:
					return n(LEATHER, u, v, 8)
				return n(Color(0.36, 0.3, 0.24), u, v, 9)
			hem = func(f, u, v, w, h) -> Color:
				if f == TP or f == BT:
					return P.darkened(0.2)
				if v == h - 1 or (f == F and u == 4):
					return P.darkened(0.2)
				return n(P.darkened(0.06), u, v, 10)
		1:   # leather armour over a coloured shirt
			body = func(f, u, v, w, h) -> Color:
				if v == 8:
					return GOLD if f == F and (u == 3 or u == 4) else LEATHER_D.darkened(0.2)
				if f == TP:
					return P
				if v == 0:
					return n(P, u, v, 11)
				if v >= 9:
					return n(LEATHER_D if u % 2 == 0 else LEATHER, u, v, 12)
				if v == 3 or v == 6:
					return LEATHER.lightened(0.12)
				return n(LEATHER, u, v, 13)
			arm = func(f, u, v, w, h) -> Color:
				if f == TP or v <= 4:
					return n(P, u, v, 14)
				if v >= 10 or f == BT:
					return LEATHER_D
				return n(LEATHER, u, v, 15)
			leg = func(f, u, v, w, h) -> Color:
				if v >= 8 or f == BT:
					return n(LEATHER_D, u, v, 16)
				if v == 5:
					return LEATHER
				return n(P.darkened(0.25), u, v, 17)
			if female:
				hem = func(f, u, v, w, h) -> Color: return n(LEATHER_D if u % 2 == 0 else LEATHER, u, v, 18)
		2:   # mage robe
			var trim := GOLD.darkened(0.05)
			body = func(f, u, v, w, h) -> Color:
				if v == 8:
					return n(P.darkened(0.35), u, v, 19)
				if f == F and (v == 0 or u == 3 or u == 4) and v != 8:
					return trim if (u == 3 or u == 4 or v == 0) else P
				return n(P, u, v, 20)
			arm = func(f, u, v, w, h) -> Color:
				if v >= 10 or f == BT:
					return skin
				if v == 9:
					return trim
				return n(P, u, v, 21)
			leg = func(f, u, v, w, h) -> Color:
				if v >= 9 or f == BT:
					return Color(0.3, 0.22, 0.18)
				return n(P.darkened(0.05), u, v, 22)
			hem = func(f, u, v, w, h) -> Color:
				if v == h - 1 or (f == F and u == 4):
					return trim
				return n(P, u, v, 23)
		3:   # squire plate with coloured tabard
			body = func(f, u, v, w, h) -> Color:
				if f == F and u >= 2 and u <= 5 and v >= 1:
					if (v == 3 or v == 4) and (u == 3 or u == 4):
						return GOLD
					return n(P, u, v, 24)
				if v == 8:
					return n(LEATHER_D, u, v, 25)
				if v >= 9:
					return MAIL if (u + v) % 2 == 0 else MAIL_D
				if f == TP or v == 0:
					return PLATE_D
				return n(PLATE_L if u == 3 or u == 4 else PLATE, u, v, 26)
			arm = func(f, u, v, w, h) -> Color:
				if f == TP:
					return PLATE
				if v >= 4 and v <= 6:
					return n(P, u, v, 27)
				if v == 7:
					return PLATE_D
				return n(PLATE_L if v == 8 else PLATE, u, v, 28)
			leg = func(f, u, v, w, h) -> Color:
				if f == BT or v == 11:
					return Color(0.7, 0.5, 0.3)
				if v <= 3:
					return MAIL if (u + v) % 2 == 0 else MAIL_D
				if v == 4:
					return LEATHER_D
				if v == 10:
					return Color(0.84, 0.62, 0.38)
				return n(PLATE_L if v == 7 and f == F else PLATE, u, v, 29)
			hem = func(f, u, v, w, h) -> Color:
				if (f == SPX or f == SNX) and u >= 1 and u <= 3:
					return n(P, u, v, 30)
				if f == TP or v == h - 1:
					return MAIL_D
				return MAIL if (u + v) % 2 == 0 else MAIL_D
		4:   # ranger tunic
			body = func(f, u, v, w, h) -> Color:
				if v == 8:
					return n(Color(0.35, 0.24, 0.14), u, v, 31)
				if f == F and v >= 1 and v <= 5 and (u == 3 or u == 4):
					return Color(0.28, 0.2, 0.14) if (u + v) % 2 == 0 else P.darkened(0.15)
				if v == 0:
					return P.darkened(0.2)
				return n(P if v < 9 else P.darkened(0.1), u, v, 32)
			arm = func(f, u, v, w, h) -> Color:
				if v >= 10 or f == BT:
					return skin
				if v >= 8:
					return n(LEATHER, u, v, 33)
				return n(P, u, v, 34)
			leg = func(f, u, v, w, h) -> Color:
				if f == BT or v == 11:
					return LEATHER_D.darkened(0.2)
				if v == 6:
					return LEATHER.lightened(0.15)
				if v >= 6:
					return n(LEATHER, u, v, 35)
				return n(Color(0.3, 0.28, 0.21), u, v, 36)
			hem = func(f, u, v, w, h) -> Color: return n(P.darkened(0.1) if v < h - 1 else P.darkened(0.25), u, v, 37)
		5:   # priest robe
			body = func(f, u, v, w, h) -> Color:
				if f == F:
					if (u == 3 or u == 4) and v >= 2 and v <= 5 or v == 3 and u >= 2 and u <= 5:
						return GOLD
					if u == 1 or u == 6:
						return n(P, u, v, 38)
				if v == 8:
					return P.darkened(0.25)
				if f == BK and v == 0:
					return P
				return n(WHITE, u, v, 39, 0.02)
			arm = func(f, u, v, w, h) -> Color:
				if v >= 10 or f == BT:
					return skin
				if v == 9:
					return P
				return n(WHITE, u, v, 40, 0.02)
			leg = func(f, u, v, w, h) -> Color:
				if v >= 9 or f == BT:
					return Color(0.35, 0.25, 0.2)
				return n(WHITE.darkened(0.04), u, v, 41, 0.02)
			hem = func(f, u, v, w, h) -> Color:
				if v == h - 1:
					return P
				if f == F and (u == 2 or u == 6):
					return P
				return n(WHITE, u, v, 42, 0.02)
		6:   # merchant: shirt, vest, apron
			var apron := Color(0.78, 0.68, 0.5)
			body = func(f, u, v, w, h) -> Color:
				if v == 8:
					return n(LEATHER_D, u, v, 43)
				if f == F and v >= 9:
					return n(apron, u, v, 44)
				if f == F and (u == 3 or u == 4) and v < 8:
					return Color(0.3, 0.3, 0.32) if u == 3 and v % 3 == 1 else WHITE
				if v >= 9:
					return n(Color(0.32, 0.28, 0.24), u, v, 45)
				return n(P, u, v, 46)
			arm = func(f, u, v, w, h) -> Color:
				if v >= 8 or f == BT:
					return skin
				if v == 7:
					return WHITE.darkened(0.08)
				return n(WHITE, u, v, 47, 0.02)
			leg = func(f, u, v, w, h) -> Color:
				if v >= 9 or f == BT:
					return n(LEATHER, u, v, 48)
				return n(Color(0.32, 0.28, 0.24), u, v, 49)
			if female:
				hem = func(f, u, v, w, h) -> Color: return n(apron if f == F else P.darkened(0.1), u, v, 50)
		_:   # shadow garb
			var strap := Color(0.38, 0.27, 0.18)
			body = func(f, u, v, w, h) -> Color:
				if v == 8:
					return n(P, u, v, 51)
				if (f == F or f == BK) and v <= 7 and (u == v or u == 7 - v):
					return strap
				return n(DARK, u, v, 52, 0.03)
			arm = func(f, u, v, w, h) -> Color:
				if v == 5:
					return P
				return n(DARK if v < 10 else DARK.lightened(0.08), u, v, 53, 0.03)
			leg = func(f, u, v, w, h) -> Color:
				if v == 4:
					return strap
				if v >= 8 or f == BT:
					return n(Color(0.3, 0.22, 0.16), u, v, 54)
				return n(DARK, u, v, 55, 0.03)
			if female:
				hem = func(f, u, v, w, h) -> Color: return n(DARK.lightened(0.05), u, v, 56, 0.03)
	return [body, arm, leg, hem]


# ------------------------------------------------------------------ model
static func model(a: Dictionary) -> BoxModel:
	var key := var_to_str(a)
	if _models.has(key):
		return _models[key]
	if _models.size() > 120:
		_models.clear()
	var skin: Color = SKIN_TONES[a.skin]
	var hair: Color = HAIR_COLORS[a.hair_color]
	var acc_c: Color = CLOTH_COLORS[a.accent_color]
	var m := BoxModel.new(PX)
	var headp := _head_painter(a)
	m.add("head", Vector3i(8, 8, 8), headp, {"hd": _hd_head(a, headp), "hd_faces": [F, BK, SPX, SNX]})
	var op := _outfit_painters(a)
	m.add("body", Vector3i(8, 12, 4), op[0])
	m.add("arm", Vector3i(4, 12, 4), op[1])
	m.add("leg", Vector3i(4, 12, 4), op[2])
	if op[3] != null:
		var long := int(a.outfit) in [2, 5]
		m.add("hem", Vector3i(9, 7 if long else 4, 5), op[3])
	if int(a.outfit) == 3:
		m.add("pauldron", Vector3i(5, 4, 5), func(f, u, v, w, h):
			if f == TP:
				return n(PLATE_L if u == 0 or u == 4 or v == 0 or v == 4 else PLATE, u, v, 60)
			if f == BT:
				return PLATE_D
			return n([PLATE_L, PLATE, PLATE_D, PLATE][v], u, v, 61))
	# hair pieces
	var hairf := func(f, u, v, w, h) -> Color: return n(hair.lightened(0.06) if f == TP else hair, u, v, 62)
	m.add("hair_bit", Vector3i(2, 3, 2), hairf, {"hd": _hd_hair(hair, hairf), "hd_faces": _SIDES})
	m.add("hair_side", Vector3i(1, 7, 8), hairf, {"hd": _hd_hair(hair, hairf), "hd_faces": _SIDES})
	var backf := func(f, u, v, w, h): return n(hair.darkened(0.06) if v == h - 1 else hair, u, v, 63)
	m.add("hair_back", Vector3i(8, 10, 1), backf, {"hd": _hd_hair(hair, backf), "hd_faces": _SIDES})
	var tailf := func(f, u, v, w, h): return n(hair.darkened(0.04 * v), u, v, 64)
	m.add("tail", Vector3i(2, 7, 2), tailf, {"hd": _hd_hair(hair, tailf), "hd_faces": _SIDES})
	m.add("bun", Vector3i(4, 3, 4), hairf, {"hd": _hd_hair(hair, hairf), "hd_faces": _SIDES})
	m.add("tie", Vector3i(2, 1, 2), BoxModel.flat(acc_c, 65))
	# accessories
	m.add("cape", Vector3i(9, 15, 1), func(f, u, v, w, h):
		if v == 0:
			return acc_c.darkened(0.25)
		if f == BK and (u == 0 or u == w - 1):
			return acc_c.darkened(0.15)
		return n(acc_c.darkened(0.12) if f == F else acc_c, u, v, 66))
	m.add("clasp", Vector3i(2, 2, 1), BoxModel.flat(GOLD, 67))
	m.add("scarf", Vector3i(9, 2, 5), func(f, u, v, w, h): return n(acc_c.lightened(0.08) if v == 0 else acc_c, u, v, 68))
	m.add("scarf_end", Vector3i(2, 5, 1), func(f, u, v, w, h): return n(acc_c.darkened(0.1) if v == h - 1 else acc_c, u, v, 69))
	m.add("bag", Vector3i(4, 4, 2), func(f, u, v, w, h):
		if f == SPX or f == SNX or f == F:
			if v == 0:
				return LEATHER_D
			if v == 1 and (u == 1 or u == 2):
				return GOLD
		return n(LEATHER, u, v, 70))
	m.add("strap", Vector3i(1, 17, 1), BoxModel.flat(LEATHER_D, 71))
	m.add("glasses", Vector3i(9, 2, 1), func(f, u, v, w, h):
		if f != F and f != BK:
			return Color(0.15, 0.13, 0.12)
		if u == 4:
			return Color(0.15, 0.13, 0.12) if v == 0 else Color(0, 0, 0, 0)
		if v == 1 and (u == 2 or u == 6):
			return Color(0.75, 0.88, 1.0, 1.0)
		if (u == 1 or u == 2 or u == 6 or u == 7) and v == 0:
			return Color(0.15, 0.13, 0.12)
		if u == 0 or u == 3 or u == 5 or u == 8:
			return Color(0.15, 0.13, 0.12)
		return Color(0.75, 0.88, 1.0, 1.0) if v == 1 else Color(0, 0, 0, 0))
	m.add("headband", Vector3i(9, 1, 9), BoxModel.flat(acc_c, 72))
	m.add("knot", Vector3i(2, 3, 1), BoxModel.flat(acc_c.darkened(0.1), 73))
	m.add("ear", Vector3i(1, 2, 3), func(f, u, v, w, h): return skin.darkened(0.12) if v == 1 and u == 1 else skin)
	m.add("ear_tip", Vector3i(1, 2, 2), func(f, u, v, w, h): return skin.darkened(0.04 * v))
	m.add("flower", Vector3i(3, 3, 1), func(f, u, v, w, h):
		if u == 1 and v == 1:
			return Color(1.0, 0.85, 0.2)
		if (u + v) % 2 == 0:
			return Color(0, 0, 0, 0) if f == F or f == BK else Color(0.95, 0.45, 0.65)
		return Color(0.98, 0.55, 0.72))
	m.add("hat_brim", Vector3i(11, 1, 11), func(f, u, v, w, h): return n(acc_c.darkened(0.1), u, v, 74))
	m.add("hat_top", Vector3i(7, 4, 7), func(f, u, v, w, h): return n(LEATHER_D if v == 3 else acc_c, u, v, 75))
	m.add("feather", Vector3i(1, 6, 2), func(f, u, v, w, h): return Color(0.97, 0.95, 0.9).darkened(0.03 * v) if v < 5 else Color(0.85, 0.3, 0.25))
	_add_gear_parts(m, a)
	m.bake()
	_models[key] = m
	return m


## Builds the avatar under `root` (feet at y=0, facing +Z). Returns the rig pivots
## (hips, torso, head, arm_l, arm_r, leg_l, leg_r) plus "weapon".
static func assemble(root: Node3D, a: Dictionary, with_weapon := true) -> Dictionary:
	var m := model(a)
	var r := Skins.humanoid(m, root)
	var female: bool = a.gender == "female"
	var style: int = a.hair
	var gear: Dictionary = a.get("gear", {})
	var hat := has(a, "hat") or gear.has("head")
	var helm := String(a.get("armor_model", "")) != ""
	if m._parts.has("hem") and String(a.get("armor_model", "")) == "":
		var long := int(a.outfit) in [2, 5]
		m.part(r.torso, "hem", Vector3(0, -2.5 if long else -1.0, 0))
	if int(a.outfit) == 3:
		m.part(r.arm_l, "pauldron", Vector3(0.5, 0.3, 0))
		m.part(r.arm_r, "pauldron", Vector3(-0.5, 0.3, 0))
	# hair
	match style:
		1:
			if not hat and not helm:
				for s in [[-2.2, 8.6, 1.0, -20, 10], [0.5, 8.9, 0.5, 5, -8], [2.6, 8.5, -1.0, 15, 20], [-0.8, 8.4, -2.4, -30, 0]]:
					m.part(r.head, "hair_bit", Vector3(s[0], s[1], s[2]), Vector3(s[3], 0, s[4]))
		2:
			if not hat and not helm:
				m.part(r.head, "hair_bit", Vector3(0.5, 8.8, 1.0), Vector3(-25, 0, 12))
		3:
			for s in [-1.0, 1.0]:
				m.part(r.head, "hair_side", Vector3(s * 4.5, 4.5, 0))
		4:
			for s in [-1.0, 1.0]:
				m.part(r.head, "hair_side", Vector3(s * 4.5, 4.5, 0))
			m.part(r.head, "hair_back", Vector3(0, 2.0, -4.5))
		5:
			m.part(r.head, "tie", Vector3(0, 5.2, -4.4))
			var t := m.part(r.head, "tail", Vector3(0, 1.4, -5.4), Vector3(-18, 0, 0))
			t.position.z = -5.2 * PX
		6:
			for s in [-1.0, 1.0]:
				m.part(r.head, "tie", Vector3(s * 4.4, 5.5, -2.0))
				m.part(r.head, "tail", Vector3(s * 5.0, 1.8, -2.2), Vector3(0, 0, s * 10))
		8:
			if not hat and not helm:
				m.part(r.head, "bun", Vector3(0, 8.8, -2.0))
	# accessories
	if has(a, "cape") and not gear.has("garment"):
		m.part(r.torso, "cape", Vector3(0, 4.6, -2.6), Vector3(8, 0, 0))
		for s in [-1.0, 1.0]:
			m.part(r.torso, "clasp", Vector3(s * 3.0, 11.0, 2.2))
	if has(a, "scarf") and not gear.has("garment"):
		m.part(r.torso, "scarf", Vector3(0, 11.6, 0))
		m.part(r.torso, "scarf_end", Vector3(1.8, 8.6, 2.6), Vector3(0, 0, 8))
	if has(a, "satchel"):
		m.part(r.torso, "strap", Vector3(0, 6.0, 2.15), Vector3(0, 0, 38))
		m.part(r.torso, "strap", Vector3(0, 6.0, -2.15), Vector3(0, 0, -38))
		m.part(r.torso, "bag", Vector3(4.6, 1.0, 0.5))
	if has(a, "glasses"):
		m.part(r.head, "glasses", Vector3(0, 3.7, 4.3))
	if has(a, "headband"):
		m.part(r.head, "headband", Vector3(0, 6.0, 0))
		m.part(r.head, "knot", Vector3(1.2, 5.0, -4.6), Vector3(0, 0, -20))
	if has(a, "elf_ears"):
		for s in [-1.0, 1.0]:
			m.part(r.head, "ear", Vector3(s * 4.5, 4.0, 0.5), Vector3(0, 0, -s * 35))
			m.part(r.head, "ear_tip", Vector3(s * 5.6, 5.7, 0.5), Vector3(0, 0, -s * 55))
	if has(a, "flower"):
		m.part(r.head, "flower", Vector3(-3.0, 7.0, 4.2))
	_place_gear(m, r, a)
	if hat and not gear.has("head"):
		m.part(r.head, "hat_brim", Vector3(0, 8.3, 0))
		m.part(r.head, "hat_top", Vector3(0, 10.6, 0))
		m.part(r.head, "feather", Vector3(3.2, 11.5, -1.5), Vector3(0, 0, -25))
	if female:
		root.scale = Vector3(0.97, 0.97, 0.97)
	if with_weapon:
		r.weapon = attach_weapon(r, String(a.get("job", "swordsman")), String(a.get("weapon_sprite", "")), String(a.get("weapon_pal", "")), String(a.get("weapon_model", "")))
	if String(a.get("armor_model", "")) != "":
		attach_armor_set(r, String(a.armor_model))
	if String(a.get("wings", "")) != "":
		attach_wings(r, String(a.wings))
	apply_glow(root, r, a)
	if a.get("fashion", "") == "forest_mage" and a.get("job", "") == "mage":
		preload("res://scripts/voxel/forest_mage_fashion.gd").apply(root, r, with_weapon)
	elif preload("res://scripts/voxel/spectre_fashion.gd").is_spectre(String(a.get("fashion", ""))):
		preload("res://scripts/voxel/spectre_fashion.gd").apply(root, r, String(a.fashion))
	preload("res://scripts/characters/cape_flow.gd").install(root)
	return r


# ------------------------------------------------------------------ 3D gear models (arcane_mage_set_360.blend)
## Models are exported in metres with their origin at the grip / joint, so they
## drop straight onto the rig. Their flat Blender colours are redrawn by the HD
## shader below: 1/64-block sub-pixel grain, a soft top light and ink-dark facets,
## so they match the block models.
static var _glb := {}
static var _glb_mats := {}
static var _glb_shader: Shader
static var _glow_shader: Shader

const GLB_SHADER := """
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec3 emission : source_color = vec3(0.0);
uniform float cell = 0.01375;
varying vec3 lp;
varying vec3 ln;
float hash(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void vertex() {
	lp = VERTEX;
	ln = NORMAL;
}
void fragment() {
	vec3 an = abs(ln);
	vec3 q = floor(lp / cell + 0.001 * ln);
	if (an.x >= an.y && an.x >= an.z) { q.x = 0.0; } else if (an.y >= an.z) { q.y = 0.0; } else { q.z = 0.0; }
	float h = hash(q);
	vec3 c = albedo.rgb * (0.955 + 0.09 * h);
	// facets that turn away from the light read a step darker, like painted pixel shading
	c *= ln.y > 0.6 ? 1.06 : (ln.y < -0.6 ? 0.8 : 0.95);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	EMISSION = emission * (0.9 + 0.2 * h);
}
"""


static func _hd_mat(src: Material) -> Material:
	if not src is BaseMaterial3D:
		return src
	if _glb_mats.has(src):
		return _glb_mats[src]
	if _glb_shader == null:
		_glb_shader = Shader.new()
		_glb_shader.code = GLB_SHADER
	var b := src as BaseMaterial3D
	var m := ShaderMaterial.new()
	m.shader = _glb_shader
	# Blender colours are linear; the shader takes sRGB (source_color)
	m.set_shader_parameter("albedo", b.albedo_color)
	var e := Color(0, 0, 0)
	if b.emission_enabled:
		e = b.emission * minf(b.emission_energy_multiplier, 1.2) * 0.6
	m.set_shader_parameter("emission", e)
	_glb_mats[src] = m
	return m


## Seven Arcane Bows (seven_pixel_bows_64_360.blend): already solid 1/64 voxels with
## 64x64 nearest textures, so they keep their own materials (no HD repaint).
const VOXEL_MODELS := ["aureate_seraph_bow", "frost_crescent_bow", "verdant_ruby_bow", "crimson_thorn_bow",
	"obsidian_dragon_bow", "astral_silver_bow", "aether_cyan_bow",
	# Fourteen Celestial Staves (celestial_staves_14_64_360.blend)
	"violet_moon_staff", "astral_star_staff", "azure_orb_staff", "jade_enchanter_staff", "verdant_crescent_staff", "solar_wand",
	"rose_compass_staff", "midnight_fleur_staff", "ivory_moonwing_staff", "sapphire_lotus_staff", "lunar_familiar_staff",
	"frost_diadem_staff", "amber_starfall_staff", "ruby_eclipse_staff"]


static func _voxel_mat(src: Material) -> Material:
	if not src is BaseMaterial3D:
		return src
	var key := "vx_%d" % src.get_instance_id()
	if _glb_mats.has(key):
		return _glb_mats[key]
	var m := (src as BaseMaterial3D).duplicate() as BaseMaterial3D
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.metallic = 0.0
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if m.emission_enabled:
		m.emission_energy_multiplier = minf(m.emission_energy_multiplier, 0.5)
	_glb_mats[key] = m
	return m


static func glb_model(id: String) -> Node3D:
	if id == "":
		return null
	if not _glb.has(id):
		var path := "res://assets/models/arcane/%s.glb" % id
		_glb[id] = load(path) if ResourceLoader.exists(path) else null
	var ps: PackedScene = _glb[id]
	if ps == null:
		return null
	var n := ps.instantiate() as Node3D
	n.name = id
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mm := mi as MeshInstance3D
		mm.set_meta("glb", true)
		mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var voxel := id in VOXEL_MODELS or id.begins_with("reforged_")
		for i in mm.mesh.get_surface_count():
			var sm := mm.mesh.surface_get_material(i)
			mm.set_surface_override_material(i, _voxel_mat(sm) if voxel else _hd_mat(sm))
	return n


static func glow_overlay(c: Color, lv: int) -> ShaderMaterial:
	if _glow_shader == null:
		_glow_shader = Shader.new()
		_glow_shader.code = "shader_type spatial;\nrender_mode unshaded, blend_add, depth_draw_never, shadows_disabled;\nuniform vec4 col : source_color;\nvoid fragment() { ALBEDO = col.rgb * (0.75 + 0.25 * sin(TIME * 3.0)); }"
	var m := ShaderMaterial.new()
	m.shader = _glow_shader
	m.set_shader_parameter("col", c * (0.06 + lv * 0.025))
	return m


## Full armour set: one model per body part, parented to the matching joint.
static func attach_armor_set(r: Dictionary, set_id: String) -> void:
	for part in [["head", "head"], ["torso", "torso"], ["arm_l", "arm_l"], ["arm_r", "arm_r"], ["leg_l", "leg_l"], ["leg_r", "leg_r"]]:
		var n := glb_model("%s_armor_%s" % [set_id, part[0]])
		if n and r.has(part[1]):
			(r[part[1]] as Node3D).add_child(n)


# ------------------------------------------------------------------ wyvern wings (models from wyvern_six_wings_animated.blend)
const WING_KINDS := ["lightning", "ancient", "abyssal", "frozen", "fire", "poison"]
static var _wing_scenes := {}


static func wing_scene(kind: String) -> PackedScene:
	if not _wing_scenes.has(kind):
		var path := "res://assets/models/wings/wings_%s.glb" % kind
		_wing_scenes[kind] = load(path) if ResourceLoader.exists(path) else null
	return _wing_scenes[kind]


## Wings on the back, between the shoulder blades. Animations: flap / glide / fold.
static func attach_wings(r: Dictionary, kind: String) -> void:
	var ps := wing_scene(kind)
	if ps == null:
		return
	var holder := Node3D.new()
	holder.name = "Wings"
	(r.torso as Node3D).add_child(holder)
	holder.position = Vector3(0, 9.0, -2.6) * PX
	holder.rotation_degrees = Vector3(-12, 180, 0)
	holder.scale = Vector3.ONE * 0.36
	var w := ps.instantiate()
	holder.add_child(w)
	for gi in w.find_children("*", "GeometryInstance3D", true, false):
		(gi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var ap := w.find_children("*", "AnimationPlayer", true, false)
	if ap.size() > 0:
		var player := ap[0] as AnimationPlayer
		for n in ["flap", "glide"]:
			if player.has_animation(n):
				player.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if player.has_animation("glide"):
			player.play("glide")
		r.wing_player = player
	r.wings = holder


# ------------------------------------------------------------------ weapons
const SPRITES := {
	"iron_sword": {"px": 0.036, "grip": Vector2(4.5, 17.5), "rows": [
		"...kkk...", "..kWWLk..", "..kWLSk..", "..kWLSk..", "..kWLSk..", "..kWLSk..", "..kWLSk..",
		"..kWLSk..", "..kWLSk..", "..kWLSk..", "..kWLSk..", "..kWLSk..", "..kWLSk..",
		"kkkkkkkkk", "kGgGgGgGk", "kkkkkkkkk", "...kBk...", "...kbk...", "...kBk...", "...kbk...",
		"..kkkkk..", "..kGgGk..", "..kkkkk.."],
		"pal": {"k": Color(0.16, 0.16, 0.17), "W": Color(0.97, 0.97, 0.97), "L": Color(0.8, 0.8, 0.82), "S": Color(0.9, 0.9, 0.92),
			"G": Color(0.52, 0.52, 0.55), "g": Color(0.36, 0.36, 0.38), "B": Color(0.47, 0.33, 0.14), "b": Color(0.3, 0.2, 0.08)}},
	"sword": {"rows": VoxelSprite.CRYSTAL_SWORD, "pal": VoxelSprite.CRYSTAL_PALETTE, "px": 0.038, "grip": Vector2(7.5, 21.0)},
	"staff": {"px": 0.04, "grip": Vector2(3.5, 17.0), "rows": [
		"...LC...", "..LCCD..", ".LCCCCD.", ".CCCCCD.", "..CCDD..", ".G.CD.G.", ".GG..GG.", "..GGGG..",
		"...WW...", "...Ww...", "...WW...", "...Ww...", "...WW...", "...Ww...", "...WW...", "..KKKK..",
		"...RR...", "...rR...", "...RR...", "..KKKK..", "...WW...", "...Ww...", "...WW...", "...Ww...",
		"...WW...", "...Ww...", "...WW...", "...GG..."],
		"pal": {"L": Color(0.95, 0.75, 1.0), "C": Color(0.7, 0.4, 1.0), "D": Color(0.45, 0.2, 0.75), "G": Color(0.92, 0.72, 0.25),
			"W": Color(0.55, 0.36, 0.2), "w": Color(0.42, 0.27, 0.15), "K": Color(0.25, 0.2, 0.18), "R": Color(0.62, 0.15, 0.2), "r": Color(0.45, 0.1, 0.14)}},
	"mace": {"px": 0.036, "grip": Vector2(3.5, 13.0), "rows": [
		"..S..S..", ".SGGGGS.", "SGGLGGGS", ".GGLGGG.", ".GGGGGG.", "SGGGGGGS", ".SGGGGS.", "...KK...",
		"...WW...", "...Ww...", "...WW...", "..KKKK..", "...RR...", "...rR...", "...RR...", "..KKKK..", "...GG..."],
		"pal": {"S": Color(0.85, 0.87, 0.92), "G": Color(0.86, 0.68, 0.26), "L": Color(1.0, 0.92, 0.6), "K": Color(0.25, 0.22, 0.2),
			"W": Color(0.55, 0.36, 0.2), "w": Color(0.42, 0.27, 0.15), "R": Color(0.25, 0.3, 0.6), "r": Color(0.18, 0.22, 0.45)}},
	"axe": {"px": 0.048, "grip": Vector2(7.5, 13.0), "rows": [
		"..DDD.....", ".DLLCD....", "DLLLCCDKK.", "DLLCCCCKW.", "DLLCCCCKW.", "DLLLCCDKK.", ".DLLCD.Ww.", "..DDD..WW.",
		".......Ww.", ".......WW.", ".......Ww.", "......KKKK", ".......RR.", ".......rR.", ".......RR.", "......KKKK"],
		"pal": {"L": Color(0.9, 0.92, 0.95), "C": Color(0.7, 0.72, 0.78), "D": Color(0.42, 0.44, 0.5), "K": Color(0.25, 0.22, 0.2),
			"W": Color(0.58, 0.38, 0.2), "w": Color(0.44, 0.28, 0.15), "R": Color(0.62, 0.2, 0.18), "r": Color(0.45, 0.13, 0.12)}},
	"dagger": {"px": 0.032, "grip": Vector2(3.0, 10.0), "rows": [
		"...L...", "..LCD..", "..LCD..", "..LCD..", "..LCD..", "..LCD..", "..LCD..", "KKGGGKK", ".K.W.K.", "...w...", "...W...", "...w...", "..GGG.."],
		"pal": {"L": Color(0.92, 0.94, 0.98), "C": Color(0.72, 0.75, 0.82), "D": Color(0.45, 0.48, 0.55), "K": Color(0.22, 0.2, 0.22),
			"G": Color(0.86, 0.68, 0.26), "W": Color(0.35, 0.2, 0.3), "w": Color(0.25, 0.14, 0.22)}},
	"spear": {"px": 0.04, "grip": Vector2(3.0, 22.0), "rows": [
		"...L...", "..LCD..", "..LCD..", ".LCCCD.", "..LCD..", "...C...", ".KKGKK.", "...W...", "...w...", "...W...", "...w...",
		"...W...", "...w...", "...W...", "...w...", "...W...", "...w...", "..KKK..", "...R...", "...r...", "...R...",
		"..KKK..", "...W...", "...w...", "...W...", "...w...", "...W...", "...K..."],
		"pal": {"L": Color(0.92, 0.94, 0.98), "C": Color(0.72, 0.75, 0.82), "D": Color(0.45, 0.48, 0.55), "K": Color(0.25, 0.22, 0.2),
			"G": Color(0.86, 0.68, 0.26), "W": Color(0.58, 0.4, 0.22), "w": Color(0.44, 0.3, 0.16), "R": Color(0.62, 0.18, 0.18), "r": Color(0.45, 0.12, 0.12)}},
	"greatsword": {"px": 0.042, "grip": Vector2(5.0, 23.0), "rows": [
		"....kk....", "...kWLk...", "..kWWLSk..", "..kWLLSk..", "..kWLLSk..", "..kWLLSk..", "..kWLLSk..", "..kWLLSk..",
		"..kWLLSk..", "..kWLLSk..", "..kWLLSk..", "..kWLLSk..", "..kWLLSk..", "..kWLLSk..", "..kWLLSk..", "..kWLLSk..",
		"kkkkkkkkkk", "kGgGgGgGgk", "kkkkkkkkkk", "....kBk...", "....kbk...", "....kBk...", "....kbk...", "....kBk...",
		"....kbk...", "...kkkk...", "...kGgk...", "...kkkk..."],
		"pal": {"k": Color(0.16, 0.16, 0.17), "W": Color(0.97, 0.97, 0.97), "L": Color(0.8, 0.8, 0.82), "S": Color(0.9, 0.9, 0.92),
			"G": Color(0.52, 0.52, 0.55), "g": Color(0.36, 0.36, 0.38), "B": Color(0.47, 0.33, 0.14), "b": Color(0.3, 0.2, 0.08)}},
	"katar": {"px": 0.034, "grip": Vector2(4.0, 13.0), "rows": [
		".L.....L.", ".LC...LC.", ".LC...LC.", ".LCD.LCD.", ".LCD.LCD.", "..LCDLCD.", "..LCCCD..", "..LCCCD..",
		"...LCD...", "KKKGGGKKK", "K.......K", "K..WWW..K", "K..wWw..K", "K.......K", "KKKKKKKKK"],
		"pal": {"L": Color(0.92, 0.94, 0.98), "C": Color(0.72, 0.75, 0.82), "D": Color(0.45, 0.48, 0.55), "K": Color(0.3, 0.27, 0.25),
			"G": Color(0.86, 0.68, 0.26), "W": Color(0.4, 0.25, 0.18), "w": Color(0.3, 0.18, 0.12)}},
	"knuckle": {"px": 0.03, "grip": Vector2(4.0, 6.0), "rows": [
		".S.S.S.S.", "SGSGSGSGS", "GGGGGGGGG", "GLLLLLLLG", "GWWWWWWWG", "GwWwWwWwG", "GWWWWWWWG", ".GGGGGGG."],
		"pal": {"S": Color(0.9, 0.92, 0.96), "G": Color(0.55, 0.55, 0.6), "L": Color(0.75, 0.75, 0.8), "W": Color(0.5, 0.33, 0.2), "w": Color(0.38, 0.24, 0.14)}},
	"book": {"px": 0.034, "grip": Vector2(5.0, 12.0), "rows": [
		"KKKKKKKKKK", "KCCCCCCCPK", "KCGGGGGCPK", "KCGLLLGCPK", "KCGLDLGCPK", "KCGLLLGCPK", "KCGGGGGCPK",
		"KCCCCCCCPK", "KCCCCCCCPK", "KCCGGGCCPK", "KCCCCCCCPK", "KKKKKKKKKK"],
		"pal": {"K": Color(0.22, 0.14, 0.1), "C": Color(0.55, 0.2, 0.18), "G": Color(0.92, 0.75, 0.3), "L": Color(1.0, 0.92, 0.6),
			"D": Color(0.7, 0.4, 1.0), "P": Color(0.95, 0.92, 0.82)}},
	"whip": {"px": 0.034, "grip": Vector2(5.0, 19.0), "rows": [
		"...B......", "..Bb......", "..b.......", ".Bb.......", ".b........", ".Bb.......", "..bB......", "...bB.....",
		"....bB....", ".....bB...", ".....bB...", "....Bb....", "...Bb.....", "...bB.....", "....bB....", "....KK....",
		"....WW....", "....Ww....", "....WW....", "....Ww....", "....KK...."],
		"pal": {"B": Color(0.5, 0.32, 0.18), "b": Color(0.36, 0.22, 0.12), "K": Color(0.86, 0.68, 0.26),
			"W": Color(0.3, 0.2, 0.14), "w": Color(0.22, 0.14, 0.1)}},
	"lute": {"px": 0.036, "grip": Vector2(4.5, 14.0), "rows": [
		"...KKK...", "...KWK...", "....W....", "....w....", "....W....", "....w....", "....W....", "...WSW...",
		"..WWSWW..", ".WWWSWWW.", ".WWKSKWW.", "WWWKKKWWW", "WWWWSWWWW", "WWWWSWWWW", ".WWWSWWW.", ".wWWGWWw.", "..wwwww.."],
		"pal": {"K": Color(0.2, 0.14, 0.1), "W": Color(0.78, 0.52, 0.26), "w": Color(0.58, 0.36, 0.17),
			"S": Color(0.92, 0.92, 0.95), "G": Color(0.86, 0.68, 0.26)}},
}


static func _bow_rows() -> Array:
	var rows := []
	var H := 25
	for y in H:
		var bend := int(round(sin(float(y) / (H - 1) * PI) * 4.0))
		var row := ""
		for x in 8:
			var c := "."
			if x == 1 + bend:
				c = "R" if y >= 10 and y <= 14 else ("K" if y == 0 or y == H - 1 else "B")
			elif x == 2 + bend and y > 2 and y < H - 3:
				c = "R" if y >= 10 and y <= 14 else "b"
			elif x == 1:
				c = "T"
			row += c
		rows.append(row)
	return rows


## Colour variants of the base weapon sprites (region weapons).
const PAL_VARIANTS := {
	"jade": {"W": Color(0.75, 1.0, 0.85), "L": Color(0.3, 0.75, 0.5), "S": Color(0.5, 0.9, 0.68), "G": Color(0.85, 0.7, 0.25),
		"g": Color(0.6, 0.45, 0.15), "B": Color(0.2, 0.35, 0.25), "b": Color(0.12, 0.22, 0.15)},
	"sun": {"W": Color(1.0, 0.95, 0.7), "L": Color(0.95, 0.72, 0.25), "S": Color(1.0, 0.85, 0.45), "G": Color(0.25, 0.4, 0.8),
		"g": Color(0.15, 0.25, 0.6), "B": Color(0.6, 0.15, 0.15), "b": Color(0.4, 0.1, 0.1)},
	"inferno": {"W": Color(1.0, 0.85, 0.4), "L": Color(0.85, 0.15, 0.08), "S": Color(1.0, 0.45, 0.1), "k": Color(0.15, 0.05, 0.05),
		"G": Color(0.3, 0.22, 0.22), "g": Color(0.2, 0.14, 0.14), "B": Color(0.12, 0.08, 0.08), "b": Color(0.08, 0.05, 0.05)},
	"druid": {"L": Color(0.75, 1.0, 0.75), "C": Color(0.3, 0.85, 0.4), "D": Color(0.15, 0.5, 0.25), "W": Color(0.4, 0.3, 0.18),
		"w": Color(0.3, 0.22, 0.12), "G": Color(0.35, 0.6, 0.25)},
	"magma": {"L": Color(1.0, 0.9, 0.4), "C": Color(1.0, 0.45, 0.1), "D": Color(0.7, 0.15, 0.05), "W": Color(0.15, 0.12, 0.14),
		"w": Color(0.1, 0.08, 0.1), "G": Color(0.6, 0.3, 0.1)},
	"vine": {"B": Color(0.3, 0.55, 0.25), "b": Color(0.2, 0.4, 0.18), "T": Color(0.6, 0.85, 0.4), "R": Color(0.95, 0.5, 0.6)},
	"phoenix": {"B": Color(0.95, 0.45, 0.12), "b": Color(0.75, 0.25, 0.08), "T": Color(1.0, 0.9, 0.5), "R": Color(1.0, 0.85, 0.3)},
	"frost": {"L": Color(0.9, 0.97, 1.0), "C": Color(0.55, 0.8, 1.0), "D": Color(0.3, 0.5, 0.85), "W": Color(0.45, 0.5, 0.6),
		"w": Color(0.35, 0.4, 0.5), "R": Color(0.4, 0.75, 1.0), "r": Color(0.3, 0.55, 0.85), "S": Color(0.9, 0.97, 1.0), "G": Color(0.55, 0.8, 1.0)},
	"scorpion": {"L": Color(0.9, 0.6, 0.5), "C": Color(0.6, 0.15, 0.12), "D": Color(0.35, 0.08, 0.06), "G": Color(0.95, 0.75, 0.25),
		"W": Color(0.2, 0.1, 0.1), "w": Color(0.12, 0.06, 0.06)},
}


static func sprite_pal(kind: String, pal: String) -> Dictionary:
	var s := sprite(kind)
	if pal == "" or not PAL_VARIANTS.has(pal):
		return s
	var d := s.duplicate()
	var p: Dictionary = (s.pal as Dictionary).duplicate()
	p.merge(PAL_VARIANTS[pal], true)
	d.pal = p
	return d


static func sprite(kind: String) -> Dictionary:
	if kind == "bow":
		return {"rows": _bow_rows(), "px": 0.04, "grip": Vector2(5.5, 12.5),
			"pal": {"B": Color(0.62, 0.4, 0.2), "b": Color(0.45, 0.28, 0.14), "K": Color(0.25, 0.22, 0.2),
				"T": Color(0.92, 0.9, 0.85), "R": Color(0.65, 0.18, 0.18)}}
	return SPRITES.get(kind, SPRITES.sword)


static func weapon_mesh(kind: String, pal := "") -> ArrayMesh:
	var s := sprite_pal(kind, pal)
	return VoxelSprite.extrude(s.rows, s.pal, s.px, s.grip)


## 16x16-ish pixel icon of a weapon sprite (fit into `size` px, transparent background).
static func weapon_image(kind: String, size := 16) -> Image:
	var s := sprite(kind)
	var rows: Array = s.rows
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var dim := maxi(w, h)
	var img := Image.create(dim, dim, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ox := (dim - w) / 2
	var oy := (dim - h) / 2
	for y in h:
		var r: String = rows[y]
		for x in r.length():
			if r[x] != ".":
				img.set_pixel(ox + x, oy + y, s.pal.get(r[x], Color.MAGENTA))
	if dim != size:
		img.resize(size, size, Image.INTERPOLATE_NEAREST)
	return img


static func attach_weapon(r: Dictionary, job_id: String, override := "", pal := "", model := "") -> Node3D:
	var j := job(job_id)
	var kind: String = override if override != "" else j.sprite
	var holder := Node3D.new()
	holder.name = "Weapon"
	if kind == "none":
		r.arm_r.add_child(holder)
		return holder
	var visual_model := model
	if kind == "axe" and visual_model == "":visual_model="reforged_frost_axe" if pal=="frost" else "reforged_hand_axe"
	var mi: Node3D = glb_model(visual_model) if visual_model != "" else null
	if kind in ["sword", "iron_sword"] and visual_model=="":mi=TownAssets.instance("basic_iron_sword")
	if mi == null:
		var vm := MeshInstance3D.new()
		vm.mesh = weapon_mesh(kind, pal)
		vm.material_override = VoxelSprite.material()
		mi = vm
	holder.add_child(mi)
	match kind:
		"bow":
			r.arm_l.add_child(holder)
			holder.position = Vector3(0, -9.5, 0.4) * PX
			holder.rotation_degrees = Vector3(90, 0, 0)
			mi.rotation_degrees = Vector3(0, 0, 0)
		"staff", "spear":
			r.arm_r.add_child(holder)
			holder.position = Vector3(0, -9.5, 2.2) * PX
			holder.rotation_degrees = Vector3(0, 0, 0)
			mi.rotation_degrees = Vector3(0, 90, 0)
		"knuckle":
			r.arm_r.add_child(holder)
			holder.position = Vector3(0, -10.5, 0.6) * PX
			holder.rotation_degrees = Vector3(90, 0, 0)
			mi.rotation_degrees = Vector3(0, 90, 0)
		"book":
			r.arm_r.add_child(holder)
			holder.position = Vector3(0, -9.6, 1.4) * PX
			holder.rotation_degrees = Vector3(10, 0, 0)
			mi.rotation_degrees = Vector3(0, 90, 0)
		_:
			r.arm_r.add_child(holder)
			holder.position = Vector3(0, -9.2, 0.6) * PX
			holder.rotation_degrees = Vector3(70, 0, 0)
			mi.rotation_degrees = Vector3(0, 90, 0)
	return holder


# ------------------------------------------------------------------ equipment look
## Appearance with the equipped gear applied (armour outfit, headgear, cape,
## gloves, boots, shield, weapon sprite and refine glow).
static func dress(a: Dictionary, equip: Dictionary, refine: Dictionary) -> Dictionary:
	var d := a.duplicate(true)
	var gear := {}
	var w: String = equip.get("weapon", "")
	d.weapon_sprite = Items.info(w).get("sprite", "") if w != "" else "none"
	d.weapon_pal = String(Items.info(w).get("pal", "")) if w != "" else ""
	d.weapon_model = String(Items.info(w).get("model", "")) if w != "" else ""
	d.glow_w = int(refine.get(w, 0)) if w != "" else 0
	d.refine_slots = {}
	for slot in Items.SLOTS:
		var item: String = equip.get(slot, "")
		d.refine_slots[slot] = int(refine.get(item, 0)) if item != "" else 0
	var glow_a := 0
	for slot in ["shield", "head", "armor", "garment", "gloves", "boots"]:
		var id: String = equip.get(slot, "")
		if id == "":
			continue
		glow_a = maxi(glow_a, int(refine.get(id, 0)))
		var look: Dictionary = Items.info(id).get("look", {})
		if slot == "armor":
			if look.has("model_set"):
				d.armor_model = String(look.model_set)
				d.outfit = 7          # dark undersuit so nothing bright peeks between plates
				d.outfit_color = 3
				continue
			if look.has("outfit"):
				d.outfit = int(look.outfit)
				d.outfit_color = int(look.color)
			continue
		if look.is_empty() and slot != "shield":
			continue
		if slot == "garment" and look.has("wings"):
			d.wings = String(look.wings)      # Wyvern wings replace the cape
			continue
		gear[slot] = look.duplicate()
	d.gear = gear
	d.glow_a = glow_a
	return d


static func _add_gear_parts(m: BoxModel, a: Dictionary) -> void:
	var gear: Dictionary = a.get("gear", {})
	if gear.has("head"):
		var g: Dictionary = gear.head
		var c: Color = g.get("color", Color(0.6, 0.6, 0.65))
		var shade := func(base: Color, seed: int) -> Callable:
			return func(f, u, v, w, h) -> Color:
				if f == TP:
					return n(base.lightened(0.12), u, v, seed)
				if f == BT:
					return base.darkened(0.35)
				return n(base.darkened(0.12) if v == h - 1 else base, u, v, seed)
		match String(g.get("kind", "cap")):
			"cap", "bonnet":
				m.add("g_cap", Vector3i(9, 3, 9), shade.call(c, 80))
				m.add("g_brim", Vector3i(9, 1, 3), shade.call(c.darkened(0.15), 81))
			"helm":
				m.add("g_helm", Vector3i(10, 5, 10), func(f, u, v, w, h) -> Color:
					if f == TP:
						return n(c.lightened(0.18) if u == 4 or u == 5 else c.lightened(0.08), u, v, 82)
					if v == h - 1:
						return c.darkened(0.25)
					return n(c.lightened(0.2) if v == 0 else c, u, v, 83))
				m.add("g_crest", Vector3i(1, 2, 8), BoxModel.flat(Color(0.75, 0.18, 0.16), 84))
				m.add("g_guard", Vector3i(1, 4, 4), shade.call(c.darkened(0.08), 85))
			"wizard":
				m.add("g_brim", Vector3i(13, 1, 13), shade.call(c.darkened(0.1), 86))
				m.add("g_cone1", Vector3i(8, 3, 8), func(f, u, v, w, h) -> Color:
					return Color(0.95, 0.78, 0.3) if v == h - 1 and f != TP and f != BT else n(c, u, v, 87))
				m.add("g_cone2", Vector3i(6, 3, 6), shade.call(c, 88))
				m.add("g_cone3", Vector3i(4, 3, 4), shade.call(c.lightened(0.05), 89))
				m.add("g_cone4", Vector3i(2, 3, 2), shade.call(c.lightened(0.1), 90))
				m.add("g_star", Vector3i(2, 2, 1), BoxModel.flat(Color(1.0, 0.9, 0.4), 91))
			"crown":
				m.add("g_ring", Vector3i(9, 2, 9), func(f, u, v, w, h) -> Color:
					if f == TP or f == BT:
						return Color(0, 0, 0, 0) if u > 0 and u < w - 1 and v > 0 and v < h - 1 else c
					return Color(0.85, 0.15, 0.25) if u == 4 and v == 1 else n(c, u, v, 92))
				m.add("g_spike", Vector3i(1, 2, 1), BoxModel.flat(c.lightened(0.1), 93))
	if gear.has("garment"):
		var gc: Color = gear.garment.get("color", Color(0.6, 0.2, 0.2))
		if String(gear.garment.get("kind", "cape")) == "scarf":
			m.add("g_scarf", Vector3i(9, 2, 5), func(f, u, v, w, h): return n(gc.lightened(0.06) if v == 0 else gc, u, v, 94))
			m.add("g_scarf_end", Vector3i(2, 6, 1), func(f, u, v, w, h): return n(gc.darkened(0.1) if v == h - 1 else gc, u, v, 95))
		else:
			m.add("g_cape", Vector3i(9, 15, 1), func(f, u, v, w, h):
				if v == 0:
					return gc.darkened(0.3)
				if v == h - 1:
					return gc.darkened(0.2)
				return n(gc.darkened(0.15) if f == F else gc, u, v, 96))
			m.add("g_clasp", Vector3i(2, 2, 1), BoxModel.flat(GOLD, 97))
	if gear.has("gloves"):
		var lc: Color = gear.gloves.get("color", LEATHER)
		m.add("g_glove", Vector3i(5, 3, 5), func(f, u, v, w, h) -> Color:
			return lc.lightened(0.15) if v == 0 else n(lc, u, v, 98))
	if gear.has("boots"):
		var bc: Color = gear.boots.get("color", LEATHER_D)
		m.add("g_boot", Vector3i(5, 5, 5), func(f, u, v, w, h) -> Color:
			if v == 0:
				return bc.lightened(0.18)
			if v == h - 1 or f == BT:
				return bc.darkened(0.45)
			return n(bc, u, v, 99))
		m.add("g_toe", Vector3i(5, 2, 2), func(f, u, v, w, h) -> Color:
			return bc.darkened(0.45) if v == h - 1 or f == BT else n(bc, u, v, 100))


static func _place_gear(m: BoxModel, r: Dictionary, a: Dictionary) -> void:
	var gear: Dictionary = a.get("gear", {})
	if gear.has("head"):
		if gear.head.has("model"):
			var headgear:=TownAssets.instance(String(gear.head.model))
			if headgear:r.head.add_child(headgear)
		match String(gear.head.get("kind", "cap")):
			"cap":
				m.part(r.head, "g_cap", Vector3(0, 7.6, 0))
				m.part(r.head, "g_brim", Vector3(0, 6.6, 4.8))
			"bonnet":
				m.part(r.head, "g_cap", Vector3(0, 7.6, 0))
				m.part(r.head, "g_brim", Vector3(0, 6.6, 4.8))
				m.part(r.head, "feather", Vector3(3.6, 10.0, -1.5), Vector3(-15, 0, -30))
			"helm":
				m.part(r.head, "g_helm", Vector3(0, 6.6, 0))
				m.part(r.head, "g_crest", Vector3(0, 10.0, -0.5))
				for sx in [-1.0, 1.0]:
					m.part(r.head, "g_guard", Vector3(sx * 4.6, 3.2, 1.0))
			"wizard":
				m.part(r.head, "g_brim", Vector3(0, 8.4, 0))
				m.part(r.head, "g_cone1", Vector3(0, 10.4, 0))
				m.part(r.head, "g_cone2", Vector3(0, 13.2, -0.4), Vector3(-6, 0, 0))
				m.part(r.head, "g_cone3", Vector3(0, 15.8, -1.2), Vector3(-14, 0, 0))
				m.part(r.head, "g_cone4", Vector3(0, 18.0, -2.4), Vector3(-26, 0, 0))
				m.part(r.head, "g_star", Vector3(0, 10.6, 4.4))
			"crown":
				m.part(r.head, "g_ring", Vector3(0, 8.6, 0))
				for p in [Vector3(-4, 10.4, -4), Vector3(4, 10.4, -4), Vector3(-4, 10.4, 4), Vector3(4, 10.4, 4), Vector3(0, 10.6, 4), Vector3(0, 10.6, -4)]:
					m.part(r.head, "g_spike", p)
	if gear.has("garment"):
		if String(gear.garment.get("kind", "cape")) == "scarf":
			m.part(r.torso, "g_scarf", Vector3(0, 11.6, 0))
			m.part(r.torso, "g_scarf_end", Vector3(1.8, 8.3, 2.6), Vector3(0, 0, 8))
		else:
			m.part(r.torso, "g_cape", Vector3(0, 4.6, -2.7), Vector3(8, 0, 0))
			for sx in [-1.0, 1.0]:
				m.part(r.torso, "g_clasp", Vector3(sx * 3.0, 11.0, 2.3))
	if gear.has("gloves"):
		for arm in [r.arm_l, r.arm_r]:
			m.part(arm, "g_glove", Vector3(0, -8.6, 0))
	if gear.has("boots"):
		for leg in [r.leg_l, r.leg_r]:
			m.part(leg, "g_boot", Vector3(0, -9.6, 0))
			m.part(leg, "g_toe", Vector3(0, -11.1, 3.0))
	if gear.has("shield"):
		var sh := Node3D.new()
		sh.name = "Shield"
		r.arm_l.add_child(sh)
		sh.position = Vector3(2.7, -5.5, 0.6) * PX
		sh.rotation_degrees = Vector3(0, 90, 0)
		var gm: Node3D = glb_model(String(gear.shield.get("model", ""))) if gear.shield.has("model") else null
		if gm:
			sh.add_child(gm)
			sh.position = Vector3(2.9, -5.5, 0.4) * PX
		else:
			var mi := MeshInstance3D.new()
			var sp := shield_sprite(String(gear.shield.get("kind", "buckler")))
			mi.mesh = VoxelSprite.extrude(sp.rows, sp.pal, PX * 0.75, sp.grip, 0.65)
			mi.material_override = VoxelSprite.material()
			sh.add_child(mi)
		r.shield = sh


static func shield_sprite(kind: String) -> Dictionary:
	var rows := []
	var pal := {"k": Color(0.18, 0.16, 0.16), "W": Color(0.55, 0.36, 0.2), "w": Color(0.42, 0.27, 0.15),
		"M": Color(0.78, 0.8, 0.86), "m": Color(0.58, 0.6, 0.66), "B": Color(0.2, 0.32, 0.66), "G": Color(0.95, 0.76, 0.28),
		"R": Color(0.55, 0.16, 0.14)}
	match kind:
		"buckler":
			for y in 11:
				var row := ""
				for x in 11:
					var d := Vector2(x - 5, y - 5).length()
					row += "." if d > 5.4 else ("M" if d > 4.3 else ("G" if d < 1.5 else ("W" if (x + y) % 3 else "w")))
				rows.append(row)
			return {"rows": rows, "pal": pal, "grip": Vector2(5.5, 5.5)}
		"kite":
			for y in 15:
				var half := 6 if y < 7 else int(6 - (y - 7) * 0.8)
				var row := ""
				for x in 13:
					var dx := absi(x - 6)
					if dx > half:
						row += "."
					elif dx == half or y == 0:
						row += "M"
					elif (x == 6 and y > 2 and y < 12) or (y == 5 and dx < 4):
						row += "G"
					else:
						row += "B"
				rows.append(row)
			return {"rows": rows, "pal": pal, "grip": Vector2(6.5, 6.0)}
	for y in 17:
		var row := ""
		for x in 12:
			if y == 16 and (x < 3 or x > 8):
				row += "."
			elif x == 0 or x == 11 or y == 0 or y == 16:
				row += "m"
			elif (x == 2 or x == 9) and y % 5 == 2:
				row += "M"
			elif x == 5 or x == 6:
				row += "R"
			else:
				row += "M" if (x + y) % 7 else "m"
		rows.append(row)
	return {"rows": rows, "pal": pal, "grip": Vector2(6.0, 7.0)}


## Refine glow: the weapon shines brighter per refine level (+1..+10) and gains
## sparkles; refined armour adds a soft aura around the body from +5.
const GLOW_COLORS := [Color(0, 0, 0), Color(0.25, 0.45, 0.9), Color(0.3, 0.55, 1.0), Color(0.35, 0.65, 1.0),
	Color(0.45, 0.75, 1.0), Color(0.55, 0.9, 1.0), Color(0.7, 0.55, 1.0), Color(0.85, 0.5, 1.0),
	Color(1.0, 0.55, 0.85), Color(1.0, 0.75, 0.4), Color(1.0, 0.9, 0.45)]


static func glow_color(lv: int) -> Color:
	return GLOW_COLORS[clampi(lv, 0, 10)]


static func apply_glow(root: Node3D, r: Dictionary, a: Dictionary) -> void:
	preload("res://scripts/voxel/refine_visuals.gd").apply(root, r, a)


static func _sparkles(c: Color, amount: int, spread: float, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Glow"
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * size * 2.2
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bm.material = m
	p.mesh = bm
	p.amount = amount
	p.lifetime = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(spread * 0.15, spread, spread * 0.15)
	p.position = Vector3(0, spread * 0.9, 0)
	p.direction = Vector3.UP
	p.spread = 30.0
	p.gravity = Vector3(0, 0.4, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var g := Gradient.new()
	g.set_color(0, Color(c.lightened(0.5), 0.0))
	g.add_point(0.3, Color(c.lightened(0.3), 1.0))
	g.set_color(g.get_point_count() - 1, Color(c, 0.0))
	p.color_ramp = g
	p.local_coords = false
	return p
