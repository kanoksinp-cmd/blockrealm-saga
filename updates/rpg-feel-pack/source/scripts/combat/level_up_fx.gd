extends Node3D
## Ragnarok-style level-up: a pair of feathered angel wings opens behind the
## hero, flaps a few times under a golden halo and light rays, then rises and
## fades while loose feathers drift down.

const LIFE := 3.2
const GOLD := Color(1.0, 0.86, 0.42)

static var _feather_tex: Texture2D
static var _ray_tex: Texture2D

var target: Node3D
var _t := 0.0
var _wings: Array[Node3D] = []
var _halo: MeshInstance3D
var _rays: Node3D
var _mats: Array[StandardMaterial3D] = []
var _base_alpha: Array[float] = []


static func spawn(node: Node3D) -> void:
	if node == null or not node.is_inside_tree():
		return
	var fx := new()
	fx.target = node
	var root := node.get_tree().current_scene
	if root == null:
		root = node.get_tree().root
	root.add_child(fx)
	fx.global_position = node.global_position


# ------------------------------------------------------------------ textures
static func feather_texture() -> Texture2D:
	if _feather_tex:
		return _feather_tex
	var w := 32
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var v := float(y) / float(h - 1)              # 0 = tip, 1 = quill
		# feather outline: rounded tip, widest at 35%, narrow at the quill
		var half := 0.5 * (sin(clampf(v * 1.15, 0.0, 1.0) * PI) * 0.75 + 0.25) * (1.0 - v * 0.55)
		if v > 0.88:
			half = 0.05
		for x in w:
			var u := (float(x) + 0.5) / float(w) - 0.5
			var d := absf(u) / maxf(0.01, half)
			var a := clampf((1.0 - d) * 4.0, 0.0, 1.0)
			# barbs: faint diagonal stripes
			var barb := 0.88 + 0.12 * sin((v * 70.0 + absf(u) * 40.0))
			var shaft := 1.0 - smoothstep(0.0, 0.035, absf(u))
			var c := Color(1.0, 0.99, 0.96).lerp(Color(1.0, 0.9, 0.62), v * 0.55) * barb
			# warm gold rim so every feather reads on bright ground
			c = c.lerp(Color(0.86, 0.62, 0.26), smoothstep(0.62, 0.98, d) * 0.85)
			c = c.lerp(Color(0.95, 0.72, 0.32), shaft * 0.7)
			c.a = a * (0.9 if v < 0.88 else 1.0)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	_feather_tex = ImageTexture.create_from_image(img)
	return _feather_tex


