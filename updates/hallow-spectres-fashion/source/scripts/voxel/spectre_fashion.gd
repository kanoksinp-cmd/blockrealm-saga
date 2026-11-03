extends RefCounted
## "Hallow Spectres" fashion sets (Halloween 2026). Original voxel designs drawn in code with
## the same BoxModel painter style as the base avatar. Any job can wear them.
## Visual only here; the stat bonus lives in Game.FASHIONS.

const F := BoxModel.FRONT
const BK := BoxModel.BACK
const SPX := BoxModel.SIDE_PX
const SNX := BoxModel.SIDE_NX
const TP := BoxModel.TOP
const BT := BoxModel.BOTTOM
const CLEAR := Color(0, 0, 0, 0)

const IDS := ["pumpkin_reaper", "bone_oracle", "hollow_scarecrow"]

static var _models := {}


static func n(c: Color, u: int, v: int, s: int, amt := 0.05) -> Color:
	return BoxModel.noise(c, u, v, s, amt)


static func is_spectre(id: String) -> bool:
	return id in IDS


## Hide the base body, hair, outfit and armour meshes, keep weapon / shield / wings,
## and put the fashion parts on the same rig pivots so every animation still works.
static func apply(root: Node3D, rig: Dictionary, id: String) -> void:
	if not is_spectre(id):
		return
	var keep: Array = []
	for k in ["weapon", "shield", "wings"]:
		if rig.has(k) and rig[k] is Node3D:
			keep.append(rig[k])
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		var hidden := true
		for k: Node3D in keep:
			if k == mesh or k.is_ancestor_of(mesh):
				hidden = false
				break
		if hidden:
			(mesh as MeshInstance3D).visible = false
	var m := model(id)
	match id:
		"pumpkin_reaper":_place_pumpkin_reaper(m, rig)
		"bone_oracle":_place_bone_oracle(m, rig)
		"hollow_scarecrow":_place_hollow_scarecrow(m, rig)


static func model(id: String) -> BoxModel:
	if _models.has(id):
		return _models[id]
	var m := BoxModel.new(Avatar.PX)
	match id:
		"pumpkin_reaper":_build_pumpkin_reaper(m)
		"bone_oracle":_build_bone_oracle(m)
		"hollow_scarecrow":_build_hollow_scarecrow(m)
	m.bake()
	_models[id] = m
	return m


# ======================================================================= Pumpkin Reaper
# Carved pumpkin helm, soot-black plate with ember seams, torn wine-red tabard and cape.
const PR_IRON := Color(0.16, 0.16, 0.19)
const PR_IRON_L := Color(0.27, 0.27, 0.31)
const PR_EMBER := Color(1.0, 0.55, 0.12)
const PR_WINE := Color(0.42, 0.07, 0.1)
const PR_PUMPKIN := Color(0.93, 0.47, 0.08)
const PR_PUMPKIN_D := Color(0.72, 0.31, 0.05)
const PR_FLAME := Color(1.0, 0.86, 0.3)


