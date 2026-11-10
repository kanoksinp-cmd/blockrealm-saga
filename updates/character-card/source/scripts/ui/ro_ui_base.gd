extends CanvasLayer
## Game HUD in a clean dark-fantasy MMO style: charcoal glass panels with thin bronze
## borders, a colour-coded accent per window, Prompt (Thai + Latin) typography,
## portrait with HP / SP / EXP bars, Zeny + weight pills, menu buttons with key hints,
## minimap with quest tracker, F1-F8 hotbar, chat log, and windows for
## Character Card (S / Alt+A), Inventory (I / Alt+E), Equipment (Alt+Q),
## Quests (J / Alt+U), NPC dialog, Shop and Options (O / Esc).
## Windows are dragged by their title bars.

# palette (names kept from the older themes; values are the new dark style)
const PARCH := Color(0.075, 0.08, 0.1)      # default panel fill
const PARCH_D := Color(0.17, 0.18, 0.22)    # buttons
const SLOT := Color(0.0, 0.0, 0.0, 0.38)
const SLOT_B := Color(1.0, 1.0, 1.0, 0.09)
const WOOD := Color(0.05, 0.05, 0.065)
const WOOD_D := Color(0.03, 0.03, 0.04)
const GOLD := Color(0.95, 0.78, 0.45)
const GOLD_D := Color(0.62, 0.48, 0.26)
const LINE := Color(0.5, 0.42, 0.28, 0.85)   # bronze panel border
const INK := Color(0.94, 0.93, 0.9)
const INK_L := Color(0.68, 0.7, 0.76)
const CREAM := Color(1.0, 0.97, 0.9)
const TITLE := Color(0.98, 0.88, 0.66)
const R_BROWN := Color(0.85, 0.62, 0.36)
const R_GREEN := Color(0.45, 0.8, 0.45)
const R_BLUE := Color(0.42, 0.65, 1.0)
const R_PURPLE := Color(0.7, 0.52, 1.0)
const R_RED := Color(0.95, 0.42, 0.36)
const R_TEAL := Color(0.3, 0.82, 0.76)
const R_GRAY := Color(0.62, 0.64, 0.7)
const R_YELLOW := Color(0.98, 0.8, 0.3)
const GOOD := Color(0.55, 0.92, 0.5)
const BAD := Color(1.0, 0.5, 0.42)
const ACCENT := Color(0.62, 0.82, 1.0)
const BTN_GREEN := Color(0.2, 0.46, 0.32)

const MINI_HALF := 128
const WORLD_HALF := 128.0
const WMAP_PX := 512
const INV_SLOTS := 20

var _root: Control
var _theme: Theme
var _font_b: Font
var _font_t: Font
var _windows: Array[Control] = []

# HUD
var _name_lbl: Label
var _job_lbl: Label
var _lv_lbl: Label
var _hp_bar: ProgressBar
var _sp_bar: ProgressBar
var _exp_bar: ProgressBar
var _zeny_lbl: Label
var _weight_lbl: Label
var _portrait_vp: SubViewport
var _banner: TextureRect
var _banner_key := ""
var _info_panel: Control
var _pills: Control
var _menu: Control
var _chat: RichTextLabel
var _chat_panel: Control
var _hot_panel: Control
var _hot_slots := []
var _hot_cd := []
var _auto_glow: Control
var _auto_glow_t := 0.0        ## per slot [shade ColorRect, seconds Label]
var _auto_btn: Button
var _cast_bar: ProgressBar
var _buff_row: HBoxContainer
var _party_frame: VBoxContainer
var _party: Dictionary
var _party_tab := 0
var _party_vps := {}
var _party_bars := []
var _party_t := 0.0
var _buff_t := 0.0
var _skills: Dictionary
var _skill_list: VBoxContainer
var _skill_pts: Label
var _skill_job: Label
var _skill_tab := 1
var _skill_tabs := []
var _skill_adv: VBoxContainer
var _wmap: Dictionary
var _wmap_img: TextureRect
var _wmap_marks: Control
var _wmap_list: VBoxContainer
var _world_img: ImageTexture
var _clock: Control
var _clock_lbl: Label
var _clock_icon: TextureRect
var _mon_dots := {}
var _autoset: Dictionary
var _auto_ctl := {}
var _auto_face: TextureRect
var _auto_profile: Label
var _auto_refresh := 0.0
var _guaranteed_refine := false
var _refine_busy := false
var _smith: Dictionary
var _craft_weapon_kind := "all"
var _smith_tab := 0
var _smith_tabs := []
var _smith_list: VBoxContainer
var _smith_zeny: Label
var _smith_msg: Label
var _qmark_t := 0.0
var _skill_badge: Label
var _map_panel: Control
var _map_title: Label
var _map_indoor: Control
var _fade: ColorRect
var _area_lbl: Label
var _rank_lbl: Label
var _guild: Dictionary
var _guild_tab := 0
var _guild_head: VBoxContainer
var _guild_list: VBoxContainer
var _guild_tabs := []
var _minimap: TextureRect
var _mm_area := "town"
var _mm_center := Vector2.ZERO
var _mm_half := Vector2(128, 128)
var _mm_tex := {}
var _wm_center := Vector2.ZERO
var _wm_half := Vector2(128, 128)
var _wmap_world := false
var _map_dots: Control
var _map_zoom := 0.3
var _tracker: Dictionary
var _tracker_box: VBoxContainer
# windows
var _status: Dictionary
var _status_rows := {}
var _status_info: GridContainer
var _status_points: Label
var _status_head: Label
var _status_vp: SubViewport
var _status_job: Label
var _status_guild: Label
var _status_spin := true
var _status_yaw := 0.35
var _status_fit_queued := false
var _status_model_key := ""
var _status_rotate: Button
var _inv: Dictionary
var _inv_tab := 0
var _inv_tabs := []
var _inv_grid: GridContainer
var _inv_footer: Label
var _inv_zeny: Label
var _equip: Dictionary
var _equip_vp: SubViewport
var _equip_slots := {}
var _equip_stats: Label
var _quests: Dictionary
var _quest_list: VBoxContainer
var _dialog: Dictionary
var _dialog_text: RichTextLabel
var _dialog_buttons: Container
var _dialog_name: Label
var _dialog_face: TextureRect
var _dialog_vps := {}
var _shop: Dictionary
var _shop_grid: GridContainer
var _shop_zeny: Label
var _shop_quantities := {}
var _shop_stock: Array = []
var _shop_buy := true
var _shop_tabs := []
# options
var _settings: Dictionary
var _settings_tabs: TabContainer
var _opt_controls := {}
var _keys_lbl: RichTextLabel
var _yaw := 0.0
# ---- phones / tablets: touch HUD + bigger UI
var _mobile := false
var _mobile_scale := 1.0
var _mobile_hud
var _fit_t := 0.0
var _popups: Array[Control] = []     # real windows (not HUD boxes): may be shrunk to fit a phone


func _ready() -> void:
	Audio.ensure()
	Game.ui = self
	_mobile = _detect_mobile()
	_font_b = load("res://assets/fonts/ui_font_bold.tres")
	_font_t = load("res://assets/fonts/ui_font_title.tres")
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_root)
	_build_info()
	var target_profile := PanelContainer.new()
	target_profile.set_script(preload("res://scripts/ui/target_profile.gd"))
	_root.add_child(target_profile)
	_build_pills()
	_build_menu()
	_build_minimap()
	_build_tracker()
	_build_chat()
	_build_hotbar()
	_build_status()
	_build_inventory()
	_build_quests()
	_build_dialog()
	_build_shop()
	_build_skills()
	_build_worldmap()
	_build_auto_settings()
	_build_smith()
	_build_clock()
	_build_settings()
	_build_guild_board()
	_build_party()
	_build_online()
	_build_fade()
	if _mobile:
		_setup_mobile()
	Game.changed.connect(_refresh)
	Game.inventory_changed.connect(_refresh_inventory)
	Game.quest_changed.connect(_refresh_quests)
	Game.message.connect(add_message)
	Game.skills_changed.connect(_refresh_skills)
	Game.skills_changed.connect(_refresh_hotbar)
	Game.party_changed.connect(_refresh_party_frame)
	Settings.changed.connect(_on_settings_changed)
	get_viewport().size_changed.connect(layout_defaults)
	_refresh()
	_refresh_quests()
	layout_defaults.call_deferred()
	_on_settings_changed()
	add_message("Welcome to Aldenvale!", Color(0.75, 0.45, 0.05))
	if _mobile:
		if TranslationServer.get_locale().begins_with("th"):
			add_message("จอยซ้าย: เดิน   แตะมอนสเตอร์ / NPC: เลือกเป้าหมาย   ปุ่มขวา: โจมตี / คุยเควส / เก็บของ   ลากนิ้ว: หมุนกล้อง   สองนิ้ว: ซูม", INK)
		else:
			add_message("Left stick: move   Tap a monster / NPC: target   Action button: attack / talk / pick up   Drag: turn camera   Pinch: zoom", INK)
	else:
		add_message("Click: walk / attack / talk / pick up.  S: Status   I: Items   K: Skills   M: Map   Z: Auto   O: Options   F1-F8: hotbar", INK)
	add_message("Talk to Guide Lumi (the gold \"!\" near the fountain) to begin your story. Click the quest on the right to walk there.", Color(1.0, 0.85, 0.4))


# ================================================================== theme + helpers
func _sb(bg: Color, border := WOOD, bw := 2, radius := 2, margin := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = maxi(2, margin - 2)
	s.content_margin_bottom = maxi(2, margin - 2)
	s.anti_aliasing = radius > 0
	return s


## Standard button look: slate fill, hairline border, gold edge on hover.
func _btn_style(state: String, base := PARCH_D, margin := 10) -> StyleBoxFlat:
	var bg: Color = {"normal": base, "hover": base.lightened(0.1), "pressed": base.darkened(0.2),
		"disabled": base.darkened(0.35)}.get(state, base)
	var br: Color = {"normal": base.lightened(0.22), "hover": GOLD, "pressed": GOLD_D,
		"disabled": base.lightened(0.05)}.get(state, base)
	var s := _sb(bg, br, 1, 5, margin)
	s.content_margin_top = 4
	s.content_margin_bottom = 5
	if state == "normal" or state == "hover":
		s.shadow_color = Color(0, 0, 0, 0.3)
		s.shadow_size = 2
		s.shadow_offset = Vector2(0, 1)
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = load("res://assets/fonts/ui_font.tres")
	t.default_font_size = 14
	t.set_color("font_color", "Label", INK)
	for typ in ["Button", "OptionButton", "MenuButton"]:
		for st in ["normal", "hover", "pressed", "disabled"]:
			t.set_stylebox(st, typ, _btn_style(st))
		t.set_stylebox("focus", typ, StyleBoxEmpty.new())
		t.set_font("font", typ, _font_b)
	for c in ["font_color", "font_focus_color"]:
		for typ in ["Button", "OptionButton", "CheckButton", "CheckBox"]:
			t.set_color(c, typ, INK)
	for typ in ["Button", "OptionButton", "CheckButton", "CheckBox"]:
		t.set_color("font_hover_color", typ, CREAM)
		t.set_color("font_pressed_color", typ, GOLD)
		t.set_color("font_hover_pressed_color", typ, GOLD)
		t.set_color("font_disabled_color", typ, Color(0.5, 0.52, 0.56))
		t.set_constant("outline_size", typ, 0)
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	# soft 1px drop shadow keeps text readable over the 3D world
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.32))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_color("font_shadow_color", "RichTextLabel", Color(0, 0, 0, 0.3))
	t.set_constant("shadow_offset_x", "RichTextLabel", 0)
	t.set_constant("shadow_offset_y", "RichTextLabel", 1)
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_font("bold_font", "RichTextLabel", _font_b)
	# tooltips + popups
	var tip := _sb(Color(0.06, 0.065, 0.085, 0.97), LINE, 1, 6, 10)
	tip.content_margin_top = 7
	tip.content_margin_bottom = 8
	tip.shadow_color = Color(0, 0, 0, 0.45)
	tip.shadow_size = 6
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0))
	t.set_font_size("font_size", "TooltipLabel", 13)
	t.set_stylebox("panel", "PopupMenu", _sb(Color(0.08, 0.085, 0.105, 0.98), LINE, 1, 6, 6))
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", CREAM)
	t.set_stylebox("hover", "PopupMenu", _sb(Color(GOLD, 0.16), Color(0, 0, 0, 0), 0, 4, 4))
	t.set_constant("v_separation", "PopupMenu", 8)
	# tabs: flat strip, selected tab gets a gold underline
	t.set_stylebox("panel", "TabContainer", _sb(Color(0, 0, 0, 0.22), SLOT_B, 1, 6, 10))
	var tsel := _sb(Color(1, 1, 1, 0.07), GOLD, 0, 5, 14)
	tsel.border_width_bottom = 2
	tsel.corner_radius_bottom_left = 0
	tsel.corner_radius_bottom_right = 0
	var tun := _sb(Color(0, 0, 0, 0.0), Color(0, 0, 0, 0), 0, 5, 14)
	var thov := _sb(Color(1, 1, 1, 0.04), Color(GOLD, 0.4), 0, 5, 14)
	thov.border_width_bottom = 2
	for s in [tsel, tun, thov]:
		s.content_margin_top = 5
		s.content_margin_bottom = 6
	t.set_stylebox("tab_selected", "TabContainer", tsel)
	t.set_stylebox("tab_unselected", "TabContainer", tun)
	t.set_stylebox("tab_hovered", "TabContainer", thov)
	t.set_font("font", "TabContainer", _font_b)
	t.set_color("font_selected_color", "TabContainer", GOLD)
	t.set_color("font_unselected_color", "TabContainer", INK_L)
	t.set_color("font_hovered_color", "TabContainer", INK)
	t.set_constant("outline_size", "TabContainer", 0)
	# slider
	var track := _sb(Color(0, 0, 0, 0.5), SLOT_B, 1, 4, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	var area := _sb(GOLD_D, GOLD_D, 0, 4, 0)
	t.set_stylebox("grabber_area", "HSlider", area)
	t.set_stylebox("grabber_area_highlight", "HSlider", _sb(GOLD, GOLD, 0, 4, 0))
	# slim scrollbars
	for typ in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", typ, _sb(Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 0, 3, 3))
		t.set_stylebox("grabber", typ, _sb(Color(1, 1, 1, 0.18), Color(0, 0, 0, 0), 0, 3, 3))
		t.set_stylebox("grabber_highlight", typ, _sb(Color(GOLD, 0.6), Color(0, 0, 0, 0), 0, 3, 3))
		t.set_stylebox("grabber_pressed", typ, _sb(GOLD, Color(0, 0, 0, 0), 0, 3, 3))
	# text fields
	var le := _sb(Color(0, 0, 0, 0.4), SLOT_B, 1, 5, 8)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", _sb(Color(0, 0, 0, 0), GOLD_D, 1, 5, 8))
	t.set_color("font_color", "LineEdit", INK)
	t.set_constant("separation", "HSeparator", 10)
	t.set_stylebox("separator", "HSeparator", _sb(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 0, 0, 0))
	return t


func _label(text := "", size := 13, color := INK, bold := false) -> Label:
	var l := Label.new()
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", _font_b)
	return l


func _outlined(l: Label, outline := WOOD_D, size := 4) -> Label:
	l.add_theme_color_override("font_outline_color", Color(outline, 0.85))
	l.add_theme_constant_override("outline_size", mini(size, 3))
	return l


func _button(text: String, cb: Callable, min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(min_w, 30)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func() -> void: Audio.play("ui_click", null, 0.0, 0.03))
	b.pressed.connect(cb)
	return b


## Primary / coloured button (confirm, buy, learn ...).
func _color_button(b: Button, bg: Color, fg := CREAM) -> Button:
	for st in ["normal", "hover", "pressed", "disabled"]:
		var s := _btn_style(st, bg, 12)
		if st == "normal":
			s.border_color = bg.lightened(0.35)
		b.add_theme_stylebox_override(st, s)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, fg)
	b.add_theme_font_override("font", _font_b)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


## Selected / unselected look for the small tab buttons (inventory, shop, smith).
func _set_tab(b: Button, on: bool) -> void:
	if on:
		var s := _btn_style("normal", Color(0.24, 0.19, 0.1), 10)
		s.border_color = GOLD
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", s)
		b.add_theme_color_override("font_color", GOLD)
		b.add_theme_color_override("font_hover_color", GOLD)
	else:
		for st in ["normal", "hover"]:
			b.remove_theme_stylebox_override(st)
		b.remove_theme_color_override("font_color")
		b.remove_theme_color_override("font_hover_color")


func _icon_rect(tex: Texture2D, size := 16) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _slot_style(selected := false, empty := false) -> StyleBoxFlat:
	if selected:
		var s := _sb(Color(GOLD, 0.2), GOLD, 2, 6, 2)
		return s
	return _sb(Color(0, 0, 0, 0.22) if empty else SLOT, SLOT_B, 1, 6, 2)


func _slot(size := 48) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(size, size)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _slot_style())
	b.add_theme_stylebox_override("hover", _sb(Color(1, 1, 1, 0.08), GOLD, 1, 6, 2))
	b.add_theme_stylebox_override("pressed", _sb(Color(GOLD, 0.25), GOLD, 2, 6, 2))
	b.add_theme_stylebox_override("disabled", _slot_style(false, true))
	for side in ["left", "right", "top", "bottom"]:
		b.get_theme_stylebox("normal").set("content_margin_" + side, 7)
	b.add_theme_constant_override("icon_max_width", size - 14)
	return b


func _count_label(b: Control, text: String) -> Label:
	var c := _outlined(_label(text, 11, CREAM, true), Color(0, 0, 0), 3)
	c.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	c.offset_left = -28
	c.offset_top = -19
	c.offset_right = -4
	c.offset_bottom = -1
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(c)
	return c


## Small section header: gold caps text with a coloured underline.
func _ribbon(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _sb(Color(0, 0, 0, 0), color, 0, 0, 2)
	s.border_width_bottom = 2
	s.content_margin_top = 0
	s.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", s)
	var l := _label(text, 13, TITLE, true)
	l.name = "Text"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


func _round_frame(size: float, bg := PARCH, border := GOLD, bw := 4) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _sb(bg, border, mini(bw, 2), int(size / 2.0), 0)
	s.anti_aliasing = true
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 4
	p.add_theme_stylebox_override("panel", s)
	p.custom_minimum_size = Vector2(size, size)
	return p


func _pill(_bg := Color()) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _sb(Color(0.06, 0.065, 0.085, 0.86), LINE, 1, 12, 10)
	s.content_margin_top = 3
	s.content_margin_bottom = 4
	s.shadow_color = Color(0, 0, 0, 0.3)
	s.shadow_size = 3
	p.add_theme_stylebox_override("panel", s)
	return p


func _bar(fill: Color, h := 16, icon := "") -> Dictionary:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := _sb(Color(0, 0, 0, 0.55), Color(1, 1, 1, 0.1), 1, 4, 0)
	var fg := _sb(fill, fill.lightened(0.35), 0, 4, 0)
	fg.border_width_top = 1
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	var l := _outlined(_label("", 11 if h >= 14 else 10, CREAM, true), Color(0, 0, 0), 3)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("line_spacing", -4)
	b.add_child(l)
	if icon != "":
		var ic := _icon_rect(UiIcons.tex(icon, 2), 16)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(ic)
	hb.add_child(b)
	return {"box": hb, "bar": b, "label": l}


## Draggable dark window with a title bar; `ribbon_color` is the accent line under
## the title so each kind of window is recognisable. Returns {panel, body, title}.
func _window(title: String, pos: Vector2, min_size: Vector2, ribbon_color := R_BROWN, closable := true) -> Dictionary:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _pixel_box(ribbon_color, 2, 0.0, 12))
	panel.position = pos
	panel.custom_minimum_size = min_size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var bar := PanelContainer.new()
	var bs := _sb(Color(0, 0, 0, 0), ribbon_color, 0, 0, 2)
	bs.border_width_bottom = 2
	bs.border_color = Color(ribbon_color, 0.75)
	bs.content_margin_top = 0
	bs.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", bs)
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	bar.add_child(top)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.add_theme_stylebox_override("panel", _sb(ribbon_color, ribbon_color.lightened(0.3), 0, 2, 0))
	dot.rotation_degrees = 45
	dot.pivot_offset = Vector2(4, 4)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(dot)
	var lbl := _label(title, 17, TITLE, false)
	lbl.add_theme_font_override("font", _font_t)
	lbl.name = "Text"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(lbl)
	if closable:
		var x := Button.new()
		x.text = "×"
		x.tooltip_text = "Close (Esc)"
		x.focus_mode = Control.FOCUS_NONE
		x.custom_minimum_size = Vector2(42, 36) if _mobile else Vector2(28, 26)
		x.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		x.add_theme_stylebox_override("normal", _sb(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.08), 1, 5, 0))
		x.add_theme_stylebox_override("hover", _sb(Color(0.75, 0.2, 0.18), Color(0.95, 0.4, 0.35), 1, 5, 0))
		x.add_theme_stylebox_override("pressed", _sb(Color(0.55, 0.14, 0.12), Color(0.95, 0.4, 0.35), 1, 5, 0))
		x.add_theme_color_override("font_color", INK_L)
		x.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		x.add_theme_font_size_override("font_size", 19)
		x.pressed.connect(panel.hide)
		top.add_child(x)
	var drag := func(e: InputEvent) -> void:
		if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			panel.position += e.relative
		elif e is InputEventMouseButton and e.pressed:
			panel.move_to_front()
	bar.gui_input.connect(drag)
	v.add_child(bar)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	v.add_child(body)
	_root.add_child(panel)
	_windows.append(panel)
	_popups.append(panel)
	return {"panel": panel, "body": body, "title": lbl}


## Panel look shared by windows and HUD boxes. (Kept the old name so every caller
## picks up the new style.) border >= 2: framed panel; border 1: small chip.
func _pixel_box(base: Color, border := 2, _noise := 0.0, margin := 8) -> StyleBoxFlat:
	var s: StyleBoxFlat
	if border >= 2:
		var fill := PARCH.lerp(base, 0.06)
		fill.a = 0.95
		s = _sb(fill, LINE, 1, 8, margin)
		s.shadow_color = Color(0, 0, 0, 0.45)
		s.shadow_size = 10
		s.shadow_offset = Vector2(0, 3)
	else:
		s = _sb(Color(base.darkened(0.55), 0.92), base.lightened(0.1), 1, 5, margin)
	return s


func _hud_panel(color := R_GRAY) -> PanelContainer:
	var p := PanelContainer.new()
	var fill := PARCH.lerp(color, 0.05)
	fill.a = 0.84
	var s := _sb(fill, Color(LINE, 0.6), 1, 8, 10)
	s.content_margin_top = 8
	s.content_margin_bottom = 9
	s.shadow_color = Color(0, 0, 0, 0.3)
	s.shadow_size = 5
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(p)
	_windows.append(p)
	return p


func _over_ui(p: Vector2) -> bool:
	for w in _windows:
		if w.visible and w.get_global_rect().has_point(p):
			return true
	return false


