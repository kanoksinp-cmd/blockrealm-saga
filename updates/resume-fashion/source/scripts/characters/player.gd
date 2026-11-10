extends CharacterBody3D






signal stats_changed

@export var move_speed: = 4.2
@export var turn_speed: = 12.0
@export var gravity: = 20.0
@export var attack_range: = 1.9
@export var talk_range: = 2.6

@onready var model: KnightModel = $Model

var attack_target: Monster
var interact_target: Node3D
var hovered: Node3D

var _target: = Vector3.ZERO
var _has_target: = false
var _marker: Node3D
var _marker_ring: MeshInstance3D
var _marker_arrow: Node3D
var _marker_mat: StandardMaterial3D
var _arrow_mat: StandardMaterial3D
var _marker_t: = 0.0
var _drop_t: = 9.0
var _hold_t: = 0.0
var _stuck_t: = 0.0
var _cooldown: = 0.0
var _dead: = false
var _dead_t: = 0.0
var _since_hurt: = 99.0
var _regen_t: = 0.0
var _pending_skill: = ""
var _skill_fire: = ""
var _skill_target: Monster
var _casting: = { }
var _release_queue: = ""
var _cast_ring: MeshInstance3D

var _path: = PackedVector3Array()
var _path_goal: = Vector3(INF, 0, INF)


const RUN_DIST: = 16.0
const RUN_MULT: = 1.6
var _run_k: = 0.0
var _run_dust: CPUParticles3D
var _path_t: = 0.0
var _path_failed: = false
var _travel_warp: = { }
var _warping: = false
var _unreachable: = { }
var _last_safe_position: = Vector3.INF
var _restoring_resume := true

var _auto_t: = 0.0
var _auto_home: = Vector3.ZERO
var _potion_cd: = 0.0
var _rng: = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	add_to_group("player")
	collision_layer = 4
	collision_mask = 1
	model.attack_hit.connect(_on_attack_hit)
	get_tree().process_frame.connect(func () -> void: Party.sync(), CONNECT_ONE_SHOT)
	UiCursors.install()

	_marker = Node3D.new()
	_marker.top_level = true
	_marker.visible = false
	add_child(_marker)
	_marker_ring = MeshInstance3D.new()
	var torus: = TorusMesh.new()
	torus.inner_radius = 0.32
	torus.outer_radius = 0.42
	torus.rings = 16
	torus.ring_segments = 6
	_marker_ring.mesh = torus
	_marker_mat = StandardMaterial3D.new()
	_marker_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker_mat.albedo_color = Color(1.0, 0.85, 0.3)
	_marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_marker_ring.material_override = _marker_mat
	_marker.add_child(_marker_ring)
	_arrow_mat = StandardMaterial3D.new()
	_arrow_mat.albedo_color = Color(1.0, 0.85, 0.3)
	_arrow_mat.emission_enabled = true
	_arrow_mat.emission = Color(1.0, 0.75, 0.2)
	_arrow_mat.emission_energy_multiplier = 0.6
	_arrow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_marker_arrow = Node3D.new()
	_marker.add_child(_marker_arrow)
	var tilt: = Node3D.new()
	tilt.rotation_degrees = Vector3(18, 35, 0)
	_marker_arrow.add_child(tilt)
	var shaft: = MeshInstance3D.new()
	var sm: = BoxMesh.new()
	sm.size = Vector3(0.09, 0.62, 0.09)
	shaft.mesh = sm
	shaft.position.y = 0.55
	shaft.material_override = _arrow_mat
	tilt.add_child(shaft)
	var head: = MeshInstance3D.new()
	var hm: = CylinderMesh.new()
	hm.top_radius = 0.22
	hm.bottom_radius = 0.0
	hm.height = 0.32
	hm.radial_segments = 4
	head.mesh = hm
	head.position.y = 0.12
	head.material_override = _arrow_mat
	tilt.add_child(head)
	for k in 2:
		var fin: = MeshInstance3D.new()
		var fm: = BoxMesh.new()
		fm.size = Vector3(0.26, 0.16, 0.03)
		fin.mesh = fm
		fin.position.y = 0.86
		fin.rotation_degrees.y = 90.0 * k
		var fmat: = _arrow_mat.duplicate() as StandardMaterial3D
		fmat.albedo_color = Color(0.95, 0.3, 0.25)
		fmat.emission = Color(0.6, 0.1, 0.05)
		fin.material_override = fmat
		tilt.add_child(fin)
	_cast_ring = MeshInstance3D.new()
	var ct: = TorusMesh.new()
	ct.inner_radius = 0.75
	ct.outer_radius = 0.9
	ct.rings = 24
	ct.ring_segments = 4
	_cast_ring.mesh = ct
	var cm: = StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color(0.6, 0.8, 1.0, 0.8)
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cast_ring.material_override = cm
	_cast_ring.position.y = 0.05
	_cast_ring.visible = false
	add_child(_cast_ring)
	global_position = Game.save_point
	_update_range()
	Game.changed.connect(_sync_weapon)
	_sync_weapon()
	_restore_resume_checkpoint.call_deferred()


var _shown_weapon: = "?"



func _sync_weapon() -> void:
	if Game.appearance.is_empty():
		return
	model.refresh_look()


func _update_range() -> void:
	if not Game.appearance.is_empty():
		attack_range = Game.job_info().range + (Game.range_bonus() if Game.job_info().anim == "shoot" else 0.0)
		if Items.weapon_type(Game.equip.get("weapon", "")) == "spear" and attack_range < 3.0:
			attack_range += 0.6


func is_alive() -> bool:
	return not _dead


func is_casting() -> bool:
	return not _casting.is_empty()


func cast_progress() -> float:
	return 0.0 if _casting.is_empty() else clampf(_casting.t / _casting.total, 0.0, 1.0)



func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if touch_controls or Game.get_meta("cam_gesture", false):
			return
		_last_press_ms = Time.get_ticks_msec()
		_click(event.position, true)
		_hold_t = 0.0
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_stop_all()
		if model.attack():
			_cooldown = Game.attack_interval()


var _last_press_ms: = -100000


var touch_controls: = false



func cancel_walk() -> void:
	if Time.get_ticks_msec() - _last_press_ms < 600:
		_stop_all()
	_hold_t = 0.0


func _stop_all(preserve_gather := false) -> void:
	if not preserve_gather: _clear_auto_gather()
	_end_gather()
	_has_target = false
	attack_target = null
	interact_target = null
	_pending_skill = ""
	_path = PackedVector3Array()
	_travel_warp = { }
	_cancel_cast()


func _pick(screen_pos: Vector2) -> Dictionary:
	var cam: = get_viewport().get_camera_3d()
	if cam == null:
		return { }
	var from: = cam.project_ray_origin(screen_pos)
	var dir: = cam.project_ray_normal(screen_pos)
	var q: = PhysicsRayQueryParameters3D.create(from, from + dir * 600.0, 1 | 2 | 8 | 16 | 64 | 128)
	q.exclude = [get_rid()]
	var hit: = get_world_3d().direct_space_state.intersect_ray(q)
	hit["from"] = from
	hit["dir"] = dir
	return hit


func _click(screen_pos: Vector2, fresh: bool) -> void:
	if Game.mouse_over_ui:
		return
	var hit: = _pick(screen_pos)
	if hit.is_empty():
		return
	var col = hit.get("collider")
	if col is Monster and (col as Monster).is_alive():
		_end_gather()
		_travel_warp = { }
		_pending_skill = ""
		attack_target = col
		interact_target = null
		_has_target = false
		_show_marker(attack_target.global_position, Color(1.0, 0.3, 0.25), false)
		return
	if fresh and (col is NPC or col is DropItem or col is GatherNode):
		talk_to(col)
		return
	if col is Node and (col as Node).has_meta("remote_player"):

		if fresh:
			var rp = (col as Node).get_meta("remote_player")
			if is_instance_valid(rp) and Game.ui and Game.ui.has_method("open_player_profile"):
				Game.ui.open_player_profile(rp.id)
		return
	if not fresh and (attack_target != null or interact_target != null):
		return
	var p: Vector3
	var from: Vector3 = hit.from
	var dir: Vector3 = hit.dir
	if hit.has("position") and hit.position.y < 0.3:
		p = hit.position
	elif absf(dir.y) > 0.001:
		p = from + dir * (- from.y / dir.y)
	else:
		return
	go_to(p)



func go_to(p: Vector3, show: = true) -> void:
	_clear_auto_gather()
	_end_gather()
	attack_target = null
	interact_target = null
	_travel_warp = { }
	_pending_skill = ""
	_cancel_cast()
	_target = _standable(Vector3(p.x, 0.0, p.z))


	var nav: = _nav()
	if nav and VillageBuilder.area_at(_target) == VillageBuilder.area_at(global_position) and not nav.line_clear(global_position, _target):
		var pth: = nav.find_path(global_position, _target)
		if pth.size() > 0:
			var last: = pth[pth.size() - 1]
			if Vector2(last.x - _target.x, last.z - _target.z).length() > 0.75:
				_target = last
	_has_target = true
	_stuck_t = 0.0
	_path = PackedVector3Array()
	_auto_home = _target
	if show:
		_show_marker(_target, Color(1.0, 0.85, 0.3))