static func ray_texture() -> Texture2D:
	if _ray_tex:
		return _ray_tex
	var img := Image.create(16, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 16:
			var u := absf((float(x) + 0.5) / 16.0 - 0.5) * 2.0
			var v := float(y) / 63.0
			var a := (1.0 - u * u) * sin(v * PI) * 0.9
			img.set_pixel(x, y, Color(1, 0.95, 0.75, a))
	_ray_tex = ImageTexture.create_from_image(img)
	return _ray_tex


func _mat(tex: Texture2D, color: Color, additive := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = tex
	m.albedo_color = color
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.no_depth_test = false
	m.render_priority = 2
	_mats.append(m)
	_base_alpha.append(color.a)
	return m


# ------------------------------------------------------------------ build
func _ready() -> void:
	var tex := feather_texture()
	var body := _mat(tex, Color(1, 1, 1, 0.97))
	var glow := _mat(tex, Color(1.0, 0.85, 0.45, 0.22), true)
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.14, 1.3, 0)
		add_child(wing)
		_wings.append(wing)
		# three tiers: long primaries, secondaries, short coverts
		# [count, length, width, first angle, last angle, depth] - classic arched angel wing
		var tiers := [[9, 1.55, 0.26, 22.0, 100.0, 0.0], [7, 1.0, 0.25, 30.0, 92.0, 0.02], [6, 0.55, 0.24, 38.0, 84.0, 0.04]]
		for tier in tiers:
			var n: int = tier[0]
			for i in n:
				var k := float(i) / float(n - 1)
				var feather := MeshInstance3D.new()
				var q := QuadMesh.new()
				var length: float = tier[1] * (0.82 + 0.25 * sin(k * PI * 0.9))
				q.size = Vector2(tier[2], length)
				q.center_offset = Vector3(0, length * 0.5, 0)
				feather.mesh = q
				feather.material_override = body
				feather.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				# fan from almost straight up to sideways-down
				var ang: float = deg_to_rad(lerpf(tier[3], tier[4], k))
				feather.rotation = Vector3(0, 0, -side * ang)
				# feathers root along an arm bone that arches up and out
				var arm := Vector2(0.18 + k * 0.62, 0.28 * sin(k * PI * 0.8) - k * 0.1)
				feather.position = Vector3(side * arm.x, arm.y, float(tier[5]))
				wing.add_child(feather)
				var halo := MeshInstance3D.new()
				var gq := QuadMesh.new()
				gq.size = q.size * 1.25
				gq.center_offset = Vector3(0, length * 0.55, 0)
				halo.mesh = gq
				halo.material_override = glow
				halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				halo.position = Vector3(0, 0, -0.01)
				feather.add_child(halo)
	# halo over the head
	_halo = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.24
	tm.outer_radius = 0.3
	tm.rings = 32
	tm.ring_segments = 6
	_halo.mesh = tm
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.albedo_color = Color(1.0, 0.88, 0.45, 0.95)
	_halo.material_override = hm
	_mats.append(hm)
	_base_alpha.append(0.95)
	_halo.position = Vector3(0, 2.35, 0)
	add_child(_halo)
	# light rays fanning out behind the hero
	_rays = Node3D.new()
	_rays.position = Vector3(0, 1.3, -0.15)
	add_child(_rays)
	var rm := _mat(ray_texture(), Color(1.0, 0.9, 0.55, 0.32), true)
	for i in 10:
		var r := MeshInstance3D.new()
		var rq := QuadMesh.new()
		rq.size = Vector2(0.45, 3.4)
		rq.center_offset = Vector3(0, 1.7, 0)
		r.mesh = rq
		r.material_override = rm
		r.rotation.z = TAU * float(i) / 10.0
		r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_rays.add_child(r)
	# feathers drifting down
	var p := CPUParticles3D.new()
	var pq := QuadMesh.new()
	pq.size = Vector2(0.07, 0.22)
	pq.material = _mat(tex, Color(1, 1, 1, 0.95))
	(pq.material as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	p.mesh = pq
	p.amount = 26
	p.lifetime = 2.2
	p.one_shot = false
	p.explosiveness = 0.15
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.3, 0.3, 0.4)
	p.position = Vector3(0, 2.0, 0)
	p.direction = Vector3(0, -1, 0)
	p.spread = 40.0
	p.gravity = Vector3(0, -0.6, 0)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.angular_velocity_min = -160.0
	p.angular_velocity_max = 160.0
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.15, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	add_child(p)
	get_tree().create_timer(1.8).timeout.connect(func() -> void:
		if is_instance_valid(p):
			p.emitting = false)
	_apply(0.0)


# ------------------------------------------------------------------ animate
func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE or target == null or not is_instance_valid(target):
		queue_free()
		return
	_apply(delta)


func _apply(_delta: float) -> void:
	if target and is_instance_valid(target):
		global_position = target.global_position + Vector3(0, minf(1.0, maxf(0.0, _t - 2.2) / 1.0) * 0.8, 0)
	# face the camera (also its pitch) so the wings always read as wings
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam:
		var to := (cam.global_position - global_position).normalized()
		var flat := Vector3(to.x, 0.0, to.z)
		if flat.length() > 0.01:
			rotation.y = atan2(flat.x, flat.z)
			rotation.x = -atan2(to.y, flat.length()) * 0.75
	var open := ease(clampf(_t / 0.45, 0.0, 1.0), 0.35)
	var flap := sin(maxf(0.0, _t - 0.45) * 7.5) * 0.22 * clampf((_t - 0.45) * 2.0, 0.0, 1.0)
	for i in _wings.size():
		var w := _wings[i]
		var side := -1.0 if i == 0 else 1.0
		w.scale = Vector3.ONE * lerpf(0.2, 1.25, open)
		w.rotation = Vector3(0, side * (0.35 - flap), side * (0.9 * (1.0 - open) + flap * 0.6))
		# sit just behind the hero (relative to the camera)
		w.position.z = -0.25
	_halo.rotation.y = _t * 2.0
	_halo.scale = Vector3.ONE * (0.6 + 0.4 * open)
	_rays.rotation.z = _t * 0.35
	_rays.scale = Vector3.ONE * (0.4 + 0.6 * open)
	var fade := 1.0 - smoothstep(LIFE - 0.9, LIFE, _t)
	var rays_fade := (1.0 - smoothstep(1.4, 2.4, _t)) * clampf(_t / 0.3, 0.0, 1.0)
	for k in _mats.size():
		var m := _mats[k]
		var a := _base_alpha[k] * fade
		if m.blend_mode == BaseMaterial3D.BLEND_MODE_ADD and m.albedo_texture == _ray_tex:
			a = _base_alpha[k] * rays_fade
		m.albedo_color.a = a