static func _commas(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


func _item_tip(id: String) -> String:
	var it := Items.info(id)
	var kind: String = {"use": "Consumable", "etc": "Material", "weapon": "Weapon", "armor": "Armor"}.get(it.type, "Item")
	var slot := Items.slot_of(id)
	if slot != "":
		kind = Items.SLOT_NAMES[slot]
	var head := Game.item_label(id) + "   [" + tr(kind) + "]"
	var st := Items.stat_text(id)
	if Game.refine_lv(id) > 0:
		st += "  ·  " + tr("Refine bonus: %s") % ("%s +%d" % ["ATK" if slot == "weapon" else "DEF", Game.refine_bonus(id)])
	var tip: String = tr("%s\n%s\nWeight %d   Sells for %d z") % [head + ("\n" + st if st != "" else ""), Items.desc(id), it.weight, Game.sell_price(id)]
	if (it.get("look", {}) as Dictionary).has("wings"):
		tip += "\n" + tr("Wings: fly outside town, move speed +40%")
	if slot != "" and Game.equip.get(slot, "") != id:
		tip += "\n" + _compare_text(id)
	return tip


# ---- gear comparison with what is equipped in the same slot
## Stats an item gives (incl. refine), as {key: value}.
func _gear_stats(id: String) -> Dictionary:
	var out := {}
	if id == "":
		return out
	var it := Items.info(id)
	var slot := Items.slot_of(id)
	var atk := int(it.get("atk", 0)) + (Game.refine_bonus(id) if slot == "weapon" else 0)
	var df := int(it.get("def", 0)) + (Game.refine_bonus(id) if slot != "weapon" else 0)
	if atk != 0:
		out["ATK "] = atk
	if df != 0:
		out["DEF "] = df
	var b: Dictionary = it.get("bonus", {})
	for k in b:
		out[k] = int(out.get(k, 0)) + int(b[k])
	return out


## One number to rank gear for your job (main stat counts most).
func _gear_score(id: String) -> float:
	var st := _gear_stats(id)
	var main: String = Game.job_info().main
	var w := {"ATK ": 1.0, "DEF ": 1.6, "ATK": 1.0, "DEF": 1.6, "HIT": 0.6, "FLEE": 0.7, "CRIT": 0.9, "ASPD": 2.0, "MOVE": 0.4,
		"MAXHP_PCT": 2.0, "MAXSP_PCT": 1.0, "HPREGEN": 0.3, "SPREGEN": 0.3, "HEAL_PCT": 0.5, "POISON": 0.6, "ATK_PCT": 3.0}
	var score := 0.0
	for k in st:
		var v := float(st[k])
		if k in ["STR", "AGI", "VIT", "INT", "DEX", "LUK"]:
			score += v * (4.0 if k == main else (2.0 if k == "VIT" else 1.2))
		else:
			score += v * float(w.get(k, 1.0))
	return score


## 1 = better than what you wear, -1 = worse, 0 = same / not comparable.
func _compare(id: String) -> int:
	var slot := Items.slot_of(id)
	if slot == "":
		return 0
	var cur: String = Game.equip.get(slot, "")
	if cur == id:
		return 0
	var d := _gear_score(id) - (_gear_score(cur) if cur != "" else 0.0)
	return 1 if d > 0.01 else (-1 if d < -0.01 else 0)


func _compare_text(id: String) -> String:
	var slot := Items.slot_of(id)
	var cur: String = Game.equip.get(slot, "")
	var a := _gear_stats(id)
	var b := _gear_stats(cur)
	var keys := []
	for k in a:
		keys.append(k)
	for k in b:
		if not k in keys:
			keys.append(k)
	var parts: PackedStringArray = []
	for k in keys:
		var d := int(a.get(k, 0)) - int(b.get(k, 0))
		if d == 0:
			continue
		var lbl: String = String(k).strip_edges()
		lbl = tr(SkillDB.BONUS_LABEL.get(lbl, lbl))
		parts.append("%s %s%d%s" % [lbl, "+" if d > 0 else "", d, "%" if String(k) in SkillDB.PCT_KEYS else ""])
	var head := tr("Compared to %s:") % (Game.item_label(cur) if cur != "" else tr("(empty slot)"))
	var verdict := ""
	match _compare(id):
		1:
			verdict = tr("Better")
		-1:
			verdict = tr("Worse")
		_:
			verdict = tr("About the same")
	return "%s  %s\n%s" % [head, verdict, "  ".join(parts) if parts.size() > 0 else tr("No stat difference")]


static var _cmp_cache := {}


func _cmp_arrow_tex(up: bool) -> ImageTexture:
	if _cmp_cache.has(up):
		return _cmp_cache[up]
	var rows := ["....k....", "...kGk...", "..kGGGk..", ".kGGGGGk.", "kGGGGGGGk", "kkkGGGkkk", "..kGGGk..", "..kGGGk..", "..kkkkk.."]
	var img := Image.create(9, 9, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := Color(0.35, 0.95, 0.35) if up else Color(1.0, 0.3, 0.25)
	for y in 9:
		for x in 9:
			var ch: String = rows[y if up else 8 - y][x]
			if ch != ".":
				img.set_pixel(x, y, Color(0.05, 0.05, 0.05) if ch == "k" else fill)
	var t := ImageTexture.create_from_image(img)
	_cmp_cache[up] = t
	return t


func _compare_arrow(b: Control, c: int) -> void:
	if c == 0:
		return
	var r := TextureRect.new()
	r.texture = _cmp_arrow_tex(c > 0)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = Vector2(2, 2)
	r.size = Vector2(18, 18)
	b.add_child(r)


# ================================================================== HUD: portrait + bars
func _build_info() -> void:
	## Compact portrait card: round face with a level badge, name / job on one
	## line and slim HP, SP and EXP bars (about 70% of the old footprint).
	var p := _hud_panel(R_BROWN)
	var ps := p.get_theme_stylebox("panel") as StyleBoxFlat
	ps.content_margin_left = 7
	ps.content_margin_right = 9
	ps.content_margin_top = 6
	ps.content_margin_bottom = 7
	_info_panel = p
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	# job emblem lives in the tooltip of the job label now; keep the node for _refresh
	_banner = TextureRect.new()
	_banner.visible = false
	h.add_child(_banner)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", -9)
	h.add_child(left)
	var frame := _round_frame(58, Color(0.16, 0.2, 0.28), GOLD_D, 2)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_portrait_vp = Portrait.make(self, Vector2i(112, 112), "player", null, "head", true)
	var face := TextureRect.new()
	face.texture = _portrait_vp.get_texture()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.custom_minimum_size = Vector2(56, 56)
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(face)
	left.add_child(frame)
	var lvc := CenterContainer.new()
	var lvp := PanelContainer.new()
	var ls := _sb(Color(0.16, 0.12, 0.06, 0.96), GOLD, 1, 9, 6)
	ls.content_margin_top = 0
	ls.content_margin_bottom = 0
	lvp.add_theme_stylebox_override("panel", ls)
	_lv_lbl = _label("", 10, GOLD, true)
	lvp.add_child(_lv_lbl)
	lvc.add_child(lvp)
	left.add_child(lvc)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 3)
	right.custom_minimum_size.x = 188
	h.add_child(right)
	var nh := HBoxContainer.new()
	nh.add_theme_constant_override("separation", 5)
	_name_lbl = _label("", 14, CREAM)
	_name_lbl.add_theme_font_override("font", _font_t)
	_name_lbl.clip_text = true
	_name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_lbl.custom_minimum_size.x = 40
	_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_lbl.size_flags_stretch_ratio = 1.4
	nh.add_child(_name_lbl)
	_rank_lbl = _label("", 10, Color(0.05, 0.05, 0.07), true)
	_rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rank_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_rank_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_rank_lbl.tooltip_text = "Adventurer rank"
	_rank_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	nh.add_child(_rank_lbl)
	_job_lbl = _label("", 10, INK_L)
	_job_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_job_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_job_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_job_lbl.clip_text = true
	_job_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_job_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	nh.add_child(_job_lbl)
	right.add_child(nh)
	var hp := _bar(Color(0.8, 0.2, 0.22), 14, "heart")
	_hp_bar = hp.bar
	right.add_child(hp.box)
	var spb := _bar(Color(0.24, 0.5, 0.92), 14, "drop")
	_sp_bar = spb.bar
	right.add_child(spb.box)
	var xb := _bar(Color(0.85, 0.66, 0.24), 9, "star")
	_exp_bar = xb.bar
	(xb.label as Label).add_theme_font_size_override("font_size", 9)
	right.add_child(xb.box)
	for box in [hp.box, spb.box, xb.box]:
		for c in (box as Control).get_children():
			if c is TextureRect:
				(c as TextureRect).custom_minimum_size = Vector2(13, 13)


func _build_pills() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	_root.add_child(h)
	_pills = h
	for kind in ["coin", "bag"]:
		var p := _pill()
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		_windows.append(p)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		hb.add_child(_icon_rect(UiIcons.tex(kind, 2), 20))
		var l := _label("", 14, CREAM, true)
		l.custom_minimum_size.x = 92
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(l)
		p.add_child(hb)
		p.tooltip_text = "Zeny" if kind == "coin" else "Weight"
		h.add_child(p)
		if kind == "coin":
			_zeny_lbl = l
		else:
			_weight_lbl = l


const MENU_ART := {"hero": "status", "bag": "bag", "star": "skills", "scroll": "quests", "map": "map", "gear": "options", "auto": "auto"}


## Painted 64 px menu icon (assets/icons/ui) or null.
func _menu_art(icon: String) -> Texture2D:
	var path := "res://assets/icons/ui/%s.png" % MENU_ART.get(icon, icon)
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _round_button(icon: String, tip: String, cb: Callable, size := 42) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(size, size)
	var art := _menu_art(icon)
	b.icon = art if art else UiIcons.tex(icon, 2)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if art else CanvasItem.TEXTURE_FILTER_NEAREST
	b.tooltip_text = tip
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var pad := int(size * (0.1 if art else 0.2))
	for st in ["normal", "hover", "pressed"]:
		var s := _sb({"normal": Color(0.06, 0.065, 0.085, 0.88), "hover": Color(0.14, 0.14, 0.17, 0.95),
			"pressed": Color(0.2, 0.17, 0.1, 0.95)}[st], {"normal": Color(LINE, 0.7), "hover": GOLD, "pressed": GOLD}[st], 1, 8, pad)
		s.content_margin_top = pad
		s.content_margin_bottom = pad
		s.shadow_color = Color(0, 0, 0, 0.3)
		s.shadow_size = 3
		b.add_theme_stylebox_override(st, s)
	b.pressed.connect(cb)
	return b


## Small key-cap hint in the bottom-right corner of a button ("I", "F1" ...).
func _key_hint(b: Control, key: String, top := false) -> Label:
	var k := _label(key, 10, GOLD, true)
	var s := _sb(Color(0, 0, 0, 0.72), Color(GOLD, 0.35), 1, 3, 3)
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	k.add_theme_stylebox_override("normal", s)
	k.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if top:
		k.position = Vector2(-3, -5)
	else:
		k.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		k.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		k.grow_vertical = Control.GROW_DIRECTION_BEGIN
		k.offset_right = 4
		k.offset_bottom = 4
	b.add_child(k)
	return k


func _key_hint_label(key: String) -> Label:
	var k := _label(key, 10, GOLD, true)
	var s := _sb(Color(0, 0, 0, 0.5), Color(GOLD, 0.35), 1, 3, 4)
	s.content_margin_top = 0
	s.content_margin_bottom = 0
	k.add_theme_stylebox_override("normal", s)
	k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	k.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return k


func _build_menu() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	_root.add_child(h)
	_menu = h
	for d in [["hero", "Status (S)", "S", func() -> void: toggle(_status.panel)],
			["bag", "Items (I)", "I", func() -> void: toggle(_inv.panel)],
			["star", "Skills (K)", "K", func() -> void: toggle(_skills.panel)],
			["scroll", "Quests (J)", "J", func() -> void: toggle(_quests.panel)],
			["map", "World Map (M)", "M", func() -> void: toggle(_wmap.panel)],
			["gear", "Options (O)", "O", func() -> void: toggle(_settings.panel)]]:
		var b := _round_button(d[0], d[1], d[3], 48)
		_key_hint(b, d[2])
		_windows.append(b)
		h.add_child(b)
		if d[0] == "star":
			var badge := _label("!", 12, Color(1, 1, 1), true)
			badge.add_theme_stylebox_override("normal", _sb(Color(0.85, 0.2, 0.17), Color(1, 0.6, 0.5), 1, 8, 5))
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.position = Vector2(33, -7)
			badge.custom_minimum_size = Vector2(18, 18)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			badge.visible = false
			b.add_child(badge)
			_skill_badge = badge


# ================================================================== minimap + quest tracker
const MAP_SHADER := """
shader_type canvas_item;
uniform vec2 center = vec2(0.5);
uniform float zoom = 0.5;
void fragment() {
	vec2 d = UV - 0.5;
	float r = length(d);
	if (r > 0.5) discard;
	vec2 uv = center + d * zoom;
	vec4 c = texture(TEXTURE, uv);
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) c = vec4(0.33, 0.55, 0.26, 1.0);
	c.rgb *= 1.0 - smoothstep(0.36, 0.5, r) * 0.4;
	COLOR = c;
}
"""


func _build_minimap() -> void:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(176, 196)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(holder)
	_windows.append(holder)
	_map_panel = holder
	var ring := _round_frame(176, PARCH, GOLD_D, 2)
	ring.position = Vector2(0, 14)
	ring.size = Vector2(176, 176)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(ring)
	_minimap = TextureRect.new()
	_minimap.position = Vector2(8, 22)
	_minimap.size = Vector2(160, 160)
	_minimap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_minimap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = MAP_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = sh
	_minimap.material = sm
	holder.add_child(_minimap)
	_map_dots = Control.new()
	_map_dots.position = _minimap.position
	_map_dots.size = _minimap.size
	_map_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_map_dots)
	# player arrow in the middle
	var me := _icon_rect(_arrow_tex(), 14)
	me.position = _minimap.size * 0.5 - Vector2(7, 7)
	me.name = "Me"
	me.pivot_offset = Vector2(7, 7)
	_map_dots.add_child(me)
	var rib := _pill()
	var rl := _label("Aldenvale", 13, TITLE, true)
	_map_title = rl
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rib.add_child(rl)
	rib.position = Vector2(88 - 55, 2)
	rib.custom_minimum_size.x = 110
	rib.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(rib)
	var n := _round_frame(22, WOOD_D, GOLD, 2)
	n.position = Vector2(150, 24)
	var nl := _outlined(_label("N", 12, CREAM, true), Color(0, 0, 0, 0.6), 2)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.add_child(nl)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(n)
	for z in [["+", Vector2(148, 156), -1], ["-", Vector2(124, 168), 1]]:
		var b := Button.new()
		b.text = z[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(24, 24)
		b.position = z[1]
		_color_button(b, WOOD)
		for st in ["normal", "hover", "pressed"]:
			var bs := b.get_theme_stylebox(st) as StyleBoxFlat
			bs.set_corner_radius_all(12)
			bs.content_margin_left = 0
			bs.content_margin_right = 0
			bs.content_margin_top = 0
			bs.content_margin_bottom = 2
		var dir: int = z[2]
		b.pressed.connect(func() -> void: _map_zoom = clampf(_map_zoom * (0.7 if dir < 0 else 1.0 / 0.7), 0.12, 0.9))
		holder.add_child(b)
	# indoor: dark disc with a house icon instead of the world map
	var ind := _round_frame(160, Color(0.08, 0.07, 0.09), Color(0, 0, 0, 0), 0)
	ind.position = Vector2(8, 22)
	ind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var il := _label("Indoors", 14, INK_L, true)
	il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	il.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ind.add_child(il)
	ind.visible = false
	holder.add_child(ind)
	_map_indoor = ind
	call_deferred("_make_minimap")


func _arrow_tex() -> ImageTexture:
	var img := Image.create(7, 7, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rows := ["...k...", "..kRk..", "..kRk..", ".kRRRk.", ".kRRRk.", "kRRRRRk", "kkk.kkk"]
	for y in 7:
		for x in 7:
			var c: String = rows[y][x]
			if c != ".":
				img.set_pixel(x, y, Color(1, 1, 1) if c == "k" else Color(0.9, 0.15, 0.12))
	return ImageTexture.create_from_image(img)


func _make_minimap() -> void:
	var vb := get_tree().root.find_child("StarterVillage", true, false)
	if vb and vb.has_method("minimap_image"):
		_world_img = ImageTexture.create_from_image(vb.minimap_image(MINI_HALF))
		_minimap.texture = _world_img
		_mm_tex["town"] = _world_img
	for npc in get_tree().get_nodes_in_group("npc"):
		var dot := ColorRect.new()
		dot.color = Color(1.0, 0.85, 0.2)
		dot.size = Vector2(6, 6)
		dot.set_meta("node", npc)
		dot.tooltip_text = tr(npc.npc_name)
		_map_dots.add_child(dot)


func _set_minimap_area(ar: String) -> void:
	_mm_area = ar
	var vb := VillageBuilder.current
	if ar == "town" or vb == null or not VillageBuilder.AREAS.has(ar):
		_mm_center = Vector2.ZERO
		_mm_half = Vector2(MINI_HALF, MINI_HALF)
		if _mm_tex.has("town"):
			_minimap.texture = _mm_tex.town
		return
	var r: Rect2 = VillageBuilder.AREAS[ar]
	_mm_center = r.get_center()
	_mm_half = r.size * 0.5
	if not _mm_tex.has(ar):
		_mm_tex[ar] = ImageTexture.create_from_image(vb.minimap_image_area(ar))
	_minimap.texture = _mm_tex[ar]


func _update_minimap() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null or _minimap.texture == null:
		return
	var ar := VillageBuilder.area_at(p.global_position)
	var indoor := ar.begins_with("guild") or ar == "smithy"
	_map_indoor.visible = indoor
	_map_dots.visible = not indoor
	_map_title.text = tr(VillageBuilder.AREA_NAMES[ar])
	if indoor:
		return
	if ar != _mm_area:
		_set_minimap_area(ar)
	var center := (Vector2(p.global_position.x, p.global_position.z) - _mm_center + _mm_half) / (_mm_half * 2.0)
	var m := _minimap.material as ShaderMaterial
	m.set_shader_parameter("center", center)
	m.set_shader_parameter("zoom", _map_zoom)
	var cam := get_viewport().get_camera_3d()
	var me := _map_dots.get_node("Me") as Control
	var model := p.get_node_or_null("Model") as Node3D
	if model:
		var f := model.global_transform.basis.z
		me.rotation = atan2(f.x, -f.z)
	for old in _mon_dots.keys():
		if not is_instance_valid(old): _mon_dots.erase(old)
	for mo in get_tree().get_nodes_in_group("monster"):
		if not _mon_dots.has(mo):
			var md := ColorRect.new()
			md.color = Color(0.95, 0.25, 0.2)
			md.size = Vector2(4, 4)
			md.set_meta("node", mo)
			md.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_map_dots.add_child(md)
			_mon_dots[mo] = md
		(_mon_dots[mo] as Control).set_meta("alive", mo.is_alive())
	for dot in _map_dots.get_children():
		if not dot.has_meta("node"):
			continue
		var reference = dot.get_meta("node")
		if not is_instance_valid(reference):
			_map_dots.remove_child(dot)
			dot.queue_free()
			continue
		if dot.has_meta("alive") and not dot.get_meta("alive"):
			dot.visible = false
			continue
		var n := reference as Node3D
		var uv := (Vector2(n.global_position.x, n.global_position.z) - _mm_center + _mm_half) / (_mm_half * 2.0)
		var rel := (uv - center) / _map_zoom
		dot.visible = rel.length() < 0.47
		dot.position = _minimap.size * (Vector2(0.5, 0.5) + rel) - dot.size * 0.5
	if cam:
		pass


func _build_tracker() -> void:
	var p := _hud_panel(R_GREEN)
	p.custom_minimum_size = Vector2(220, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var hd := HBoxContainer.new()
	var ttl := _label("Quests", 13, TITLE, true)
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(ttl)
	# one tap: walk to every quest, hunt, report back and take the next one
	_qauto_btn = Button.new()
	_qauto_btn.focus_mode = Control.FOCUS_NONE
	_qauto_btn.toggle_mode = true
	_qauto_btn.text = "ออโต้เควส" if TranslationServer.get_locale().begins_with("th") else "Auto Quest"
	_qauto_btn.tooltip_text = "Walk to every quest automatically, hunt, report back and continue with the next one"
	_qauto_btn.add_theme_font_size_override("font_size", 11)
	_qauto_btn.custom_minimum_size = Vector2(0, 22)
	_qauto_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_color_button(_qauto_btn, PARCH_D)
	_qauto_btn.toggled.connect(_set_quest_auto)
	hd.add_child(_qauto_btn)
	hd.add_child(_key_hint_label("J"))
	v.add_child(hd)
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	v.add_child(sep)
	_tracker_box = VBoxContainer.new()
	_tracker_box.add_theme_constant_override("separation", 4)
	v.add_child(_tracker_box)
	_tracker = {"panel": p}


# ================================================================== chat
func _build_chat() -> void:
	var p := _hud_panel(R_GRAY)
	_chat_panel = p
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var hb := HBoxContainer.new()
	hb.add_child(_icon_rect(UiIcons.tex("chat", 1), 16))
	hb.add_child(_label("Chat", 12, INK_L, true))
	v.add_child(hb)
	_chat = RichTextLabel.new()
	_chat.bbcode_enabled = true
	_chat.scroll_following = true
	_chat.custom_minimum_size = Vector2(320, 96)
	_chat.add_theme_font_size_override("normal_font_size", 12)
	_chat.add_theme_color_override("default_color", INK)
	var sb := _sb(Color(0, 0, 0, 0.35), SLOT_B, 2, 2, 6)
	_chat.add_theme_stylebox_override("normal", sb)
	v.add_child(_chat)
	# online chat: type and press Enter (Enter also opens the box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	v.add_child(row)
	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = tr("Press Enter to chat with everyone online")
	_chat_input.max_length = 160
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.custom_minimum_size = Vector2(0, 24)
	_chat_input.add_theme_font_size_override("font_size", 12)
	_chat_input.add_theme_stylebox_override("normal", _sb(Color(0, 0, 0, 0.3), SLOT_B, 1, 3, 5))
	_chat_input.text_submitted.connect(_on_chat_submit)
	row.add_child(_chat_input)
	_online_label = _label("", 11, INK_L)
	row.add_child(_online_label)
	Net.status_changed.connect(_on_net_status)
	_on_net_status(Net.online, Net.player_count())


var _chat_input: LineEdit
var _online_label: Label


func _on_chat_submit(text: String) -> void:
	if text.strip_edges() != "":
		Net.send_chat(text)
	_chat_input.clear()
	_chat_input.release_focus()


func _on_net_status(on: bool, count: int) -> void:
	if _online_label == null:
		return
	_online_label.text = (tr("Online %d") % count) if on else tr("Offline")
	_online_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.6) if on else INK_L)


func add_message(text: String, color := Color(1, 1, 1)) -> void:
	if _chat == null:
		return
	# light colours from the game log are darkened so they read on parchment
	var c := color
	if c.get_luminance() < 0.5:
		c = c.lightened(0.55)
	_chat.append_text("[color=#%s]%s[/color]\n" % [c.to_html(false), tr(text)])


# ================================================================== hotbar (F1-F8 + 1-8) + auto + cast bar + buffs
func _slot_icon(id: String) -> Texture2D:
	if id == "":
		return null
	if Items.DB.has(id):
		return Items.icon(id)
	return SkillDB.icon(id)


func _build_hotbar() -> void:
	var panel := _hud_panel(R_GRAY)
	var hs := panel.get_theme_stylebox("panel") as StyleBoxFlat
	hs.content_margin_left = 8
	hs.content_margin_right = 8
	hs.content_margin_top = 8
	hs.content_margin_bottom = 8
	_hot_panel = panel
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 5)
	panel.add_child(h)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	h.add_child(rows)
	var row: HBoxContainer
	for i in Game.HOTBAR_SIZE:
		if i % 8 == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			rows.add_child(row)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(44, 44)
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for st in ["normal", "hover", "pressed"]:
			var s := _sb({"normal": SLOT, "hover": Color(1, 1, 1, 0.08), "pressed": Color(GOLD, 0.25)}[st],
				{"normal": SLOT_B, "hover": GOLD, "pressed": GOLD}[st], 1, 6, 8)
			b.add_theme_stylebox_override(st, s)
		b.add_theme_constant_override("icon_max_width", 30)
		b.pressed.connect(func() -> void: activate_hotkey(i))
		b.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
				Game.hotbar[i] = ""
				_refresh_hotbar())
		# cooldown: a dark shade that drains from the top, with seconds left
		var shade := ColorRect.new()
		shade.color = Color(0.02, 0.03, 0.06, 0.72)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.visible = false
		shade.anchor_right = 1.0
		shade.anchor_bottom = 1.0
		shade.anchor_top = 0.0
		b.add_child(shade)
		var secs := _outlined(_label("", 15, Color(1.0, 0.92, 0.6), true), Color(0, 0, 0), 4)
		secs.set_anchors_preset(Control.PRESET_FULL_RECT)
		secs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		secs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		secs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		secs.visible = false
		b.add_child(secs)
		_hot_cd.append([shade, secs])
		var key := _label(("F%d" % (i + 1)) if i < 8 else str(i - 7), 10, INK_L, true)
		key.position = Vector2(4, 0)
		key.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		b.add_child(key)
		var cnt := _count_label(b, "")
		row.add_child(b)
		_hot_slots.append(cnt)
		if i % 8 == 3:
			var sep := VSeparator.new()
			sep.add_theme_stylebox_override("separator", _sb(Color(1, 1, 1, 0.1), Color(0, 0, 0, 0), 0, 0, 0))
			sep.add_theme_constant_override("separation", 6)
			row.add_child(sep)
	var sep2 := VSeparator.new()
	sep2.add_theme_stylebox_override("separator", _sb(Color(1, 1, 1, 0.1), Color(0, 0, 0, 0), 0, 0, 0))
	sep2.add_theme_constant_override("separation", 8)
	h.add_child(sep2)
	# AUTO toggle + its settings
	var auto := Button.new()
	auto.text = "AUTO"
	auto.focus_mode = Control.FOCUS_NONE
	auto.custom_minimum_size = Vector2(84, 92)
	auto.icon = _menu_art("auto")
	auto.expand_icon = false
	auto.add_theme_constant_override("icon_max_width", 26)
	auto.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	auto.tooltip_text = "Auto hunt (Z)"
	auto.add_theme_font_override("font", _font_b)
	auto.add_theme_font_size_override("font_size", 14)
	auto.pressed.connect(func() -> void:
		var p := get_tree().get_first_node_in_group("player")
		if p:
			p.toggle_auto())
	_key_hint(auto, "Z")
	_auto_btn = auto
	# running lights around the frame while auto is on
	_auto_glow = Control.new()
	_auto_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_auto_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_auto_glow.draw.connect(_draw_auto_glow)
	auto.add_child(_auto_glow)
	h.add_child(auto)
	var cfg := _round_button("gear", "Auto Settings", func() -> void: toggle(_autoset.panel), 48)
	h.add_child(cfg)
	# cast bar (above the hotbar)
	_cast_bar = ProgressBar.new()
	_cast_bar.show_percentage = false
	_cast_bar.custom_minimum_size = Vector2(220, 10)
	_cast_bar.max_value = 1.0
	_cast_bar.add_theme_stylebox_override("background", _sb(Color(0, 0, 0, 0.6), Color(GOLD, 0.5), 1, 5, 0))
	_cast_bar.add_theme_stylebox_override("fill", _sb(Color(0.5, 0.75, 1.0), Color(0.75, 0.9, 1.0), 0, 5, 0))
	_cast_bar.visible = false
	_root.add_child(_cast_bar)
	# buff icons (under the portrait panel)
	_buff_row = HBoxContainer.new()
	_buff_row.add_theme_constant_override("separation", 4)
	_root.add_child(_buff_row)


func _refresh_hotbar() -> void:
	for i in Game.HOTBAR_SIZE:
		var id: String = Game.hotbar[i]
		var lbl: Label = _hot_slots[i]
		var b := lbl.get_parent() as Button
		b.icon = _slot_icon(id)
		if id == "":
			lbl.text = ""
			b.tooltip_text = tr("Empty slot. Learn skills in the Skill window (K).")
		elif Items.DB.has(id):
			lbl.text = str(Game.count(id))
			b.tooltip_text = Items.item_name(id) + "\n" + Items.desc(id)
		else:
			var lv := Game.slv(id)
			lbl.text = str(SkillDB.sp_cost(id, lv))
			b.tooltip_text = "%s  Lv %d\n%s\n%s   SP %d" % [tr(Game.skill_name(id)), lv, tr(SkillDB.info(id).desc), SkillDB.effect(id, lv), SkillDB.sp_cost(id, lv)]
	if _auto_btn:
		_color_button(_auto_btn, BTN_GREEN if Game.auto_on else PARCH_D)


## Point at distance `d` along a rectangle's border (clockwise from the top-left).
func _rect_point(r: Rect2, d: float) -> Vector2:
	var w := r.size.x
	var h := r.size.y
	d = fposmod(d, 2.0 * (w + h))
	if d < w:
		return r.position + Vector2(d, 0)
	d -= w
	if d < h:
		return r.position + Vector2(w, d)
	d -= h
	if d < w:
		return r.position + Vector2(w - d, h)
	return r.position + Vector2(0, h - (d - w))


