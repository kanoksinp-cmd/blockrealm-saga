class_name TownAssets
extends RefCounted
static var scenes:Dictionary={}
static func instance(id: String) -> Node3D:
	if not scenes.has(id):scenes[id]=load("res://assets/models/town/%s.glb" % id)
	var scene:PackedScene=scenes[id]
	if scene==null:return null
	var node:=scene.instantiate() as Node3D;node.name=id;return node

## Bake imported mesh colors for the shared inventory/drop mesh renderer.
static func item_mesh(id: String) -> ArrayMesh:
	var root:=instance(id)
	if root==null:return null
	var points:=PackedVector3Array();var normals:=PackedVector3Array();var colors:=PackedColorArray()
	var stack=[{"node":root,"transform":Transform3D.IDENTITY}]
	while not stack.is_empty():
		var entry:Dictionary=stack.pop_back();var node:Node=entry.node
		var xf:Transform3D=entry.transform
		if node is Node3D:xf=xf*node.transform
		if node is MeshInstance3D:
			for surface in node.mesh.get_surface_count():
				var mat:Material=node.get_active_material(surface);var color:=Color.WHITE
				if mat is BaseMaterial3D:color=mat.albedo_color
				var a=node.mesh.surface_get_arrays(surface);var v:PackedVector3Array=a[Mesh.ARRAY_VERTEX];var ns:PackedVector3Array=a[Mesh.ARRAY_NORMAL]
				var ix:PackedInt32Array=a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
				if ix.is_empty():
					for j in v.size():ix.append(j)
				for j in ix:
					points.append(xf*v[j]);normals.append((xf.basis*ns[j]).normalized());colors.append(color)
		for child in node.get_children():stack.append({"node":child,"transform":xf})
	root.free()
	if points.is_empty():return null
	var bounds:=AABB(points[0],Vector3.ZERO)
	for point in points:bounds=bounds.expand(point)
	var center:=bounds.get_center();var factor:=1.6/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	for i in points.size():points[i]=(points[i]-center)*factor
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh
