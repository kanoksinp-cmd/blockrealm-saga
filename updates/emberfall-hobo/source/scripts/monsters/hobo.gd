extends Critter
## Hobo, a low-slung volcanic crawler with a hinged jaw and a segmented tail.

const BASALT := Color("#413139")
const BASALT_SHADE := Color("#221c26")
const EMBER := Color("#cf5729")
const AMBER := Color("#f2a54e")
const EYE := Color("#ffee82")

static var _hobo_model: BoxModel
var _jaw: Node3D
var _tail_tip: Node3D


func _init() -> void:
	species = "hobo"
	body_radius = 0.62
	body_height = 1.03
	attack_range = 2.05
	attack_time = 1.05
	hit_time = 0.53
	attack_cooldown = 1.65
	respawn_time = 18.0


static func _stone(f: int, u: int, v: int, w: int, h: int) -> Color:
	var stagger := floori(v / 2.0)
	var seam := (u + stagger * 2) % 5 == 0 or (v % 3 == 2 and u % 4 < 2)
	var base := BASALT_SHADE if seam else BASALT.lerp(Color("#77524a"), PixelTex.h(u / 2, v / 2, f + 31) * 0.55)
	if f == BoxModel.TOP:
		base = base.lightened(0.11)
	return BoxModel.noise(base, u, v, 88)


static func _chimney(f: int, u: int, v: int, w: int, h: int) -> Color:
	if f == BoxModel.TOP and u > 0 and v > 0 and u < w - 1 and v < h - 1:
		return BASALT_SHADE.darkened(0.65)
	return _stone(f, u, v, w, h)


static func _hide(f: int, u: int, v: int, w: int, h: int) -> Color:
	var patch := PixelTex.h(floori(u / 2.0), floori(v / 2.0), f + 23)
	var mix_amount := clampf(patch * 0.56 + float(v) / maxf(h, 1) * 0.38, 0.0, 1.0)
	return BoxModel.noise(EMBER.lerp(AMBER, mix_amount), u, v, 42, 0.055)


static func _upper_jaw(f: int, u: int, v: int, w: int, h: int) -> Color:
	if f == BoxModel.TOP or v == 0:
		return _stone(f, u, v, w, h)
	if f in [BoxModel.SIDE_PX, BoxModel.SIDE_NX] and v in [1, 2]:
		var x := u if f == BoxModel.SIDE_PX else w - 1 - u
		if x in [1, 2, 3]:
			return BASALT_SHADE if x == 2 and v == 2 else EYE
	return _hide(f, u, v, w, h)


static func _parts() -> BoxModel:
	if _hobo_model != null:
		return _hobo_model
	var m := BoxModel.new(0.056)
	m.voxel = BoxModel.MONSTER_VOXEL
	m.add("ember_body", Vector3i(11, 7, 17), _hide)
	m.add("back_plate", Vector3i(12, 2, 6), _stone)
	m.add("head", Vector3i(10, 5, 9), _upper_jaw)
	m.add("brow", Vector3i(11, 2, 6), _stone)
	m.add("jaw", Vector3i(9, 2, 9), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		return BoxModel.noise(Color("#6b1c26"), u, v, 17) if f == BoxModel.TOP else _hide(f, u, v, w, h))
	m.add("thigh", Vector3i(4, 5, 4), _hide)
	m.add("foot", Vector3i(4, 2, 5), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		return BASALT_SHADE if f == BoxModel.FRONT and u % 2 == 0 else _hide(f, u, v, w, h))
	m.add("tail_base", Vector3i(8, 5, 8), _hide)
	m.add("tail_mid", Vector3i(6, 4, 7), _hide)
	m.add("tail_end", Vector3i(5, 3, 6), _hide)
	m.add("tail_armor", Vector3i(6, 2, 6), _stone)
	m.add("vent_tall", Vector3i(4, 9, 4), _chimney)
	m.add("vent_mid", Vector3i(4, 7, 4), _chimney)
	m.add("vent_small", Vector3i(3, 5, 3), _chimney)
	m.bake()
	_hobo_model = m
	return m


func _build_model(root: Node3D) -> void:
	var m := _parts()
	var body := m.pivot(root, "Body", Vector3(0, 9, 0))
	m.part(body, "ember_body", Vector3.ZERO)
	for z in [-6.0, 0.0, 6.0]:
		m.part(body, "back_plate", Vector3(0, 4, z))
	m.part(body, "vent_tall", Vector3(-1.8, 8.5, 3.3), Vector3(-18, 0, -13))
	m.part(body, "vent_mid", Vector3(1.4, 7.5, -3.5), Vector3(-21, 0, 11))
	m.part(body, "vent_small", Vector3(-1.2, 6.5, -7), Vector3(-20, 0, -10))

	var head := m.pivot(body, "Head", Vector3(0, 0.5, 7.5))
	m.part(head, "head", Vector3(0, 0.6, 4.2))
	m.part(head, "brow", Vector3(0, 3.2, 3.5), Vector3(-8, 0, 0))
	m.part(head, "vent_small", Vector3(0, 4.4, 5.8), Vector3(-12, 0, 0))
	_jaw = m.pivot(head, "JawHinge", Vector3(0, -1.2, 0.2))
	m.part(_jaw, "jaw", Vector3(0, -1.05, 4.6))
	_jaw.rotation.x = 0.08

	var legs: Array[Node3D] = []
	for z in [-5.0, 5.0]:
		for side in [-1.0, 1.0]:
			var leg := m.pivot(body, "Leg", Vector3(side * 4.4, -2.4, z))
			m.part(leg, "thigh", Vector3(side * 0.7, -1.8, 0), Vector3(0, 0, side * 18))
			m.part(leg, "foot", Vector3(side * 1.3, -5.6, 0.6))
			legs.append(leg)

	var tail := m.pivot(body, "Tail", Vector3(0, -0.4, -7))
	m.part(tail, "tail_base", Vector3(0, 0, -3.5))
	m.part(tail, "tail_armor", Vector3(0, 2.5, -3.8))
	var mid := m.pivot(tail, "TailMiddle", Vector3(0, 0.3, -7))
	mid.rotation_degrees.x = 12.0
	m.part(mid, "tail_mid", Vector3(0, 0, -3.2))
	m.part(mid, "tail_armor", Vector3(0, 2, -3.1))
	_tail_tip = m.pivot(mid, "TailTip", Vector3(0, 0, -6.4))
	_tail_tip.rotation_degrees.x = 19.0
	m.part(_tail_tip, "tail_end", Vector3(0, 0, -2.5))
	m.part(_tail_tip, "tail_armor", Vector3(0, 1.6, -2.8))
	for side in [-1.0, 1.0]:
		m.part(_tail_tip, "vent_mid", Vector3(side * 1.45, 3.7, -3.1), Vector3(-18, 0, -side * 20))
	_body_y = body.position.y
	_rig = {"kind": "quad", "body": body, "head": head, "legs": legs, "arms": [], "tails": [tail], "body_y": _body_y}


func _animate(delta: float) -> void:
	super._animate(delta)
	var jaw_angle := 0.08
	if state == State.ATTACK:
		var phase := _state_t / attack_time
		var open := smoothstep(0.03, 0.39, phase) * (1.0 - smoothstep(0.40, hit_time, phase))
		jaw_angle += open * 0.57
	_jaw.rotation.x = lerpf(_jaw.rotation.x, jaw_angle, 1.0 - exp(-28.0 * delta))
	_tail_tip.rotation.y = sin(_t * 2.6 - 0.8) * 0.16
