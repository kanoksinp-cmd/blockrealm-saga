extends SceneTree
## Starter "basic iron sword": chunky voxel blade with a fuller, wooden guard and grip, gold caps.
## Same frame as the old model: blade up +Y, grip centred on the origin, thin along Z.
const PX := 0.046
const COLORS := {
	"L": Color(0.93, 0.95, 0.96),   # bright edge / tip
	"M": Color(0.82, 0.86, 0.90),   # blade face
	"D": Color(0.62, 0.66, 0.73),   # fuller / shadow side
	"W": Color(0.56, 0.38, 0.24),   # wood
	"K": Color(0.36, 0.23, 0.15),   # dark wood
	"G": Color(0.95, 0.73, 0.28),   # gold
	"g": Color(0.74, 0.52, 0.17),   # gold shade
}
# rows top (tip) to bottom (pommel); 16 columns
const ROWS := [
	"......LL........",
	".....LLML.......",
	"....LLMMML......",
	"....LMMDMML.....",
	"...LMMMDMMMD....",
	"...LMMMDMMMD....",
	"...LMMMDMMMD....",
	"...LMMMDMMMD....",
	"...LMMMDMMMD....",
	"...LMMMDMMMD....",
	"...LMMMDMMMD....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMDMMD.....",
	"....LMMMMMD.....",
	"......gGg.......",
	"GgWWWWWWWWWWWgG.",
	"GKKKKKKKKKKKKKG.",
	"......KWK.......",
	"......WKW.......",
	"......KWK.......",
	"......WKW.......",
	"......KWK.......",
	"......WKW.......",
	".....gGGg.......",
	".....GGGg.......",
]
const DEPTH := {"L": 2, "M": 2, "D": 2, "W": 3, "K": 3, "G": 4, "g": 4}

func _initialize():
	var h := ROWS.size()
	var grip_row := 28              # row that sits on the origin (middle of the grip)
	var cells := {}                 # Vector3i -> key
	for r in h:
		var line: String = ROWS[r]
		for c in line.length():
			var k := line[c]
			if k == ".": continue
			var d: int = DEPTH[k]
			for z in range(-d / 2, d - d / 2):
				cells[Vector3i(c, h - 1 - r, z)] = k
	var st := {}
	for k in COLORS: st[k] = SurfaceTool.new(); st[k].begin(Mesh.PRIMITIVE_TRIANGLES)
	var dirs := [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,1,0), Vector3i(0,-1,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
	var origin := Vector3(7.0, float(h - 1 - grip_row), 0.0)   # column 7 = grip centre
	for p: Vector3i in cells:
		var k: String = cells[p]
		for dv: Vector3i in dirs:
			if cells.has(p + dv): continue
			var n := Vector3(dv)
			var u := Vector3(n.y, n.z, n.x).abs()
			if u == n.abs(): u = Vector3(0, 1, 0)
			var t := n.cross(u)
			var c := (Vector3(p) + Vector3(0.5, 0.5, 0.5) - origin - Vector3(0.5, 0.5, 0)) * PX + n * PX * 0.5
			var a := c + (-u - t) * PX * 0.5
			var b := c + (u - t) * PX * 0.5
			var cc := c + (u + t) * PX * 0.5
			var dd := c + (-u + t) * PX * 0.5
			var s: SurfaceTool = st[k]
			for q in [a, b, cc, a, cc, dd]:
				s.set_normal(n); s.add_vertex(q)
	var arr_mesh := ArrayMesh.new()
	for k in COLORS:
		var s: SurfaceTool = st[k]
		s.commit(arr_mesh)
		var mat := StandardMaterial3D.new(); mat.albedo_color = COLORS[k]; mat.roughness = 0.6 if k in ["L","M","D","G","g"] else 0.9
		mat.metallic = 0.35 if k in ["L","M","D","G","g"] else 0.0
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		arr_mesh.surface_set_material(arr_mesh.get_surface_count() - 1, mat)
	# fix winding: use both sides (cull disabled) so orientation of quads never matters
	var root := Node3D.new(); root.name = "basic_iron_sword2"
	var mi := MeshInstance3D.new(); mi.name = "basic_iron_sword"; mi.mesh = arr_mesh
	root.add_child(mi); mi.owner = root
	var ps := PackedScene.new(); ps.pack(root)
	print("aabb=", arr_mesh.get_aabb(), " surfaces=", arr_mesh.get_surface_count())
	print("save=", ResourceSaver.save(ps, "/tmp/basic_iron_sword.scn", ResourceSaver.FLAG_COMPRESS))
	quit()
