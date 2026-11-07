extends RefCounted
## Element-specific skill visuals: a glyph magic circle per element plus a
## clear, recognisable impact for fire, water, wind, earth, lightning and ice
## (holy / shadow get their own circle too).

const COLORS := {
	"fire": Color(1.0, 0.45, 0.12), "water": Color(0.25, 0.6, 1.0), "wind": Color(0.55, 1.0, 0.72),
	"earth": Color(0.86, 0.62, 0.3), "lightning": Color(1.0, 0.93, 0.4), "ice": Color(0.6, 0.9, 1.0),
	"holy": Color(1.0, 0.93, 0.62), "shadow": Color(0.72, 0.42, 1.0), "physical": Color(1.0, 0.85, 0.55)}
const ELEMENTS := ["fire", "water", "wind", "earth", "lightning", "ice", "holy", "shadow"]

static var _circle_cache := {}
static var _soft_tex: Texture2D


static func color(el: String) -> Color:
	return COLORS.get(el, COLORS.physical)


static func _root(from: Node) -> Node:
	var r := from.get_tree().current_scene
	return r if r else from.get_tree().root


static func _mat(c: Color, additive := true, tex: Texture2D = null, billboard := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = c
	if tex:
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if billboard:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.billboard_keep_scale = true
	m.vertex_color_use_as_albedo = true
	return m


static func _lit(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## Soft round sprite used for flames, mist, splashes and glows.
static func soft_texture() -> Texture2D:
	if _soft_tex:
		return _soft_tex
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x - n * 0.5 + 0.5, y - n * 0.5 + 0.5).length() / (n * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	img.generate_mipmaps()
	_soft_tex = ImageTexture.create_from_image(img)
	return _soft_tex


# ================================================================== magic circle textures
## A 256 px glyph circle, different geometry for every element.
static func circle_texture(el: String) -> Texture2D:
	if _circle_cache.has(el):
		return _circle_cache[el]
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(n, n) * 0.5
	var R := n * 0.48
	var plot := func(p: Vector2, a: float, w: float) -> void:
		var r := int(ceil(w))
		for yy in range(int(p.y) - r, int(p.y) + r + 1):
			for xx in range(int(p.x) - r, int(p.x) + r + 1):
				if xx < 0 or yy < 0 or xx >= n or yy >= n:
					continue
				var d := Vector2(xx + 0.5, yy + 0.5).distance_to(p)
				var k := clampf(w - d + 0.5, 0.0, 1.0) * a
				if k <= 0.0:
					continue
				var old := img.get_pixel(xx, yy)
				img.set_pixel(xx, yy, Color(1, 1, 1, maxf(old.a, k)))
	var line := func(a: Vector2, b: Vector2, alpha: float, w: float) -> void:
		var steps := int(a.distance_to(b)) + 1
		for i in steps + 1:
			plot.call(a.lerp(b, float(i) / float(steps)), alpha, w)
	var ring := func(r: float, alpha: float, w: float) -> void:
		var steps := int(TAU * r) + 8
		for i in steps:
			var t := TAU * float(i) / float(steps)
			plot.call(c + Vector2(cos(t), sin(t)) * r, alpha, w)
	var poly := func(k: int, r: float, rot: float, skip: int, alpha: float, w: float) -> void:
		for i in k:
			var a0 := rot + TAU * float(i) / float(k)
			var a1 := rot + TAU * float((i + skip) % k) / float(k)
			line.call(c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r, alpha, w)
	# shared frame: double outer ring with rune ticks
	ring.call(R, 1.0, 2.2)
	ring.call(R * 0.88, 0.9, 1.4)
	for i in 36:
		var t := TAU * float(i) / 36.0
		var l := 0.04 if i % 3 else 0.075
		line.call(c + Vector2(cos(t), sin(t)) * R * 0.885, c + Vector2(cos(t), sin(t)) * R * (0.885 + l), 0.85, 1.0)
	match el:
		"fire":     # two triangles (hexagram) + flame petals
			poly.call(3, R * 0.84, -PI * 0.5, 1, 1.0, 1.8)
			poly.call(3, R * 0.84, PI * 0.5, 1, 1.0, 1.8)
			ring.call(R * 0.42, 0.9, 1.6)
			for i in 6:
				var t := TAU * i / 6.0 - PI * 0.5
				var tip := c + Vector2(cos(t), sin(t)) * R * 0.62
				line.call(c + Vector2(cos(t - 0.25), sin(t - 0.25)) * R * 0.43, tip, 0.9, 1.3)
				line.call(c + Vector2(cos(t + 0.25), sin(t + 0.25)) * R * 0.43, tip, 0.9, 1.3)
		"water":    # concentric waves + three drop shapes
			ring.call(R * 0.7, 0.9, 1.4)
			ring.call(R * 0.56, 0.7, 1.0)
			for k in 3:
				var steps := 140
				for i in steps:
					var t := TAU * i / float(steps)
					var r := R * (0.3 + 0.08 * k) + sin(t * 8.0 + k) * R * 0.035
					plot.call(c + Vector2(cos(t), sin(t)) * r, 0.85, 1.2)
			for i in 3:
				var t := TAU * i / 3.0 - PI * 0.5
				var dc := c + Vector2(cos(t), sin(t)) * R * 0.63
				for j in 40:
					var a := TAU * j / 40.0
					plot.call(dc + Vector2(cos(a), sin(a)) * R * 0.07, 0.9, 1.1)
		"wind":     # spiral arms
			ring.call(R * 0.2, 0.9, 1.4)
			for arm in 4:
				var steps := 160
				for i in steps:
					var k := float(i) / float(steps)
					var t := TAU * arm / 4.0 + k * PI * 1.4
					var r := R * (0.2 + 0.64 * k)
					plot.call(c + Vector2(cos(t), sin(t)) * r, 0.95 * (1.0 - k * 0.3), 1.6 - k * 0.6)
		"earth":    # nested squares + mountain glyph
			poly.call(4, R * 0.82, PI * 0.25, 1, 1.0, 1.8)
			poly.call(4, R * 0.82, 0.0, 1, 0.85, 1.4)
			poly.call(4, R * 0.5, PI * 0.25, 1, 0.9, 1.4)
			line.call(c + Vector2(-R * 0.25, R * 0.12), c + Vector2(0, -R * 0.2), 1.0, 1.8)
			line.call(c + Vector2(0, -R * 0.2), c + Vector2(R * 0.25, R * 0.12), 1.0, 1.8)
			line.call(c + Vector2(-R * 0.3, R * 0.12), c + Vector2(R * 0.3, R * 0.12), 1.0, 1.8)
		"lightning":  # eight-point star with zig-zag spokes
			poly.call(8, R * 0.84, 0.0, 3, 0.9, 1.4)
			for i in 4:
				var t := TAU * i / 4.0 + PI * 0.25
				var dir := Vector2(cos(t), sin(t))
				var nrm := Vector2(-dir.y, dir.x)
				var pts := [c + dir * R * 0.12, c + dir * R * 0.3 + nrm * R * 0.06, c + dir * R * 0.36 - nrm * R * 0.06, c + dir * R * 0.56]
				for j in 3:
					line.call(pts[j], pts[j + 1], 1.0, 1.7)
			ring.call(R * 0.12, 0.9, 1.4)
		"ice":      # snowflake
			ring.call(R * 0.66, 0.8, 1.2)
			for i in 6:
				var t := TAU * i / 6.0
				var dir := Vector2(cos(t), sin(t))
				line.call(c, c + dir * R * 0.8, 1.0, 1.6)
				for b in [0.35, 0.55]:
					var base: Vector2 = c + dir * R * b
					for sgn in [-1.0, 1.0]:
						var bd := dir.rotated(sgn * 0.75)
						line.call(base, base + bd * R * 0.14, 0.95, 1.2)
			poly.call(6, R * 0.3, 0.0, 1, 0.9, 1.3)
		"holy":     # cross + rays
			line.call(c + Vector2(0, -R * 0.75), c + Vector2(0, R * 0.75), 1.0, 2.0)
			line.call(c + Vector2(-R * 0.5, -R * 0.15), c + Vector2(R * 0.5, -R * 0.15), 1.0, 2.0)
			for i in 12:
				var t := TAU * i / 12.0
				line.call(c + Vector2(cos(t), sin(t)) * R * 0.6, c + Vector2(cos(t), sin(t)) * R * 0.78, 0.8, 1.1)
			ring.call(R * 0.3, 0.9, 1.4)
		_:          # shadow / generic: pentagram
			poly.call(5, R * 0.82, -PI * 0.5, 2, 1.0, 1.6)
			ring.call(R * 0.32, 0.9, 1.3)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_circle_cache[el] = tex
	return tex


# ================================================================== magic circle
## Flat glyph circle on the ground; follows `node` when `follow` is true.
static func circle(from: Node, el: String, pos: Vector3, radius := 1.6, time := 1.0, follow: Node3D = null) -> void:
	if from == null or not from.is_inside_tree():
		return
	if from.get_tree().get_nodes_in_group("readable_circles").size() >= (6 if Settings.is_mobile() else 16): return
	var holder := Node3D.new()
	holder.add_to_group("readable_circles")
	_root(from).add_child(holder)
	holder.global_position = pos + Vector3(0, 0.06, 0)
	var c := color(el)
	var tex := circle_texture(el)
	var mats: Array[StandardMaterial3D] = []
	for k in 2:
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2.ONE * radius * (2.0 if k == 0 else 1.15)
		mi.mesh = pm
		var m := _mat(Color(c.lerp(Color.WHITE, 0.1 * k), 0.0), false, tex)
		m.render_priority = 1
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.4
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		mi.position.y = 0.01 * k
		mats.append(m)
	# glow disc under the glyphs
	var glow := MeshInstance3D.new()
	var gm := PlaneMesh.new()
	gm.size = Vector2.ONE * radius * 2.3
	glow.mesh = gm
	var glow_m := _mat(Color(c, 0.0), true, soft_texture())
	glow.material_override = glow_m
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(glow)
	glow.position.y = -0.01
	var light := OmniLight3D.new()
	light.visible = not Settings.is_mobile()
	light.shadow_enabled = false
	light.light_color = c
	light.light_energy = 0.0
	light.omni_range = radius * 2.2
	light.position = Vector3(0, 0.6, 0)
	holder.add_child(light)
	var tw := holder.create_tween()
	tw.set_parallel(true)
	holder.scale = Vector3.ONE * 0.3
	tw.tween_property(holder, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(mats[0], "albedo_color:a", 0.7, 0.15)
	tw.tween_property(mats[1], "albedo_color:a", 0.55, 0.2)
	tw.tween_property(glow_m, "albedo_color:a", 0.24, 0.2)
	tw.tween_property(light, "light_energy", 0.8, 0.2)
	tw.tween_property(holder.get_child(0), "rotation:y", PI * 0.8 * time, time)
	tw.tween_property(holder.get_child(1), "rotation:y", -PI * 1.4 * time, time)
	var fade := minf(0.35, time * 0.4)
	for m in mats:
		tw.tween_property(m, "albedo_color:a", 0.0, fade).set_delay(time - fade)
	tw.tween_property(glow_m, "albedo_color:a", 0.0, fade).set_delay(time - fade)
	tw.tween_property(light, "light_energy", 0.0, fade).set_delay(time - fade)
	tw.chain().tween_callback(holder.queue_free)
	if follow:
		var tick := func() -> void:
			if is_instance_valid(holder) and is_instance_valid(follow):
				holder.global_position = follow.global_position + Vector3(0, 0.06, 0)
		var ft := holder.create_tween()
		ft.tween_method(func(_v: float) -> void: tick.call(), 0.0, 1.0, time)


# ================================================================== particles helper
static func _particles(parent: Node, at: Vector3, c0: Color, c1: Color, amount: int, life: float, size: float,
		vel: Vector2, spread: float, gravity: Vector3, box: Vector3, additive := true, one_shot := true, tangential := 0.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2.ONE * size * (0.7 if Settings.is_mobile() else 0.85)
	q.material = _mat(Color.WHITE, additive, soft_texture(), true)
	p.mesh = q
	p.amount = particle_count(amount)
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 0.85 if one_shot else 0.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = box
	p.direction = Vector3.UP
	p.spread = spread
	p.gravity = gravity
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	if tangential != 0.0:
		p.tangential_accel_min = tangential * 0.7
		p.tangential_accel_max = tangential
	var g := Gradient.new()
	var readable := c0
	readable.a *= 0.55 if Settings.is_mobile() else 0.75
	g.set_color(0, readable)
	g.set_color(1, c1)
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	return p


static func _holder(from: Node, pos: Vector3, life: float) -> Node3D:
	var h := Node3D.new()
	h.add_to_group("readable_impacts")
	_root(from).add_child(h)
	h.global_position = pos
	from.get_tree().create_timer(life).timeout.connect(func() -> void:
		if is_instance_valid(h):
			h.queue_free())
	return h


static func _flash_light(h: Node3D, c: Color, energy: float, rng: float, time: float, y := 1.0) -> void:
	if Settings.is_mobile(): return
	var l := OmniLight3D.new()
	l.shadow_enabled = false
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng
	l.position = Vector3(0, y, 0)
	h.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, time)


# ================================================================== impacts
static func impact(from: Node, el: String, pos: Vector3, radius := 1.0) -> void:
	if from == null or not from.is_inside_tree():
		return
	if from.get_tree().get_nodes_in_group("readable_impacts").size() >= (8 if Settings.is_mobile() else 24): return
	radius = maxf(0.8, radius)
	match el:
		"fire": _fire(from, pos, radius)
		"water": _water(from, pos, radius)
		"wind": _wind(from, pos, radius)
		"earth": _earth(from, pos, radius)
		"lightning": _lightning(from, pos, radius)
		"ice": _ice(from, pos, radius)
		_: return


static func _fire(from: Node, pos: Vector3, radius: float) -> void:
	var h := _holder(from, pos, 2.6)
	# roaring flames (yellow core -> orange -> red, then dark smoke)
	_particles(h, pos + Vector3(0, 0.3, 0), Color(1.0, 0.62, 0.12, 0.95), Color(0.75, 0.08, 0.02, 0.0), 40 + int(radius * 12), 0.75, 0.8,
		Vector2(1.6, 3.4), 22.0, Vector3(0, 2.0, 0), Vector3(radius * 0.55, 0.15, radius * 0.55), false)
	_particles(h, pos + Vector3(0, 0.25, 0), Color(1.0, 0.9, 0.45, 0.9), Color(1.0, 0.4, 0.05, 0.0), 20 + int(radius * 6), 0.5, 0.55,
		Vector2(1.2, 2.6), 18.0, Vector3(0, 1.5, 0), Vector3(radius * 0.4, 0.1, radius * 0.4))
	_particles(h, pos + Vector3(0, 0.9, 0), Color(0.25, 0.2, 0.18, 0.55), Color(0.1, 0.1, 0.1, 0.0), 14, 1.4, 1.1,
		Vector2(0.6, 1.4), 30.0, Vector3(0, 0.8, 0), Vector3(radius * 0.4, 0.2, radius * 0.4), false)
	# embers
	_particles(h, pos + Vector3(0, 0.4, 0), Color(1.0, 0.75, 0.3, 1.0), Color(1.0, 0.3, 0.05, 0.0), 24, 1.1, 0.12,
		Vector2(2.5, 5.0), 55.0, Vector3(0, -3.0, 0), Vector3(radius * 0.3, 0.1, radius * 0.3))
	# flame tongues
	for i in (3 if Settings.is_mobile() else 5) + int(radius):
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.22
		cm.height = 1.0
		cm.radial_segments = 6
		cone.mesh = cm
		var m := _mat(Color(1.0, 0.38 + randf() * 0.3, 0.06, 0.9), false)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.4, 0.05)
		m.emission_energy_multiplier = 1.5
		cone.material_override = m
		cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		h.add_child(cone)
		var off := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * 0.7
		cone.position = off + Vector3(0, 0.0, 0)
		cone.scale = Vector3(1, 0.05, 1)
		var tall := randf_range(1.2, 2.2) * (0.8 + radius * 0.15)
		var tw := cone.create_tween()
		tw.tween_interval(randf() * 0.15)
		tw.tween_property(cone, "scale", Vector3(1, tall, 1), 0.18).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(cone, "position:y", tall * 0.5, 0.18)
		tw.tween_property(m, "albedo_color:a", 0.0, 0.35)
		tw.parallel().tween_property(cone, "scale", Vector3(0.3, tall * 1.3, 0.3), 0.35)
	_flash_light(h, Color(1.0, 0.5, 0.15), 4.0, 5.0 + radius, 0.8)


static func _water(from: Node, pos: Vector3, radius: float) -> void:
	var h := _holder(from, pos, 2.4)
	var blue := Color(0.3, 0.65, 1.0)
	# geyser column
	var col := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35 * radius
	cm.bottom_radius = 0.5 * radius
	cm.height = 1.0
	cm.radial_segments = 14
	col.mesh = cm
	var m := _mat(Color(0.2, 0.5, 0.95, 0.62), false)
	m.emission_enabled = true
	m.emission = Color(0.15, 0.4, 0.9)
	m.emission_energy_multiplier = 0.6
	m.rim_enabled = true
	col.material_override = m
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	h.add_child(col)
	col.scale = Vector3(1, 0.05, 1)
	var tw := col.create_tween()
	tw.tween_property(col, "scale", Vector3(1, 2.6 + radius * 0.4, 1), 0.22).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(col, "position:y", (2.6 + radius * 0.4) * 0.5, 0.22).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.45)
	tw.parallel().tween_property(col, "scale", Vector3(0.4, 3.4 + radius * 0.4, 0.4), 0.45)
	# splash droplets falling back
	_particles(h, pos + Vector3(0, 1.6, 0), Color(0.35, 0.65, 1.0, 0.95), Color(0.2, 0.45, 0.95, 0.0), 46 + int(radius * 10), 1.1, 0.22,
		Vector2(2.5, 5.0), 60.0, Vector3(0, -9.0, 0), Vector3(radius * 0.3, 0.3, radius * 0.3), false)
	# foam / mist
	_particles(h, pos + Vector3(0, 0.2, 0), Color(0.9, 0.97, 1.0, 0.5), Color(0.6, 0.85, 1.0, 0.0), 18, 0.9, 0.9,
		Vector2(0.6, 1.6), 80.0, Vector3(0, 0.3, 0), Vector3(radius * 0.6, 0.05, radius * 0.6), false)
	# ripples
	for k in 3:
		var ring := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.9
		t.outer_radius = 1.0
		t.rings = 32
		t.ring_segments = 4
		ring.mesh = t
		var rm := _mat(Color(0.3, 0.62, 1.0, 0.8), false)
		ring.material_override = rm
		h.add_child(ring)
		ring.position.y = 0.05
		ring.scale = Vector3(0.2, 0.06, 0.2)
		var rt := ring.create_tween()
		rt.tween_interval(k * 0.15)
		rt.tween_property(ring, "scale", Vector3(1.0, 0.06, 1.0) * radius * 1.4, 0.7).set_ease(Tween.EASE_OUT)
		rt.parallel().tween_property(rm, "albedo_color:a", 0.0, 0.7)
	_flash_light(h, blue, 2.5, 4.0 + radius, 0.7)


static func _wind(from: Node, pos: Vector3, radius: float) -> void:
	var h := _holder(from, pos, 2.2)
	var green := Color(0.6, 1.0, 0.75)
	# tornado: stacked spinning arcs that widen with height
	var spin := Node3D.new()
	h.add_child(spin)
	var mats: Array[StandardMaterial3D] = []
	for k in 9:
		var arc := MeshInstance3D.new()
		var r := (0.3 + k * 0.13) * (0.6 + radius * 0.35)
		arc.mesh = FX.arc_mesh(r, k * 47.0, k * 47.0 + 280.0, 0.16 + k * 0.015)
		var m := _mat(Color(0.35, 0.9, 0.55, 0.8), false)
		m.emission_enabled = true
		m.emission = Color(0.3, 0.9, 0.5)
		m.emission_energy_multiplier = 0.8
		arc.material_override = m
		arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arc.position.y = 0.15 + k * 0.3
		spin.add_child(arc)
		mats.append(m)
	spin.scale = Vector3(0.3, 0.2, 0.3)
	var tw := spin.create_tween()
	tw.set_parallel(true)
	tw.tween_property(spin, "scale", Vector3.ONE, 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(spin, "rotation:y", TAU * 3.0, 1.3)
	for m in mats:
		tw.tween_property(m, "albedo_color:a", 0.0, 0.4).set_delay(0.9)
	# streaks and leaves swirling up
	_particles(h, pos + Vector3(0, 0.3, 0), Color(0.55, 1.0, 0.7, 0.9), Color(0.3, 0.85, 0.5, 0.0), 40, 1.0, 0.16,
		Vector2(2.0, 3.5), 15.0, Vector3.ZERO, Vector3(radius * 0.5, 0.2, radius * 0.5), false, true, 9.0)
	_particles(h, pos + Vector3(0, 0.4, 0), Color(0.45, 0.8, 0.3, 1.0), Color(0.35, 0.65, 0.2, 0.0), 14, 1.2, 0.14,
		Vector2(2.5, 4.0), 25.0, Vector3(0, -1.0, 0), Vector3(radius * 0.4, 0.2, radius * 0.4), false, true, 8.0)
	# ground gust ring
	FX.ring(from, pos, Color(0.75, 1.0, 0.85, 0.7), radius * 1.4)


static func _earth(from: Node, pos: Vector3, radius: float) -> void:
	var h := _holder(from, pos, 2.6)
	var count := 7 + int(radius * 3)
	for i in count:
		var rock := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.02
		cm.bottom_radius = randf_range(0.22, 0.36)
		cm.height = 1.0
		cm.radial_segments = 4 + randi() % 2
		rock.mesh = cm
		var shade := randf_range(0.0, 0.18)
		var m := _lit(Color(0.62 - shade, 0.5 - shade, 0.36 - shade))
		rock.material_override = m
		h.add_child(rock)
		var ang := TAU * float(i) / float(count) + randf() * 0.3
		var dist := radius * (0.35 + randf() * 0.65)
		rock.position = Vector3(cos(ang) * dist, -0.6, sin(ang) * dist)
		rock.rotation = Vector3(randf_range(-0.35, 0.35), randf() * TAU, randf_range(-0.35, 0.35))
		var tall := randf_range(0.8, 1.6) * (0.8 + radius * 0.15)
		rock.scale = Vector3(1, tall, 1)
		var tw := rock.create_tween()
		tw.tween_interval(i * 0.025)
		tw.tween_property(rock, "position:y", tall * 0.45, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.6)
		tw.tween_property(rock, "position:y", -tall, 0.45).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.45)
	# dust cloud and debris
	_particles(h, pos + Vector3(0, 0.2, 0), Color(0.72, 0.6, 0.42, 0.65), Color(0.55, 0.47, 0.35, 0.0), 26, 1.3, 1.0,
		Vector2(0.8, 2.0), 80.0, Vector3(0, 0.2, 0), Vector3(radius * 0.6, 0.1, radius * 0.6), false)
	_particles(h, pos + Vector3(0, 0.3, 0), Color(0.5, 0.42, 0.3, 1.0), Color(0.45, 0.38, 0.28, 0.0), 22, 1.0, 0.16,
		Vector2(3.0, 6.0), 40.0, Vector3(0, -12.0, 0), Vector3(radius * 0.4, 0.1, radius * 0.4), false)
	# crack ring
	FX.ring(from, pos, Color(0.45, 0.32, 0.18, 0.9), radius * 1.3)
	var cam := from.get_tree().get_first_node_in_group("camera_rig")
	if cam and cam.has_method("shake"):
		cam.shake(0.35)


static func _bolt_mesh(a: Vector3, b: Vector3, width: float, jag: float) -> ArrayMesh:
	# jagged ribbon from a to b, flattened toward the camera by billboarding the quads in y
	var pts := [a]
	var n := 9
	for i in range(1, n):
		var k := float(i) / float(n)
		var p := a.lerp(b, k)
		p += Vector3(randf_range(-jag, jag), 0, randf_range(-jag, jag)) * sin(k * PI)
		pts.append(p)
	pts.append(b)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size() - 1:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[i + 1]
		for side in [Vector3(width, 0, 0), Vector3(0, 0, width)]:
			st.add_vertex(p0 - side)
			st.add_vertex(p0 + side)
			st.add_vertex(p1 + side)
			st.add_vertex(p0 - side)
			st.add_vertex(p1 + side)
			st.add_vertex(p1 - side)
	return st.commit()


static func _lightning(from: Node, pos: Vector3, radius: float) -> void:
	var h := _holder(from, pos, 1.6)
	var strikes := 1 + int(radius * 0.8)
	for s in strikes:
		var off := Vector3.ZERO if s == 0 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).limit_length(1.0) * radius * 0.8
		var top := off + Vector3(randf_range(-0.6, 0.6), 9.0, randf_range(-0.6, 0.6))
		for layer in 2:
			var mi := MeshInstance3D.new()
			mi.mesh = _bolt_mesh(top, off, 0.05 if layer == 0 else 0.16, 0.7)
			var m := _mat(Color(1, 1, 0.92, 1.0) if layer == 0 else Color(1.0, 0.9, 0.35, 0.45))
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			h.add_child(mi)
			var tw := mi.create_tween()
			mi.visible = false
			tw.tween_interval(s * 0.07)
			tw.tween_callback(func() -> void: mi.visible = true)
			# flicker
			for f in 3:
				tw.tween_property(m, "albedo_color:a", 0.15, 0.04)
				tw.tween_property(m, "albedo_color:a", 1.0 if layer == 0 else 0.45, 0.03)
			tw.tween_property(m, "albedo_color:a", 0.0, 0.18)
		_particles(h, pos + off + Vector3(0, 0.15, 0), Color(1, 1, 0.8, 1.0), Color(1.0, 0.85, 0.3, 0.0), 18, 0.45, 0.12,
			Vector2(3.0, 6.0), 75.0, Vector3(0, -6.0, 0), Vector3(0.1, 0.05, 0.1))
	FX.flash(from, pos + Vector3(0, 0.4, 0), Color(1.0, 0.95, 0.55), 1.2 + radius * 0.3)
	_flash_light(h, Color(0.85, 0.9, 1.0), 6.0, 7.0 + radius, 0.35, 3.0)


