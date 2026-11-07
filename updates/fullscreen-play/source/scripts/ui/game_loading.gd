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
	var backdrop := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color("29314b"))
	gradient.set_color(1, Color("090e18"))
	var sky := GradientTexture2D.new()
	sky.gradient = gradient
	sky.fill_from = Vector2(0.5, 0.0)
	sky.fill_to = Vector2(0.5, 1.0)
	backdrop.texture = sky
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	for i in 50:
		var star := ColorRect.new()
		star.color = Color(0.83, 0.72, 0.49, 0.12 + float(i % 3) * 0.06)
		star.anchor_left = float((i * 37 + 13) % 97) / 100.0
		star.anchor_top = float((i * 23 + 7) % 89) / 100.0
		star.size = Vector2(2, 2)
		backdrop.add_child(star)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -90
	backdrop.add_child(center)
	var brand := VBoxContainer.new()
	brand.add_theme_constant_override("separation", 12)
	center.add_child(brand)
	var mark := TextureRect.new()
	mark.texture = ImageTexture.create_from_image(Image.load_from_file("res://assets/ui/brand_mark.png"))
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.custom_minimum_size = Vector2(100, 100)
	brand.add_child(mark)
	for text in ["BLOCKREALM", "S A G A", "การผจญภัยครั้งใหม่กำลังจะเริ่มต้น"]:
		var title := Label.new()
		title.text = text
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 42 if text == "BLOCKREALM" else (24 if text == "S A G A" else 16))
		title.add_theme_color_override("font_color", Color("f5e6c6") if text == "BLOCKREALM" else Color("d3b376"))
		brand.add_child(title)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	var fit := func () -> void:
		var half := minf(280.0, (backdrop.size.x - 48.0) * 0.5)
		panel.offset_left = -half
		panel.offset_right = half
		panel.offset_top = -108
		panel.offset_bottom = -28
	backdrop.resized.connect(fit)
	fit.call_deferred()
	var frame := StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", frame)
	backdrop.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color("c6ccd5"))
	row.add_child(_label)
	_percent = Label.new()
	_percent.add_theme_font_size_override("font_size", 15)
	_percent.add_theme_color_override("font_color", Color("e6bf70"))
	row.add_child(_percent)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size.y = 6
	_bar.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("202b3a")
	track.set_corner_radius_all(4)
	_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("e6bf70")
	fill.set_corner_radius_all(4)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)
	var hint := Label.new()
	hint.text = "เตรียมโลก • ตัวละคร • อุปกรณ์"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color("7f8d9f"))
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