func _standable(p: Vector3) -> Vector3:
	var nav: = _nav()
	if nav == null:
		return p
	var a: = VillageBuilder.area_at(p)
	if a != VillageBuilder.area_at(global_position):
		return p
	if nav.safe_position(p, a, 0) != Vector3.INF:
		return p
	var c: = Vector2i(floori(p.x), floori(p.z))
	var best: = Vector3.INF
	var best_score: = INF

	for r in range(1, 17):
		if best != Vector3.INF and r - 1 > best_score:
			break
		for dx in range(- r, r + 1):
			for dz in range(- r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var q: = Vector3(c.x + dx + 0.5, 0.0, c.y + dz + 0.5)
				if VillageBuilder.area_at(q) != a or not nav.playable_floor(q):
					continue
				var clear: = true
				for off in [Vector2.ZERO, Vector2(-0.43, -0.43), Vector2(0.43, -0.43), Vector2(-0.43, 0.43), Vector2(0.43, 0.43)]:
					if not nav.walkable(q.x + off.x, q.z + off.y):
						clear = false
						break
				if not clear:
					continue

				var score: = Vector2(q.x - p.x, q.z - p.z).length() + 0.2 * Vector2(q.x - global_position.x, q.z - global_position.z).length()
				if score < best_score:
					best_score = score
					best = q
	return p if best == Vector3.INF else best



func talk_to(n: Node3D) -> void:
	_clear_auto_gather()
	if n is GatherNode and Game.auto_on:
		_set_auto_gather(n)
	_end_gather()
	_travel_warp = { }
	interact_target = n
	attack_target = null
	_has_target = false
	_path = PackedVector3Array()
	_show_marker(n.global_position, Outline.FRIEND if n is NPC else Outline.ITEM)


func _show_marker(pos: Vector3, c: Color, arrow: = true) -> void:
	var np: = Vector3(pos.x, 0.06, pos.z)
	if not _marker.visible or _marker.global_position.distance_to(np) > 1.2 or not _marker_arrow.visible:
		_drop_t = 0.0
	_marker.global_position = np
	_marker_mat.albedo_color = c
	_arrow_mat.albedo_color = Color(c, 1.0)
	_arrow_mat.emission = c * 0.8
	_marker_arrow.visible = arrow
	_marker.visible = true
	_marker_t = 0.0


var _locked: Monster = null



func _update_lock() -> void:
	var now: Monster = attack_target if _valid(attack_target) else null
	if now == _locked:
		return
	if _locked and is_instance_valid(_locked):
		_locked.set_locked(false)
	_locked = now
	if _locked:
		_locked.set_locked(true)


func _update_hover() -> void:
	var now: Node3D = null
	if not Game.mouse_over_ui:
		var hit: = _pick(get_viewport().get_mouse_position())
		var col = hit.get("collider")
		if (col is Monster and (col as Monster).is_alive()) or col is NPC or col is DropItem or col is GatherNode:
			now = col
		elif col is Node and (col as Node).has_meta("remote_player") and is_instance_valid((col as Node).get_meta("remote_player")):
			now = (col as Node).get_meta("remote_player")
	if now == hovered:
		return
	if hovered and is_instance_valid(hovered):
		if hovered is Monster:
			hovered.set_hovered(false)
		elif hovered is NPC:
			hovered.set_hovered(false)
			Outline.apply(hovered.model, null)
		elif hovered is DropItem or hovered is RemotePlayer or hovered is GatherNode:
			hovered.set_hovered(false)
	hovered = now
	var shape: = Input.CURSOR_ARROW
	if hovered is Monster:
		hovered.set_hovered(true)
		shape = Input.CURSOR_CROSS
	elif hovered is NPC:
		hovered.set_hovered(true)
		Outline.apply(hovered.model, Outline.FRIEND)
		shape = Input.CURSOR_HELP
	elif hovered is DropItem or hovered is RemotePlayer or hovered is GatherNode:
		hovered.set_hovered(true)
		shape = Input.CURSOR_POINTING_HAND
	Input.set_default_cursor_shape(shape)



func _skill_range(id: String) -> float:
	var t: String = SkillDB.info(id).type
	if t == "melee" or t == "steal":
		return attack_range + 0.2 if attack_range < 3.0 else 2.2
	return maxf(attack_range, 8.0)


func _valid(m: Monster) -> bool:
	return m != null and is_instance_valid(m) and m.is_alive()


func use_skill(id: String) -> void:
	if _dead or is_casting():
		return
	var s: = SkillDB.info(id)
	var lv: = Game.slv(id)
	if s.is_empty() or lv <= 0:
		return
	if Game.cooldown_left(id) > 0.0:
		Audio.play("ui_error", null, -6.0)
		FX.popup(self, global_position + Vector3(0, 2.1, 0), tr("Cooldown %.1fs") % Game.cooldown_left(id), Color(0.75, 0.8, 0.9), 34, 0.5)
		return
	var cost: = SkillDB.sp_cost(id, lv)
	if Game.sp < cost:
		FX.popup(self, global_position + Vector3(0, 2.1, 0), "Not enough SP", Color(0.6, 0.7, 1.0), 36)
		Audio.play("ui_error")
		return
	if s.has("zeny") and Game.zeny < int(s.zeny) * lv:
		Game.log_msg("Not enough Zeny.", Color(1.0, 0.5, 0.5))
		return
	match s.type:
		"buff", "heal":
			if model.is_attacking():
				return
			_pay(id, lv)
			_apply_self(id, lv)
			return

	if not _valid(attack_target):
		attack_target = _nearest_monster(_skill_range(id) + 4.0)
	if not _valid(attack_target):
		Game.log_msg(tr("%s needs a target.") % tr(Game.skill_name(id)), Color(1.0, 0.6, 0.6))
		return
	interact_target = null
	_has_target = false
	if _flat_dist(attack_target) > _skill_range(id):
		_pending_skill = id
		return
	_start_skill(id)


# A pending skill can outlive its original SP, Zeny or cooldown check.
func _can_execute_skill(id: String) -> bool:
	var spec := SkillDB.info(id)
	var level := Game.slv(id)
	return not _dead and not spec.is_empty() and level > 0 and SkillDB.is_active(id) \
		and Game.cooldown_left(id) <= 0.0 and Game.sp >= SkillDB.sp_cost(id, level) \
		and Game.zeny >= int(spec.get("zeny", 0)) * level

func _start_skill(id: String) -> void:
	_pending_skill = ""
	if not _can_execute_skill(id): return
	var lv: = Game.slv(id)
	var ct: = SkillDB.cast_time(id, lv)
	if ct > 0.0:
		_casting = { "id": id, "t": 0.0, "total": ct, "target": attack_target }
		Audio.play("cast")
		_cast_ring.visible = true
		var cel: = _skill_element(id)
		if cel == "physical":
			FX.magic_circle(self, ELEMENT_COLORS[cel], 1.4, ct + 0.2)
		else:
			ElementFX.circle(self, cel, global_position, 1.7, ct + 0.3, self)
		(_cast_ring.material_override as StandardMaterial3D).albedo_color = SkillDB.info(id).get("color", Color(0.6, 0.8, 1.0, 0.8))
		return
	_release_skill(id)


func _release_skill(id: String) -> void:
	if not _can_execute_skill(id): return
	var lv: = Game.slv(id)
	if model.is_attacking():
		_release_queue = id
		return
	if not model.skill_attack(SkillDB.anim_kind(id, model.weapon_kind, model.anim_style)):
		return
	_pay(id, lv)
	_skill_fire = id
	_skill_sound(id)
	_skill_target = attack_target
	_cooldown = Game.attack_interval()
	var rel: = _skill_element(id)
	_skill_accent(id, global_position, 1.05, "release")
	if rel != "physical" and SkillDB.cast_time(id, lv) <= 0.0:
		ElementFX.circle(self, rel, global_position, 1.4, 0.75, self)
	FX.popup(self, global_position + Vector3(0, 2.3, 0), tr(Game.skill_name(id)) + "!", Color(1.0, 0.9, 0.5), 44, 0.6)


func _pay(id: String, lv: int) -> void:
	Game.start_cooldown(id)
	Game.sp -= SkillDB.sp_cost(id, lv)
	var zc: int = int(SkillDB.info(id).get("zeny", 0)) * lv
	if zc > 0:
		Game.zeny -= zc
	Game.changed.emit()


func _cancel_cast() -> void:
	if not _casting.is_empty():
		_casting = { }
		_cast_ring.visible = false



func _skill_sound(id: String) -> void:
	var s: = SkillDB.info(id)
	match String(s.get("type", "")):
		"melee":
			Audio.play("swing", null, 2.0)
		"steal":
			Audio.play("swing")
		_:
			match _skill_element(id):
				"fire":
					Audio.play("explode", null, -3.0)
				"ice":
					Audio.play("ice")
				"lightning":
					Audio.play("thunder", null, -2.0)
				"holy":
					Audio.play("heal")
				_:
					Audio.play("explode" if String(s.type).begins_with("aoe") else "bolt", null, -4.0)


func _apply_self(id: String, lv: int) -> void:
	_skill_accent(id, global_position, 1.35, "support")
	var s: = SkillDB.info(id)
	Audio.play("heal" if s.type == "heal" else "buff", null, 0.0, 0.0)
	if s.type == "heal":
		var amount: = int((Game.base_level + Game.st("INT")) / 8.0 * (4 + 8 * lv) * float(s.get("heal_mult", 1.0)) \
				* (1.0 + Game.skill_bonus("HEAL_PCT") / 100.0))
		Game.heal(amount)
		FX.popup(self, global_position + Vector3(0, 2.1, 0), "+%d" % amount, Color(0.4, 1.0, 0.5), 48)
		FX.ring(self, global_position, Color(0.5, 1.0, 0.6, 0.85), 1.6)
		FX.magic_circle(self, Color(0.45, 1.0, 0.55), 1.3, 0.9)
		FX.pillar(self, global_position, Color(0.55, 1.0, 0.6), 0.7, 3.0, 0.6)
	else:
		Game.add_buff(id, lv, SkillDB.duration(id, lv))
		if id == "increase_agi":
			Game.hp = maxi(1, Game.hp - 15)
		FX.popup(self, global_position + Vector3(0, 2.3, 0), tr(Game.skill_name(id)) + "!", Color(1.0, 0.95, 0.6), 44, 0.6)
		FX.ring(self, global_position, Color(1.0, 0.9, 0.5, 0.85), 1.4)
		FX.magic_circle(self, Color(1.0, 0.85, 0.4), 1.2, 0.9)
		FX.pillar(self, global_position, Color(1.0, 0.9, 0.55), 0.55, 2.6, 0.5)
		FX.sparks(self, global_position + Vector3(0, 1.0, 0), Color(1.0, 0.92, 0.6), 14, 2.2)

	model.skill_attack(SkillDB.anim_kind(id, model.weapon_kind, model.anim_style))


func _nearest_monster(r: float, from: = Vector3.INF) -> Monster:
	var best: Monster = null
	var bd: = r
	var origin: = global_position if from == Vector3.INF else from
	for m in get_tree().get_nodes_in_group("monster"):
		var mon: = m as Monster
		if mon and mon.is_alive():
			var d: = Vector2(mon.global_position.x - origin.x, mon.global_position.z - origin.z).length()
			if d < bd:
				bd = d
				best = mon
	return best




static func size_class(mon: Monster) -> int:
	if mon == null:
		return 1
	return 0 if mon.size < 1.0 else (1 if mon.size < 1.6 else 2)


func _roll_damage(mult: = 1.0, mon: Monster = null) -> Array:

	if mon != null:
		mult *= Items.size_mod(Items.weapon_type(Game.equip.get("weapon", "")), size_class(mon))
	var dmg: = int(Game.atk() * randf_range(0.9, 1.1) * mult)
	var crit: = randf() * 100.0 < Game.crit_rate()
	if crit:
		dmg = int(dmg * 1.4)
	return [dmg, crit]


func _hits(mon: Monster) -> bool:
	return randf() * 100.0 < clampf(80.0 + Game.hit() - mon.flee, 5.0, 100.0)


func _monsters_near(p: Vector3, r: float) -> Array:
	var out: = []
	for m in get_tree().get_nodes_in_group("monster"):
		var mon: = m as Monster
		if mon and mon.is_alive() and Vector2(mon.global_position.x - p.x, mon.global_position.z - p.z).length() <= r:
			out.append(mon)
	return out


func _proj_from() -> Vector3:
	return global_position + Vector3(0, 1.25, 0) + Vector3(sin(model.rotation.y), 0, cos(model.rotation.y)) * 0.5


var _self_cast: = false


func _on_attack_hit() -> void:
	if _self_cast:
		_self_cast = false
		return
	var skill: = _skill_fire
	_skill_fire = ""
	if skill != "":
		_apply_skill(skill, Game.slv(skill))
		return

	var victim: Monster = null
	if _valid(attack_target) and _flat_dist(attack_target) <= attack_range + 0.8:
		victim = attack_target
	else:
		var fwd: = Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
		var best: = 99.0
		for m in get_tree().get_nodes_in_group("monster"):
			var mon: = m as Monster
			if mon == null or not mon.is_alive():
				continue
			var to: = mon.global_position - global_position
			to.y = 0
			var d: = to.length()
			if d < attack_range + 0.6 and d < best and (d < 0.6 or to.normalized().dot(fwd) > 0.3):
				best = d
				victim = mon
	if victim == null:
		return
	if not _hits(victim):
		FX.popup(victim, victim.global_position + Vector3(0, 1.4 * victim.size, 0), "Miss", Color(0.75, 0.75, 0.8), 44)
		return
	var times: = 2 if randf() * 100.0 < Game.slv("double_attack") * 5 else 1
	var style: String = model.anim_style
	for k in times:
		var r: = _roll_damage(1.0, victim)
		var land: = func () -> void:
			if _valid(victim):
				victim.take_damage(r[0], self, r[1])
				FX.ring(self, victim.global_position, Color(1, 1, 1, 0.7), 0.7)
				var pc: = Game.skill_bonus("POISON")
				if pc > 0.0 and randf() * 100.0 < pc and _valid(victim):
					victim.apply_status("poison", 5.0, maxi(2, victim.max_hp / 50 + Game.base_level))
		if style == "shoot" or style == "cast":
			FX.projectile(self, _proj_from(), victim.global_position + Vector3(0, 0.45 * victim.size, 0),
					"arrow" if style == "shoot" else "magic", land, false)
		elif k == 0:
			land.call()
		else:
			get_tree().create_timer(0.12).timeout.connect(land)
	if times == 2:
		FX.popup(self, global_position + Vector3(0, 2.3, 0), "Double!", Color(1.0, 0.8, 0.3), 36, 0.5)



const SKILL_ELEMENT: = {
	"magnum_break": "fire", "fire_bolt": "fire", "fire_ball": "fire", "meteor_storm": "fire", "claymore_trap": "fire",
	"fire_flask": "fire", "shrapnel_bomb": "fire", "napalm_vulcan": "fire",
	"chi_burst": "water",
	"arrow_shower": "wind", "sharp_shooting": "wind", "knife_fan": "wind", "crescendo": "wind", "falcon_assault": "wind", "blitz_beat": "wind",
	"stone_lance": "earth", "quicksand_pit": "earth", "golem_smash": "earth", "hammer_fall": "earth", "land_mine": "earth",
	"grimtooth": "earth", "briar_lullaby": "earth",
	"lightning_bolt": "lightning", "jupitel_thunder": "lightning", "lord_of_vermilion": "lightning", "chain_spark": "lightning",
	"dissonant_chord": "lightning",
	"cold_bolt": "ice", "frost_diver": "ice", "storm_gust": "ice",
	"holy_light": "holy", "magnus_exorcismus": "holy", "judex": "holy", "sanctuary": "holy", "radiant_cross": "holy",
	"judgement_lance": "holy", "sanctified_ground": "holy",
	"gravitation_field": "shadow", "meteor_assault": "shadow", "soul_destroyer": "shadow", "phantom_blades": "shadow", "arcane_comet": "shadow" }

const ADV_ELEMENT: = { "swordsman:a:4": "lightning", "swordsman:a:5": "fire", "swordsman:b": "holy", "archer:a": "wind", "archer:b": "lightning",
	"mage:a:4": "fire", "mage:a:5": "lightning", "mage:b:4": "water", "mage:b:5": "wind", "acolyte:a": "holy", "acolyte:b": "water",
	"merchant:a": "fire", "merchant:b": "earth", "thief:a": "shadow", "thief:b": "shadow" }


func _skill_element(id: String) -> String:
	if SKILL_ELEMENT.has(id):
		return SKILL_ELEMENT[id]
	if id.ends_with("_strike") and id.count("_") >= 3:
		var parts: = id.split("_")
		var k3: = "%s:%s:%s" % [parts[0], parts[1], parts[2]]
		var k2: = "%s:%s" % [parts[0], parts[1]]
		if ADV_ELEMENT.has(k3):
			return ADV_ELEMENT[k3]
		if ADV_ELEMENT.has(k2):
			return ADV_ELEMENT[k2]
	var s: = SkillDB.info(id)
	var proj: String = s.get("proj", "")
	if proj in ["fire", "ice", "lightning", "holy"]:
		return proj
	if s.has("status") and s.status == "freeze":
		return "ice"
	var c: Color = s.get("color", Color(1, 0.8, 0.4))
	if id in ["storm_gust", "frost_diver", "cold_bolt"]:
		return "ice"
	if id in ["lord_of_vermilion", "jupitel_thunder", "lightning_bolt"]:
		return "lightning"
	if id in ["magnus_exorcismus", "judex", "holy_light", "sanctuary"]:
		return "holy"
	if id in ["gravitation_field", "meteor_assault", "soul_destroyer", "napalm_vulcan"]:
		return "shadow"
	if c.r > 0.9 and c.g < 0.6:
		return "fire"
	return "physical"


const ELEMENT_COLORS: = { "fire": Color(1.0, 0.5, 0.15), "ice": Color(0.55, 0.85, 1.0), "lightning": Color(1.0, 0.95, 0.45),
	"holy": Color(1.0, 0.92, 0.6), "shadow": Color(0.7, 0.4, 1.0), "physical": Color(1.0, 0.85, 0.55),
	"earth": Color(0.86, 0.62, 0.3), "water": Color(0.3, 0.62, 1.0), "wind": Color(0.55, 1.0, 0.72) }
const ElementFX: = preload("res://scripts/combat/element_fx.gd")
const SkillPower = preload("res://scripts/combat/skill_power.gd")



func _skill_accent(id: String, pos: Vector3, radius: float, stage: String) -> void:
	var lv := Game.slv(id)
	var spec := SkillDB.info(id)
	var strength := clampf(0.85 + sqrt(maxf(0.0, SkillDB.mult(id, lv))) * 0.22 + lv * 0.025, 1.0, 2.1)
	SkillPower.emit(self, pos, _skill_element(id), String(spec.get("type", "melee")), strength, radius, stage)


func _skill_vfx(id: String, pos: Vector3, radius: = 1.0) -> void:
	_skill_accent(id, pos, radius, "impact")
	var el: = _skill_element(id)
	var c: Color = ELEMENT_COLORS[el]
	var t: String = SkillDB.info(id).type
	if el in ["fire", "water", "wind", "earth", "lightning", "ice"]:
		ElementFX.impact(self, el, pos, radius)
		if t.begins_with("aoe"):
			ElementFX.circle(self, el, pos, maxf(1.4, radius * 1.1), 0.9)
		return
	if el in ["holy", "shadow"] and t.begins_with("aoe"):
		ElementFX.circle(self, el, pos, maxf(1.4, radius * 1.1), 0.9)
	match el:
		"lightning":
			FX.pillar(self, pos, c, 0.35 + radius * 0.12, 9.0, 0.35)
			if radius > 2.0:
				for i in 3:
					var off: = Vector3(randf_range(- radius, radius), 0, randf_range(- radius, radius)) * 0.6
					get_tree().create_timer(0.08 * (i + 1)).timeout.connect(func () -> void: FX.pillar(self, pos + off, c, 0.3, 9.0, 0.3))
		"holy":
			FX.pillar(self, pos, c, 0.5 + radius * 0.2, 7.0, 0.5)
			FX.flash(self, pos + Vector3(0, 0.6, 0), c, 0.9 + radius * 0.2)
		"ice":
			FX.spikes(self, pos, c, maxf(0.8, radius), 6 + int(radius * 3))
			FX.flash(self, pos + Vector3(0, 0.5, 0), c, 0.8)
		"fire":
			FX.flash(self, pos + Vector3(0, 0.5, 0), c, 1.0 + radius * 0.35)
			FX.burst(self, pos, Color(1.0, 0.35, 0.1), radius)
		"shadow":
			FX.flash(self, pos + Vector3(0, 0.5, 0), c, 0.8 + radius * 0.3)
			FX.ring(self, pos, Color(c, 0.9), radius * 1.2)
		_:
			if t == "melee":
				FX.slash_x(self, pos + Vector3(0, 0.6, 0), c, 1.0)
				FX.flash(self, pos + Vector3(0, 0.6, 0), c, 0.6)
			else:
				FX.flash(self, pos + Vector3(0, 0.5, 0), c, 0.7 + radius * 0.25)
				if t.begins_with("aoe"):
					FX.spikes(self, pos, Color(0.75, 0.68, 0.55), radius * 0.8, 6)


func _apply_skill(id: String, lv: int) -> void:
	var s: = SkillDB.info(id)
	var victim: Monster = _skill_target if _valid(_skill_target) else attack_target
	_move_impact(SkillDB.anim_kind(id, model.weapon_kind, model.anim_style), s, victim)
	match s.type:
		"melee":
			if not _valid(victim):
				return
			var n: = SkillDB.hits(id, lv)
			for i in n:
				var strike: = func () -> void:
					if not _valid(victim):
						return
					var r: = _roll_damage(SkillDB.mult(id, lv), victim)
					victim.take_damage(r[0], self, r[1])
					FX.ring(self, victim.global_position, s.get("color", Color(1.0, 0.7, 0.3, 0.9)), 1.3 if i == 0 else 0.8)
					if i == 0 or i == n - 1:
						_skill_vfx(id, victim.global_position, 1.0)
					else:
						FX.sparks(self, victim.global_position + Vector3(0, 0.6, 0), Color(1.0, 0.9, 0.6), 6, 2.5)
					_skill_status(victim, id, lv)
				if i == 0:
					strike.call()
				else:
					get_tree().create_timer(0.09 * i).timeout.connect(strike)
			if id == "envenom" and randf() * 100.0 < 10 + lv * 4:
				victim.apply_status("poison", 6.0, maxi(2, victim.max_hp / 40 + lv * 2))
		"bolt":
			if not _valid(victim):
				return
			var n: = SkillDB.hits(id, lv)
			var proj: String = s.get("proj", "magic")
			for i in n:
				var r: = _roll_damage(SkillDB.mult(id, lv), victim)
				var land: = func () -> void:
					if _valid(victim):
						victim.take_damage(r[0], self, r[1])
						if i == n - 1:
							_skill_vfx(id, victim.global_position, 0.8)
						if id == "cold_bolt" and randf() * 100.0 < lv * 3:
							victim.apply_status("freeze", 2.0 + lv * 0.3)
						_skill_status(victim, id, lv)
				get_tree().create_timer(0.11 * i).timeout.connect(func () -> void:
					if _valid(victim):
						FX.projectile(self, _proj_from(), victim.global_position + Vector3(0, 0.45 * victim.size, 0), proj, land, true))
		"aoe_self":
			var rad: float = s.radius
			FX.ring(self, global_position, s.get("color", Color(1, 0.6, 0.2, 0.9)), rad)
			FX.burst(self, global_position, s.get("color", Color(1, 0.6, 0.2)), rad)
			FX.ring(self, global_position, Color(1, 1, 1, 0.6), rad * 0.6)
			_skill_vfx(id, global_position, rad)
			for mon in _monsters_near(global_position, rad):
				var r: = _roll_damage(SkillDB.mult(id, lv), mon)
				mon.take_damage(r[0], self, r[1])
				_skill_status(mon, id, lv)
		"aoe_target":
			var center: = victim.global_position if _valid(victim) else global_position + Vector3(sin(model.rotation.y), 0, cos(model.rotation.y)) * 3.0
			var rad: float = s.radius
			var waves: = SkillDB.hits(id, lv) if not s.has("hits_per_lv") else 1
			var hit_all: = func () -> void:
				for w in waves:
					var wave: = func () -> void:
						FX.ring(self, center, s.get("color", Color(1, 0.8, 0.4, 0.9)), rad)
						FX.burst(self, center, s.get("color", Color(1, 0.8, 0.4)), rad)
						_skill_vfx(id, center, rad)
						for mon in _monsters_near(center, rad):
							var r: = _roll_damage(SkillDB.mult(id, lv), mon)
							mon.take_damage(r[0], self, r[1])
							_skill_status(mon, id, lv)
					if w == 0:
						wave.call()
					else:
						get_tree().create_timer(0.35 * w).timeout.connect(wave)
			if s.has("proj"):
				FX.projectile(self, _proj_from(), center + Vector3(0, 0.5, 0), s.proj, hit_all, true)
			elif id == "arrow_shower":
				for i in 5:
					var off: = Vector3(randf_range(- rad, rad) * 0.6, 0, randf_range(- rad, rad) * 0.6)
					FX.projectile(self, center + off + Vector3(0.3, 7, 0), center + off, "arrow", func () -> void: pass, false)
				get_tree().create_timer(0.3).timeout.connect(hit_all)
			else:
				hit_all.call()
		"steal":
			if not _valid(victim):
				return
			if victim.stolen:
				FX.popup(victim, victim.global_position + Vector3(0, 1.6, 0), "Nothing to steal", Color(0.8, 0.8, 0.85), 34)
				return
			var chance: = 10 + lv * 6 + (Game.st("DEX") - victim.level) / 2
			if randf() * 100.0 < chance and victim.drops.size() > 0:
				victim.stolen = true
				var d: Array = victim.drops[_rng.randi() % victim.drops.size()]
				Game.add_item(d[0], 1)
				FX.popup(victim, victim.global_position + Vector3(0, 1.6, 0), "Stole!", Color(1.0, 0.85, 0.3), 40)
			else:
				FX.popup(victim, victim.global_position + Vector3(0, 1.6, 0), "Steal failed", Color(0.8, 0.8, 0.85), 34)



func _move_impact(kind: String, s: Dictionary, victim: Monster) -> void:
	var c: Color = s.get("color", Color(1.0, 0.85, 0.55))
	var cam: = get_tree().get_first_node_in_group("camera_rig")
	var fwd: = Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
	match kind:
		"slam":
			var at: = global_position + fwd * 0.9
			FX.ring(self, at, Color(0.95, 0.85, 0.65, 0.9), float(s.get("radius", 2.5)))
			FX.spikes(self, at, Color(0.72, 0.64, 0.5), float(s.get("radius", 2.5)) * 0.7, 10)
			FX.sparks(self, at + Vector3(0, 0.2, 0), Color(0.85, 0.78, 0.62), 22, 3.5)
			if cam and cam.has_method("shake"):
				cam.shake(0.65)
		"power_strike":
			var at: = victim.global_position if _valid(victim) else global_position + fwd * 1.2
			FX.slash_x(self, at + Vector3(0, 0.7, 0), c, 1.3)
			FX.ring(self, at, Color(c, 0.8), 1.2)
			if cam and cam.has_method("shake"):
				cam.shake(0.4)
		"spin":
			FX.ring(self, global_position, Color(c, 0.85), float(s.get("radius", 3.0)) * 0.9)
			FX.sparks(self, global_position + Vector3(0, 0.9, 0), c, 18, 4.0)
		"kick":
			if _valid(victim):
				FX.flash(self, victim.global_position + Vector3(0, 0.9, 0), Color(0.75, 0.95, 1.0), 1.1)
			if cam and cam.has_method("shake"):
				cam.shake(0.45)
		"palm", "thrust_combo":
			if _valid(victim):
				FX.sparks(self, victim.global_position + Vector3(0, 0.8, 0), c, 12, 3.0)
		"cast_area":
			FX.pillar(self, global_position, Color(c, 0.8), 0.5, 3.5, 0.4)
			if cam and cam.has_method("shake") and float(s.get("radius", 2.0)) >= 3.0:
				cam.shake(0.3)
		"cast_bolt", "throw":
			FX.flash(self, _proj_from(), Color(c, 0.9), 0.55)
		"song":
			FX.ring(self, global_position, Color(0.85, 0.75, 1.0, 0.8), 1.6)
			FX.ring(self, global_position, Color(0.85, 0.75, 1.0, 0.6), 2.6)



func _skill_status(mon: Monster, id: String, lv: int) -> void:
	var s: = SkillDB.info(id)
	if not s.has("status") or not _valid(mon):
		return
	if randf() * 100.0 < SkillDB.status_chance(id, lv):
		var t: = SkillDB.status_time(id, lv)
		if s.status == "poison":
			mon.apply_status("poison", t, maxi(2, mon.max_hp / 40 + lv * 2))
		else:
			mon.apply_status(s.status, t)


func take_damage(amount: int, from: Node3D = null) -> void:
	if _dead:
		return
	var mon: = from as Monster
	if mon and randf() * 100.0 >= clampf(80.0 + mon.hit - Game.flee(), 5.0, 95.0):
		FX.popup(self, global_position + Vector3(0, 2.0, 0), "Miss", Color(0.8, 0.8, 0.85), 44)
		return
	amount = maxi(1, amount - Game.def() / 2)
	Game.hp = maxi(0, Game.hp - amount)
	Audio.play("player_hurt", null, -2.0)
	Game.changed.emit()
	_since_hurt = 0.0
	if Settings.g("damage_numbers"):
		FX.popup(self, global_position + Vector3(0, 2.0, 0), str(amount), Color(1.0, 0.3, 0.25))
	model.hurt()
	if mon and Game.auto_on and not _valid(attack_target):
		attack_target = _auto_pick_target()
	if Game.hp <= 0:
		_die()


func _die() -> void:
	_dead = true
	_dead_t = 0.0
	_stop_all()
	model.die()
	Game.log_msg("You have been defeated... returning to your save point.", Color(1.0, 0.45, 0.45))


func _respawn() -> void:
	var destination := VillageBuilder.area_at(Game.save_point)
	var nav := VillageBuilder.current
	if Settings.is_mobile() and nav:
		if not nav.built.has(destination):
			await warp({"to": destination, "dest": Game.save_point - Vector3(0, 0.15, 0)})
		else:
			nav.trim_mobile_areas(destination)
	_dead = false
	Game.hp = Game.max_hp()
	Game.sp = Game.max_sp()
	Game.changed.emit()
	global_position = Game.save_point
	_update_range()
	_sync_weapon()
	velocity = Vector3.ZERO
	model.revive()
	var a: = VillageBuilder.area_at(global_position)
	if a != area:
		area = a
		var cam: = get_tree().get_first_node_in_group("camera_rig")
		if cam and cam.has_method("snap"):
			cam.snap()
		if Game.ui and Game.ui.has_method("area_changed"):
			Game.ui.area_changed(area)
	_warping = false
	Game.save_game()


func gain_exp(amount: int) -> void:
	FX.popup(self, global_position + Vector3(0, 2.4, 0), tr("+%d EXP") % amount, Color(0.6, 0.9, 1.0), 36, 0.8)
	if Game.add_exp(amount) > 0:
		FX.popup(self, global_position + Vector3(0, 2.8, 0), "LEVEL UP!", Color(1.0, 0.85, 0.2), 72, 1.4)
		FX.level_up(self)
		Audio.play("levelup", null, 0.0, 0.0)
		model.wing_fold()


func _flat_dist(n: Node3D) -> float:
	var d: = n.global_position - global_position
	d.y = 0
	return d.length()



func _nav() -> VillageBuilder:
	return VillageBuilder.current



func _steer(goal: Vector3, delta: float) -> Vector3:
	var here: = Vector3(global_position.x, 0, global_position.z)
	var g: = Vector3(goal.x, 0, goal.z)
	var nav: = _nav()
	if _has_target or interact_target is NPC:
		if _travel_warp.is_empty():
			_travel_warp = _fast_route(g)
		if not _travel_warp.is_empty():
			g = _travel_warp.approach

	var ha: = VillageBuilder.area_at(here)
	var ga: = VillageBuilder.area_at(g)
	if ha != ga:
		var wp: = VillageBuilder.warp_towards(ha, ga)
		if not wp.is_empty():
			g = Vector3(wp.pos.x, 0, wp.pos.y)
	if nav == null or nav.line_clear(here, g):
		_path = PackedVector3Array()
		return (g - here).normalized()
	_path_t += delta




	if (_path.is_empty() and (not _path_failed or _path_t > 0.25)) or _path_goal.distance_to(g) > 1.5 or _path_t > 1.5:
		_path = nav.find_path(here, g)
		_path_failed = _path.is_empty()
		_path_goal = g
		_path_t = 0.0
	while _path.size() > 0 and here.distance_to(_path[0]) < maxf(0.08, move_speed * delta) and (_path.size() == 1 or nav.line_clear(here, _path[1])):
		_path.remove_at(0)
	if _path.size() > 1 and nav.line_clear(here, _path[1]):
		_path.remove_at(0)
	if _path.is_empty():
		return Vector3.ZERO
	return (_path[0] - here).normalized()



var _warp_cd: = 0.0
var area: = "town"


func _check_warps(delta: float) -> void:
	_warp_cd = maxf(0.0, _warp_cd - delta)
	if _warp_cd > 0.0 or _dead or _warping:
		return
	area = VillageBuilder.area_at(global_position)
	if not _travel_warp.is_empty():
		if Game.zeny < int(_travel_warp.cost):
			_travel_warp = { }
		elif global_position.distance_to(_travel_warp.approach) < 1.2:
			var route: = _travel_warp.duplicate()
			_travel_warp = { }
			Game.zeny -= int(route.cost)
			Game.changed.emit()
			warp(route)
			return
	for wp in VillageBuilder.WARPS:
		if wp.area != area:
			continue
		if Vector2(global_position.x - wp.pos.x, global_position.z - wp.pos.y).length() < float(wp.r) and _wants_warp(wp):
			warp(wp)
			return



func _goal() -> Vector3:
	if interact_target != null and is_instance_valid(interact_target):
		return interact_target.global_position
	if _valid(attack_target):
		return attack_target.global_position
	if _has_target:
		return _target
	return Vector3.INF





func _wants_warp(wp: Dictionary) -> bool:


	if (wp.area in ["smithy", "guild1"] and wp.to == "town") or (wp.area == "guild2" and wp.to == "guild1"):
		return true
	var g: = _goal()
	if g == Vector3.INF:
		return false
	if Vector2(g.x - wp.pos.x, g.z - wp.pos.y).length() < float(wp.r) + 1.0:
		return true
	var ga: = VillageBuilder.area_at(g)
	if ga == area:
		return false
	var first: = VillageBuilder.warp_towards(area, ga)
	return not first.is_empty() and first.pos == wp.pos


func warp(wp: Dictionary) -> void:
	if _warping:
		return
	_warping = true
	_travel_warp = { }
	_warp_cd = 1.0
	Audio.play("warp", null, 0.0, 0.0)
	var vb: = VillageBuilder.current
	if vb and Settings.is_mobile():
		# Release old GPU/physics resources before allocating the destination.
		_cancel_cast()
		_end_gather()
		attack_target = null
		interact_target = null
		_skill_target = null
		_pending_skill = ""
		_release_queue = ""
		_skill_fire = ""
		if is_instance_valid(_locked): _locked.set_locked(false)
		_locked = null
		if is_instance_valid(hovered) and hovered.has_method("set_hovered"): hovered.set_hovered(false)
		hovered = null
		for member in get_tree().get_nodes_in_group("party"):
			member.set("target", null)
			member.set("_pending", null)
		velocity = Vector3.ZERO
		if Game.ui and Game.ui.has_method("show_loading"): Game.ui.show_loading(String(wp.to))
		await get_tree().process_frame
		await get_tree().process_frame
		vb.trim_mobile_areas(String(wp.to))
		# queue_free and the renderer must complete before building another map.
		await get_tree().process_frame
	if vb and not vb.built.has(String(wp.to)):

		_warp_cd = 3.0
		velocity = Vector3.ZERO
		_path = PackedVector3Array()
		if Game.ui and Game.ui.has_method("show_loading"):
			Game.ui.show_loading(String(wp.to))
		await get_tree().process_frame
		await get_tree().process_frame
		vb.ensure_area(String(wp.to))
		_warp_cd = 1.0
	if Zones.is_field(String(wp.to)) and not (String(wp.to) in Game.visited_areas):
		Game.visited_areas.append(String(wp.to))
		Game.log_msg(tr("New region discovered: %s! You can now travel here from any Warp Crystal.") % tr(VillageBuilder.AREA_NAMES[wp.to]), Color(0.55, 0.9, 1.0))
	global_position = wp.dest + Vector3(0, 0.15, 0)
	_last_safe_position = global_position
	velocity = Vector3.ZERO
	_path = PackedVector3Array()
	model.rotation.y = float(wp.get("yaw", model.rotation.y))
	area = String(wp.to)
	if _valid(attack_target) and VillageBuilder.area_at(attack_target.global_position) != area:
		attack_target = null
	if _has_target and VillageBuilder.area_at(_target) == area and Vector2(_target.x - global_position.x, _target.z - global_position.z).length() < 0.5:
		_has_target = false

	if _has_target and (VillageBuilder.area_at(_target) != area and VillageBuilder.warp_towards(area, VillageBuilder.area_at(_target)).is_empty()
			or Vector2(_target.x - float(wp.get("pos", Vector2.INF).x), _target.z - float(wp.get("pos", Vector2.INF).y)).length() < float(wp.get("r", 0.0)) + 1.0):
		_has_target = false
	_auto_home = global_position if not _has_target else _target
	var cam: = get_tree().get_first_node_in_group("camera_rig")
	if cam and cam.has_method("snap"):
		cam.snap()
	if Game.ui and Game.ui.has_method("area_changed"):
		Game.ui.area_changed(area)
	_warping = false
	Game.save_game()


func _face(d: Vector3, delta: float) -> void:
	model.rotation.y = lerp_angle(model.rotation.y, atan2(d.x, d.z), 1.0 - exp(- turn_speed * delta))



func _auto_pick_target() -> Monster:
	var cfg: Dictionary = Game.auto_cfg
	var r: float = float(cfg.get("range", 20))
	var mode: String = cfg.get("target", "nearest")
	var quest: = Game.auto_quest_target
	var selected: = String(cfg.get("monster", ""))
	var best: Monster = null
	var score: = INF
	for m in get_tree().get_nodes_in_group("monster"):
		var mon: = m as Monster
		if mon == null or not mon.is_alive():
			continue
		if VillageBuilder.area_at(mon.global_position) != VillageBuilder.area_at(global_position):
			continue
		if selected != "" and quest == "" and mon.display_name != selected:
			continue
		if float(_unreachable.get(mon.get_instance_id(), 0.0)) > Time.get_ticks_msec() / 1000.0:
			continue
		var d: = _flat_dist(mon)
		if d > r:
			continue
		if cfg.get("skip_boss", true) and mon.has_meta("boss") and mon.target != self:
			continue
		if (mode == "quest" or quest != "") and quest != "" and mon.display_name != quest:
			continue
		var sc: = d
		match mode:
			"weakest":
				sc = mon.level * 100.0 + d
			"strongest":
				sc = - mon.level * 100.0 + d

		if mon.target == self and mon.state != Monster.State.IDLE:
			sc -= 10000.0
		if sc < score:
			score = sc
			best = mon
	return best



func _auto_quest_check() -> bool:
	if Game.auto_quest_target == "":
		return false
	var ba: Dictionary = Game.board_active
	if not ba.is_empty() and Guild.is_done() and Game.auto_quest_target == String(ba.zone):
		Game.auto_quest_target = ""
		for n in get_tree().get_nodes_in_group("npc"):
			if n.npc_name == "Special Quest Board":
				attack_target = null
				talk_to(n)
				Game.log_msg(tr("Bounty complete - returning to the Guild."), Color(1.0, 0.85, 0.3))
				Game.auto_on = false
				Game.changed.emit()
				return true
	for qid in Game.quests:
		var q: Dictionary = Game.quests[qid]
		if q.state == "done" and (q.target == Game.auto_quest_target or qid == "story"):
			var giver: String = q.giver
			Game.auto_quest_target = ""
			for n in get_tree().get_nodes_in_group("npc"):
				if n.npc_name == giver:
					attack_target = null
					talk_to(n)
					Game.log_msg(tr("Quest complete - returning to %s.") % tr(giver), Color(1.0, 0.85, 0.3))
					Game.auto_on = false
					Game.changed.emit()
					return true
	return false


func _auto_think() -> void:
	if not Game.auto_on or _dead or _warping or is_casting():
		return
	var cfg: Dictionary = Game.auto_cfg

	if _potion_cd <= 0.0:
		var hp_at: int = int(cfg.get("hp_potion", 40))
		var sp_at: int = int(cfg.get("sp_potion", 15))
		if hp_at > 0 and Game.hp < Game.max_hp() * hp_at / 100.0:
			for id in ["potion_red", "milk"]:
				if Game.count(id) > 0:
					Game.use_item(id)
					_potion_cd = 1.5
					break
		elif sp_at > 0 and Game.sp < Game.max_sp() * sp_at / 100.0:
			for id in ["potion_blue", "mushroom"]:
				if Game.count(id) > 0:
					Game.use_item(id)
					_potion_cd = 1.5
					break

	if _auto_gather_kind != "":
		_auto_gather_think()
		return
	if not _gather.is_empty() or interact_target is GatherNode:
		return
	if _auto_quest_check():
		return
	if cfg.get("buffs", true):
		if Game.slv("heal") > 0 and Game.hp < Game.max_hp() * 0.6 and Game.sp >= SkillDB.sp_cost("heal", Game.slv("heal")) and Game.cooldown_left("heal") <= 0.0:
			use_skill("heal")
			return
		for id in Game.job_skills():
			if SkillDB.info(id).type == "buff" and Game.slv(id) > 0 and not Game.buffs.has(id) and Game.cooldown_left(id) <= 0.0 \
					and Game.sp >= SkillDB.sp_cost(id, Game.slv(id)) + 10 and not model.is_attacking():
				use_skill(id)
				return
	if _has_target and _auto_going_home:

		var m: = _auto_pick_target()
		if m:
			_has_target = false
			_auto_going_home = false
			attack_target = m
			return
	if interact_target != null or _has_target:
		return
	_auto_going_home = false

	if not _valid(attack_target):
		attack_target = _auto_pick_target()
	if not _valid(attack_target) and cfg.get("loot", true):
		for d in get_tree().get_nodes_in_group("drop"):
			if _flat_dist(d) < 7.0 and VillageBuilder.area_at(d.global_position) == area and float(_unreachable.get(d.get_instance_id(), 0.0)) <= Time.get_ticks_msec() / 1000.0:
				talk_to(d)
				return
	if not _valid(attack_target):
		attack_target = _auto_pick_target()
		if attack_target == null:

			if _auto_home != Vector3.ZERO and Vector2(global_position.x - _auto_home.x, global_position.z - _auto_home.z).length() > 6.0:
				go_to(_auto_home, false)
				_auto_going_home = true
			elif not _waiting_msg and Game.auto_quest_target != "":
				_waiting_msg = true
				Game.log_msg(tr("Waiting for %s to respawn...") % tr(Game.auto_quest_target), Color(0.75, 0.85, 1.0))
		else:
			_waiting_msg = false
		return

	if not cfg.get("skills", true):
		return
	if _pending_skill != "" or _release_queue != "" or Game.sp < Game.max_sp() * 0.2:
		return


	var dist: = _flat_dist(attack_target)
	if dist > attack_range + 1.6:
		return
	var near: = _monsters_near(attack_target.global_position, 2.6).size()
	var aoe_at: int = int(cfg.get("aoe", 2))
	var options: = []
	for id in Game.hotbar:
		var s: = SkillDB.info(id)
		if s.is_empty() or Game.slv(id) <= 0 or Game.sp < SkillDB.sp_cost(id, Game.slv(id)) or Game.cooldown_left(id) > 0.0:
			continue
		if dist > _skill_range(id) + 0.3:
			continue
		if s.type == "aoe_self" and dist > float(s.get("radius", 3.0)) - 0.3:
			continue
		if s.type in ["melee", "bolt"]:
			options.append(id)
		elif s.type in ["aoe_self", "aoe_target"] and near >= aoe_at:
			options.push_front(id)
	if options.size() > 0 and _rng.randf() < 0.85:
		use_skill(options[0] if near >= aoe_at else options[_rng.randi() % options.size()])


var _waiting_msg: = false
var _auto_going_home: = false


func toggle_auto() -> void:
	var gathering: GatherNode = _gather.get("node", null)
	if gathering == null and is_instance_valid(interact_target) and interact_target is GatherNode:
		gathering = interact_target
	var was_gather_auto := _auto_gather_kind != ""
	Game.auto_on = not Game.auto_on
	if Game.auto_on:
		if is_instance_valid(gathering):
			_set_auto_gather(gathering)
			attack_target = null
		elif Game.auto_quest_target == "":
			_stop_all()
			_auto_going_home = false
			_unreachable.clear()
			attack_target = _auto_pick_target()
		_auto_t = 0.25
	elif was_gather_auto:
		_stop_all()
	_auto_home = _target if _has_target else global_position
	Game.log_msg("Auto mode ON" if Game.auto_on else "Auto mode OFF", Color(0.5, 0.85, 0.4) if Game.auto_on else Color(0.8, 0.6, 0.4))
	Game.changed.emit()


func _process(delta: float) -> void:
	if _restoring_resume: return
	_update_hover()
	_update_lock()
	if not _dead and not touch_controls and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Game.mouse_over_ui and not Game.get_meta("cam_gesture", false):
		_hold_t += delta
		if _hold_t > 0.12:
			_hold_t = 0.0
			_click(get_viewport().get_mouse_position(), false)
	if _valid(attack_target):
		_marker.global_position = Vector3(attack_target.global_position.x, 0.06, attack_target.global_position.z)
		_marker_mat.albedo_color.a = 0.9
		_marker_arrow.visible = false
		_marker.visible = true
	elif _marker.visible:
		_marker_t += delta
		_drop_t += delta
		var s: = 1.0 + sin(_marker_t * 8.0) * 0.12
		_marker_ring.scale = Vector3(s, 1, s)

		var k: = clampf(_drop_t / 0.22, 0.0, 1.0)
		_marker_arrow.position.y = lerpf(2.4, 0.0, k * k)
		var wob: = sin(clampf((_drop_t - 0.22) / 0.4, 0.0, 1.0) * PI * 3.0) * (1.0 - clampf((_drop_t - 0.22) / 0.4, 0.0, 1.0)) if _drop_t > 0.22 else 0.0
		_marker_arrow.rotation.z = wob * 0.25
		var arrived: = not _has_target and interact_target == null
		var a: = clampf(1.2 - _marker_t * 0.8, 0.0, 1.0) if arrived else 1.0
		_marker_mat.albedo_color.a = a * 0.9
		_arrow_mat.albedo_color.a = a
		if arrived and _marker_t > 1.5:
			_marker.visible = false
	if _release_queue != "" and not model.is_attacking():
		var q: = _release_queue
		_release_queue = ""
		_release_skill(q)

	if not _casting.is_empty():
		_casting.t += delta
		_cast_ring.rotation.y += delta * 3.0
		var sc: = 0.6 + 0.6 * cast_progress()
		_cast_ring.scale = Vector3(sc, 1, sc)
		if not _valid(_casting.target):
			_cancel_cast()
		elif _casting.t >= _casting.total:
			var id: String = _casting.id
			attack_target = _casting.target
			_cancel_cast()
			_release_skill(id)

	_potion_cd = maxf(0.0, _potion_cd - delta)
	_auto_t += delta
	if _auto_t > 0.25:
		_auto_t = 0.0
		_auto_think()

	_since_hurt += delta
	_regen_t += delta
	if not _dead and _regen_t >= 2.0:
		_regen_t = 0.0
		_update_range()
		var k: = 2.0 if _since_hurt > 5.0 else 0.5
		var dhp: = int((1 + Game.max_hp() / 120 + Game.st("VIT") / 4) * k * Game.hp_regen_mult())
		var dsp: = int((1 + Game.max_sp() / 60 + Game.st("INT") / 4) * k * Game.sp_regen_mult())
		if Game.hp < Game.max_hp() or Game.sp < Game.max_sp():
			Game.heal(dhp, dsp)


var _step_t: = 0.0


func _physics_process(delta: float) -> void:
	if _restoring_resume: return
	if _warping:
		velocity = Vector3.ZERO
		return
	_recover_map_boundary()
	_cooldown = maxf(0.0, _cooldown - delta)
	var vel: = Vector3.ZERO

	var was_flying: = model.is_flying()
	model.flying = VillageBuilder.flight_zone(global_position)
	var speed: = move_speed * Game.move_mult()
	var far: = _trip_left() > RUN_DIST
	_run_k = move_toward(_run_k, 1.0 if far and not model.is_flying() and not _dead else 0.0, delta * (2.5 if far else 4.0))
	speed *= 1.0 + (RUN_MULT - 1.0) * _run_k
	if model.is_flying():
		speed *= FLY_SPEED
	if model.is_flying() != was_flying and model.can_fly() == model.is_flying():
		_on_flight_changed(model.is_flying())
	if _dead:
		_dead_t += delta
		if _dead_t > 3.0:
			_respawn()
	elif is_casting():
		if _valid(_casting.target):
			_face(_casting.target.global_position - global_position, delta)
	elif not _gather.is_empty():
		_update_gather(delta)
	elif interact_target != null:
		if not is_instance_valid(interact_target):
			interact_target = null
		else:
			var to: = interact_target.global_position - global_position
			to.y = 0
			var reach: float = maxf(talk_range, interact_target.reach) if interact_target is NPC else (interact_target.reach if interact_target is GatherNode else 0.9)
			var goal: Vector3 = interact_target.global_position
			if interact_target is NPC and interact_target.talk_spot != Vector3.INF:
				goal = interact_target.talk_spot
			elif interact_target is GatherNode and interact_target.stand_spot != Vector3.INF:
				goal = interact_target.stand_spot
			if to.length() > reach:
				var d: = _steer(goal, delta)
				vel = d * speed
				_face(d, delta)
			else:
				var t: = interact_target
				interact_target = null
				_marker.visible = false
				if t is NPC:
					model.rotation.y = atan2(to.x, to.z)
					t.interact(self)
				elif t is DropItem:
					t.pick_up()
				elif t is GatherNode:
					_start_gather(t)
	elif attack_target != null:
		if not _valid(attack_target):
			attack_target = null
			_pending_skill = ""
		else:
			var to: = attack_target.global_position - global_position
			to.y = 0
			var dist: = to.length()
			var want: = _skill_range(_pending_skill) if _pending_skill != "" else attack_range
			if dist > want:
				if not model.is_attacking():
					var d: = _steer(attack_target.global_position, delta)
					vel = d * speed
					_face(d, delta)
			else:
				_face(to, delta)
				if _pending_skill != "" and not model.is_attacking():
					_start_skill(_pending_skill)
				elif _pending_skill == "" and _cooldown <= 0.0 and model.attack():
					_cooldown = Game.attack_interval()
					if attack_range < 3.0:
						Audio.play("swing")
	elif _has_target and not model.is_attacking():
		var to: = _target - global_position
		to.y = 0.0
		if to.length() < 0.25:
			_has_target = false
		else:
			var d: = _steer(_target, delta)
			vel = d * speed
			_face(d, delta)
	if not _path.is_empty() and vel.length() > 0.0:
		var remaining: = Vector2(_path[0].x - global_position.x, _path[0].z - global_position.z).length()
		vel = vel.limit_length(remaining / maxf(delta, 0.001))
	velocity.x = vel.x
	velocity.z = vel.z
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= gravity * delta
	var before: = global_position
	move_and_slide()
	_recover_map_boundary()

	if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 1.0 and not model.is_flying():
		_step_t -= delta * Vector2(velocity.x, velocity.z).length() / 4.0
		if _step_t <= 0.0:
			_step_t = 0.42
			Audio.play("step_snow" if VillageBuilder.area_at(global_position).begins_with("frost") else "step", null, 0.0, 0.15)
	else:
		_step_t = 0.1
	_check_warps(delta)

	var moved: = Vector2(global_position.x - before.x, global_position.z - before.z).length()
	var actually_moving: = moved > speed * delta * 0.25
	var trying: = _has_target or interact_target != null or (_valid(attack_target) and _flat_dist(attack_target) > attack_range)
	if trying and not actually_moving and not model.is_attacking() and not is_casting():
		_stuck_t += delta

		if _has_target and interact_target == null and attack_target == null and _stuck_t > 0.35 \
				and Vector2(_target.x - global_position.x, _target.z - global_position.z).length() < 1.3:
			_has_target = false
			_path.clear()
			_stuck_t = 0.0
		if _stuck_t > 0.5:
			_path.clear()
			_path_t = 2.0
		if _stuck_t > 5.0:
			if is_instance_valid(interact_target):
				_unreachable[interact_target.get_instance_id()] = Time.get_ticks_msec() / 1000.0 + 15.0
			if _valid(attack_target):
				_unreachable[attack_target.get_instance_id()] = Time.get_ticks_msec() / 1000.0 + 15.0
			_stop_all(true) # Skip blocked veins without reverting AUTO to hunting.
			_stuck_t = 0.0
			Game.log_msg(tr("No safe route. Choose another destination."), Color(1.0, 0.7, 0.4))
	else:
		_stuck_t = 0.0
	model.set_moving(vel.length() > 0.1 and actually_moving)
	model.run_amount = _run_k if actually_moving else 0.0
	_update_run_dust(_run_k > 0.55 and actually_moving and is_on_floor())
	model.channel = is_casting()
	model.attack_speed = clampf(0.5 / Game.attack_interval(), 0.8, 1.8)


const FLY_SPEED: = 1.4


func _on_flight_changed(up: bool) -> void:
	if up:
		Game.log_msg(tr("Wings spread: flying (move speed +40%)"), Color(0.7, 0.9, 1.0))
	Audio.play("swing", null, -6.0, 0.1)


func _recover_map_boundary() -> void:
	var nav: = _nav()
	if nav == null:
		return
	if nav.playable_floor(global_position) and global_position.y > -3.0:
		if nav.walkable(global_position.x, global_position.z) and absf(global_position.y) < 0.5:
			_last_safe_position = Vector3(global_position.x, 0.15, global_position.z)
		return
	var destination: = _last_safe_position
	if destination == Vector3.INF or not nav.playable_floor(destination):
		destination = nav.safe_position(global_position, VillageBuilder.area_at(global_position), 32)
	if destination == Vector3.INF:

		destination = nav.safe_position(Vector3(0, 0, 10), "town")
	if destination == Vector3.INF:
		return
	_stop_all()
	global_position = Vector3(destination.x, 0.15, destination.z)
	velocity = Vector3.ZERO
	_last_safe_position = global_position
	area = VillageBuilder.area_at(global_position)
	_auto_home = global_position
	var cam: = get_tree().get_first_node_in_group("camera_rig")
	if cam and cam.has_method("snap"):
		cam.snap()



func _fast_route(goal: Vector3) -> Dictionary:
	if not Game.auto_cfg.get("travel_warp", true) or global_position.distance_to(goal) < 60.0:
		return { }
	var here: = VillageBuilder.area_at(global_position)
	var there: = VillageBuilder.area_at(goal)
	var best: = { }
	var best_cost: = global_position.distance_to(goal)
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.role != "warp" or VillageBuilder.area_at(npc.global_position) != here:
			continue
		for dest in NPC.WARP_DEST:
			if dest[0] != there or (there != "town" and not there in Game.visited_areas) or Game.zeny < int(dest[3]):
				continue
			var approach: Vector3 = npc.talk_spot if npc.talk_spot != Vector3.INF else npc.global_position + Vector3(0, 0, 2)
			var cost: = global_position.distance_to(approach) + (dest[1] as Vector3).distance_to(goal) + 20.0
			if cost < best_cost:
				best_cost = cost
				best = { "approach": approach, "to": dest[0], "dest": dest[1], "yaw": dest[2], "cost": dest[3] }
	return best


func use_warp_item(id: String) -> bool:
	if _dead or _warping or is_casting() or _warp_cd > 0.0 or Game.count(id) < 1:
		return false
	if id == "warp_short":
		var nav: = _nav()
		if nav == null:
			return false
		var forward: = Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
		var dest: = global_position
		for step in range(1, 49):
			var candidate: = global_position + forward * (step * 0.25)
			if VillageBuilder.area_at(candidate) != VillageBuilder.area_at(global_position) or not nav.line_clear(global_position, candidate):
				break
			if test_move(global_transform, candidate - global_position):
				break
			dest = candidate
		if dest.distance_to(global_position) < 1.0:
			Game.log_msg(tr("No safe space to warp."), Color(1.0, 0.7, 0.4))
			return false
		_stop_all()
		Game.remove_item(id)
		warp({ "to": VillageBuilder.area_at(dest), "dest": Vector3(dest.x, 0, dest.z) })
		return true
	if id != "warp_long" or Game.ui == null:
		return false
	var choices: = []
	var destinations: = []
	for d in NPC.WARP_DEST:
		if d[0] == "town" or d[0] in Game.visited_areas:
			destinations.append(d)
			choices.append(tr(VillageBuilder.AREA_NAMES[d[0]]))
	choices.append(tr("Close"))
	Game.ui.dialog("Long Warp Scroll", "Choose a destination. One scroll, no Zeny fee.", choices, func (i: int) -> void:
		if i < 0 or i >= destinations.size() or _dead or _warping or is_casting() or _warp_cd > 0.0 or Game.count(id) < 1:
			return
		var d: Array = destinations[i]
		_stop_all()
		Game.remove_item(id)
		warp({ "to": d[0], "dest": d[1], "yaw": d[2] }))
	return true



var _gather: = { }
var _fish_line: MeshInstance3D
var _bobber: Node3D


func is_gathering() -> bool:
	return not _gather.is_empty()


func _start_gather(n: GatherNode) -> void:
	if not is_instance_valid(n):
		return
	if not n.is_ready():
		Game.log_msg(tr("This rock is exhausted. It will grow back soon."), Color(0.85, 0.8, 0.7))
		return
	attack_target = null
	_has_target = false
	_pending_skill = ""
	_gather = { "node": n, "t": 0.0, "total": n.work_time(), "swing": 0.0, "bit": false }
	var to: = n.global_position - global_position
	model.rotation.y = atan2(to.x, to.z)
	if n.kind == "fish":
		_cast_line(n)
		Audio.play("swing")
		Game.log_msg(tr("You cast your line..."), Color(0.7, 0.85, 1.0))
	else:
		Game.log_msg(tr("Mining %s...") % tr(n.node_name), Color(0.85, 0.8, 0.7))


func _end_gather() -> void:
	_gather = { }
	if _fish_line and is_instance_valid(_fish_line):
		_fish_line.queue_free()
	if _bobber and is_instance_valid(_bobber):
		_bobber.queue_free()
	_fish_line = null
	_bobber = null


func _update_gather(delta: float) -> void:
	var n: GatherNode = _gather.node
	if not is_instance_valid(n):
		_end_gather()
		return
	var to: = n.global_position - global_position
	to.y = 0
	_face(to, delta)
	_gather.t += delta
	if n.kind == "ore":

		_gather.swing -= delta
		if _gather.swing <= 0.0:
			_gather.swing = 0.65
			model.attack(false)
			Audio.play("hit", n.global_position, 0.0, 0.2)
			FX.burst(self, n.global_position + Vector3(0, 0.8, 0), n.ore_color.lightened(0.3), 0.5)
		if _gather.t >= _gather.total:
			_give(n.harvest(), n)
			if n.is_ready():
				_gather.t = 0.0
				_gather.total = n.work_time()
			else:
				Game.log_msg(tr("The vein is exhausted. It will grow back soon."), Color(0.85, 0.8, 0.7))
				_end_gather()
	else:
		_update_line(n, delta)
		if not _gather.bit and _gather.t >= _gather.total:
			_gather.bit = true
			Audio.play("hit", n.global_position, 0.0, 0.1)
			FX.popup(self, global_position + Vector3(0, 2.5, 0), "!", Color(1.0, 0.85, 0.2), 80, 0.6)
			FX.burst(self, n.global_position + Vector3(0, 0.1, 0), Color(0.85, 0.95, 1.0) if n.water_tile != "lava" else Color(1.0, 0.6, 0.2), 0.6)
		if _gather.bit and _gather.t >= _gather.total + 0.7:
			model.attack(false)
			if randf() < 0.88:
				_give(n.harvest(), n)
			else:
				Game.log_msg(tr("It got away..."), Color(0.8, 0.75, 0.7))

			_gather.t = 0.0
			_gather.total = n.work_time()
			_gather.bit = false
			Audio.play("swing")


func _give(loot: Array, n: GatherNode) -> void:
	if loot.is_empty():
		return
	var id: String = loot[0]
	var amt: int = loot[1]

	var mult: = Game.event_mult("gather")
	if mult > 1.0:
		var want: = amt * mult
		amt = int(want) + (1 if randf() < want - int(want) else 0)
	Game.add_item(id, amt)
	Audio.play("pickup")
	FX.popup(self, global_position + Vector3(0, 2.3, 0), "+%s x%d" % [Items.item_name(id), amt], Color(0.7, 1.0, 0.7), 40, 1.0)
	if id in ["pearl", "emerald_gem", "ruby_gem", "sapphire_gem", "golden_carp", "lava_core", "mithril_ore"]:
		Audio.play("jackpot")


func _cast_line(n: GatherNode) -> void:
	_end_gather_visuals()
	_fish_line = MeshInstance3D.new()
	_fish_line.top_level = true
	_fish_line.mesh = ImmediateMesh.new()
	var lm: = StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.92, 0.92, 0.95)
	_fish_line.material_override = lm
	_fish_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fish_line)
	_bobber = Node3D.new()
	_bobber.top_level = true
	add_child(_bobber)
	for k in 2:
		var mi: = MeshInstance3D.new()
		var sm: = SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.18
		mi.mesh = sm
		var bm: = StandardMaterial3D.new()
		bm.albedo_color = Color(0.95, 0.15, 0.12) if k == 0 else Color(0.98, 0.98, 0.98)
		mi.material_override = bm
		mi.position.y = 0.06 if k == 0 else 0.15
		mi.scale = Vector3(1, 0.6, 1)
		_bobber.add_child(mi)

	var into: = n.global_position - global_position
	into.y = 0
	_bobber.global_position = n.global_position + into.normalized() * 0.3