static func _build_pumpkin_reaper(m: BoxModel) -> void:
	m.add("pumpkin", Vector3i(10, 9, 10), func(f, u, v, w, h) -> Color:
		if f == TP:
			return n(PR_PUMPKIN_D, u, v, 201)
		if f == BT:
			return PR_PUMPKIN_D.darkened(0.3)
		var rib: bool = (u % 3) == 0
		var base: Color = PR_PUMPKIN_D if rib else PR_PUMPKIN
		if f == F:
			# triangle eyes, jagged grin; both glow like a candle inside
			if (v == 2 and (u == 2 or u == 7)) or (v == 3 and u in [1, 2, 3, 6, 7, 8]):
				return PR_FLAME
			if v == 4 and (u == 4 or u == 5):
				return PR_FLAME.darkened(0.1)
			if v == 5 and (u == 1 or u == 8):
				return PR_FLAME
			if v == 6 and u >= 1 and u <= 8 and u != 3 and u != 6:
				return PR_FLAME
			if v == 7 and u >= 2 and u <= 7:
				return PR_FLAME.darkened(0.08)
		return n(base, u, v, 202, 0.06))
	m.add("stem", Vector3i(2, 3, 2), func(f, u, v, w, h) -> Color: return n(Color(0.33, 0.4, 0.14).darkened(0.1 * v), u, v, 203))
	m.add("leaf", Vector3i(3, 1, 2), BoxModel.flat(Color(0.3, 0.52, 0.16), 204))
	m.add("body", Vector3i(8, 12, 4), func(f, u, v, w, h) -> Color:
		if v == 7:
			return PR_EMBER if f == F and (u == 3 or u == 4) else n(Color(0.24, 0.16, 0.1), u, v, 205)
		if f == F and v >= 1 and v <= 5 and (u == 3 or u == 4):
			return n(PR_EMBER.darkened(0.15), u, v, 206) if v % 2 == 1 else PR_IRON_L
		if f == F and v == 0:
			return PR_IRON_L
		return n(PR_IRON if (u + v) % 4 else PR_IRON_L, u, v, 207))
	m.add("arm", Vector3i(4, 12, 4), func(f, u, v, w, h) -> Color:
		if v == 0 or v == 4:
			return PR_EMBER.darkened(0.2) if f != TP else PR_IRON_L
		if v >= 9:
			return n(PR_IRON_L, u, v, 208)
		return n(PR_IRON, u, v, 209))
	m.add("leg", Vector3i(4, 12, 4), func(f, u, v, w, h) -> Color:
		if v >= 10:
			return n(Color(0.1, 0.1, 0.12), u, v, 210)
		if v == 5:
			return PR_EMBER.darkened(0.25)
		return n(PR_WINE.darkened(0.2) if v < 5 else PR_IRON, u, v, 211))
	m.add("pauldron", Vector3i(5, 4, 5), func(f, u, v, w, h) -> Color:
		if f == TP:
			return PR_EMBER if u == 2 and v == 2 else n(PR_IRON_L, u, v, 212)
		if v == h - 1:
			return PR_EMBER.darkened(0.3)
		return n(PR_IRON, u, v, 213))
	m.add("tabard", Vector3i(4, 9, 1), func(f, u, v, w, h) -> Color:
		if v == h - 1 and u % 2 == 1:
			return CLEAR
		if v == 1 and (u == 1 or u == 2):
			return PR_EMBER
		return n(PR_WINE, u, v, 214))
	m.add("cape", Vector3i(9, 15, 1), func(f, u, v, w, h) -> Color:
		# torn hem: a ragged, uneven bottom edge
		var cut: int = [1, 3, 0, 2, 4, 1, 3, 0, 2][u]
		if v >= h - cut:
			return CLEAR
		if v == 0:
			return PR_WINE.darkened(0.35)
		return n(PR_WINE.darkened(0.1) if f == F else PR_WINE, u, v, 215))


static func _place_pumpkin_reaper(m: BoxModel, r: Dictionary) -> void:
	_base_limbs(m, r)
	m.part(r.head, "pumpkin", Vector3(0, 4.4, 0))
	m.part(r.head, "stem", Vector3(0, 9.9, 0), Vector3(0, 0, 10))
	m.part(r.head, "leaf", Vector3(1.6, 9.2, 0.4), Vector3(0, 0, -20))
	m.part(r.torso, "body", Vector3(0, 6, 0))
	m.part(r.torso, "tabard", Vector3(0, 1.2, 2.3))
	m.part(r.torso, "cape", Vector3(0, 4.6, -2.6), Vector3(8, 0, 0))
	m.part(r.arm_l, "pauldron", Vector3(0.5, 0.3, 0))
	m.part(r.arm_r, "pauldron", Vector3(-0.5, 0.3, 0))


# ======================================================================= Bone Oracle
# Ram-horned skull mask, night-blue robe with a bone rib motif, pale-cyan soul lights.
const BO_BONE := Color(0.9, 0.87, 0.78)
const BO_BONE_D := Color(0.66, 0.62, 0.53)
const BO_ROBE := Color(0.11, 0.13, 0.28)
const BO_ROBE_D := Color(0.07, 0.08, 0.17)
const BO_SOUL := Color(0.45, 0.95, 1.0)
const BO_GOLD := Color(0.86, 0.67, 0.27)


