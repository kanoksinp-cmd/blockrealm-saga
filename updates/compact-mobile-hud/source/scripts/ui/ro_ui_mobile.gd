extends "res://scripts/ui/ro_ui_base.gd"
## Classic desktop presentation with a touch-sized, responsive mobile layout.
var _pro_header: PanelContainer
var _pro_name: Label
var _pro_level: Label
var _pro_hp: ProgressBar
var _pro_sp: ProgressBar
var _pro_exp: ProgressBar
var _pro_hp_text: Label
var _pro_gold: Label
var _pro_party: Button
var _pro_toolbar: HBoxContainer
var _pro_quest: PanelContainer
var _pro_quest_title: Label
var _pro_quest_hint: Label
var _pro_quest_button: Button
var _pro_auto: Button
var _pro_menu: Dictionary
var _pro_action := {}
var _pro_tick := 0.0
var _pro_auto_state := -1
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
	_build_pro_hud()
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
	if is_instance_valid(_pro_header):
		_pro_menu.panel.hide()
		for panel in [_pro_header,_pro_toolbar,_pro_quest,_pro_gold]: panel.hide()
		for panel in [_info_panel,_menu,_clock,_tracker.panel]: panel.show()
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
	_pro_tick -= delta
	if get_viewport().get_visible_rect().size.y > get_viewport().get_visible_rect().size.x:
		for panel in [_info_panel,_menu,_pills,_clock,_tracker.panel,_party_frame]: panel.hide()
		if _pro_tick <= 0.0:
			_pro_tick = 0.2
			_refresh_pro_hud()
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
	for panel in [_hot_panel,_info_panel,_menu,_pills,_clock,_tracker.panel,_party_frame]: panel.hide()
	_map_panel.scale = Vector2.ONE * 0.54
	_map_panel.position = Vector2(vp.x-108, 10)
	for button in _map_panel.find_children("*", "Button", true, false): button.hide()
	_buff_row.position = Vector2(12, 262)
	_buff_row.scale = Vector2.ONE * 0.8
	if is_instance_valid(_pro_header):
		_pro_header.show()
		_pro_toolbar.show()
		_pro_quest.show()
		_pro_header.position = Vector2(12, 12)
		_pro_header.custom_minimum_size = Vector2(vp.x-136, 78)
		_pro_header.size = Vector2(vp.x-136, 78)
		_pro_toolbar.position = Vector2(12, 100)
		_pro_quest.position = Vector2(12, 174)
		_pro_quest.custom_minimum_size = Vector2(vp.x-24, 68)
		_pro_quest.size = Vector2(vp.x-24, 68)
		_pro_gold.position = Vector2(vp.x-118, 119)
		_pro_gold.size = Vector2(106, 28)
		_pro_gold.show()
	_chat_panel.scale = Vector2.ONE
	_chat_panel.custom_minimum_size = Vector2(vp.x-16, 160)
	_chat_panel.size = Vector2(vp.x-16, minf(240, vp.y*0.3))
	_chat_panel.position = Vector2(8, vp.y-_chat_panel.size.y-66)
	_cast_bar.position = Vector2(vp.x*0.5-110, vp.y-290)
	if _touch_ready:
		_fit_windows()
		_mobile_hud._place_chat_btn()
		_toast.size = Vector2(vp.x-40, 36)
		_toast.position = Vector2(20, vp.y-322)
		_refresh_pro_hud()


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


func _pro_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _sb(Color(0.035,0.05,0.075,0.86), Color(0.64,0.54,0.34,0.6), 1, 12, 10))
	_root.add_child(panel)
	return panel

func _pro_bar(color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0,height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _sb(Color(0.01,0.015,0.025,0.8), Color.TRANSPARENT, 0, 4, 0))
	bar.add_theme_stylebox_override("fill", _sb(color, Color.TRANSPARENT, 0, 4, 0))
	return bar

func _pro_icon_button(icon: String, hint: String, action: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(60,60)
	button.icon = UiIcons.tex(icon, 2) if icon != "menu" else null
	if icon == "menu":
		button.draw.connect(func():
			var center := button.size * 0.5
			for i in 3:
				var y := float(i-1)*7.0
				button.draw_line(center+Vector2(-11,y),center+Vector2(11,y),CREAM,2.0,true))
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 26)
	button.tooltip_text = hint
	button.add_theme_stylebox_override("normal", _sb(Color(0.035,0.05,0.075,0.80),Color(0.6,0.52,0.36,0.48),1,16,12))
	button.add_theme_stylebox_override("pressed", _sb(Color(0.2,0.17,0.1,0.95),GOLD,1,16,12))
	button.pressed.connect(action)
	return button

