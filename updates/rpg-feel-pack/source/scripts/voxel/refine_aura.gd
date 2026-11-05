extends Node3D
## Whole-body aura for heavily refined gear.
##  +7 / +8 : warm light wraps the character (rising motes, glow ring, soft light)
##  +9 / +10: on top of that, crackling lightning arcs dance around the body

const LIGHT_AT := 7
const STORM_AT := 9
const HEIGHT := 1.95
const RADIUS := 0.5

var level := 0
var _t := 0.0
var _arc_t := 0.0
var _arcs: Array = []                # [mesh, life]
var _arc_mat: StandardMaterial3D
var _arc_glow: StandardMaterial3D
var _light: OmniLight3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _rng := RandomNumberGenerator.new()


static func attach(root: Node3D, lv: int) -> void:
	if lv < LIGHT_AT:
		return
	var old := root.get_node_or_null("RefineBodyAura")
	if old:
		old.free()
	var a: Node3D = load("res://scripts/voxel/refine_aura.gd").new()
	a.name = "RefineBodyAura"
	a.level = lv
	root.add_child(a)


func _soft() -> Texture2D:
	return preload("res://scripts/combat/element_fx.gd").soft_texture()


func _ready() -> void:
	_rng.randomize()
	var storm := level >= STORM_AT
	var tint := Color(1.0, 0.82, 0.4) if not storm else Color(0.65, 0.82, 1.0)
	# rising motes all around the body
	var p := CPUParticles3D.new()
	var q := QuadMesh.new()
	q.size = Vector2.ONE * 0.09
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pm.vertex_color_use_as_albedo = true
	pm.albedo_texture = _soft()
	q.material = pm
	p.mesh = q
	p.amount = 26 + (level - LIGHT_AT) * 8
	p.lifetime = 1.1
	p.preprocess = 1.1
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = RADIUS
	p.emission_ring_inner_radius = RADIUS * 0.7
	p.emission_ring_height = HEIGHT * 0.9
	p.position = Vector3(0, HEIGHT * 0.45, 0)
	p.direction = Vector3.UP
	p.spread = 6.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.1
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	var g := Gradient.new()
	g.set_color(0, Color(tint, 0.0))
	g.add_point(0.25, Color(tint.lightened(0.3), 0.9))
	g.set_color(1, Color(tint, 0.0))
	p.color_ramp = g
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	# vertical light veil (two crossed soft quads, billboarded on Y)
	for k in 2:
		var veil := MeshInstance3D.new()
		var vq := QuadMesh.new()
		vq.size = Vector2(RADIUS * 3.0, HEIGHT * 1.35)
		veil.mesh = vq
		var vm := StandardMaterial3D.new()
		vm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		vm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		vm.albedo_texture = _soft()
		vm.albedo_color = Color(tint, 0.3 if k == 0 else 0.16)
		vm.cull_mode = BaseMaterial3D.CULL_DISABLED
		veil.material_override = vm
		veil.position = Vector3(0, HEIGHT * 0.5, 0)
		veil.scale = Vector3.ONE * (1.0 if k == 0 else 1.35)
		veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(veil)
	# light shell over the whole body: an additive rim glow on every mesh
	_apply_shell(tint, storm)
	# pulsing ring at the feet
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = RADIUS * 1.15
	tm.outer_radius = RADIUS * 1.3
	tm.rings = 32
	tm.ring_segments = 4
	_ring.mesh = tm
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_mat.albedo_color = Color(tint, 0.5)
	_ring.material_override = _ring_mat
	_ring.scale = Vector3(1, 0.05, 1)
	_ring.position.y = 0.04
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_light = OmniLight3D.new()
	_light.light_color = tint
	_light.light_energy = 0.8
	_light.omni_range = 2.6
	_light.position = Vector3(0, 1.1, 0)
	_light.shadow_enabled = false
	add_child(_light)
	if storm:
		_arc_mat = StandardMaterial3D.new()
		_arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_arc_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_arc_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_arc_mat.albedo_color = Color(0.92, 0.97, 1.0, 1.0)
		_arc_glow = _arc_mat.duplicate()
		_arc_glow.albedo_color = Color(0.45, 0.65, 1.0, 0.55)


