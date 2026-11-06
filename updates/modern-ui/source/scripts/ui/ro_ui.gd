extends "res://scripts/ui/ro_ui_base.gd"
## Shared responsive interface. Gameplay, accounts and progression use existing APIs.
const SURFACE := Color("171d26")
const EDGE := Color("79684b")
const TEXT := Color("f2eee5")
const MUTED := Color("c4cbd5")
const EMPHASIS := Color("d3b376")
var _modern_ready := false
var _shade: ColorRect
var _modal: Control
var _menu_box: Dictionary
var _inspect: Dictionary
var _inspect_body: VBoxContainer
var _character_tabs: TabContainer
var _fashion_list: VBoxContainer
var _bag_detail: VBoxContainer
var _bag_search: LineEdit
var _bag_selected := ""
var _bag_sort := 0
var _quest_kind := 0
var _quest_selected := 0
var _quest_detail: VBoxContainer
var _journal_tabs: Array[Button] = []
var _journal_entries: Array = []
var _refine_slot := "weapon"
var _shop_detail: VBoxContainer
var _shop_selected := ""
var _shop_quantity: SpinBox
var _shop_total: Label
var _shop_trade: Button
var _shop_category := ""
var _party_collapsed := false
var _party_toggle: Button
var _location: Button
var _death: PanelContainer
var _death_text: Label
var _last_dead := false
var _tick := 0.0
var _toast_box: VBoxContainer
var _toast_items: Array = []
var _last_toast := ""
var _last_toast_at := 0
var _modal_busy := false

func _adaptive_row() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "AdaptiveColumns"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	return grid

func _ready() -> void:
	super._ready()
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_shade = ColorRect.new()
	_shade.color = Color(0.015, 0.02, 0.03, 0.48)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_shade)
	_shade.hide()
	_menu_box = _window("เมนู", Vector2.ZERO, Vector2(470, 360))
	var menus := [["ตัวละคร / อุปกรณ์ / แฟชั่น", func(): toggle(_status.panel)],
		["กระเป๋า", func(): toggle(_inv.panel)], ["สกิลและอาชีพ", func(): toggle(_skills.panel)],
		["บันทึกเควส", func(): toggle(_quests.panel)], ["แผนที่", func(): toggle(_wmap.panel)],
		["ปาร์ตี้", func(): open_party()], ["สำนักงานกิลด์", func(): open_guild_board()],
		["ตั้งค่าออโต้", func(): toggle(_autoset.panel)], ["แชท", _show_chat],
		["ตั้งค่า / บัญชีเกม", func(): toggle(_settings.panel)]]
	for entry in menus:
		_menu_box.body.add_child(_button(entry[0], entry[1]))
	_menu_box.panel.hide()
	_inspect = _window("รายละเอียดไอเทม", Vector2.ZERO, Vector2(500, 410))
	_inspect_body = _inspect.body
	_inspect.panel.hide()
	_location = _button("", func(): toggle(_wmap.panel))
	_location.add_theme_font_size_override("font_size", 12)
	_location.clip_text = true
	_location.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_root.add_child(_location)
	_windows.append(_location)
	_party_toggle = _button("ปาร์ตี้ ▾", func():
		_party_collapsed = not _party_collapsed
		_party_toggle.text = "ปาร์ตี้ ▸" if _party_collapsed else "ปาร์ตี้ ▾"
		_refresh_party_frame())
	_party_toggle.add_theme_font_size_override("font_size", 11)
	_root.add_child(_party_toggle)
	_windows.append(_party_toggle)
	_toast_box = VBoxContainer.new()
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_theme_constant_override("separation", 6)
	_root.add_child(_toast_box)
	_build_death_notice()
	_modern_ready = true
	layout_defaults()
	_sync_settings_controls()
	_refresh_fashion()

func _pixel_box(_base: Color, border := 2, _noise := 0.0, margin := 8) -> StyleBoxFlat:
	var s := _sb(Color(SURFACE, 0.97 if border >= 2 else 0.92), EDGE if border >= 2 else Color(EDGE, 0.45), 1, 10, margin)
	s.shadow_size = 0 if _mobile else 5
	s.shadow_color = Color(0, 0, 0, 0.2)
	return s

func _make_theme() -> Theme:
	var theme := super._make_theme()
	theme.default_font_size = 14
	for typ in ["Label", "Button", "OptionButton", "LineEdit"]:
		theme.set_color("font_color", typ, TEXT)
	theme.set_constant("separation", "VBoxContainer", 8)
	theme.set_constant("separation", "HBoxContainer", 8)
	theme.set_color("font_disabled_color", "Button", Color("818997"))
	return theme

func _btn_style(state: String, base := PARCH_D, margin := 10) -> StyleBoxFlat:
	var bg := SURFACE.lightened(0.09)
	var edge := Color(EDGE, 0.55)
	if state == "hover":
		bg = SURFACE.lightened(0.16)
		edge = EMPHASIS
	elif state == "pressed":
		bg = Color("55462d")
		edge = EMPHASIS
	elif state == "disabled":
		bg = SURFACE.darkened(0.15)
		edge = Color(EDGE, 0.25)
	return _sb(bg, edge, 1, 7, margin)

func _button(text: String, cb: Callable, min_w := 0) -> Button:
	var b := super._button(text, cb, min_w)
	b.custom_minimum_size.y = 36 if _mobile else 32
	b.add_theme_font_size_override("font_size", 14)
	b.focus_mode = Control.FOCUS_ALL
	b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	b.tooltip_text = tr(text)
	return b

