extends RefCounted
## Signature visuals for well-known Ragnarok-style skills (Storm Gust, Lord of
## Vermilion, Meteor Storm, Magnus Exorcismus, Grand Cross, Fire Wall, Asura
## Strike ...). All original art built from meshes and particles in the engine.
##
## play(from, id, lv, pos, radius, wave) is called by the player on every hit
## wave; lead() / lead_time() let a skill show something before its first hit.

const EFX := preload("res://scripts/combat/element_fx.gd")

## aoe_target skills that draw their own visuals (the generic projectile/burst is skipped).
const OWN := ["storm_gust", "lord_of_vermilion", "meteor_storm", "magnus_exorcismus", "fire_wall", "gravitation_field",
	"quicksand_pit", "napalm_beat", "napalm_vulcan", "grimtooth", "arcane_comet", "fire_flask"]


static func has(id: String) -> bool:
	return id in OWN


static func lead_time(id: String) -> float:
	return 0.55 if id == "meteor_storm" else 0.0


static func _mobile() -> bool:
	return Settings.is_mobile()


static func _ok(from: Node) -> bool:
	return from != null and from.is_inside_tree()


# ================================================================== dispatch
static func play(from: Node, id: String, lv: int, pos: Vector3, radius: float, wave: int) -> void:
	if not _ok(from):
		return
	match id:
		"storm_gust": _storm_gust(from, pos, radius, wave)
		"lord_of_vermilion": _vermilion(from, pos, radius, wave)
		"meteor_storm": _meteor_hit(from, pos, radius, wave)
		"magnus_exorcismus": _magnus(from, pos, radius, wave, SkillDB.hits(id, lv))
		"radiant_cross": _grand_cross(from, pos, radius, wave)
		"fire_wall": _fire_wall(from, pos, radius, wave, SkillDB.hits(id, lv))
		"gravitation_field": _gravity(from, pos, radius, wave)
		"quicksand_pit", "grimtooth": _heavens_drive(from, pos, radius, wave)
		"stone_lance": _earth_spike(from, pos)
		"napalm_beat", "napalm_vulcan": _ghost_blast(from, pos, radius)
		"thousand_palms": _asura(from, pos)
		"sonic_blow":
			if wave == 0:
				_sonic_blow(from, pos)
		"lance_charge":
			if wave == 0:
				_holy_cross(from, pos)
		"briar_lullaby":
			if wave == 0:
				_frost_joker(from, pos, radius)
		"sanctified_ground": _gospel(from, pos, radius, wave)
		"arcane_comet": _abracadabra(from, pos, radius, wave)
		"fire_flask": _fire_bomb(from, pos, radius, wave)
		_:
			_recipe(from, id, pos, radius, wave)


## Before the first hit (Meteor Storm: the meteors are already falling).
static func lead(from: Node, id: String, _lv: int, pos: Vector3, radius: float) -> void:
	if not _ok(from):
		return
	if id == "meteor_storm":
		_meteor_fall(from, pos + Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)) * radius, 0.55)


## Self skills (buffs / heals): extra touches for the famous ones.
static func support(from: Node, id: String, pos: Vector3) -> void:
	if not _ok(from):
		return
	match id:
		"sanctuary": _sanctuary(from, pos)
		"kyrie_eleison", "aegis_vow", "zen_guard", "holy_bastion": _bubble(from, pos, id)
		"assumptio": _wings(from, pos)
		"blessing", "increase_agi", "angelus", "magnificat", "impositio_manus": _blessing_light(from, pos, id)
		"berserk", "guardian_spirit": _rage(from, pos)
		"inner_spheres": _spheres(from, pos)


# ================================================================== helpers
static func _disc(h: Node3D, radius: float, c: Color, y := 0.04) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2.ONE * radius * 2.0
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	mi.material_override = EFX._mat(c, true, EFX.soft_texture())
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, y, 0)
	h.add_child(mi)
	return mi


static func _beam(h: Node3D, a: Vector3, b: Vector3, width: float, c: Color) -> MeshInstance3D:
	# flat glowing strip on the ground from a to b
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	var d := b - a
	q.size = Vector2(width, d.length())
	q.orientation = PlaneMesh.FACE_Y
	mi.mesh = q
	mi.material_override = EFX._mat(c)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	h.add_child(mi)
	mi.position = (a + b) * 0.5
	mi.rotation.y = atan2(d.x, d.z)
	return mi


static func _fade(n: Node3D, mat: StandardMaterial3D, hold: float, out: float) -> void:
	var tw := n.create_tween()
	tw.tween_interval(hold)
	tw.tween_property(mat, "albedo_color:a", 0.0, out)


static func _column(h: Node3D, at: Vector3, c: Color, r: float, height: float, time: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = height
	cm.radial_segments = 12
	cm.cap_top = false
	cm.cap_bottom = false
	mi.mesh = cm
	var m := EFX._mat(Color(c, 0.85))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	h.add_child(mi)
	mi.position = at + Vector3(0, height * 0.5, 0)
	mi.scale = Vector3(0.1, 1, 0.1)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3(0.05, 1.0, 0.05), time).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, time)


static func _shake(from: Node, amount: float) -> void:
	var cam := from.get_tree().get_first_node_in_group("camera_rig")
	if cam and cam.has_method("shake"):
		cam.shake(amount)