static func _build_bone_oracle(m: BoxModel) -> void:
	m.add("skull", Vector3i(8, 8, 8), func(f, u, v, w, h) -> Color:
		if f == F:
			# hollow eye sockets with a soul light, nose notch, teeth row
			if v >= 2 and v <= 4 and (u in [1, 2, 5, 6]):
				return BO_SOUL if v == 3 and (u == 2 or u == 5) else Color(0.05, 0.05, 0.07)
			if v == 5 and (u == 3 or u == 4):
				return Color(0.12, 0.1, 0.1)
			if v == 7:
				return Color(0.12, 0.1, 0.1) if u % 2 == 0 else BO_BONE
		if f == TP:
			return n(BO_BONE, u, v, 221, 0.04)
		return n(BO_BONE_D if v >= 6 else BO_BONE, u, v, 222, 0.05))
	m.add("horn", Vector3i(2, 2, 2), func(f, u, v, w, h) -> Color: return n(BO_BONE_D.darkened(0.05 * u), u, v, 223))
	m.add("horn_tip", Vector3i(1, 1, 1), BoxModel.flat(BO_BONE_D.darkened(0.25), 224))
	m.add("hood", Vector3i(10, 6, 10), func(f, u, v, w, h) -> Color:
		if f == F and v >= 2:
			return CLEAR
		if f == BT:
			return CLEAR
		return n(BO_ROBE_D, u, v, 225))
	m.add("body", Vector3i(8, 12, 4), func(f, u, v, w, h) -> Color:
		if f == F:
			if v in [2, 4, 6] and u >= 1 and u <= 6:
				return n(BO_BONE, u, v, 226, 0.03)
			if v >= 1 and v <= 7 and (u == 3 or u == 4):
				return n(BO_BONE_D, u, v, 227, 0.03)
			if v == 8:
				return BO_GOLD if u == 3 or u == 4 else BO_ROBE_D
		if v == 8:
			return BO_ROBE_D
		return n(BO_ROBE, u, v, 228))
	m.add("arm", Vector3i(4, 12, 4), func(f, u, v, w, h) -> Color:
		if v >= 10:
			return n(BO_BONE, u, v, 229)
		if v == 9:
			return BO_GOLD.darkened(0.2)
		return n(BO_ROBE, u, v, 230))
	m.add("leg", Vector3i(4, 12, 4), func(f, u, v, w, h) -> Color: return n(BO_ROBE_D, u, v, 231))
	m.add("hem", Vector3i(9, 8, 5), func(f, u, v, w, h) -> Color:
		if f == TP or f == BT:
			return BO_ROBE_D
		if v == h - 1:
			return BO_SOUL.darkened(0.35) if u % 3 == 0 else BO_ROBE_D
		return n(BO_ROBE, u, v, 232))
	m.add("charm", Vector3i(2, 3, 1), func(f, u, v, w, h) -> Color: return BO_SOUL if v == 1 else BO_GOLD)


static func _place_bone_oracle(m: BoxModel, r: Dictionary) -> void:
	_base_limbs(m, r)
	m.part(r.head, "skull", Vector3(0, 4, 0))
	m.part(r.head, "hood", Vector3(0, 6.2, -0.6))
	# ram horns: curl back and down from the temples (each side mirrored)
	for s in [-1.0, 1.0]:
		var path := [[4.6, 7.0, 0.0], [6.0, 8.0, -1.2], [7.0, 7.4, -2.8], [7.2, 5.8, -3.6], [6.6, 4.4, -2.8], [6.0, 4.0, -1.4]]
		for i in path.size():
			var p: Array = path[i]
			m.part(r.head, "horn", Vector3(s * p[0], p[1], p[2]), Vector3(0, 0, -s * 15 * i))
		m.part(r.head, "horn_tip", Vector3(s * 5.6, 4.0, -0.2))
	m.part(r.torso, "body", Vector3(0, 6, 0))
	m.part(r.torso, "hem", Vector3(0, -2.5, 0))
	m.part(r.torso, "charm", Vector3(0, 9.6, 2.3))


# ======================================================================= Hollow Scarecrow
# Burlap sack head with stitched grin and wisp-green button eyes, bent wide-brim hat,
# patched field coat, rope belt and straw poking out of the cuffs.
const HS_SACK := Color(0.74, 0.62, 0.42)
const HS_SACK_D := Color(0.58, 0.47, 0.3)
const HS_COAT := Color(0.35, 0.25, 0.16)
const HS_PATCH := Color(0.36, 0.46, 0.27)
const HS_HAT := Color(0.24, 0.22, 0.16)
const HS_STRAW := Color(0.93, 0.79, 0.37)
const HS_WISP := Color(0.5, 1.0, 0.35)
const HS_STITCH := Color(0.15, 0.1, 0.07)


