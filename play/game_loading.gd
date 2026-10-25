extends CanvasLayer
## Kept on the tree root until the destination scene has finished initializing.

var _bar: ProgressBar
var _label: Label
var _path: String

func start(path: String) -> void:
	_path = path
	layer = 100
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.03, 0.045)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	var title := Label.new()
	title.text = "BLOCKREALM SAGA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.45))
	box.add_child(title)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_label)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size.y = 26
	box.add_child(_bar)
	_update(0, "กำลังโหลดเกม...")
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
	_label.text = "%s  %d%%" % [message, int(_bar.value)]

func _fail() -> void:
	_label.text = "โหลดเกมไม่สำเร็จ กรุณาลองอีกครั้ง"
	await get_tree().create_timer(2.0).timeout
	var current := get_tree().current_scene
	if current != null:
		current.set("_entering_game", false)
		current.process_mode = Node.PROCESS_MODE_INHERIT
	queue_free()