func _bar(fill: Color, h := 16, icon := "") -> Dictionary:
	var result := super._bar(fill, h, icon)
	result.bar.add_theme_stylebox_override("background", _sb(Color(0, 0, 0, 0.4), Color.TRANSPARENT, 0, 4, 0))
	result.bar.add_theme_stylebox_override("fill", _sb(fill, Color.TRANSPARENT, 0, 4, 0))
	return result

func _window(title: String, _pos: Vector2, min_size: Vector2, _accent := R_BROWN, closable := true) -> Dictionary:
	var p := PanelContainer.new()
	p.name = "Window_" + str(_popups.size())
	p.add_theme_stylebox_override("panel", _pixel_box(SURFACE, 2, 0, 14))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.set_meta("preferred_width", maxf(500, min_size.x + 28))
	p.set_meta("preferred_height", 580.0)
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", 10)
	p.add_child(frame)
	var head := HBoxContainer.new()
	var name_label := _label(title, 20, TEXT, true)
	name_label.name = "Text"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(name_label)
	if closable:
		var close := _button("ปิด", p.hide, 52)
		close.name = "Close"
		close.custom_minimum_size = Vector2(42, 40)
		close.tooltip_text = "ปิด / Esc"
		close.add_theme_font_size_override("font_size", 14)
		head.add_child(close)
	frame.add_child(head)
	frame.add_child(HSeparator.new())
	var sc := ScrollContainer.new()
	sc.name = "ContentScroll"
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.follow_focus = true
	frame.add_child(sc)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	sc.add_child(body)
	var footer := HBoxContainer.new()
	footer.name = "Footer"
	footer.alignment = BoxContainer.ALIGNMENT_END
	frame.add_child(footer)
	_root.add_child(p)
	_windows.append(p)
	_popups.append(p)
	p.visibility_changed.connect(func(): _modal_changed(p))
	p.hide()
	return {"panel": p, "body": body, "title": name_label, "scroller": sc, "footer": footer}

func _modal_changed(panel: Control) -> void:
	if not _modern_ready or _modal_busy:
		return
	_modal_busy = true
	if panel.visible:
		for other in _popups:
			if other != panel and other.visible:
				other.hide()
		_modal = panel
		_shade.show()
		_shade.move_to_front()
		panel.move_to_front()
		if panel == _status.panel:
			_refresh_status()
			_refresh_equipment()
			_refresh_fashion()
		elif panel == _inv.panel: _refresh_inventory()
	else:
		if panel == _modal:
			_modal = null
		_shade.hide()
	_reset_input()
	_modal_busy = false
	_fit_windows()
	_update_play_controls()

func _reset_input() -> void:
	if is_instance_valid(_mobile_hud) and _mobile_hud.has_method("cancel_gestures"):
		_mobile_hud.cancel_gestures()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set("attack_target", null)
		if player.has_method("cancel_walk"): player.cancel_walk()
	Game.set_meta("cam_gesture", false)

func _update_play_controls() -> void:
	var blocked := is_instance_valid(_modal) and _modal.visible
	if is_instance_valid(_mobile_hud):
		_mobile_hud.set_ui_blocked(blocked or _last_dead)
	_hot_panel.visible = not _mobile and not blocked and not _last_dead
	if blocked:
		_chat_panel.hide()

func toggle(c: Control) -> void:
	if c == _chat_panel:
		_show_chat()
		return
	super.toggle(c)
	_fit_windows()

func _build_menu() -> void:
	_menu = HBoxContainer.new()
	_menu.add_theme_constant_override("separation", 6)
	_root.add_child(_menu)
	for entry in [["hero", "ตัวละคร", func(): toggle(_status.panel)],
		["bag", "กระเป๋า", func(): toggle(_inv.panel)], ["star", "สกิล", func(): toggle(_skills.panel)],
		["gear", "เมนู", func(): toggle(_menu_box.panel)]]:
		var b := _button(entry[1], entry[2], 92)
		b.custom_minimum_size.y = 48
		b.icon = _menu_art(entry[0])
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 22)
		b.add_theme_font_size_override("font_size", 12)
		_menu.add_child(b)
		_windows.append(b)
		if entry[0] == "star":
			_skill_badge = _label("•", 21, EMPHASIS, true)
			_skill_badge.position = Vector2(78, -6)
			_skill_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(_skill_badge)

func _build_info() -> void:
	super._build_info()
	_name_lbl.custom_minimum_size.x = 110
	_name_lbl.size_flags_stretch_ratio = 3.0
	_job_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
	_job_lbl.custom_minimum_size.x = 58
	_name_lbl.tooltip_text = Game.player_name
	_hp_bar.custom_minimum_size.y = 16
	_sp_bar.custom_minimum_size.y = 14
	_exp_bar.custom_minimum_size.y = 7
	_portrait_vp.render_target_update_mode = SubViewport.UPDATE_ONCE

func _build_status() -> void:
	super._build_status()
	_status.title.text = "ตัวละคร / อุปกรณ์ / แฟชั่น"
	_status.panel.set_meta("preferred_width", 820.0)
	var content: Control = _status.body.get_child(0)
	var values: Control = content.get_child(1)
	values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(values.get_child(0) as GridContainer).columns = 8
	_status.body.remove_child(content)
	_character_tabs = TabContainer.new()
	_character_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.body.add_child(_character_tabs)
	var page := VBoxContainer.new()
	page.name = "สถานะ"
	_character_tabs.add_child(page)
	page.add_child(content)
	_character_tabs.tab_changed.connect(func(_i):
		_status_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		if is_instance_valid(_equip_vp): _equip_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		_refresh_fashion())

