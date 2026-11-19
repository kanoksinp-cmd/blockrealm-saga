@tool
class_name KnightModel
extends Node3D






signal attack_hit

const PLATE: = Color(0.72, 0.74, 0.79)
const PLATE_D: = Color(0.55, 0.57, 0.63)
const MAIL: = Color(0.55, 0.55, 0.58)
const RED: = Color(0.76, 0.16, 0.16)
const TAN: = Color(0.84, 0.62, 0.38)
const TAN_D: = Color(0.7, 0.5, 0.3)
const STRAP: = Color(0.43, 0.27, 0.15)
const GOLD: = Color(0.92, 0.7, 0.24)
const SKIN: = Color(0.9, 0.73, 0.6)
const EYE: = Color(0.22, 0.6, 0.95)
const DARK: = Color(0.2, 0.22, 0.29)
const CRYSTAL: = Color(0.38, 0.68, 1.0)
const GEM: = Color(0.98, 0.12, 0.62)
const BRONZE: = Color(0.76, 0.48, 0.2)
const WRAP: = Color(0.55, 0.12, 0.16)
const HIP_Y: = 0.66
const ATTACK_TIME: = 0.5
const HIT_AT: = 0.27

@export var attack_speed: = 1.0

var hips: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var sword: Node3D

var appearance: = { }
var anim_style: = "slash"
var weapon_kind: = ""
var has_shield: = false
var trail_color: = Color(0.8, 0.9, 1.0)
var _combo: = 0
var _arm_r_rest: = Vector3.INF
var _trail_sent: = false

var _t: = 0.0
var _moving: = false
var _walk: = 0.0
## 0 = walk, 1 = full run (long trips); set by the player every physics frame.
var run_amount: = 0.0
var _run_v: = 0.0
var _walk_ph: = 0.0
var _attack_t: = -1.0
var _hit_sent: = false
var _hurt_t: = -1.0
var _dead: = false
var _dead_t: = 0.0


var _look_key: = ""



var hold: = "one_hand"

var calm: = false
var wing_player: AnimationPlayer
var _wing_anim: = ""


var flying: = false
var _fly: = 0.0
const HOVER: = 0.6
var _w_base: = Vector3.ZERO
var _arm_l_rest: = Vector3.INF
var _hw: = 1.0
var _idle_for: = 0.0
var _look: = Vector2.ZERO
var _look_goal: = Vector2.ZERO
var _look_timer: = 1.0
var _gest: = ""
var _gest_t: = 0.0
var _gest_timer: = 4.0
var _prev_yaw: = INF
var _turn: = 0.0
var _rng: = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_t = _rng.randf() * 20.0
	_gest_timer = _rng.randf_range(3.0, 9.0)
	_build()



func _on_game_changed() -> void:
	if not appearance.is_empty() or not is_inside_tree():
		return
	var g: = get_node_or_null("/root/Game")
	if g and var_to_str(g.dressed_appearance()) != _look_key:
		_build()


func refresh_look() -> void:
	_on_game_changed()



func set_moving(m: bool) -> void:
	_moving = m



func can_fly() -> bool:
	return flying and not _dead and wing_player != null and is_instance_valid(wing_player)



func is_flying() -> bool:
	return can_fly() and _fly > 0.5


func is_attacking() -> bool:
	return _attack_t >= 0.0




const SKILL_MOVES: = {
	"power_strike": [0.72, 0.5], "thrust_combo": [0.7, 0.28], "spin": [0.75, 0.45], "slam": [0.85, 0.55],
	"cast_bolt": [0.55, 0.45], "cast_area": [0.85, 0.62], "volley": [0.7, 0.32], "sky_shot": [0.75, 0.48],
	"throw": [0.55, 0.42], "palm": [0.6, 0.3], "kick": [0.7, 0.45], "song": [0.8, 0.4],
	"buff": [0.75, -1.0], "pray": [0.85, -1.0], "quick": [0.45, 0.4],
	# Ragnarok-style signature moves
	"thrust": [0.55, 0.32], "spiral": [0.95, 0.66], "sweep": [0.72, 0.42], "power_up": [0.8, -1.0],
	"falcon": [0.65, 0.42], "set_trap": [0.7, 0.52], "aim_shot": [0.9, 0.64], "dash": [0.6, 0.42],
	"flurry": [0.8, 0.22], "ground_stab": [0.7, 0.46], "dash_stab": [0.55, 0.4], "asura": [1.0, 0.74],
	"cross_slash": [0.75, 0.52], "shield_bash": [0.55, 0.34], "cross_pose": [0.9, 0.56], "cast_ground": [0.75, 0.5],
	"uppercut": [0.6, 0.36], "chop": [0.7, 0.48],
}
var _skill: = ""
var _skill_dur: = 0.5
var _skill_hit: = 0.5

var channel: = false
var _chan: = 0.0



func skill_attack(kind: String) -> bool:
	if _attack_t >= 0.0 or _dead:
		return false
	var m: Array = SKILL_MOVES.get(kind, SKILL_MOVES.power_strike)
	_skill = kind if SKILL_MOVES.has(kind) else "power_strike"
	_skill_dur = float(m[0])
	_skill_hit = float(m[1])
	_attack_t = 0.0
	_hit_sent = _skill_hit < 0.0
	_trail_sent = false
	return true


func attack(trail: = true) -> bool:
	if _attack_t >= 0.0 or _dead:
		return false
	_attack_t = 0.0
	_hit_sent = false
	_trail_sent = not trail
	_combo = (_combo + 1) % 3
	return true


func hurt() -> void:
	if not _dead:
		_hurt_t = 0.0


func die() -> void:
	_dead = true
	_dead_t = 0.0
	_attack_t = -1.0


func revive() -> void:
	_dead = false
	rotation = Vector3(0, rotation.y, 0)
	position = Vector3.ZERO



func set_appearance(a: Dictionary) -> void:
	appearance = a
	if is_inside_tree():
		_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.free()
	scale = Vector3.ONE
	var a: = appearance
	if a.is_empty() and not Engine.is_editor_hint():
		var g: = get_node_or_null("/root/Game")
		if g and not g.appearance.is_empty():
			a = g.dressed_appearance()
			_look_key = var_to_str(a)
			if not g.changed.is_connected(_on_game_changed):
				g.changed.connect(_on_game_changed)
	if not a.is_empty():
		var r: = Avatar.assemble(self, a)
		_arm_r_rest = Vector3.INF
		hips = r.hips
		torso = r.torso
		head = r.head
		arm_l = r.arm_l
		arm_r = r.arm_r
		leg_l = r.leg_l
		leg_r = r.leg_r
		sword = r.weapon
		anim_style = Avatar.job(a.get("job", "swordsman")).anim
		weapon_kind = String(a.get("weapon_sprite", ""))
		if weapon_kind == "":
			weapon_kind = Avatar.job(a.get("job", "swordsman")).sprite
		if r.get("fashion_weapon", "") == "staff": weapon_kind = "staff"; anim_style = "cast"
		has_shield = r.has("shield")
		wing_player = r.get("wing_player")
		_wing_anim = "glide"
		_setup_hold()
		trail_color = Avatar.glow_color(int(a.get("glow_w", 0))).lightened(0.35) if int(a.get("glow_w", 0)) > 0 else Color(0.8, 0.9, 1.0)
		return
	anim_style = "slash"
	wing_player = null
	var m: = Skins.knight()
	var r: = Skins.humanoid(m, self)
	hips = r.hips
	torso = r.torso
	head = r.head
	arm_l = r.arm_l
	arm_r = r.arm_r
	leg_l = r.leg_l
	leg_r = r.leg_r
	m.part(torso, "skirt", Vector3(0, 0.5, 0))
	m.part(head, "crest", Vector3(0, 9, 0))
	for s in [-1.0, 1.0]:
		m.part(head, "ear", Vector3(s * 4.5, 4.5, 0.5), Vector3(0, 0, - s * 35))
		m.part(head, "ear_tip", Vector3(s * 5.6, 6.2, 0.5), Vector3(0, 0, - s * 55))
	m.part(arm_l, "pauldron", Vector3(0.5, 0.3, 0))
	m.part(arm_r, "pauldron", Vector3(-0.5, 0.3, 0))

	sword = Node3D.new()
	sword.name = "Sword"
	arm_r.add_child(sword)
	sword.position = Vector3(0, -9.2, 0.6) * m.px
	sword.rotation_degrees = Vector3(70, 0, 0)
	var sm: = MeshInstance3D.new()
	sm.mesh = VoxelSprite.extrude(VoxelSprite.CRYSTAL_SWORD, VoxelSprite.CRYSTAL_PALETTE, 0.038, Vector2(7.5, 21.0))
	sm.material_override = VoxelSprite.material()
	sm.rotation_degrees = Vector3(0, 90, 0)
	sword.add_child(sm)
	weapon_kind = "sword"
	has_shield = false
	_setup_hold()