func _draw_auto_glow() -> void:
	if not Game.auto_on:
		return
	var r := Rect2(Vector2(1.5, 1.5), _auto_glow.size - Vector2(3, 3))
	var per := 2.0 * (r.size.x + r.size.y)
	var pulse := 0.5 + 0.5 * sin(_auto_glow_t * 4.0)
	_auto_glow.draw_rect(r.grow(1.0), Color(1.0, 0.8, 0.3, 0.18 + 0.15 * pulse), false, 5.0)
	_auto_glow.draw_rect(r, Color(1.0, 0.88, 0.45, 0.45 + 0.3 * pulse), false, 1.5)
	for k in 2:
		var head := _auto_glow_t * per * 0.45 + k * per * 0.5
		var n := 34
		var core := Color(1.0, 0.9, 0.45) if k == 0 else Color(0.45, 1.0, 0.8)
		for i in n:
			var a := pow(1.0 - float(i) / n, 1.4)
			var p0 := _rect_point(r, head - i * 3.0)
			var p1 := _rect_point(r, head - (i + 1) * 3.0)
			_auto_glow.draw_line(p0, p1, Color(core, a * 0.35), 9.0 * a + 2.0, true)
			_auto_glow.draw_line(p0, p1, Color(core.lerp(Color.WHITE, 0.4), a), 3.5 * a + 1.0, true)
		var hp := _rect_point(r, head)
		_auto_glow.draw_circle(hp, 7.0, Color(core, 0.35))
		_auto_glow.draw_circle(hp, 3.5, Color(1, 1, 0.95, 1.0))


func _update_hot_cooldowns() -> void:
	for i in mini(_hot_cd.size(), Game.HOTBAR_SIZE):
		var id: String = Game.hotbar[i]
		var shade: ColorRect = _hot_cd[i][0]
		var secs: Label = _hot_cd[i][1]
		var left := 0.0
		var total := 1.0
		if id != "" and not Items.DB.has(id):
			left = Game.cooldown_left(id)
			total = maxf(0.01, SkillDB.cooldown(id, Game.slv(id)))
		if left <= 0.0:
			if shade.visible:
				shade.visible = false
				secs.visible = false
			continue
		shade.visible = true
		secs.visible = true
		shade.anchor_top = 1.0 - clampf(left / total, 0.0, 1.0)
		shade.offset_top = 0
		secs.text = ("%.1f" % left) if left < 10.0 else str(int(ceil(left)))


func activate_hotkey(i: int) -> void:
	if i < 0 or i >= Game.HOTBAR_SIZE:
		return
	var id: String = Game.hotbar[i]
	var p := get_tree().get_first_node_in_group("player")
	if id == "" or p == null or not p.is_alive():
		return
	if Items.DB.has(id):
		Game.use_item(id)
	else:
		p.use_skill(id)


func _refresh_buffs() -> void:
	for c in _buff_row.get_children():
		_buff_row.remove_child(c)
		c.queue_free()
	for id in Game.buffs:
		var f := PanelContainer.new()
		f.add_theme_stylebox_override("panel", _sb(WOOD_D, Color(GOLD, 0.7), 1, 5, 2))
		f.tooltip_text = "%s (%ds)" % [tr(Game.skill_name(id)), int(Game.buffs[id].t)]
		f.mouse_filter = Control.MOUSE_FILTER_STOP
		var ic := _icon_rect(SkillDB.icon(id, 24), 24)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		f.add_child(ic)
		var t := _outlined(_label("%d" % int(Game.buffs[id].t), 9, CREAM, true), WOOD_D, 3)
		t.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.add_child(t)
		_buff_row.add_child(f)


# ================================================================== skill window (K)
var _skill_sel := ""                 # skill shown in the detail card
var _skill_tree: Control
var _skill_detail: VBoxContainer
var _skill_joblv: Label
var _skill_jobbar: ProgressBar
var _skill_preview_branch := "a"     # branch previewed on a 2nd/3rd job tab before choosing


func _build_skills() -> void:
	_skills = _window("Skills", Vector2(300, 60), Vector2(540, 0), R_PURPLE)
	var top := HBoxContainer.new()
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 2)
	_skill_job = _label("", 15, CREAM)
	_skill_job.add_theme_font_override("font", _font_t)
	tv.add_child(_skill_job)
	_skill_joblv = _label("", 11, INK_L)
	tv.add_child(_skill_joblv)
	_skill_jobbar = ProgressBar.new()
	_skill_jobbar.show_percentage = false
	_skill_jobbar.custom_minimum_size = Vector2(180, 6)
	_skill_jobbar.add_theme_stylebox_override("background", _sb(Color(0, 0, 0, 0.5), Color(1, 1, 1, 0.08), 1, 3, 0))
	_skill_jobbar.add_theme_stylebox_override("fill", _sb(R_TEAL, R_TEAL, 0, 3, 0))
	tv.add_child(_skill_jobbar)
	top.add_child(tv)
	var pp := _pill()
	_skill_pts = _label("", 13, GOLD, true)
	pp.add_child(_skill_pts)
	pp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(pp)
	_skills.body.add_child(top)
	# tier tabs: Novice / 1st job / 2nd job / 3rd job
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	_skill_tabs = []
	for t in range(0, 6):
		var b := _button("", func() -> void:
			_skill_tab = t
			_skill_sel = ""
			_refresh_skills(), 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 40
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true
		tabs.add_child(b)
		_skill_tabs.append(b)
	_skills.body.add_child(tabs)
	_skill_adv = VBoxContainer.new()
	_skill_adv.add_theme_constant_override("separation", 6)
	_skills.body.add_child(_skill_adv)
	var sc := ScrollContainer.new()
	sc.name = "TreeScroll"
	sc.custom_minimum_size = Vector2(0, 230)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_skill_tree = Control.new()
	_skill_tree.draw.connect(_draw_skill_links)
	sc.add_child(_skill_tree)
	_skills.body.add_child(sc)
	_skill_detail = VBoxContainer.new()
	_skills.body.add_child(_skill_detail)
	# kept for older code paths that add rows to the list
	_skill_list = VBoxContainer.new()
	_skill_list.visible = false
	_skills.body.add_child(_skill_list)
	_skills.body.add_child(_label("Tap a skill to see it. Lines show which skill must be learned first.", 11, INK_L))
	_skills.panel.hide()
	_skills.panel.visibility_changed.connect(func() -> void:
		if _skills.panel.visible:
			_skill_tab = Game.job_tier
			_skill_sel = ""
			_refresh_skills())


## Skills shown on a tab (branch-aware; a not-yet-chosen branch is previewed).
func _tab_skills(t: int) -> Array:
	if t == 0:
		return SkillDB.NOVICE_SKILLS
	if Game.job_id == "novice":
		return []
	var br := Game.job_branch if Game.job_tier >= 2 else _skill_preview_branch
	return SkillDB.tier_skills(Game.job_id, t, br)


func _tab_title(t: int) -> String:
	if t == 0:
		return tr("Novice")
	if Game.job_id == "novice":
		return "?"
	if t >= 2 and Game.job_tier < 2:
		return "%s / %s" % [tr(SkillDB.tier_name(Game.job_id, t, "a")), tr(SkillDB.tier_name(Game.job_id, t, "b"))]
	return tr(Game.tier_title(t))


func _refresh_skills() -> void:
	if _skills.is_empty():
		return
	_skill_tab = clampi(_skill_tab, 0, 5)
	_skill_job.text = tr(Game.job)
	var jmax: int = SkillDB.JOB_MAX[Game.job_tier]
	_skill_joblv.text = tr("Job Lv %d / %d") % [Game.job_level, jmax] + ("" if Game.job_level >= jmax else "   (%d / %d)" % [Game.job_exp, Game.job_exp_to_next()])
	_skill_jobbar.max_value = maxi(1, Game.job_exp_to_next())
	_skill_jobbar.value = Game.job_exp if Game.job_level < jmax else _skill_jobbar.max_value
	_skill_pts.text = tr("Skill Points: %d") % Game.skill_points
	if _skill_badge:
		_skill_badge.visible = Game.skill_points > 0 or Game.advance_block() == ""
	for t in range(0, 6):
		var b: Button = _skill_tabs[t]
		var locked := t > Game.job_tier
		b.text = "%s\n%s" % [tr(SkillDB.tier_label(t)), _tab_title(t)]
		b.tooltip_text = b.text
		b.icon = UiIcons.tex("lock", 1) if locked else null
		b.modulate = Color(1, 1, 1) if not locked or t == _skill_tab else Color(0.75, 0.75, 0.8)
		_set_tab(b, t == _skill_tab)
	for box in [_skill_adv, _skill_detail, _skill_list]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	var builds := HBoxContainer.new()
	for option in [["attack", "ลงแต้มสายโจมตี"], ["support", "ลงแต้มสายป้องกัน"], ["balanced", "ลงแต้มสมดุล"]]:
		builds.add_child(_button(option[1], Game.allocate_build.bind(option[0]), 0))
	_skill_adv.add_child(builds)
	# job change card on the next locked tier
	if _skill_tab == Game.job_tier + 1:
		_skill_adv.add_child(_job_change_card())
	elif _skill_tab > Game.job_tier + 1:
		_skill_adv.add_child(_label(tr("Requires job change: %s") % _tab_title(_skill_tab - 1), 11, BAD))
	# branch preview switch for a 2nd / 3rd job tab before the branch is chosen
	if _skill_tab >= 2 and Game.job_tier < 2 and Game.job_id != "novice":
		var bh := HBoxContainer.new()
		bh.add_theme_constant_override("separation", 6)
		bh.add_child(_label(tr("Preview:"), 11, INK_L))
		for br in ["a", "b"]:
			var pb := _button(SkillDB.tier_name(Game.job_id, _skill_tab, br), func() -> void:
				_skill_preview_branch = br
				_skill_sel = ""
				_refresh_skills(), 0)
			pb.add_theme_font_size_override("font_size", 11)
			_set_tab(pb, _skill_preview_branch == br)
			bh.add_child(pb)
		_skill_adv.add_child(bh)
	_layout_skill_tree(_tab_skills(_skill_tab))
	# keep the window on a phone / 720p screen: shorter tree while the job change card shows
	var tsc := _skill_tree.get_parent() as ScrollContainer
	if tsc:
		tsc.custom_minimum_size.y = 120 if _skill_adv.get_child_count() > 1 else (150 if _skill_adv.get_child_count() > 0 else 230)
	if _skill_sel == "" or not (_skill_sel in _tab_skills(_skill_tab)):
		var list := _tab_skills(_skill_tab)
		_skill_sel = list[0] if list.size() > 0 else ""
	if _skill_sel != "":
		_skill_detail.add_child(_skill_row(_skill_sel))
	_skill_tree.queue_redraw()


## Next job change: the requirements and one button per choice.
func _job_change_card() -> Control:
	var card := PanelContainer.new()
	var cs := _sb(Color(GOLD, 0.08), Color(GOLD, 0.45), 1, 6, 10)
	cs.content_margin_top = 8
	cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	v.add_child(_label(tr("Job Change"), 14, TITLE, true))
	var t := Game.job_tier
	var need := tr("Job Lv %d") % SkillDB.JOB_CHANGE_AT[t]
	if SkillDB.JOB_CHANGE_BASE[t] > 1:
		need += "  +  " + tr("Base Lv %d") % SkillDB.JOB_CHANGE_BASE[t]
	if t == 0:
		need += "  +  " + tr("%s Lv 9") % tr(Game.skill_name("basic_training"))
	v.add_child(_label(need, 11, INK_L))
	var block := Game.advance_block()
	var st := _label(block if block != "" else tr("Ready! Choose your new job."), 11, BAD if block != "" else GOOD)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size.x = 300
	v.add_child(st)
	var grid := GridContainer.new()
	grid.columns = 3 if t == 0 else 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for o in Game.advance_choices():
		var key: String = o[0]
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b := _button(tr(String(o[1])), func() -> void:
			if Game.advance_job(key):
				var pl := get_tree().get_first_node_in_group("player")
				if pl:
					FX.ring(pl, pl.global_position, Color(1.0, 0.85, 0.3, 0.9), 2.5)
					pl.model.refresh_look()
				_skill_tab = Game.job_tier
				_skill_sel = ""
				_refresh_skills()
				_refresh_equipment_if_open(), 0)
		_color_button(b, Color(0.5, 0.36, 0.12))
		b.disabled = block != ""
		b.custom_minimum_size.y = 36
		if t == 0:
			b.icon = ImageTexture.create_from_image(Avatar.weapon_image(Avatar.JOBS[key].sprite, 24))
			if key == Game.planned_job:
				b.text += " ★"
		cell.add_child(b)
		var desc := ""
		if t == 1:
			desc = SkillDB.BRANCH_DESC.get(Game.job_id, {}).get(key, "")
		elif t == 0:
			desc = tr(String(Avatar.JOBS[key].desc)).get_slice("\n", 0)
		if desc != "":
			var dl := _label(tr(desc), 10, INK_L)
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			dl.custom_minimum_size.x = 140
			cell.add_child(dl)
		var wt := Items.weapon_types_for(key if t == 0 else Game.job_id, t + 1, key if t >= 1 else "a")
		var names := []
		for w in wt:
			names.append(tr(Items.WEAPON_TYPE_NAMES.get(w, w)))
		var wl := _label(tr("Weapons: %s") % ", ".join(names), 10, ACCENT)
		wl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		wl.custom_minimum_size.x = 140
		cell.add_child(wl)
		grid.add_child(cell)
	v.add_child(grid)
	return card


func _refresh_equipment_if_open() -> void:
	_refresh_equipment()


## Skill tree: column = how many prerequisites deep (inside this tab), lines
## from each prerequisite to the skills it unlocks.
var _tree_pos := {}
const TREE_CELL := Vector2(104, 82)


func _layout_skill_tree(list: Array) -> void:
	for c in _skill_tree.get_children():
		_skill_tree.remove_child(c)
		c.queue_free()
	_tree_pos = {}
	var depth := {}
	for _pass in 6:
		for id in list:
			var d := 0
			for r in SkillDB.info(id).get("req", {}):
				if r in list:
					d = maxi(d, int(depth.get(r, 0)) + 1)
			depth[id] = d
	var rows := {}
	var max_col := 0
	var max_row := 0
	for id in list:
		var col: int = depth[id]
		var row: int = rows.get(col, 0)
		if SkillDB.tier(id) >= 4:col=list.find(id);row=0
		rows[col] = row + 1
		_tree_pos[id] = Vector2i(col, row)
		max_col = maxi(max_col, col)
		max_row = maxi(max_row, row)
	_skill_tree.custom_minimum_size = Vector2((max_col + 1) * TREE_CELL.x + 8, (max_row + 1) * TREE_CELL.y + 4)
	for id in list:
		var cell: Vector2i = _tree_pos[id]
		var lv := Game.slv(id)
		var node := VBoxContainer.new()
		node.position = Vector2(cell.x * TREE_CELL.x + 8, cell.y * TREE_CELL.y + 2)
		node.custom_minimum_size = Vector2(TREE_CELL.x - 16, TREE_CELL.y - 6)
		node.add_theme_constant_override("separation", 0)
		var ib := _slot(52)
		ib.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		ib.add_theme_constant_override("icon_max_width", 42)
		ib.icon = SkillDB.icon(id, 42)
		ib.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var learnable := Game.learn_block(id) == ""
		ib.modulate = Color(1, 1, 1) if lv > 0 else (Color(0.85, 0.85, 0.9) if learnable else Color(0.45, 0.45, 0.5))
		if id == _skill_sel:
			ib.add_theme_stylebox_override("normal", _sb(Color(GOLD, 0.2), GOLD, 2, 6, 4))
		ib.tooltip_text = tr(Game.skill_name(id))
		ib.pressed.connect(func() -> void:
			_skill_sel = id
			_refresh_skills())
		node.add_child(ib)
		var nm := _label(tr(Game.skill_name(id)), 10, CREAM if lv > 0 else INK_L, lv > 0)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.custom_minimum_size.x = TREE_CELL.x - 16
		node.add_child(nm)
		var ll := _label("%d/%d" % [lv, int(SkillDB.info(id).max)], 10, GOLD if lv > 0 else INK_L, true)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		node.add_child(ll)
		_skill_tree.add_child(node)


func _draw_skill_links() -> void:
	for id in _tree_pos:
		var to: Vector2i = _tree_pos[id]
		for r in SkillDB.info(id).get("req", {}):
			if not _tree_pos.has(r):
				continue
			var from: Vector2i = _tree_pos[r]
			var a := Vector2(from.x * TREE_CELL.x + 8 + (TREE_CELL.x - 16) * 0.5 + 27, from.y * TREE_CELL.y + 2 + 26)
			var b := Vector2(to.x * TREE_CELL.x + 8 + (TREE_CELL.x - 16) * 0.5 - 27, to.y * TREE_CELL.y + 2 + 26)
			var met := Game.slv(r) >= int(SkillDB.info(id).req[r])
			var c := Color(GOLD, 0.9) if met else Color(0.55, 0.55, 0.6, 0.7)
			var mid := (a.x + b.x) * 0.5
			_skill_tree.draw_polyline(PackedVector2Array([a, Vector2(mid, a.y), Vector2(mid, b.y), b]), c, 2.0, true)
			_skill_tree.draw_circle(b, 3.0, c)


func _skill_row(id: String) -> Control:
	var s := SkillDB.info(id)
	var lv := Game.slv(id)
	var block := Game.learn_block(id)
	var tier_locked := not (id in Game.job_skills())
	var card := PanelContainer.new()
	var cs := _sb(Color(1, 1, 1, 0.045) if lv > 0 else Color(0, 0, 0, 0.3), Color(GOLD, 0.35) if lv > 0 else SLOT_B, 1, 6, 8)
	cs.content_margin_top = 6
	cs.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", cs)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	card.add_child(h)
	var ib := _slot(48)
	ib.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ib.add_theme_constant_override("icon_max_width", 40)
	ib.icon = SkillDB.icon(id, 40)
	ib.modulate = Color(1, 1, 1) if lv > 0 else Color(0.55, 0.55, 0.6)
	ib.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if SkillDB.is_active(id):
		ib.tooltip_text = tr("Put on hotbar")
		ib.pressed.connect(func() -> void:
			if Game.slv(id) <= 0 or id in Game.hotbar:
				return
			for i in Game.HOTBAR_SIZE:
				if Game.hotbar[i] == "":
					Game.hotbar[i] = id
					break
			_refresh_hotbar())
	h.add_child(ib)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := HBoxContainer.new()
	title.add_theme_constant_override("separation", 6)
	title.add_child(_label(tr(s.name), 13, CREAM if lv > 0 else INK, true))
	var kind := _label(tr("Passive" if s.type == "passive" else ("Buff" if s.type == "buff" else "Active")), 10,
		R_TEAL if s.type == "passive" else (R_YELLOW if s.type == "buff" else R_RED), true)
	kind.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.add_child(kind)
	v.add_child(title)
	var d := _label(tr(s.desc), 11, INK_L)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 280
	v.add_child(d)
	var eff := SkillDB.effect(id, maxi(lv, 1))
	if SkillDB.is_active(id):
		eff += "   SP %d" % SkillDB.sp_cost(id, maxi(lv, 1))
	var el := _label(eff, 11, ACCENT, true)
	el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	el.custom_minimum_size.x = 280
	v.add_child(el)
	if block != "" and block != tr("Max level") and block != tr("No skill points") and not tier_locked:
		v.add_child(_label(block, 11, BAD))
	h.add_child(v)
	var lvl := _label("Lv %d/%d" % [lv, s.max], 12, GOLD if lv >= int(s.max) else INK, true)
	lvl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(lvl)
	var plus := _button("+", func() -> void: Game.learn_skill(id), 30)
	_color_button(plus, BTN_GREEN)
	plus.disabled = block != ""
	plus.tooltip_text = block if block != "" else tr("Learn")
	plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(plus)
	return card


var _monster_map_portraits := {}
var _wmap_player_level := -1


func _monster_map_portrait(zone: Dictionary) -> Texture2D:
	var key: String = zone.name
	if not _monster_map_portraits.has(key):
		_monster_map_portraits[key] = Portrait.monster(self, zone)
	return (_monster_map_portraits[key] as SubViewport).get_texture()


func _hunting_advice(zone: Dictionary, player_level: int) -> String:
	if absi(int(zone.lv) - player_level) > 3:
		return ""
	return tr("Similar-level boss: a party is recommended.") if zone.get("boss", false) else tr("Recommended: similar level, suitable for leveling.")


# ================================================================== world map (M)
func _build_worldmap() -> void:
	_wmap = _window("World Map", Vector2(200, 40), Vector2(0, 0), R_TEAL)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	_wmap.body.add_child(h)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _sb(Color(0.3, 0.5, 0.25), GOLD_D, 3, 4, 0))
	h.add_child(frame)
	_wmap_img = TextureRect.new()
	_wmap_img.custom_minimum_size = Vector2(WMAP_PX, WMAP_PX)
	_wmap_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wmap_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wmap_img.mouse_filter = Control.MOUSE_FILTER_STOP
	_wmap_img.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if _wmap_world:
				_world_click(e.position)
				return
			var w := _wmap_to_world(e.position)
			var p := get_tree().get_first_node_in_group("player")
			if p:
				p.go_to(w)
				add_message(tr("Walking to the selected spot..."), INK_L))
	frame.add_child(_wmap_img)
	_wmap_marks = Control.new()
	_wmap_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wmap_img.add_child(_wmap_marks)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 4)
	side.custom_minimum_size.x = 270
	h.add_child(side)
	side.add_child(_label("Click the map, an NPC or a hunting ground to travel there automatically.", 11, INK_L))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(270, WMAP_PX - 40)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	_wmap_list = VBoxContainer.new()
	_wmap_list.add_theme_constant_override("separation", 3)
	_wmap_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_wmap_list)
	_wmap.panel.hide()
	_wmap.panel.visibility_changed.connect(func() -> void:
		if _wmap.panel.visible:
			_fill_worldmap())


func _wmap_to_world(local: Vector2) -> Vector3:
	var k := (_wm_half * 2.0) / WMAP_PX
	return Vector3(local.x * k.x - _wm_half.x + _wm_center.x, 0, local.y * k.y - _wm_half.y + _wm_center.y)


func _world_to_wmap(p: Vector3) -> Vector2:
	var k := Vector2(WMAP_PX, WMAP_PX) / (_wm_half * 2.0)
	return Vector2((p.x - _wm_center.x + _wm_half.x) * k.x, (p.z - _wm_center.y + _wm_half.y) * k.y)


# ---- world overview: the continent with Aldenvale in the middle and the four regions
const WORLD_SPOTS := {"town": Vector2(0.5, 0.5), "verdant": Vector2(0.22, 0.34), "ember": Vector2(0.74, 0.22),
	"frost": Vector2(0.8, 0.62), "desert": Vector2(0.42, 0.8)}
const WORLD_COLORS := {"town": Color(0.5, 0.72, 0.36), "verdant": Color(0.2, 0.48, 0.22), "ember": Color(0.45, 0.2, 0.15),
	"frost": Color(0.86, 0.92, 0.98), "desert": Color(0.88, 0.75, 0.48)}
var _overview: ImageTexture


func _overview_tex() -> ImageTexture:
	if _overview:
		return _overview
	var N := 256
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	for y in N:
		for x in N:
			var u := Vector2(x, y) / N
			var best := 9.0
			var second := 9.0
			var who := ""
			for k in WORLD_SPOTS:
				var d := u.distance_to(WORLD_SPOTS[k]) * (1.25 if k == "town" else 1.0)
				if d < best:
					second = best
					best = d
					who = k
				elif d < second:
					second = d
			var ang := atan2(u.y - 0.52, u.x - 0.5)
			var coast := u.distance_to(Vector2(0.5, 0.52)) + sin(ang * 5.0) * 0.025 + sin(ang * 11.0 + 1.3) * 0.012 + (PixelTex.h(x / 8, y / 8, 3) - 0.5) * 0.03
			var c: Color
			if coast > 0.44:
				c = Color(0.18, 0.42, 0.7).lightened(0.12 if coast < 0.47 else 0.0)
				if PixelTex.h(x / 3, y / 2, 9) > 0.93:
					c = c.lightened(0.25)
			elif coast > 0.425:
				c = Color(0.9, 0.84, 0.62)
			else:
				c = WORLD_COLORS[who]
				if second - best < 0.012:
					c = c.darkened(0.35)
				c = c.darkened(PixelTex.h(x / 2, y / 2, 5) * 0.12)
				if who == "ember" and u.distance_to(WORLD_SPOTS.ember + Vector2(0.03, -0.03)) < 0.04:
					c = Color(1.0, 0.45, 0.1)
			img.set_pixel(x, y, c)
	_overview = ImageTexture.create_from_image(img)
	return _overview


func _world_click(local: Vector2) -> void:
	var u := local / WMAP_PX
	var best := ""
	var bd := 0.12
	for k in WORLD_SPOTS:
		var d := u.distance_to(WORLD_SPOTS[k])
		if d < bd:
			bd = d
			best = k
	if best != "":
		_go_area(best)


func _go_area(a: String) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var target := Vector3(0, 0, 8)
	if VillageBuilder.AREAS.has(a):
		var r: Rect2 = VillageBuilder.AREAS[a]
		target = Vector3(r.get_center().x, 0, r.get_center().y)
		# arrive just past the entrance warp rather than in the middle of the map
		for wp in VillageBuilder.WARPS:
			if wp.to == a:
				target = wp.dest
				break
	p.go_to(target)
	_wmap.panel.hide()
	add_message(tr("Travelling to %s...") % tr(VillageBuilder.AREA_NAMES.get(a, a)), INK_L)


func _go_npc(n: Node3D) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.talk_to(n)
		_wmap.panel.hide()


func _go_zone(z: Dictionary) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		# stop at the edge of the hunting ground that faces the town
		var c := Vector3(z.pos.x, 0, z.pos.y)
		var edge := c - c.normalized() * (float(z.r) * 0.6) if String(z.get("area", "town")) == "town" else c
		p.go_to(edge)
		_wmap.panel.hide()
		add_message(tr("Travelling to %s (Lv %d). Press Z for auto-hunt.") % [tr(z.name), z.lv], INK_L)