const SHELL := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, cull_back;
uniform vec4 col : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform float strength = 1.0;
uniform float flicker = 0.0;
void vertex() {
	VERTEX += NORMAL * 0.012;
}
void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float pulse = 0.78 + 0.22 * sin(TIME * 3.0);
	float f = 1.0 + flicker * step(0.82, fract(sin(floor(TIME * 18.0) * 12.9898) * 43758.5453)) * 1.6;
	ALBEDO = col.rgb * (rim * 1.25 + 0.05) * strength * pulse * f;
}
"""
static var _shell_shader: Shader


func _apply_shell(tint: Color, storm: bool) -> void:
	var host := get_parent()
	if host == null:
		return
	if _shell_shader == null:
		_shell_shader = Shader.new()
		_shell_shader.code = SHELL
	var m := ShaderMaterial.new()
	m.shader = _shell_shader
	m.set_shader_parameter("col", tint)
	m.set_shader_parameter("strength", 1.0 + (level - LIGHT_AT) * 0.15)
	m.set_shader_parameter("flicker", 1.0 if storm else 0.0)
	for n in host.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.is_ancestor_of(self) or self.is_ancestor_of(mi) or mi.material_overlay != null or not mi.visible or mi.has_meta("flowing_cloth"):
			continue
		mi.material_overlay = m


func _process(delta: float) -> void:
	_t += delta
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)
	_ring_mat.albedo_color.a = 0.25 + 0.35 * pulse
	_ring.scale = Vector3(1.0 + 0.08 * pulse, 0.05, 1.0 + 0.08 * pulse)
	_light.light_energy = 0.6 + 0.4 * pulse
	if _arc_mat == null:
		return
	# lightning: short jagged arcs that hug the body
	for i in range(_arcs.size() - 1, -1, -1):
		_arcs[i][1] -= delta
		if _arcs[i][1] <= 0.0:
			(_arcs[i][0] as Node).queue_free()
			_arcs.remove_at(i)
	_arc_t -= delta
	if _arc_t <= 0.0:
		_arc_t = _rng.randf_range(0.05, 0.16) * (1.2 if level < 10 else 0.8)
		_spawn_arc()
		if _rng.randf() < 0.3:
			_light.light_energy = 2.4
			_light.light_color = Color(0.7, 0.85, 1.0)


func _spawn_arc() -> void:
	var a0 := _rng.randf() * TAU
	var y0 := _rng.randf_range(0.15, HEIGHT * 0.95)
	var span := _rng.randf_range(0.6, 1.4)
	var dy := _rng.randf_range(-0.5, 0.5)
	var pts: Array[Vector3] = []
	var n := 6
	for i in n + 1:
		var k := float(i) / float(n)
		var a := a0 + span * k
		var r := RADIUS * _rng.randf_range(0.85, 1.25)
		pts.append(Vector3(cos(a) * r, clampf(y0 + dy * k + _rng.randf_range(-0.08, 0.08), 0.05, HEIGHT), sin(a) * r))
	for layer in 2:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var w := 0.018 if layer == 0 else 0.06
		for i in pts.size() - 1:
			var p0 := pts[i]
			var p1 := pts[i + 1]
			var up := Vector3(0, w, 0)
			var out := Vector3(p0.x, 0, p0.z).normalized() * w
			for side in [up, out]:
				st.add_vertex(p0 - side)
				st.add_vertex(p0 + side)
				st.add_vertex(p1 + side)
				st.add_vertex(p0 - side)
				st.add_vertex(p1 + side)
				st.add_vertex(p1 - side)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = _arc_mat if layer == 0 else _arc_glow
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_arcs.append([mi, _rng.randf_range(0.06, 0.12)])
