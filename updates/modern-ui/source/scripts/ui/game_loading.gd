extends CanvasLayer


var _bar: ProgressBar
var _label: Label
var _path: String
var _percent: Label

func start(path: String) -> void:
	_path = path
	layer = 100
	_build_ui()
	await _load_game()

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("171d26")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var art := preload("res://assets/ui/loading_cover.png")
	var background := TextureRect.new()
	background.texture = art
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	var fit_background := func () -> void:
		var view_size := backdrop.size
		var image_size := art.get_size()
		var cover_scale := maxf(view_size.x / image_size.x, view_size.y / image_size.y)
		background.size = image_size * cover_scale
		background.position = Vector2((view_size.x - background.size.x) * 0.5, 0)
	backdrop.resized.connect(fit_background)
	fit_background.call_deferred()
	background.modulate = Color.WHITE
	backdrop.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.045, 0.025, 0.08, 0.12)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(shade)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.15
	panel.anchor_right = 0.85
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -174
	panel.offset_bottom = -28
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.09, 0.114, 0.149, 0.97)
	frame.border_color = Color("c7a567")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(12)
	frame.content_margin_left = 28
	frame.content_margin_right = 28
	frame.content_margin_top = 16
	frame.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", frame)
	backdrop.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color("f5e7c9"))
	row.add_child(_label)
	_percent = Label.new()
	_percent.add_theme_font_size_override("font_size", 24)
	_percent.add_theme_color_override("font_color", Color("ffd779"))
	row.add_child(_percent)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size.y = 16
	_bar.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("292034")
	track.set_corner_radius_all(8)
	_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("eeb95b")
	fill.set_corner_radius_all(8)
	fill.shadow_color = Color(1.0, 0.65, 0.2, 0.2)
	fill.shadow_size = 0
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)
	var hint := Label.new()
	hint.text = "การผจญภัยครั้งใหม่กำลังจะเริ่มต้น"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("c4cbd5"))
	box.add_child(hint)
	_update(0, "กำลังโหลดเกม...")

func _load_game() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var error := ResourceLoader.load_threaded_request(_path)
	if error != OK:
		_fail()
		return
	while true:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(_path, progress)
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail()
			return
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if not progress.is_empty():
			_update(int(float(progress[0]) * 90.0), "กำลังโหลดเกม...")
		await get_tree().process_frame
	_update(90, "กำลังเตรียมโลกและตัวละคร...")
	await get_tree().process_frame
	await get_tree().process_frame
	var scene := ResourceLoader.load_threaded_get(_path) as PackedScene
	if scene == null or get_tree().change_scene_to_packed(scene) != OK:
		_fail()
		return
	await get_tree().scene_changed
	_update(100, "พร้อมเข้าเกม")
	await get_tree().create_timer(0.25).timeout
	queue_free()

func _update(percent: int, message: String) -> void:
	_bar.value = maxi(int(_bar.value), percent)
	_label.text = message
	_percent.text = "%d%%" % int(_bar.value)

func _fail() -> void:
	_label.text = "โหลดเกมไม่สำเร็จ กรุณาลองอีกครั้ง"
	await get_tree().create_timer(2.0).timeout
	var current := get_tree().current_scene
	if current != null:
		current.set("_entering_game", false)
		current.process_mode = Node.PROCESS_MODE_INHERIT
	queue_free()

