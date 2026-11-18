extends Control
## The roll is committed by Game before this presentation opens.
signal finished
signal again   ## "refine again" pressed: the owner starts the next attempt
var item_id := ""
var before := 0
var after := 0
var success := false
var elapsed := 0.0
var duration := 1.2
var done := false
var _panel: PanelContainer
var _heading: Label
var _result: Label
var _progress: ProgressBar
var _close: Button
var _again: Button
var can_again := true

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.03, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_panel = PanelContainer.new()
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("171d26")
	surface.border_color = Color("c7a567")
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(12)
	surface.set_content_margin_all(22)
	_panel.add_theme_stylebox_override("panel", surface)
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_panel.add_child(column)
	_heading = _text("กำลังตีบวกอุปกรณ์…", 23)
	column.add_child(_heading)
	var image := TextureRect.new()
	image.texture = Items.icon(item_id)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2(80, 80)
	column.add_child(image)
	column.add_child(_text(Items.item_name(item_id), 18))
	_result = _text("+%d  →  …" % before, 28)
	column.add_child(_result)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.y = 8
	_progress.show_percentage = false
	column.add_child(_progress)
	_close = Button.new()
	_close.text = "กำลังดำเนินการ…"
	_close.custom_minimum_size.y = 42
	_close.disabled = true
	_close.pressed.connect(close)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	_again = Button.new()
	_again.text = "ตีบวกอีกครั้ง"
	_again.custom_minimum_size.y = 42
	_again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_again.visible = false
	var green := StyleBoxFlat.new()
	green.bg_color = Color("2f6b45")
	green.border_color = Color("8fd19e")
	green.set_border_width_all(1)
	green.set_corner_radius_all(8)
	green.set_content_margin_all(8)
	_again.add_theme_stylebox_override("normal", green)
	var green_h := green.duplicate() as StyleBoxFlat
	green_h.bg_color = Color("3a8255")
	_again.add_theme_stylebox_override("hover", green_h)
	_again.add_theme_stylebox_override("pressed", green_h)
	_again.add_theme_color_override("font_color", Color("f2eee5"))
	_again.pressed.connect(_refine_again)
	buttons.add_child(_again)
	_close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_close)
	get_viewport().size_changed.connect(_layout)
	_layout.call_deferred()

func _text(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", load("res://assets/fonts/ui_font_bold.tres"))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f2eee5"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _layout() -> void:
	_panel.size = Vector2(minf(500, size.x - 32), 0)
	_panel.position = (size - _panel.size) * 0.5

func _process(delta: float) -> void:
	if done: return
	elapsed += delta
	_progress.value = minf(100, elapsed / duration * 100)
	if elapsed < duration: return
	done = true
	_heading.text = "ตีบวกสำเร็จ" if success else "ตีบวกไม่สำเร็จ · ระดับคงเดิม"
	_result.text = "+%d  →  +%d" % [before, after]
	_close.text = "กลับไปโรงตีเหล็ก"
	_close.disabled = false
	_again.visible = can_again
	if can_again: _again.grab_focus()
	else: _close.grab_focus()
	_layout.call_deferred()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if done: close()
		get_viewport().set_input_as_handled()

func _refine_again() -> void:
	if not done: return
	again.emit()
	queue_free()

func close() -> void:
	if not done: return
	finished.emit()
	queue_free()