func _build_pro_hud() -> void:
	_pro_header = _pro_panel()
	_pro_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	_pro_header.add_child(row)
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)
	var face := TextureRect.new()
	face.texture = _portrait_vp.get_texture()
	face.custom_minimum_size = Vector2(48,48)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	left.add_child(face)
	_pro_level = _label("",10,GOLD,true)
	_pro_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_pro_level)
	var stats := VBoxContainer.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("separation",4)
	row.add_child(stats)
	_pro_name = _label("",18,CREAM,true)
	_pro_name.clip_text = true
	_pro_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stats.add_child(_pro_name)
	_pro_hp = _pro_bar(Color("cc4552"),16)
	stats.add_child(_pro_hp)
	_pro_hp_text = _label("",11,Color.WHITE,true)
	_pro_hp_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pro_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pro_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pro_hp.add_child(_pro_hp_text)
	_pro_sp = _pro_bar(Color("438bca"),7)
	stats.add_child(_pro_sp)
	_pro_exp = _pro_bar(Color("d9b76b"),3)
	stats.add_child(_pro_exp)
	_pro_toolbar = HBoxContainer.new()
	_pro_toolbar.add_theme_constant_override("separation",8)
	_root.add_child(_pro_toolbar)
	_pro_toolbar.add_child(_pro_icon_button("menu","เมนู",func():toggle(_pro_menu.panel)))
	_pro_toolbar.add_child(_pro_icon_button("bag","กระเป๋า",func():toggle(_inv.panel)))
	_pro_toolbar.add_child(_pro_icon_button("star","สกิล",func():toggle(_skills.panel)))
	_pro_party = _button("ปาร์ตี้",func():open_party(0))
	_pro_party.custom_minimum_size = Vector2(100,60)
	_pro_party.add_theme_font_size_override("font_size",13)
	_pro_party.add_theme_stylebox_override("normal",_sb(Color(0.035,0.05,0.075,0.8),Color(0.6,0.52,0.36,0.48),1,16,8))
	_pro_toolbar.add_child(_pro_party)
	_pro_gold = _label("",12,GOLD,true)
	_pro_gold.clip_text = true
	_pro_gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pro_gold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_pro_gold)
	_pro_quest = _pro_panel()
	var quest_row := HBoxContainer.new()
	quest_row.add_theme_constant_override("separation",8)
	_pro_quest.add_child(quest_row)
	_pro_quest_button = Button.new()
	_pro_quest_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pro_quest_button.custom_minimum_size.y = 52
	for state in ["normal","hover","pressed","focus"]: _pro_quest_button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	quest_row.add_child(_pro_quest_button)
	var copy := VBoxContainer.new()
	copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation",4)
	_pro_quest_button.add_child(copy)
	_pro_quest_title = _label("",16,TITLE,true)
	_pro_quest_title.clip_text = true
	_pro_quest_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_pro_quest_title)
	_pro_quest_hint = _label("",12,INK_L)
	_pro_quest_hint.clip_text = true
	_pro_quest_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_pro_quest_hint)
	_pro_quest_button.pressed.connect(func():
		if _pro_action.is_empty(): toggle(_quests.panel)
		else: _quest_go(_pro_action))
	_pro_auto = _button("AUTO",func(): _qauto_btn.button_pressed = not _qauto_btn.button_pressed)
	_pro_auto.custom_minimum_size = Vector2(60,60)
	_pro_auto.add_theme_font_size_override("font_size",12)
	quest_row.add_child(_pro_auto)
	_pro_menu = _window("เมนูการผจญภัย",Vector2.ZERO,Vector2(440,0))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	_pro_menu.body.add_child(grid)
	var names := ["ตัวละคร","กระเป๋า","สกิล","เควส","แผนที่","ตั้งค่า"]
	var icons := ["hero","bag","star","scroll","map","gear"]
	for i in 6:
		var original: Button = _menu.get_child(i)
		var button := _button(names[i],func():
			_pro_menu.panel.hide()
			original.pressed.emit())
		button.icon = UiIcons.tex(icons[i],2)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",32)
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.custom_minimum_size = Vector2(120,100)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(button)
	_pro_menu.panel.hide()
	for panel in [_pro_header,_pro_toolbar,_pro_quest,_pro_gold]: panel.hide()

func _refresh_pro_hud() -> void:
	if not is_instance_valid(_pro_header): return
	_pro_name.text = _name_lbl.text
	_pro_level.text = "Lv.%d" % Game.base_level
	for pair in [[_pro_hp,_hp_bar],[_pro_sp,_sp_bar],[_pro_exp,_exp_bar]]:
		pair[0].max_value = pair[1].max_value
		pair[0].value = pair[1].value
	_pro_hp_text.text = "%d / %d" % [Game.hp,Game.max_hp()]
	_pro_gold.text = "●  "+_zeny_lbl.text
	_pro_party.text = "ปาร์ตี้ · %d" % Game.party.size()
	var entries := _quest_entries()
	var selected: Array = []
	for entry in entries:
		if not entry[5]:
			if selected.is_empty() or str(entry[1]).begins_with("บท"):
				selected = entry
				if str(entry[1]).begins_with("บท"): break
	_pro_action = {}
	if selected.is_empty():
		_pro_quest_title.text = "การผจญภัยของคุณ"
		_pro_quest_hint.text = "แตะเพื่อเปิดสมุดเควส"
	else:
		_pro_quest_title.text = str(selected[1])
		_pro_quest_hint.text = str(selected[2])+"  "+str(selected[3])
		if selected.size()>6: _pro_action = selected[6]
	_pro_auto.text = "หยุด" if _qauto_btn.button_pressed else "AUTO"
	var auto_state := int(_qauto_btn.button_pressed)
	if auto_state != _pro_auto_state:
		_pro_auto_state = auto_state
		_color_button(_pro_auto, BTN_GREEN if _qauto_btn.button_pressed else PARCH_D)