func _end_gather_visuals() -> void:
	if _fish_line and is_instance_valid(_fish_line):
		_fish_line.queue_free()
	if _bobber and is_instance_valid(_bobber):
		_bobber.queue_free()


func _update_line(n: GatherNode, _delta: float) -> void:
	if _fish_line == null or _bobber == null:
		return
	var bob: = 0.03 * sin(_gather.t * 4.0)
	if _gather.bit:
		bob = -0.14 + 0.05 * sin(_gather.t * 30.0)
	var bp: = _bobber.global_position
	bp.y = n.global_position.y + 0.04 + bob
	_bobber.global_position = bp

	var fwd: = Vector3(sin(model.rotation.y), 0, cos(model.rotation.y))
	var tip: = global_position + Vector3(0, 2.1, 0) + fwd * 0.9
	var im: = _fish_line.mesh as ImmediateMesh
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 13:
		var k: = i / 12.0
		var p: = tip.lerp(bp + Vector3(0, 0.12, 0), k)
		p.y -= sin(k * PI) * 0.35
		im.surface_add_vertex(p)
	im.surface_end()

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(global_position + Vector3(0, 1.0, 0) + fwd * 0.35)
	im.surface_add_vertex(tip)
	im.surface_end()




func _trip_left() -> float:
	var goal: = Vector3.INF
	if interact_target != null and is_instance_valid(interact_target):
		goal = interact_target.global_position
	elif _has_target and attack_target == null:
		goal = _target
	if goal == Vector3.INF:
		return 0.0
	var d: = Vector2(goal.x - global_position.x, goal.z - global_position.z).length()

	if not _path.is_empty():
		var acc: = 0.0
		var prev: = global_position
		for p in _path:
			acc += Vector2(p.x - prev.x, p.z - prev.z).length()
			prev = p
		d = maxf(d, acc)
	return d


