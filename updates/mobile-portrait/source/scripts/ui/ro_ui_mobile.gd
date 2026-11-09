extends "res://scripts/ui/ro_ui_base.gd"
## Classic desktop presentation with a touch-sized, responsive mobile layout.
var _touch_ready := false
var _touch_shade: ColorRect
var _syncing := false
var _touch_map_view: Control
var _touch_map_side: VBoxContainer
var _touch_map_list_scroll: ScrollContainer
var _portrait_key := ""
var _toast: Label
var _toast_left := 0.0
var _portrait_map_row: VBoxContainer
var _tracker_scroll: ScrollContainer

func _ready() -> void:
	super._ready()
	_touch_shade = ColorRect.new()
	_touch_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_touch_shade.color = Color(0, 0, 0, 0.28)
	_touch_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_touch_shade)
	_touch_shade.hide()
	_toast = _label("", 14, CREAM, true)
	_toast.add_theme_stylebox_override("normal", _sb(Color(0.04,0.045,0.06,0.9), LINE, 1, 6, 8))
	_toast.clip_text = true
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast)
	_toast.hide()
	Game.message.connect(func(text: String, color: Color = Color.WHITE):
		_toast.text = tr(text)
		_toast.add_theme_color_override("font_color", color)
		_toast_left = 2.5)
	_inv.panel.visibility_changed.connect(_refresh_equipment)
	_touch_ready = true
	Game.inventory_changed.connect(func(): _fit_windows.call_deferred())
	Game.skills_changed.connect(func(): _fit_windows.call_deferred())
	layout_defaults()
	_sync_touch_modal()

func _button(text: String, cb: Callable, min_w := 0) -> Button:
	var button := super._button(text, cb, min_w)
	button.custom_minimum_size.y = maxf(60, button.custom_minimum_size.y)
	return button

func _window(title: String, pos: Vector2, min_size: Vector2, accent := R_BROWN, closable := true) -> Dictionary:
	var result := super._window(title, pos, Vector2(min_size.x, 0), accent, closable)
	var body: Control = result.body
	var parent := body.get_parent()
	parent.remove_child(body)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	scroll.add_child(body)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.panel.set_meta("touch_scroll", scroll)
	result.panel.set_meta("touch_body", body)
	result.panel.set_meta("touch_width", min_size.x)
	result.panel.visibility_changed.connect(func():
		if not _touch_ready or _syncing: return
		if result.panel.visible:
			_chat_panel.hide()
			_syncing = true
			for other in _popups:
				if other != result.panel: other.hide()
			_syncing = false
			_fit_windows.call_deferred()
		_sync_touch_modal())
	return result

func _setup_mobile() -> void:
	_mobile_hud = Control.new()
	_mobile_hud.set_script(preload("res://scripts/ui/mobile_hud_pc.gd"))
	_root.add_child(_mobile_hud)
	_root.move_child(_mobile_hud, 0)
	_mobile_hud.setup(self)
	_hot_panel.hide()
	_chat_panel.hide()
	for button in _menu.get_children():
		button.custom_minimum_size = Vector2(60, 60)
		for hint in button.get_children():
			if hint is Label and hint.text.length() <= 2 and hint.text != "!": hint.hide()
	_chat_input.placeholder_text = "แตะเพื่อพิมพ์แชท"