func _build_inventory() -> void:
	_inv = _window("กระเป๋า", Vector2.ZERO, Vector2(870, 0))
	var equipped := VBoxContainer.new()
	equipped.name = "อุปกรณ์"
	_character_tabs.add_child(equipped)
	_build_equipment(equipped)
	_equip = _status
	var fashion := VBoxContainer.new()
	fashion.name = "แฟชั่น"
	_character_tabs.add_child(fashion)
	fashion.add_child(_label("เลือกชุดเพื่อดูค่าสถานะ วัตถุดิบ และการสวมใส่", 13, MUTED))
	_fashion_list = VBoxContainer.new()
	fashion.add_child(_fashion_list)
	_bag_search = LineEdit.new()
	_bag_search.placeholder_text = "ค้นหาชื่อไอเทม…"
	_bag_search.custom_minimum_size.y = 38
	_bag_search.text_changed.connect(func(_s): _refresh_inventory())
	var search_row := HBoxContainer.new()
	_bag_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_row.add_child(_bag_search)
	var sort := OptionButton.new()
	for label in ["ชื่อ ก→ฮ", "จำนวนมากก่อน", "ประเภทไอเทม"]: sort.add_item(label)
	sort.item_selected.connect(func(index):
		_bag_sort = index
		_refresh_inventory())
	search_row.add_child(sort)
	_inv.body.add_child(search_row)
	var tabs := HFlowContainer.new()
	for i in INV_TABS.size():
		var b := _button(INV_TABS[i][0], func():
			_inv_tab = i
			_refresh_inventory(), 90)
		tabs.add_child(b)
		_inv_tabs.append(b)
	_inv.body.add_child(tabs)
	var row := _adaptive_row()
	_inv.body.add_child(row)
	_inv_grid = GridContainer.new()
	_inv_grid.columns = 5
	_inv_grid.add_theme_constant_override("h_separation", 6)
	_inv_grid.add_theme_constant_override("v_separation", 6)
	row.add_child(_inv_grid)
	_bag_detail = VBoxContainer.new()
	_bag_detail.custom_minimum_size.x = 255
	_bag_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_bag_detail)
	var foot: HBoxContainer = _inv.footer
	_inv_footer = _label("", 12, MUTED)
	_inv_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_inv_footer)
	_inv_zeny = _label("", 14, EMPHASIS, true)
	foot.add_child(_inv_zeny)
	_inv.panel.hide()
	_refresh_inventory()

func _refresh_inventory() -> void:
	if _inv.is_empty() or not is_instance_valid(_inv_grid): return
	if _modern_ready and not _inv.panel.visible:
		_refresh_hotbar()
		_refresh_equipment()
		return
	for i in _inv_tabs.size(): _set_tab(_inv_tabs[i], i == _inv_tab)
	_clear(_inv_grid)
	var want: String = INV_TABS[_inv_tab][1]
	var ids: Array[String] = []
	var query := _bag_search.text.strip_edges().to_lower() if _bag_search else ""
	for id in Game.inventory:
		if (want == "" or Items.info(id).type in want.split(",")) and (query == "" or Items.item_name(id).to_lower().contains(query)):
			ids.append(id)
	ids.sort_custom(func(a, b):
		if _bag_sort == 1 and Game.count(a) != Game.count(b): return Game.count(a) > Game.count(b)
		if _bag_sort == 2 and Items.info(a).type != Items.info(b).type: return String(Items.info(a).type) < String(Items.info(b).type)
		return Items.item_name(a) < Items.item_name(b))
	if _bag_selected == "" and not ids.is_empty(): _bag_selected = ids[0]
	for id in ids:
		var b := _slot(58)
		b.icon = Items.icon(id)
		b.tooltip_text = _item_tip(id)
		b.add_theme_stylebox_override("normal", _slot_style(id == _bag_selected))
		_count_label(b, str(Game.count(id)))
		b.pressed.connect(func():
			_bag_selected = id
			_refresh_inventory())
		_inv_grid.add_child(b)
	if not ids.is_empty():
		for i in maxi(0, 20 - ids.size()):
			var empty := _slot(58)
			empty.disabled = true
			_inv_grid.add_child(empty)
	if ids.is_empty(): _inv_grid.add_child(_label("ไม่พบไอเทม", 14, MUTED))
	_inv_footer.text = "%d ชนิด · น้ำหนัก %d / %d" % [Game.inventory.size(), Game.weight() / 10, Game.max_weight() / 10]
	_inv_zeny.text = _commas(Game.zeny) + " Zeny"
	_show_item_detail(_bag_detail, _bag_selected if Game.count(_bag_selected) > 0 else "")
	_refresh_hotbar()
	_refresh_equipment()
	_refresh_fashion()

