extends PanelContainer


var target: Monster
var title: Label
var health: ProgressBar
var health_text: Label
var portrait: SubViewport
var holder: Node3D
var camera: Camera3D
var _mobile := false


func _ready() -> void:
	_mobile = Settings.is_mobile()
	var detail_width := 136.0 if _mobile else 220.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.114, 0.149, 0.96)
	style.border_color = Color("c7a567")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 6 if _mobile else 10
	style.content_margin_right = 6 if _mobile else 10
	style.content_margin_top = 5 if _mobile else 8
	style.content_margin_bottom = 5 if _mobile else 8
	add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6 if _mobile else 10)
	add_child(row)
	portrait = SubViewport.new()
	portrait.size = Vector2i(64, 64) if _mobile else Vector2i(128, 128)
	portrait.transparent_bg = true
	portrait.own_world_3d = true
	portrait.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(portrait)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.8
	camera = Camera3D.new()
	camera.environment = environment
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	portrait.add_child(camera)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.6, -0.4, 0)
	portrait.add_child(light)
	holder = Node3D.new()
	portrait.add_child(holder)
	var face := TextureRect.new()
	face.texture = portrait.get_texture()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.custom_minimum_size = Vector2(36, 36) if _mobile else Vector2(64, 64)
	row.add_child(face)
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = detail_width
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(details)
	title = Label.new()
	title.custom_minimum_size.x = detail_width
	title.clip_text = true
	title.add_theme_font_size_override("font_size", 12 if _mobile else 15)
	details.add_child(title)
	health = ProgressBar.new()
	health.custom_minimum_size = Vector2(detail_width, 16 if _mobile else 22)
	health.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.18, 0.2)
	fill.set_corner_radius_all(4)
	health.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.15, 0.04, 0.05)
	background.set_corner_radius_all(4)
	health.add_theme_stylebox_override("background", background)
	details.add_child(health)
	health_text = Label.new()
	health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_text.add_theme_font_size_override("font_size", 10 if _mobile else 12)
	health.add_child(health_text)
	for control in find_children("*", "Control", true, false):
		(control as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var next: Monster = null
	if is_instance_valid(player) and player.is_alive():
		var candidate: Monster = player.attack_target
		if is_instance_valid(candidate) and candidate.is_alive():
			next = candidate
	if next == null:
		target = null
		hide()
		portrait.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	if next != target:
		target = next
		_make_portrait()
	show()
	title.text = "%s  Lv.%d" % [tr(target.display_name), target.level]
	health.max_value = maxi(1, target.max_hp)
	health.value = clampi(target.hp, 0, target.max_hp)
	health_text.text = "HP %d / %d" % [maxi(0, target.hp), target.max_hp]
	var vp := get_viewport().get_visible_rect().size
	position = Vector2(maxf(10, (vp.x - size.x) * 0.5), 352 if _mobile and vp.y > vp.x else (66 if _mobile else 90))


func _make_portrait() -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	if not is_instance_valid(target.model):
		return
	var bounds := AABB()
	var first := true
	var meshes: Array[Node] = target.model.find_children("*", "MeshInstance3D", true, false)
	if target.model is MeshInstance3D:
		meshes.push_front(target.model)
	for node in meshes:
		var source := node as MeshInstance3D
		if source.mesh == null or not source.is_visible_in_tree():
			continue
		var copy := MeshInstance3D.new()
		copy.mesh = source.mesh
		copy.material_override = source.material_override
		for surface in source.mesh.get_surface_count():
			copy.set_surface_override_material(surface, source.get_surface_override_material(surface))
		holder.add_child(copy)
		copy.transform = target.global_transform.affine_inverse() * source.global_transform
		var box: AABB = copy.transform * copy.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var center := bounds.get_center()
	var diameter := maxf(bounds.size.length(), 0.5)
	camera.size = diameter * 1.15
	camera.far = maxf(100, diameter * 6)
	camera.position = center + Vector3(0.3, 0.2, 1).normalized() * diameter * 2
	camera.look_at(center)
	portrait.render_target_update_mode = SubViewport.UPDATE_ONCE
