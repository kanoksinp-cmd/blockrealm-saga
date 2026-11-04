extends RefCounted
## Relic Vanguard outfits attach to the same animation pivots as the base avatar.

const PX := 0.055
const F := BoxModel.FRONT
const VOID := Color("#151622")
const TINTS := {
	"crimson_bastion": ["#733343", "#9d9a9b", "#d06666", "#c8b5a6", "horn", "plate", "spine", "saw", "shield"],
	"iron_warden": ["#54403b", "#b9a98d", "#806456", "#ded3b1", "antler", "plate", "none", "sword", "shield"],
	"cinder_ranger": ["#3d4859", "#8a9ba8", "#aa5229", "#ffd18d", "hood", "coat", "quiver", "bow", ""],
	"gilded_wayfarer": ["#3a2624", "#e2b254", "#8a3629", "#f7deb1", "hat", "coat", "none", "rapier", ""],
	"verdigris_arcanist": ["#4f385c", "#76a8a0", "#6ac377", "#dbffc2", "spires", "robe", "orbs", "fork", ""],
	"azure_bulwark": ["#674536", "#8bc7df", "#d19a5a", "#c2f4ff", "bar", "plate", "none", "hammer", "shield"],
	"solar_regalia": ["#1d4359", "#f5ce77", "#c77d53", "#fff3a3", "crown", "robe", "halo", "sun", ""],
	"amethyst_oracle": ["#222d52", "#e5a96d", "#a65cdc", "#f3b4ff", "diadem", "robe", "orbs", "wand", ""],
	"infernal_executioner": ["#4f2526", "#f5a145", "#b8482d", "#ffdc6d", "horn", "plate", "halo", "axe", ""],
	"rosewing_paladin": ["#694061", "#f5c29d", "#d354a8", "#ffd0f5", "crest", "plate", "wing", "sword", ""],
	"evergreen_giftkeeper": ["#a4392b", "#f2d4ab", "#4ca565", "#ffdc83", "winter", "coat", "gift", "pine", ""],
	"celestial_falcon": ["#394980", "#f2c486", "#77639c", "#93e7ff", "falcon", "plate", "wing", "bow", ""],
}
static var _models := {}


static func _plate(base: Color, trim: Color, gem: Color, seed: int) -> Callable:
	return func(f: int, u: int, v: int, w: int, h: int) -> Color:
		var ink := base
		if v == 0 or v == h - 1 or (f == F and u in [0, w - 1]):
			ink = trim
		elif f == F and absi(u - w / 2) + absi(v - h / 2) <= 2:
			ink = gem if v <= h / 2 else gem.darkened(0.22)
		elif (u / 2 + v / 2) % 3 == 0:
			ink = base.lightened(0.15)
		return BoxModel.noise(ink, u, v, seed, 0.045)