# ================================================================== Storm Gust
static func _storm_gust(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	if wave == 0:
		var h := EFX._holder(from, pos, 3.6)
		var floor_mi := _disc(h, radius * 1.15, Color(0.75, 0.9, 1.0, 0.55))
		_fade(h, floor_mi.material_override, 2.6, 0.8)
		# a swirling blizzard: snow whirling around the centre plus drifting mist
		EFX._particles(h, pos + Vector3(0, 1.2, 0), Color(1, 1, 1, 1.0), Color(0.7, 0.9, 1.0, 0.0), 40, 1.1, 0.16,
			Vector2(1.0, 2.5), 60.0, Vector3(0, -2.0, 0), Vector3(radius * 0.8, 1.0, radius * 0.8), true, false, 9.0)
		EFX._particles(h, pos + Vector3(0, 0.5, 0), Color(0.9, 0.96, 1.0, 0.5), Color(0.6, 0.85, 1.0, 0.0), 18, 1.6, 1.4,
			Vector2(0.3, 1.0), 90.0, Vector3(0, 0.2, 0), Vector3(radius * 0.7, 0.2, radius * 0.7), false, false, 4.0)
		from.get_tree().create_timer(2.6).timeout.connect(func() -> void:
			for p in h.get_children():
				if p is CPUParticles3D:
					p.emitting = false)
		EFX._flash_light(h, Color(0.6, 0.85, 1.0), 2.0, radius + 4.0, 3.0, 2.0)
		# shards of ice whirl around the storm's eye
		var pivot := Node3D.new()
		h.add_child(pivot)
		var shards := 8 if _mobile() else 16
		for i in shards:
			var mi := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(0.18, 0.55, 0.18)
			mi.mesh = pm
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.85, 0.96, 1.0, 0.9)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.emission_enabled = true
			m.emission = Color(0.5, 0.8, 1.0)
			m.emission_energy_multiplier = 1.2
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var a := TAU * i / shards
			var r := radius * (0.35 + 0.6 * float(i % 4) / 3.0)
			mi.position = Vector3(cos(a) * r, 0.4 + float(i % 5) * 0.45, sin(a) * r)
			mi.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
			pivot.add_child(mi)
			var tw := mi.create_tween()
			tw.tween_interval(2.6)
			tw.tween_property(m, "albedo_color:a", 0.0, 0.6)
		var spin := pivot.create_tween()
		spin.tween_property(pivot, "rotation:y", TAU * 2.2, 3.2)
		# a white wall of wind around the edge
		var wall := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = radius * 1.05
		cm.bottom_radius = radius * 0.95
		cm.height = 2.6
		cm.radial_segments = 24
		cm.cap_top = false
		cm.cap_bottom = false
		wall.mesh = cm
		var wm := ShaderMaterial.new()
		wm.shader = EFX._column_shader()
		wm.set_shader_parameter("tint", Color(0.85, 0.95, 1.0, 0.55))
		wall.material_override = wm
		wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wall.position = Vector3(0, 1.3, 0)
		pivot.add_child(wall)
		var wt := wall.create_tween()
		wt.tween_interval(2.6)
		wt.tween_property(wall, "scale", Vector3(1.2, 0.05, 1.2), 0.6)
	# every hit: a few ice crystals jut out somewhere in the storm
	if wave % 2 == 0:
		var at := pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * 0.6
		FX.spikes(from, at, Color(0.75, 0.92, 1.0, 0.9), radius * 0.35, 3 if _mobile() else 5)


# ================================================================== Lord of Vermilion
static func _vermilion(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	var h := EFX._holder(from, pos, 1.4)
	if wave == 0:
		var g := _disc(h, radius * 1.2, Color(1.0, 0.85, 0.3, 0.45))
		_fade(h, g.material_override, 0.9, 0.4)
	var bolts := 3 if _mobile() else 6
	for i in bolts:
		var off := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * 0.85
		var top := off + Vector3(randf_range(-0.8, 0.8), 10.0, randf_range(-0.8, 0.8))
		for layer in 2:
			var mi := MeshInstance3D.new()
			mi.mesh = EFX._bolt_mesh(top, off, 0.05 if layer == 0 else 0.2, 0.9)
			var m := EFX._mat(Color(1, 1, 0.95, 1.0) if layer == 0 else Color(1.0, 0.82, 0.25, 0.5))
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visible = false
			h.add_child(mi)
			var tw := mi.create_tween()
			tw.tween_interval(i * 0.045)
			tw.tween_callback(func() -> void: mi.visible = true)
			tw.tween_property(m, "albedo_color:a", 0.1, 0.05)
			tw.tween_property(m, "albedo_color:a", 1.0 if layer == 0 else 0.5, 0.04)
			tw.tween_property(m, "albedo_color:a", 0.0, 0.25)
		EFX._particles(h, pos + off + Vector3(0, 0.1, 0), Color(1, 1, 0.8, 1), Color(1, 0.8, 0.2, 0), 8, 0.4, 0.12,
			Vector2(2.0, 5.0), 75.0, Vector3(0, -6, 0), Vector3(0.1, 0.05, 0.1))
	EFX._flash_light(h, Color(1.0, 0.95, 0.7), 7.0, radius + 6.0, 0.3, 4.0)
	_shake(from, 0.25)


# ================================================================== Meteor Storm
static func _meteor_fall(from: Node, at: Vector3, time: float) -> void:
	var h := EFX._holder(from, at, time + 0.2)
	var rock := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.9
	sm.radial_segments = 10
	sm.rings = 6
	rock.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.16, 0.08)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.45, 0.1)
	m.emission_energy_multiplier = 2.5
	rock.material_override = m
	rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	h.add_child(rock)
	var start := Vector3(-3.5, 11.0, -2.5)
	rock.position = start
	var tw := rock.create_tween()
	tw.tween_property(rock, "position", Vector3(0, 0.3, 0), time).set_ease(Tween.EASE_IN)
	# fiery tail that follows the rock
	var tail := EFX._particles(rock, at + start, Color(1.0, 0.7, 0.2, 1.0), Color(0.6, 0.1, 0.02, 0.0), 26, 0.45, 0.8,
		Vector2(0.2, 0.8), 30.0, Vector3(0, 1.0, 0), Vector3(0.15, 0.15, 0.15), true, false)
	tail.local_coords = false