func _fill_worldmap() -> void:
	_wmap_player_level = Game.base_level
	for c in _wmap_marks.get_children():
		_wmap_marks.remove_child(c)
		c.queue_free()
	for c in _wmap_list.get_children():
		_wmap_list.remove_child(c)
		c.queue_free()
	var pl := get_tree().get_first_node_in_group("player") as Node3D
	var here := VillageBuilder.area_at(pl.global_position) if pl else "town"
	if here.begins_with("guild"):
		here = "town"
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	for t in [["This map", false], ["World", true]]:
		var b := _button(t[0], func() -> void:
			_wmap_world = t[1]
			_fill_worldmap(), 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_color_button(b, BTN_GREEN if _wmap_world == t[1] else WOOD)
		tabs.add_child(b)
	_wmap_list.add_child(tabs)
	var plv := Game.base_level
	if _wmap_world:
		_fill_world_overview(here, plv)
		return
	# ---- local map of the current area
	_wm_center = Vector2.ZERO
	_wm_half = Vector2(WORLD_HALF, WORLD_HALF)
	if here == "town":
		if _world_img:
			_wmap_img.texture = _world_img
	else:
		var r: Rect2 = VillageBuilder.AREAS[here]
		_wm_center = r.get_center()
		_wm_half = r.size * 0.5
		if not _mm_tex.has(here) and VillageBuilder.current:
			_mm_tex[here] = ImageTexture.create_from_image(VillageBuilder.current.minimap_image_area(here))
		_wmap_img.texture = _mm_tex.get(here)
	_wmap_list.add_child(_label(tr(VillageBuilder.AREA_NAMES[here]) + ("  " + String(Zones.LEVELS[here]) if Zones.LEVELS.has(here) else ""), 13, TITLE, true))
	# hunting grounds
	_wmap_list.add_child(_label("Hunting grounds", 12, GOOD, true))
	var zones: Array = load("res://scripts/monsters/spawner.gd").ZONES
	for z in zones:
		if String(z.get("area", "town")) != here:
			continue
		var pos := _world_to_wmap(Vector3(z.pos.x, 0, z.pos.y))
		var col := Color(0.35, 0.8, 0.3) if z.lv <= plv + 1 else (Color(0.95, 0.75, 0.2) if z.lv <= plv + 5 else Color(0.9, 0.25, 0.2))
		var ring := _round_frame(float(z.r) * 2.0 * WMAP_PX / (_wm_half.x * 2.0) + 6.0, Color(col, 0.25), col, 2)
		ring.position = pos - ring.custom_minimum_size * 0.5
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_wmap_marks.add_child(ring)
		var boss: bool = z.get("boss", false)
		var tag := _outlined(_label(("★ " if boss else "") + "%s %d" % [tr(z.name), z.lv], 9, CREAM if not boss else Color(1.0, 0.6, 0.45), true), Color(0, 0, 0, 0.8), 3)
		tag.position = pos + Vector2(-30, 8)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_wmap_marks.add_child(tag)
		var b := _button(("★ " if boss else "") + "%s  Lv %d" % [tr(z.name), z.lv], func() -> void: _go_zone(z), 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 11)
		b.icon = _monster_map_portrait(z)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 48)
		b.custom_minimum_size.y = 58
		b.add_theme_color_override("font_color", col)
		_wmap_list.add_child(b)
		var advice := _hunting_advice(z, plv)
		if advice != "":
			var hint := _label(advice, 11, R_YELLOW if boss else GOOD)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hint.custom_minimum_size.x = 250
			_wmap_list.add_child(hint)
	# exits of this map
	var exits := []
	for wp in VillageBuilder.WARPS:
		if wp.area == here and not String(wp.to).begins_with("guild"):
			exits.append(wp)
	if exits.size() > 0:
		_wmap_list.add_child(_label("Warp gates", 12, Color(0.55, 0.85, 1.0), true))
		for wp in exits:
			var pos := _world_to_wmap(Vector3(wp.pos.x, 0, wp.pos.y))
			var ring := _round_frame(12, Color(0.4, 0.8, 1.0, 0.4), Color(0.6, 0.9, 1.0), 2)
			ring.position = pos - Vector2(6, 6)
			ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_wmap_marks.add_child(ring)
			var tag := _outlined(_label(tr(VillageBuilder.AREA_NAMES[wp.to]), 9, Color(0.7, 0.92, 1.0), true), Color(0, 0, 0, 0.8), 3)
			tag.position = pos + Vector2(-28, -18)
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_wmap_marks.add_child(tag)
			var target: Vector3 = Vector3(wp.pos.x, 0, wp.pos.y)
			var eb := _button("➜ " + tr(VillageBuilder.AREA_NAMES[wp.to]), func() -> void:
				pl.go_to(target)
				_wmap.panel.hide(), 0)
			eb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			eb.add_theme_font_size_override("font_size", 11)
			_wmap_list.add_child(eb)
	# NPCs on this map
	var npcs := []
	for n in get_tree().get_nodes_in_group("npc"):
		var na := VillageBuilder.area_at(n.global_position)
		if na == here or (here == "town" and (na.begins_with("guild") or na == "smithy")):
			npcs.append(n)
	if npcs.size() > 0:
		_wmap_list.add_child(_label("NPCs", 12, ACCENT, true))
	for n in npcs:
		if VillageBuilder.area_at(n.global_position) == here:
			var pos := _world_to_wmap(n.global_position)
			var dot := ColorRect.new()
			dot.color = Color(1.0, 0.85, 0.2)
			dot.size = Vector2(6, 6)
			dot.position = pos - Vector2(3, 3)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_wmap_marks.add_child(dot)
		var b := _button(tr(n.npc_name), func() -> void: _go_npc(n), 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 11)
		b.icon = _npc_portrait(n.npc_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 48)
		b.custom_minimum_size.y = 58
		_wmap_list.add_child(b)
	if here == "town":
		var town := _outlined(_label(tr("Aldenvale"), 12, CREAM, true), WOOD_D, 4)
		town.position = _world_to_wmap(Vector3(-14, 0, -6))
		town.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_wmap_marks.add_child(town)
	var me := _icon_rect(_arrow_tex(), 14)
	me.name = "Me"
	me.pivot_offset = Vector2(7, 7)
	_wmap_marks.add_child(me)


func _fill_world_overview(here: String, plv: int) -> void:
	_wmap_img.texture = _overview_tex()
	var base_here := here.trim_suffix("_d")
	_wmap_list.add_child(_label("Regions", 12, GOOD, true))
	for k in ["town", "verdant", "desert", "frost", "ember"]:
		var pos: Vector2 = WORLD_SPOTS[k] * WMAP_PX
		var nm := tr(VillageBuilder.AREA_NAMES[k])
		var lv := "Lv 1-20" if k == "town" else String(Zones.LEVELS[k])
		var tag := _outlined(_label(nm + "\n" + lv, 12 if k != "town" else 13, CREAM, true), Color(0, 0, 0, 0.85), 4)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.position = pos - Vector2(60, 14)
		tag.custom_minimum_size.x = 120
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_wmap_marks.add_child(tag)
		if k != "town":
			var dpos: Vector2 = pos + Vector2(0, 34)
			var dg := _outlined(_label("⚑ " + tr(VillageBuilder.AREA_NAMES[k + "_d"]), 9, Color(1.0, 0.7, 0.5), true), Color(0, 0, 0, 0.85), 3)
			dg.position = dpos - Vector2(50, 0)
			dg.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_wmap_marks.add_child(dg)
		if k == base_here:
			var me := _icon_rect(_arrow_tex(), 14)
			me.position = pos - Vector2(7, 30)
			_wmap_marks.add_child(me)
		var lo := 1 if k == "town" else int(lv.split(" ")[1].split("-")[0])
		var col := Color(0.35, 0.8, 0.3) if lo <= plv + 1 else (Color(0.95, 0.75, 0.2) if lo <= plv + 6 else Color(0.9, 0.25, 0.2))
		var b := _button("%s  %s" % [nm, lv], func() -> void: _go_area(k), 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 11)
		b.icon = UiIcons.tex("map", 1)
		b.add_theme_color_override("icon_normal_color", col)
		_wmap_list.add_child(b)
	_wmap_list.add_child(_label("Dungeons", 12, Color(1.0, 0.65, 0.45), true))
	for k in ["verdant_d", "desert_d", "frost_d", "ember_d", "chivalry_d", "abyss_d", "valhalla_d"]:
		var b := _button("%s  %s" % [tr(VillageBuilder.AREA_NAMES[k]), Zones.LEVELS[k]], func() -> void: _go_area(k), 0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 11)
		_wmap_list.add_child(b)
	_wmap_list.add_child(_label("Region gates stand at the ends of the west, south and east roads. Warp Crystals take you back to places you have visited.", 10, INK_L))


func _update_worldmap() -> void:
	if _wmap_player_level != Game.base_level:
		_fill_worldmap()
	if _wmap_world:
		return
	var me := _wmap_marks.get_node_or_null("Me") as Control
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if me == null or p == null:
		return
	me.position = _world_to_wmap(p.global_position) - Vector2(7, 7)
	var model := p.get_node_or_null("Model") as Node3D
	if model:
		var f := model.global_transform.basis.z
		me.rotation = atan2(f.x, -f.z)


# ================================================================== day / night clock
func _build_clock() -> void:
	var p := _pill()
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	_windows.append(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	_clock_icon = _icon_rect(UiIcons.tex("sun", 1), 16)
	h.add_child(_clock_icon)
	_clock_lbl = _label("", 12, CREAM, true)
	h.add_child(_clock_lbl)
	p.add_child(h)
	_root.add_child(p)
	_clock = p


func _update_clock() -> void:
	var dn := get_tree().get_first_node_in_group("daynight")
	if dn == null:
		_clock.visible = false
		return
	var hrs: float = dn.hour
	_clock_lbl.text = "%s  %02d:%02d" % [tr(Ambience.season_name()), int(hrs), int(fmod(hrs, 1.0) * 60.0)]
	var night: bool = hrs < 6.0 or hrs >= 18.5
	_clock_icon.texture = UiIcons.tex("moon" if night else "sun", 1)


# ================================================================== refresh HUD
func _refresh() -> void:
	_name_lbl.text = tr(Game.player_name)
	_job_lbl.text = tr(Game.job)
	if _rank_lbl:
		_rank_lbl.visible = Game.guild_member
		if Game.guild_member:
			var rc: Color = Guild.RANK_COLORS[Game.guild_rank]
			_rank_lbl.text = " %s " % Guild.letter()
			var rs := _sb(rc, rc.lightened(0.4), 1, 4, 3)
			rs.content_margin_top = 0
			rs.content_margin_bottom = 0
			_rank_lbl.add_theme_stylebox_override("normal", rs)
			_rank_lbl.tooltip_text = tr("Guild Rank %s (%s) - %d GP") % [Guild.letter(), tr(Guild.RANK_TITLES[Game.guild_rank]), Game.guild_points]
	var bk := "%s_%d" % [Game.job_id, Game.job_tier] + ("b" if Game.job_tier >= 2 and Game.job_branch == "b" else "")
	if bk != _banner_key and _banner:
		_banner_key = bk
		var bp := "res://assets/ui/banners/%s.png" % bk
		_banner.texture = load(bp) if ResourceLoader.exists(bp) else null
		_banner.tooltip_text = "%s  (%s)" % [tr(Game.job), tr(SkillDB.tier_label(Game.job_tier))]
		_job_lbl.tooltip_text = _banner.tooltip_text
	_lv_lbl.text = tr("Lv. %d") % Game.base_level + "  " + tr("Job %d") % Game.job_level
	_hp_bar.max_value = Game.max_hp()
	_hp_bar.value = Game.hp
	(_hp_bar.get_child(0) as Label).text = "%d / %d" % [Game.hp, Game.max_hp()]
	_sp_bar.max_value = Game.max_sp()
	_sp_bar.value = Game.sp
	(_sp_bar.get_child(0) as Label).text = "%d / %d" % [Game.sp, Game.max_sp()]
	_exp_bar.max_value = Game.exp_to_next()
	_exp_bar.value = Game.base_exp
	var exp_lbl := _exp_bar.get_child(0) as Label
	if Game.base_level >= Game.MAX_LEVEL:
		exp_lbl.text = "MAX Lv 99"
	else:
		exp_lbl.text = "EXP %.1f%%" % (100.0 * float(Game.base_exp) / maxf(1.0, float(Game.exp_to_next())))
		_exp_bar.tooltip_text = "EXP %d / %d" % [Game.base_exp, Game.exp_to_next()]
	_zeny_lbl.text = _commas(Game.zeny)
	_weight_lbl.text = "%d / %d" % [Game.weight() / 10, Game.max_weight() / 10]
	_refresh_status()
	_refresh_hotbar()
	if _skill_badge:
		_skill_badge.visible = Game.skill_points > 0 or Game.advance_block() == ""
	_refresh_equipment()
	if _shop.panel.visible:
		_fill_shop()
	if _smith.panel.visible:
		_smith_zeny.text = _commas(Game.zeny)
	if _inv.panel.visible:
		_inv_zeny.text = _commas(Game.zeny)


# ================================================================== Character Card (status)
const STAT_TIPS := {"STR": "Melee attack power, carry weight", "AGI": "Attack speed and dodge (FLEE)",
	"VIT": "Max HP, defence, HP recovery", "INT": "Max SP, magic power, SP recovery",
	"DEX": "Accuracy (HIT), ranged power", "LUK": "Critical hits"}


func _build_status() -> void:
	_status = _window("Character Card", Vector2(20, 130), Vector2(580, 0), R_BLUE)
	var sheet := _sb(Color(0.055,0.075,0.10,0.98), LINE, 1, 10, 12)
	sheet.shadow_color = Color(0,0,0,0.4)
	sheet.shadow_size = 10
	_status.panel.add_theme_stylebox_override("panel", sheet)
	var compact := _mobile and get_viewport().get_visible_rect().size.y > get_viewport().get_visible_rect().size.x
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	_status.body.add_child(header)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 4)
	header.add_child(identity)
	_status_head = _label("", 19, TITLE, true)
	_status_head.clip_text = true
	_status_head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(_status_head)
	_status_job = _label("", 13, INK_L)
	_status_job.clip_text = true
	_status_job.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	identity.add_child(_status_job)
	var guild := VBoxContainer.new()
	guild.add_theme_constant_override("separation", 4)
	header.add_child(guild)
	_status_guild = _label("", 12, GOLD, true)
	_status_guild.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	guild.add_child(_status_guild)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_END
	stars.name = "Stars"
	guild.add_child(stars)
	_status.body.add_child(HSeparator.new())
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 12 if compact else 18)
	_status.body.add_child(content)
	var figure := VBoxContainer.new()
	figure.add_theme_constant_override("separation", 6)
	content.add_child(figure)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _sb(Color("17232e"), Color(LINE, 0.7), 1, 10, 4))
	figure.add_child(frame)
	_status_vp = Portrait.make(self, Vector2i(224, 288), "player", null, "body", true)
	_status_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var image := TextureRect.new()
	image.texture = _status_vp.get_texture()
	image.custom_minimum_size = Vector2(100, 206) if compact else Vector2(200, 260)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame.add_child(image)
	_status_rotate = _button("หยุดหมุน", func() -> void:
		_status_spin = not _status_spin
		_status_rotate.text = "หยุดหมุน" if _status_spin else "หมุนต่อ"
		_status_update_preview())
	_status_rotate.custom_minimum_size.y = 60 if _mobile else 30
	figure.add_child(_status_rotate)
	var attributes := VBoxContainer.new()
	attributes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attributes.add_theme_constant_override("separation", 10)
	content.add_child(attributes)
	attributes.add_child(_label("ค่าสเตตัสพื้นฐาน", 13, ACCENT, true))
	var grid := GridContainer.new()
	grid.columns = 2 if compact else 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8 if compact else 12)
	grid.add_theme_constant_override("v_separation", 8 if compact else 6)
	attributes.add_child(grid)
	for stat in Game.STATS:
		var name := _label(stat, 13, ACCENT, true)
		name.tooltip_text = STAT_TIPS[stat]
		name.mouse_filter = Control.MOUSE_FILTER_STOP
		var value := _label("", 16, INK, true)
		value.custom_minimum_size.x = 32 if compact else 48
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if not compact: value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var increase := _button("+", func() -> void: Game.raise_stat(stat))
		_color_button(increase, BTN_GREEN)
		increase.custom_minimum_size = Vector2(60, 60) if _mobile else Vector2(34, 30)
		var cost := _label("", 11, INK_L)
		if compact:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", _sb(Color(0.04,0.06,0.08,0.65), Color(LINE,0.45), 1, 6, 4))
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 5)
			card.add_child(row)
			var numbers := VBoxContainer.new()
			var top := HBoxContainer.new()
			top.add_theme_constant_override("separation", 4)
			top.add_child(name)
			top.add_child(value)
			numbers.add_child(top)
			numbers.add_child(cost)
			row.add_child(numbers)
			row.add_child(increase)
			grid.add_child(card)
		else:
			grid.add_child(name)
			grid.add_child(value)
			grid.add_child(increase)
			cost.custom_minimum_size.x = 64
			grid.add_child(cost)
		_status_rows[stat] = [value, increase, cost]
	_status_points = _label("", 13, GOLD, true)
	attributes.add_child(_status_points)
	_status.body.add_child(HSeparator.new())
	_status.body.add_child(_label("ค่าการต่อสู้", 13, TITLE, true))
	_status_info = GridContainer.new()
	_status_info.columns = 2
	_status_info.add_theme_constant_override("h_separation", 8)
	_status_info.add_theme_constant_override("v_separation", 6)
	_status.body.add_child(_status_info)
	_status.panel.hide()
	_status.panel.visibility_changed.connect(func():
		if _status.panel.visible: _status.panel.move_to_front()
		_status_update_preview())


func _status_update_preview() -> void:
	if not is_instance_valid(_status_vp): return
	if not _status.panel.visible:
		_status_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	else:
		Portrait.set_yaw(_status_vp, _status_yaw)
		_status_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _status_spin else SubViewport.UPDATE_ONCE
		if not _status_fit_queued:
			_status_fit_queued = true
			_status_fit_card.call_deferred()


func _refresh_status() -> void:
	if _status.is_empty(): return
	for stat in Game.STATS:
		var row: Array = _status_rows[stat]
		var number := float(Game.stats[stat])
		(row[0] as Label).text = str(int(number)) if is_equal_approx(number, roundf(number)) else "%.1f" % number
		(row[1] as Button).disabled = Game.stat_points < Game.stat_cost(stat)
		(row[1] as Button).tooltip_text = "เพิ่ม %s · ใช้ %d แต้ม" % [stat, Game.stat_cost(stat)]
		(row[2] as Label).text = "ใช้ %d แต้ม" % Game.stat_cost(stat)
	_status_points.text = "แต้มคงเหลือ  %d" % Game.stat_points
	_status_head.text = tr(Game.player_name)
	_status_job.text = "%s · Lv.%d · Job %d" % [tr(Game.job), Game.base_level, Game.job_level]
	_status_guild.text = "กิลด์ %s · %d GP" % [Guild.letter(), Game.guild_points] if Game.guild_member else "นักผจญภัย"
	for child in _status_info.get_children():
		_status_info.remove_child(child)
		child.queue_free()
	var rows := [["heart", "HP", "%d / %d" % [Game.hp, Game.max_hp()]], ["drop", "SP", "%d / %d" % [Game.sp, Game.max_sp()]],
		["iron_sword", "ATK", str(Game.atk())], ["shield", "DEF", str(Game.def())],
		["bow", "HIT", str(Game.hit())], ["boot", "FLEE", str(Game.flee())],
		["star", "CRIT", "%.0f%%" % Game.crit_rate()], ["dagger", "ASPD", str(Game.aspd())]]
	for row in rows:
		var texture: Texture2D = UiIcons.tex(row[0], 1) if UiIcons.ICONS.has(row[0]) else UiIcons.scaled(Avatar.weapon_image(row[0], 16), 1)
		var metric := HBoxContainer.new()
		metric.add_theme_constant_override("separation", 6)
		metric.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_status_info.add_child(metric)
		metric.add_child(_icon_rect(texture, 16))
		var key := _label(row[1], 12, INK_L)
		key.custom_minimum_size.x = 34
		metric.add_child(key)
		var value := _label(row[2], 14, INK, true)
		value.custom_minimum_size.x = 96
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		metric.add_child(value)
	var stars := _status.panel.find_child("Stars", true, false) as HBoxContainer
	for child in stars.get_children():
		stars.remove_child(child)
		child.queue_free()
	for i in 5:
		var star := _icon_rect(UiIcons.tex("star", 1), 12)
		star.modulate = Color.WHITE if i < 1 + Game.base_level / 10 else Color(0.3,0.25,0.2,0.5)
		stars.add_child(star)
	_status_update_preview()


# ================================================================== inventory
const INV_TABS := [["All", ""], ["Items", "use"], ["Equipment", "weapon,armor"], ["Materials", "etc"]]


func _build_inventory() -> void:
	_inv = _window("Inventory / Equipment", Vector2(400, 120), Vector2(560, 0), R_BROWN)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_inv.body.add_child(row)
	# left: equipment (character + worn gear)
	var eq := VBoxContainer.new()
	eq.add_theme_constant_override("separation", 6)
	row.add_child(eq)
	_build_equipment(eq)
	eq.add_child(_button("แฟชั่น", _open_mage_fashion, 0))
	row.add_child(VSeparator.new())
	# right: bag
	var bag := VBoxContainer.new()
	bag.add_theme_constant_override("separation", 6)
	row.add_child(bag)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	for i in INV_TABS.size():
		var b := _button(INV_TABS[i][0], func() -> void:
			_inv_tab = i
			_refresh_inventory())
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		_inv_tabs.append(b)
	bag.add_child(tabs)
	_inv_grid = GridContainer.new()
	_inv_grid.columns = 5
	_inv_grid.add_theme_constant_override("h_separation", 5)
	_inv_grid.add_theme_constant_override("v_separation", 5)
	bag.add_child(_inv_grid)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 6)
	foot.add_child(_icon_rect(UiIcons.tex("bag", 1), 18))
	_inv_footer = _label("", 12, INK, true)
	_inv_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(_inv_footer)
	foot.add_child(_icon_rect(UiIcons.tex("coin", 1), 18))
	_inv_zeny = _label("", 12, INK, true)
	foot.add_child(_inv_zeny)
	bag.add_child(foot)
	bag.add_child(_label("Tap an item to use / equip it." if _is_touch() else "Double-click (or right-click) to use / equip.", 11, INK_L))
	_inv.panel.hide()
	_equip = _inv
	_inv.panel.visibility_changed.connect(func() -> void:
		_equip_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _inv.panel.visible else SubViewport.UPDATE_DISABLED)
	_refresh_inventory()


func _refresh_inventory() -> void:
	if _inv.is_empty():
		return
	for i in _inv_tabs.size():
		var b: Button = _inv_tabs[i]
		if i == _inv_tab:
			_set_tab(b, true)
		else:
			_set_tab(b, false)
	for c in _inv_grid.get_children():
		_inv_grid.remove_child(c)
		c.queue_free()
	var want: String = INV_TABS[_inv_tab][1]
	var ids := []
	for id in Game.inventory:
		if want == "" or Items.info(id).type in want.split(","):
			ids.append(id)
	var n := maxi(INV_SLOTS, int(ceil(ids.size() / 5.0)) * 5)
	for i in n:
		var b := _slot(50)
		if i < ids.size():
			var id: String = ids[i]
			b.icon = Items.icon(id)
			b.tooltip_text = _item_tip(id)
			_count_label(b, str(Game.count(id)))
			if Items.is_gear(id):
				_refine_glow(b, Game.refine_lv(id))
				_compare_arrow(b, _compare(id))
			b.gui_input.connect(func(e: InputEvent) -> void:
				if not (e is InputEventMouseButton and e.pressed):
					return
				if not _is_touch() and (e.double_click or e.button_index == MOUSE_BUTTON_RIGHT):
					Game.use_item(id))
			b.pressed.connect(func():
				if _is_touch(): _item_menu(id, b))
		else:
			b.disabled = true
		_inv_grid.add_child(b)
	_inv_footer.text = "%d / %d   %s %d / %d" % [Game.inventory.size(), INV_SLOTS, tr("Weight"), Game.weight() / 10, Game.max_weight() / 10]
	_inv_zeny.text = _commas(Game.zeny)
	_refresh_hotbar()
	_refresh_equipment()


# ================================================================== equipment
func _build_equipment(parent: VBoxContainer) -> void:
	parent.add_child(_label("Equipment", 13, INK, true))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(h)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	left.add_theme_constant_override("separation", 6)
	right.add_theme_constant_override("separation", 6)
	for d in [["head", left], ["armor", left], ["gloves", left], ["weapon", left],
			["garment", right], ["accessory", right], ["boots", right], ["shield", right]]:
		var b := _slot(46)
		var slot: String = d[0]
		b.gui_input.connect(func(e: InputEvent) -> void:
			if not (e is InputEventMouseButton and e.pressed):
				return
			if not _is_touch() and (e.double_click or e.button_index == MOUSE_BUTTON_RIGHT):
				Game.unequip(slot))
		b.pressed.connect(func():
			if _is_touch() and Game.equip.get(slot, "") != "":
				_item_menu(Game.equip[slot], b, slot))
		d[1].add_child(b)
		_equip_slots[slot] = b
	h.add_child(left)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(Color(0.14, 0.17, 0.24), Color(LINE, 0.6), 1, 8, 2))
	_equip_vp = Portrait.make(self, Vector2i(150, 200), "player", null, "body", true)
	_equip_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var pic := TextureRect.new()
	pic.texture = _equip_vp.get_texture()
	pic.custom_minimum_size = Vector2(150, 200)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.add_child(pic)
	h.add_child(card)
	h.add_child(right)
	_equip_stats = _label("", 12, INK, true)
	_equip_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(_equip_stats)
	parent.add_child(_label("Tap an item to equip or unequip it." if _is_touch() else "Right-click a slot to unequip.", 11, INK_L))


# ---- touch screens: tap an item -> small menu (equip / use / unequip)
var _menu_layer: Control


func _is_touch() -> bool:
	return DisplayServer.is_touchscreen_available()


func _close_item_menu() -> void:
	if _menu_layer and is_instance_valid(_menu_layer):
		_menu_layer.queue_free()
	_menu_layer = null