func _setup_hold() -> void:
	_arm_r_rest = Vector3.INF
	_arm_l_rest = Vector3.INF
	_w_base = sword.rotation if sword else Vector3.ZERO
	if anim_style == "shoot" or weapon_kind == "bow":
		hold = "bow"
	elif anim_style == "cast" or weapon_kind == "staff":
		hold = "staff"
	elif weapon_kind == "none" or weapon_kind == "knuckle":
		hold = "fists"
	elif weapon_kind in ["greatsword", "spear"] or (weapon_kind == "axe" and not has_shield):
		hold = "two_hand"
	elif weapon_kind in ["dagger", "katar"]:
		hold = "dagger"
	else:
		hold = "one_hand"



func _process(delta: float) -> void:
	if hips == null:
		return
	_t += delta
	if _dead:
		_dead_t += delta
		var k: = clampf(_dead_t / 0.55, 0.0, 1.0)
		rotation.x = lerpf(0.0, - PI * 0.5, k * k)
		position.y = lerpf(0.0, 0.15, k)
		arm_l.rotation = Vector3(-0.3, 0, 0.6)
		arm_r.rotation = Vector3(-0.3, 0, -0.6)
		return
	if _arm_r_rest == Vector3.INF:
		_arm_r_rest = arm_r.position
		_arm_l_rest = arm_l.position

	_walk = move_toward(_walk, 1.0 if _moving else 0.0, delta * 5.0)
	var w: = _walk
	var idle: = 1.0 - w
	var attacking: = _attack_t >= 0.0
	_hw = move_toward(_hw, 0.0 if attacking else 1.0, delta * (14.0 if attacking else 4.0))
	_update_life(delta, w, attacking)
	_update_wings()


	_run_v = move_toward(_run_v, run_amount, delta * 3.0)
	_walk_ph += delta * (10.0 + 5.0 * _run_v)
	var ph: = _walk_ph
	var sw: = sin(ph)
	var br: = sin(_t * 2.1)
	var shift: = sin(_t * 0.55)
	hips.position = Vector3(shift * 0.012 * idle, HIP_Y + absf(cos(ph)) * 0.055 * w - 0.012 * w + br * 0.006 * idle, 0.0)
	hips.rotation = Vector3(0.0, sw * 0.12 * w, sin(ph) * 0.035 * w + shift * 0.025 * idle)
	torso.rotation = Vector3(0.1 * w + 0.24 * _run_v * w + br * 0.018 * idle, - sw * (0.2 + 0.08 * _run_v) * w, - hips.rotation.z * 0.6 - _turn * 0.05 * w)
	head.rotation = Vector3(_look.y + absf(cos(ph)) * 0.04 * w - br * 0.012 * idle, _look.x - torso.rotation.y * 0.7 - hips.rotation.y + _turn * 0.06, - torso.rotation.z * 0.5)
	var stride: = (0.72 + 0.3 * _run_v) * w
	leg_l.rotation = Vector3(sw * stride - 0.12 * idle, 0.0, 0.045 * idle - shift * 0.02 * idle)
	leg_r.rotation = Vector3(- sw * stride + 0.1 * idle, 0.0, -0.045 * idle - shift * 0.02 * idle)
	arm_r.position = _arm_r_rest + Vector3(0, br * 0.004 * idle, 0)
	arm_l.position = _arm_l_rest + Vector3(0, br * 0.004 * idle, 0)


	var arms: = _hold_pose(sw, br, w, idle)
	arm_r.rotation = arms[0]
	arm_l.rotation = arms[1]
	if sword:
		sword.quaternion = Quaternion.from_euler(_w_base).slerp(Quaternion.from_euler(arms[2]), _hw)
	_gesture_pose()
	_update_flight(delta, w)
	_chan = move_toward(_chan, 1.0 if channel and not attacking else 0.0, delta * 5.0)
	if _chan > 0.0:
		_channel_pose(_chan)

	if attacking and _skill != "":
		_attack_t += delta * maxf(attack_speed, 1.0)
		var sk: = _attack_t / _skill_dur
		if sk >= 1.0:
			if not _hit_sent:
				_hit_sent = true
				attack_hit.emit()
			_attack_t = -1.0
			_skill = ""
		else:
			_skill_pose(_skill, sk)
			if not _hit_sent and sk >= _skill_hit:
				_hit_sent = true
				attack_hit.emit()
		_hurt_anim(delta)
		return
	if attacking:
		_attack_t += delta * attack_speed
		var k: = _attack_t / ATTACK_TIME
		if k >= 1.0:

			if not _hit_sent:
				_hit_sent = true
				attack_hit.emit()
			_attack_t = -1.0
		else:
			var a: float
			if anim_style == "shoot":

				var up: = ease(clampf(k / 0.3, 0.0, 1.0), 0.5)
				var draw: = clampf((k - 0.15) / 0.35, 0.0, 1.0) if k < 0.55 else clampf(1.0 - (k - 0.55) / 0.45, 0.0, 1.0)
				var keep: = up if k < 0.8 else (1.0 - k) / 0.2
				arm_l.rotation = arm_l.rotation.lerp(Vector3(-1.5, 0, 0.15), keep)
				arm_r.rotation = arm_r.rotation.lerp(Vector3(-1.45, -0.6 * draw, -0.4 * draw), keep)
				torso.rotation.y += -0.35 * keep
				leg_l.rotation.x -= 0.2 * keep
				leg_r.rotation.x += 0.15 * keep
				if not _hit_sent and _attack_t >= HIT_AT * 1.3:
					_hit_sent = true
					attack_hit.emit()
				_hurt_anim(delta)
				return
			if anim_style == "cast":

				if k < 0.45:
					a = lerpf(-0.3, -2.9, ease(k / 0.45, 0.4))
				elif k < 0.65:
					a = lerpf(-2.9, -1.4, (k - 0.45) / 0.2)
				else:
					a = lerpf(-1.4, -0.3, (k - 0.65) / 0.35)
				arm_r.rotation = Vector3(a, 0, -0.1)
				arm_l.rotation = Vector3(a * 0.5, 0, 0.35)
				torso.rotation.x += 0.1 * sin(k * PI)
				if not _hit_sent and _attack_t >= HIT_AT * 1.2:
					_hit_sent = true
					attack_hit.emit()
				_hurt_anim(delta)
				return
			if not _weapon_attack(k):
				_slash_attack(k)
			if hold == "two_hand":

				arm_l.rotation = Vector3(arm_r.rotation.x - 0.05, - arm_r.rotation.y - 0.55, - arm_r.rotation.z + 0.1)
			if not _hit_sent and _attack_t >= HIT_AT:
				_hit_sent = true
				attack_hit.emit()

	_hurt_anim(delta)