static func _meteor_hit(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	var at := pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * (0.0 if wave == 0 else 0.6)
	EFX.impact(from, "fire", at, radius * 0.7)
	FX.ring(from, at, Color(1.0, 0.55, 0.15, 0.9), radius * 0.9)
	_shake(from, 0.45)
	# the next meteor is already on its way
	var n := SkillDB.hits("meteor_storm", Game.slv("meteor_storm"))
	if wave + 1 < n:
		_meteor_fall(from, pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * 0.6, 0.35)


# ================================================================== Magnus Exorcismus
static func _magnus(from: Node, pos: Vector3, radius: float, wave: int, waves: int) -> void:
	if wave == 0:
		var life := 0.35 * maxi(1, waves) + 0.6
		var h := EFX._holder(from, pos, life + 0.3)
		var gold := Color(1.0, 0.9, 0.45, 0.85)
		var arm := radius * 1.05
		var a := _beam(h, Vector3(0, 0.05, -arm), Vector3(0, 0.05, arm * 0.7), 0.9, gold)
		var b := _beam(h, Vector3(-arm * 0.75, 0.06, -arm * 0.25), Vector3(arm * 0.75, 0.06, -arm * 0.25), 0.9, gold)
		var glow := _disc(h, radius * 1.1, Color(1.0, 0.95, 0.7, 0.35))
		for mi in [a, b, glow]:
			_fade(h, mi.material_override, life - 0.4, 0.4)
		EFX._particles(h, pos + Vector3(0, 0.2, 0), Color(1, 0.97, 0.75, 0.9), Color(1, 0.9, 0.5, 0), 26, 1.4, 0.18,
			Vector2(0.8, 2.0), 15.0, Vector3(0, 0.6, 0), Vector3(radius * 0.6, 0.05, radius * 0.6), true, false)
		EFX._flash_light(h, Color(1.0, 0.92, 0.6), 3.0, radius + 5.0, life, 2.0)
	var at := pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * 0.7
	FX.pillar(from, at, Color(1.0, 0.95, 0.7), 0.45, 8.0, 0.4)


# ================================================================== Grand Cross
static func _grand_cross(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	var h := EFX._holder(from, pos, 1.2)
	var gold := Color(1.0, 0.9, 0.5, 0.9)
	var arm := radius * 1.2
	var mats := []
	for d in [Vector3(1, 0, 0), Vector3(0, 0, 1)]:
		var mi := _beam(h, -d * arm + Vector3(0, 0.05, 0), d * arm + Vector3(0, 0.05, 0), 1.0, gold)
		mats.append(mi.material_override)
	for m in mats:
		_fade(h, m, 0.35, 0.45)
	for d in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		_column(h, d * arm * 0.75, Color(1.0, 0.93, 0.6), 0.35, 5.0, 0.5)
	if wave == 0:
		_column(h, Vector3.ZERO, Color(1.0, 0.97, 0.75), 0.9, 9.0, 0.7)
		EFX._flash_light(h, Color(1.0, 0.9, 0.55), 5.0, radius + 5.0, 0.9, 1.5)
		_shake(from, 0.35)


# ================================================================== Fire Wall
static func _fire_wall(from: Node, pos: Vector3, radius: float, wave: int, waves: int) -> void:
	if wave != 0:
		return
	var life := 0.35 * maxi(1, waves) + 0.6
	var h := EFX._holder(from, pos, life + 1.0)
	var side := Vector3.RIGHT
	if from is Node3D:
		var to := pos - (from as Node3D).global_position
		to.y = 0
		if to.length() > 0.1:
			side = to.normalized().cross(Vector3.UP)
	var cells := 3 if _mobile() else 5
	for i in cells:
		var off := side * (float(i) - (cells - 1) * 0.5) * radius * 0.55
		var p := EFX._particles(h, pos + off + Vector3(0, 0.2, 0), Color(1.0, 0.75, 0.2, 1.0), Color(0.8, 0.1, 0.02, 0.0), 34, 0.8, 1.15,
			Vector2(1.8, 3.4), 12.0, Vector3(0, 1.5, 0), Vector3(0.3, 0.1, 0.3), true, false)
		_column(h, off, Color(1.0, 0.5, 0.12), 0.32, 2.4, life)
		from.get_tree().create_timer(life).timeout.connect(func() -> void:
			if is_instance_valid(p):
				p.emitting = false)
	var g := _beam(h, -side * radius * 1.4, side * radius * 1.4, 0.8, Color(1.0, 0.45, 0.1, 0.55))
	_fade(h, g.material_override, life, 0.6)
	EFX._flash_light(h, Color(1.0, 0.5, 0.15), 3.0, 6.0, life + 0.5, 1.0)


static func _fire_bomb(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	if wave == 0:
		EFX.impact(from, "fire", pos, radius)
	else:
		EFX._particles(EFX._holder(from, pos, 1.2), pos + Vector3(0, 0.15, 0), Color(1.0, 0.6, 0.15, 0.9), Color(0.6, 0.1, 0.02, 0.0),
			14, 0.6, 0.6, Vector2(1.0, 2.2), 20.0, Vector3(0, 1.2, 0), Vector3(radius * 0.5, 0.05, radius * 0.5), false)


# ================================================================== Gravitation Field
static func _gravity(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	if wave == 0:
		var h := EFX._holder(from, pos, 2.2)
		var d := _disc(h, radius * 1.2, Color(0.55, 0.3, 1.0, 0.6))
		_fade(h, d.material_override, 1.4, 0.6)
		# particles spiral inward and sink
		EFX._particles(h, pos + Vector3(0, 2.2, 0), Color(0.8, 0.6, 1.0, 1.0), Color(0.3, 0.1, 0.6, 0.0), 34, 1.0, 0.16,
			Vector2(0.5, 1.2), 180.0, Vector3(0, -5.0, 0), Vector3(radius * 0.7, 0.4, radius * 0.7), true, false, -6.0)
		EFX._flash_light(h, Color(0.6, 0.4, 1.0), 2.5, radius + 4.0, 1.8, 1.0)
	FX.ring(from, pos, Color(0.7, 0.45, 1.0, 0.9), radius * (1.1 - wave * 0.15))
	_shake(from, 0.15)


# ================================================================== Heaven's Drive / Grimtooth / Earth Spike
static func _heavens_drive(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	var at := pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * (0.0 if wave == 0 else 0.5)
	FX.spikes(from, at, Color(0.72, 0.6, 0.42), radius * 0.8, 5 if _mobile() else 9)
	EFX._particles(EFX._holder(from, at, 1.2), at + Vector3(0, 0.2, 0), Color(0.7, 0.58, 0.4, 0.8), Color(0.5, 0.42, 0.3, 0.0), 14, 0.8, 0.5,
		Vector2(0.8, 2.0), 50.0, Vector3(0, -2.0, 0), Vector3(radius * 0.5, 0.05, radius * 0.5), false)
	_shake(from, 0.2)


static func _earth_spike(from: Node, pos: Vector3) -> void:
	FX.spikes(from, pos, Color(0.72, 0.6, 0.42), 0.7, 4)


# ================================================================== ghost (Napalm Beat)
static func _ghost_blast(from: Node, pos: Vector3, radius: float) -> void:
	var h := EFX._holder(from, pos, 1.4)
	EFX._particles(h, pos + Vector3(0, 0.4, 0), Color(0.85, 0.7, 1.0, 0.95), Color(0.4, 0.2, 0.7, 0.0), 22, 0.9, 0.55,
		Vector2(1.5, 3.0), 70.0, Vector3(0, 1.5, 0), Vector3(radius * 0.3, 0.2, radius * 0.3))
	FX.flash(from, pos + Vector3(0, 0.6, 0), Color(0.75, 0.55, 1.0), 0.9 + radius * 0.3)
	FX.ring(from, pos, Color(0.75, 0.55, 1.0, 0.85), radius * 1.1)


# ================================================================== Asura Strike
static func _asura(from: Node, pos: Vector3) -> void:
	var h := EFX._holder(from, pos, 1.6)
	_column(h, Vector3.ZERO, Color(0.8, 0.92, 1.0), 1.2, 10.0, 0.6)
	for r in [1.5, 3.0, 4.5]:
		FX.ring(from, pos, Color(0.85, 0.95, 1.0, 0.9), r)
	EFX._particles(h, pos + Vector3(0, 0.8, 0), Color(1, 1, 1, 1), Color(0.6, 0.85, 1.0, 0), 34, 0.7, 0.2,
		Vector2(5.0, 10.0), 180.0, Vector3(0, -4, 0), Vector3(0.3, 0.3, 0.3))
	FX.flash(from, pos + Vector3(0, 0.9, 0), Color(0.8, 0.92, 1.0), 2.4)
	EFX._flash_light(h, Color(0.75, 0.9, 1.0), 9.0, 10.0, 0.5, 1.5)
	_shake(from, 0.9)


# ================================================================== melee signatures
static func _sonic_blow(from: Node, pos: Vector3) -> void:
	for i in 8:
		from.get_tree().create_timer(0.07 * i).timeout.connect(func() -> void:
			if _ok(from):
				FX.slash_x(from, pos + Vector3(randf_range(-0.3, 0.3), 0.5 + randf() * 0.6, randf_range(-0.3, 0.3)),
					Color(0.85, 0.75, 1.0), 0.8))


static func _holy_cross(from: Node, pos: Vector3) -> void:
	var h := EFX._holder(from, pos, 1.0)
	var gold := Color(1.0, 0.92, 0.55, 0.95)
	var up := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 2.4)
	up.mesh = q
	up.material_override = EFX._mat(gold, true, null, true)
	h.add_child(up)
	up.position = Vector3(0, 1.1, 0)
	var across := MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(1.6, 0.35)
	across.mesh = q2
	across.material_override = EFX._mat(gold, true, null, true)
	h.add_child(across)
	across.position = Vector3(0, 1.45, 0)
	for mi in [up, across]:
		_fade(h, mi.material_override, 0.35, 0.4)
	FX.flash(from, pos + Vector3(0, 1.2, 0), Color(1.0, 0.95, 0.65), 1.0)


static func _frost_joker(from: Node, pos: Vector3, radius: float) -> void:
	for i in 3:
		from.get_tree().create_timer(0.12 * i).timeout.connect(func() -> void:
			if _ok(from):
				FX.ring(from, pos, Color(0.75, 0.92, 1.0, 0.85), radius * (0.4 + 0.3 * i)))
	EFX._particles(EFX._holder(from, pos, 1.6), pos + Vector3(0, 0.6, 0), Color(1, 1, 1, 0.9), Color(0.6, 0.85, 1.0, 0), 30, 1.0, 0.14,
		Vector2(2.0, 4.0), 90.0, Vector3(0, -1.0, 0), Vector3(0.4, 0.2, 0.4))


static func _gospel(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	if wave == 0:
		var h := EFX._holder(from, pos, 1.8)
		var d := _disc(h, radius * 1.1, Color(1.0, 0.9, 0.5, 0.45))
		_fade(h, d.material_override, 1.0, 0.6)
		EFX._particles(h, pos + Vector3(0, 0.3, 0), Color(1, 0.95, 0.7, 1), Color(1, 0.85, 0.4, 0), 24, 1.2, 0.2,
			Vector2(1.0, 2.2), 25.0, Vector3(0, 0.5, 0), Vector3(radius * 0.7, 0.05, radius * 0.7), true, false)
	for i in 3:
		var at := pos + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * 0.7
		FX.pillar(from, at, Color(1.0, 0.93, 0.6), 0.3, 5.0, 0.35)


static func _abracadabra(from: Node, pos: Vector3, radius: float, wave: int) -> void:
	if wave != 0:
		return
	var el := "shadow"
	if from.has_method("_skill_element"):
		el = from._skill_element("arcane_comet")
	if el in ["fire", "water", "wind", "earth", "lightning", "ice"]:
		EFX.impact(from, el, pos, radius)
	else:
		FX.pillar(from, pos, EFX.color(el), 0.8, 8.0, 0.5)
		FX.flash(from, pos + Vector3(0, 0.6, 0), EFX.color(el), 1.6)
	EFX.circle(from, el, pos, radius, 0.9)


# ================================================================== self skills
static func _sanctuary(from: Node, pos: Vector3) -> void:
	var h := EFX._holder(from, pos, 2.4)
	var green := Color(0.65, 1.0, 0.7, 0.55)
	for x in range(-2, 3):
		_beam(h, Vector3(x * 0.6, 0.05, -1.5), Vector3(x * 0.6, 0.05, 1.5), 0.08, green)
		_beam(h, Vector3(-1.5, 0.05, x * 0.6), Vector3(1.5, 0.05, x * 0.6), 0.08, green)
	_disc(h, 2.0, Color(0.6, 1.0, 0.7, 0.45))
	for c in h.get_children():
		if c is MeshInstance3D:
			_fade(h, c.material_override, 1.6, 0.7)
	EFX._particles(h, pos + Vector3(0, 0.2, 0), Color(0.8, 1.0, 0.8, 1), Color(0.5, 1.0, 0.6, 0), 24, 1.3, 0.16,
		Vector2(0.8, 1.8), 10.0, Vector3(0, 0.5, 0), Vector3(1.4, 0.05, 1.4))


static func _bubble(from: Node, pos: Vector3, id: String) -> void:
	var h := EFX._holder(from, pos, 1.6)
	var c := Color(1.0, 0.85, 0.35, 0.35) if id == "zen_guard" else Color(0.7, 0.9, 1.0, 0.3)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 20
	sm.rings = 10
	mi.mesh = sm
	var m := EFX._mat(c)
	m.rim_enabled = true
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	h.add_child(mi)
	mi.position = Vector3(0, 1.0, 0)
	mi.scale = Vector3.ONE * 0.3
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.15, 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.7)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.5)


static func _wings(from: Node, pos: Vector3) -> void:
	var h := EFX._holder(from, pos, 1.8)
	for side in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.4, 1.8)
		mi.mesh = q
		mi.material_override = EFX._mat(Color(1, 1, 1, 0.7), true, EFX.soft_texture(), false)
		h.add_child(mi)
		mi.position = Vector3(side * 0.7, 1.6, -0.2)
		mi.rotation = Vector3(0, side * 0.5, side * 0.35)
		_fade(h, mi.material_override, 1.0, 0.6)
	EFX._particles(h, pos + Vector3(0, 2.4, 0), Color(1, 1, 1, 1), Color(1, 0.95, 0.8, 0), 18, 1.4, 0.18,
		Vector2(0.2, 0.6), 60.0, Vector3(0, -0.8, 0), Vector3(0.9, 0.2, 0.4))


static func _blessing_light(from: Node, pos: Vector3, id: String) -> void:
	var c := Color(0.75, 1.0, 0.75) if id == "increase_agi" else (Color(0.8, 0.9, 1.0) if id == "angelus" else Color(1.0, 0.95, 0.7))
	EFX._particles(EFX._holder(from, pos, 1.8), pos + Vector3(0, 3.2, 0), Color(c, 1.0), Color(c, 0.0), 22, 1.1, 0.16,
		Vector2(0.2, 0.6), 30.0, Vector3(0, -2.5, 0), Vector3(0.6, 0.1, 0.6))


static func _rage(from: Node, pos: Vector3) -> void:
	var h := EFX._holder(from, pos, 1.6)
	EFX._particles(h, pos + Vector3(0, 0.3, 0), Color(1.0, 0.25, 0.15, 0.9), Color(0.4, 0.0, 0.0, 0.0), 30, 0.9, 0.5,
		Vector2(1.5, 3.0), 20.0, Vector3(0, 2.0, 0), Vector3(0.5, 0.1, 0.5), false)
	EFX._flash_light(h, Color(1.0, 0.25, 0.15), 4.0, 6.0, 1.0, 1.2)


static func _spheres(from: Node, pos: Vector3) -> void:
	var h := EFX._holder(from, pos, 1.6)
	for i in 5:
		var a := TAU * i / 5.0
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		mi.mesh = sm
		mi.material_override = EFX._mat(Color(0.7, 0.95, 1.0, 0.95))
		h.add_child(mi)
		mi.position = Vector3(cos(a) * 0.9, 1.4, sin(a) * 0.9)
		var tw := mi.create_tween()
		tw.tween_property(mi, "position", Vector3(cos(a + 2.0) * 0.6, 1.2, sin(a + 2.0) * 0.6), 1.2)
		tw.parallel().tween_property(mi.material_override, "albedo_color:a", 0.0, 1.2)


# ================================================================== recipes for every other skill
## id -> list of [primitive, color]. Wave 0 only. Signature skills above keep their own code.
const RECIPES := {
	# Swordsman / Knight / Lord Knight / Crusader / Paladin
	"bash": [["shock", Color(1.0, 0.85, 0.4)], ["stars", Color(1, 1, 0.6)]],
	"magnum_break": [["fire_ring", Color(1.0, 0.5, 0.15)], ["dust", Color(0.8, 0.6, 0.4)]],
	"pierce": [["line", Color(0.85, 0.95, 1.0)], ["shock", Color(0.85, 0.95, 1.0)]],
	"brandish_spear": [["arc", Color(1.0, 0.9, 0.6)], ["dust", Color(0.8, 0.7, 0.5)]],
	"bowling_bash": [["shock", Color(1.0, 0.75, 0.4)], ["dust", Color(0.85, 0.7, 0.5)]],
	"spiral_pierce": [["drill", Color(0.8, 0.9, 1.0)], ["shock", Color(0.8, 0.9, 1.0)]],
	"shield_rush": [["shock", Color(0.9, 0.9, 1.0)], ["stars", Color(1, 1, 0.6)]],
	"judgement_lance": [["shock", Color(0.95, 0.9, 0.7)]],
	# Archer / Hunter / Sniper / Bard
	"double_strafe": [["sparkle", Color(1.0, 0.95, 0.75)]],
	"blitz_beat": [["falcon", Color(0.75, 0.55, 0.35)]],
	"falcon_assault": [["falcon", Color(0.95, 0.75, 0.35)], ["shock", Color(1.0, 0.85, 0.5)]],
	"ankle_snare": [["trap", Color(0.55, 0.9, 0.4)]],
	"land_mine": [["trap", Color(0.9, 0.7, 0.35)], ["dust", Color(0.8, 0.65, 0.4)]],
	"claymore_trap": [["trap", Color(1.0, 0.5, 0.2)], ["fire_ring", Color(1.0, 0.5, 0.15)]],
	"sharp_shooting": [["line", Color(0.8, 0.95, 1.0)]],
	"crescendo": [["sparkle", Color(0.85, 0.95, 1.0)]],
	"dissonant_chord": [["notes", Color(0.85, 0.75, 1.0)]],
	"trick_shot": [["sparkle", Color(1.0, 0.95, 0.75)]],
	# Mage / Wizard / Sage
	"fire_bolt": [["glow", Color(1.0, 0.5, 0.15)]],
	"cold_bolt": [["glow", Color(0.6, 0.85, 1.0)]],
	"lightning_bolt": [["glow", Color(1.0, 0.95, 0.5)]],
	"soul_strike": [["ghost", Color(0.8, 0.65, 1.0)]],
	"fire_ball": [["fire_ring", Color(1.0, 0.45, 0.1)]],
	"frost_diver": [["ice_block", Color(0.7, 0.9, 1.0)]],
	"jupitel_thunder": [["thunder_ball", Color(0.7, 0.75, 1.0)]],
	"holy_light": [["sky_beam", Color(1.0, 0.95, 0.7)]],
	"soul_destroyer": [["ghost", Color(0.55, 0.3, 0.85)]],
	"chi_burst": [["glow", Color(0.7, 0.95, 1.0)]],
	# Merchant / Blacksmith / Alchemist
	"mammonite": [["coins", Color(1.0, 0.85, 0.3)], ["shock", Color(1.0, 0.85, 0.3)]],
	"cart_revolution": [["shock", Color(0.85, 0.65, 0.35)], ["dust", Color(0.8, 0.65, 0.45)]],
	"cart_termination": [["coins", Color(1.0, 0.85, 0.3)], ["dust", Color(0.8, 0.65, 0.45)], ["stars", Color(1, 1, 0.6)]],
	"hammer_fall": [["shock", Color(0.95, 0.8, 0.45)], ["stars", Color(1, 1, 0.6)]],
	"acid_flask": [["splash", Color(0.6, 0.95, 0.3)]],
	"golem_smash": [["splash", Color(0.75, 0.95, 0.35)], ["fire_ring", Color(1.0, 0.6, 0.2)]],
	"shrapnel_bomb": [["fire_ring", Color(1.0, 0.6, 0.25)], ["dust", Color(0.7, 0.6, 0.5)]],
	# Thief / Assassin / Rogue
	"envenom": [["splash", Color(0.5, 0.9, 0.3)]],
	"sand_attack": [["dust", Color(0.9, 0.78, 0.5)]],
	"steal": [["sparkle", Color(1.0, 0.85, 0.3)]],
	"meteor_assault": [["shock", Color(0.6, 0.35, 0.95)], ["smoke", Color(0.4, 0.25, 0.55)]],
	"dirty_trick": [["smoke", Color(0.5, 0.5, 0.6)]],
	"knife_fan": [["smoke", Color(0.6, 0.6, 0.7)], ["stars", Color(1, 1, 0.6)]],
	"ambush_combo": [["smoke", Color(0.5, 0.5, 0.6)]],
	# Monk / Champion
	"palm_strike": [["shock", Color(0.8, 0.9, 1.0)]],
	"rising_dragon_kick": [["shock", Color(0.8, 0.95, 1.0)], ["stars", Color(1, 1, 0.6)]],
}

## Self skills (buffs / heals) -> aura colour.
const AURAS := {
	"endure": Color(1.0, 0.7, 0.3), "two_hand_quicken": Color(1.0, 0.85, 0.4), "aura_blade": Color(0.7, 0.85, 1.0),
	"parrying": Color(0.85, 0.9, 1.0), "improve_concentration": Color(0.7, 1.0, 0.7), "true_sight": Color(0.75, 0.95, 1.0),
	"wind_walk": Color(0.7, 1.0, 0.85), "mystical_amplification": Color(0.75, 0.6, 1.0), "impositio_manus": Color(1.0, 0.95, 0.6),
	"adrenaline_rush": Color(1.0, 0.45, 0.2), "power_thrust": Color(1.0, 0.6, 0.25), "maximize_power": Color(1.0, 0.85, 0.35),
	"maximum_overthrust": Color(1.0, 0.35, 0.15), "meltdown": Color(1.0, 0.55, 0.2), "cloaking": Color(0.5, 0.5, 0.6),
	"enchant_poison": Color(0.5, 0.95, 0.35), "enchant_deadly_poison": Color(0.6, 0.25, 0.85), "rhythm_of_haste": Color(1.0, 0.8, 0.4),
	"stage_presence": Color(0.75, 1.0, 0.85), "ballad_of_vigor": Color(1.0, 0.5, 0.5), "whiplash_volley": Color(0.85, 0.75, 1.0),
	"virtuoso_focus": Color(0.75, 0.65, 1.0), "elemental_infusion": Color(1.0, 0.45, 0.15), "spell_ward": Color(0.6, 0.75, 1.0),
	"chain_spark": Color(0.6, 0.8, 1.0), "runic_aegis": Color(0.8, 0.75, 1.0), "alloy_coating": Color(0.7, 0.95, 0.75),
	"elixir_rush": Color(1.0, 0.4, 0.3), "smoke_veil": Color(0.55, 0.55, 0.65), "shadow_step": Color(0.45, 0.45, 0.55),
	"phantom_blades": Color(0.85, 0.85, 0.95), "aegis_vow": Color(0.95, 0.9, 0.7), "holy_bastion": Color(1.0, 0.95, 0.7),
	"basilica": Color(1.0, 0.95, 0.75), "magnificat": Color(1.0, 0.95, 0.75), "field_dressing": Color(0.6, 1.0, 0.6),
	"heal": Color(0.6, 1.0, 0.65),
}


static func _recipe(from: Node, id: String, pos: Vector3, radius: float, wave: int) -> void:
	if wave != 0:
		return
	var list: Array = RECIPES.get(id, [])
	if list.is_empty():
		list = _default_recipe(id)
	for step in list:
		_prim(from, String(step[0]), step[1], pos, radius)


## Skills without their own entry (3rd/4th-job skills): pick something fitting from type and element.
static func _default_recipe(id: String) -> Array:
	var s := SkillDB.info(id)
	var el := ""
	for k in ["fire", "ice", "lightning", "earth", "wind", "holy", "shadow", "water"]:
		if id.contains(k):
			el = k
	var c: Color = s.get("color", Color(1.0, 0.85, 0.55))
	match String(s.get("type", "")):
		"aoe_self":
			return [["shock", c], ["dust", Color(0.8, 0.7, 0.55)]]
		"aoe_target":
			return [["sky_beam", c], ["shock", c]]
		"bolt":
			return [["glow", c]]
		"melee":
			return [["shock", c]]
	return []


static func _prim(from: Node, kind: String, c: Color, pos: Vector3, radius: float) -> void:
	match kind:
		"shock": _shockwave(from, pos, c, maxf(1.2, radius))
		"stars": _stun_stars(from, pos, c)
		"fire_ring": _fire_ring(from, pos, c, maxf(1.5, radius))
		"dust": _dust(from, pos, c, maxf(1.0, radius))
		"line": _line_beam(from, pos, c)
		"arc": _arc(from, pos, c, maxf(2.0, radius))
		"drill": _drill(from, pos, c)
		"sparkle": _sparkle(from, pos, c)
		"falcon": _falcon(from, pos, c)
		"trap": _trap(from, pos, c)
		"notes": _notes(from, pos, c)
		"glow": FX.flash(from, pos + Vector3(0, 0.7, 0), c, 0.9)
		"ghost": _ghost_blast(from, pos, 0.8)
		"ice_block": _ice_block(from, pos)
		"thunder_ball": _thunder_ball(from, pos, c)
		"sky_beam": FX.pillar(from, pos, c, 0.55, 9.0, 0.45)
		"coins": _coins(from, pos)
		"splash": _splash(from, pos, c)
		"smoke": _smoke(from, pos, c)


# ------------------------------------------------------------------ primitives
static func _shockwave(from: Node, pos: Vector3, c: Color, radius: float) -> void:
	var h := EFX._holder(from, pos, 0.8)
	var d := _disc(h, 0.4, Color(c, 0.8), 0.06)
	var m: StandardMaterial3D = d.material_override
	var tw := d.create_tween()
	tw.tween_property(d, "scale", Vector3.ONE * radius * 2.6, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.4)
	FX.ring(from, pos, Color(c, 0.9), radius * 0.8)


static func _stun_stars(from: Node, pos: Vector3, c: Color) -> void:
	var h := EFX._holder(from, pos, 1.6)
	var pivot := Node3D.new()
	h.add_child(pivot)
	pivot.position = Vector3(0, 1.9, 0)
	for i in 3:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.28, 0.28)
		mi.mesh = q
		mi.material_override = EFX._mat(Color(c, 1.0), true, EFX.soft_texture(), true)
		pivot.add_child(mi)
		var a := TAU * i / 3.0
		mi.position = Vector3(cos(a) * 0.45, 0, sin(a) * 0.45)
		var tw := mi.create_tween()
		tw.tween_interval(1.0)
		tw.tween_property(mi.material_override, "albedo_color:a", 0.0, 0.4)
	var spin := pivot.create_tween()
	spin.tween_property(pivot, "rotation:y", TAU * 2.0, 1.4)


static func _fire_ring(from: Node, pos: Vector3, c: Color, radius: float) -> void:
	var h := EFX._holder(from, pos, 1.4)
	var n := 8 if _mobile() else 14
	for i in n:
		var a := TAU * i / n
		var at := pos + Vector3(cos(a), 0, sin(a)) * radius * 0.75
		EFX._particles(h, at + Vector3(0, 0.15, 0), Color(c.lightened(0.3), 1.0), Color(c.darkened(0.4), 0.0), 8, 0.55, 0.5,
			Vector2(1.5, 3.0), 15.0, Vector3(0, 1.0, 0), Vector3(0.12, 0.05, 0.12))
	_shockwave(from, pos, c, radius)
	EFX._flash_light(h, c, 4.0, radius + 4.0, 0.5, 1.0)


static func _dust(from: Node, pos: Vector3, c: Color, radius: float) -> void:
	EFX._particles(EFX._holder(from, pos, 1.4), pos + Vector3(0, 0.15, 0), Color(c, 0.75), Color(c, 0.0), 16, 0.9, 0.6,
		Vector2(1.0, 2.6), 80.0, Vector3(0, -0.6, 0), Vector3(radius * 0.4, 0.05, radius * 0.4), false)


static func _line_beam(from: Node, pos: Vector3, c: Color) -> void:
	if not (from is Node3D):
		return
	var a: Vector3 = (from as Node3D).global_position + Vector3(0, 0.9, 0)
	var b := pos + Vector3(0, 0.7, 0)
	var dir := (b - a)
	dir.y = 0
	if dir.length() < 0.1:
		return
	b = a + dir.normalized() * (dir.length() + 3.0) + Vector3(0, -0.2, 0)
	var h := EFX._holder(from, a, 0.6)
	var mi := MeshInstance3D.new()
	mi.mesh = EFX._bolt_mesh(Vector3.ZERO, b - a, 0.16, 0.0)
	var m := EFX._mat(Color(c, 0.95))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	h.add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.4)


