class_name FX
extends RefCounted
## Small visual effects shared by players and monsters.


## Floating text (damage numbers, "LEVEL UP!", "MISS"...) that rises and fades.
static var _font: Font


static func popup(from: Node, pos: Vector3, text: String, color: Color, size := 56, rise := 1.1) -> void:
	if from == null or not from.is_inside_tree():
		return
	# Combat callers pass bare numbers, append ! on crits, or pass Miss.
	# Keep loot, healing, EXP and other messages on the existing world-label path.
	var digits := text.trim_suffix("!")
	var miss := text == "Miss"
	if miss or (digits.is_valid_int() and digits[0] in "0123456789"):
		if not Settings.is_mobile():
			var state = from.get_node_or_null("/root/Game")
			var ui = state.get("ui") if state != null else null
			if is_instance_valid(ui) and ui.has_method("record_combat_event"):
				ui.record_combat_event(from, digits, text.ends_with("!"), miss)
		if Settings.g("damage_numbers"):
			_damage_popup(from, pos, "MISS" if miss else digits, color, text.ends_with("!"), miss)
		return
	var root := from.get_tree().current_scene
	if root == null:
		root = from.get_tree().root
	var l := Label3D.new()
	l.text = TranslationServer.translate(text)
	if _font == null:
		_font = load("res://assets/fonts/ui_font_bold.tres")
	l.font = _font
	l.font_size = size
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.modulate = color
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.outline_render_priority = 9
	root.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.25, 0.25), 0, randf_range(-0.1, 0.1))
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "global_position", l.global_position + Vector3(0, rise, 0), 0.9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "scale", Vector3.ONE * 1.3, 0.12)
	tw.chain().tween_property(l, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(l.queue_free)


static func _damage_popup(from: Node, pos: Vector3, text: String, old_color: Color, crit: bool, miss: bool) -> void:
	var scene := _scene_root(from)
	var layer := scene.get_node_or_null("CombatDamagePopups") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "CombatDamagePopups"
		layer.layer = 0
		scene.add_child(layer)
	# Keep independent arcs and bound the number alive on each target.
	var stack: Array = from.get_meta(&"combat_popup_stack", [])
	var live: Array = []
	for old in stack:
		if is_instance_valid(old) and old.is_inside_tree() and not old.is_queued_for_deletion():
			live.append(old)
	while live.size() >= 8:
		live.pop_front().queue_free()
	var lane := int(from.get_meta(&"combat_popup_arc_lane", 0))
	from.set_meta(&"combat_popup_arc_lane", (lane + 1) % 5)
	var ink := Color("#fffdf4")
	if crit:
		ink = Color("#ffe26a")
	elif not miss and old_color.r > 0.9 and old_color.g <= 0.5:
		ink = Color("#ff615d")
	elif not miss and old_color.g > old_color.r:
		ink = Color("#a4ec66")
	var label := preload("res://scripts/combat/damage_popup.gd").new()
	label.anchor = pos
	label.lane = lane
	label.setup(text, ink, crit, miss)
	layer.add_child(label)
	live.append(label)
	from.set_meta(&"combat_popup_stack", live)


## Quick ring burst on the ground (hit / slam effect).
static func ring(from: Node, pos: Vector3, color: Color, radius := 1.0) -> void:
	if from == null or not from.is_inside_tree():
		return
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.85
	t.outer_radius = 1.0
	t.rings = 20
	t.ring_segments = 4
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	mi.material_override = m
	var root := from.get_tree().current_scene
	if root == null:
		root = from.get_tree().root
	root.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.05, 0)
	mi.scale = Vector3(0.2, 0.2, 0.2) * radius
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(1, 0.3, 1) * radius, 0.35)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.35)
	tw.chain().tween_callback(mi.queue_free)


