extends RefCounted
## Static interior furniture is baked into a shared one-metre grid per room.
## Actors, moving bellows and the exterior facade retain their own geometry.
const CELL := 1.0
const ROOMS := ["guild1", "guild2", "smithy"]

static func _animated(node: Node, root: Node) -> bool:
 var parent := node.get_parent()
 while parent != null and parent != root:
  if parent.get_script() != null or parent.name == "Bellows": return true
  parent = parent.get_parent()
 return false

static func apply(root: Node3D, vb) -> void:
 if root == null: return
 var rooms := {}
 var removed := 0
 for mesh_node in root.find_children("*", "MeshInstance3D", true, false):
  var node := mesh_node as MeshInstance3D
  if node.mesh == null or node.name == "WorkshopFloor" or _animated(node, root): continue
  var bounds: AABB = node.global_transform * node.mesh.get_aabb()
  var area: String = vb.area_at(bounds.get_center())
  if area not in ROOMS: continue
  var material := node.material_override as StandardMaterial3D
  if material == null and node.mesh.get_surface_count() > 0:
   material = node.mesh.surface_get_material(0) as StandardMaterial3D
  var color := material.albedo_color if material != null else Color(0.3, 0.28, 0.25)
  var glowing := material != null and material.emission_enabled
  var extent := bounds.size
  # Drop mugs, paper pins, embers and other tiny static clutter instead of inflating each into a cube.
  if maxf(extent.x, maxf(extent.y, extent.z)) >= 0.5:
   if not rooms.has(area): rooms[area] = {}
   var cells: Dictionary = rooms[area]
   var count := Vector3i(maxi(1, roundi(extent.x)), maxi(1, roundi(extent.y)), maxi(1, roundi(extent.z)))
   var begin := Vector3i((bounds.get_center() - Vector3(count) * 0.5).round())
   var score := maxf(0.0001, extent.x * extent.y * extent.z)
   for x in count.x:
    for y in count.y:
     for z in count.z:
      var cell := begin + Vector3i(x, y, z)
      var center := Vector3(cell) + Vector3.ONE * 0.5
      # Keep existing walkable lanes and NPC standing cells open at body height.
      if cell.y < 2 and vb.walkable(center.x, center.z): continue
      if not cells.has(cell) or score >= float(cells[cell].score):
       cells[cell] = {"color": color, "glow": glowing, "score": score}
  node.get_parent().remove_child(node)
  node.free()
  removed += 1
 for area in rooms:
  var group := Node3D.new()
  group.name = "Metre_" + area
  group.set_meta("voxel_size", CELL)
  root.add_child(group)
  _mesh(group, rooms[area], false)
  _mesh(group, rooms[area], true)
 root.set_meta("metre_removed_meshes", removed)

static func _mesh(root: Node3D, cells: Dictionary, glow: bool) -> void:
 var vertices := PackedVector3Array()
 var normals := PackedVector3Array()
 var colors := PackedColorArray()
 for cell: Vector3i in cells:
  var data: Dictionary = cells[cell]
  if bool(data.glow) != glow: continue
  for face in BlockWorld.FACES:
   if cells.has(cell + Vector3i(face[0])): continue
   for i in [0, 1, 2, 0, 2, 3]:
    vertices.append(Vector3(cell) + Vector3(face[1][i]))
    normals.append(Vector3(face[0]))
    colors.append(data.color)
 if vertices.is_empty(): return
 var arrays := []
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX] = vertices
 arrays[Mesh.ARRAY_NORMAL] = normals
 arrays[Mesh.ARRAY_COLOR] = colors
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
 var material := StandardMaterial3D.new()
 material.vertex_color_use_as_albedo = true
 material.roughness = 0.9
 if glow:
  material.emission_enabled = true
  material.emission = Color(1.0, 0.3, 0.02)
  material.emission_energy_multiplier = 1.2
 var node := MeshInstance3D.new()
 node.name = "Glow" if glow else "Furniture"
 node.mesh = mesh
 node.material_override = material
 root.add_child(node)