static func _arc(from: Node, pos: Vector3, c: Color, radius: float) -> void:
	if from is Node3D:
		var o: Vector3 = (from as Node3D).global_position
		var h := EFX._holder(from, o, 0.8)
		var fwd := (pos - o)
		fwd.y = 0
		fwd = fwd.normalized() if fwd.length() > 0.1 else Vector3.FORWARD
		for i in 7:
			var a := lerpf(-1.1, 1.1, i / 6.0)
			var at := fwd.rotated(Vector3.UP, a) * radius * 0.85
			_column(h, at, c, 0.12, 1.2, 0.35)
	_dust(from, pos, Color(0.85, 0.75, 0.55), radius * 0.6)


static func _drill(from: Node, pos: Vector3, c: Color) -> void:
	var h := EFX._holder(from, pos, 1.0)
	EFX._particles(h, pos + Vector3(0, 0.8, 0), Color(c, 1.0), Color(c, 0.0), 30, 0.6, 0.18, Vector2(0.5, 1.5), 30.0,
		Vector3(0, -3.0, 0), Vector3(0.3, 0.6, 0.3), true, false, 14.0)
	_column(h, Vector3.ZERO, c, 0.4, 3.0, 0.4)


static func _sparkle(from: Node, pos: Vector3, c: Color) -> void:
	EFX._particles(EFX._holder(from, pos, 1.0), pos + Vector3(0, 0.8, 0), Color(c, 1.0), Color(c, 0.0), 14, 0.6, 0.12,
		Vector2(1.0, 2.5), 180.0, Vector3(0, -1.0, 0), Vector3(0.2, 0.3, 0.2))