func _hold_pose(sw: float, br: float, w: float, idle: float) -> Array:
	var ar: = Vector3.ZERO
	var al: = Vector3.ZERO
	var wr: = _w_base
	match hold:
		"one_hand":

			ar = Vector3(lerpf(-0.6 + br * 0.03, -0.28 + sw * 0.35, w), lerpf(0.08, 0.05, w), lerpf(-0.4, -0.26, w))

			wr = _aim(ar, Vector3(-0.3, 0.9, 0.35).lerp(Vector3(-0.2, 0.75, 0.6), w), Vector3(0, 0.3, 1))
			if has_shield:
				al = Vector3(lerpf(-0.72 - br * 0.03, -0.55 - sw * 0.15, w), lerpf(0.5, 0.35, w), 0.15)
			else:
				al = Vector3(lerpf(-0.12 - br * 0.02, - sw * 0.75, w), 0.0, lerpf(0.24, 0.12, w))
		"dagger":

			ar = Vector3(lerpf(-0.75 + br * 0.03, -0.45 + sw * 0.3, w), lerpf(0.35, 0.15, w), -0.22)
			al = Vector3(lerpf(-0.6 - br * 0.03, - sw * 0.7, w), lerpf(-0.3, 0.0, w), lerpf(0.2, 0.12, w))
			wr = _w_base + Vector3(0.25 * idle, 0.0, 0.0)
			torso.rotation.x += 0.08 * idle
			hips.position.y -= 0.03 * idle
		"two_hand":

			ar = Vector3(-0.5 + br * 0.03 + sw * 0.08 * w, 0.35, 0.0)
			al = Vector3(-0.78 + br * 0.03 + sw * 0.08 * w, -0.42, 0.22)

			wr = _aim(ar, Vector3(0.55, 0.85, 0.2), Vector3(0, 0, 1))
		"staff":

			ar = Vector3(lerpf(-0.32 + br * 0.02, -0.25 + sw * 0.2, w), 0.0, lerpf(-0.24, -0.18, w))
			al = Vector3(lerpf(-0.1 - br * 0.02, - sw * 0.75, w), 0.0, lerpf(0.18, 0.12, w))
			wr = Vector3(- ar.x + 0.06, 0.0, - ar.z - 0.08)
		"bow":

			al = Vector3(lerpf(-0.3 - br * 0.02, -0.25 - sw * 0.3, w), 0.0, lerpf(0.2, 0.14, w))
			ar = Vector3(lerpf(-0.08 + br * 0.02, sw * 0.7, w), 0.0, lerpf(-0.14, -0.1, w))
			wr = Vector3(- al.x + 0.22, 0.0, 0.1)
		_:

			ar = Vector3(lerpf(-1.0 + br * 0.04, -0.3 + sw * 0.6, w), lerpf(0.45, 0.1, w), -0.1)
			al = Vector3(lerpf(-1.1 - br * 0.04, -0.3 - sw * 0.6, w), lerpf(-0.45, -0.1, w), 0.1)
	if anim_style == "shoot" and hold != "bow":
		al = Vector3(-0.35 - sw * 0.3 * w, 0, 0.12)
	return [ar, al, wr]




func _aim(arm_rot: Vector3, dir: Vector3, zhint: Vector3) -> Vector3:
	var y: = dir.normalized()
	var x: = y.cross(zhint).normalized()
	var z: = x.cross(y)
	return (Basis.from_euler(arm_rot).inverse() * Basis(x, y, z)).get_euler()




func _update_flight(delta: float, w: float) -> void:
	_fly = move_toward(_fly, 1.0 if can_fly() else 0.0, delta * 1.6)
	if _fly <= 0.0:
		if position.y != 0.0 and not _dead:
			position.y = 0.0
		return
	var e: = ease(_fly, -1.8)
	position.y = (HOVER + sin(_t * 2.6) * 0.07) * e

	torso.rotation.x += (0.12 * w + 0.04) * e
	hips.rotation.x = lerpf(hips.rotation.x, 0.25 * w, e)

	var drift: = sin(_t * 2.6 + 0.8) * 0.06
	leg_l.rotation = leg_l.rotation.lerp(Vector3(0.35 * w + 0.12 + drift, 0.0, 0.07), e)
	leg_r.rotation = leg_r.rotation.lerp(Vector3(0.5 * w + 0.2 - drift, 0.0, -0.07), e)



func _update_wings() -> void:
	if wing_player == null or not is_instance_valid(wing_player):
		return
	if _wing_anim == "fold" and wing_player.is_playing():
		return
	var air: = _fly > 0.3
	var want: = "flap" if _walk > 0.5 or _attack_t >= 0.0 or air else "glide"
	if want != _wing_anim:
		_wing_anim = want
		wing_player.play(want, 0.35)
	if want == "flap":

		wing_player.speed_scale = (1.45 if _walk > 0.5 else 0.85) if air else 1.0
	else:
		wing_player.speed_scale = 0.7



func wing_fold() -> void:
	if wing_player and wing_player.has_animation("fold"):
		_wing_anim = "fold"
		wing_player.play("fold", 0.2)
		wing_player.animation_finished.connect(func (_n) -> void: _wing_anim = "", CONNECT_ONE_SHOT)



func _update_life(delta: float, w: float, attacking: bool) -> void:
	var yaw: = global_rotation.y if is_inside_tree() else rotation.y
	if _prev_yaw != INF and delta > 0.0:
		var rate: = clampf(wrapf(yaw - _prev_yaw, - PI, PI) / delta, -8.0, 8.0)
		_turn = lerpf(_turn, rate, 1.0 - exp(-8.0 * delta))
	_prev_yaw = yaw
	if w > 0.3 or attacking or _hurt_t >= 0.0 or calm:
		_idle_for = 0.0
		_gest = ""
		_look_goal = Vector2.ZERO
	else:
		_idle_for += delta
		_look_timer -= delta
		if _look_timer <= 0.0:
			_look_timer = _rng.randf_range(1.5, 4.5)
			_look_goal = Vector2(_rng.randf_range(-0.55, 0.55), _rng.randf_range(-0.12, 0.15)) if _rng.randf() < 0.7 else Vector2.ZERO
		if _gest == "":
			_gest_timer -= delta
			if _gest_timer <= 0.0 and _idle_for > 2.0:
				_gest = ["look", "weapon", "stretch", "bounce", "weapon"][_rng.randi() % 5]
				_gest_t = 0.0
				_gest_timer = _rng.randf_range(6.0, 13.0)
	_look = _look.lerp(_look_goal, 1.0 - exp(-4.0 * delta))
	if _gest != "":
		_gest_t += delta
		if _gest_t > _gest_len():
			_gest = ""


func _gest_len() -> float:
	return { "look": 2.6, "weapon": 2.2, "stretch": 1.8, "bounce": 1.1 }.get(_gest, 1.0)