## equipped_slot != "" means the item is worn in that slot (menu offers Unequip).
func _item_menu(id: String, anchor: Control, equipped_slot := "") -> void:
	_close_item_menu()
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_item_menu())
	add_child(layer)
	_menu_layer = layer
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(Color(0.1, 0.09, 0.08, 0.97), GOLD_D, 2, 6, 10))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var tip := _label(_item_tip(id), 12, INK)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(260, 0)
	v.add_child(tip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(row)
	var it := Items.info(id)
	var act := ""
	var cb := Callable()
	if equipped_slot != "":
		act = "Unequip"
		cb = func() -> void: Game.unequip(equipped_slot)
	elif it.get("type", "") in ["weapon", "armor"] and Items.slot_of(id) != "":
		act = "Equip"
		cb = func() -> void: Game.use_item(id)
	elif it.get("type", "") == "use":
		act = "Use"
		cb = func() -> void: Game.use_item(id)
	if act != "":
		var go := _color_button(_button(tr(act), func() -> void:
			_close_item_menu()
			cb.call(), 110), GOLD_D)
		go.custom_minimum_size.y = 40
		row.add_child(go)
	var close := _button(tr("Close"), _close_item_menu, 90)
	close.custom_minimum_size.y = 40
	row.add_child(close)
	# place next to the tapped slot, kept on screen
	await get_tree().process_frame
	if not is_instance_valid(p):
		return
	var vp := get_viewport().get_visible_rect().size
	var r := anchor.get_global_rect()
	var sz := p.get_combined_minimum_size()
	var pos := Vector2(r.position.x + r.size.x + 6, r.position.y)
	if pos.x + sz.x > vp.x - 6:
		pos.x = r.position.x - sz.x - 6
	pos.x = clampf(pos.x, 6, maxf(6, vp.x - sz.x - 6))
	pos.y = clampf(pos.y, 6, maxf(6, vp.y - sz.y - 6))
	p.position = pos


func _refresh_equipment() -> void:
	if _equip.is_empty():
		return
	for slot in Items.SLOTS:
		var b: Button = _equip_slots[slot]
		var id: String = Game.equip[slot]
		for c in b.get_children():
			if c.name.begins_with("Tag"):
				b.remove_child(c)
				c.queue_free()
		b.icon = Items.icon(id) if id != "" else null
		b.tooltip_text = _item_tip(id) if id != "" else tr(Items.SLOT_NAMES[slot]) + ": -"
		b.add_theme_stylebox_override("normal", _slot_style(false))
		if id == "":
			var t := _label(tr(Items.SLOT_NAMES[slot]), 9, Color(INK_L, 0.55), true)
			t.name = "TagSlot"
			t.set_anchors_preset(Control.PRESET_FULL_RECT)
			t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			b.add_child(t)
		else:
			var before := b.get_child_count()
			_refine_glow(b, Game.refine_lv(id))
			if b.get_child_count() > before:
				b.get_child(b.get_child_count() - 1).name = "TagRefine"
	_equip_stats.text = "ATK %d    DEF %d    ASPD %d" % [Game.atk(), Game.def(), Game.aspd()]


# ================================================================== quests window
func _build_quests() -> void:
	_quests = _window("Quests", Vector2(470, 130), Vector2(300, 0), R_GREEN)
	_quest_list = VBoxContainer.new()
	_quest_list.add_theme_constant_override("separation", 6)
	_quests.body.add_child(_quest_list)
	_quests.panel.hide()


func _quest_card(icon: Texture2D, title: String, desc: String, progress: String, done := false, locked := false) -> PanelContainer:
	var p := PanelContainer.new()
	var bg := Color(0, 0, 0, 0.28)
	if done:
		bg = Color(0.25, 0.45, 0.2)
	if locked:
		bg = Color(0, 0, 0, 0.45)
	p.add_theme_stylebox_override("panel", _sb(bg, SLOT_B, 2, 6, 6))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	var ic := _icon_rect(icon, 30)
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_label(title, 13, INK_L if locked else INK, true))
	var d := _label(desc, 11, INK_L)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 150
	v.add_child(d)
	h.add_child(v)
	if progress != "":
		var pr := _label(progress, 12, GOOD if done else INK, true)
		pr.size_flags_vertical = Control.SIZE_SHRINK_END
		h.add_child(pr)
	return p


func _quest_entries() -> Array:
	## [icon, title, desc, progress, done, locked, action]
	var out := []
	for task in SideQuests.TASKS:
		var q: Dictionary = Game.quests.get(task.id, {})
		if q.is_empty() or q.state == "finished":continue
		var done: bool = q.state == "done"
		out.append([UiIcons.tex("scroll", 2), task.title, "รายงานต่อ " + task.giver if done else "กำจัด " + task.target, "%d / %d" % [mini(int(q.count), int(task.need)), task.need], done, false, {"npc":task.giver} if done else {"zone":task.target, "giver":task.giver}])
	# The active guild bounty is listed first so it always shows in the journal
	# and the tracker, even after the main story has been completed.
	var b := _bounty_entry()
	if not b.is_empty():
		out.append(b)
	var s := Story.current()
	if s.is_empty():
		out.append([UiIcons.tex("star", 2), tr("Hero of Aldenvale"), tr("The main story is complete. Thank you for playing!"), "", true, false, {}])
		return out
	var st := Story.state()
	var g: Dictionary = s.goal
	var title := "%s %d · %s" % [tr("Ch."), int(s.chapter), tr(s.title)]
	var icon: Texture2D = _story_icon(s)
	if st == "offer":
		out.append([UiIcons.tex("scroll", 2), title, tr("Talk to %s to start.") % tr(s.giver), "!", false, false, {"npc": s.giver}])
	elif st == "done" or g.type == "talk":
		out.append([icon, title, tr("Report to %s.") % tr(s.turnin), "?", true, false, {"npc": s.turnin}])
	else:
		var pr := Story.progress()
		var act := {}
		match String(g.type):
			"kill":
				act = {"zone": g.target, "giver": s.turnin}
			"collect":
				var zn := _zone_for_item(g.item)
				act = {"zone": zn, "giver": s.turnin} if zn != "" else {"npc": s.turnin}
			"refine":
				act = {"npc": "Blacksmith Doran"}
			"level":
				var zl := _zone_for_level(Game.base_level)
				act = {"zone": zl} if zl != "" else {}
			"job":
				# ready to change job: open the skill window; otherwise level up first
				var zj := _zone_for_level(Game.base_level)
				act = {"ui": "skills"} if Game.advance_block() == "" else ({"zone": zj} if zj != "" else {"ui": "skills"})
			"skills":
				act = {"ui": "skills"}
			"gear":
				act = {"ui": "inventory"}
			"stats":
				act = {"ui": "status"}
			"guild", "rank":
				act = {"npc": "Guild Clerk Mira"}
			"board":
				act = {"npc": "Special Quest Board"} if Game.board_active.is_empty() else act
		out.append([icon, title, Story.goal_text(s) + "\n" + tr("Tip:") + " " + tr(s.tip), "%d/%d" % [pr[0], pr[1]], false, false, act])
	var nx := Story.step(Game.story_step + 1)
	if not nx.is_empty():
		out.append([UiIcons.tex("lock", 2), "???", tr("Complete the previous quest."), "", false, true])
	return out


## Journal/tracker row for the active guild bounty, or [] when there is none.
func _bounty_entry() -> Array:
	if Game.board_active.is_empty():
		return []
	var a: Dictionary = Game.board_active
	var pr := Guild.progress()
	var bt := "%s [%s] · %s" % [tr("Bounty"), Guild.RANKS[int(a.rank)], tr(a.zone)]
	if Guild.is_done():
		return [UiIcons.tex("scroll", 2), bt, tr("Claim your reward at the Special Quest Board."), "?", true, false, {"npc": "Special Quest Board"}]
	var act := {"zone": a.zone, "giver": "Special Quest Board"}
	return [Items.icon(a.item) if a.type == "collect" else UiIcons.tex("slime", 2), bt, Guild.offer_text(a), "%d/%d" % [pr[0], pr[1]], false, false, act]


## Accepting a bounty starts quest-auto right away: walk to the zone and hunt.
func _start_bounty_auto() -> void:
	var a: Dictionary = Game.board_active
	if a.is_empty() or Guild.is_done():
		return
	_guild.panel.hide()
	_quest_go({"zone": a.zone, "giver": "Special Quest Board"})


func _story_icon(s: Dictionary) -> Texture2D:
	var g: Dictionary = s.goal
	match String(g.type):
		"kill":
			return UiIcons.tex("slime", 2) if String(g.target).contains("Slime") else Items.icon("iron_sword")
		"collect":
			return Items.icon(g.item)
		"skills", "job":
			return UiIcons.tex("star", 2)
		"gear", "refine":
			return Items.icon("weapon_stone")
	return UiIcons.tex("hero", 2)


func _zone_for_item(item: String, allow_boss := false) -> String:
	var best := ""
	var best_lv := 999
	for z in load("res://scripts/monsters/spawner.gd").ZONES:
		for d in z.drops:
			if d[0] == item and int(z.lv) < best_lv and (allow_boss or not z.get("boss", false)):
				best = z.name
				best_lv = int(z.lv)
	if best == "" and not allow_boss:
		return _zone_for_item(item, true)
	return best


func _zone_for_level(lv: int) -> String:
	var best := ""
	for z in load("res://scripts/monsters/spawner.gd").ZONES:
		if not z.get("boss", false) and int(z.lv) <= lv:
			best = z.name
	return best


func _refresh_quests() -> void:
	var entries := _quest_entries()
	for box in [_quest_list, _tracker_box]:
		if box == null:
			continue
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	for e in entries:
		_quest_list.add_child(_quest_card(e[0], e[1], e[2], e[3], e[4], e[5]))
		if not e[5]:
			var row := Button.new()
			row.focus_mode = Control.FOCUS_NONE
			row.flat = false
			row.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
			row.add_theme_stylebox_override("hover", _sb(Color(GOLD, 0.12), Color(GOLD, 0.6), 1, 5, 2))
			row.add_theme_stylebox_override("pressed", _sb(Color(GOLD, 0.22), GOLD, 1, 5, 2))
			row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			row.tooltip_text = tr("Click to go there automatically")
			row.custom_minimum_size = Vector2(200, 24)
			var rh := HBoxContainer.new()
			rh.set_anchors_preset(Control.PRESET_FULL_RECT)
			rh.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rh.add_theme_constant_override("separation", 6)
			rh.add_child(_icon_rect(e[0], 20))
			var l := _label("%s  %s" % [e[1], e[3]] if e[3] != "" else e[1], 12, GOOD if e[4] else INK, true)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rh.add_child(l)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rh.add_child(_label("→", 13, GOLD, true))
			row.add_child(rh)
			var act: Dictionary = e[6] if e.size() > 6 else {}
			row.pressed.connect(func() -> void: _quest_go(act))
			_quest_list.get_child(_quest_list.get_child_count() - 1).gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_quest_go(act))
			_tracker_box.add_child(row)


# ================================================================== dialog
func _build_dialog() -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _pixel_box(R_BROWN, 2, 0.09, 12))
	panel.custom_minimum_size = Vector2(560, 150)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(panel)
	_windows.append(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	panel.add_child(h)
	var face_frame := PanelContainer.new()
	face_frame.add_theme_stylebox_override("panel", _sb(Color(0.16, 0.2, 0.28), GOLD_D, 2, 8, 2))
	_dialog_face = TextureRect.new()
	_dialog_face.custom_minimum_size = Vector2(110, 110)
	_dialog_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face_frame.add_child(_dialog_face)
	face_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(face_frame)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	h.add_child(v)
	var top := HBoxContainer.new()
	var rib := _ribbon("NPC", R_BLUE)
	_dialog_name = rib.get_node("Text")
	rib.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
			panel.position += e.relative)
	top.add_child(rib)
	v.add_child(top)
	_dialog_text = RichTextLabel.new()
	_dialog_text.bbcode_enabled = true
	_dialog_text.fit_content = true
	_dialog_text.scroll_active = false
	_dialog_text.custom_minimum_size = Vector2(400, 54)
	_dialog_text.add_theme_color_override("default_color", INK)
	_dialog_text.add_theme_font_size_override("normal_font_size", 14)
	_dialog_text.add_theme_font_size_override("bold_font_size", 14)
	_dialog_text.add_theme_font_override("bold_font", _font_b)
	v.add_child(_dialog_text)
	_dialog_buttons = HBoxContainer.new()
	_dialog_buttons.alignment = BoxContainer.ALIGNMENT_END
	_dialog_buttons.add_theme_constant_override("separation", 6)
	v.add_child(_dialog_buttons)
	_dialog = {"panel": panel}
	panel.hide()


func _npc_portrait(npc_name: String) -> Texture2D:
	if _dialog_vps.has(npc_name):
		return (_dialog_vps[npc_name] as SubViewport).get_texture()
	var skin := 0
	var npc: Node = null
	for n in get_tree().get_nodes_in_group("npc"):
		if n.npc_name == npc_name:
			skin = n.skin
			npc = n
	if npc and npc.role in ["board", "ranking"]:
		return UiIcons.tex("scroll", 4)
	if npc and npc.role == "warp":
		return UiIcons.tex("map", 4)
	var vp: SubViewport
	if npc and not npc.look.is_empty():
		vp = Portrait.make(self, Vector2i(128, 128), "avatar", Avatar.dress(npc.look, npc.gear, {}), "head", false)
		preload("res://scripts/npc/npc_costume.gd").decorate(vp.get_node("Holder/Model"), npc.role)
	else:
		vp = Portrait.make(self, Vector2i(128, 128), "villager", skin, "head", false)
	_dialog_vps[npc_name] = vp
	return vp.get_texture()


func dialog(npc_name: String, text: String, choices: Array, cb: Callable) -> void:
	_dialog_choices = choices.duplicate()
	_qauto_press = 1.6 if _quest_auto and not choices.is_empty() and String(choices[0]) in QAUTO_PRESS else -1.0
	_dialog_name.text = tr(npc_name)
	_dialog_face.texture = _npc_portrait(npc_name)
	_dialog_text.text = tr(text)
	for c in _dialog_buttons.get_children():
		_dialog_buttons.remove_child(c)
		c.queue_free()
	for i in choices.size():
		var b := _button(choices[i], func() -> void:
			_dialog.panel.hide()
			if cb.is_valid():
				cb.call(i), 80)
		if i == 0 and choices.size() > 1:
			_color_button(b, BTN_GREEN)
		_dialog_buttons.add_child(b)
	_dialog.panel.show()
	_dialog.panel.reset_size()
	_dialog.panel.move_to_front()


# ================================================================== shop
func _build_shop() -> void:
	_shop = _window("Shop", Vector2(300, 120), Vector2(330, 0), R_YELLOW)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	for t in [["Buy", true], ["Sell", false]]:
		var b := _button(t[0], func() -> void:
			_shop_buy = t[1]
			_fill_shop(), 70)
		top.add_child(b)
		_shop_tabs.append(b)
	_shop.body.add_child(top)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(310, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_shop.body.add_child(scroll)
	_shop_grid = GridContainer.new()
	_shop_grid.columns = 3
	_shop_grid.add_theme_constant_override("h_separation", 6)
	_shop_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_shop_grid)
	var foot := _pill()
	var fh := HBoxContainer.new()
	fh.alignment = BoxContainer.ALIGNMENT_CENTER
	fh.add_child(_icon_rect(UiIcons.tex("coin", 2), 22))
	_shop_zeny = _outlined(_label("", 15, CREAM, true), Color(0, 0, 0, 0.5), 3)
	fh.add_child(_shop_zeny)
	foot.add_child(fh)
	_shop.body.add_child(foot)
	_shop.body.add_child(_label("Set quantity below each item, then press Buy or Sell.", 11, INK_L))
	_shop.panel.hide()


func open_shop(npc_name: String, stock: Array, buy: bool) -> void:
	_shop_quantities.clear()
	_shop_stock = stock
	_shop_buy = buy
	_shop.title.text = tr("Shop - %s") % tr(npc_name)
	_fill_shop()
	_shop.panel.show()
	_shop.panel.move_to_front()


func _fill_shop() -> void:
	for i in _shop_tabs.size():
		var b: Button = _shop_tabs[i]
		if (i == 0) == _shop_buy:
			_set_tab(b, true)
		else:
			_set_tab(b, false)
	for c in _shop_grid.get_children():
		_shop_grid.remove_child(c)
		c.queue_free()
	_shop_zeny.text = _commas(Game.zeny)
	var ids: Array = _shop_stock if _shop_buy else Game.inventory.keys()
	for id in ids:
		var price: int = Game.buy_price(id) if _shop_buy else Game.sell_price(id)
		var key := ("buy:" if _shop_buy else "sell:") + String(id)
		var card := PanelContainer.new()
		card.custom_minimum_size.x = 96
		card.add_theme_stylebox_override("panel", _sb(SLOT, SLOT_B, 1, 6, 4))
		card.tooltip_text = _item_tip(id)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		card.add_child(v)
		var nm := _label(Items.item_name(id) + ("" if _shop_buy else " x%d" % Game.count(id)), 10, INK)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.custom_minimum_size.x = 90
		v.add_child(nm)
		var ic := _icon_rect(Items.icon(id), 36)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var quantity := SpinBox.new()
		quantity.min_value = 1
		quantity.max_value = 9999
		quantity.step = 1
		quantity.value = int(_shop_quantities.get(key, 1))
		quantity.update_on_text_changed = true
		quantity.tooltip_text = tr("Quantity")
		quantity.custom_minimum_size.x = 90
		v.add_child(quantity)
		var ph := HBoxContainer.new()
		ph.alignment = BoxContainer.ALIGNMENT_CENTER
		ph.add_child(_icon_rect(UiIcons.tex("coin", 1), 14))
		var pl := _label(_commas(price * int(quantity.value)), 12, Color(1.0, 0.85, 0.35), true)
		ph.add_child(pl)
		v.add_child(ph)
		quantity.value_changed.connect(func(value: float) -> void:
			_shop_quantities[key] = int(value)
			pl.text = _commas(price * int(value)))
		var trade := _button("Buy" if _shop_buy else "Sell", func() -> void:
			quantity.apply()
			_trade_shop_item(id, int(quantity.value)), 80)
		v.add_child(trade)
		if not _shop_buy:
			var sell_all := _button("ขายทั้งหมด" if TranslationServer.get_locale().begins_with("th") else "Sell All", func() -> void:
				_sell_all_shop_item(id), 80)
			sell_all.tooltip_text = "ขายเฉพาะไอเทมชนิดนี้ทั้งหมดในกระเป๋า" if TranslationServer.get_locale().begins_with("th") else "Sell every unequipped copy of this item in your bag."
			sell_all.set_meta("sell_all_item", id)
			v.add_child(sell_all)
		_shop_grid.add_child(card)


func _sell_all_shop_item(id: String) -> void:
	# Read the current stack at activation; a stale sell button must never buy items.
	if _shop_buy: return
	var amount := Game.count(id)
	if amount > 0: _trade_shop_item(id, amount)


func _trade_shop_item(id: String, quantity: int) -> void:
	if quantity < 1:
		return
	var price: int = Game.buy_price(id) if _shop_buy else Game.sell_price(id)
	var total := price * quantity
	if _shop_buy:
		if not _shop_stock.has(id):
			return
		if Game.zeny < total:
			Game.log_msg("Not enough Zeny.", BAD)
			return
		Game.add_zeny(-total)
		Game.add_item(id, quantity)
	else:
		if not Game.remove_item(id, quantity):
			Game.log_msg("Not enough items.", BAD)
			return
		Game.add_zeny(total)
		Game.log_msg(tr("Sold %s x%d for %d Zeny.") % [Items.item_name(id), quantity, total], R_YELLOW)
	_fill_shop()


# ================================================================== quest helpers (tracker click -> auto quest)
func _zone_by_name(n: String) -> Dictionary:
	var zones: Array = load("res://scripts/monsters/spawner.gd").ZONES
	for z in zones:
		if z.name == n:
			return z
	return {}


func _npc_by_name(n: String) -> Node3D:
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc.npc_name == n:
			return npc
	return null


func _quest_go(action: Dictionary) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p == null or action.is_empty():
		return
	_qauto_wait = 2.0
	if action.has("ui"):
		var w: Control = {"skills": _skills.panel, "inventory": _inv.panel, "status": _status.panel}.get(String(action.ui), null)
		if w and not w.visible:
			toggle(w)
		if _quest_auto:
			# this step needs a choice from the player: pause until they turn it back on
			_qauto_btn.button_pressed = false
			add_message("ออโต้เควสหยุดชั่วคราว: ทำขั้นตอนในหน้าต่างให้เสร็จ แล้วกด ออโต้เควส อีกครั้ง" if TranslationServer.get_locale().begins_with("th") else "Auto Quest paused: finish this step in the window, then turn Auto Quest on again.", Color(1.0, 0.85, 0.4))
		return
	if action.has("npc"):
		var n := _npc_by_name(action.npc)
		if n:
			Game.auto_quest_target = ""
			p.talk_to(n)
			add_message(tr("Walking to %s...") % tr(action.npc), INK_L)
	elif action.has("zone"):
		var z := _zone_by_name(action.zone)
		if z.is_empty():
			return
		var c := Vector3(z.pos.x, 0, z.pos.y)
		p.go_to(c - c.normalized() * (float(z.r) * 0.5) if String(z.get("area", "town")) == "town" else c)
		Game.auto_quest_target = action.zone
		Game.auto_quest_giver = action.get("giver", "")
		if not Game.auto_on:
			p.toggle_auto()
		add_message(tr("Quest auto: hunting %s.") % tr(action.zone), INK_L)


## Quest markers: "!" / "?" over quest givers and a star on the current target zone.
func _quest_marks() -> Array:
	var out := []
	for n in get_tree().get_nodes_in_group("npc"):
		if n._marker.text != "":
			out.append({"pos": n.global_position, "text": n._marker.text})
	for qid in Game.quests:
		var q: Dictionary = Game.quests[qid]
		if q.state == "active":
			var z := _zone_by_name(q.target)
			if not z.is_empty():
				out.append({"pos": Vector3(z.pos.x, 0, z.pos.y), "text": "*"})
	if not Game.board_active.is_empty() and not Guild.is_done():
		var bz := _zone_by_name(Game.board_active.zone)
		if not bz.is_empty():
			out.append({"pos": Vector3(bz.pos.x, 0, bz.pos.y), "text": "*"})
	return out


func _mark_label(text: String) -> Label:
	var l := _outlined(_label(text if text != "*" else "★", 16 if text != "*" else 15, Color(1.0, 0.85, 0.2), true), WOOD_D, 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if text == "*":
		l.text = ""
		var ic := _icon_rect(UiIcons.tex("star", 1), 16)
		l.add_child(ic)
		l.custom_minimum_size = Vector2(16, 16)
	return l


func _update_quest_marks(container: Control, to_px: Callable, clip: float) -> void:
	for c in container.get_children():
		if c.has_meta("qmark"):
			container.remove_child(c)
			c.queue_free()
	for m in _quest_marks():
		var pos: Vector2 = to_px.call(m.pos)
		if clip > 0.0 and (pos - container.size * 0.5).length() > clip:
			continue
		var l := _mark_label(m.text)
		l.set_meta("qmark", true)
		l.size = Vector2(16, 18)
		l.position = pos - Vector2(8, 14)
		container.add_child(l)


# ================================================================== auto settings
func _build_auto_settings() -> void:
	_autoset = _window("Auto Settings", Vector2(400, 200), Vector2(320, 0), R_TEAL)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 6)
	_autoset.body.add_child(g)
	_auto_choice(g, "Target", "target", [["Nearest", "nearest"], ["Weakest", "weakest"], ["Strongest", "strongest"], ["Quest monster only", "quest"]])
	_auto_choice(g, "Monster", "monster", [[tr("All monsters in range"), ""]])
	var monster_picker: OptionButton = _auto_ctl.monster
	monster_picker.add_theme_constant_override("icon_max_width", 28)
	monster_picker.get_popup().add_theme_constant_override("icon_max_width", 28)
	monster_picker.get_popup().max_size.y = 300
	var profile := HBoxContainer.new()
	profile.add_theme_constant_override("separation", 8)
	_auto_face = TextureRect.new()
	_auto_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_auto_face.custom_minimum_size = Vector2(64, 64)
	_auto_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	profile.add_child(_auto_face)
	_auto_profile = _label("", 11, INK_L)
	_auto_profile.custom_minimum_size.x = 240
	_auto_profile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_auto_profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile.add_child(_auto_profile)
	_autoset.body.add_child(profile)
	_auto_check(g, "Use Warp Crystals on long trips (Zeny fee)", "travel_warp")
	_auto_choice(g, "Search range", "range", [["10 m", 10], ["20 m", 20], ["35 m", 35]])
	_auto_check(g, "Use attack skills", "skills")
	_auto_choice(g, "Area skill when", "aoe", [["2+ monsters", 2], ["3+ monsters", 3], ["4+ monsters", 4], ["Never", 99]])
	_auto_check(g, "Use buff / heal skills", "buffs")
	_auto_choice(g, "HP potion below", "hp_potion", [["Off", 0], ["30%", 30], ["40%", 40], ["50%", 50], ["60%", 60], ["70%", 70]])
	_auto_choice(g, "SP potion below", "sp_potion", [["Off", 0], ["10%", 10], ["15%", 15], ["25%", 25], ["40%", 40]])
	_auto_check(g, "Pick up loot", "loot")
	_auto_check(g, "Avoid bosses", "skip_boss")
	_autoset.body.add_child(_label("Settings are saved with your character.", 11, INK_L))
	_autoset.panel.hide()
	_autoset.panel.visibility_changed.connect(_sync_auto_settings)


func _auto_choice(g: GridContainer, text: String, key: String, items: Array) -> void:
	g.add_child(_label(text, 12))
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	o.custom_minimum_size.x = 150
	o.add_theme_font_size_override("font_size", 12)
	for i in items.size():
		o.add_item(items[i][0], i)
		o.set_item_metadata(i, items[i][1])
	o.item_selected.connect(func(i: int) -> void:
		Game.auto_cfg[key] = o.get_item_metadata(i)
		if key == "monster":
			Game.auto_quest_target = ""
			var p := get_tree().get_first_node_in_group("player")
			if p and Game.auto_on:
				p._stop_all()
		if key in ["monster", "range"]:
			_refresh_auto_monsters()
		Game.save_game())
	g.add_child(o)
	_auto_ctl[key] = o


func _auto_check(g: GridContainer, text: String, key: String) -> void:
	g.add_child(_label(text, 12))
	var c := CheckBox.new()
	c.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		c.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	c.toggled.connect(func(on: bool) -> void:
		Game.auto_cfg[key] = on
		Game.save_game())
	g.add_child(c)
	_auto_ctl[key] = c


func _sync_auto_settings() -> void:
	if _autoset.panel.visible:
		_refresh_auto_monsters()
	for key in _auto_ctl:
		var c = _auto_ctl[key]
		var v = Game.auto_cfg.get(key)
		if c is CheckBox:
			c.set_pressed_no_signal(bool(v))
		else:
			for i in c.item_count:
				if c.get_item_metadata(i) == v:
					c.select(i)