static func _falcon(from: Node, pos: Vector3, c: Color) -> void:
	# a simple bird: two wing quads in a V that swoop down onto the target
	var start := pos + Vector3(-4.0, 6.0, -3.0)
	var h := EFX._holder(from, start, 0.9)
	var bird := Node3D.new()
	h.add_child(bird)
	for side in [-1.0, 1.0]:
		var w := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.9, 0.32)
		w.mesh = q
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		w.material_override = m
		w.position = Vector3(side * 0.42, 0, 0)
		w.rotation = Vector3(PI * 0.5, 0, side * 0.35)
		bird.add_child(w)
	bird.look_at_from_position(start, pos, Vector3.UP)
	var tw := bird.create_tween()
	tw.tween_property(bird, "global_position", pos + Vector3(0, 0.8, 0), 0.35).set_ease(Tween.EASE_IN)
	tw.tween_property(bird, "global_position", pos + Vector3(4.0, 5.0, 3.0), 0.4).set_ease(Tween.EASE_OUT)
	from.get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if _ok(from):
			_sparkle(from, pos, Color(1.0, 0.95, 0.8))
			FX.flash(from, pos + Vector3(0, 0.8, 0), Color(1.0, 0.95, 0.8), 0.9))


static func _trap(from: Node, pos: Vector3, c: Color) -> void:
	var h := EFX._holder(from, pos, 1.2)
	var dev := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22
	cm.bottom_radius = 0.28
	cm.height = 0.12
	dev.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.3, 0.25)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 1.5
	dev.material_override = m
	dev.position = Vector3(0, 0.06, 0)
	h.add_child(dev)
	var tw := dev.create_tween()
	tw.tween_property(dev, "scale", Vector3(1.6, 0.3, 1.6), 0.5).set_delay(0.3)
	FX.ring(from, pos, Color(c, 0.9), 1.1)
	_sparkle(from, pos, c)


