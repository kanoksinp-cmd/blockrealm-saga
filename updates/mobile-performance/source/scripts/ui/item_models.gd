class_name ItemModels
extends Node








const VOXEL := 0.1
const BAKE_SIZE := 64
const IDLE_PITCH := 16.0
const IDLE_YAW := -32.0
const SPIN_SPEED := 2.4

static var _inst: ItemModels
static var _sources := { }
static var _textures := { }
static var _meshes := { }
static var _material: StandardMaterial3D

var _queue: Array[String] = []
var _baking := ""
var _bake_frames := 0
var _bake_vp: SubViewport
var _bake_pivot: Node3D
var _bake_cam: Camera3D
var _spin_vp: SubViewport
var _spin_pivot: Node3D
var _spin_cam: Camera3D
var _hover: Control
var _hover_prev: Texture2D
var _hover_id := ""
var _spin_t := 0.0


static func rendering() -> bool:
	return DisplayServer.get_name() != "headless"



static func register(id: String, tex: Texture2D) -> void:
	if tex == null or _sources.has(id):
		return
	var img := tex.get_image()
	if img == null:
		return
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	_sources[id] = img
	_textures[tex.get_instance_id()] = id
	if tex is ImageTexture and rendering():
		var inst := _instance()
		if inst:
			inst._queue.append(id)


static func item_of(tex: Texture2D) -> String:
	if tex == null:
		return ""
	return _textures.get(tex.get_instance_id(), "")


static func _instance() -> ItemModels:
	if _inst != null and is_instance_valid(_inst):
		return _inst
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	_inst = ItemModels.new()
	_inst.name = "ItemModels"
	tree.root.add_child.call_deferred(_inst)
	return _inst


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.75
		_material.metallic_specular = 0.35
		_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return _material



static func mesh(id: String) -> ArrayMesh:
	if _meshes.has(id):
		return _meshes[id]
	var display_model := String(Items.info(id).get("display_model", ""))
	if display_model != "":
		var imported := TownAssets.item_mesh(display_model)
		if imported:
			_meshes[id] = imported
			return imported
	if not _sources.has(id):
		Items.icon(id)
	var img: Image = _sources.get(id)
	if img == null:
		return null
	var m := _extrude(img)
	_meshes[id] = m
	return m


static func _extrude(img: Image) -> ArrayMesh:
	var w := img.get_width()
	var h := img.get_height()
	var solid := func (x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and img.get_pixel(x, y).a > 0.5

	var dist := { }
	var frontier: Array[Vector2i] = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in h:
		for x in w:
			if solid.call(x, y):
				for d: Vector2i in dirs:
					if not solid.call(x + d.x, y + d.y):
						dist[Vector2i(x, y)] = 0
						frontier.append(Vector2i(x, y))
						break
	while not frontier.is_empty():
		var next: Array[Vector2i] = []
		for c in frontier:
			for d: Vector2i in dirs:
				var q: Vector2i = c + d
				if solid.call(q.x, q.y) and not dist.has(q):
					dist[q] = int(dist[c]) + 1
					next.append(q)
		frontier = next

	var half := func (x: int, y: int) -> float:
		if not solid.call(x, y):
			return 0.0
		return (1 + 2 * mini(int(dist.get(Vector2i(x, y), 0)), 2)) * VOXEL * 0.5
	var ox := w * VOXEL * 0.5
	var oy := h * VOXEL * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in h:
		for x in w:
			if not solid.call(x, y):
				continue
			var col := img.get_pixel(x, y)
			col.a = 1.0
			var x0 := x * VOXEL - ox
			var x1 := x0 + VOXEL
			var y1 := oy - y * VOXEL
			var y0 := y1 - VOXEL
			var hz: float = half.call(x, y)
			_quad(st, [Vector3(x0, y1, hz), Vector3(x1, y1, hz), Vector3(x1, y0, hz), Vector3(x0, y0, hz)], Vector3(0, 0, 1), col)
			_quad(st, [Vector3(x1, y1, - hz), Vector3(x0, y1, - hz), Vector3(x0, y0, - hz), Vector3(x1, y0, - hz)], Vector3(0, 0, -1), col.darkened(0.08))
			for side in [[Vector2i(1, 0), Vector3(1, 0, 0), 0.14], [Vector2i(-1, 0), Vector3(-1, 0, 0), 0.1],
					[Vector2i(0, -1), Vector3(0, 1, 0), -0.06], [Vector2i(0, 1), Vector3(0, -1, 0), 0.22]]:
				var nh: float = half.call(x + side[0].x, y + side[0].y)
				if nh >= hz - 0.0001:
					continue
				var shade: float = side[2]
				var c2 := col.lightened(- shade) if shade < 0.0 else col.darkened(shade)
				if nh <= 0.0:
					_side(st, side[1], x0, x1, y0, y1, - hz, hz, c2)
				else:
					_side(st, side[1], x0, x1, y0, y1, nh, hz, c2)
					_side(st, side[1], x0, x1, y0, y1, - hz, - nh, c2)
	st.index()
	return st.commit()


static func _side(st: SurfaceTool, n: Vector3, x0: float, x1: float, y0: float, y1: float, za: float, zb: float, c: Color) -> void:
	if n.x > 0.5:
		_quad(st, [Vector3(x1, y1, zb), Vector3(x1, y1, za), Vector3(x1, y0, za), Vector3(x1, y0, zb)], n, c)
	elif n.x < -0.5:
		_quad(st, [Vector3(x0, y1, za), Vector3(x0, y1, zb), Vector3(x0, y0, zb), Vector3(x0, y0, za)], n, c)
	elif n.y > 0.5:
		_quad(st, [Vector3(x0, y1, za), Vector3(x1, y1, za), Vector3(x1, y1, zb), Vector3(x0, y1, zb)], n, c)
	else:
		_quad(st, [Vector3(x0, y0, zb), Vector3(x1, y0, zb), Vector3(x1, y0, za), Vector3(x0, y0, za)], n, c)


static func _quad(st: SurfaceTool, q: Array, n: Vector3, c: Color) -> void:
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_color(c)
		st.add_vertex(q[i])



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bake := _make_stage(BAKE_SIZE)
	_bake_vp = bake[0]
	_bake_pivot = bake[1]
	_bake_cam = bake[2]
	_bake_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var spin := _make_stage(BAKE_SIZE)
	_spin_vp = spin[0]
	_spin_pivot = spin[1]
	_spin_cam = spin[2]
	_spin_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _make_stage(size: int) -> Array:
	var vp := SubViewport.new()
	vp.size = Vector2i(size, size)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	env.environment.ambient_light_energy = 0.55
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -40, 0)
	key.light_energy = 1.0
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, 150, 0)
	fill.light_energy = 0.35
	vp.add_child(fill)
	var pivot := Node3D.new()
	vp.add_child(pivot)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL

	cam.position = Vector3(0, sin(deg_to_rad(IDLE_PITCH)), cos(deg_to_rad(IDLE_PITCH))) * 10.0
	cam.current = true
	vp.add_child(cam)
	cam.look_at(Vector3.ZERO)
	return [vp, pivot, cam]