func _update_run_dust(on: bool) -> void:
	if _run_dust == null:
		if not on:
			return
		_run_dust = CPUParticles3D.new()
		var bm: = BoxMesh.new()
		bm.size = Vector3.ONE * 0.09
		var m: = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.vertex_color_use_as_albedo = true
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		bm.material = m
		_run_dust.mesh = bm
		_run_dust.amount = 18
		_run_dust.lifetime = 0.55
		_run_dust.local_coords = false
		_run_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_run_dust.emission_sphere_radius = 0.18
		_run_dust.direction = Vector3(0, 1, 0)
		_run_dust.spread = 60.0
		_run_dust.gravity = Vector3(0, -1.5, 0)
		_run_dust.initial_velocity_min = 0.4
		_run_dust.initial_velocity_max = 1.0
		_run_dust.scale_amount_min = 0.6
		_run_dust.scale_amount_max = 1.5
		var g: = Gradient.new()
		g.set_color(0, Color(0.85, 0.78, 0.62, 0.55))
		g.set_color(1, Color(0.85, 0.78, 0.62, 0.0))
		_run_dust.color_ramp = g
		_run_dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_run_dust)
		_run_dust.position = Vector3(0, 0.08, 0)
	_run_dust.emitting = on

# Explicitly selecting a resource makes AUTO gather in that area instead of hunting.
var _auto_gather_item := ""
var _auto_gather_kind := ""
var _auto_gather_area := ""
var _auto_gather_anchor := Vector3.ZERO
var _auto_gather_waiting := false