func _build_tracker() -> void:
	super._build_tracker()
	_qauto_btn.custom_minimum_size = Vector2(92, 60)
	var parent := _tracker_box.get_parent()
	parent.remove_child(_tracker_box)
	_tracker_scroll = ScrollContainer.new()
	_tracker_scroll.custom_minimum_size = Vector2(0, 60)
	_tracker_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(_tracker_scroll)
	_tracker_scroll.add_child(_tracker_box)
	_tracker_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _build_dialog() -> void:
	_dialog = _window("สนทนา", Vector2.ZERO, Vector2(740, 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_dialog.body.add_child(row)
	_dialog_face = TextureRect.new()
	_dialog_face.custom_minimum_size = Vector2(72, 72)
	_dialog_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row.add_child(_dialog_face)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	_dialog_name = _label("", 18, TITLE, true)
	column.add_child(_dialog_name)
	_dialog_text = RichTextLabel.new()
	_dialog_text.bbcode_enabled = true
	_dialog_text.fit_content = true
	_dialog_text.custom_minimum_size = Vector2(0, 54)
	_dialog_text.add_theme_font_size_override("normal_font_size", 16)
	column.add_child(_dialog_text)
	_dialog_buttons = GridContainer.new()
	_dialog_buttons.columns = 3
	_dialog_buttons.add_theme_constant_override("h_separation", 8)
	_dialog_buttons.add_theme_constant_override("v_separation", 8)
	_dialog.body.add_child(_dialog_buttons)
	_dialog.panel.hide()

func dialog(npc_name: String, text: String, choices: Array, cb: Callable) -> void:
	super.dialog(npc_name, text, choices, cb)
	for button in _dialog_buttons.get_children():
		button.custom_minimum_size = Vector2(160, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fit_windows.call_deferred()

func _layout_mobile(vp: Vector2) -> void:
	if vp.y > vp.x:
		_layout_portrait(vp)
		return
	if not is_instance_valid(_mobile_hud): return
	_mobile_hud.relayout(vp)
	_hot_panel.hide()
	_info_panel.scale = Vector2.ONE * 0.9
	_info_panel.position = Vector2(8, 8)
	var info_end := _info_panel.position + _sz(_info_panel) * _info_panel.scale
	_menu.scale = Vector2.ONE
	_menu.reset_size()
	var map_scale := 0.66 if vp.y >= 450 else 0.56
	_map_panel.scale = Vector2.ONE * map_scale
	_map_panel.position = Vector2(vp.x - 176*map_scale - 12, 6)
	_menu.position = Vector2(vp.x - 140 - _menu.get_combined_minimum_size().x, 8)
	if _menu.position.x < info_end.x + 8:
		_menu.position = Vector2(vp.x - _menu.get_combined_minimum_size().x - 8, info_end.y + 6)
		_map_panel.position.y = _menu.position.y + 62
	_pills.scale = Vector2.ONE * 0.74
	_pills.position = Vector2(info_end.x + 8, 10)
	_pills.show()
	if _pills.position.x + _sz(_pills).x * 0.74 >= _menu.position.x - 8:
		_pills.position = Vector2(_menu.position.x, _menu.position.y + 62)
	_buff_row.position = Vector2(10, info_end.y + 6)
	_party_frame.position = Vector2(8, info_end.y + 36)
	_party_frame.scale = Vector2.ONE * 0.9
	_clock.scale = Vector2.ONE * 0.88
	_clock.position = Vector2(vp.x - _sz(_clock).x * 0.88 - 8, _map_panel.position.y + 192*map_scale + 4)
	_tracker.panel.scale = Vector2.ONE
	_tracker.panel.custom_minimum_size.x = 222
	_tracker.panel.size = Vector2(222, 0)
	_tracker.panel.position = Vector2(vp.x - 230, _clock.position.y + _sz(_clock).y * 0.88 + 6)
	# Keep long quest lists within their own scrolling area.
	var header_height: float = _tracker.panel.get_combined_minimum_size().y - _tracker_scroll.get_combined_minimum_size().y
	_tracker_scroll.custom_minimum_size.y = maxf(20, minf(60, _mobile_hud.pad_top() - _tracker.panel.position.y - header_height - 8))
	for button in _map_panel.find_children("*", "Button", true, false): button.hide()
	_chat_panel.scale = Vector2.ONE
	_chat_panel.custom_minimum_size = Vector2(280, 130)
	_chat_panel.size = Vector2(minf(330, vp.x * 0.42), minf(170, vp.y * 0.42))
	_chat_panel.position = Vector2(8, vp.y - _chat_panel.size.y - 8)
	_cast_bar.position = Vector2(vp.x * 0.5 - 110, _mobile_hud.pad_top() - 24)
	if _touch_ready:
		_fit_windows()
		_mobile_hud._place_chat_btn()
		_toast.size = Vector2(minf(360, vp.x-300), 36)
		_toast.position = Vector2((vp.x-_toast.size.x)*0.5,_mobile_hud.pad_top()-44)

func _fit_windows() -> void:
	if not _touch_ready: return
	if is_instance_valid(_mobile_hud) and _mobile_hud._sc_active: return
	var vp := get_viewport().get_visible_rect().size
	_fit_touch_map(vp)
	_dialog_buttons.columns = 2 if vp.y > vp.x else 3
	for panel in _popups:
		if not panel.visible: continue
		var scroll = panel.get_meta("touch_scroll", null)
		var body = panel.get_meta("touch_body", null)
		if scroll == null or body == null: continue
		for button in panel.find_children("*", "BaseButton", true, false):
			button.custom_minimum_size.y = maxf(60, button.custom_minimum_size.y)
			button.custom_minimum_size.x = maxf(60, button.custom_minimum_size.x)
		var width := minf(float(panel.get_meta("touch_width", 640)), vp.x - 24)
		if vp.y > vp.x: width = vp.x - 24
		if vp.y > vp.x:
			_portrait_content(body, width - 36)
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		panel.scale = Vector2.ONE
		panel.custom_minimum_size = Vector2(width, 0)
		scroll.custom_minimum_size = Vector2(0, minf(maxf(80, body.get_combined_minimum_size().y), vp.y - 112))
		panel.size = Vector2(width, 0)
		panel.position = ((vp - panel.size) * 0.5).max(Vector2(8, 8))
	_sync_touch_modal()

func _sync_touch_modal() -> void:
	if not _touch_ready: return
	var active: Control
	for panel in _popups:
		if panel.visible: active = panel
	_touch_shade.visible = active != null
	_mobile_hud.set_ui_blocked(active != null)
	if active:
		_touch_shade.move_to_front()
		active.move_to_front()

func _refresh() -> void:
	super._refresh()
	var key := str(Game.appearance) + str(Game.equip) + Game.job + Game.worn_fashion()
	if key != _portrait_key and is_instance_valid(_portrait_vp):
		_portrait_key = key
		_portrait_vp.render_target_update_mode = SubViewport.UPDATE_ONCE

func _process(delta: float) -> void:
	super._process(delta)
	if not _touch_ready: return
	_toast_left = maxf(0,_toast_left-delta)
	_toast.visible = _toast_left > 0 and not _mobile_hud._ui_blocked and not _chat_panel.visible


func _refresh_equipment() -> void:
	super._refresh_equipment()
	if is_instance_valid(_equip_vp):
		_equip_vp.render_target_update_mode = SubViewport.UPDATE_ONCE if _inv.panel.visible else SubViewport.UPDATE_DISABLED

func _is_touch() -> bool:
	return true

func _build_worldmap() -> void:
	super._build_worldmap()
	var frame := _wmap_img.get_parent()
	var row := frame.get_parent()
	_touch_map_side = row.get_child(1)
	_portrait_map_row = VBoxContainer.new()
	row.get_parent().add_child(_portrait_map_row)
	frame.reparent(_portrait_map_row)
	_touch_map_side.reparent(_portrait_map_row)
	row.queue_free()
	_touch_map_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hint := _touch_map_side.get_child(0) as Label
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 0
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_touch_map_list_scroll = _touch_map_side.get_child(1)
	frame.remove_child(_wmap_img)
	_touch_map_view = Control.new()
	_touch_map_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch_map_view.clip_contents = true
	frame.add_child(_touch_map_view)
	_touch_map_view.add_child(_wmap_img)
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Keep map coordinates at 512 for clicks, pins, quest markers and world links.
	_wmap_img.size = Vector2(WMAP_PX, WMAP_PX)

func _fit_touch_map(vp: Vector2) -> void:
	if not is_instance_valid(_touch_map_view): return
	var portrait := vp.y > vp.x
	var side := floorf(maxf(180, minf(512, minf(vp.y - 128, vp.x - 310))))
	if portrait: side = minf(vp.x - 68, vp.y * 0.4)
	if is_instance_valid(_portrait_map_row): _portrait_map_row.visible = true
	_touch_map_view.custom_minimum_size = Vector2(side, side)
	_touch_map_view.size = Vector2(side, side)
	_wmap_img.scale = Vector2.ONE * side / WMAP_PX
	_touch_map_side.custom_minimum_size.x = side if portrait else 240
	_touch_map_list_scroll.custom_minimum_size = Vector2(0, minf(210, vp.y * 0.23) if portrait else side-64)
	_wmap.panel.set_meta("touch_width", minf(940, vp.x-24))


func _scale_for_short_side(_css_short: float) -> float:
	# The mobile viewport already uses touch-sized logical pixels.
	return 1.0


func _layout_portrait(vp: Vector2) -> void:
	if not is_instance_valid(_mobile_hud): return
	_mobile_hud.cancel_gestures()
	_mobile_hud.relayout(vp)
	_hot_panel.hide()
	_info_panel.scale = Vector2.ONE * 0.82
	_info_panel.position = Vector2(8, 8)
	var info_end := _info_panel.position + _sz(_info_panel) * _info_panel.scale
	_map_panel.scale = Vector2.ONE * 0.57
	_map_panel.position = Vector2(vp.x - 108, 8)
	for button in _map_panel.find_children("*", "Button", true, false): button.hide()
	_menu.scale = Vector2.ONE
	_menu.position = Vector2(8, maxf(info_end.y + 8, 110))
	var menu_width := _menu.get_combined_minimum_size().x
	if menu_width > vp.x - 16:
		_menu.scale = Vector2.ONE * (vp.x - 16) / menu_width
	_pills.scale = Vector2.ONE * 0.72
	_pills.position = Vector2(8, _menu.position.y + 62)
	_clock.scale = Vector2.ONE * 0.72
	_clock.position = Vector2(vp.x - _sz(_clock).x * 0.72 - 8, _pills.position.y)
	_buff_row.position = Vector2(8, _pills.position.y + 28)
	_party_frame.scale = Vector2.ONE * 0.74
	_party_frame.position = Vector2(8, _buff_row.position.y + 26)
	_tracker.panel.scale = Vector2.ONE
	_tracker.panel.custom_minimum_size = Vector2(244, 0)
	_tracker.panel.size = Vector2(244, 0)
	_tracker.panel.position = Vector2(vp.x - 252, _buff_row.position.y + 26)
	_tracker_scroll.custom_minimum_size.y = 48
	_qauto_btn.custom_minimum_size = Vector2(80, 48)
	_chat_panel.scale = Vector2.ONE
	_chat_panel.custom_minimum_size = Vector2(vp.x-16, 160)
	_chat_panel.size = Vector2(vp.x-16, minf(240, vp.y*0.3))
	_chat_panel.position = Vector2(8, vp.y-_chat_panel.size.y-64)
	_cast_bar.position = Vector2(vp.x*0.5-110, _mobile_hud.pad_top()-28)
	if _touch_ready:
		_fit_windows()
		_mobile_hud._place_chat_btn()
		_toast.size = Vector2(vp.x-32, 40)
		_toast.position = Vector2(16, _mobile_hud.pad_top()-54)


func _portrait_content(node: Control, width: float) -> void:
	# Convert wide split panes into a readable vertical flow on phones.
	if node is HBoxContainer and node.get_child_count() > 1 and node.get_combined_minimum_size().x > width:
		var wide := false
		for item in node.get_children():
			if item is Control and item.get_combined_minimum_size().x > width * 0.46: wide = true
		if wide:
			var column := VBoxContainer.new()
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.add_theme_constant_override("separation", 10)
			var parent := node.get_parent()
			var index := node.get_index()
			parent.add_child(column)
			parent.move_child(column, index)
			for child in node.get_children(): child.reparent(column)
			parent.remove_child(node)
			node.queue_free()
			node = column
	if node.custom_minimum_size.x > width:
		node.custom_minimum_size.x = width
	if node is RichTextLabel:
		node.custom_minimum_size.x = minf(node.custom_minimum_size.x, width)
	if node is Label and node.get_minimum_size().x > width:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if node is GridContainer:
		var cell_width := 0.0
		for child in node.get_children():
			if child is Control: cell_width = maxf(cell_width, child.get_combined_minimum_size().x)
		node.columns = mini(node.columns, maxi(1, floori(width / maxf(cell_width + 6, 1))))
	if node is TabContainer:
		node.get_tab_bar().scrolling_enabled = true
	for child in node.get_children():
		if child is Control: _portrait_content(child, width)