static func _notes(from: Node, pos: Vector3, c: Color) -> void:
	EFX._particles(EFX._holder(from, pos, 1.6), pos + Vector3(0, 1.0, 0), Color(c, 1.0), Color(c, 0.0), 10, 1.2, 0.22,
		Vector2(0.6, 1.4), 40.0, Vector3(0, 0.6, 0), Vector3(0.4, 0.3, 0.4))


static func _ice_block(from: Node, pos: Vector3) -> void:
	# Frost Diver: ice runs along the ground to the target, which ends up in a block of ice
	if from is Node3D:
		var o: Vector3 = (from as Node3D).global_position
		var steps := 5
		for i in steps:
			var at := o.lerp(pos, (i + 1.0) / steps)
			from.get_tree().create_timer(0.04 * i).timeout.connect(func() -> void:
				if _ok(from):
					FX.spikes(from, at, Color(0.75, 0.92, 1.0, 0.9), 0.35, 3))
	var h := EFX._holder(from, pos, 2.2)
	var block := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 1.6, 1.1)
	block.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.7, 0.9, 1.0, 0.45)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.4, 0.7, 1.0)
	m.emission_energy_multiplier = 0.6
	m.rim_enabled = true
	block.material_override = m
	block.position = Vector3(0, 0.8, 0)
	block.scale = Vector3(1, 0.05, 1)
	h.add_child(block)
	var tw := block.create_tween()
	tw.tween_interval(0.2)
	tw.tween_property(block, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.4)