func _show_item_detail(box: VBoxContainer, id: String, slot := "") -> void:
	_clear(box)
	if id == "":
		box.add_child(_label("เลือกไอเทมเพื่อดูรายละเอียด", 15, MUTED))
		return
	var top := HBoxContainer.new()
	top.add_child(_icon_rect(Items.icon(id), 60))
	var name_label := _label(Game.item_label(id), 17, TEXT, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	box.add_child(top)
	var info := _label(_item_tip(id), 13, MUTED)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = 225
	box.add_child(info)
	if Items.is_gear(id):
		box.add_child(HSeparator.new())
		var compare := _label("เทียบกับที่สวมอยู่\n" + _compare_text(id), 13, TEXT)
		compare.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(compare)
	var action := "ถอดอุปกรณ์" if slot != "" else ("สวมใส่" if Items.is_gear(id) else "ใช้ไอเทม")
	var usable: bool = slot != "" or Items.is_gear(id) or Items.info(id).get("type", "") == "use"
	if usable:
		var use := _button(action, func():
			if slot != "": Game.unequip(slot)
			else: Game.use_item(id)
			_refresh_inventory()
			if not _inspect.is_empty(): _inspect.panel.hide())
		_color_button(use, Color("655333"))
		box.add_child(use)

func _item_menu(id: String, _anchor: Control, equipped_slot := "") -> void:
	if _inspect.is_empty(): return
	_show_item_detail(_inspect_body, id, equipped_slot)
	_inspect.panel.show()

func _is_touch() -> bool:
	return true # One selection opens details on desktop and touch alike.

func _refresh_fashion() -> void:
	if not is_instance_valid(_fashion_list): return
	if _modern_ready and (not _status.panel.visible or _character_tabs.current_tab != 2): return
	_clear(_fashion_list)
	for fid in Game.FASHION_ORDER:
		if not Game.fashion_job_ok(fid): continue
		var data: Dictionary = Game.FASHIONS[fid]
		var row := HBoxContainer.new()
		row.add_child(_icon_rect(Items.icon(data.recipe.id), 48))
		var title := _label(String(data.name), 14, TEXT, true)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(title)
		row.add_child(_button("สวมอยู่" if Game.worn_fashion() == fid else ("ดู / สวมใส่" if Game.owns_fashion(fid) else "วิธีคราฟ"), _fashion_detail.bind(fid), 110))
		_fashion_list.add_child(row)

func _refresh_equipment() -> void:
	if _modern_ready and not _status.panel.visible: return
	super._refresh_equipment()
	if is_instance_valid(_equip_vp) and not _status.is_empty() and _status.panel.visible:
		_equip_vp.render_target_update_mode = SubViewport.UPDATE_ONCE

func _refresh_status() -> void:
	if _modern_ready and not _status.panel.visible: return
	super._refresh_status()

func _open_mage_fashion(_page := 0) -> void:
	_character_tabs.current_tab = 2
	_refresh_fashion()
	_status.panel.show()

func _build_dialog() -> void:
	_dialog = _window("สนทนา", Vector2.ZERO, Vector2(690, 0))
	_dialog.panel.set_meta("preferred_height", 390.0)
	var row := HBoxContainer.new()
	_dialog_face = _icon_rect(null, 64)
	row.add_child(_dialog_face)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	_dialog_name = _label("", 18, EMPHASIS, true)
	text_column.add_child(_dialog_name)
	_dialog_text = RichTextLabel.new()
	_dialog_text.bbcode_enabled = true
	_dialog_text.fit_content = true
	_dialog_text.custom_minimum_size.y = 60
	_dialog_text.scroll_active = false
	_dialog_text.add_theme_font_size_override("normal_font_size", 15)
	text_column.add_child(_dialog_text)
	_dialog.body.add_child(row)
	_dialog_buttons = GridContainer.new()
	_dialog_buttons.columns = 3
	_dialog_buttons.add_theme_constant_override("h_separation", 8)
	_dialog_buttons.add_theme_constant_override("v_separation", 8)
	_dialog.body.add_child(_dialog_buttons)
	_dialog.panel.hide()

func dialog(npc_name: String, text: String, choices: Array, cb: Callable) -> void:
	super.dialog(npc_name, text, choices, cb)
	_dialog.title.text = "บริการ / สนทนา"
	for child in _dialog_buttons.get_children():
		child.custom_minimum_size = Vector2(140, 42)
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialog_buttons.columns = mini(3, maxi(1, choices.size()))
	_fit_windows()

func _build_shop() -> void:
	_shop = _window("ร้านค้า NPC", Vector2.ZERO, Vector2(790, 0))
	var tabs := HBoxContainer.new()
	for buy in [true, false]:
		var b := _button("ซื้อ" if buy else "ขาย", func():
			_shop_buy = buy
			_shop_selected = ""
			_fill_shop(), 110)
		_shop_tabs.append(b)
		tabs.add_child(b)
	_shop.body.add_child(tabs)
	var category := OptionButton.new()
	var choices := [["ทั้งหมด", ""], ["ยา / ของใช้", "use"], ["อาวุธ / อุปกรณ์", "weapon,armor"], ["วัตถุดิบ", "etc"]]
	for option in choices: category.add_item(option[0])
	category.item_selected.connect(func(index):
		_shop_category = choices[index][1]
		_fill_shop())
	tabs.add_child(category)
	var row := _adaptive_row()
	_shop.body.add_child(row)
	_shop_grid = GridContainer.new()
	_shop_grid.columns = 3
	_shop_grid.add_theme_constant_override("h_separation", 8)
	_shop_grid.add_theme_constant_override("v_separation", 8)
	row.add_child(_shop_grid)
	_shop_detail = VBoxContainer.new()
	_shop_detail.custom_minimum_size.x = 250
	_shop_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_shop_detail)
	_shop_zeny = _label("", 15, EMPHASIS, true)
	_shop.footer.add_child(_shop_zeny)
	_shop.panel.hide()