func _clear_auto_gather() -> void:
	_auto_gather_item = ""
	_auto_gather_kind = ""
	_auto_gather_area = ""
	_auto_gather_waiting = false

func _set_auto_gather(node: GatherNode) -> void:
	# A selected resource is an explicit task, so quest travel must not steal it.
	Game.auto_quest_target = ""
	if Game.ui and Game.ui.get("_quest_auto") == true:
		Game.ui.call("_set_quest_auto", false)
		Game.ui._qauto_btn.set_pressed_no_signal(false)
	_auto_gather_kind = node.kind
	_auto_gather_area = VillageBuilder.area_at(node.global_position)
	_auto_gather_anchor = node.global_position
	_auto_gather_waiting = false
	_auto_going_home = false

func _auto_gather_think() -> void:
	if VillageBuilder.area_at(global_position) != _auto_gather_area:
		if _auto_gather_item != "":
			if not _has_target: _continue_resource_trip()
		else:
			_clear_auto_gather()
		return
	if _auto_gather_anchor == Vector3.INF:
		_has_target = false
		_path.clear()
		var closest := INF
		_auto_gather_anchor = global_position
		for candidate in get_tree().get_nodes_in_group("gather_node"):
			if not _resource_matches(candidate): continue
			var d := global_position.distance_squared_to(candidate.global_position)
			if d < closest:
				closest = d
				_auto_gather_anchor = candidate.global_position
	attack_target = null
	if not _gather.is_empty(): return
	if is_instance_valid(interact_target) and interact_target is GatherNode:
		if interact_target.is_ready(): return
		interact_target = null
	var nearest: GatherNode
	var distance := INF
	for node in get_tree().get_nodes_in_group("gather_node"):
		if not _resource_matches(node) or not node.is_ready(): continue
		if VillageBuilder.area_at(node.global_position) != _auto_gather_area: continue
		if Vector2(node.global_position.x-_auto_gather_anchor.x,node.global_position.z-_auto_gather_anchor.z).length() > 40: continue
		if float(_unreachable.get(node.get_instance_id(),0.0)) > Time.get_ticks_msec()/1000.0: continue
		var next_distance := global_position.distance_squared_to(node.global_position)
		if next_distance < distance:
			distance = next_distance
			nearest = node
	if nearest:
		var anchor := _auto_gather_anchor
		var item := _auto_gather_item
		talk_to(nearest)
		_auto_gather_anchor = anchor
		_auto_gather_item = item
		_auto_gather_waiting = false
	elif not _auto_gather_waiting:
		_auto_gather_waiting = true
		Game.log_msg("รอแหล่งวัตถุดิบใกล้เคียงเกิดใหม่...", Color(0.85,0.8,0.7))

