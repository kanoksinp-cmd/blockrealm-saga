class_name Monster
extends CharacterBody3D
## Base monster: wander around its spawn point, aggro / chase the player,
## telegraphed attack, take damage, die, respawn.
## Subclasses build the model and animate it (_build_model, _animate, _attack_motion).

signal died(monster: Monster)

enum State { IDLE, WANDER, CHASE, ATTACK, DEAD }

@export var display_name := "Monster"
@export var level := 1
@export var max_hp := 50
@export var damage_min := 5
@export var damage_max := 8
@export var move_speed := 1.6
@export var chase_speed := 2.8
@export var aggro_range := 0.0          ## 0 = passive until hit
@export var attack_range := 1.3
@export var attack_time := 1.0          ## whole attack action length
@export var hit_time := 0.6             ## when in the action the damage lands
@export var attack_cooldown := 1.4
@export var exp_reward := 20
@export var wander_radius := 7.0
@export var leash_range := 20.0
@export var respawn_time := 12.0
@export var hit := 20
@export var flee := 5
@export var def := 0
@export var drops: Array = []               ## [[item_id, chance 0..1], ...]
@export var body_radius := 0.45
@export var body_height := 0.8
@export var size := 1.0

var hp := 0
var state := State.IDLE
var target: Node3D
var home := Vector3.ZERO
var model: Node3D
var bar: HpBar3D

var _t := 0.0
var _state_t := 0.0
var _wander_to := Vector3.ZERO
var _cooldown := 0.0
var _hit_done := false
var _hurt_t := -1.0
var _attack_dir := Vector3.FORWARD
var _rng := RandomNumberGenerator.new()
var _shape: CollisionShape3D
var stolen := false
var _freeze_t := 0.0
var _poison_t := 0.0
var _poison_dmg := 0
var _poison_tick := 0.0


func _ready() -> void:
	_rng.randomize()
	add_to_group("monster")
	collision_layer = 2
	collision_mask = 1
	home = global_position
	hp = max_hp
	_shape = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = body_radius * size
	cap.height = maxf(body_height * size, cap.radius * 2.0)
	_shape.shape = cap
	_shape.position.y = cap.height * 0.5
	add_child(_shape)
	model = Node3D.new()
	model.name = "Model"
	add_child(model)
	_build_model(model)
	model.scale = Vector3.ONE * size
	model.rotation.y = _rng.randf() * TAU
	bar = HpBar3D.new()
	bar.width = 0.7 + 0.2 * size
	add_child(bar)
	bar.position.y = body_height * size + 0.45
	bar.set_label("%s  Lv%d" % [display_name, level])
	bar.visible = false
	_t = _rng.randf() * 10.0
	_enter(State.IDLE)


# ------------------------------------------------------------------ overridables
func _build_model(_root: Node3D) -> void:
	pass


func _animate(_delta: float) -> void:
	pass


## Called every physics frame during ATTACK. k = 0..1 progress. Return extra velocity.
func _attack_motion(_k: float, _delta: float) -> Vector3:
	return Vector3.ZERO


func _on_hit_landed() -> void:
	pass


# ------------------------------------------------------------------ combat
func is_alive() -> bool:
	return state != State.DEAD


var _hovered := false
var locked := false


func set_hovered(b: bool) -> void:
	if state == State.DEAD:
		b = false
	_hovered = b
	_update_bar()
	_refresh_outline()


## Target lock (the player's current attack target): pulsing orange-gold outline.
func set_locked(b: bool) -> void:
	locked = b and state != State.DEAD
	_update_bar()
	_refresh_outline()


## Name + HP bar: shown while hovered, targeted or hurt; never on a dead monster.
func _update_bar() -> void:
	if state == State.DEAD:
		bar.visible = false
		return
	bar.set_label("%s  Lv%d" % [tr(display_name), level])
	bar.set_label_color(level_color(level))
	bar.visible = _hovered or locked or hp < max_hp


## Name colour by level difference to the player (RO-style "con" colours).
static func level_color(lv: int) -> Color:
	var diff := lv - Game.base_level
	if diff <= -10:
		return Color(0.45, 0.45, 0.48)      # trivial - grey
	if diff <= -3:
		return Color(0.1, 0.55, 0.15)       # easy - green
	if diff <= 2:
		return Color(0.05, 0.05, 0.07)      # even - black
	if diff <= 5:
		return Color(0.85, 0.5, 0.0)        # tough - orange
	if diff <= 9:
		return Color(0.85, 0.1, 0.1)        # dangerous - red
	return Color(0.55, 0.1, 0.75)           # deadly - purple