static func _ice(from: Node, pos: Vector3, radius: float) -> void:
	var h := _holder(from, pos, 2.6)
	var count := mini(6 if Settings.is_mobile() else 12, 4 + int(radius * 2))
	for i in count:
		var spike := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = randf_range(0.16, 0.28)
		cm.height = 1.0
		cm.radial_segments = 6
		spike.mesh = cm
		spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.72, 0.92, 1.0, 0.82)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.metallic = 0.2
		m.roughness = 0.05
		m.emission_enabled = true
		m.emission = Color(0.35, 0.7, 1.0)
		m.emission_energy_multiplier = 0.6
		m.rim_enabled = true
		spike.material_override = m
		h.add_child(spike)
		var ang := TAU * float(i) / float(count) + randf() * 0.25
		var dist := radius * (0.58 + randf() * 0.4)
		var out := Vector3(cos(ang), 0, sin(ang))
		spike.position = out * dist
		# crystals lean outward like a frozen bloom
		spike.basis = Basis(out.cross(Vector3.UP).normalized(), -randf_range(0.2, 0.6)) if dist > 0.1 else Basis()
		var tall := randf_range(0.65, 1.25) * (0.8 + radius * 0.12)
		spike.scale = Vector3(1, 0.05, 1)
		var tw := spike.create_tween()
		tw.tween_interval(i * 0.02)
		tw.tween_property(spike, "scale", Vector3(1, tall, 1), 0.14).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(spike, "position:y", tall * 0.42, 0.14).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.7)
		tw.tween_property(m, "albedo_color:a", 0.0, 0.3)
		tw.parallel().tween_property(spike, "scale", Vector3(0.2, tall * 0.4, 0.2), 0.3)
	# frost mist + snow sparkles + shards when it shatters
	_particles(h, pos + Vector3(0, 0.3, 0), Color(0.92, 0.98, 1.0, 0.6), Color(0.7, 0.9, 1.0, 0.0), 22, 1.4, 1.0,
		Vector2(0.4, 1.2), 85.0, Vector3(0, 0.1, 0), Vector3(radius * 0.6, 0.1, radius * 0.6), false)
	_particles(h, pos + Vector3(0, 1.0, 0), Color(1, 1, 1, 1.0), Color(0.6, 0.85, 1.0, 0.0), 30, 1.2, 0.09,
		Vector2(0.5, 2.0), 180.0, Vector3(0, -1.5, 0), Vector3(radius * 0.6, 0.6, radius * 0.6))
	from.get_tree().create_timer(0.95).timeout.connect(func() -> void:
		if is_instance_valid(h):
			_particles(h, pos + Vector3(0, 0.6, 0), Color(0.85, 0.95, 1.0, 1.0), Color(0.5, 0.8, 1.0, 0.0), 26, 0.7, 0.12,
				Vector2(2.0, 4.5), 70.0, Vector3(0, -9.0, 0), Vector3(radius * 0.5, 0.3, radius * 0.5)))
	_flash_light(h, Color(0.6, 0.85, 1.0), 2.5, 4.5 + radius, 0.9)

static func particle_count(amount: int) -> int:
	return clampi(int(ceil(amount * (0.35 if Settings.is_mobile() else 0.65))), 1, 18 if Settings.is_mobile() else 40)