func _fill_shop() -> void:
	if _shop.is_empty(): return
	for i in _shop_tabs.size(): _set_tab(_shop_tabs[i], (i == 0) == _shop_buy)
	_clear(_shop_grid)
	_clear(_shop_detail)
	_shop_zeny.text = "เงินคงเหลือ " + _commas(Game.zeny) + " Zeny"
	var candidates: Array = _shop_stock if _shop_buy else Game.inventory.keys()
	var ids := candidates.filter(func(id): return _shop_category == "" or Items.info(id).type in _shop_category.split(","))
	if not ids.has(_shop_selected): _shop_selected = String(ids[0]) if not ids.is_empty() else ""
	for id in ids:
		var b := _button(Items.item_name(id), func():
			_shop_selected = id
			_fill_shop(), 94)
		b.custom_minimum_size = Vector2(94, 82)
		b.icon = Items.icon(id)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 38)
		b.add_theme_font_size_override("font_size", 12)
		_set_tab(b, id == _shop_selected)
		_shop_grid.add_child(b)
	if _shop_selected == "":
		_shop_detail.add_child(_label("ไม่มีไอเทมในหมวดนี้", 15, MUTED))
		return
	_shop_detail.add_child(_icon_rect(Items.icon(_shop_selected), 68))
	var description := _label(_item_tip(_shop_selected), 14, TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shop_detail.add_child(description)
	_shop_detail.add_child(_label("จำนวน", 13, MUTED))
	_shop_quantity = SpinBox.new()
	_shop_quantity.min_value = 1
	_shop_quantity.max_value = 9999 if _shop_buy else maxi(1, Game.count(_shop_selected))
	_shop_quantity.custom_minimum_size.y = 40
	_shop_quantity.value = 1
	_shop_detail.add_child(_shop_quantity)
	_shop_total = _label("", 15, EMPHASIS, true)
	_shop_detail.add_child(_shop_total)
	_shop_trade = _button("ซื้อ" if _shop_buy else "ขาย", _request_shop_trade)
	_color_button(_shop_trade, Color("655333"))
	_shop_detail.add_child(_shop_trade)
	_shop_quantity.value_changed.connect(func(_v): _refresh_trade_total())
	_refresh_trade_total()

func _refresh_trade_total() -> void:
	var price: int = Game.buy_price(_shop_selected) if _shop_buy else Game.sell_price(_shop_selected)
	var total := price * int(_shop_quantity.value)
	_shop_total.text = "ราคารวม " + _commas(total) + " Zeny"
	_shop_trade.disabled = _shop_buy and Game.zeny < total
	_shop_trade.tooltip_text = "เงินไม่เพียงพอ" if _shop_trade.disabled else ("ยืนยันซื้อ" if _shop_buy else "ยืนยันขาย")

func _request_shop_trade() -> void:
	_shop_quantity.apply()
	var id := _shop_selected
	var quantity := int(_shop_quantity.value)
	if _shop_buy:
		_trade_shop_item(id, quantity)
		return
	var total: int = Game.sell_price(id) * quantity
	dialog("ยืนยันขายไอเทม", "%s ×%d\nได้รับ %s Zeny\nไอเทมที่ขายจะถูกนำออกจากกระเป๋า" % [Items.item_name(id), quantity, _commas(total)], ["ยืนยันขาย", "ยกเลิก"], func(index):
		if index == 0: _trade_shop_item(id, quantity)
		_shop.panel.show())

func _build_smith() -> void:
	_smith = _window("โรงตีเหล็ก", Vector2.ZERO, Vector2(900, 0))
	var tabs := HFlowContainer.new()
	for entry in [["ตีบวก", 0], ["อาวุธ", 1], ["หมวก", 8], ["เกราะ", 9], ["เครื่องประดับ", 10], ["ปีก", 2], ["แฟชั่น", 7], ["วัสดุ", 6]]:
		var b := _button(entry[0], func():
			_smith_tab = entry[1]
			_fill_smith(), 90)
		b.set_meta("tab", entry[1])
		tabs.add_child(b)
		_smith_tabs.append(b)
	_smith.body.add_child(tabs)
	_smith_list = VBoxContainer.new()
	_smith_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_smith.body.add_child(_smith_list)
	_smith_msg = _label("", 13, EMPHASIS)
	_smith_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_smith.body.add_child(_smith_msg)
	_smith_zeny = _label("", 14, EMPHASIS, true)
	_smith.footer.add_child(_smith_zeny)
	_smith.panel.hide()

func _fill_smith() -> void:
	if _smith.is_empty(): return
	for child in _smith.footer.get_children():
		if child != _smith_zeny:
			_smith.footer.remove_child(child)
			child.queue_free()
	if _smith_tab != 0:
		super._fill_smith()
		return
	for b in _smith_tabs: _set_tab(b, int(b.get_meta("tab")) == 0)
	_smith_zeny.text = _commas(Game.zeny) + " Zeny"
	_clear(_smith_list)
	var row := _adaptive_row()
	_smith_list.add_child(row)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 240
	row.add_child(list)
	list.add_child(_label("อุปกรณ์ที่สวมอยู่", 16, EMPHASIS, true))
	var slots: Array[String] = []
	for slot in Items.SLOTS:
		var id: String = Game.equip.get(slot, "")
		if id == "": continue
		slots.append(slot)
		var b := _button(Game.item_label(id), func():
			_refine_slot = slot
			_fill_smith(), 220)
		b.icon = Items.icon(id)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 34)
		b.custom_minimum_size.y = 52
		_set_tab(b, _refine_slot == slot)
		list.add_child(b)
	var detail := VBoxContainer.new()
	detail.custom_minimum_size.x = 300
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	if slots.is_empty():
		detail.add_child(_label("สวมอุปกรณ์ก่อนเลือกตีบวก", 16, MUTED))
		return
	if not slots.has(_refine_slot): _refine_slot = slots[0]
	var id: String = Game.equip[_refine_slot]
	var level: int = Game.refine_lv(id)
	detail.add_child(_icon_rect(Items.icon(id), 64))
	detail.add_child(_label(Game.item_label(id), 19, TEXT, true))
	detail.add_child(_label("ระดับปัจจุบัน +%d" % level, 15, MUTED))
	if level >= Game.REFINE_MAX:
		detail.add_child(_label("ตีบวกถึงระดับสูงสุดแล้ว", 15, EMPHASIS))
		return
	var check := CheckBox.new()
	check.text = "ใช้หินการันตี · มี %d" % Game.count("guarantee_stone")
	check.button_pressed = _guaranteed_refine
	check.toggled.connect(func(on):
		_guaranteed_refine = on
		_fill_smith())
	detail.add_child(check)
	var chance: int = 100 if _guaranteed_refine else Game.refine_chance(id)
	detail.add_child(_label("ถัดไป +%d · โอกาสสำเร็จ %d%%" % [level + 1, chance], 16, EMPHASIS, true))
	var stat := "ATK" if _refine_slot == "weapon" else "DEF"
	detail.add_child(_label("%s +%d → +%d" % [stat, Game.refine_bonus(id), Game.refine_bonus(id, level + 1)], 15, TEXT))
	detail.add_child(_mat_row(Game.refine_stone(id), Game.refine_stones(id)))
	detail.add_child(_label("ค่าใช้จ่าย %s Zeny" % _commas(Game.refine_cost(id)), 15, MUTED))
	detail.add_child(_label("ล้มเหลว: คงระดับตีบวกเดิม", 13, MUTED))
	var go := _button("ตีบวก", func(): _begin_refine(_refine_slot))
	go.disabled = Game.zeny < Game.refine_cost(id) or Game.count(Game.refine_stone(id)) < Game.refine_stones(id) or (_guaranteed_refine and Game.count("guarantee_stone") < 1) or _refine_busy
	go.tooltip_text = "เงินหรือวัตถุดิบไม่ครบ" if go.disabled else "ยืนยันตีบวก"
	_color_button(go, Color("655333"))
	_smith.footer.add_child(go)