func _resource_matches(node: Node) -> bool:
	if not node is GatherNode or node.kind != _auto_gather_kind: return false
	if VillageBuilder.area_at(node.global_position) != _auto_gather_area: return false
	if _auto_gather_item == "": return true
	for entry in node.table:
		if String(entry[0]) == _auto_gather_item: return true
	return false

func start_resource_trip(item: String, source_area := "") -> bool:
	var sources: Array = Gathering.sources(item)
	if sources.is_empty(): return false
	var here := VillageBuilder.area_at(global_position)
	var chosen: Array = []
	var best := 100000
	for source in sources:
		if source_area != "" and String(source[1]) != source_area: continue
		var at := here
		var cost := 0
		while at != String(source[1]) and cost < 16:
			var gate := VillageBuilder.warp_towards(at,String(source[1]))
			if gate.is_empty():
				cost=100000
				break
			at=String(gate.to)
			cost+=1
		if at != String(source[1]): cost=100000
		if cost < best:
			best=cost
			chosen=source
	if chosen.is_empty(): return false
	_stop_all()
	Game.auto_on=true
	Game.auto_quest_target=""
	if Game.ui and Game.ui.get("_quest_auto") == true:
		Game.ui.call("_set_quest_auto",false)
		Game.ui._qauto_btn.set_pressed_no_signal(false)
	_auto_gather_item=item
	_auto_gather_kind=String(chosen[0])
	_auto_gather_area=String(chosen[1])
	_auto_gather_anchor=Vector3.INF
	_unreachable.clear()
	if here != _auto_gather_area: _continue_resource_trip()
	else: _auto_gather_think()
	Game.log_msg("กำลังไปเก็บ %s อัตโนมัติ" % Items.item_name(item) if TranslationServer.get_locale().begins_with("th") else "Automatically gathering %s" % Items.item_name(item),Color(1,0.85,0.4))
	Game.changed.emit()
	return true