func _refresh_auto_monsters() -> void:
	var picker: OptionButton = _auto_ctl.monster
	# Do not replace menu indices while the player is choosing an entry.
	if picker.get_popup().visible:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var entries: Array = preload("res://scripts/ui/auto_targets.gd").nearby(get_tree(), player.global_position, float(Game.auto_cfg.get("range", 20)))
	var selected := String(Game.auto_cfg.get("monster", ""))
	picker.clear()
	picker.add_item(tr("All monsters in range"))
	picker.set_item_metadata(0, "")
	_auto_face.texture = null
	_auto_face.hide()
	_auto_profile.text = tr("Choose a monster to view its profile.") if not entries.is_empty() else tr("No living monsters in search range.")
	var found := selected == ""
	for entry in entries:
		var levels := str(entry.min_level) if entry.min_level == entry.max_level else "%d–%d" % [entry.min_level, entry.max_level]
		var index := picker.item_count
		picker.add_item("%s  Lv.%s" % [tr(entry.name), levels])
		picker.set_item_metadata(index, entry.name)
		var texture: Texture2D
		for zone in preload("res://scripts/monsters/spawner.gd").ZONES:
			if zone.name == entry.name:
				texture = _monster_map_portrait(zone)
				picker.set_item_icon(index, texture)
				break
		if entry.name == selected:
			found = true
			picker.select(index)
			_auto_face.texture = texture
			_auto_face.visible = texture != null
			var mon: Monster = entry.monster
			_auto_profile.text = "%s  Lv.%s\nHP %d / %d\n" % [tr(entry.name), levels, mon.hp, mon.max_hp]
			_auto_profile.text += tr("In range: %d · Nearest: %.1f m") % [entry.count, entry.distance]
			if mon.has_meta("boss") and Game.auto_cfg.get("skip_boss", true):
				_auto_profile.text += "\n" + tr("Boss excluded by Avoid bosses setting.")
	if not found:
		# Keep the saved hunt filter; leaving range must not switch to all species.
		picker.select(-1)
		picker.text = tr("Choose a monster in range")
		_auto_profile.text = tr("Saved target: %s — currently out of range.") % tr(selected)
	_auto_refresh = 0.5


# ================================================================== blacksmith (refine + craft)
func _build_smith() -> void:
	_smith = _window("Blacksmith", Vector2(360, 100), Vector2(720, 0), R_RED)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	for t in [["ตีบวก",0],["อาวุธ",1],["หมวก",8],["เกราะ",9],["เครื่องประดับ",10],["ปีก",2],["แฟชั่น",7],["วัสดุ",6]]:
		var b := _button(t[0], func() -> void:
			_smith_tab = t[1]
			_fill_smith(), 0)
		b.set_meta("tab", t[1])
		tabs.add_child(b)
		_smith_tabs.append(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(sp)
	var pz := _pill()
	var ph := HBoxContainer.new()
	ph.add_child(_icon_rect(UiIcons.tex("coin", 1), 16))
	_smith_zeny = _outlined(_label("", 13, CREAM, true), Color(0, 0, 0, 0.5), 3)
	ph.add_child(_smith_zeny)
	pz.add_child(ph)
	tabs.add_child(pz)
	_smith.body.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_smith.body.add_child(scroll)
	_smith_list = VBoxContainer.new()
	_smith_list.add_theme_constant_override("separation", 6)
	_smith_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_smith_list)
	_smith_msg = _label("", 12, INK, true)
	_smith.body.add_child(_smith_msg)
	_smith.panel.hide()


func open_smith(npc_name: String, tab := 0) -> void:
	_fashion_vendor_name = npc_name
	_craft_weapon_kind="bow" if tab==4 else ("staff" if tab==5 else "all")
	_smith_tab = 1 if tab in [4,5] else (9 if tab==3 else tab)
	_smith_msg.text = ""
	_fill_smith()
	_smith.panel.show()
	_smith.panel.move_to_front()


## Coloured glow frame + "+N" badge on an item slot for refined gear.
func _refine_glow(b: Button, r: int) -> void:
	if r <= 0:
		return
	var c := Avatar.glow_color(r)
	var st := _sb(Color(c, 0.1 + r * 0.025), Color(c, 0.45 + r * 0.05), 1 if r < 7 else 2, 6, 7)
	st.shadow_color = Color(c, 0.25 + r * 0.05)
	st.shadow_size = 2 + r
	b.add_theme_stylebox_override("normal", st)
	var k := _label("+%d" % r, 10, c.lightened(0.4), true)
	k.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	k.add_theme_constant_override("outline_size", 3)
	k.position = Vector2(3, 0)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	k.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	b.add_child(k)


func _mat_row(id: String, need: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 3)
	h.add_child(_icon_rect(Items.icon(id), 18))
	var have := Game.count(id)
	h.add_child(_label("%s %d/%d" % [Items.item_name(id), have, need], 11, GOOD if have >= need else BAD, true))
	return h


func _fill_smith() -> void:
	if _smith.is_empty():
		return
	for i in _smith_tabs.size():
		var b: Button = _smith_tabs[i]
		if int(b.get_meta("tab", i)) == _smith_tab:
			_set_tab(b, true)
		else:
			_set_tab(b, false)
	_smith_zeny.text = _commas(Game.zeny)
	for c in _smith_list.get_children():
		_smith_list.remove_child(c)
		c.queue_free()
	if _smith_tab == 0:
		_smith_list.add_child(_label("Refine gear with stones and Zeny. Failure keeps the current level. Higher levels produce more light aura.", 11, INK_L))
		_smith_list.get_child(0).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_smith_list.get_child(0).custom_minimum_size.x = 430
		var guarantee := CheckBox.new()
		guarantee.text = tr("Use Guaranteed Refine Stone (100%)") + " x%d" % Game.count("guarantee_stone")
		guarantee.button_pressed = _guaranteed_refine
		guarantee.toggled.connect(func(on: bool) -> void:
			_guaranteed_refine = on
			_fill_smith())
		_smith_list.add_child(guarantee)
		for slot in Items.SLOTS:
			var id: String = Game.equip[slot]
			if id == "":
				continue
			var r := Game.refine_lv(id)
			var card := PanelContainer.new()
			var gc := Avatar.glow_color(r)
			card.add_theme_stylebox_override("panel", _sb(Color(gc, 0.08) if r > 0 else Color(0, 0, 0, 0.28), Color(gc, 0.6) if r > 0 else SLOT_B, 1, 6, 8))
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 10)
			card.add_child(h)
			var ic := _slot(52)
			ic.icon = Items.icon(id)
			ic.tooltip_text = _item_tip(id)
			_refine_glow(ic, r)
			h.add_child(ic)
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_theme_constant_override("separation", 1)
			var stat := "ATK" if slot == "weapon" else "DEF"
			var nl := _label("%s  ·  %s" % [Game.item_label(id), tr(Items.SLOT_NAMES[slot])], 14, gc.lightened(0.3) if r > 0 else INK, true)
			v.add_child(nl)
			v.add_child(_label(tr("Refine bonus: %s") % ("%s +%d" % [stat, Game.refine_bonus(id)]), 11, INK_L))
			if r < Game.REFINE_MAX:
				var ch := 100 if _guaranteed_refine else Game.refine_chance(id)
				v.add_child(_label(tr("Next +%d: %s   Success %d%%") % [r + 1, "%s +%d" % [stat, Game.refine_bonus(id, r + 1)], ch], 11,
					GOOD if ch >= 90 else (R_YELLOW if ch >= 45 else BAD), true))
				var mh := HBoxContainer.new()
				mh.add_theme_constant_override("separation", 10)
				mh.add_child(_mat_row(Game.refine_stone(id), Game.refine_stones(id)))
				var zl := HBoxContainer.new()
				zl.add_child(_icon_rect(UiIcons.tex("coin", 1), 16))
				zl.add_child(_label(_commas(Game.refine_cost(id)), 11, GOOD if Game.zeny >= Game.refine_cost(id) else BAD, true))
				mh.add_child(zl)
				v.add_child(mh)
			else:
				v.add_child(_label("Maximum refine reached!", 11, GOLD, true))
			h.add_child(v)
			var b := _button("Refine", func() -> void: _begin_refine(slot), 80)
			_color_button(b, BTN_GREEN)
			b.disabled = Game.refine_lv(id) >= Game.REFINE_MAX or (_guaranteed_refine and Game.count("guarantee_stone") < 1)
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(b)
			_smith_list.add_child(card)
	elif _smith_tab == 2:
		_fill_wings()
	elif _smith_tab in [1,8,9,10,6]:
		var category:String={1:"weapons",8:"hats",9:"armor",10:"accessories",6:"materials"}[_smith_tab]
		if _smith_tab==1:
			var filters:=GridContainer.new();filters.columns=5
			for option in [["all","ทั้งหมด"],["sword","ดาบ"],["axe","ขวาน"],["bow","ธนู"],["staff","คทา"],["dagger","มีด"],["spear","หอก"],["mace","กระบอง"],["greatsword","ดาบใหญ่"],["book","ตำรา"],["katar","กาตาร์"],["knuckle","สนับมือ"],["whip","แส้"],["instrument","เครื่องดนตรี"]]:
				var filter_button:=_button(option[1],func() -> void:
					_craft_weapon_kind=option[0];_fill_smith(),0)
				_set_tab(filter_button,_craft_weapon_kind==option[0]);filters.add_child(filter_button)
			_smith_list.add_child(filters)
		_fill_recipe_cards(Game.crafting_recipes(category,_craft_weapon_kind if _smith_tab==1 else "all"),"เลือกสูตร ดูวัตถุดิบที่ขาด และกดรวบรวมเพื่อหาแหล่งวัตถุดิบ")
	elif _smith_tab == 7:
		_fashion_gallery_view().fill(_smith_list, true)
	elif _smith_tab == 6:
		_fill_recipe_cards(Game.GATHER_RECIPES, "Gear forged from what you mine and fish. Click an ore rock to mine it (a few swings per haul, it grows back later) or a fishing spot on water to cast a line. Press \"Find\" next to a material to walk to the nearest place it comes from.")
	elif _smith_tab == 5:
		_fill_recipe_cards(Game.STAFF_RECIPES, "Fourteen Celestial Staves carved from solid 1/64 voxels for mages and acolytes. Press \"Gather\" next to a material to hunt the monster that drops it.")
	elif _smith_tab == 4:
		_fill_recipe_cards(Game.BOW_RECIPES, "Seven Arcane Bows carved from solid 1/64 voxels. Archers' two-handed bows; press \"Gather\" next to a material to hunt the monster that drops it.")
	elif _smith_tab == 3:
		_fill_recipe_cards(Game.ARCANE_RECIPES, "The Arcane Mage collection: weapons, shields and a full armour set, forged from zone materials and one boss trophy. Press \"Gather\" next to a material to hunt the monster that drops it.")
	else:
		_smith_list.add_child(_label("Forge new gear from monster materials.", 11, INK_L))
		for r in Game.RECIPES:
			var it := Items.info(r.id)
			var card := PanelContainer.new()
			var ok := Game.can_craft(r)
			card.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.28) if ok else Color(0, 0, 0, 0.45), SLOT_B, 2, 2, 6))
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			card.add_child(h)
			var ic := _slot(46)
			ic.icon = Items.icon(r.id)
			ic.tooltip_text = _item_tip(r.id)
			h.add_child(ic)
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_theme_constant_override("separation", 1)
			var stat := Items.stat_text(r.id)
			v.add_child(_label("%s   %s" % [Items.item_name(r.id), stat], 13, INK, true))
			var mats := HFlowContainer.new()
			mats.add_theme_constant_override("h_separation", 10)
			for m in r.mats:
				mats.add_child(_mat_row(m, int(r.mats[m])))
			var zl := HBoxContainer.new()
			zl.add_child(_icon_rect(UiIcons.tex("coin", 1), 16))
			zl.add_child(_label(_commas(int(r.zeny)), 11, GOOD if Game.zeny >= int(r.zeny) else BAD, true))
			mats.add_child(zl)
			v.add_child(mats)
			h.add_child(v)
			var b := _button("Craft", func() -> void:
				if Game.craft(r):
					_smith_msg.text = tr("Crafted %s!") % Items.item_name(r.id)
					_smith_msg.add_theme_color_override("font_color", GOOD)
				_fill_smith(), 70)
			_color_button(b, BTN_GREEN)
			b.disabled = not ok
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(b)
			_smith_list.add_child(card)


# ================================================================== update / keys
func toggle(c: Control) -> void:
	c.visible = not c.visible
	Audio.play("ui_open" if c.visible else "ui_close", null, 0.0, 0.03)
	if c.visible:
		c.move_to_front()
		if _mobile:
			_fit_windows.call_deferred()


func _process(delta: float) -> void:
	_update_stat_popups(delta)
	_update_quest_auto(delta)
	if _mobile:
		_fit_t -= delta
		if _fit_t <= 0.0:
			_fit_t = 0.3
			_fit_windows()
	if not _autoset.is_empty() and _autoset.panel.visible:
		_auto_refresh -= delta
		if _auto_refresh <= 0.0:
			_refresh_auto_monsters()
	_party_t -= delta
	if _party_t <= 0.0:
		_party_t = 0.25
		_update_party_bars()
		_update_online_bars()
	var hovered := get_viewport().gui_get_hovered_control()
	if _mobile and hovered == _mobile_hud:
		hovered = null        # the touch layer is "the world", not a panel
	Game.mouse_over_ui = hovered != null or _over_ui(get_viewport().get_mouse_position())
	_update_minimap()
	_update_clock()
	_qmark_t += delta
	if _qmark_t > 0.3:
		_qmark_t = 0.0
		var pl0 := get_tree().get_first_node_in_group("player") as Node3D
		if pl0 and _minimap.texture:
			var center := (Vector2(pl0.global_position.x, pl0.global_position.z) + Vector2(MINI_HALF, MINI_HALF)) / (MINI_HALF * 2.0)
			_update_quest_marks(_map_dots, func(p: Vector3) -> Vector2:
				var uv := (Vector2(p.x, p.z) + Vector2(MINI_HALF, MINI_HALF)) / (MINI_HALF * 2.0)
				return _minimap.size * (Vector2(0.5, 0.5) + (uv - center) / _map_zoom), 74.0)
		if _wmap.panel.visible:
			_update_quest_marks(_wmap_marks, _world_to_wmap, 0.0)
	if _wmap.panel.visible:
		_update_worldmap()
	_update_hot_cooldowns()
	if _auto_glow and (Game.auto_on or _auto_glow_t > 0.0):
		_auto_glow_t = _auto_glow_t + delta if Game.auto_on else 0.0
		_auto_glow.queue_redraw()
	var pl := get_tree().get_first_node_in_group("player")
	if pl and pl.has_method("is_casting"):
		_cast_bar.visible = pl.is_casting()
		_cast_bar.value = pl.cast_progress()
	_buff_t += delta
	if _buff_t > 0.5:
		_buff_t = 0.0
		_refresh_buffs()
	if _status.panel.visible and _status_spin:
		_status_yaw = fposmod(_status_yaw + delta * 0.6, TAU)
		Portrait.set_yaw(_status_vp, _status_yaw)
	if _equip.panel.visible and (not _mobile):
		_yaw += delta * 0.6
		Portrait.set_yaw(_equip_vp, _yaw)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = event.keycode
	# typing in the chat box: keys belong to the text field (Esc leaves it)
	if _chat_input and _chat_input.has_focus():
		if k == KEY_ESCAPE:
			_chat_input.release_focus()
			get_viewport().set_input_as_handled()
		return
	if (k == KEY_ENTER or k == KEY_KP_ENTER) and _chat_input and get_viewport().gui_get_focus_owner() == null:
		_chat_input.grab_focus()
		get_viewport().set_input_as_handled()
		return
	if (k == KEY_I and not event.alt_pressed) or (k == KEY_E and event.alt_pressed):
		toggle(_inv.panel)
	elif (k == KEY_S and not event.alt_pressed) or (k == KEY_A and event.alt_pressed):
		toggle(_status.panel)
	elif k == KEY_Q and event.alt_pressed:
		toggle(_equip.panel)
	elif (k == KEY_J and not event.alt_pressed) or (k == KEY_U and event.alt_pressed):
		toggle(_quests.panel)
	elif k == KEY_O and not event.alt_pressed:
		toggle(_settings.panel)
	elif k >= KEY_F1 and k <= KEY_F8:
		activate_hotkey(k - KEY_F1 + (8 if event.shift_pressed else 0))
	elif k >= KEY_1 and k <= KEY_8 and not (get_viewport().gui_get_focus_owner() is LineEdit):
		activate_hotkey(8 + k - KEY_1)
	elif (k == KEY_K and not event.alt_pressed) or (k == KEY_S and event.alt_pressed):
		toggle(_skills.panel)
	elif k == KEY_M and not event.alt_pressed:
		toggle(_wmap.panel)
	elif k == KEY_P and not event.alt_pressed:
		if _party.panel.visible:
			_party.panel.hide()
		else:
			open_party(_party_tab)
	elif k == KEY_Z and not event.alt_pressed:
		var p := get_tree().get_first_node_in_group("player")
		if p:
			p.toggle_auto()
	elif k == KEY_ESCAPE:
		var closed := false
		for wnd in [_invite_box.panel, _gift.panel, _pprof.panel, _settings.panel, _dialog.panel, _party.panel, _guild.panel, _shop.panel, _smith.panel, _autoset.panel, _wmap.panel, _skills.panel, _inv.panel, _status.panel, _quests.panel]:
			if wnd.visible:
				wnd.hide()
				closed = true
				break
		if not closed:
			toggle(_settings.panel)
	else:
		return
	get_viewport().set_input_as_handled()


# ================================================================== layout
func _sz(c: Control) -> Vector2:
	return c.size.max(c.get_combined_minimum_size())


func layout_defaults() -> void:
	## Put every window back in its default spot for the current (scaled) screen size.
	var vp := get_viewport().get_visible_rect().size
	_info_panel.position = Vector2(10, 10)
	_pills.position = Vector2(_sz(_info_panel).x + 22, 12)
	_menu.position = Vector2(vp.x - 196 - _sz(_menu).x - 10, 10)
	_map_panel.position = Vector2(vp.x - 190, 6)
	_tracker.panel.position = Vector2(vp.x - 236, 236)
	_clock.position = Vector2(vp.x - 100 - maxf(_sz(_clock).x, 120.0) * 0.5, 202)
	_buff_row.position = Vector2(14, 10 + _sz(_info_panel).y + 8)
	_party_frame.position = Vector2(12, _buff_row.position.y + 30)
	_party.panel.position = Vector2(vp.x * 0.5 - _sz(_party.panel).x * 0.5, maxf(10.0, vp.y * 0.5 - 250))
	_cast_bar.position = Vector2(vp.x * 0.5 - 110, vp.y - _sz(_hot_panel).y - 34)
	_skills.panel.position = Vector2(clampf(vp.x * 0.5 - 240, 330, 700), 60)
	_autoset.panel.position = Vector2(vp.x * 0.5 + 40, vp.y - 120 - _sz(_autoset.panel).y)
	_smith.panel.position = Vector2(vp.x * 0.5 - _sz(_smith.panel).x * 0.5, maxf(10.0, vp.y * 0.5 - 250))
	_wmap.panel.position = Vector2(vp.x * 0.5 - _sz(_wmap.panel).x * 0.5, maxf(6.0, vp.y * 0.5 - _sz(_wmap.panel).y * 0.5))
	_chat_panel.position = Vector2(10, vp.y - _sz(_chat_panel).y - 10)
	_hot_panel.position = Vector2(vp.x * 0.5 - _sz(_hot_panel).x * 0.5, vp.y - _sz(_hot_panel).y - 14)
	_status.panel.position = Vector2(10, 130)
	_inv.panel.position = Vector2(vp.x - 236 - _sz(_inv.panel).x - 12, 120)
	_quests.panel.position = Vector2(vp.x - 236 - _sz(_quests.panel).x - 12, 120)
	_dialog.panel.position = Vector2(vp.x * 0.5 - _sz(_dialog.panel).x * 0.5, vp.y - _sz(_dialog.panel).y - 96)
	_shop.panel.position = Vector2(vp.x * 0.5 - _sz(_shop.panel).x * 0.5, maxf(10.0, vp.y * 0.5 - 230))
	_settings.panel.position = Vector2(vp.x * 0.5 - _sz(_settings.panel).x * 0.5, maxf(10.0, vp.y * 0.5 - 230))
	_guild.panel.position = Vector2(vp.x * 0.5 - _sz(_guild.panel).x * 0.5, maxf(10.0, vp.y * 0.5 - 270))
	if _fade:
		_fade.size = vp
		_area_lbl.position = Vector2(0, vp.y * 0.3)
		_area_lbl.size = Vector2(vp.x, 100)
	if _mobile:
		_layout_mobile(vp)


# ================================================================== options window
func _build_settings() -> void:
	_settings = _window("Options", Vector2.ZERO, Vector2(460, 0), R_GRAY)
	var v := _settings.body as VBoxContainer
	_settings_tabs = TabContainer.new()
	_settings_tabs.custom_minimum_size = Vector2(440, 300)
	_settings_tabs.focus_mode = Control.FOCUS_NONE
	_settings_tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE
	_settings_tabs.add_theme_font_size_override("font_size", 13)
	v.add_child(_settings_tabs)
	_settings_tabs.tab_changed.connect(func(_t: int) -> void: _settings.panel.reset_size())

	var game := _opt_page("Game")
	if OS.get_name() == "Web":
		# on phones the page has no buttons around the game: screen + reload live here
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var fs := _button(tr("Full screen"), func() -> void:
			JavaScriptBridge.eval("if(window.parent.blockrealmEnterDisplay)window.parent.blockrealmEnterDisplay();"), 0)
		var exit := _button(tr("Exit full screen"), func() -> void:
			_settings.panel.hide()
			JavaScriptBridge.eval("if(window.parent.blockrealmRestoreDisplay)window.parent.blockrealmRestoreDisplay();"), 0)
		var reload := _button(tr("Reload game"), func() -> void:
			if Game.character_ready:
				Game.save_game()
			JavaScriptBridge.eval("if(window.parent.blockrealmReloadGame){window.parent.blockrealmReloadGame();}else{location.reload();}"), 0)
		_color_button(reload, Color(0.55, 0.32, 0.12))
		for b in [fs, exit, reload]:
			(b as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			(b as Control).custom_minimum_size.y = 38
			row.add_child(b)
		game.add_child(row)
	_opt_choice(game, "Language", "language", [["English", "en"], ["ภาษาไทย", "th"]])
	_opt_check(game, "Show damage numbers", "damage_numbers")
	_opt_check(game, "Show NPC names", "npc_names")
	_opt_check(game, "Highlight on mouse-over", "outlines")
	_opt_check(game, "See-through walls", "xray")
	_opt_choice(game, "Season", "season", [["Follow calendar", -1], ["Spring", 0], ["Summer", 1], ["Autumn", 2], ["Winter", 3]])
	_opt_check(game, "Weather (rain / snow)", "weather")

	var account_page := _opt_page("บัญชีเกม")
	account_page.add_child(preload("res://scripts/ui/account_panel.gd").new())

	var gfx := _opt_page("Graphics")
	if OS.get_name() == "Web":
		var enter_screen := _button("เต็มจอแนวนอน / ขยายหน้าต่าง", func() -> void:
			JavaScriptBridge.eval("if(window.parent.blockrealmEnterDisplay)window.parent.blockrealmEnterDisplay();"))
		gfx.add_child(enter_screen)
		var restore_screen := _button("คืนค่าจอเดิม", func() -> void:
			JavaScriptBridge.eval("if(window.parent.blockrealmRestoreDisplay)window.parent.blockrealmRestoreDisplay();"))
		gfx.add_child(restore_screen)
	else:
		_opt_check(gfx, "Fullscreen", "fullscreen")
	_opt_check(gfx, "V-Sync", "vsync")
	_opt_choice(gfx, "Shadows", "shadows", [["Off", 0], ["Low", 1], ["High", 2]])
	_opt_choice(gfx, "Anti-aliasing", "msaa", [["Off", 0], ["2x", 1], ["4x", 2]])
	_opt_slider(gfx, "Render scale", "render_scale", 0.5, 1.0, 0.05, "%d%%", 100.0)
	_opt_slider(gfx, "View distance", "view_distance", 60.0, 400.0, 10.0, "%d m")
	_opt_check(gfx, "Clouds", "clouds")

	var snd := _opt_page("Sound")
	_opt_slider(snd, "Master volume", "vol_master", 0.0, 1.0, 0.05, "%d%%", 100.0)
	_opt_slider(snd, "Music", "vol_music", 0.0, 1.0, 0.05, "%d%%", 100.0)
	_opt_slider(snd, "Sound effects", "vol_sfx", 0.0, 1.0, 0.05, "%d%%", 100.0)
	_opt_slider(snd, "Ambience (birds, rain, wind)", "vol_ambient", 0.0, 1.0, 0.05, "%d%%", 100.0)

	var ui := _opt_page("Interface")
	_opt_slider(ui, "Nameplate text size", "nameplate_scale", 0.5, 2.0, 0.1, "%d%%", 100.0)
	_opt_slider(ui, "UI scale", "ui_scale", 0.75, 1.5, 0.05, "%d%%", 100.0)
	_opt_slider(ui, "Chat opacity", "chat_opacity", 0.3, 1.0, 0.05, "%d%%", 100.0)
	_opt_check(ui, "Show minimap", "minimap")
	var rp := _button("Reset window positions", layout_defaults)
	rp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ui.add_child(rp)

	var ctl := _opt_page("Controls")
	_opt_slider(ctl, "Camera rotate speed", "cam_rotate_speed", 0.25, 2.5, 0.05, "%.2fx")
	_opt_slider(ctl, "Zoom step", "zoom_step", 0.5, 5.0, 0.25, "%.2f m")
	_opt_check(ctl, "Invert camera drag", "invert_drag")
	ctl.add_child(_label("Key bindings", 13, ACCENT, true))
	_keys_lbl = RichTextLabel.new()
	_keys_lbl.bbcode_enabled = true
	_keys_lbl.fit_content = true
	_keys_lbl.custom_minimum_size = Vector2(400, 20)
	_keys_lbl.add_theme_color_override("default_color", INK)
	_keys_lbl.add_theme_font_size_override("normal_font_size", 12)
	_keys_lbl.add_theme_font_size_override("bold_font_size", 12)
	_keys_lbl.add_theme_font_override("bold_font", _font_b)
	ctl.add_child(_keys_lbl)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 4)
	bottom.add_child(_button("Reset to defaults", func() -> void: Settings.reset(), 0))
	bottom.add_child(_button("Return to Title", func() -> void:
		if Game.character_ready:
			Game.save_game()
		get_tree().change_scene_to_file("res://scenes/character_create.tscn"), 0))
	if OS.get_name() != "Web":
		bottom.add_child(_button("Exit game", func() -> void:
			if Game.character_ready:
				Game.save_game()
			get_tree().quit(), 0))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(sp)
	bottom.add_child(_color_button(_button("Close", _settings.panel.hide, 70), BTN_GREEN))
	v.add_child(bottom)
	v.add_child(_label("Settings are saved automatically.", 11, INK_L))
	_settings.panel.hide()


func _opt_page(title: String) -> VBoxContainer:
	var m := MarginContainer.new()
	m.name = title
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 8)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	m.add_child(page)
	_settings_tabs.add_child(m)
	return page


