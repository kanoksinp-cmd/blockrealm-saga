extends Critter
## Two Verdant tyrants share the biped rig and use their own proportions and skin.

static var _rex_models := {}

var _ash := false
var _jaw: Node3D
var _tail_end: Node3D


func _init(ash := false) -> void:
	_ash = ash
	species = "ashfang_rex" if ash else "mossjaw_rex"
	body_radius = 0.75 if ash else 0.66
	body_height = 2.05 if ash else 1.85
	attack_range = 3.8 if ash else 3.25
	attack_time = 1.62 if ash else 1.24
	hit_time = 0.86 if ash else 0.67
	attack_cooldown = 1.75 if ash else 1.4
	respawn_time = 150.0 if ash else 120.0


static func _hide(ash: bool, seed: int, striped := false) -> Callable:
	return func(f: int, u: int, v: int, w: int, h: int) -> Color:
		var main := Color("#696459") if ash else Color("#626b3e")
		var dark := Color("#34342e") if ash else Color("#282e24")
		var pale := Color("#b1a797") if ash else Color("#bfc2a3")
		var light := Color("#89806b") if ash else Color("#989656")
		var side := f in [BoxModel.SIDE_PX, BoxModel.SIDE_NX]
		var patch := PixelTex.h(floori(u / 2.0), floori(v / 2.0), seed + f * 13)
		var base := main.lerp(light, patch * 0.62)
		if f == BoxModel.BOTTOM or (f != BoxModel.TOP and v >= h - 2):
			base = pale.lerp(main, patch * 0.28)
		elif striped and side and ((u + floori(v / 2.0)) % (6 if ash else 5)) < 2:
			base = dark.lerp(main, 0.26 + patch * 0.25)
		return BoxModel.noise(base, u, v, seed, 0.045)


static func _model(ash: bool) -> BoxModel:
	if _rex_models.has(ash):
		return _rex_models[ash]
	var m := BoxModel.new(0.064)
	m.voxel = BoxModel.MONSTER_VOXEL
	var skin := _hide(ash, 501, true)
	var head_skin := _hide(ash, 502)
	m.add("trunk", Vector3i(ash_i(ash, 15, 12), ash_i(ash, 15, 12), ash_i(ash, 22, 20)), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		if ash and f in [BoxModel.SIDE_PX, BoxModel.SIDE_NX] and u in [7, 11, 15] and v in [4, 5, 6, 7]:
			return Color("#69372d") if (u + v) % 3 != 0 else Color("#8d5445")
		return skin.call(f, u, v, w, h))
	m.add("neck", Vector3i(ash_i(ash, 11, 9), 11, 9), skin)
	m.add("crown", Vector3i(ash_i(ash, 13, 10), ash_i(ash, 9, 7), 9), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		if f in [BoxModel.SIDE_PX, BoxModel.SIDE_NX]:
			var x := u if f == BoxModel.SIDE_PX else w - u - 1
			if x in [2, 3, 4, 5] and v in [2, 3, 4]:
				return (Color("#fff0cf") if ash else Color("#ed3e2d")) if x in [3, 4] and v == 3 else Color("#201c1b")
		return head_skin.call(f, u, v, w, h))
	m.add("brow", Vector3i(3, 2, 5), BoxModel.flat(Color("#817a70") if ash else Color("#626a43"), 505))
	m.add("snout", Vector3i(ash_i(ash, 11, 8), 5, ash_i(ash, 12, 11)), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		if f == BoxModel.FRONT and v == 1 and u in [1, w - 2]:
			return Color("#272323")
		return head_skin.call(f, u, v, w, h))
	m.add("lower_jaw", Vector3i(ash_i(ash, 10, 8), 4, ash_i(ash, 17, 15)), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		if f == BoxModel.TOP:
			return BoxModel.noise(Color("#a45345") if ash else Color("#ad7166"), u, v, 507)
		return head_skin.call(f, u, v, w, h))
	m.add("tooth", Vector3i(1, 2, 1), BoxModel.flat(Color("#dcd3b4"), 508))
	m.add("thigh", Vector3i(ash_i(ash, 8, 6), ash_i(ash, 12, 10), ash_i(ash, 9, 7)), skin)
	m.add("shin", Vector3i(ash_i(ash, 5, 4), 10, 5), _hide(ash, 509))
	m.add("foot", Vector3i(ash_i(ash, 8, 6), 3, ash_i(ash, 9, 8)), func(f: int, u: int, v: int, w: int, h: int) -> Color:
		if f == BoxModel.FRONT and u % 2 == 0:
			return Color("#302c29") if ash else Color("#dfd4b3")
		return head_skin.call(f, u, v, w, h))
	m.add("arm", Vector3i(3, 6, 3), head_skin)
	m.add("arm_claw", Vector3i(1, 1, 2), BoxModel.flat(Color("#d1c9ad"), 510))
	m.add("tail_base", Vector3i(ash_i(ash, 11, 9), 10, 12), skin)
	m.add("tail_middle", Vector3i(ash_i(ash, 8, 6), 7, 11), skin)
	m.add("tail_tip", Vector3i(ash_i(ash, 5, 4), 4, 12), skin)
	m.bake()
	_rex_models[ash] = m
	return m