func _continue_resource_trip() -> void:
	var target_area := _auto_gather_area
	var item := _auto_gather_item
	var kind := _auto_gather_kind
	var rect: Rect2 = VillageBuilder.AREAS.get(target_area,Rect2(-128,-128,256,256))
	go_to(Vector3(rect.get_center().x,0,rect.get_center().y),false)
	_auto_gather_item=item
	_auto_gather_kind=kind
	_auto_gather_area=target_area
	_auto_gather_anchor=Vector3.INF
	_auto_gather_waiting=false


func _restore_resume_checkpoint() -> void:
	var checkpoint := Game.resume_checkpoint()
	var navigation := _nav()
	var destination: Vector3 = checkpoint.get("position", Game.save_point)
	var region := VillageBuilder.area_at(destination)
	if navigation:
		if Settings.is_mobile(): navigation.trim_mobile_areas(region)
		navigation.ensure_area(region)
		var safe := navigation.safe_position(destination, region, 16)
		if safe == Vector3.INF:
			destination = Game.save_point
			region = VillageBuilder.area_at(destination)
			navigation.ensure_area(region)
			safe = navigation.safe_position(destination, region, 24)
		if safe == Vector3.INF:
			region = "town"
			safe = navigation.safe_position(Vector3(0,0,10), region, 24)
		if safe != Vector3.INF: destination = safe + Vector3(0,0.15,0)
	global_position = destination
	velocity = Vector3.ZERO
	_last_safe_position = global_position
	_auto_home = global_position
	area = VillageBuilder.area_at(global_position)
	if navigation and Settings.is_mobile(): navigation.trim_mobile_areas(area)
	model.rotation.y = float(checkpoint.get("yaw", model.rotation.y))
	var spawner := get_tree().get_first_node_in_group("spawner")
	if spawner and area != "town": spawner.spawn_area(area)
	var camera := get_tree().get_first_node_in_group("camera_rig")
	if camera and camera.has_method("snap"): camera.snap()
	if Game.ui and is_instance_valid(Game.ui) and Game.ui.has_method("area_changed"): Game.ui.area_changed(area)
	_restoring_resume = false