## Arrow / magic bolt flying from `a` to `b`; calls `on_hit` when it lands.
static func projectile(from: Node, a: Vector3, b: Vector3, kind: String, on_hit: Callable, big := false) -> void:
	if from == null or not from.is_inside_tree():
		on_hit.call()
		return
	Audio.play("bow_shot" if kind == "arrow" else "bolt", a, -2.0 if kind == "arrow" else -6.0)
	var root := from.get_tree().current_scene
	if root == null:
		root = from.get_tree().root
	var node := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var color := Color(1.0, 0.55, 0.2)
	if kind == "arrow":
		var shaft := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.05, 0.62)
		shaft.mesh = bm
		mat.albedo_color = Color(0.55, 0.38, 0.2)
		shaft.material_override = mat
		node.add_child(shaft)
		var tip := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.08, 0.08, 0.12)
		tip.mesh = tm
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = Color(0.85, 0.87, 0.9)
		tip.material_override = tmat
		tip.position.z = 0.34
		node.add_child(tip)
		var fl := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.14, 0.02, 0.14)
		fl.mesh = fm
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(0.95, 0.95, 0.92)
		fl.material_override = fmat
		fl.position.z = -0.26
		node.add_child(fl)
		color = Color(1, 1, 1, 0.7)
	else:
		var kinds := {"fire": Color(1.0, 0.45, 0.12), "ice": Color(0.55, 0.85, 1.0), "lightning": Color(1.0, 0.95, 0.4), "holy": Color(1.0, 0.95, 0.65)}
		if kinds.has(kind):
			color = kinds[kind]
		else:
			color = Color(1.0, 0.45, 0.15) if from.get_node_or_null("/root/Game") == null or from.get_node("/root/Game").job_id != "acolyte" else Color(1.0, 0.95, 0.55)
		var orb := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		var s := 0.32 if big else 0.22
		bm2.size = Vector3(s, s, s)
		orb.mesh = bm2
		mat.albedo_color = color
		orb.material_override = mat
		node.add_child(orb)
		var core := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(s, s, s) * 0.55
		core.mesh = cm
		var cmat := StandardMaterial3D.new()
		cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cmat.albedo_color = Color(1, 1, 0.85)
		core.material_override = cmat
		node.add_child(core)
		var spin := node.create_tween().set_loops()
		spin.tween_property(orb, "rotation", Vector3(TAU, TAU, 0), 0.4).from(Vector3.ZERO)
	root.add_child(node)
	node.global_position = a
	if a.distance_to(b) > 0.01:
		node.look_at(b, Vector3.UP)
		node.rotate_object_local(Vector3.UP, PI)
	if big:
		load("res://scripts/combat/skill_power.gd").projectile_tail(node, color)
	var t := clampf(a.distance_to(b) / 22.0, 0.08, 0.45)
	var tw := node.create_tween()
	if kind == "arrow":
		var mid := (a + b) * 0.5 + Vector3(0, a.distance_to(b) * 0.06, 0)
		tw.tween_method(func(k: float) -> void:
			var p := a.lerp(mid, k).lerp(mid.lerp(b, k), k)
			if is_instance_valid(node):
				node.global_position = p, 0.0, 1.0, t)
	else:
		tw.tween_property(node, "global_position", b, t)
	tw.tween_callback(func() -> void:
		on_hit.call()
		ring(from, Vector3(b.x, (from as Node3D).global_position.y if from is Node3D else 0.0, b.z), color, 0.6 if kind == "arrow" else 1.1)
		node.queue_free())