static func ash_i(ash: bool, broad: int, lean: int) -> int:
	return broad if ash else lean


func _build_model(root: Node3D) -> void:
	var m := _model(_ash)
	var body := m.pivot(root, "Body", Vector3(0, 20, 0))
	m.part(body, "trunk", Vector3(0, 0, 0), Vector3(-6, 0, 0))
	m.part(body, "neck", Vector3(0, 2.8, 11.1), Vector3(-22, 0, 0))
	var head := m.pivot(body, "Head", Vector3(0, 6.2, 13.5))
	m.part(head, "crown", Vector3(0, 2.1, 1.0))
	m.part(head, "snout", Vector3(0, 0.85, 9.5))
	_jaw = m.pivot(head, "JawHinge", Vector3(0, -2.1, -1))
	m.part(_jaw, "lower_jaw", Vector3(0, -1.7, 8.5))
	_jaw.rotation.x = 0.1
	var jaw_width := 4.5 if _ash else 3.4
	for side in [-1.0, 1.0]:
		m.part(head, "brow", Vector3(side * (5.1 if _ash else 4), 5.6, 2.6), Vector3(10, 0, 0))
		for i in 5:
			var z := 5.7 + 1.8 * i
			m.part(head, "tooth", Vector3(side * jaw_width, -2.25, z), Vector3(-8, 0, 0))
			m.part(_jaw, "tooth", Vector3(side * (jaw_width - 0.65), 0.8, z + 0.6), Vector3(8, 0, 0))
	var legs: Array[Node3D] = []
	var arms: Array[Node3D] = []
	for side in [-1.0, 1.0]:
		var leg := m.pivot(body, "Leg", Vector3(side * (6.4 if _ash else 5.2), -1.4, -1.8))
		m.part(leg, "thigh", Vector3(side * 0.3, -3.5, 0.1), Vector3(12, 0, side * 8))
		m.part(leg, "shin", Vector3(0, -11.8, -0.8), Vector3(-13, 0, 0))
		m.part(leg, "foot", Vector3(0, -17.1, 2.4))
		legs.append(leg)
		var arm := m.pivot(body, "Arm", Vector3(side * 4.8, -3.2, 9.7))
		m.part(arm, "arm", Vector3(0, -2.3, 0.8), Vector3(-22, 0, 0))
		for finger in [-0.65, 0.65]:
			m.part(arm, "arm_claw", Vector3(finger, -4.9, 2.3))
		arms.append(arm)
	var tail := m.pivot(body, "Tail", Vector3(0, 0.1, -8))
	m.part(tail, "tail_base", Vector3(0, -0.7, -5), Vector3(-7, 0, 0))
	var middle := m.pivot(tail, "TailMiddle", Vector3(0, -1.3, -10))
	middle.rotation_degrees.x = -8.0 if _ash else 12.0
	m.part(middle, "tail_middle", Vector3(0, 0, -4.7))
	_tail_end = m.pivot(middle, "TailTip", Vector3(0, 0.2, -9.8))
	_tail_end.rotation_degrees.x = -3.0 if _ash else 16.0
	m.part(_tail_end, "tail_tip", Vector3(0, 0, -5.1))
	_kind = "biped"
	_body_y = body.position.y
	_rig = {"kind": _kind, "body": body, "head": head, "legs": legs, "arms": arms, "tails": [tail], "body_y": _body_y}


func _attack_motion(progress: float, _delta: float) -> Vector3:
	if progress > 0.38 and progress < 0.64:
		return _attack_dir * (4.0 if _ash else 5.5)
	return Vector3.ZERO


func _animate(delta: float) -> void:
	super._animate(delta)
	var open := 0.0
	if state == State.ATTACK:
		var phase := _state_t / attack_time
		open = smoothstep(0.03, 0.36, phase) * (1.0 - smoothstep(0.38, hit_time / attack_time, phase))
	var jaw_angle := 0.10 + 0.62 * open
	_jaw.rotation.x = lerpf(_jaw.rotation.x, jaw_angle, 1.0 - exp(-22.0 * delta))
	_tail_end.rotation.y = sin(_t * 2.6 - 0.65) * 0.16