func _build_quests() -> void:
	_quests = _window("บันทึกเควส", Vector2.ZERO, Vector2(850, 0))
	var tabs := HBoxContainer.new()
	for i in 3:
		var b := _button(["เควสหลัก", "เควสเสริม / กิลด์", "สำเร็จแล้ว"][i], func():
			_quest_kind = i
			_quest_selected = 0
			_refresh_quests(), 125)
		_journal_tabs.append(b)
		tabs.add_child(b)
	_quests.body.add_child(tabs)
	var row := _adaptive_row()
	_quest_list = VBoxContainer.new()
	_quest_list.custom_minimum_size.x = 250
	row.add_child(_quest_list)
	_quest_detail = VBoxContainer.new()
	_quest_detail.custom_minimum_size.x = 300
	_quest_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_quest_detail)
	_quests.body.add_child(row)
	_quests.panel.hide()

func _refresh_quests() -> void:
	if not is_instance_valid(_quest_list): return
	_clear(_quest_list)
	_clear(_quest_detail)
	_clear(_tracker_box)
	for i in _journal_tabs.size(): _set_tab(_journal_tabs[i], i == _quest_kind)
	var all := _quest_entries()
	_journal_entries = []
	for entry in all:
		if entry[5]: continue
		var is_story := String(entry[1]).contains("·") or String(entry[1]).contains("Hero of")
		if (_quest_kind == 0 and is_story) or (_quest_kind == 1 and not is_story): _journal_entries.append(entry)
	if _quest_kind == 2:
		for step_index in Game.story_step:
			var finished_story: Dictionary = Story.step(step_index)
			if not finished_story.is_empty():
				_journal_entries.append([UiIcons.tex("scroll", 2), "บท %d · %s" % [finished_story.chapter, tr(finished_story.title)], "สำเร็จแล้ว", "✓", true, false, {}])
		for task in SideQuests.TASKS:
			if Game.quests.get(task.id, {}).get("state", "") == "finished":
				_journal_entries.append([UiIcons.tex("scroll", 2), task.title, "ส่งเควสสำเร็จแล้ว", "✓", true, false, {}])
		_quest_detail.add_child(_label("เนื้อเรื่องผ่านแล้ว %d ขั้น" % Game.story_step, 15, MUTED))
	for i in _journal_entries.size():
		var entry: Array = _journal_entries[i]
		var b := _button(tr(entry[1]), func():
			_quest_selected = i
			_refresh_quests(), 240)
		_set_tab(b, i == _quest_selected)
		_quest_list.add_child(b)
	if _journal_entries.is_empty():
		_quest_list.add_child(_label("ยังไม่มีรายการ", 14, MUTED))
	else:
		_quest_selected = clampi(_quest_selected, 0, _journal_entries.size() - 1)
		var entry: Array = _journal_entries[_quest_selected]
		var title := _label(tr(entry[1]), 19, EMPHASIS, true)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_quest_detail.add_child(title)
		var about := _label(tr(entry[2]), 15, TEXT)
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_quest_detail.add_child(about)
		_quest_detail.add_child(_label("ความคืบหน้า " + String(entry[3]), 16, EMPHASIS))
		var action: Dictionary = entry[6] if entry.size() > 6 else {}
		if not action.is_empty(): _quest_detail.add_child(_button("นำทาง / ทำเป้าหมาย", func():
			_quests.panel.hide()
			_quest_go(action)))
	# Keep one current story target visible; side quests stay in the journal.
	var active: Array = []
	for entry in all:
		if not entry[5] and String(entry[1]).contains("·"): active = entry
	if active.is_empty() and not all.is_empty(): active = all[0]
	if not active.is_empty():
		var title := _label(tr(active[1]), 12, TEXT, true)
		title.custom_minimum_size.x = 190
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_tracker_box.add_child(title)
		_tracker_box.add_child(_label("ความคืบหน้า " + String(active[3]), 12, EMPHASIS))
		var go := _button("ดูรายละเอียด ›", func(): toggle(_quests.panel))
		go.custom_minimum_size.y = 28
		go.add_theme_font_size_override("font_size", 11)
		_tracker_box.add_child(go)

