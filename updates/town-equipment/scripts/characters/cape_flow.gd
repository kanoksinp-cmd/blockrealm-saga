extends Node
## Per-avatar wind clock. Keeps cloth moving while standing, walking or casting.
var elapsed:=0.0
var cloth_materials: Array[ShaderMaterial]=[]
const WIND = """
uniform float wind_time=0.0;
uniform float cape_bottom=-0.4;
uniform float cape_top=0.4;
void vertex(){
 float w=clamp((cape_top-VERTEX.y)/max(0.01,cape_top-cape_bottom),0.0,1.0);
 w=w*w;
 VERTEX.z-=w*(0.035+sin(wind_time*2.2+VERTEX.y*7.0+VERTEX.x*5.0)*0.030);
 VERTEX.x+=w*sin(wind_time*1.65+VERTEX.y*5.0)*0.022;
}
"""
static func install(root: Node3D) -> Node:
	var controller=load("res://scripts/characters/cape_flow.gd").new()
	controller.name="CapeWind";controller.process_mode=Node.PROCESS_MODE_ALWAYS;root.add_child(controller)
	for node in root.find_children("*","MeshInstance3D",true,false):
		var mi:=node as MeshInstance3D
		if not mi.visible or not "cape" in mi.name.to_lower() or mi.mesh==null:continue
		var bounds:=mi.mesh.get_aabb()
		mi.mesh=grid(mi.mesh)
		for surface in mi.mesh.get_surface_count():
			var src: Material=mi.material_override if mi.material_override else mi.get_active_material(surface)
			var material:=ShaderMaterial.new();var code: String
			if src is ShaderMaterial:
				material=src.duplicate();code=src.shader.code
			else:
				code="shader_type spatial; render_mode cull_disabled; uniform vec4 tint:source_color=vec4(1.0); uniform sampler2D tex:source_color,filter_nearest; uniform bool has_tex=false; void fragment(){ALBEDO=tint.rgb*(texture(tex,UV).rgb if has_tex else vec3(1.0)); ROUGHNESS=1.0;}"
				# Godot shader uses a ternary expression.
				code=code.replace("texture(tex,UV).rgb if has_tex else vec3(1.0)","has_tex ? texture(tex,UV).rgb : vec3(1.0)")
				if src is BaseMaterial3D:
					material.set_shader_parameter("tint",src.albedo_color)
			var shader:=Shader.new();shader.code=code+WIND;material.shader=shader
			if src is BaseMaterial3D:
				material.set_shader_parameter("tint",src.albedo_color)
				material.set_shader_parameter("has_tex",src.albedo_texture!=null)
				if src.albedo_texture:material.set_shader_parameter("tex",src.albedo_texture)
			material.set_shader_parameter("cape_bottom",bounds.position.y);material.set_shader_parameter("cape_top",bounds.end.y)
			mi.set_surface_override_material(surface,material);controller.cloth_materials.append(material)
		if mi.material_overlay is ShaderMaterial:
			var source_overlay:=mi.material_overlay as ShaderMaterial
			var overlay:=source_overlay.duplicate() as ShaderMaterial
			var overlay_shader:=Shader.new();overlay_shader.code=source_overlay.shader.code+WIND;overlay.shader=overlay_shader
			for parameter in source_overlay.shader.get_shader_uniform_list():overlay.set_shader_parameter(parameter.name,source_overlay.get_shader_parameter(parameter.name))
			overlay.set_shader_parameter("cape_bottom",bounds.position.y);overlay.set_shader_parameter("cape_top",bounds.end.y)
			mi.material_overlay=overlay;controller.cloth_materials.append(overlay)
		mi.material_override=null;mi.extra_cull_margin=.12;mi.set_meta("flowing_cloth",true)
	if controller.cloth_materials.is_empty():root.remove_child(controller);controller.free();return null
	return controller
func _process(dt: float):
	elapsed+=dt
	for material in cloth_materials:material.set_shader_parameter("wind_time",elapsed)
static func grid(source: Mesh) -> ArrayMesh:
	var mesh:=ArrayMesh.new()
	for surface in source.get_surface_count():
		var a=source.surface_get_arrays(surface);var v:PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		var ns:PackedVector3Array=a[Mesh.ARRAY_NORMAL];var uv:PackedVector2Array=a[Mesh.ARRAY_TEX_UV] if a[Mesh.ARRAY_TEX_UV]!=null else PackedVector2Array()
		var indices:PackedInt32Array=a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if indices.is_empty():
			for i in v.size():indices.append(i)
		var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uvs:=PackedVector2Array()
		for triangle in range(0,indices.size(),3):
			var ids=[indices[triangle],indices[triangle+1],indices[triangle+2]]
			for i in range(4):
				for j in range(4-i):
					var points=[Vector2(i,j),Vector2(i+1,j),Vector2(i,j+1)]
					if i+j<3:points.append_array([Vector2(i+1,j),Vector2(i+1,j+1),Vector2(i,j+1)])
					for p in points:
						var u:float=p.x/4.0;var w:float=p.y/4.0;var k:=1.0-u-w
						vertices.append(v[ids[0]]*k+v[ids[1]]*u+v[ids[2]]*w)
						normals.append((ns[ids[0]]*k+ns[ids[1]]*u+ns[ids[2]]*w).normalized())
						uvs.append(uv[ids[0]]*k+uv[ids[1]]*u+uv[ids[2]]*w if not uv.is_empty() else Vector2.ZERO)
		var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uvs
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh.surface_set_material(surface,source.surface_get_material(surface))
	return mesh