static func _model(id: String) -> BoxModel:
	if _models.has(id):
		return _models[id]
	var d: Array = TINTS[id]
	var base := Color(d[0])
	var trim := Color(d[1])
	var accent := Color(d[2])
	var gem := Color(d[3])
	var helm: String = d[4]
	var suit: String = d[5]
	var back: String = d[6]
	var weapon: String = d[7]
	var m := BoxModel.new(PX)
	var metal := BoxModel.flat(trim, 72)
	var armor := _plate(base, trim, accent, 75)
	var body_paint := _plate(base, trim, gem, 82)
	m.add("relic_helm", Vector3i(10, 9, 9), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		if f == F and v >= 3 and v <= (6 if helm in ["bar", "horn", "antler"] else 7) and u >= 2 and u <= 7:
			return gem if v == 4 and u in [2, 3, 6, 7] and helm not in ["hood", "hat", "winter"] else VOID
		var ink := trim if v in [0, 8] or u == 0 or u == w - 1 else base
		if helm == "bar" and u in [3, 6] and f == F:
			ink = accent
		return BoxModel.noise(ink, u, v, 77))
	m.add("relic_brim", Vector3i(13, 1, 12), metal)
	m.add("relic_cap", Vector3i(9, 5, 9), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		if f == F and v >= 2 and u in [3, 4, 5]:
			return trim if v == 2 or u != 4 else VOID
		return BoxModel.noise(accent if v == 3 else base, u, v, 78))
	m.add("relic_ridge", Vector3i(3, 7, 3), _plate(accent, trim, gem, 79))
	m.add("relic_prong", Vector3i(2, 5, 2), metal)
	m.add("relic_crystal", Vector3i(2, 5, 2), _plate(accent, gem, gem.lightened(0.2), 80))
	m.add("relic_core", Vector3i(4, 4, 2), _plate(accent, trim, gem, 81))
	m.add("relic_body", Vector3i(9, 12, 5), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		if f == F:
			if helm == "hood" and (u == floori(v * 0.66) or u == 8 - floori(v * 0.66)):
				return BoxModel.noise(accent, u, v, 82)
			if helm in ["horn", "antler", "bar"] and v in [3, 6, 9]:
				return BoxModel.noise(trim.darkened(0.22) if u in [3, 4, 5] else accent, u, v, 82)
			if helm in ["hat", "winter"] and v in [4, 7, 10] and u in [2, 3, 4, 5, 6]:
				return BoxModel.noise(trim if u == 4 else accent, u, v, 82)
		return body_paint.call(f, u, v, w, h))
	m.add("relic_belt", Vector3i(10, 2, 6), _plate(accent.darkened(0.32), trim, gem, 83))
	m.add("relic_arm", Vector3i(4, 12, 4), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		var ink := trim if v in [4, 8, 11] else (accent if v >= 9 else base)
		return BoxModel.noise(ink, u, v, 84))
	m.add("relic_shoulder", Vector3i(6 if suit == "plate" else 5, 4, 6), armor)
	m.add("relic_leg", Vector3i(5, 12, 5), _plate(base.darkened(0.15), trim, accent, 85))
	m.add("relic_panel", Vector3i(4, 8 if suit != "plate" else 5, 2), armor)
	m.add("relic_cape", Vector3i(10, 14, 1), _plate(accent.darkened(0.22), trim, accent, 86))
	if back in ["wing", "halo", "spine"]:
		m.add("relic_feather", Vector3i(2, 9, 2), _plate(accent, trim, gem, 87))
	if back in ["quiver", "gift"]:
		m.add("relic_pack", Vector3i(6, 8, 5), _plate(accent, trim, gem, 88))
	if weapon in ["sword", "saw", "rapier", "axe"]:
		var narrow := weapon == "rapier"
		m.add("relic_blade", Vector3i(2 if narrow else 4, 15 if narrow else 14, 2), _plate(trim.darkened(0.25), trim.lightened(0.23), gem, 90))
		m.add("relic_tip", Vector3i(2, 4, 2), metal)
		m.add("relic_tooth", Vector3i(2, 3, 2), metal)
	m.add("relic_grip", Vector3i(2, 6, 2), _plate(base.darkened(0.2), trim, accent, 91))
	m.add("relic_guard", Vector3i(7, 2, 3), _plate(accent, trim, gem, 92))
	m.add("relic_shaft", Vector3i(2, 24, 2), _plate(base, trim, accent, 93))
	if weapon in ["hammer", "axe"]:
		m.add("relic_hammer", Vector3i(10, 6, 6), _plate(base, trim, gem, 94))
		m.add("relic_axe", Vector3i(6, 9, 2), _plate(trim.darkened(0.34), trim, accent, 95))
	if weapon == "bow":
		m.add("relic_bow_limb", Vector3i(3, 9, 2), _plate(accent, trim, gem, 96))
		m.add("relic_string", Vector3i(1, 27, 1), BoxModel.flat(trim.lightened(0.33), 97))
	if weapon == "pine":
		m.add("relic_branch", Vector3i(7, 4, 5), _plate(accent, trim, gem, 98))
	if d[8] == "shield":
		m.add("relic_shield", Vector3i(10, 12, 2), _plate(accent.darkened(0.2), trim, gem, 99))
		m.add("relic_shield_boss", Vector3i(4, 4, 2), metal)
	m.bake()
	_models[id] = m
	return m