## Burst of little cubes flying out from `pos` (area skills).
static func burst(from: Node, pos: Vector3, color: Color, radius := 2.0) -> void:
	if from == null or not from.is_inside_tree():
		return
	var root := from.get_tree().current_scene
	if root == null:
		root = from.get_tree().root
	var p := CPUParticles3D.new()
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bm := BoxMesh.new()
	bm.size = Vector3(0.18, 0.18, 0.18)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.material = m
	p.mesh = bm
	p.amount = 14 if Settings.is_mobile() else 28
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = radius * 2.0
	p.initial_velocity_max = radius * 3.5
	p.gravity = Vector3(0, -12, 0)
	var g := Gradient.new()
	g.set_color(0, Color(color, 1.0))
	g.set_color(1, Color(color, 0.0))
	p.color_ramp = g
	root.add_child(p)
	p.global_position = pos + Vector3(0, 0.3, 0)
	p.emitting = true
	from.get_tree().create_timer(1.2).timeout.connect(p.queue_free)


# ------------------------------------------------------------------ richer skill effects
static func _scene_root(from: Node) -> Node:
	var root := from.get_tree().current_scene
	return root if root != null else from.get_tree().root


static func _glow_mat(c: Color, additive := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = c
	m.vertex_color_use_as_albedo = true
	return m


## Curved ribbon mesh (weapon trail / slash). Arc in the XZ plane of `parent`.
static func arc_mesh(radius: float, from_deg: float, to_deg: float, width: float, tilt := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 14
	for i in seg:
		var t0 := float(i) / seg
		var t1 := float(i + 1) / seg
		var a0 := deg_to_rad(lerpf(from_deg, to_deg, t0))
		var a1 := deg_to_rad(lerpf(from_deg, to_deg, t1))
		var w0 := width * sin(t0 * PI)
		var w1 := width * sin(t1 * PI)
		var p0 := Vector3(sin(a0), tilt * (t0 - 0.5), cos(a0))
		var p1 := Vector3(sin(a1), tilt * (t1 - 0.5), cos(a1))
		var o0 := p0 * (radius + w0)
		var i0 := p0 * (radius - w0 * 0.3)
		var o1 := p1 * (radius + w1)
		var i1 := p1 * (radius - w1 * 0.3)
		var c0 := Color(1, 1, 1, t0)
		var c1 := Color(1, 1, 1, t1)
		for v in [[i0, c0], [o0, c0], [o1, c1], [i0, c0], [o1, c1], [i1, c1]]:
			st.set_color(v[1])
			st.add_vertex(v[0])
	return st.commit()


## Sword swoosh that follows `parent` (the character model).
static func trail(parent: Node3D, color: Color, from_deg: float, to_deg: float, height := 1.0, roll := 0.0, radius := 0.85) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var mi := MeshInstance3D.new()
	mi.mesh = arc_mesh(radius, from_deg, to_deg, 0.22, 0.25)
	var m := _glow_mat(Color(color, 0.85))
	mi.material_override = m
	mi.position = Vector3(0, height, 0.05)
	mi.rotation = Vector3(0, 0, roll)
	parent.add_child(mi)
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.28).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(mi, "scale", Vector3.ONE * 1.15, 0.28)
	tw.tween_callback(mi.queue_free)


## Bright flash ball + spark burst at an impact point.
static func flash(from: Node, pos: Vector3, color: Color, size := 1.0) -> void:
	if from == null or not from.is_inside_tree():
		return
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	var m := _glow_mat(Color(color.lightened(0.3), 0.9))
	mi.material_override = m
	_scene_root(from).add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * 0.2 * size
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * size, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(mi.queue_free)
	sparks(from, pos, color, int(10 * size) + 6, 3.0 * size)


static func sparks(from: Node, pos: Vector3, color: Color, amount := 16, speed := 3.0) -> void:
	var p := CPUParticles3D.new()
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.06, 0.22)
	bm.material = _glow_mat(color)
	p.mesh = bm
	p.amount = clampi(int(amount * (0.4 if Settings.is_mobile() else 0.75)), 1, 16 if Settings.is_mobile() else 40)
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.6
	p.initial_velocity_max = speed * 1.3
	p.gravity = Vector3(0, -6, 0)
	p.particle_flag_align_y = true
	var g := Gradient.new()
	g.set_color(0, Color(color.lightened(0.5), 1.0))
	g.set_color(1, Color(color, 0.0))
	p.color_ramp = g
	_scene_root(from).add_child(p)
	p.global_position = pos
	p.emitting = true
	from.get_tree().create_timer(1.0).timeout.connect(p.queue_free)