static func _thunder_ball(from: Node, pos: Vector3, c: Color) -> void:
	var h := EFX._holder(from, pos, 0.9)
	for i in 4:
		var a := randf() * TAU
		var mi := MeshInstance3D.new()
		mi.mesh = EFX._bolt_mesh(Vector3(0, 0.8, 0), Vector3(cos(a) * 1.2, 0.3 + randf() * 1.2, sin(a) * 1.2), 0.05, 0.4)
		var m := EFX._mat(Color(0.9, 0.92, 1.0, 1.0))
		mi.material_override = m
		h.add_child(mi)
		var tw := mi.create_tween()
		tw.tween_property(m, "albedo_color:a", 0.0, 0.3).set_delay(0.05 * i)
	FX.flash(from, pos + Vector3(0, 0.8, 0), c, 1.2)


static func _coins(from: Node, pos: Vector3) -> void:
	var h := EFX._holder(from, pos, 1.4)
	var p := EFX._particles(h, pos + Vector3(0, 1.0, 0), Color(1.0, 0.85, 0.3, 1.0), Color(1.0, 0.75, 0.2, 0.0), 18, 1.0, 0.16,
		Vector2(2.5, 4.5), 70.0, Vector3(0, -9.0, 0), Vector3(0.2, 0.2, 0.2), false)
	p.direction = Vector3.UP