static func _build_hollow_scarecrow(m: BoxModel) -> void:
	m.add("sack", Vector3i(8, 8, 8), func(f, u, v, w, h) -> Color:
		if f == F:
			if v == 3 and (u == 2 or u == 5):
				return HS_WISP
			if v == 6 and u >= 1 and u <= 6:
				return HS_STITCH if u % 2 == 1 else HS_SACK_D
			if v == 5 and (u == 1 or u == 6):
				return HS_STITCH
		if v == 0 and f != BT:
			return HS_STITCH if (u % 2 == 0) else HS_SACK_D
		return n(HS_SACK if (u + v) % 3 else HS_SACK_D, u, v, 241, 0.05))
	m.add("brim", Vector3i(14, 1, 14), func(f, u, v, w, h) -> Color: return n(HS_HAT if (u + v) % 5 else HS_HAT.darkened(0.2), u, v, 242))
	m.add("band", Vector3i(8, 1, 8), BoxModel.flat(Color(0.48, 0.12, 0.1), 243))
	m.add("cone1", Vector3i(7, 3, 7), BoxModel.flat(HS_HAT, 244))
	m.add("cone2", Vector3i(5, 3, 5), BoxModel.flat(HS_HAT.darkened(0.05), 245))
	m.add("cone3", Vector3i(3, 3, 3), BoxModel.flat(HS_HAT.darkened(0.1), 246))
	m.add("straw", Vector3i(1, 3, 1), func(f, u, v, w, h) -> Color: return HS_STRAW.darkened(0.08 * v))
	m.add("body", Vector3i(8, 12, 4), func(f, u, v, w, h) -> Color:
		if v == 8:
			return n(Color(0.72, 0.6, 0.38), u, v, 247)
		if f == F and v >= 2 and v <= 5 and u >= 5 and u <= 6:
			return n(HS_PATCH, u, v, 248) if not (v == 2 or v == 5) else HS_STITCH
		if f == F and (u == 3 or u == 4):
			return HS_COAT.darkened(0.2) if v % 3 == 1 else HS_COAT.darkened(0.08)
		return n(HS_COAT, u, v, 249))
	m.add("arm", Vector3i(4, 12, 4), func(f, u, v, w, h) -> Color:
		if v >= 10:
			return n(HS_SACK, u, v, 250)
		if f == SPX and v >= 3 and v <= 5:
			return n(HS_PATCH, u, v, 251)
		return n(HS_COAT, u, v, 252))
	m.add("leg", Vector3i(4, 12, 4), func(f, u, v, w, h) -> Color:
		if v >= 10:
			return n(Color(0.2, 0.14, 0.09), u, v, 253)
		if f == F and v >= 4 and v <= 6 and u <= 1:
			return n(Color(0.52, 0.3, 0.18), u, v, 254)
		return n(Color(0.3, 0.27, 0.2), u, v, 255))


static func _place_hollow_scarecrow(m: BoxModel, r: Dictionary) -> void:
	_base_limbs(m, r)
	m.part(r.head, "sack", Vector3(0, 4, 0))
	m.part(r.head, "brim", Vector3(0, 8.5, 0), Vector3(4, 0, -3))
	m.part(r.head, "band", Vector3(0, 9.2, 0))
	m.part(r.head, "cone1", Vector3(0, 10.6, -0.2), Vector3(-4, 0, 0))
	m.part(r.head, "cone2", Vector3(0.3, 13.2, -0.9), Vector3(-14, 0, 6))
	m.part(r.head, "cone3", Vector3(1.0, 15.4, -2.2), Vector3(-34, 0, 18))
	m.part(r.torso, "body", Vector3(0, 6, 0))
	for s in [-1.0, 1.0]:
		m.part(r.torso, "straw", Vector3(s * 1.5, 12.6, 1.6), Vector3(-20, 0, s * 25))
	for arm in [r.arm_l, r.arm_r]:
		for k in [-1.0, 0.0, 1.0]:
			m.part(arm, "straw", Vector3(k * 1.2, -8.8, k * 0.8), Vector3(k * 20, 0, 180 + k * 25))


# ----------------------------------------------------------------------- shared
## Arms and legs on the same pivots/offsets as Skins.humanoid.
static func _base_limbs(m: BoxModel, r: Dictionary) -> void:
	m.part(r.leg_l, "leg", Vector3(0, -6, 0))
	m.part(r.leg_r, "leg", Vector3(0, -6, 0))
	m.part(r.arm_l, "arm", Vector3(0, -4, 0))
	m.part(r.arm_r, "arm", Vector3(0, -4, 0))