## Column of light from the sky (lightning / holy).
static func pillar(from: Node, pos: Vector3, color: Color, radius := 0.6, height := 7.0, time := 0.45) -> void:
	if from == null or not from.is_inside_tree():
		return
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius * 0.6
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 10
	cm.cap_top = false
	cm.cap_bottom = false
	mi.mesh = cm
	var m := _glow_mat(Color(color, 0.75))
	mi.material_override = m
	_scene_root(from).add_child(mi)
	mi.global_position = pos + Vector3(0, height * 0.5, 0)
	mi.scale = Vector3(0.2, 1, 0.2)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(1, 1, 1), 0.08)
	tw.tween_property(mi, "scale", Vector3(0.05, 1, 0.05), time).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, time)
	tw.tween_callback(mi.queue_free)
	ring(from, pos, Color(color, 0.9), radius * 2.4)
	sparks(from, pos + Vector3(0, 0.3, 0), color, 14, 3.5)


## Crystal / blade spikes bursting out of the ground.
static func spikes(from: Node, pos: Vector3, color: Color, radius := 2.0, count := 9) -> void:
	if from == null or not from.is_inside_tree():
		return
	var root := _scene_root(from)
	for i in count:
		var a := randf() * TAU
		var d := sqrt(randf()) * radius
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.25, 0.9 + randf() * 0.7, 0.25)
		mi.mesh = pm
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.6
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m
		root.add_child(mi)
		mi.global_position = pos + Vector3(cos(a) * d, -0.6, sin(a) * d)
		mi.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
		var tw := mi.create_tween()
		tw.tween_property(mi, "global_position:y", pos.y + pm.size.y * 0.4, 0.1 + randf() * 0.08)
		tw.tween_interval(0.35)
		tw.tween_property(m, "albedo_color:a", 0.0, 0.3)
		tw.tween_callback(mi.queue_free)


## Rotating magic circle on the ground under `node` (casting / buffs).
static func magic_circle(node: Node3D, color: Color, radius := 1.2, time := 0.8) -> void:
	if node == null or not node.is_inside_tree():
		return
	var holder := Node3D.new()
	_scene_root(node).add_child(holder)
	holder.global_position = node.global_position + Vector3(0, 0.07, 0)
	var mats := []
	for k in 3:
		var mi := MeshInstance3D.new()
		var t := TorusMesh.new()
		var r: float = radius * [1.0, 0.72, 0.42][k]
		t.inner_radius = r * 0.93
		t.outer_radius = r
		t.rings = 32
		t.ring_segments = 3
		mi.mesh = t
		var m := _glow_mat(Color(color, 0.8))
		mi.material_override = m
		mi.scale = Vector3(1, 0.05, 1)
		holder.add_child(mi)
		mats.append(m)
	for k in 6:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(radius * 1.4, 0.01, 0.03)
		mi.mesh = bm
		mi.material_override = mats[0]
		mi.rotation.y = k * PI / 3.0
		holder.add_child(mi)
	var rise := CPUParticles3D.new()
	rise.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pb := BoxMesh.new()
	pb.size = Vector3.ONE * 0.06
	pb.material = _glow_mat(color)
	rise.mesh = pb
	rise.amount = 7 if Settings.is_mobile() else 12
	rise.lifetime = 0.8
	rise.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	rise.emission_ring_axis = Vector3.UP
	rise.emission_ring_radius = radius
	rise.emission_ring_inner_radius = radius * 0.6
	rise.emission_ring_height = 0.01
	rise.direction = Vector3.UP
	rise.spread = 5.0
	rise.gravity = Vector3.ZERO
	rise.initial_velocity_min = 1.2
	rise.initial_velocity_max = 2.4
	var g := Gradient.new()
	g.set_color(0, Color(color.lightened(0.4), 1.0))
	g.set_color(1, Color(color, 0.0))
	rise.color_ramp = g
	holder.add_child(rise)
	var tw := holder.create_tween()
	tw.set_parallel(true)
	tw.tween_property(holder, "rotation:y", PI, time)
	for m in mats:
		tw.tween_property(m, "albedo_color:a", 0.0, time * 0.5).set_delay(time * 0.5)
	tw.chain().tween_callback(func() -> void: rise.emitting = false)
	tw.chain().tween_interval(0.8)
	tw.chain().tween_callback(holder.queue_free)