func _opt_row(page: VBoxContainer, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := _label(text, 13)
	l.custom_minimum_size.x = 200
	h.add_child(l)
	page.add_child(h)
	return h


func _opt_check(page: VBoxContainer, text: String, key: String) -> void:
	var h := _opt_row(page, text)
	var c := CheckButton.new()
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_size_override("font_size", 13)
	for st in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color", "font_focus_color"]:
		c.add_theme_color_override(st, Color(1.0, 0.92, 0.5))
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		c.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	h.add_child(c)
	_opt_controls[key] = c


func _opt_choice(page: VBoxContainer, text: String, key: String, items: Array) -> void:
	var h := _opt_row(page, text)
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	o.custom_minimum_size.x = 150
	for i in items.size():
		o.add_item(items[i][0], i)
		o.set_item_metadata(i, items[i][1])
	o.item_selected.connect(func(i: int) -> void: Settings.set_value(key, o.get_item_metadata(i)))
	h.add_child(o)
	_opt_controls[key] = o


func _opt_slider(page: VBoxContainer, text: String, key: String, lo: float, hi: float, step: float, fmt: String, mul := 1.0) -> void:
	var h := _opt_row(page, text)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.focus_mode = Control.FOCUS_NONE
	s.custom_minimum_size.x = 150
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(s)
	var val := _label("", 12, INK_L, true)
	val.custom_minimum_size.x = 56
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(val)
	var show_val := func(x: float) -> void:
		val.text = fmt % (roundi(x * mul) if fmt.contains("%d") else x * mul)
	# apply when the drag ends (UI scale / render scale are expensive to change every tick)
	s.value_changed.connect(show_val)
	s.drag_ended.connect(func(_c: bool) -> void: Settings.set_value(key, s.value))
	s.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and not e.pressed:
			Settings.set_value(key, s.value))
	_opt_controls[key] = [s, show_val]


func _sync_settings_controls() -> void:
	for key in _opt_controls:
		var c = _opt_controls[key]
		var v = Settings.g(key)
		if c is CheckButton:
			c.set_pressed_no_signal(v)
			c.text = tr("On") if v else tr("Off")
		elif c is OptionButton:
			for i in c.item_count:
				if c.get_item_metadata(i) == v:
					c.select(i)
		else:
			(c[0] as HSlider).set_value_no_signal(v)
			(c[1] as Callable).call(float(v))


func _on_settings_changed() -> void:
	_sync_settings_controls()
	for i in _settings_tabs.get_tab_count():
		_settings_tabs.set_tab_title(i, tr(_settings_tabs.get_child(i).name))
	_keys_lbl.text = tr(LocTH.KEYS)
	_settings.panel.reset_size.call_deferred()
	_chat_panel.modulate.a = Settings.g("chat_opacity")
	if _mobile:
		var want := float(Settings.g("ui_scale")) * _mobile_scale
		if not is_equal_approx(get_window().content_scale_factor, want):
			get_window().content_scale_factor = want
			layout_defaults.call_deferred()
	_map_panel.visible = Settings.g("minimap")
	_refresh()
	_refresh_inventory()
	_refresh_quests()
	for n in get_tree().get_nodes_in_group("npc"):
		if n.has_method("refresh_label"):
			n.refresh_label()
	# keep windows on screen after a UI-scale change
	var vp := get_viewport().get_visible_rect().size
	for w in _windows:
		if w.get_parent() == _root:
			w.position = w.position.clamp(Vector2.ZERO, (vp - _sz(w)).max(Vector2.ZERO))


# ================================================================== warp fade + area title
func _build_fade() -> void:
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)
	_area_lbl = _label("", 30, TITLE)
	_area_lbl.add_theme_font_override("font", _font_t)
	_area_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_area_lbl.add_theme_constant_override("outline_size", 8)
	_area_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_area_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area_lbl.modulate.a = 0.0
	_root.add_child(_area_lbl)


## Called by the player after walking through a door / stairs warp.
func show_loading(area: String) -> void:
	_fade.size = get_viewport().get_visible_rect().size
	_fade.color = Color(0, 0, 0, 1)
	_area_lbl.text = tr(VillageBuilder.AREA_NAMES.get(area, area)) + "\n" + tr("Loading...")
	_area_lbl.modulate.a = 1.0


func area_changed(area: String) -> void:
	_fade.size = get_viewport().get_visible_rect().size
	_fade.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.45).set_ease(Tween.EASE_OUT)
	_area_lbl.text = tr(VillageBuilder.AREA_NAMES.get(area, area))
	if Zones.LEVELS.has(area):
		_area_lbl.text += "\n" + String(Zones.LEVELS[area])
	var tl := create_tween()
	tl.tween_property(_area_lbl, "modulate:a", 1.0, 0.3)
	tl.tween_interval(1.4)
	tl.tween_property(_area_lbl, "modulate:a", 0.0, 0.6)
	add_message(tr("Entered: %s") % tr(VillageBuilder.AREA_NAMES.get(area, area)), INK_L)
	for z in load("res://scripts/monsters/spawner.gd").ZONES:
		if z.get("boss", false) and String(z.get("area", "town")) == area:
			add_message(tr("A powerful boss lurks here: %s (Lv %d)!") % [tr(z.name), int(z.lv)], Color(1.0, 0.55, 0.4))


# ================================================================== guild: special quest board + ranking
func _build_guild_board() -> void:
	_guild = _window("Adventurers' Guild", Vector2(300, 60), Vector2(500, 0), R_YELLOW)
	_guild_head = VBoxContainer.new()
	_guild_head.add_theme_constant_override("separation", 4)
	_guild.body.add_child(_guild_head)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for t in [["Special Quests", 0], ["Ranking", 1]]:
		var b := _button(t[0], func() -> void:
			_guild_tab = t[1]
			_fill_guild(), 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		_guild_tabs.append(b)
	_guild.body.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 330)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_guild_list = VBoxContainer.new()
	_guild_list.add_theme_constant_override("separation", 6)
	_guild_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_guild_list)
	_guild.body.add_child(sc)
	_guild.panel.hide()
	Game.quest_changed.connect(func() -> void:
		if _guild.panel.visible:
			_fill_guild())


func open_guild_board(tab := 0) -> void:
	_guild_tab = tab
	if Game.guild_member and Game.board_offers.is_empty():
		Guild.gen_offers()
	_fill_guild()
	_guild.panel.show()
	_guild.panel.move_to_front()


func _rank_badge(r: int, size := 34) -> PanelContainer:
	var c: Color = Guild.RANK_COLORS[r]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(c.darkened(0.55), c, 2, 6, 4))
	p.custom_minimum_size = Vector2(size, size)
	var l := _label(Guild.RANKS[r], int(size * 0.6), c.lightened(0.2))
	l.add_theme_font_override("font", _font_t)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


func _fill_guild() -> void:
	for box in [_guild_head, _guild_list]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	for i in _guild_tabs.size():
		_set_tab(_guild_tabs[i], i == _guild_tab)
	# ---- header: rank, GP and progress to the next rank
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	_guild_head.add_child(h)
	if not Game.guild_member:
		h.add_child(_rank_badge(0))
		var nl := _label("You are not registered yet. Talk to Guild Clerk Mira at the counter to get your Guild Card.", 12, INK_L)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.custom_minimum_size.x = 400
		h.add_child(nl)
	else:
		var r: int = Game.guild_rank
		h.add_child(_rank_badge(r, 46))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 2)
		v.add_child(_label(tr("Rank %s · %s") % [Guild.letter(), tr(Guild.RANK_TITLES[r])], 15, TITLE, true))
		if r + 1 < Guild.RANKS.size():
			var need: Array = Guild.RANK_REQ[r + 1]
			var bar := _bar(Guild.RANK_COLORS[r + 1], 14)
			bar.bar.max_value = need[0]
			bar.bar.value = mini(Game.guild_points, int(need[0]))
			bar.label.text = "%d / %d GP" % [Game.guild_points, need[0]]
			v.add_child(bar.box)
			var block := Guild.rank_up_block()
			v.add_child(_label(tr("Next: Rank %s (Base Lv %d)") % [Guild.RANKS[r + 1], need[1]] if block != "" else tr("Rank up ready! Report to Guild Clerk Mira."),
				11, INK_L if block != "" else GOOD, true))
		else:
			v.add_child(_label(tr("Highest rank reached - a true legend! %d GP") % Game.guild_points, 12, GOLD, true))
		h.add_child(v)
		var bonus := _label(tr("EXP +%d%%") % int(round((Guild.exp_mult() - 1.0) * 100)), 12, GOOD, true)
		bonus.tooltip_text = tr("Monster EXP bonus from your rank")
		h.add_child(bonus)
	if _guild_tab == 0:
		_fill_guild_quests()
	else:
		_fill_guild_ranking()
	_guild.panel.reset_size()


func _guild_card(body: Control, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var cs := _sb(Color(accent, 0.07), Color(accent, 0.45), 1, 6, 10)
	cs.content_margin_top = 8
	cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)
	card.add_child(body)
	return card


func _fill_guild_quests() -> void:
	if not Game.guild_member:
		return
	var a: Dictionary = Game.board_active
	if not a.is_empty():
		_guild_list.add_child(_label("Current bounty", 13, TITLE, true))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		h.add_child(_rank_badge(int(a.rank), 30))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(_label(Guild.offer_text(a), 13, CREAM, true))
		var pr := Guild.progress()
		var bar := _bar(Color(0.85, 0.66, 0.24), 12)
		bar.bar.max_value = pr[1]
		bar.bar.value = pr[0]
		bar.label.text = "%d / %d" % [pr[0], pr[1]]
		v.add_child(bar.box)
		v.add_child(_label(tr("Reward:") + " " + Guild.reward_text(a), 11, ACCENT, true))
		h.add_child(v)
		var bv := VBoxContainer.new()
		var claim := _button("Claim", func() -> void:
			if Guild.claim():
				var p := get_tree().get_first_node_in_group("player") as Node3D
				if p:
					FX.flash(p, p.global_position + Vector3(0, 1.0, 0), Color(1.0, 0.85, 0.35), 1.4)
			_fill_guild(), 90)
		_color_button(claim, BTN_GREEN)
		claim.disabled = not Guild.is_done()
		bv.add_child(claim)
		var ab := _button("Abandon", func() -> void:
			Guild.abandon()
			_fill_guild(), 90)
		bv.add_child(ab)
		h.add_child(bv)
		_guild_list.add_child(_guild_card(h, GOLD))
	_guild_list.add_child(_label("Bounties on the board", 13, TITLE, true))
	for i in Game.board_offers.size():
		var o: Dictionary = Game.board_offers[i]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		h.add_child(_rank_badge(int(o.rank), 30))
		var ic := _icon_rect(Items.icon(o.item) if o.type == "collect" else UiIcons.tex("slime", 2), 28)
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(_label(Guild.offer_text(o), 13, INK, true))
		v.add_child(_label(tr("Reward:") + " " + Guild.reward_text(o), 11, ACCENT, true))
		h.add_child(v)
		var acc := _button("Accept", func() -> void:
			Guild.accept(i)
			_fill_guild()
			_start_bounty_auto(), 90)
		_color_button(acc, BTN_GREEN)
		acc.disabled = not a.is_empty()
		acc.tooltip_text = tr("Finish or abandon your current bounty first.") if not a.is_empty() else ""
		acc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(acc)
		_guild_list.add_child(_guild_card(h, Guild.RANK_COLORS[int(o.rank)]))
	var tip := _label("Harder bounties unlock as your rank rises. New bounties are posted every time you claim a reward.", 11, INK_L)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 460
	_guild_list.add_child(tip)


func _fill_guild_ranking() -> void:
	var rows := Guild.leaderboard()
	var place := Guild.player_place()
	var msg := tr("You are #%d of %d adventurers.") % [place, rows.size()]
	if place > 1:
		var above: Array = rows[place - 2]
		msg += "  " + tr("%d GP more to pass %s.") % [int(above[2]) - Game.guild_points + 1, above[0]]
	_guild_list.add_child(_label(msg, 12, GOLD, true))
	for i in rows.size():
		var r: Array = rows[i]
		var me: bool = r[3]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var pos := _label("#%d" % (i + 1), 15, GOLD if i < 3 else INK_L, true)
		pos.custom_minimum_size.x = 36
		h.add_child(pos)
		h.add_child(_rank_badge(Guild.rank_for_gp(int(r[2])) if not me else Game.guild_rank, 26))
		var nm := _label(String(r[0]), 13, CREAM if me else INK, true)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(nm)
		h.add_child(_label(tr(String(r[1])), 12, INK_L))
		var gp := _label("%d GP" % int(r[2]), 13, GOLD if me else INK, true)
		gp.custom_minimum_size.x = 70
		gp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(gp)
		var card := PanelContainer.new()
		var cs := _sb(Color(GOLD, 0.16) if me else Color(0, 0, 0, 0.25), GOLD if me else SLOT_B, 1, 6, 8)
		cs.content_margin_top = 3
		cs.content_margin_bottom = 3
		card.add_theme_stylebox_override("panel", cs)
		card.add_child(h)
		_guild_list.add_child(card)


# ================================================================== party (P)
func _party_portrait(d: Dictionary) -> Texture2D:
	var key := "%s|%s|%d" % [d.name, d.job, Party.tier()]
	if not _party_vps.has(key):
		_party_vps[key] = Portrait.make(self, Vector2i(96, 96), "avatar", Avatar.dress(d.look, Party.gear_for(d.job), {}), "head", false)
	return (_party_vps[key] as SubViewport).get_texture()


func _build_party() -> void:
	_party_frame = VBoxContainer.new()
	_party_frame.add_theme_constant_override("separation", 4)
	_root.add_child(_party_frame)
	_party = _window("Party", Vector2.ZERO, Vector2(520, 0), R_TEAL)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	for t in [["My party", 0], ["Find adventurers", 1], ["Online players", 2]]:
		var b := _button(t[0], func() -> void:
			_party_tab = t[1]
			_fill_party(), 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.set_meta("tab", t[1])
		tabs.add_child(b)
	tabs.name = "Tabs"
	_party.body.add_child(tabs)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.name = "List"
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	_party.body.add_child(sc)
	_party.list = list
	_party.tabs = tabs
	_party.panel.hide()
	_refresh_party_frame()


func open_party(tab := 0) -> void:
	_party_tab = tab
	_fill_party()
	_party.panel.show()
	_party.panel.move_to_front()


func _member_card(d: Dictionary, right: Control, sub: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.1), 1, 6, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	card.add_child(h)
	var fr := _round_frame(58, Color(0.16, 0.2, 0.28), GOLD_D, 2)
	fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var face := TextureRect.new()
	face.texture = _party_portrait(d)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.custom_minimum_size = Vector2(54, 54)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.add_child(face)
	h.add_child(fr)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var role: String = Party.ROLES[d.job].role
	v.add_child(_label("%s   Lv %d" % [d.name, Game.base_level], 15, CREAM, true))
	v.add_child(_label("%s  ·  %s" % [tr(Party.job_title(d.job)), tr(role)], 12, ACCENT))
	v.add_child(_label(sub, 11, INK_L))
	h.add_child(v)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(right)
	return card


func _fill_party() -> void:
	var list: VBoxContainer = _party.list
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	for b in (_party.tabs as Control).get_children():
		_color_button(b, BTN_GREEN if int(b.get_meta("tab")) == _party_tab else WOOD)
	var n: int = Game.party.size()
	if _party_tab == 2:
		_fill_online_party(list)
	elif _party_tab == 0:
		list.add_child(_label(tr("Party members: %d / %d  (plus you)") % [n, Party.MAX_MEMBERS], 13, TITLE, true))
		if n == 0:
			list.add_child(_label("You are adventuring alone. Open \"Find adventurers\" to invite up to 3 companions at your level. They follow you, fight with you and share the EXP with you.", 12, INK_L))
		var nodes := {}
		for m in Party.members():
			nodes[m.info.name] = m
		for i in n:
			var d: Dictionary = Game.party[i]
			var st := Party.stats(d.job)
			var m = nodes.get(d.name)
			var hp_txt := "HP %d / %d" % [m.hp, m.max_hp] if m else "HP %d" % st.hp
			var b := _button("Dismiss", func() -> void:
				Party.dismiss(i)
				_fill_party(), 0)
			_color_button(b, Color(0.55, 0.2, 0.18))
			list.add_child(_member_card(d, b, "%s   ATK %d   DEF %d" % [hp_txt, st.atk, st.def]))
		var fb := _button("Find adventurers", func() -> void:
			_party_tab = 1
			_fill_party(), 0)
		_color_button(fb, BTN_GREEN)
		fb.disabled = n >= Party.MAX_MEMBERS
		list.add_child(fb)
	else:
		list.add_child(_label(tr("Adventurers looking for a party - all at your level (Lv %d)") % Game.base_level, 13, TITLE, true))
		for d in Party.candidates():
			var st := Party.stats(d.job)
			var b := _button("Invite", func() -> void:
				if Party.recruit(d):
					_fill_party(), 0)
			_color_button(b, BTN_GREEN)
			b.disabled = n >= Party.MAX_MEMBERS
			list.add_child(_member_card(d, b, "HP %d   ATK %d   DEF %d" % [st.hp, st.atk, st.def]))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		var nf := _button("New faces", func() -> void:
			Party.new_faces()
			_fill_party(), 0)
		h.add_child(nf)
		if n >= Party.MAX_MEMBERS:
			h.add_child(_label("Your party is full.", 12, Color(1.0, 0.6, 0.45)))
		list.add_child(h)
	_party.panel.reset_size()


func _refresh_party_frame() -> void:
	if _party_frame == null:
		return
	for c in _party_frame.get_children():
		_party_frame.remove_child(c)
		c.queue_free()
	_party_bars.clear()
	var nodes := {}
	for m in Party.members():
		nodes[m.info.name] = m
	for d in Game.party:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _pixel_box(R_TEAL, 2, 0.0, 6))
		p.custom_minimum_size = Vector2(200, 0)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				open_party(0))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		p.add_child(h)
		var face := TextureRect.new()
		face.texture = _party_portrait(d)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.custom_minimum_size = Vector2(34, 34)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(face)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl := _label("%s  ·  %s" % [d.name, tr(Party.job_title(d.job))], 11, CREAM, true)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(nl)
		var hb := _bar(Color(0.25, 0.75, 0.95), 11)
		hb.box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(hb.box)
		h.add_child(v)
		_party_frame.add_child(p)
		_party_bars.append([nodes.get(d.name), hb.bar, hb.label, face])
	_add_online_frames()
	var add := _button(tr("Party (P)") if Game.party.is_empty() and Net.party_id == 0 else "+", func() -> void: open_party(1 if Game.party.size() < Party.MAX_MEMBERS else 0), 0)
	add.add_theme_font_size_override("font_size", 11)
	add.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add.visible = Game.party.size() < Party.MAX_MEMBERS
	_party_frame.add_child(add)
	_update_party_bars()


func _update_party_bars() -> void:
	if _party_bars.is_empty():
		return
	var nodes := {}
	for m in Party.members():
		nodes[m.info.name] = m
	for i in _party_bars.size():
		var row: Array = _party_bars[i]
		if i >= Game.party.size():
			continue
		var m = nodes.get(Game.party[i].name)
		if m == null:
			continue
		var bar: ProgressBar = row[1]
		bar.max_value = m.max_hp
		bar.value = m.hp
		(row[2] as Label).text = "%d / %d" % [m.hp, m.max_hp] if m.is_alive() else tr("Knocked out")
		(row[3] as TextureRect).modulate = Color(1, 1, 1) if m.is_alive() else Color(0.4, 0.4, 0.4)


# ================================================================== wyvern wings (smith tab 2)
func _fill_wings() -> void:
	_fill_recipe_cards(Game.WING_RECIPES, "Wyvern wings are worn in the garment slot. They flap when you run and glide when you rest. Press \"Gather\" next to a material to hunt the monster that drops it.")


## One card per recipe: icon, stats, each material with where it drops and a
## "Gather" button (auto-hunt), the Zeny cost and a Craft button.
func _fill_recipe_cards(recipes: Array, intro: String) -> void:
	var il := _label(intro, 11, INK_L)
	il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_smith_list.add_child(il)
	for r in recipes:
		var ok := Game.can_craft(r)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _sb(Color(0, 0, 0, 0.28) if ok else Color(0, 0, 0, 0.45), SLOT_B, 2, 4, 8))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		card.add_child(h)
		var ic := _slot(64)
		ic.icon = Items.icon(r.id)
		ic.expand_icon = true
		if Items.info(r.id).get("portrait", false):
			# full-outfit picture fills a taller frame
			ic.custom_minimum_size = Vector2(96, 128)
			ic.icon = null
			var pic := TextureRect.new()
			pic.texture = Items.icon(r.id)
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
			ic.add_child(pic)
		ic.tooltip_text = _item_tip(r.id)
		ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 3)
		v.add_child(_label(Items.item_name(r.id), 14, TITLE, true))
		var st := _label(Items.stat_text(r.id), 11, ACCENT)
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(st)
		v.add_child(_label("Materials:", 11, INK_L, true))
		for m in r.mats:
			var need := int(r.mats[m])
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var mr := _mat_row(m, need)
			mr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(mr)
			var zn := _zone_for_item(m)
			var gsrc := Gathering.sources(m)
			if zn == "" and not gsrc.is_empty():
				var parts := PackedStringArray()
				for sx in gsrc:
					var an: String = "Aldenvale" if sx[1] == "town" else VillageBuilder.AREA_NAMES.get(sx[1], sx[1])
					parts.append("%s %s" % [tr("Mining:") if sx[0] == "ore" else tr("Fishing:"), tr(an)])
				var gl := _label(" · ".join(parts), 10, INK_L)
				gl.custom_minimum_size.x = 150
				gl.clip_text = true
				gl.tooltip_text = "\n".join(parts)
				row.add_child(gl)
				var fb := _button("Find", func() -> void: _find_gather(m), 0)
				fb.add_theme_font_size_override("font_size", 11)
				fb.disabled = Game.count(m) >= need
				row.add_child(fb)
			elif zn != "":
				var z := _zone_by_name(zn)
				var src := "%s Lv%d" % [tr(zn), int(z.get("lv", 0))]
				var za := String(z.get("area", "town"))
				if za != "town":
					src += " · " + tr(VillageBuilder.AREA_NAMES.get(za, za))
				var sl := _label(src, 10, INK_L)
				sl.custom_minimum_size.x = 150
				sl.clip_text = true
				row.add_child(sl)
				var g := _button("Gather", func() -> void: _gather(m), 0)
				g.add_theme_font_size_override("font_size", 11)
				g.disabled = Game.count(m) >= need
				row.add_child(g)
			v.add_child(row)
		var zl := HBoxContainer.new()
		zl.add_child(_icon_rect(UiIcons.tex("coin", 1), 16))
		zl.add_child(_label(_commas(int(r.zeny)), 11, GOOD if Game.zeny >= int(r.zeny) else BAD, true))
		v.add_child(zl)
		h.add_child(v)
		var b := _button("Craft", func() -> void:
			if Game.craft(r):
				_smith_msg.text = tr("Crafted %s!") % Items.item_name(r.id)
				_smith_msg.add_theme_color_override("font_color", GOOD)
			_fill_smith(), 70)
		_color_button(b, BTN_GREEN)
		b.disabled = not ok
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
		_smith_list.add_child(card)


## Travel to an available source map and automatically gather the requested material.
func _find_gather(item: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null: return
	# Close menus before starting the trip so modal gesture cancellation cannot erase it.
	_smith.panel.hide()
	_dialog.panel.hide()
	player.start_resource_trip(item)


## Walk to the monster that drops `item` and hunt it automatically.
func _gather(item: String) -> void:
	var zn := _zone_for_item(item)
	if zn == "":
		return
	_smith.panel.hide()
	_dialog.panel.hide()
	_quest_go({"zone": zn})
	add_message(tr("Gathering %s: hunting %s.") % [Items.item_name(item), tr(zn)], Color(1.0, 0.85, 0.4))


func _begin_refine(slot: String) -> void:
	if _refine_busy:
		return
	_refine_busy = true
	var id: String = Game.equip.get(slot, "")
	var before := Game.refine_lv(id)
	var result := Game.try_refine(slot, _guaranteed_refine)
	if result not in ["ok", "fail"]:
		_refine_busy = false
		var messages := {"guarantee": "You need a Guaranteed Refine Stone.", "ore": "You need more Refine Stones.", "zeny": "Not enough Zeny.", "max": "Already at maximum.", "empty": "Nothing equipped."}
		dialog("Blacksmith", messages.get(result, result), ["Close"], Callable())
		return
	# Commit once before the presentation, so closing the game cannot reroll.
	Game.save_game()
	var popup := preload("res://scripts/ui/refine_popup.gd").new()
	popup.item_id = id
	popup.before = before
	popup.after = Game.refine_lv(id)
	popup.success = result == "ok"
	popup.finished.connect(func() -> void:
		_refine_busy = false
		_fill_smith())
	add_child(popup)


# ================================================================== online: profile, gifts, party invites
var _pprof := {}            # profile window of another online player
var _pprof_id := 0
var _pprof_vp: SubViewport
var _gift := {}             # "send item" window
var _gift_sel := ""
var _invite_box := {}       # incoming party invite prompt
var _invite_from := 0
var _online_bars: Array = []   # [player id, bar, label]


func _build_online() -> void:
	_pprof = _window("Adventurer profile", Vector2(380, 90), Vector2(420, 0), R_TEAL)
	_pprof.panel.hide()
	_gift = _window("Send an item", Vector2(420, 110), Vector2(380, 0), R_YELLOW)
	_gift.panel.hide()
	_invite_box = _window("Party invite", Vector2(440, 200), Vector2(340, 0), R_TEAL, false)
	_invite_box.panel.hide()
	Net.invite_received.connect(_on_invite)
	Net.party_changed.connect(func() -> void:
		_refresh_party_frame()
		if _party.panel.visible:
			_fill_party()
		if _pprof.panel.visible:
			_fill_profile())
	Net.players_changed.connect(func() -> void:
		if _party.panel.visible and _party_tab == 2:
			_fill_party()
		if _pprof.panel.visible and Net.remote(_pprof_id) == null:
			_pprof.panel.hide()
			_gift.panel.hide())
	Net.status_changed.connect(func(_on: bool, _n: int) -> void:
		if _party.panel.visible and _party_tab == 2:
			_fill_party())


func _clear(c: Control) -> void:
	for k in c.get_children():
		c.remove_child(k)
		k.queue_free()


func _job_name(job: String) -> String:
	return tr(String(Avatar.job(job).get("name", job.capitalize())))


## Profile of another online player: picture, level, class, gear and actions.
func open_player_profile(id: int) -> void:
	if Net.remote(id) == null:
		return
	_pprof_id = id
	_fill_profile()
	_pprof.panel.show()
	_pprof.panel.move_to_front()


func _fill_profile() -> void:
	var r := Net.remote(_pprof_id)
	var body: VBoxContainer = _pprof.body
	_clear(body)
	if r == null:
		_pprof.panel.hide()
		return
	var info: Dictionary = r.info
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	body.add_child(h)
	# full-body picture of their character
	if _pprof_vp and is_instance_valid(_pprof_vp):
		_pprof_vp.queue_free()
	_pprof_vp = Portrait.make(self, Vector2i(150, 200), "avatar", r.model.appearance if r.model else {}, "body", false)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(Color(0.14, 0.17, 0.24), Color(LINE, 0.6), 1, 8, 2))
	var pic := TextureRect.new()
	pic.texture = _pprof_vp.get_texture()
	pic.custom_minimum_size = Vector2(130, 175)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(pic)
	h.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(_label(String(info.get("name", "?")), 18, CREAM, true))
	v.add_child(_label("%s   ·   Lv %d" % [_job_name(String(info.get("job", ""))), int(info.get("lv", 1))], 13, ACCENT, true))
	var status := tr("In your party") if Net.in_party(_pprof_id) else tr("Online")
	v.add_child(_label("%s   ·   HP %d%%" % [status, r.hp_pct], 12, Color(0.55, 1.0, 0.6) if Net.in_party(_pprof_id) else INK_L))
	v.add_child(_label("Equipment", 12, TITLE, true))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	var equip: Dictionary = info.get("equip", {})
	var refine: Dictionary = info.get("refine", {})
	for slot in Items.SLOTS:
		var b := _slot(44)
		var id: String = String(equip.get(slot, ""))
		if id != "":
			b.icon = Items.icon(id)
			var lv := int(refine.get(id, 0))
			b.tooltip_text = ("+%d " % lv if lv > 0 else "") + Items.item_name(id)
			if lv > 0:
				_refine_glow(b, lv)
			b.gui_input.connect(func(e: InputEvent) -> void:
				if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and _is_touch():
					_item_peek(id, b))
		else:
			b.tooltip_text = tr(Items.SLOT_NAMES[slot]) + ": -"
			b.disabled = true
		grid.add_child(b)
	# actions
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	var mine := Net.in_party(_pprof_id)
	if mine:
		if Net.party_leader == Net.my_id:
			var kb := _button(tr("Remove from party"), func() -> void: Net.kick(_pprof_id), 0)
			_color_button(kb, Color(0.55, 0.2, 0.18))
			row.add_child(kb)
	else:
		var ib := _button(tr("Invite to party"), func() -> void: Net.invite(_pprof_id), 0)
		_color_button(ib, BTN_GREEN)
		ib.disabled = not Net.online or Net.party_members.size() >= Net.PARTY_MAX
		row.add_child(ib)
	var gb := _button(tr("Send item"), func() -> void: open_gift(_pprof_id), 0)
	_color_button(gb, GOLD_D)
	gb.disabled = not Net.online
	row.add_child(gb)
	for c in row.get_children():
		(c as Control).custom_minimum_size.y = 36
		(c as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pprof.panel.reset_size()


## Small read-only card for an item (touch screens have no tooltips).
func _item_peek(id: String, anchor: Control) -> void:
	_close_item_menu()
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_close_item_menu())
	add_child(layer)
	_menu_layer = layer
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(Color(0.1, 0.09, 0.08, 0.97), GOLD_D, 2, 6, 10))
	layer.add_child(p)
	var t := _label(Items.item_name(id) + "\n" + Items.stat_text(id) + "\n" + Items.desc(id), 12, INK)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(240, 0)
	p.add_child(t)
	var r := anchor.get_global_rect()
	p.position = Vector2(clampf(r.position.x, 6, get_viewport().get_visible_rect().size.x - 260), r.position.y + r.size.y + 4)