static func _splash(from: Node, pos: Vector3, c: Color) -> void:
	var h := EFX._holder(from, pos, 1.2)
	EFX._particles(h, pos + Vector3(0, 0.8, 0), Color(c, 1.0), Color(c.darkened(0.3), 0.0), 18, 0.7, 0.2,
		Vector2(1.5, 3.5), 75.0, Vector3(0, -7.0, 0), Vector3(0.2, 0.2, 0.2), false)
	var d := _disc(h, 0.9, Color(c, 0.55))
	_fade(h, d.material_override, 0.5, 0.5)


static func _smoke(from: Node, pos: Vector3, c: Color) -> void:
	EFX._particles(EFX._holder(from, pos, 1.6), pos + Vector3(0, 0.5, 0), Color(c, 0.75), Color(c, 0.0), 18, 1.1, 1.0,
		Vector2(0.4, 1.2), 90.0, Vector3(0, 0.4, 0), Vector3(0.4, 0.3, 0.4), false)


## Rising aura around the caster for a buff.
static func aura(from: Node, id: String, pos: Vector3) -> void:
	if not _ok(from) or not AURAS.has(id):
		return
	var c: Color = AURAS[id]
	var h := EFX._holder(from, pos, 1.5)
	EFX._particles(h, pos + Vector3(0, 0.1, 0), Color(c, 0.9), Color(c, 0.0), 22 if not _mobile() else 12, 0.9, 0.35,
		Vector2(1.0, 2.6), 10.0, Vector3(0, 1.0, 0), Vector3(0.45, 0.05, 0.45), true)
	var d := _disc(h, 1.1, Color(c, 0.45))
	_fade(h, d.material_override, 0.6, 0.6)


## Ragnarok drops Fire/Cold/Lightning Bolt from the sky onto the target: start point of each bolt.
static func sky_start(id: String, target: Vector3) -> Vector3:
	if id in ["fire_bolt", "cold_bolt", "lightning_bolt", "napalm_vulcan", "holy_light"]:
		return target + Vector3(randf_range(-0.8, 0.8), 7.5, randf_range(-0.8, 0.8))
	return Vector3.INF


## Lightning Bolt arrives as real lightning from the sky instead of a projectile.
static func sky_lightning(from: Node, pos: Vector3) -> void:
	var h := EFX._holder(from, pos, 0.5)
	var top := Vector3(randf_range(-0.6, 0.6), 9.0, randf_range(-0.6, 0.6))
	for layer in 2:
		var mi := MeshInstance3D.new()
		mi.mesh = EFX._bolt_mesh(top, Vector3(0, 0.3, 0), 0.05 if layer == 0 else 0.18, 0.7)
		var m := EFX._mat(Color(1, 1, 0.95, 1.0) if layer == 0 else Color(1.0, 0.9, 0.35, 0.5))
		mi.material_override = m
		h.add_child(mi)
		var tw := mi.create_tween()
		tw.tween_property(m, "albedo_color:a", 0.0, 0.3)
	EFX._flash_light(h, Color(1.0, 0.95, 0.6), 5.0, 6.0, 0.25, 3.0)