func _gesture_pose() -> void:
	if _gest == "":
		return
	var k: = _gest_t / _gest_len()
	var e: = sin(clampf(k, 0.0, 1.0) * PI)
	var held: = clampf(sin(clampf(k, 0.0, 1.0) * PI) * 1.6, 0.0, 1.0)
	match _gest:
		"look":

			head.rotation.y += sin(k * TAU) * 0.75 * held
			head.rotation.x -= 0.08 * held
			torso.rotation.y += sin(k * TAU) * 0.15 * held
		"stretch":

			torso.rotation.z += sin(k * TAU * 2.0) * 0.06 * e
			head.rotation.z += sin(k * TAU * 2.0) * 0.18 * e
			head.rotation.x -= 0.12 * e
			arm_l.rotation.z += 0.18 * e
			arm_r.rotation.z -= 0.18 * e
			hips.position.y += 0.012 * e
		"bounce":

			hips.position.y += absf(sin(k * TAU * 1.5)) * 0.03
			arm_l.rotation.x -= 0.1 * e
			arm_r.rotation.x -= 0.1 * e
		"weapon":
			match hold:
				"bow":
					arm_l.rotation = arm_l.rotation.lerp(Vector3(-1.1, 0.35, 0.1), held)
					head.rotation = head.rotation.lerp(Vector3(0.25, 0.35, 0.0), held)
					arm_r.rotation = arm_r.rotation.lerp(Vector3(-0.9, -0.2, -0.05), held * (0.5 + 0.5 * sin(k * TAU * 2.0)))
				"staff":

					var tap: = maxf(sin(k * TAU * 2.0), 0.0) * held
					arm_r.rotation.x -= 0.28 * tap
					if sword:
						sword.rotation.x += 0.28 * tap
					head.rotation.x += 0.12 * held
				"two_hand":

					arm_r.rotation = arm_r.rotation.lerp(Vector3(-2.3, 0.25, -0.25), held)
					arm_l.rotation = arm_l.rotation.lerp(Vector3(-1.0, -0.6, 0.3), held)
					if sword:
						sword.rotation = sword.rotation.lerp(_w_base + Vector3(0.9, 0.0, 0.0), held)
					head.rotation.y -= 0.2 * held
				"fists":
					arm_r.rotation.x -= 0.5 * maxf(sin(k * TAU * 3.0), 0.0) * held
					arm_l.rotation.x -= 0.5 * maxf(- sin(k * TAU * 3.0), 0.0) * held
				_:

					arm_r.rotation = arm_r.rotation.lerp(Vector3(-1.15, 0.65, -0.1), held)
					if sword:
						sword.rotation = sword.rotation.lerp(_w_base + Vector3(-0.2, sin(k * TAU) * 0.9, 0.3), held)
					head.rotation = head.rotation.lerp(Vector3(0.18, 0.45, 0.0), held)



func _channel_pose(e: float) -> void:
	var pulse: = sin(_t * 6.0) * 0.06
	arm_r.rotation = arm_r.rotation.lerp(Vector3(-2.2 + pulse, 0.1, -0.15), e)
	arm_l.rotation = arm_l.rotation.lerp(Vector3(-1.3 - pulse, -0.25, 0.45), e)
	torso.rotation.x -= 0.08 * e
	head.rotation.x -= 0.12 * e
	hips.position.y += (0.02 + pulse * 0.1) * e



static func _ph(k: float, a: float, b: float, curve: = 1.0) -> float:
	return ease(clampf((k - a) / (b - a), 0.0, 1.0), curve)