func _build_worldmap() -> void:
	super._build_worldmap()
	_wmap.title.text = "แผนที่และการเดินทาง"
	_wmap.panel.set_meta("preferred_width", 940.0)
	_wmap_img.custom_minimum_size = Vector2(330, 330)
	_wmap_img.get_parent().size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_wmap_img.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var list_scroll := _wmap_list.get_parent() as ScrollContainer
	list_scroll.custom_minimum_size.y = 260
	var old: Control = _wmap.body.get_child(0)
	var row := _adaptive_row()
	_wmap.body.add_child(row)
	for child in old.get_children(): child.reparent(row)
	old.queue_free()
	var zoom := HBoxContainer.new()
	for amount in [-60, 60]:
		zoom.add_child(_button("ย่อแผนที่ −" if amount < 0 else "ขยายแผนที่ +", func():
			var side := clampf(_wmap_img.custom_minimum_size.x + amount, 240, 600)
			_wmap_img.custom_minimum_size = Vector2(side, side)
			await get_tree().process_frame
			_fill_worldmap()))
	_wmap.body.add_child(zoom)
	_wmap.body.move_child(zoom, 0)
	# Mapping functions below use the displayed map dimensions, not its texture size.

func _world_click(local: Vector2) -> void:
	super._world_click(local / _wmap_img.size * float(WMAP_PX))

func _fill_world_overview(here: String, plv: int) -> void:
	super._fill_world_overview(here, plv)
	var ratio := _wmap_img.size / float(WMAP_PX)
	for child in _wmap_marks.get_children():
		if child is Control: child.position *= ratio

func _build_skills() -> void:
	super._build_skills()
	_skills.panel.set_meta("preferred_width", 940.0)
	var old: Control = _skill_tabs[0].get_parent()
	var flow := HFlowContainer.new()
	_skills.body.add_child(flow)
	_skills.body.move_child(flow, old.get_index())
	for b in _skill_tabs:
		b.reparent(flow)
		b.custom_minimum_size = Vector2(125, 48)
		b.size_flags_horizontal = Control.SIZE_FILL
	old.queue_free()
	var tree_scroll: ScrollContainer = _skill_tree.get_parent()
	var row := _adaptive_row()
	_skills.body.add_child(row)
	_skills.body.move_child(row, _skill_detail.get_index())
	tree_scroll.reparent(row)
	tree_scroll.custom_minimum_size.x = 360
	tree_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_detail.reparent(row)
	_skill_detail.custom_minimum_size.x = 300

func _wmap_to_world(local: Vector2) -> Vector3:
	var p := _wm_center + (local / _wmap_img.size - Vector2(0.5, 0.5)) * _wm_half * 2.0
	return Vector3(p.x, 0, p.y)

func _world_to_wmap(p: Vector3) -> Vector2:
	return (Vector2(p.x, p.z) - _wm_center) / (_wm_half * 2.0) * _wmap_img.size + _wmap_img.size * 0.5

func _refresh_party_frame() -> void:
	super._refresh_party_frame()
	if not _party_frame: return
	for child in _party_frame.get_children():
		if child is PanelContainer:
			child.custom_minimum_size.x = 175
			child.visible = not _party_collapsed
			for texture in child.find_children("*", "TextureRect", true, false): texture.custom_minimum_size = Vector2(26, 26)
			for label in child.find_children("*", "Label", true, false): label.add_theme_font_size_override("font_size", 10)

func _show_chat() -> void:
	if _modal: _modal.hide()
	_chat_panel.visible = not _chat_panel.visible
	if _chat_panel.visible:
		_chat_panel.move_to_front()
		_chat_input.grab_focus()
	else: _chat_input.release_focus()

func _build_chat() -> void:
	super._build_chat()
	_chat_panel.hide()
	var row := HBoxContainer.new()
	row.add_child(_label("ข้อความทั่วไป / ระบบ", 12, MUTED))
	row.add_child(_button("ปิด", func():
		_chat_panel.hide()
		_chat_input.release_focus(), 50))
	_chat_panel.get_child(0).add_child(row)
	var send := _button("ส่ง", func(): _on_chat_submit(_chat_input.text), 48)
	_chat_input.get_parent().add_child(send)

func _build_settings() -> void:
	super._build_settings()
	_settings.panel.set_meta("preferred_width", 750.0)
	if Settings.is_mobile():
		var info := _label("มือถือ · ประหยัดพลังงาน 30 FPS\nเงาและเอฟเฟกต์บางส่วนถูกจำกัดเพื่อช่วยลดภาระเครื่อง", 14, EMPHASIS)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_settings.body.add_child(info)
		_settings.body.move_child(info, 0)

func _sync_settings_controls() -> void:
	super._sync_settings_controls()
	if not Settings.is_mobile(): return
	for key in ["shadows", "msaa", "render_scale", "clouds", "weather", "outlines", "xray"]:
		if not _opt_controls.has(key): continue
		var control = _opt_controls[key]
		if control is BaseButton: control.disabled = true
		elif control is Array: control[0].editable = false
		if control is Control: control.tooltip_text = "จำกัดโดยโปรไฟล์มือถือเพื่อช่วยลดการใช้ทรัพยากร"

func _build_death_notice() -> void:
	_death = PanelContainer.new()
	_death.add_theme_stylebox_override("panel", _pixel_box(SURFACE, 2, 0, 20))
	var column := VBoxContainer.new()
	column.add_child(_label("ตัวละครล้มลง", 24, EMPHASIS, true))
	_death_text = _label("", 16, TEXT)
	column.add_child(_death_text)
	_death.add_child(column)
	_root.add_child(_death)
	_death.hide()