func _show(pivot: Node3D, cam: Camera3D, id: String, turning := true) -> bool:
	for c in pivot.get_children():
		pivot.remove_child(c)
		c.queue_free()
	var m := mesh(id)
	if m == null or m.get_surface_count() == 0:
		return false
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material()
	pivot.add_child(mi)
	var size := m.get_aabb().size
	var tilt := deg_to_rad(IDLE_PITCH)
	if turning:

		var across := Vector2(size.x, size.z).length()
		cam.size = maxf(size.y * cos(tilt) + across * sin(tilt), across) * 1.06
	else:

		var yaw := deg_to_rad(absf(IDLE_YAW))
		var wide := size.x * cos(yaw) + size.z * sin(yaw)
		var deep := size.x * sin(yaw) + size.z * cos(yaw)
		cam.size = maxf(size.y * cos(tilt) + deep * sin(tilt), wide) * 1.04
	return true


func _process(delta: float) -> void:
	_bake_step()
	_hover_step(delta)


func _bake_step() -> void:
	if _baking != "":
		_bake_frames += 1
		if _bake_frames < 2:
			return
		var img := _bake_vp.get_texture().get_image()
		var tex: Texture2D = Items.icon(_baking)
		if img and tex is ImageTexture and not img.is_empty():
			(tex as ImageTexture).set_image(img)
		_baking = ""
		_bake_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	while not _queue.is_empty():
		var id: String = _queue.pop_front()
		if _show(_bake_pivot, _bake_cam, id, false):
			_bake_pivot.rotation_degrees = Vector3(0, IDLE_YAW, 0)
			_baking = id
			_bake_frames = 0
			_bake_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			return



func _hover_step(delta: float) -> void:
	if Settings.is_mobile():
		if _hover != null:
			_restore()
		return
	var viewport := get_viewport()
	var c: Control = viewport.gui_get_hovered_control() if viewport else null
	var target: Control = null
	var id := ""
	var walk := c
	for i in 3:
		if walk == null:
			break
		var tex: Texture2D = null
		if walk is Button:
			tex = (walk as Button).icon
		elif walk is TextureRect:
			tex = (walk as TextureRect).texture
		if walk == _hover and tex == _spin_vp.get_texture():
			target = walk
			id = _hover_id
			break
		var found := item_of(tex)
		if found != "":
			target = walk
			id = found
			break
		walk = walk.get_parent() as Control
	if target != _hover:
		_restore()
		if target != null:
			_hover = target
			_hover_id = id
			if target is Button:
				_hover_prev = (target as Button).icon
			else:
				_hover_prev = (target as TextureRect).texture
			_show(_spin_pivot, _spin_cam, id)
			_spin_t = 0.0
			_spin_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			if target is Button:
				(target as Button).icon = _spin_vp.get_texture()
			else:
				(target as TextureRect).texture = _spin_vp.get_texture()
	elif _hover != null and target != null:

		var current: Texture2D = (target as Button).icon if target is Button else (target as TextureRect).texture
		if current != _spin_vp.get_texture():
			var now := item_of(current)
			if now != "" and now != _hover_id:
				_hover_id = now
				_show(_spin_pivot, _spin_cam, now)
			_hover_prev = current
			if target is Button:
				(target as Button).icon = _spin_vp.get_texture()
			else:
				(target as TextureRect).texture = _spin_vp.get_texture()
	if _hover != null:
		_spin_t += delta
		_spin_pivot.rotation = Vector3(0, deg_to_rad(IDLE_YAW) + _spin_t * SPIN_SPEED, 0)


func _restore() -> void:
	if _hover != null and is_instance_valid(_hover):
		if _hover is Button and (_hover as Button).icon == _spin_vp.get_texture():
			(_hover as Button).icon = _hover_prev
		elif _hover is TextureRect and (_hover as TextureRect).texture == _spin_vp.get_texture():
			(_hover as TextureRect).texture = _hover_prev
	_hover = null
	_hover_prev = null
	_hover_id = ""
	_spin_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