# ---- send an item
func open_gift(id: int) -> void:
	var r := Net.remote(id)
	if r == null:
		return
	_gift_sel = ""
	_gift["to"] = id
	_fill_gift()
	_gift.panel.show()
	_gift.panel.move_to_front()


func _fill_gift() -> void:
	var to: int = int(_gift.get("to", 0))
	var r := Net.remote(to)
	var body: VBoxContainer = _gift.body
	_clear(body)
	if r == null:
		_gift.panel.hide()
		return
	(_gift.title as Label).text = tr("Send an item to %s") % String(r.info.get("name", "?"))
	body.add_child(_label("Pick an item from your bag (equipped gear can't be sent).", 12, INK_L))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(360, 200)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	sc.add_child(grid)
	var ids := Game.inventory.keys()
	ids.sort()
	for id in ids:
		if Game.count(id) <= 0:
			continue
		var b := _slot(50)
		b.icon = Items.icon(id)
		b.tooltip_text = _item_tip(id)
		_count_label(b, str(Game.count(id)))
		if id == _gift_sel:
			b.add_theme_stylebox_override("normal", _sb(Color(GOLD, 0.25), GOLD, 2, 6, 2))
		b.pressed.connect(func() -> void:
			_gift_sel = id
			_fill_gift())
		grid.add_child(b)
	if ids.is_empty():
		body.add_child(_label("Your bag is empty.", 12, Color(1.0, 0.6, 0.45)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	body.add_child(row)
	var sel := _label(Items.item_name(_gift_sel) if _gift_sel != "" else tr("No item selected"), 13, CREAM if _gift_sel != "" else INK_L, true)
	sel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel.clip_text = true
	row.add_child(sel)
	var qty := SpinBox.new()
	qty.min_value = 1
	qty.max_value = maxi(1, Game.count(_gift_sel)) if _gift_sel != "" else 1
	qty.value = 1
	qty.custom_minimum_size = Vector2(90, 0)
	qty.editable = _gift_sel != ""
	row.add_child(qty)
	var send := _button(tr("Send"), func() -> void:
		if _gift_sel != "" and Net.send_gift(to, _gift_sel, int(qty.value)):
			_gift_sel = ""
			_gift.panel.hide(), 90)
	_color_button(send, BTN_GREEN)
	send.disabled = _gift_sel == ""
	send.custom_minimum_size.y = 36
	row.add_child(send)
	_gift.panel.reset_size()


# ---- party invite prompt
func _on_invite(from_id: int, name: String, lv: int, job: String) -> void:
	_invite_from = from_id
	var body: VBoxContainer = _invite_box.body
	_clear(body)
	var t := _label(tr("%s (Lv %d %s) invites you to their party.") % [name, lv, _job_name(job)], 14, CREAM, true)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(320, 0)
	body.add_child(t)
	body.add_child(_label("Party members near your kills share EXP.", 12, INK_L))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_END
	body.add_child(row)
	var yes := _button(tr("Join"), func() -> void:
		Net.answer_invite(_invite_from, true)
		_invite_box.panel.hide(), 100)
	_color_button(yes, BTN_GREEN)
	var no := _button(tr("Decline"), func() -> void:
		Net.answer_invite(_invite_from, false)
		_invite_box.panel.hide(), 100)
	for b in [yes, no]:
		(b as Control).custom_minimum_size.y = 38
		row.add_child(b)
	Audio.play("ui_click", null, 0.0, 0.03)
	_invite_box.panel.show()
	_invite_box.panel.reset_size()
	var vp := get_viewport().get_visible_rect().size
	_invite_box.panel.position = Vector2(vp.x * 0.5 - _invite_box.panel.size.x * 0.5, vp.y * 0.3)
	_invite_box.panel.move_to_front()


# ---- party window, "Online players" tab
func _fill_online_party(list: VBoxContainer) -> void:
	if not Net.online:
		list.add_child(_label("Not connected to the online server.", 13, Color(1.0, 0.7, 0.5), true))
		return
	if Net.party_id != 0:
		list.add_child(_label(tr("Online party: %d / %d") % [Net.party_members.size(), Net.PARTY_MAX], 13, TITLE, true))
		for m in Net.party_members:
			var id: int = int(m.id)
			var me := id == Net.my_id
			var r := Net.remote(id)
			var sub := (tr("You") if me else ("HP %d%%" % r.hp_pct if r else "")) + ("   ·   " + tr("Leader") if id == Net.party_leader else "")
			var right := HBoxContainer.new()
			right.add_theme_constant_override("separation", 6)
			if me:
				var lb := _button(tr("Leave party"), func() -> void: Net.leave_party(), 0)
				_color_button(lb, Color(0.55, 0.2, 0.18))
				right.add_child(lb)
			else:
				right.add_child(_button(tr("Profile"), func() -> void: open_player_profile(id), 0))
				if Net.party_leader == Net.my_id:
					var kb := _button(tr("Remove"), func() -> void: Net.kick(id), 0)
					_color_button(kb, Color(0.55, 0.2, 0.18))
					right.add_child(kb)
			list.add_child(_online_card(String(m.name), String(m.job), int(m.lv), sub, right, r))
	var others := []
	for r in Net.remotes():
		if not Net.in_party(r.id):
			others.append(r)
	list.add_child(_label(tr("Players online: %d") % (Net.remotes().size() + 1), 13, TITLE, true))
	if others.is_empty():
		list.add_child(_label("Nobody else is online right now. Invite friends to play together!", 12, INK_L))
	for r in others:
		var id: int = r.id
		var right := HBoxContainer.new()
		right.add_theme_constant_override("separation", 6)
		right.add_child(_button(tr("Profile"), func() -> void: open_player_profile(id), 0))
		var ib := _button(tr("Invite"), func() -> void: Net.invite(id), 0)
		_color_button(ib, BTN_GREEN)
		ib.disabled = Net.party_members.size() >= Net.PARTY_MAX
		right.add_child(ib)
		list.add_child(_online_card(String(r.info.get("name", "?")), String(r.info.get("job", "")), int(r.info.get("lv", 1)), "HP %d%%" % r.hp_pct, right, r))


func _online_card(nm: String, job: String, lv: int, sub: String, right: Control, r: RemotePlayer) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.1), 1, 6, 8))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	card.add_child(h)
	var fr := _round_frame(48, Color(0.16, 0.2, 0.28), GOLD_D, 2)
	fr.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var face := TextureRect.new()
	face.texture = _online_face(r) if r else _my_face()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.custom_minimum_size = Vector2(44, 44)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.add_child(face)
	h.add_child(fr)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_label("%s   Lv %d" % [nm, lv], 14, CREAM, true))
	v.add_child(_label(_job_name(job), 12, ACCENT))
	if sub != "":
		v.add_child(_label(sub, 11, INK_L))
	h.add_child(v)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(right)
	return card


var _face_vps := {}


func _online_face(r: RemotePlayer) -> Texture2D:
	var key := "%d|%s" % [r.id, var_to_str(r.model.appearance if r.model else {}).md5_text()]
	if not _face_vps.has(key):
		_face_vps[key] = Portrait.make(self, Vector2i(96, 96), "avatar", r.model.appearance if r.model else {}, "head", false)
	return (_face_vps[key] as SubViewport).get_texture()


func _my_face() -> Texture2D:
	if not _face_vps.has("me"):
		_face_vps["me"] = Portrait.make(self, Vector2i(96, 96), "player", null, "head", false)
	return (_face_vps["me"] as SubViewport).get_texture()


# ---- HUD party frame: online party members under the companions
func _add_online_frames() -> void:
	_online_bars.clear()
	for m in Net.party_members:
		var id: int = int(m.id)
		if id == Net.my_id:
			continue
		var r := Net.remote(id)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", _pixel_box(Color(0.35, 0.9, 0.4), 2, 0.0, 6))
		p.custom_minimum_size = Vector2(200, 0)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				open_player_profile(id))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		p.add_child(h)
		if r:
			var face := TextureRect.new()
			face.texture = _online_face(r)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.custom_minimum_size = Vector2(34, 34)
			face.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(face)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl := _label("★ %s  ·  Lv %d" % [String(m.name), int(m.lv)], 11, Color(0.7, 1.0, 0.7), true)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(nl)
		var hb := _bar(Color(0.35, 0.85, 0.4), 11)
		hb.box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(hb.box)
		h.add_child(v)
		_party_frame.add_child(p)
		_online_bars.append([id, hb.bar, hb.label])
	_update_online_bars()


func _update_online_bars() -> void:
	for row in _online_bars:
		var r := Net.remote(int(row[0]))
		var bar: ProgressBar = row[1]
		bar.max_value = 100
		bar.value = r.hp_pct if r else 0
		(row[2] as Label).text = ("%d%%" % r.hp_pct) if r else tr("Away")


var _fashion_vendor_name := ""
var _fashion_gallery: Node

func _fashion_gallery_view() -> Node:
	if not is_instance_valid(_fashion_gallery):
		_fashion_gallery = load("res://scripts/ui/fashion_gallery.gd").new()
		_root.add_child(_fashion_gallery)
		_fashion_gallery.setup(self)
	return _fashion_gallery

func _open_mage_fashion(_page := 0) -> void:
	_dialog.panel.hide()
	_fashion_gallery_view().open()

func _fashion_detail(id: String, _page := 0) -> void:
	_fashion_gallery_view().show_detail(id)


# ================================================================== phones / tablets
## Touch device? (?mobile=1 / ?mobile=0 in the page address forces it either way.)
func _detect_mobile() -> bool:
	if OS.get_environment("BR_MOBILE") != "":
		_mobile_scale = _scale_for_short_side(float(OS.get_environment("BR_CSS_SHORT")) if OS.get_environment("BR_CSS_SHORT") != "" else 390.0)
		return OS.get_environment("BR_MOBILE") == "1"
	if OS.get_name() == "Web":
		var js := """(function(){var q='';try{q+=location.search||'';}catch(e){}
try{if(window.parent&&window.parent!==window)q+=window.parent.location.search||'';}catch(e){}
var s=Math.min(screen.width||0,screen.height||0)||Math.min(innerWidth,innerHeight);
if(/[?&]mobile=0/.test(q))return '0,'+s;
if(/[?&]mobile=1/.test(q))return '1,'+s;
var touch=(navigator.maxTouchPoints||0)>0||('ontouchstart' in window);
var coarse=!!(window.matchMedia&&matchMedia('(pointer:coarse)').matches);
var ua=/Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent||'');
return ((touch&&coarse)||ua?'1,':'0,')+s;})()"""
		var r = JavaScriptBridge.eval(js, true)
		var parts := str(r).split(",")
		if parts.size() == 2:
			_mobile_scale = _scale_for_short_side(float(parts[1]))
			return parts[0] == "1"
		return false
	return OS.has_feature("mobile")


## Phones: keep the UI about 1.2x the size it would be on a 720p desktop window,
## measured against the short side of the screen in CSS pixels.
func _scale_for_short_side(css_short: float) -> float:
	if css_short <= 0.0:
		return 1.0
	return clampf(720.0 / (css_short * 1.2), 1.0, 1.75)


func _setup_mobile() -> void:
	_mobile_hud = Control.new()
	_mobile_hud.set_script(preload("res://scripts/ui/mobile_hud.gd"))
	_root.add_child(_mobile_hud)
	_root.move_child(_mobile_hud, 0)        # behind every panel and window
	_mobile_hud.setup(self)
	_hot_panel.visible = false
	_chat_panel.visible = false
	_pills.visible = false
	# key-cap hints mean nothing without a keyboard
	for b in _menu.get_children():
		for k in b.get_children():
			if k is Label and k.text.length() <= 2 and k.text != "!":
				k.visible = false
	if _chat_input:
		_chat_input.placeholder_text = "แตะเพื่อพิมพ์แชท" if TranslationServer.get_locale().begins_with("th") else "Tap here to chat"


func _layout_mobile(vp: Vector2) -> void:
	_hot_panel.visible = false
	_pills.visible = false
	_mobile_hud.relayout(vp)
	# portrait panel a bit smaller so the 3D view breathes
	_info_panel.scale = Vector2.ONE
	_buff_row.position = Vector2(14, 10 + _sz(_info_panel).y + 6)
	_party_frame.position = Vector2(12, _buff_row.position.y + 30)
	# minimap a little smaller, clock + quest tracker tucked under it
	var ms := 0.78
	_map_panel.scale = Vector2(ms, ms)
	_map_panel.position = Vector2(vp.x - 176.0 * ms - 8.0, 4)
	var map_cx := _map_panel.position.x + 88.0 * ms
	var cw := maxf(_sz(_clock).x, 120.0)
	_clock.position = Vector2(map_cx - cw * 0.5, 4 + 192.0 * ms)
	_tracker.panel.position = Vector2(vp.x - _sz(_tracker.panel).x - 8, _clock.position.y + _sz(_clock).y + 6)
	if _tracker.panel.position.y + _sz(_tracker.panel).y > _mobile_hud.pad_top() - 6.0:
		# short screen: the quest list moves left of the minimap, under the menu
		var tx := _map_panel.position.x - _sz(_tracker.panel).x - 8
		var ir := _info_panel.get_global_rect()
		var ty := 70.0 if tx >= ir.end.x + 6.0 else ir.end.y + 6.0
		_tracker.panel.position = Vector2(tx, ty)
	# menu row between the portrait and the minimap (shrinks on narrow screens)
	var info_r := _info_panel.get_global_rect().end.x + 10.0
	var mw := _sz(_menu).x
	var room := _map_panel.position.x - 10.0 - info_r
	var s := clampf(room / mw, 0.62, 1.0)
	_menu.scale = Vector2(s, s)
	_menu.position = Vector2(_map_panel.position.x - 10.0 - mw * s, 10)
	_chat_panel.position = Vector2(10, vp.y - _sz(_chat_panel).y - 10)
	_cast_bar.position = Vector2(vp.x * 0.5 - 110, vp.y - 118)
	_dialog.panel.position = Vector2(clampf(vp.x * 0.5 - _sz(_dialog.panel).x * 0.5, 8.0, maxf(8.0, vp.x - _sz(_dialog.panel).x - 8.0)), maxf(8.0, vp.y - _sz(_dialog.panel).y - 16))
	_autoset.panel.position = Vector2(vp.x - _sz(_autoset.panel).x - 12, maxf(8.0, vp.y * 0.5 - _sz(_autoset.panel).y * 0.5))
	_fit_windows()


## Windows taller/wider than a phone screen are scaled down to fit, and any
## window pushed off-screen is pulled back in.
func _fit_windows() -> void:
	if not _mobile:
		return
	var vp := get_viewport().get_visible_rect().size
	for w in _popups:
		if not w.visible or w.get_parent() != _root:
			continue
		var sz := _sz(w)
		var s := minf(1.0, minf((vp.y - 12.0) / maxf(1.0, sz.y), (vp.x - 12.0) / maxf(1.0, sz.x)))
		if not is_equal_approx(w.scale.x, s):
			w.scale = Vector2(s, s)
		var real := sz * s
		w.position = w.position.clamp(Vector2(4, 4), (vp - real - Vector2(4, 4)).max(Vector2(4, 4)))


# ================================================================== stat change popups
## Equip / unequip, buffs, stat points ... anything that moves a number on the
## Character Card floats "ATK +12" (green, up) / "DEF -3" (red, down) next to
## the hero for a couple of seconds.
const STAT_WATCH := ["ATK", "DEF", "HIT", "FLEE", "CRIT", "ASPD", "MaxHP", "MaxSP", "STR", "AGI", "VIT", "INT", "DEX", "LUK"]
var _stat_snap := {}
var _stat_poll := 1.0
var _stat_fx: Array = []          # [{box, t}]
var _stat_slot := ""             # character the snapshot belongs to


func _stat_snapshot() -> Dictionary:
	var d := {"ATK": Game.atk(), "DEF": Game.def(), "HIT": Game.hit(), "FLEE": Game.flee(),
		"CRIT": snappedf(Game.crit_rate(), 0.1), "ASPD": Game.aspd(), "MaxHP": Game.max_hp(), "MaxSP": Game.max_sp()}
	for k in ["STR", "AGI", "VIT", "INT", "DEX", "LUK"]:
		d[k] = Game.st(k)
	return d


func _update_stat_popups(delta: float) -> void:
	_stat_poll -= delta
	if _stat_poll <= 0.0:
		_stat_poll = 0.25
		if Game.character_ready:
			var key := "%d:%s" % [Game.slot, Game.player_name]
			var now := _stat_snapshot()
			if _stat_snap.is_empty() or key != _stat_slot:
				_stat_snap = now
				_stat_slot = key
			else:
				var lines := []
				for k in STAT_WATCH:
					var dv = now[k] - _stat_snap.get(k, now[k])
					if absf(float(dv)) > 0.001:
						lines.append([k, dv])
				_stat_snap = now
				if not lines.is_empty():
					_show_stat_popup(lines)
	if _stat_fx.is_empty():
		return
	var p := get_tree().get_first_node_in_group("player") as Node3D
	var cam := get_viewport().get_camera_3d()
	var base := Vector2(get_viewport().get_visible_rect().size.x * 0.5 + 60, get_viewport().get_visible_rect().size.y * 0.4)
	if p and cam and not cam.is_position_behind(p.global_position):
		base = cam.unproject_position(p.global_position + Vector3(0, 2.2, 0)) + Vector2(44, 0)
	var y := 0.0
	for i in range(_stat_fx.size() - 1, -1, -1):
		var e: Dictionary = _stat_fx[i]
		e.t += delta
		var box: Control = e.box
		if e.t > 2.6:
			box.queue_free()
			_stat_fx.remove_at(i)
			continue
		var rise: float = minf(1.0, e.t / 0.35)
		box.modulate.a = minf(1.0, e.t / 0.15) * (1.0 - smoothstep(2.0, 2.6, e.t))
		box.position = (base + Vector2(8.0 * (1.0 - rise), -y - 26.0 * ease(minf(1.0, e.t / 2.6), 0.5) - box.size.y)).round()
		y += box.size.y + 4.0


func _show_stat_popup(lines: Array) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", -2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ln in lines.slice(0, 7):
		var k: String = ln[0]
		var dv = ln[1]
		var up: bool = dv > 0
		var txt: String
		if k == "CRIT":
			txt = "%s %s%.1f" % [k, "+" if up else "", dv]
		else:
			txt = "%s %s%d" % [k, "+" if up else "", int(dv)]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# small up / down chevron drawn as a polygon (no glyph needed in the font)
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(0, 9), Vector2(5, 3), Vector2(10, 9)]) if up else PackedVector2Array([Vector2(0, 4), Vector2(10, 4), Vector2(5, 10)])
		arrow.color = GOOD if up else BAD
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(11, 14)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(arrow)
		arrow.position = Vector2(0, 2)
		row.add_child(holder)
		var l := _outlined(_label(txt, 14, Color(0.62, 1.0, 0.55) if up else Color(1.0, 0.52, 0.45), true), Color(0.05, 0.05, 0.06), 5)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)
		box.add_child(row)
	_root.add_child(box)
	box.modulate.a = 0.0
	_stat_fx.append({"box": box, "t": 0.0})
	while _stat_fx.size() > 4:
		(_stat_fx.pop_front().box as Node).queue_free()


# ================================================================== auto quest
## Choices the quest auto may confirm on its own (story / side quest flow only).
const QAUTO_PRESS := ["Accept", "Complete", "Close", "OK", "Claim", "Claim reward", "Continue"]
var _quest_auto := false
var _qauto_btn: Button
var _qauto_wait := 0.0
var _qauto_press := -1.0
var _dialog_choices: Array = []


func _set_quest_auto(on: bool) -> void:
	_quest_auto = on
	_color_button(_qauto_btn, BTN_GREEN if on else PARCH_D)
	_qauto_wait = 0.2
	if on:
		add_message("ออโต้เควส: เดินทำเควสทุกเควสให้อัตโนมัติ" if TranslationServer.get_locale().begins_with("th") else "Auto Quest on: following every quest automatically.", Color(0.6, 1.0, 0.6))
	else:
		_qauto_press = -1.0


func _update_quest_auto(delta: float) -> void:
	if not _quest_auto:
		return
	# confirm quest dialogs after a short, visible countdown
	if _dialog.panel.visible:
		if _qauto_press >= 0.0 and _dialog_buttons.get_child_count() > 0:
			_qauto_press -= delta
			var b := _dialog_buttons.get_child(0) as Button
			var base_txt: String = tr(String(_dialog_choices[0])) if not _dialog_choices.is_empty() else b.text
			b.text = "%s (%d)" % [base_txt, ceili(maxf(0.0, _qauto_press))]
			if _qauto_press <= 0.0:
				_qauto_press = -1.0
				b.text = base_txt
				b.pressed.emit()
				_qauto_wait = 1.2
		return
	var p := get_tree().get_first_node_in_group("player")
	if p == null or not p.is_alive():
		return
	# busy: walking, talking, fighting or hunting for the quest
	var busy: bool = p._has_target or p.interact_target != null or (p.attack_target != null and is_instance_valid(p.attack_target)) \
			or (Game.auto_on and Game.auto_quest_target != "") or p.is_casting()
	if busy:
		_qauto_wait = maxf(_qauto_wait, 1.0)
		return
	_qauto_wait -= delta
	if _qauto_wait > 0.0:
		return
	_qauto_wait = 2.5
	for e in _quest_entries():
		if e.size() > 6 and not e[5] and not (e[6] as Dictionary).is_empty():
			_quest_go(e[6])
			return
	# nothing left to follow
	_qauto_btn.button_pressed = false


func _status_fit_card() -> void:
	await get_tree().process_frame
	_status_fit_queued = false
	if not is_instance_valid(_status.panel) or not _status.panel.visible: return
	_status.panel.size = _status.panel.get_combined_minimum_size()
	if _mobile:
		_fit_windows()
	elif has_method("_pc_fit_popup"):
		call("_pc_fit_popup", _status.panel, "Character Card")
	var key := str(Game.appearance) + str(Game.equip) + Game.job + Game.worn_fashion()
	if key == _status_model_key: return
	var holder := _status_vp.get_node_or_null("Holder") as Node3D
	var camera := _status_vp.get_node_or_null("Cam") as Camera3D
	if holder == null or camera == null: return
	var bounds := AABB()
	var first := true
	for node in holder.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null or not mesh.is_visible_in_tree(): continue
		var box: AABB = (holder.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if first: return
	var center := Vector3(0, bounds.get_center().y, 0)
	var radius := 0.1
	for x in [bounds.position.x, bounds.end.x]:
		for z in [bounds.position.z, bounds.end.z]: radius = maxf(radius, Vector2(x,z).length())
	var projection := camera.get_camera_projection()
	var half_x := atan(1.0 / maxf(absf(projection.x.x), 0.01))
	var half_y := atan(1.0 / maxf(absf(projection.y.y), 0.01))
	var distance := maxf(radius / sin(half_x), bounds.size.y * 0.5 / tan(half_y) + radius) * 1.08
	camera.position = center + Vector3(0, 0.1, maxf(distance, 2.5))
	camera.look_at(center)
	_status_model_key = key
	_status_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _status_spin else SubViewport.UPDATE_ONCE