## Big X-shaped slash at a target (melee skills).
static func slash_x(from: Node, pos: Vector3, color: Color, size := 1.0) -> void:
	if from == null or not from.is_inside_tree():
		return
	var root := _scene_root(from)
	var cam := from.get_viewport().get_camera_3d()
	for k in 2:
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(1.9 * size, 0.18 * size)
		mi.mesh = qm
		var m := _glow_mat(Color(color.lightened(0.25), 0.95))
		m.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		mi.material_override = m
		root.add_child(mi)
		mi.global_position = pos
		if cam:
			mi.look_at(cam.global_position, Vector3.UP)
			mi.rotate_object_local(Vector3.UP, PI)
		mi.rotate_object_local(Vector3.FORWARD, deg_to_rad(45 if k == 0 else -45))
		mi.scale = Vector3(0.1, 1, 1)
		var tw := mi.create_tween()
		tw.tween_interval(0.06 * k)
		tw.tween_property(mi, "scale", Vector3(1, 1, 1), 0.08)
		tw.tween_property(m, "albedo_color:a", 0.0, 0.25)
		tw.tween_callback(mi.queue_free)


## Level-up celebration: golden beam, magic circle, spiralling sparkles and a
## glow that follows the character for a moment.
static func level_up(node: Node3D) -> void:
	if node == null or not node.is_inside_tree():
		return
	var gold := Color(1.0, 0.85, 0.35)
	var pos := node.global_position
	# angel wings + halo + light rays (Ragnarok style)
	preload("res://scripts/combat/level_up_fx.gd").spawn(node)
	pillar(node, pos, gold, 0.9, 10.0, 0.9)
	magic_circle(node, gold, 1.8, 1.4)
	flash(node, pos + Vector3(0, 1.0, 0), Color(1.0, 0.95, 0.7), 1.6)
	ring(node, pos, Color(1.0, 0.9, 0.5, 0.9), 3.0)
	node.get_tree().create_timer(0.18).timeout.connect(func() -> void: ring(node, node.global_position, Color(1.0, 0.95, 0.7, 0.8), 2.0))
	# spiral of sparkles rising around the character (follows it)
	var p := CPUParticles3D.new()
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * 0.07
	var m := _glow_mat(gold)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bm.material = m
	p.mesh = bm
	p.amount = 22 if Settings.is_mobile() else 42
	p.lifetime = 1.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.75
	p.emission_ring_inner_radius = 0.55
	p.emission_ring_height = 0.1
	p.direction = Vector3.UP
	p.spread = 8.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.0
	p.tangential_accel_min = 3.0
	p.tangential_accel_max = 5.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 0.85, 1.0))
	g.set_color(1, Color(gold, 0.0))
	p.color_ramp = g
	node.add_child(p)
	p.position = Vector3(0, 0.1, 0)
	p.emitting = true
	# warm light on the character
	var light := OmniLight3D.new()
	light.light_color = gold
	light.light_energy = 2.5
	light.omni_range = 4.0
	light.position = Vector3(0, 1.2, 0)
	node.add_child(light)
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 1.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		p.emitting = false
		light.queue_free())
	node.get_tree().create_timer(3.0).timeout.connect(p.queue_free)
