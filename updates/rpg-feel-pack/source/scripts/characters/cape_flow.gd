extends Node
## Capes are rebuilt as a thin, double-sided cloth sheet that is never still:
## it ripples in the wind all the time, billows back when the hero runs and
## sways side to side.  The original voxel cape stays (invisible) so refine
## effects and outfit code that look for it keep working.

var elapsed := 0.0
var cloth_materials: Array[ShaderMaterial] = []
var _root: Node3D
var _last := Vector3.INF
var _speed := 0.0

const CLOTH_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;
uniform vec4 main_color : source_color = vec4(0.6, 0.15, 0.15, 1.0);
uniform vec4 hem_color : source_color = vec4(0.85, 0.65, 0.25, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.38, 0.09, 1.0);
uniform float glow = 0.0;
uniform float wind_time = 0.0;
uniform float speed = 0.0;
uniform float cape_top = 0.4;
uniform float cape_bottom = -0.4;
uniform float seed = 0.0;
varying float fall;

void vertex() {
	float h = max(0.01, cape_top - cape_bottom);
	float w = clamp((cape_top - VERTEX.y) / h, 0.0, 1.0);
	fall = w;
	float w2 = w * w;
	float t = wind_time + seed;
	// constant breeze: travelling ripples down the cloth + a slow side sway
	float ripple = sin(t * 3.1 + VERTEX.y * 9.0 + VERTEX.x * 6.0) * 0.032
		+ sin(t * 5.7 - VERTEX.x * 15.0 + VERTEX.y * 4.0) * 0.012
		+ sin(t * 1.3 + VERTEX.y * 3.0) * 0.02;
	float billow = 0.045 + 0.26 * speed;
	VERTEX.z -= w2 * billow + w * ripple * (1.0 + speed * 1.4);
	VERTEX.x += w2 * (sin(t * 1.7 + VERTEX.y * 4.0) * 0.035 + sin(t * 3.3 + VERTEX.y * 7.0) * 0.012);
	VERTEX.y += w2 * speed * 0.12;
	// corners flutter a little more than the middle
	VERTEX.z -= w2 * abs(UV.x - 0.5) * sin(t * 6.3 + UV.x * 9.0) * 0.03 * (1.0 + speed);
}