func _refresh_outline() -> void:
	if state == State.DEAD:
		Outline.apply(model, null)
	elif locked:
		Outline.apply(model, Outline.LOCK)
	elif _hovered:
		Outline.apply(model, Outline.ENEMY)
	else:
		Outline.apply(model, null)


func take_damage(amount: int, from: Node3D = null, crit := false) -> void:
	if state == State.DEAD:
		return
	amount = maxi(1, amount - def)
	hp -= amount
	if Settings.g("damage_numbers"):
		FX.popup(self, global_position + Vector3(0, body_height * size + 0.2, 0), str(amount) + ("!" if crit else ""),
				Color(1.0, 0.85, 0.2) if crit else Color(1, 1, 1), 64 if crit else 56)
	bar.set_ratio(float(hp) / max_hp)
	_update_bar()
	_hurt_t = 0.0
	Audio.play("crit" if crit else ("hit_heavy" if amount > max_hp / 4 else "hit"), global_position)
	if hp > 0 and randf() < 0.35:
		Audio.play("mob_hurt", global_position, 0.0, 0.15)
	if from and is_instance_valid(from):
		target = from
		if state == State.IDLE or state == State.WANDER:
			_enter(State.CHASE)
		# small knockback
		var away := global_position - from.global_position
		away.y = 0
		if away.length() > 0.01:
			velocity += away.normalized() * (1.6 if crit else 0.7)
	if hp <= 0:
		hp = 0
		if from and from.has_method("gain_exp"):
			from.gain_exp(int(exp_reward * Guild.exp_mult() * Game.monster_exp_multiplier(level)))
			# online party: members near this kill get a share
			if from.is_in_group("player") or from.is_in_group("party"):
				Net.share_exp(int(exp_reward * Guild.exp_mult() * Game.monster_exp_multiplier(level)), global_position)
		Game.on_kill(display_name)
		_drop_zeny()
		# loot goes straight into the bag of the player (or the party leader)
		var looter: Node3D = null
		if from and is_instance_valid(from) and (from.is_in_group("player") or from.is_in_group("party")):
			looter = get_tree().get_first_node_in_group("player") as Node3D
		var n_drop := 0
		for d in drops:
			if _rng.randf() < minf(1.0, float(d[1]) * Game.event_mult("drop")):
				var di := DropItem.spawn(self, global_position, d[0], int(d[2]) if d.size() > 2 else 1)
				if looter:
					di.collect(looter, 0.45 + n_drop * 0.12)
				n_drop += 1
		_die()


## Every kill pays Zeny straight to your purse (bosses x10), with a small
## chance of a jackpot pouch worth five times as much.
func _drop_zeny() -> void:
	var z := level * _rng.randi_range(6, 12) + 10
	var jackpot := _rng.randf() < 0.08
	if jackpot:
		z *= 5
	if has_meta("boss"):
		z *= 10
	Game.add_zeny(z)
	Audio.play("jackpot" if jackpot else "coin", global_position)
	FX.popup(self, global_position + Vector3(0, body_height * size + 0.7, 0), "+%d z" % z, Color(1.0, 0.82, 0.25), 60 if jackpot else 44, 0.9)
	if jackpot:
		Game.log_msg(tr("Jackpot! The monster dropped a pouch of %d Zeny.") % z, Color(1.0, 0.85, 0.3))


## Status effects from player skills: "freeze" (cannot act) and "poison" (damage over time).
func apply_status(kind: String, seconds: float, power := 0) -> void:
	if state == State.DEAD:
		return
	if kind == "freeze":
		_freeze_t = seconds
		FX.popup(self, global_position + Vector3(0, body_height * size + 0.6, 0), "Frozen!", Color(0.6, 0.85, 1.0), 40, 0.6)
	elif kind == "stun":
		_freeze_t = seconds
		FX.popup(self, global_position + Vector3(0, body_height * size + 0.6, 0), "Stunned!", Color(1.0, 0.85, 0.3), 40, 0.6)
	elif kind == "poison":
		_poison_t = seconds
		_poison_dmg = maxi(1, power)
		FX.popup(self, global_position + Vector3(0, body_height * size + 0.6, 0), "Poisoned!", Color(0.6, 0.95, 0.3), 40, 0.6)


func _die() -> void:
	Audio.play("mob_die", global_position, 0.0, 0.12)
	_freeze_t = 0.0
	_poison_t = 0.0
	locked = false
	_hovered = false
	_enter(State.DEAD)
	bar.visible = false
	Outline.apply(model, null)
	collision_layer = 0
	died.emit(self)