static func place(r: Dictionary, id: String, with_weapon: bool) -> void:
	var d: Array = TINTS[id]
	var m := _model(id)
	var helm: String = d[4]
	var suit: String = d[5]
	m.part(r.head, "relic_helm", Vector3(0, 4.4, 0))
	m.part(r.torso, "relic_body", Vector3(0, 6, 0))
	m.part(r.torso, "relic_belt", Vector3(0, 1.9, 0))
	for side in [-1.0, 1.0]:
		var arm: Node3D = r.arm_l if side > 0 else r.arm_r
		var leg: Node3D = r.leg_l if side > 0 else r.leg_r
		m.part(arm, "relic_arm", Vector3(0, -4, 0))
		m.part(arm, "relic_shoulder", Vector3(side * 0.4, 0.6, 0.1), Vector3(0, 0, -side * 20))
		m.part(leg, "relic_leg", Vector3(0, -6, 0))
		m.part(leg, "relic_panel", Vector3(0, -2.5, 2.65), Vector3(-9, 0, side * 8))
	if suit != "plate":
		m.part(r.torso, "relic_cape", Vector3(0, 3.8, -3), Vector3(8, 0, 0))
	_place_helm(m, r.head, helm)
	_place_back(m, r.torso, d[6], id)
	if with_weapon:
		_place_weapon(m, r, d[7], d[8])


static func _place_helm(m: BoxModel, head: Node3D, helm: String) -> void:
	match helm:
		"hat", "winter":
			m.part(head, "relic_brim", Vector3(0, 8, 0))
			m.part(head, "relic_cap", Vector3(0, 10.3 if helm == "hat" else 9.5, -0.4))
			if helm == "winter":
				m.part(head, "relic_core", Vector3(3.3, 10.5, -3))
		"hood":
			m.part(head, "relic_cap", Vector3(0, 7.3, -0.7))
			m.part(head, "relic_guard", Vector3(0, 1.2, 4.7))
		"horn", "antler":
			m.part(head, "relic_ridge", Vector3(0, 9.7, -1))
			for side in [-1.0, 1.0]:
				m.part(head, "relic_prong", Vector3(side * 4.8, 9, -0.8), Vector3(-10, 0, -side * 44))
				m.part(head, "relic_prong", Vector3(side * 6.4, 11.4, -0.9), Vector3(-16, 0, side * 19))
		"bar":
			for side in [-1.0, 1.0]:
				m.part(head, "relic_ridge", Vector3(side * 2, 7.6, 4.6))
		"spires":
			m.part(head, "relic_crystal", Vector3(0, 11.5, -1))
			for side in [-1.0, 1.0]:
				m.part(head, "relic_ridge", Vector3(side * 3.6, 9.6, 1), Vector3(-8, 0, -side * 14))
			m.part(head, "relic_core", Vector3(0, 6.2, 5), Vector3(0, 0, 45))
		_:
			m.part(head, "relic_core", Vector3(0, 7, 5), Vector3(0, 0, 45))
			for side in [-1.0, 1.0]:
				m.part(head, "relic_prong", Vector3(side * 4.8, 8.2, 1), Vector3(-18, 0, -side * (57 if helm in ["falcon", "crest"] else 34)))
				if helm in ["crown", "falcon"]:
					m.part(head, "relic_ridge", Vector3(side * 3.2, 9.6, -2), Vector3(-19, 0, -side * 28))
			if helm == "crest":
				m.part(head, "relic_crystal", Vector3(0, 12, -1.5), Vector3(-16, 0, 0))


static func _place_back(m: BoxModel, torso: Node3D, back: String, id: String) -> void:
	match back:
		"spine":
			for side in [-1.0, 1.0]:
				m.part(torso, "relic_feather", Vector3(side * 4.7, 10, -4), Vector3(-24, 0, -side * 30))
		"quiver", "gift":
			m.part(torso, "relic_pack", Vector3(4.6 if back == "gift" else 2.6, 8.7, -4.6), Vector3(-9, 0, 23))
			for i in 3:
				m.part(torso, "relic_crystal", Vector3(1.9 + i * 1.5, 13.4 - i * 0.6, -4.8), Vector3(-15, 0, -33))
		"wing", "halo":
			for side in [-1.0, 1.0]:
				for i in 4:
					var spread := 7.8 + 2.2 * i if back == "wing" else 5.2 + i * 0.7
					var rise := 10.5 + 1.8 * i if back == "wing" else 12.0 + i * 1.6
					var tilt := 58.0 - i * 12.0 if back == "wing" else 56.0 - i * 13.0
					if id == "celestial_falcon":
						rise -= 1.2 * i
						tilt += 12
					m.part(torso, "relic_feather", Vector3(side * spread, rise, -3.8 - i * 0.45), Vector3(-12, side * 9, -side * tilt))
		"orbs":
			for side in [-1.0, 1.0]:
				for i in 2:
					m.part(torso, "relic_core", Vector3(side * (8.5 + i * 2.6), 8.5 + i * 6.5, -4.8), Vector3(0, side * 12, 45))
					m.part(torso, "relic_crystal", Vector3(side * (9.8 + i * 2.9), 8.5 + i * 6.5, -3.9), Vector3(0, 0, -side * 30))