func add_message(text: String, color := Color(1, 1, 1)) -> void:
	super.add_message(text, color)
	if not _modern_ready or not _toast_box: return
	var now := Time.get_ticks_msec()
	if text == _last_toast and now - _last_toast_at < 2000: return
	_last_toast = text
	_last_toast_at = now
	var message := _label(tr(text), 13, TEXT)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = 320
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var notice := PanelContainer.new()
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.add_theme_stylebox_override("panel", _pixel_box(SURFACE, 1, 0, 8))
	notice.add_child(message)
	_toast_box.add_child(notice)
	_toast_items.append([notice, 4.0])
	while _toast_items.size() > 3:
		var old: Array = _toast_items.pop_front()
		old[0].queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var focus := get_viewport().gui_get_focus_owner()
		if focus is LineEdit and focus != _chat_input:
			if event.keycode == KEY_ESCAPE: focus.release_focus()
			return
		if event.keycode == KEY_ESCAPE and is_instance_valid(_modal):
			_modal.hide()
			get_viewport().set_input_as_handled()
			return
		if is_instance_valid(_modal) and ((event.keycode >= KEY_F1 and event.keycode <= KEY_F8) or (event.keycode >= KEY_1 and event.keycode <= KEY_8) or event.keycode == KEY_Z):
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ENTER and not is_instance_valid(_modal) and not _chat_panel.visible:
			_show_chat()
			get_viewport().set_input_as_handled()
			return
	super._input(event)

func _process(delta: float) -> void:
	super._process(delta)
	if not _modern_ready: return
	_tick -= delta
	if _tick <= 0:
		_tick = 0.25
		var player := get_tree().get_first_node_in_group("player")
		var area := VillageBuilder.area_at(player.global_position) if player else "town"
		var indoor: bool = area.begins_with("guild") or area == "smithy"
		_location.text = tr(VillageBuilder.AREA_NAMES.get(area, area))
		_location.text += "  ·  " + _clock_lbl.text
		_location.tooltip_text = _location.text
		_map_panel.visible = not indoor and bool(Settings.g("minimap"))
		_clock.hide()
		if player:
			var dead: bool = not player.is_alive()
			if dead != _last_dead:
				_last_dead = dead
				_reset_input()
				_update_play_controls()
			_death.visible = dead
			if dead:
				_death_text.text = "กำลังกลับจุดเกิดใน %d วินาที" % maxi(0, ceili(3.0 - float(player.get("_dead_t"))))
				_death.position = (get_viewport().get_visible_rect().size - _death.get_combined_minimum_size()) * 0.5
		_fit_windows()
	for entry in _toast_items.duplicate():
		entry[1] -= delta
		if entry[1] <= 0:
			entry[0].queue_free()
			_toast_items.erase(entry)

func layout_defaults() -> void:
	if not _modern_ready:
		super.layout_defaults()
		return
	var vp := get_viewport().get_visible_rect().size
	_info_panel.position = Vector2(12, 12)
	_menu.get_child(0).visible = vp.x >= 780 # Character remains available in the menu.
	_menu.reset_size()
	_menu.position = Vector2(vp.x - _menu.get_combined_minimum_size().x - 12, 12)
	_location.position = Vector2(vp.x - 270, 68)
	_location.size = Vector2(258, 34)
	_map_panel.scale = Vector2.ONE * 0.62
	_map_panel.position = Vector2(vp.x - 126, 110)
	_clock.hide()
	_tracker.panel.custom_minimum_size.x = 210
	_tracker.panel.size = Vector2(220, 0)
	_tracker.panel.position = Vector2(vp.x - 240, 240)
	_party_toggle.position = Vector2(12, 116)
	_party_toggle.custom_minimum_size = Vector2(100, 28)
	_party_frame.position = Vector2(12, 150)
	_party_frame.scale = Vector2.ONE
	_buff_row.position = Vector2(12, 96)
	_pills.position = Vector2(_info_panel.size.x + 24, 12)
	_pills.visible = not _mobile
	_chat_panel.position = Vector2(12, maxf(12, vp.y - _chat_panel.get_combined_minimum_size().y - 12))
	_hot_panel.position = Vector2((vp.x - _sz(_hot_panel).x) * 0.5, vp.y - _sz(_hot_panel).y - 12)
	_hot_panel.visible = not _mobile
	_cast_bar.position = Vector2(vp.x * 0.5 - 110, vp.y - 160)
	if _mobile:
		_mobile_hud.relayout(vp)
		_tracker.panel.position.y = 238 if vp.y > 520 else 110
		if vp.y <= 520: _tracker.panel.position.x = maxf(_info_panel.size.x + 32, vp.x - 390)
	_toast_box.position = Vector2(maxf(230, (vp.x - 340) * 0.5), vp.y - 110)
	_toast_box.size.x = 340
	if _fade:
		_fade.size = vp
		_area_lbl.position = Vector2(0, vp.y * 0.3)
		_area_lbl.size = Vector2(vp.x, 100)
	_fit_windows()

func _layout_mobile(_vp: Vector2) -> void:
	if _modern_ready: layout_defaults()

func _fit_windows() -> void:
	if not _modern_ready: return
	var vp := get_viewport().get_visible_rect().size
	for window in _popups:
		if not window.visible: continue
		var width := minf(float(window.get_meta("preferred_width", 720)), vp.x - 24)
		var height := minf(float(window.get_meta("preferred_height", 580)), vp.y - 24)
		window.scale = Vector2.ONE
		window.custom_minimum_size = Vector2.ZERO
		window.size = Vector2(width, height)
		window.position = (vp - window.size) * 0.5
		window.position = window.position.max(Vector2(8, 8))
		for grid in window.find_children("AdaptiveColumns", "GridContainer", true, false):
			var wanted := 1 if width < 760 else 2
			if grid.columns != wanted: grid.columns = wanted
	if is_instance_valid(_character_tabs):
		var status_page: Control = _character_tabs.get_child(0)
		var stats: GridContainer = status_page.get_child(0).get_child(1).get_child(0)
		stats.columns = 4 if _status.panel.size.x < 760 else 8

func _update_minimap() -> void:
	if _modern_ready and not _map_panel.visible: return
	super._update_minimap()