func _skill_pose(kind: String, k: float) -> void:
	var rec: = 1.0 - _ph(k, 0.78, 1.0, 0.6)
	match kind:
		"power_strike":

			var wind: = _ph(k, 0.0, 0.42, 0.5)
			var hit: = _ph(k, 0.42, 0.56, 2.4)
			var x: = lerpf(lerpf(-0.6, -3.1, wind), -0.15, hit)
			arm_r.rotation = Vector3(lerpf(-0.6, x, rec), 0.0, -0.2)
			arm_l.rotation = Vector3(lerpf(-0.2, x * 0.8, rec), 0.0, 0.3)
			torso.rotation.x += (-0.3 * wind + 0.55 * hit) * rec
			hips.position.y += (0.06 * wind - 0.14 * hit) * rec
			hips.position.z = 0.25 * hit * rec
			leg_l.rotation.x = (-0.2 * wind - 0.6 * hit) * rec
			leg_r.rotation.x = 0.35 * hit * rec
			if not _trail_sent and k >= 0.44:
				_trail_sent = true
				FX.trail(self, trail_color, 110.0, -30.0, 1.0, PI * 0.5, 1.1)
		"thrust_combo":

			var on: = _ph(k, 0.0, 0.15) * rec
			var jab: = absf(sin(k * PI * 7.0))
			arm_r.rotation = Vector3(lerpf(-0.6, -1.55, on), lerpf(0.25, -0.1, on), -0.05)
			arm_r.position.z = (0.04 + 0.2 * jab) * on
			torso.rotation.y += (0.35 - 0.3 * jab) * on
			torso.rotation.x += 0.15 * on
			hips.position.z = 0.12 * on
			leg_l.rotation.x = -0.55 * on
			leg_r.rotation.x = 0.35 * on
			if not _trail_sent and k >= 0.2:
				_trail_sent = true
				FX.trail(self, trail_color, -12.0, 12.0, 1.0, 0.0, 1.3)
		"spin":

			var wind: = _ph(k, 0.0, 0.25, 0.5)
			var turn: = _ph(k, 0.25, 0.7, 1.4)
			hips.rotation.y += - TAU * turn * rec
			arm_r.rotation = Vector3(lerpf(-0.6, -1.5, maxf(wind, turn) * rec), 0.0, lerpf(-0.3, -1.25, turn * rec))
			arm_l.rotation = Vector3(-0.4 * rec, 0.0, lerpf(0.35, 1.1, turn * rec))
			hips.position.y -= (0.1 * wind * (1.0 - turn) + 0.05 * turn) * rec
			leg_l.rotation.z = 0.25 * turn * rec
			leg_r.rotation.z = -0.25 * turn * rec
			if not _trail_sent and k >= 0.3:
				_trail_sent = true
				FX.trail(self, trail_color, 0.0, 359.0, 0.95, 0.0, 1.35)
		"slam":

			var up: = _ph(k, 0.0, 0.4, 0.5)
			var down: = _ph(k, 0.4, 0.55, 2.5)
			var air: = sin(clampf(k / 0.55, 0.0, 1.0) * PI)
			hips.position.y += (0.45 * air - 0.16 * down) * rec
			var x: = lerpf(lerpf(-0.6, -3.0, up), 0.1, down)
			arm_r.rotation = Vector3(lerpf(-0.6, x, rec), 0.0, -0.15)
			arm_l.rotation = Vector3(lerpf(-0.2, x, rec), 0.0, 0.15)
			torso.rotation.x += (-0.35 * up + 0.7 * down) * rec
			leg_l.rotation.x = (-0.8 * air - 0.4 * down) * rec
			leg_r.rotation.x = (0.3 * air + 0.5 * down) * rec
		"cast_bolt":

			var gather: = _ph(k, 0.0, 0.4, 0.5)
			var push: = _ph(k, 0.4, 0.52, 2.0)
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.0, -1.65, push), rec), lerpf(0.0, 0.5 * (1.0 - push), gather), -0.1)
			arm_l.rotation = Vector3(lerpf(-0.2, lerpf(-1.1, -1.5, push), rec), lerpf(0.0, -0.6 * (1.0 - push), gather), 0.2)
			torso.rotation.y += (0.3 * gather - 0.45 * push) * rec
			torso.rotation.x += 0.12 * push * rec
			leg_l.rotation.x = -0.3 * push * rec
		"cast_area":

			var raise: = _ph(k, 0.0, 0.5, 0.5)
			var drop: = _ph(k, 0.55, 0.68, 2.2)
			var x: = lerpf(lerpf(-0.4, -3.0, raise), -1.2, drop)
			arm_r.rotation = Vector3(lerpf(-0.6, x, rec), 0.0, lerpf(-0.1, -0.35, raise) * rec)
			arm_l.rotation = Vector3(lerpf(-0.2, x, rec), 0.0, lerpf(0.2, 0.35, raise) * rec)
			torso.rotation.x += (-0.3 * raise * (1.0 - drop) + 0.2 * drop) * rec
			head.rotation.x -= 0.35 * raise * (1.0 - drop) * rec
			hips.position.y += 0.05 * raise * (1.0 - drop) * rec
		"volley":

			var hold_k: = _ph(k, 0.0, 0.18) * rec
			var draw: = absf(sin(k * PI * 2.0))
			arm_l.rotation = arm_l.rotation.lerp(Vector3(-1.5, 0, 0.15), hold_k)
			arm_r.rotation = arm_r.rotation.lerp(Vector3(-1.45, -0.65 * draw, -0.45 * draw), hold_k)
			torso.rotation.y += -0.4 * hold_k
			leg_l.rotation.x -= 0.25 * hold_k
			leg_r.rotation.x += 0.2 * hold_k
		"sky_shot":

			var hold_k: = _ph(k, 0.0, 0.3, 0.5) * rec
			var draw: = _ph(k, 0.1, 0.45) * (1.0 - _ph(k, 0.48, 0.55))
			arm_l.rotation = arm_l.rotation.lerp(Vector3(-2.4, 0, 0.15), hold_k)
			arm_r.rotation = arm_r.rotation.lerp(Vector3(-2.3, -0.6 * draw, -0.4 * draw), hold_k)
			torso.rotation.x -= 0.35 * hold_k
			head.rotation.x -= 0.4 * hold_k
			leg_l.rotation.x -= 0.3 * hold_k
		"throw":

			var back: = _ph(k, 0.0, 0.38, 0.5)
			var fling: = _ph(k, 0.38, 0.5, 2.0)
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-2.7, -1.2, fling), maxf(back, fling) * rec), 0.0, lerpf(-0.3, -0.5, back) * rec)
			arm_l.rotation = Vector3(lerpf(-0.2, -1.2, back * (1.0 - fling)) * rec, 0.0, 0.3)
			torso.rotation.y += (0.6 * back - 0.8 * fling) * rec
			torso.rotation.x += 0.2 * fling * rec
			leg_l.rotation.x = -0.4 * fling * rec
			leg_r.rotation.x = 0.3 * fling * rec
		"palm":

			var on: = _ph(k, 0.0, 0.12) * rec
			var l: = maxf(sin(k * PI * 6.0), 0.0)
			var r: = maxf(- sin(k * PI * 6.0), 0.0)
			arm_r.rotation = Vector3(lerpf(-0.6, -0.9 - 0.7 * r, on), 0.0, -0.1)
			arm_l.rotation = Vector3(lerpf(-0.2, -0.9 - 0.7 * l, on), 0.0, 0.1)
			arm_r.position.z = 0.16 * r * on
			arm_l.position.z = 0.16 * l * on
			torso.rotation.y += 0.3 * (l - r) * on
			hips.position.y -= 0.06 * on
			leg_l.rotation.x = -0.4 * on
			leg_r.rotation.x = 0.3 * on
		"kick":

			var prep: = _ph(k, 0.0, 0.3, 0.5)
			var kick: = _ph(k, 0.3, 0.48, 2.0)
			leg_r.rotation.x = lerpf(0.0, lerpf(0.4, -1.9, kick), maxf(prep, kick) * rec)
			leg_l.rotation.x = 0.2 * kick * rec
			torso.rotation.x += (0.15 * prep + 0.4 * kick) * rec
			hips.position.y += (0.12 * kick - 0.05 * prep) * rec
			arm_r.rotation = Vector3(-0.3 * rec, 0.0, -0.9 * kick * rec)
			arm_l.rotation = Vector3(-0.3 * rec, 0.0, 0.9 * kick * rec)
		"song":

			var on: = _ph(k, 0.0, 0.15) * rec
			var beat: = sin(k * PI * 8.0)
			arm_r.rotation = Vector3(lerpf(-0.6, -1.1 + 0.35 * beat, on), lerpf(0.2, 0.5, on), -0.25)
			arm_l.rotation = Vector3(lerpf(-0.2, -1.3, on), -0.4 * on, 0.4 * on)
			hips.position.y += absf(beat) * 0.05 * on
			head.rotation.z += 0.12 * beat * on
			torso.rotation.z += 0.05 * beat * on
		"buff":

			var up: = _ph(k, 0.0, 0.4, 0.5) * rec
			arm_r.rotation = arm_r.rotation.lerp(Vector3(-3.0, 0.0, -0.1), up)
			arm_l.rotation = arm_l.rotation.lerp(Vector3(-0.4, 0.0, 0.9), up)
			torso.rotation.x -= 0.15 * up
			head.rotation.x -= 0.25 * up
			hips.position.y += 0.05 * sin(clampf(k / 0.6, 0.0, 1.0) * PI)
		"pray":

			var p: = _ph(k, 0.0, 0.3, 0.5) * rec
			arm_r.rotation = arm_r.rotation.lerp(Vector3(-1.2, 0.55, 0.0), p)
			arm_l.rotation = arm_l.rotation.lerp(Vector3(-1.2, -0.55, 0.0), p)
			head.rotation.x += 0.35 * p
			torso.rotation.x += 0.1 * p
			hips.position.y -= 0.04 * p
		"quick":
			var dart: = _ph(k, 0.0, 0.4, 2.0) * rec
			arm_r.rotation = Vector3(lerpf(-0.6, -1.4, dart), 0.0, -0.1)
			arm_r.position.z = 0.15 * dart
			hips.position.z = 0.2 * dart
			leg_l.rotation.x = -0.5 * dart
		"thrust":   # Pierce: low lunge, weapon straight ahead
			var back: = _ph(k, 0.0, 0.3, 0.5)
			var lunge: = _ph(k, 0.3, 0.42, 2.4)
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.2, -1.6, lunge), maxf(back, lunge) * rec), lerpf(0.0, 0.4 * (1.0 - lunge), back) * rec, -0.05)
			arm_r.position.z = (-0.1 * back + 0.28 * lunge) * rec
			torso.rotation.y += (0.45 * back - 0.5 * lunge) * rec
			torso.rotation.x += 0.25 * lunge * rec
			hips.position.z = (-0.08 * back + 0.4 * lunge) * rec
			hips.position.y -= 0.1 * lunge * rec
			leg_l.rotation.x = -0.9 * lunge * rec
			leg_r.rotation.x = 0.55 * lunge * rec
			if not _trail_sent and k >= 0.32:
				_trail_sent = true
				FX.trail(self, trail_color, -8.0, 8.0, 1.0, 0.0, 1.6)
		"spiral":   # Spiral Pierce: leap, spin and drive down
			var crouch: = _ph(k, 0.0, 0.2, 0.5)
			var rise: = _ph(k, 0.2, 0.5, 0.6)
			var dive: = _ph(k, 0.55, 0.68, 2.4)
			hips.position.y += (-0.12 * crouch * (1.0 - rise) + 1.1 * rise * (1.0 - dive) - 0.1 * dive) * rec
			hips.rotation.y += TAU * 1.5 * rise * rec
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-2.8, -1.0, dive), maxf(rise, dive) * rec), 0.0, -0.1)
			torso.rotation.x += (-0.3 * rise * (1.0 - dive) + 0.8 * dive) * rec
			leg_l.rotation.x = (-0.9 * rise * (1.0 - dive) - 0.4 * dive) * rec
			leg_r.rotation.x = (-0.6 * rise * (1.0 - dive) + 0.4 * dive) * rec
			if not _trail_sent and k >= 0.56:
				_trail_sent = true
				FX.trail(self, trail_color, 0.0, 359.0, 0.8, PI * 0.5, 1.4)
		"sweep":   # Brandish Spear: a wide horizontal arc
			var wind: = _ph(k, 0.0, 0.32, 0.5)
			var cut: = _ph(k, 0.32, 0.5, 2.2)
			arm_r.rotation = Vector3(lerpf(-0.6, -1.45, maxf(wind, cut) * rec), lerpf(0.0, lerpf(1.1, -1.3, cut), maxf(wind, cut) * rec), -0.2)
			torso.rotation.y += (0.9 * wind - 1.5 * cut) * rec
			hips.position.y -= 0.1 * cut * rec
			leg_l.rotation.x = -0.5 * cut * rec
			leg_r.rotation.x = 0.35 * cut * rec
			if not _trail_sent and k >= 0.34:
				_trail_sent = true
				FX.trail(self, trail_color, 80.0, -80.0, 1.35, 0.0, 1.2)
		"power_up":   # Two-Hand Quicken / Aura Blade / Frenzy: crouch, fists clenched, burst upward
			var gather: = _ph(k, 0.0, 0.45, 0.5)
			var burst: = _ph(k, 0.45, 0.6, 2.0)
			hips.position.y += (-0.14 * gather * (1.0 - burst) + 0.06 * burst) * rec
			arm_r.rotation = arm_r.rotation.lerp(Vector3(lerpf(-0.9, -0.3, burst), 0.0, lerpf(-0.2, -1.1, burst)), maxf(gather, burst) * rec)
			arm_l.rotation = arm_l.rotation.lerp(Vector3(lerpf(-0.9, -0.3, burst), 0.0, lerpf(0.2, 1.1, burst)), maxf(gather, burst) * rec)
			torso.rotation.x += (0.3 * gather * (1.0 - burst) - 0.25 * burst) * rec
			head.rotation.x += (0.25 * gather * (1.0 - burst) - 0.35 * burst) * rec
		"falcon":   # Blitz Beat / Falcon Assault: arm thrust out, sending the falcon
			var up: = _ph(k, 0.0, 0.3, 0.5)
			var send: = _ph(k, 0.32, 0.45, 2.0)
			arm_l.rotation = arm_l.rotation.lerp(Vector3(lerpf(-2.6, -1.5, send), 0.0, 0.25), maxf(up, send) * rec)
			arm_l.position.z = 0.15 * send * rec
			arm_r.rotation = arm_r.rotation.lerp(Vector3(-0.3, 0.0, -0.4), up * rec)
			torso.rotation.y += (-0.3 * up + 0.4 * send) * rec
			leg_l.rotation.x = -0.35 * send * rec
		"set_trap":   # traps: kneel and set it on the ground
			var down: = _ph(k, 0.0, 0.4, 0.5)
			var place: = _ph(k, 0.4, 0.55, 1.5)
			hips.position.y -= 0.32 * down * rec
			torso.rotation.x += 0.7 * down * rec
			leg_l.rotation.x = -1.2 * down * rec
			leg_r.rotation.x = 0.9 * down * rec
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.0, -0.5, place), down * rec), 0.0, -0.1)
			arm_l.rotation = Vector3(lerpf(-0.2, -0.8, down * rec), 0.0, 0.2)
		"aim_shot":   # Sharp Shooting: a long, steady draw
			var hold_k: = _ph(k, 0.0, 0.2) * rec
			var draw: = _ph(k, 0.15, 0.6, 0.6) * (1.0 - _ph(k, 0.62, 0.68))
			arm_l.rotation = arm_l.rotation.lerp(Vector3(-1.55, 0, 0.12), hold_k)
			arm_r.rotation = arm_r.rotation.lerp(Vector3(-1.5, -0.85 * draw, -0.6 * draw), hold_k)
			torso.rotation.y += -0.5 * hold_k
			hips.position.y -= 0.08 * hold_k
			leg_l.rotation.x = -0.45 * hold_k
			leg_r.rotation.x = 0.35 * hold_k
		"dash", "dash_stab":   # Cart Termination / Back Stab: burst forward and strike
			var lean: = _ph(k, 0.0, 0.25, 0.5)
			var go: = _ph(k, 0.25, 0.45, 1.6)
			hips.position.z = (-0.1 * lean + 0.9 * go) * rec
			hips.position.y += 0.08 * sin(go * PI) * rec
			torso.rotation.x += (0.35 * lean + 0.2 * go) * rec
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-0.4, -1.7, go), maxf(lean, go) * rec), 0.0, -0.1)
			arm_r.position.z = 0.2 * go * rec
			arm_l.rotation = Vector3(lerpf(-0.2, 0.5, lean) * rec, 0.0, 0.3)
			leg_l.rotation.x = (-0.3 * lean - 0.8 * go) * rec
			leg_r.rotation.x = (0.3 * lean + 0.6 * go) * rec
			if not _trail_sent and k >= 0.4:
				_trail_sent = true
				FX.trail(self, trail_color, -20.0, 20.0, 1.0, 0.0, 1.4)
		"flurry":   # Sonic Blow: eight blurred stabs, both arms
			var on: = _ph(k, 0.0, 0.1) * rec
			var a: = sin(k * PI * 16.0)
			arm_r.rotation = Vector3(lerpf(-0.6, -1.3 - 0.35 * a, on), lerpf(0.0, 0.3 * a, on), -0.1)
			arm_l.rotation = Vector3(lerpf(-0.2, -1.3 + 0.35 * a, on), lerpf(0.0, 0.3 * a, on), 0.1)
			arm_r.position.z = 0.15 * maxf(a, 0.0) * on
			arm_l.position.z = 0.15 * maxf(-a, 0.0) * on
			torso.rotation.y += 0.25 * a * on
			hips.position.y -= 0.08 * on
			leg_l.rotation.x = -0.5 * on
			leg_r.rotation.x = 0.35 * on
			if not _trail_sent and k >= 0.15:
				_trail_sent = true
				FX.trail(self, trail_color, -60.0, 60.0, 0.9, 0.3, 1.0)
		"ground_stab":   # Grimtooth: drive the weapon into the ground
			var up: = _ph(k, 0.0, 0.38, 0.5)
			var down: = _ph(k, 0.38, 0.5, 2.6)
			hips.position.y += (0.15 * up * (1.0 - down) - 0.3 * down) * rec
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-2.9, -0.1, down), maxf(up, down) * rec), 0.0, -0.1)
			arm_l.rotation = Vector3(lerpf(-0.2, lerpf(-2.7, -0.2, down), maxf(up, down) * rec), 0.0, 0.1)
			torso.rotation.x += (-0.2 * up + 0.9 * down) * rec
			leg_l.rotation.x = -1.0 * down * rec
			leg_r.rotation.x = 0.8 * down * rec
		"asura":   # Asura Strike: gather glowing power, then a blinding dash-punch
			var gather: = _ph(k, 0.0, 0.62, 0.7)
			var strike: = _ph(k, 0.64, 0.76, 2.4)
			var shake: = sin(_t * 60.0) * 0.03 * gather * (1.0 - strike)
			hips.position.y += (-0.18 * gather * (1.0 - strike)) * rec
			hips.position.z = (0.04 * shake + 1.2 * strike) * rec
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(0.4, -1.6, strike), maxf(gather, strike) * rec), lerpf(0.0, 0.5 * (1.0 - strike), gather) * rec, -0.2)
			arm_r.position.z = (-0.12 * gather * (1.0 - strike) + 0.25 * strike) * rec
			arm_l.rotation = Vector3(lerpf(-0.2, lerpf(-1.2, 0.4, strike), maxf(gather, strike) * rec), 0.0, 0.4)
			torso.rotation.y += (0.6 * gather * (1.0 - strike) - 0.4 * strike) * rec + shake
			torso.rotation.x += (0.2 * gather + 0.25 * strike) * rec
			leg_l.rotation.x = (-0.5 * gather - 0.5 * strike) * rec
			leg_r.rotation.x = (0.45 * gather + 0.4 * strike) * rec
		"cross_slash":   # Holy Cross: two diagonal cuts making an X
			var a1: = _ph(k, 0.1, 0.32, 2.0)
			var back: = _ph(k, 0.34, 0.44, 0.6)
			var a2: = _ph(k, 0.44, 0.58, 2.0)
			var z: = lerpf(lerpf(lerpf(-1.4, 0.8, a1), 0.9, back), -1.2, a2)
			var x: = lerpf(lerpf(lerpf(-2.6, -0.5, a1), -2.6, back), -0.5, a2)
			arm_r.rotation = Vector3(lerpf(-0.6, x, rec), 0.0, lerpf(-0.3, z, rec))
			torso.rotation.y += (0.4 * (a1 - a2)) * rec
			torso.rotation.x += 0.2 * maxf(a1, a2) * rec
			leg_l.rotation.x = -0.4 * rec
			if not _trail_sent and k >= 0.2:
				_trail_sent = true
				FX.trail(self, Color(1.0, 0.92, 0.55), -60.0, 60.0, 1.1, PI * 0.25, 1.0)
				get_tree().create_timer(0.2).timeout.connect(func() -> void:
					if is_inside_tree():
						FX.trail(self, Color(1.0, 0.92, 0.55), 60.0, -60.0, 1.1, -PI * 0.25, 1.0))
		"shield_bash":   # Shield Charge: shoulder forward behind the shield
			var go: = _ph(k, 0.15, 0.36, 2.0)
			var lean: = _ph(k, 0.0, 0.15)
			arm_l.rotation = Vector3(lerpf(-0.2, -1.5, maxf(lean, go)) * rec, 0.0, 0.1)
			arm_l.position.z = 0.25 * go * rec
			arm_r.rotation = Vector3(-0.3 * rec, 0.0, -0.3)
			hips.position.z = 0.55 * go * rec
			torso.rotation.y += (-0.5 * lean + 0.3 * go) * rec
			torso.rotation.x += 0.3 * go * rec
			leg_l.rotation.x = -0.8 * go * rec
			leg_r.rotation.x = 0.5 * go * rec
		"cross_pose":   # Grand Cross / Gospel: arms spread wide, head back
			var open: = _ph(k, 0.0, 0.5, 0.5)
			var flare: = _ph(k, 0.5, 0.6, 2.0)
			arm_r.rotation = arm_r.rotation.lerp(Vector3(-0.2, 0.0, -1.5), open * rec)
			arm_l.rotation = arm_l.rotation.lerp(Vector3(-0.2, 0.0, 1.5), open * rec)
			torso.rotation.x -= (0.15 * open + 0.15 * flare) * rec
			head.rotation.x -= (0.3 * open + 0.15 * flare) * rec
			hips.position.y += 0.1 * open * rec
		"cast_ground":   # Earth Spike / Heaven's Drive: palm slammed to the ground
			var up: = _ph(k, 0.0, 0.35, 0.5)
			var down: = _ph(k, 0.38, 0.5, 2.4)
			hips.position.y -= 0.35 * down * rec
			torso.rotation.x += (-0.2 * up + 0.8 * down) * rec
			arm_l.rotation = Vector3(lerpf(-0.2, lerpf(-2.7, -0.3, down), maxf(up, down) * rec), 0.0, 0.2)
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.0, -0.5, down), maxf(up, down) * rec), 0.0, -0.25)
			leg_l.rotation.x = -1.1 * down * rec
			leg_r.rotation.x = 0.8 * down * rec
		"uppercut":   # Tiger Knuckle Fist / Occult Impaction: rising strike
			var dip: = _ph(k, 0.0, 0.3, 0.5)
			var rise: = _ph(k, 0.3, 0.45, 2.0)
			hips.position.y += (-0.15 * dip * (1.0 - rise) + 0.15 * rise) * rec
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-0.2, -2.8, rise), maxf(dip, rise) * rec), 0.0, -0.15)
			arm_l.rotation = Vector3(lerpf(-0.2, -1.0, dip) * rec, 0.0, 0.3)
			torso.rotation.x += (0.3 * dip * (1.0 - rise) - 0.25 * rise) * rec
			torso.rotation.y += (0.4 * dip - 0.5 * rise) * rec
			leg_l.rotation.x = -0.5 * rise * rec
		"chop":   # Mammonite / axe skills: big overhead chop
			var up: = _ph(k, 0.0, 0.4, 0.5)
			var hit: = _ph(k, 0.4, 0.52, 2.6)
			var x: = lerpf(lerpf(-0.6, -3.2, up), 0.05, hit)
			arm_r.rotation = Vector3(lerpf(-0.6, x, rec), 0.0, -0.1)
			arm_l.rotation = Vector3(lerpf(-0.2, x * 0.9, rec), 0.0, 0.15)
			torso.rotation.x += (-0.4 * up + 0.75 * hit) * rec
			hips.position.y += (0.05 * up - 0.18 * hit) * rec
			leg_l.rotation.x = -0.6 * hit * rec
			leg_r.rotation.x = 0.35 * hit * rec
			if not _trail_sent and k >= 0.42:
				_trail_sent = true
				FX.trail(self, trail_color, 120.0, -40.0, 1.05, PI * 0.5, 1.2)
		_:
			_slash_attack(k)
	if hold == "two_hand" and kind in ["power_strike", "thrust_combo", "spin", "slam", "thrust", "spiral", "sweep", "chop", "dash"]:
		arm_l.rotation = Vector3(arm_r.rotation.x - 0.05, - arm_r.rotation.y - 0.55, - arm_r.rotation.z + 0.1)