static func _place_weapon(m: BoxModel, r: Dictionary, weapon: String, offhand: String) -> void:
	var grip: Node3D = r.get("weapon")
	if grip == null:
		grip = m.pivot(r.arm_r, "Weapon", Vector3(0, -9.3, 0.7))
		r.weapon = grip
	if grip.position.is_zero_approx():
		grip.position = Vector3(0, -9.3, 0.7) * PX
	var visual := m.pivot(grip, "RelicWeapon", Vector3.ZERO)
	# The equipped weapon still drives the combat pose and projectile origin.
	if weapon == "bow":
		m.part(visual, "relic_grip", Vector3.ZERO)
		m.part(visual, "relic_string", Vector3(-3.7, 0, 0))
		for side in [-1.0, 1.0]:
			m.part(visual, "relic_bow_limb", Vector3(0.4, side * 5, 0), Vector3(0, 0, -side * 14))
			m.part(visual, "relic_bow_limb", Vector3(-1.3, side * 11.6, 0), Vector3(0, 0, side * 43))
			m.part(visual, "relic_crystal", Vector3(-3.6, side * 14.2, 0), Vector3(0, 0, side * 31))
	elif weapon in ["sword", "saw", "rapier"]:
		m.part(visual, "relic_grip", Vector3.ZERO)
		m.part(visual, "relic_guard", Vector3(0, 3, 0))
		m.part(visual, "relic_blade", Vector3(0, 11, 0))
		m.part(visual, "relic_tip", Vector3(0.55 if weapon == "saw" else 0.0, 19, 0), Vector3(0, 0, 17))
		if weapon == "saw":
			for y in [7, 11, 15]:
				m.part(visual, "relic_tooth", Vector3(2.15, y, 0), Vector3(0, 0, 34))
	else:
		m.part(visual, "relic_shaft", Vector3(0, 3, 0))
		match weapon:
			"hammer":
				m.part(visual, "relic_hammer", Vector3(0, 14, 0))
				for side in [-1.0, 1.0]:
					m.part(visual, "relic_core", Vector3(side * 3.4, 14, 3.4), Vector3(0, 0, 45))
			"axe":
				m.part(visual, "relic_axe", Vector3(3.6, 12.7, 0), Vector3(0, 0, -16))
				m.part(visual, "relic_blade", Vector3(6, 11.8, 0), Vector3(0, 0, -29))
				m.part(visual, "relic_tooth", Vector3(-2, 15.5, 0), Vector3(0, 0, 32))
			"pine":
				for i in 3:
					m.part(visual, "relic_branch", Vector3(0, 13 + 3.1 * i, 0), Vector3(0, i * 32, 0)).scale *= 1.0 - 0.18 * i
				m.part(visual, "relic_core", Vector3(0, 22.3, 0), Vector3(0, 0, 45))
			_:
				m.part(visual, "relic_core", Vector3(0, 15.7, 0), Vector3(0, 0, 45))
				for side in [-1.0, 1.0]:
					m.part(visual, "relic_crystal", Vector3(side * (3.9 if weapon != "wand" else 2.6), 16.0, 0), Vector3(0, 0, -side * 40))
				if weapon == "sun":
					for side in [-1.0, 1.0]:
						m.part(visual, "relic_prong", Vector3(0, 15.7 + side * 4.8, 0))
						m.part(visual, "relic_prong", Vector3(side * 5.0, 15.7, 0), Vector3(0, 0, 90))
	if offhand == "shield":
		var shield := m.pivot(r.arm_l, "RelicShield", Vector3(1.0, -5.0, 3.2))
		m.part(shield, "relic_shield", Vector3.ZERO, Vector3(8, -18, -10))
		m.part(shield, "relic_shield_boss", Vector3(0, 0, 1.5), Vector3(8, -18, 35))