func _respawn() -> void:
	global_position = home + Vector3(_rng.randf_range(-2, 2), 0.2, _rng.randf_range(-2, 2))
	hp = max_hp
	stolen = false
	bar.set_ratio(1.0)
	bar.visible = false
	collision_layer = 2
	target = null
	model.visible = true
	model.scale = Vector3.ONE * size
	model.rotation = Vector3(0, _rng.randf() * TAU, 0)
	model.position = Vector3.ZERO
	_enter(State.IDLE)


# ------------------------------------------------------------------ state machine
func _enter(s: State) -> void:
	state = s
	_state_t = 0.0
	match s:
		State.IDLE:
			_state_t = -_rng.randf_range(1.0, 4.0)
		State.WANDER:
			var a := _rng.randf() * TAU
			var r := _rng.randf_range(1.5, wander_radius)
			_wander_to = home + Vector3(cos(a) * r, 0, sin(a) * r)
		State.ATTACK:
			_hit_done = false
			if target:
				var d := target.global_position - global_position
				d.y = 0
				if d.length() > 0.01:
					_attack_dir = d.normalized()


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _target_alive() -> bool:
	return target != null and is_instance_valid(target) and (not target.has_method("is_alive") or target.is_alive())


func _physics_process(delta: float) -> void:
	_t += delta
	_state_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	var want := Vector3.ZERO
	if _poison_t > 0.0 and state != State.DEAD:
		_poison_t -= delta
		_poison_tick += delta
		if _poison_tick >= 1.0:
			_poison_tick = 0.0
			hp = maxi(1, hp - _poison_dmg)
			bar.set_ratio(float(hp) / max_hp)
			if Settings.g("damage_numbers"):
				FX.popup(self, global_position + Vector3(0, body_height * size + 0.2, 0), str(_poison_dmg), Color(0.6, 0.95, 0.3), 40)
	if _freeze_t > 0.0 and state != State.DEAD:
		_freeze_t -= delta
		velocity = Vector3(0, velocity.y - 20.0 * delta, 0)
		move_and_slide()
		return

	match state:
		State.IDLE:
			if _state_t > 0.0:
				_enter(State.WANDER)
			_look_for_player()
		State.WANDER:
			var to := _wander_to - global_position
			to.y = 0
			if to.length() < 0.3 or _state_t > 8.0:
				_enter(State.IDLE)
			else:
				want = to.normalized() * move_speed
			_look_for_player()
		State.CHASE:
			if not _target_alive() or global_position.distance_to(home) > leash_range:
				target = null
				_enter(State.WANDER)
				_wander_to = home
			else:
				var to := target.global_position - global_position
				to.y = 0
				if to.length() <= attack_range and _cooldown <= 0.0:
					_enter(State.ATTACK)
				elif to.length() > attack_range * 0.8:
					want = to.normalized() * chase_speed
				else:
					_face(to, delta)
		State.ATTACK:
			var k := _state_t / attack_time
			want = _attack_motion(clampf(k, 0.0, 1.0), delta)
			if not _hit_done and _state_t >= hit_time:
				_hit_done = true
				_try_hit()
			if k >= 1.0:
				_cooldown = attack_cooldown
				_enter(State.CHASE)
		State.DEAD:
			if _state_t > respawn_time:
				_respawn()

	if state != State.DEAD:
		if want.length() > 0.01 and state != State.ATTACK:
			_face(want, delta)
		var damp := 1.0 - exp(-8.0 * delta)
		velocity.x = lerpf(velocity.x, want.x, damp)
		velocity.z = lerpf(velocity.z, want.z, damp)
		if is_on_floor():
			velocity.y = -0.5
		else:
			velocity.y -= 20.0 * delta
		move_and_slide()
	if _hurt_t >= 0.0:
		_hurt_t += delta
		if _hurt_t > 0.3:
			_hurt_t = -1.0
	_animate(delta)


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.001:
		return
	model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-10.0 * delta))


func _look_for_player() -> void:
	if aggro_range <= 0.0:
		return
	var p := _player()
	if p and (not p.has_method("is_alive") or p.is_alive()) and p.global_position.distance_to(global_position) < aggro_range:
		target = p
		FX.popup(self, global_position + Vector3(0, body_height * size + 0.5, 0), "!", Color(1, 0.3, 0.2), 72, 0.4)
		_enter(State.CHASE)


func _try_hit() -> void:
	if not _target_alive():
		return
	var d := target.global_position - global_position
	d.y = 0
	if d.length() <= attack_range + 0.6:
		_on_hit_landed()
		if target.has_method("take_damage"):
			target.take_damage(_rng.randi_range(damage_min, damage_max), self)