## Ragnarok-style basic attack per weapon type (sword keeps the 3-hit slash combo).
func _weapon_attack(k: float) -> bool:
	var wind: = ease(clampf(k / 0.35, 0.0, 1.0), 0.5)
	var strike: = ease(clampf((k - 0.35) / 0.2, 0.0, 1.0), 2.2)
	var off: = 1.0 - ease(clampf((k - 0.6) / 0.4, 0.0, 1.0), 0.6)
	match weapon_kind:
		"spear":   # thrust from the hip
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-1.1, -1.55, strike), maxf(wind, strike) * off), lerpf(0.0, 0.35 * (1.0 - strike), wind) * off, -0.05)
			arm_r.position.z = (-0.1 * wind + 0.3 * strike) * off
			torso.rotation.y += (0.4 * wind - 0.45 * strike) * off
			hips.position.z = 0.25 * strike * off
			leg_l.rotation.x = -0.6 * strike * off
			leg_r.rotation.x = 0.35 * strike * off
			if not _trail_sent and k >= 0.36:
				_trail_sent = true
				FX.trail(self, trail_color, -6.0, 6.0, 1.0, 0.0, 1.5)
		"axe", "mace", "book":   # overhead chop / bonk, then a side swing
			if _combo == 1:
				return false
			var x: = lerpf(lerpf(-0.6, -3.0, wind), -0.1, strike)
			arm_r.rotation = Vector3(lerpf(-0.6, x, off), 0.0, -0.15)
			if hold == "two_hand" or not has_shield:
				arm_l.rotation = Vector3(lerpf(-0.2, x * (0.9 if hold == "two_hand" else 0.3), off), 0.0, 0.2)
			torso.rotation.x += (-0.3 * wind + 0.55 * strike) * off
			hips.position.y += (0.04 * wind - 0.12 * strike) * off
			leg_l.rotation.x = -0.5 * strike * off
			leg_r.rotation.x = 0.3 * strike * off
			if not _trail_sent and k >= 0.37:
				_trail_sent = true
				FX.trail(self, trail_color, 110.0, -30.0, 0.95, PI * 0.5, 1.0)
		"greatsword":   # heavy two-handed swings: diagonal, overhead, rising
			var z0: float = [-1.4, 0.0, 1.0][_combo]
			var x0: float = [-2.2, -3.0, -0.3][_combo]
			var x1: float = [-0.6, -0.1, -2.6][_combo]
			var z1: float = [0.9, 0.0, -0.9][_combo]
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(x0, x1, strike), maxf(wind, strike) * off), 0.0, lerpf(-0.2, lerpf(z0, z1, strike), maxf(wind, strike) * off))
			torso.rotation.y += ((0.6 * wind - 0.9 * strike) if _combo != 1 else 0.0) * off
			torso.rotation.x += (0.45 * strike if _combo == 1 else 0.15 * strike) * off
			hips.position.y -= 0.12 * strike * off
			leg_l.rotation.x = -0.6 * strike * off
			leg_r.rotation.x = 0.35 * strike * off
			if not _trail_sent and k >= 0.37:
				_trail_sent = true
				var a0: float = [-110.0, 110.0, 40.0][_combo]
				var a1: float = [70.0, -30.0, -120.0][_combo]
				var tilt: float = [0.15, PI * 0.5, -0.2][_combo]
				FX.trail(self, trail_color, a0, a1, 1.25, tilt, 1.2)
		"dagger":   # quick stab, slash, stab
			if _combo == 1:
				return false
			var fast: = ease(clampf((k - 0.25) / 0.15, 0.0, 1.0), 2.0)
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-0.8, -1.6, fast), off), lerpf(0.3, -0.1, fast) * off, -0.1)
			arm_r.position.z = 0.22 * fast * off
			torso.rotation.y += (0.3 - 0.5 * fast) * off
			hips.position.z = 0.15 * fast * off
			leg_l.rotation.x = -0.45 * fast * off
			if not _trail_sent and k >= 0.3:
				_trail_sent = true
				FX.trail(self, trail_color, -10.0, 10.0, 0.85, 0.0, 1.2)
		"katar":   # Assassin: alternating left/right jabs with both katars
			var l: = _combo % 2 == 1
			var jab: = ease(clampf((k - 0.25) / 0.17, 0.0, 1.0), 2.0)
			var punch: = Vector3(lerpf(-0.9, -1.6, jab), 0.0, 0.0)
			var guard: = Vector3(-1.1, 0.0, 0.0)
			arm_r.rotation = (guard if l else punch).lerp(Vector3(-0.6, 0.0, -0.2), 1.0 - off)
			arm_l.rotation = (punch if l else guard).lerp(Vector3(-0.2, 0.0, 0.2), 1.0 - off)
			if l:
				arm_l.position.z = 0.22 * jab * off
			else:
				arm_r.position.z = 0.22 * jab * off
			torso.rotation.y += (0.35 if l else -0.35) * jab * off
			hips.position.y -= 0.06 * off
			leg_l.rotation.x = -0.45 * off
			leg_r.rotation.x = 0.3 * off
			if not _trail_sent and k >= 0.3:
				_trail_sent = true
				FX.trail(self, trail_color, -10.0, 10.0, 0.85, 0.0, 1.2)
		"knuckle", "none":   # Monk: jab, cross, uppercut
			var up: = _combo == 2
			var l: = _combo == 0
			var hit: = ease(clampf((k - 0.25) / 0.17, 0.0, 1.0), 2.0)
			var arm: Node3D = arm_l if l else arm_r
			var other: Node3D = arm_r if l else arm_l
			arm.rotation = Vector3(lerpf(-0.9, -2.6 if up else -1.6, hit), 0.0, 0.0).lerp(arm.rotation, 1.0 - off)
			other.rotation = Vector3(-1.1, 0.0, 0.0).lerp(other.rotation, 1.0 - off)
			arm.position.z = (0.08 if up else 0.22) * hit * off
			torso.rotation.y += (0.35 if l else -0.4) * hit * off
			hips.position.y += (0.1 * hit if up else -0.05) * off
			leg_l.rotation.x = -0.45 * off
			leg_r.rotation.x = 0.3 * off
		"lute":   # Bard: strum, then swing the instrument
			if _combo != 0:
				return false
			var beat: = sin(k * PI * 6.0)
			arm_r.rotation = Vector3(-1.0 + 0.3 * beat * off, 0.5, -0.25)
			arm_l.rotation = Vector3(-1.3, -0.4, 0.4)
			hips.position.y += absf(beat) * 0.04 * off
			head.rotation.z += 0.1 * beat * off
		"whip":   # Dancer: whip crack forward
			var back: = _ph(k, 0.0, 0.35, 0.5)
			var crack: = _ph(k, 0.35, 0.45, 2.6)
			arm_r.rotation = Vector3(lerpf(-0.6, lerpf(-2.8, -1.1, crack), maxf(back, crack) * off), 0.0, lerpf(-0.2, -0.6, back) * off)
			torso.rotation.y += (0.5 * back - 0.6 * crack) * off
			hips.rotation.z += 0.08 * crack * off
			leg_l.rotation.x = -0.4 * crack * off
			if not _trail_sent and k >= 0.37:
				_trail_sent = true
				FX.trail(self, trail_color, 90.0, -10.0, 1.6, PI * 0.5, 0.8)
		_:
			return false
	return true