void fragment() {
	vec3 n = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	NORMAL = FRONT_FACING ? n : -n;
	float hem = step(UV.y, 0.07) + step(0.93, UV.y) + step(UV.x, 0.035) + step(0.965, UV.x);
	vec3 c = mix(main_color.rgb, hem_color.rgb, clamp(hem, 0.0, 1.0));
	// soft woven folds running down the cloth
	c *= 0.9 + 0.1 * sin(UV.x * 31.0 + fall * 3.0);
	if (!FRONT_FACING) {
		c *= 0.72;   // lining
	}
	ALBEDO = c;
	ROUGHNESS = 0.82;
	SPECULAR = 0.25;
	EMISSION = glow_color.rgb * glow * (0.6 + 0.4 * sin(wind_time * 3.0 + UV.y * 6.0));
}
"""

static var _shader: Shader


static func install(root: Node3D) -> Node:
	var controller = load("res://scripts/characters/cape_flow.gd").new()
	controller.name = "CapeWind"
	controller.process_mode = Node.PROCESS_MODE_ALWAYS
	controller._root = root
	root.add_child(controller)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi.visible or not "cape" in mi.name.to_lower() or mi.mesh == null or mi.has_meta("flowing_cloth"):
			continue
		var cloth: MeshInstance3D = controller._make_cloth(mi)
		if cloth:
			mi.get_parent().add_child(cloth)
			cloth.transform = mi.transform
			# refine glow mounts etc. move onto the cloth; the voxel original is hidden
			for ch in mi.get_children():
				ch.reparent(cloth, false)
			if mi.material_overlay:
				cloth.set_meta("had_overlay", true)
			mi.visible = false
			mi.set_meta("flowing_cloth", true)
	if controller.cloth_materials.is_empty():
		root.remove_child(controller)
		controller.free()
		return null
	return controller


## Average colour of the cape's outer face and of its top row, read from the
## voxel atlas, so the cloth keeps the cape's colours.
func _sample_colors(mi: MeshInstance3D) -> Array:
	var main := Color(0.6, 0.18, 0.18)
	var hem := main.darkened(0.3)
	var mat := mi.get_active_material(0)
	var tex: Texture2D = null
	if mat is ShaderMaterial:
		tex = (mat as ShaderMaterial).get_shader_parameter("tex")
	elif mat is BaseMaterial3D:
		tex = (mat as BaseMaterial3D).albedo_texture
		if tex == null:
			main = (mat as BaseMaterial3D).albedo_color
			return [main, main.darkened(0.3)]
	if tex == null:
		return [main, hem]
	var img := tex.get_image()
	if img == null:
		return [main, hem]
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var a = mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var uvs = a[Mesh.ARRAY_TEX_UV]
	if uvs == null or norms.is_empty():
		return [main, hem]
	var aabb := mi.mesh.get_aabb()
	var sum := Color(0, 0, 0, 0)
	var top := Color(0, 0, 0, 0)
	var n := 0
	var nt := 0
	for i in verts.size():
		if absf(norms[i].z) < 0.5:
			continue
		var uv: Vector2 = uvs[i]
		var px := Vector2i(clampi(int(uv.x * img.get_width()), 0, img.get_width() - 1), clampi(int(uv.y * img.get_height()), 0, img.get_height() - 1))
		var c := img.get_pixelv(px)
		if c.a < 0.5:
			continue
		if verts[i].y > aabb.end.y - aabb.size.y * 0.08:
			top += c
			nt += 1
		else:
			sum += c
			n += 1
	if n > 0:
		main = Color(sum.r / n, sum.g / n, sum.b / n)
	hem = Color(top.r / nt, top.g / nt, top.b / nt) if nt > 0 else main.darkened(0.3)
	if hem.get_luminance() > main.get_luminance() * 0.9:
		hem = main.darkened(0.28)
	return [main, hem]


func _make_cloth(mi: MeshInstance3D) -> MeshInstance3D:
	var b := mi.mesh.get_aabb()
	if b.size.y < 0.05:
		return null
	var cols := 8
	var rows := 16
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z := b.position.z + b.size.z * 0.5
	for r in rows:
		for c in cols:
			for k in [[0, 0], [1, 0], [1, 1], [0, 0], [1, 1], [0, 1]]:
				var u := float(c + k[0]) / float(cols)
				var v := float(r + k[1]) / float(rows)
				# a touch wider at the bottom, like a real cape hanging from the shoulders
				var flare := 1.0 + v * 0.16
				var x := lerpf(b.position.x, b.end.x, 0.5 + (u - 0.5) * flare)
				var y := lerpf(b.end.y, b.position.y - b.size.y * 0.04, v)
				st.set_uv(Vector2(u, v))
				st.set_normal(Vector3(0, 0, -1))
				st.add_vertex(Vector3(x, y, z))
	var mesh := st.commit()
	if _shader == null:
		_shader = Shader.new()
		_shader.code = CLOTH_SHADER
	var m := ShaderMaterial.new()
	m.shader = _shader
	var cols_ := _sample_colors(mi)
	m.set_shader_parameter("main_color", cols_[0])
	m.set_shader_parameter("hem_color", cols_[1])
	m.set_shader_parameter("cape_top", b.end.y)
	m.set_shader_parameter("cape_bottom", b.position.y)
	m.set_shader_parameter("seed", randf() * 10.0)
	m.set_shader_parameter("glow", 0.35 if mi.material_overlay != null else 0.0)
	var cloth := MeshInstance3D.new()
	cloth.name = String(mi.name) + "Cloth"
	cloth.mesh = mesh
	cloth.material_override = m
	cloth.extra_cull_margin = 0.3
	cloth.set_meta("flowing_cloth", true)
	cloth_materials.append(m)
	return cloth


func _process(dt: float) -> void:
	elapsed += dt
	# how fast the wearer moves -> how far the cape billows back
	if _root and is_instance_valid(_root) and _root.is_inside_tree():
		var p := _root.global_position
		if _last != Vector3.INF and dt > 0.0:
			var v := Vector2(p.x - _last.x, p.z - _last.z).length() / dt
			_speed = lerpf(_speed, clampf(v / 7.0, 0.0, 1.0), minf(1.0, dt * 4.0))
		_last = p
	for material in cloth_materials:
		material.set_shader_parameter("wind_time", elapsed)
		material.set_shader_parameter("speed", _speed)