func _slash_attack(k: float) -> void:
	var wind: = ease(clampf(k / 0.35, 0.0, 1.0), 0.5)
	var strike: = ease(clampf((k - 0.35) / 0.22, 0.0, 1.0), 2.2)
	var rec: = ease(clampf((k - 0.6) / 0.4, 0.0, 1.0), 0.6)
	var off: = 1.0 - rec
	if not _trail_sent and k >= 0.36:
		_trail_sent = true
		match _combo:
			0:
				FX.trail(self, trail_color, -110.0, 70.0, 1.05, 0.15)
			1:
				FX.trail(self, trail_color, 100.0, -20.0, 0.95, PI * 0.5, 0.9)
			2:
				FX.trail(self, trail_color, -18.0, 18.0, 1.0, 0.0, 1.25)
	match _combo:
		0:
			var x: = lerpf(-0.6, -1.35, wind)
			var z: = lerpf(-0.3, -1.2, wind)
			z = lerpf(z, 0.75, strike)
			arm_r.rotation = Vector3(lerpf(-0.6, x, off), lerpf(0.25, -0.3 * strike, off), lerpf(-0.3, z, off))
			torso.rotation.y += (0.55 * wind - 1.05 * strike) * off
			arm_l.rotation = Vector3(-0.3, 0.2, 0.35 + 0.3 * strike * off)
			leg_l.rotation.x = -0.25 * off
		1:
			var x: = lerpf(-0.6, -2.9, wind)
			x = lerpf(x, -0.25, strike)
			arm_r.rotation = Vector3(lerpf(-0.6, x, off), 0.0, -0.18)
			if not has_shield:
				arm_l.rotation = Vector3(lerpf(-0.15, x * 0.85, off), 0.0, 0.25)
			torso.rotation.x += (-0.18 * wind + 0.4 * strike) * off
			hips.position.y -= 0.06 * strike * off
			leg_l.rotation.x = -0.45 * strike * off
			leg_r.rotation.x = 0.25 * strike * off
		_:
			var x: = lerpf(-0.6, -0.85, wind)
			x = lerpf(x, -1.6, strike)
			arm_r.rotation = Vector3(lerpf(-0.6, x, off), lerpf(0.25, -0.15, off), lerpf(-0.3, -0.05, off))
			arm_r.position.z = (-0.08 * wind + 0.18 * strike) * off
			torso.rotation.y += (0.45 * wind - 0.55 * strike) * off
			torso.rotation.x += 0.18 * strike * off
			hips.position.z = 0.22 * strike * off
			leg_l.rotation.x = -0.7 * strike * off
			leg_r.rotation.x = 0.4 * strike * off


func _hurt_anim(delta: float) -> void:
	if _hurt_t >= 0.0:
		_hurt_t += delta
		var h: = sin(clampf(_hurt_t / 0.25, 0.0, 1.0) * PI)
		torso.rotation.x -= 0.25 * h
		head.rotation.x -= 0.2 * h
		if _hurt_t > 0.25:
			_hurt_t = -1.0
