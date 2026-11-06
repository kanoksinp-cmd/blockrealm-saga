extends Control
## Touch controls for phones / tablets.
##
## Sits at the very back of the HUD root (behind every window) and owns the
## "world" part of the screen:
##   * left thumb  – floating virtual joystick (camera-relative movement)
##   * right side  – tap = walk / attack / talk / pick up (same as a click),
##                   hold = keep walking toward the finger, drag = turn camera,
##                   two fingers = pinch zoom
##   * action pad  – big attack/interact button, 4 hotbar skills (4 pages),
##                   2 quick items, AUTO, chat toggle with unread badge
## Every button reads raw InputEventScreenTouch so several fingers work at once
## (the browser only turns the first finger into a mouse).

const GOLD := Color(0.96, 0.78, 0.36)
const GOLD_D := Color(0.62, 0.45, 0.16)
const INK := Color(0.96, 0.93, 0.85)
const BG := Color(0.05, 0.055, 0.075, 0.62)
const BG_PRESS := Color(0.24, 0.19, 0.09, 0.85)
const JOY_R := 62.0          # joystick travel radius
const TAP_MOVE := 14.0       # px a finger may wander and still count as a tap
var tap_time := 280          # ms
var hold_time := 380         # ms before a still finger becomes "walk here"

var ui                        # ro_ui.gd (HUD)
var _font: Font
var _font_b: Font

var _touches := {}            # index -> {start, pos, t0, mode, moved}
var _joy_idx := -1
var _joy_base := Vector2.ZERO
var _joy_knob := Vector2.ZERO
var _joy_t := 0.0
var _joy_rest := Vector2.ZERO
var _hold_t := 0.0
var _pinch_d := 0.0

var _pad: Control             # action pad holder (children are RoundButtons)
var _attack: RoundButton
var _skill_btns: Array[RoundButton] = []
var _item_btns: Array[RoundButton] = []
var _page_btn: RoundButton
var _auto: RoundButton
var _chat_btn: RoundButton
var _page := 0
var _unread := 0
var _feed: VBoxContainer
var _feed_items := []         # [label, time_left]
var _drops := []
var _drop_script: Script
var _ui_blocked := false

func cancel_gestures() -> void:
	_touches.clear()
	_joy_idx = -1
	_joy_knob = Vector2.ZERO
	_pinch_d = 0.0
	_hold_t = 0.0
	_sc = null
	_sc_idx = -1
	_sc_active = false
	_sc_vel = Vector2.ZERO
	_fling_sc = null
	_fling_v = Vector2.ZERO
	var p := _player()
	if p: p.cancel_walk()
	for b in _skill_btns + _item_btns + [_attack, _auto, _chat_btn, _page_btn]:
		if b:
			b._down = -1
			b._press = 0.0
	queue_redraw()

func set_ui_blocked(blocked: bool) -> void:
	if _ui_blocked == blocked: return
	_ui_blocked = blocked
	cancel_gestures()
	_pad.visible = not blocked
	_feed.visible = false # The shared HUD toast queue handles messages.
	mouse_filter = Control.MOUSE_FILTER_IGNORE if blocked else Control.MOUSE_FILTER_STOP
	queue_redraw()


# ================================================================== round touch button
class RoundButton extends Control:
	signal tapped
	var radius := 30.0
	var icon: Texture2D
	var text := ""
	var sub := ""                # small number bottom-right (SP cost / count)
	var badge := ""
	var glyph := ""              # vector icon drawn when no texture: sword, chat, auto, page
	var accent := Color(0.96, 0.78, 0.36)
	var active := false          # lit ring (AUTO on)
	var cd := 0.0                # 0..1 cooldown fraction left
	var cd_text := ""
	var dim := false
	var font: Font
	var font_b: Font
	var _down := -1
	var _press := 0.0

	func _init(r: float) -> void:
		radius = r
		custom_minimum_size = Vector2(r, r) * 2.0
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		pivot_offset = size * 0.5

	func center() -> Vector2:
		return position + size * 0.5

	func place(c: Vector2) -> void:
		position = c - size * 0.5

	func _has_point(p: Vector2) -> bool:
		return p.distance_to(size * 0.5) <= radius + 8.0   # a little extra for thumbs

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventScreenTouch:
			if e.pressed and _down == -1:
				_down = e.index
				_press = 1.0
				queue_redraw()
				tapped.emit()
			elif not e.pressed and e.index == _down:
				_down = -1
				queue_redraw()
			accept_event()
		elif e is InputEventMouseButton:
			# the browser's copy of the first finger: already handled as a touch
			if e.device != InputEvent.DEVICE_ID_EMULATION and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				_press = 1.0
				tapped.emit()
			accept_event()
		elif e is InputEventScreenDrag or e is InputEventMouseMotion:
			accept_event()

	func _process(delta: float) -> void:
		if _press > 0.0 and _down == -1:
			_press = maxf(0.0, _press - delta * 6.0)
			queue_redraw()
		var s := 1.0 - 0.08 * (_press if _down == -1 else 1.0)
		scale = Vector2(s, s)

	func _draw() -> void:
		var c := size * 0.5
		var r := radius
		draw_circle(c + Vector2(0, 2), r, Color(0, 0, 0, 0.28))
		draw_circle(c, r, Color(0.24, 0.19, 0.09, 0.85) if _down != -1 else Color(0.05, 0.055, 0.075, 0.62))
		if active:
			draw_circle(c, r, Color(accent, 0.22))
		draw_arc(c, r - 1.0, 0, TAU, 48, Color(accent, 0.95 if (active or _down != -1) else 0.55), 2.5 if active else 1.6, true)
		draw_arc(c, r - 4.0, 0, TAU, 48, Color(1, 1, 1, 0.07), 1.0, true)
		if icon:
			var ir := r * 1.15
			draw_texture_rect(icon, Rect2(c - Vector2(ir, ir) * 0.5, Vector2(ir, ir)), false, Color(1, 1, 1, 0.45 if dim else 1.0))
		elif glyph != "":
			_draw_glyph(c, r)
		if text != "" and font_b:
			var fs := maxi(12, int(r * 0.42)) if glyph == "" and icon == null else maxi(10, int(r * 0.3))
			var tw := font_b.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var ty := c.y + fs * 0.35 if glyph == "" and icon == null else c.y + r * 0.62
			draw_string_outline(font_b, Vector2(c.x - tw * 0.5, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.85))
			draw_string(font_b, Vector2(c.x - tw * 0.5, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.95, 0.8))
		if cd > 0.0:
			var pts := PackedVector2Array([c])
			var a0 := -PI * 0.5
			var steps := 32
			for i in steps + 1:
				var a := a0 + TAU * cd * float(i) / steps
				pts.append(c + Vector2(cos(a), sin(a)) * (r - 2.0))
			if pts.size() >= 3:
				draw_colored_polygon(pts, Color(0.01, 0.02, 0.05, 0.68))
			if cd_text != "" and font_b:
				var fs2 := int(r * 0.5)
				var w2 := font_b.get_string_size(cd_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
				draw_string_outline(font_b, Vector2(c.x - w2 * 0.5, c.y + fs2 * 0.36), cd_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, 4, Color(0, 0, 0))
				draw_string(font_b, Vector2(c.x - w2 * 0.5, c.y + fs2 * 0.36), cd_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(1, 0.92, 0.6))
		if sub != "" and font_b:
			var fs3 := maxi(10, int(r * 0.34))
			var w3 := font_b.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs3).x
			var p3 := c + Vector2(r * 0.72 - w3 * 0.5, r * 0.78)
			draw_string_outline(font_b, p3, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs3, 4, Color(0, 0, 0, 0.9))
			draw_string(font_b, p3, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, fs3, Color(0.75, 0.88, 1.0))
		if badge != "" and font_b:
			var bc := c + Vector2(r * 0.72, -r * 0.72)
			draw_circle(bc, 9.0, Color(0.86, 0.2, 0.17))
			draw_arc(bc, 9.0, 0, TAU, 20, Color(1, 0.65, 0.55), 1.2, true)
			var w4 := font_b.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font_b, bc + Vector2(-w4 * 0.5, 4), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	func _draw_glyph(c: Vector2, r: float) -> void:
		var col := Color(1, 0.94, 0.78)
		var w := maxf(2.0, r * 0.09)
		match glyph:
			"sword":
				# two crossed blades
				for sgn in [-1.0, 1.0]:
					var d := Vector2(sgn, -1).normalized()
					var tip: Vector2 = c + d * r * 0.55
					var hilt: Vector2 = c - d * r * 0.32
					var n := Vector2(-d.y, d.x)
					draw_colored_polygon(PackedVector2Array([tip, hilt + n * r * 0.07, hilt - n * r * 0.07]), Color(0.92, 0.94, 1.0))
					draw_line(tip, hilt, Color(0.55, 0.6, 0.72), 1.0, true)
					draw_line(hilt + n * r * 0.17, hilt - n * r * 0.17, GOLD_C, w * 1.3, true)
					draw_line(hilt, hilt - d * r * 0.2, Color(0.45, 0.28, 0.12), w * 1.4, true)
			"chat":
				var rr := Rect2(c - Vector2(r * 0.42, r * 0.32), Vector2(r * 0.84, r * 0.56))
				draw_rect(rr, col, false, w)
				draw_colored_polygon(PackedVector2Array([rr.position + Vector2(r * 0.18, rr.size.y), rr.position + Vector2(r * 0.42, rr.size.y), rr.position + Vector2(r * 0.12, rr.size.y + r * 0.22)]), col)
				for i in 3:
					draw_circle(rr.get_center() + Vector2((i - 1) * r * 0.22, 0), w * 0.7, col)
			"page":
				for i in 2:
					var o := Vector2(i * r * 0.16 - r * 0.08, -i * r * 0.16 + r * 0.08)
					draw_rect(Rect2(c - Vector2(r * 0.3, r * 0.3) + o, Vector2(r * 0.6, r * 0.6)), col if i == 1 else Color(col, 0.5), false, w)
			"talk", "quest":
				var bc := Color(1, 0.94, 0.78) if glyph == "talk" else Color(1.0, 0.86, 0.35)
				var rr := Rect2(c - Vector2(r * 0.42, r * 0.5), Vector2(r * 0.84, r * 0.56))
				draw_rect(rr, Color(bc, 0.22), true)
				draw_rect(rr, bc, false, w)
				draw_colored_polygon(PackedVector2Array([rr.position + Vector2(r * 0.16, rr.size.y), rr.position + Vector2(r * 0.4, rr.size.y), rr.position + Vector2(r * 0.1, rr.size.y + r * 0.22)]), bc)
				if glyph == "talk":
					for i in 3:
						draw_circle(rr.get_center() + Vector2((i - 1) * r * 0.22, 0), w * 0.8, bc)
				else:
					var cx := rr.get_center().x
					draw_line(Vector2(cx, rr.position.y + r * 0.1), Vector2(cx, rr.end.y - r * 0.2), bc, w * 1.6, true)
					draw_circle(Vector2(cx, rr.end.y - r * 0.09), w * 0.9, bc)
			"loot":
				var bag := Rect2(c - Vector2(r * 0.34, r * 0.3), Vector2(r * 0.68, r * 0.5))
				draw_rect(bag, Color(0.75, 0.55, 0.3), true)
				draw_rect(bag, col, false, w)
				draw_arc(c + Vector2(0, -r * 0.3), r * 0.18, PI, TAU, 12, col, w, true)
				draw_circle(c + Vector2(0, -r * 0.05), w * 1.1, Color(1.0, 0.85, 0.3))
			"plus":
				var cc := Color(1, 1, 1, 0.28)
				draw_line(c - Vector2(r * 0.28, 0), c + Vector2(r * 0.28, 0), cc, w, true)
				draw_line(c - Vector2(0, r * 0.28), c + Vector2(0, r * 0.28), cc, w, true)
			"menu":
				for i in 3:
					var y := c.y + (i - 1) * r * 0.3
					draw_line(Vector2(c.x - r * 0.4, y), Vector2(c.x + r * 0.4, y), col, w, true)

	const GOLD_C := Color(0.96, 0.78, 0.36)


# ================================================================== setup
func setup(hud) -> void:
	ui = hud
	name = "MobileHUD"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = load("res://assets/fonts/ui_font.tres")
	_font_b = load("res://assets/fonts/ui_font_bold.tres")
	if ResourceLoader.exists("res://scripts/game/drop_item.gd"):
		_drop_script = load("res://scripts/game/drop_item.gd")
	get_tree().node_added.connect(_on_node_added)

	_pad = Control.new()
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_pad)

	_attack = _make(46.0)
	_attack.glyph = "sword"
	_attack.accent = Color(1.0, 0.62, 0.3)
	_attack.tapped.connect(_on_attack)
	for i in 4:
		var b := _make(28.0)
		b.tapped.connect(_on_skill.bind(i))
		_skill_btns.append(b)
	for i in 2:
		var b := _make(23.0)
		b.tapped.connect(_on_item.bind(i))
		_item_btns.append(b)
	_page_btn = _make(19.0)
	_page_btn.tapped.connect(func() -> void:
		_page = (_page + 1) % 4
		_buzz(8)
		_refresh_slots())
	_auto = _make(25.0)
	_auto.text = "AUTO"
	_auto.accent = Color(0.45, 1.0, 0.55)
	_auto.tapped.connect(func() -> void:
		var p := _player()
		if p:
			p.toggle_auto()
			_buzz(12))
	_chat_btn = _make(21.0)
	_chat_btn.glyph = "chat"
	_chat_btn.tapped.connect(_toggle_chat)

	_feed = VBoxContainer.new()
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feed.add_theme_constant_override("separation", 2)
	_feed.alignment = BoxContainer.ALIGNMENT_END
	add_child(_feed)

	Game.message.connect(_on_message)
	Game.changed.connect(_refresh_slots)
	Game.inventory_changed.connect(_refresh_slots)
	Game.skills_changed.connect(_refresh_slots)
	_refresh_slots()


func _make(r: float) -> RoundButton:
	var b := RoundButton.new(r)
	b.font = _font
	b.font_b = _font_b
	_pad.add_child(b)
	return b


func _on_node_added(n: Node) -> void:
	if _drop_script and n.get_script() == _drop_script:
		_drops.append(n)


func _player() -> Node:
	return get_tree().get_first_node_in_group("player")


func _rig() -> Node:
	return get_tree().get_first_node_in_group("camera_rig")


func _buzz(ms: int) -> void:
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("try{navigator.vibrate&&navigator.vibrate(%d)}catch(e){}" % ms)


# ================================================================== layout
func relayout(vp: Vector2) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var c := Vector2(vp.x - 74, vp.y - 72)
	_attack.place(c)
	var angles := [180.0, 213.0, 246.0, 279.0]
	for i in 4:
		var a := deg_to_rad(angles[i])
		_skill_btns[i].place(c + Vector2(cos(a), sin(a)) * 98.0)
	_page_btn.place(c + Vector2(-150, 44))
	_item_btns[0].place(c + Vector2(-208, 34))
	_item_btns[1].place(c + Vector2(-262, 34))
	_auto.place(c + Vector2(-162, -94))
	_place_chat_btn()
	_joy_rest = Vector2(118, vp.y - 108)
	var fw := clampf(c.x - 200.0 - 214.0, 200.0, 440.0)
	_feed.position = Vector2(214, vp.y - 72 - 150)
	_feed.size = Vector2(fw, 150)
	for it in _feed_items:
		(it[0] as Label).custom_minimum_size.x = _feed.size.x
	queue_redraw()


## Top edge of the action pad (so other HUD parts can stay above it).
func pad_top() -> float:
	var top := 1e9
	for b in [_attack, _page_btn, _auto] + _skill_btns:
		top = minf(top, (b as Control).position.y)
	return top


# ================================================================== hotbar mirror
func _refresh_slots() -> void:
	if _skill_btns.is_empty():
		return
	for i in 4:
		var idx := _page * 4 + i
		var id: String = Game.hotbar[idx] if idx < Game.hotbar.size() else ""
		var b := _skill_btns[i]
		b.icon = ui._slot_icon(id) if id != "" else null
		b.glyph = "" if id != "" else "plus"
		b.sub = ""
		b.text = "" if id != "" else ""
		if id != "" and Items.DB.has(id):
			b.sub = str(Game.count(id))
		elif id != "":
			b.sub = str(SkillDB.sp_cost(id, Game.slv(id)))
		b.queue_redraw()
	_page_btn.text = "%d/4" % (_page + 1)
	_page_btn.queue_redraw()
	var items := _quick_items()
	for i in 2:
		var b := _item_btns[i]
		var id: String = items[i] if i < items.size() else ""
		b.icon = Items.icon(id) if id != "" else null
		b.sub = str(Game.count(id)) if id != "" else ""
		b.dim = id != "" and Game.count(id) <= 0
		b.visible = id != ""
		b.queue_redraw()
	_auto.active = Game.auto_on
	_auto.queue_redraw()


## Item ids on the hotbar (in slot order) for the two quick-use buttons.
func _quick_items() -> Array:
	var out := []
	for id in Game.hotbar:
		if id != "" and Items.DB.has(id) and not out.has(id):
			out.append(id)
	if out.is_empty():
		for id in ["potion_red", "potion_blue"]:
			if Game.count(id) > 0:
				out.append(id)
	return out


func _hot_index_for_item(id: String) -> int:
	return Game.hotbar.find(id)


func _on_skill(i: int) -> void:
	var idx := _page * 4 + i
	if idx < Game.HOTBAR_SIZE and Game.hotbar[idx] != "":
		_buzz(10)
		ui.activate_hotkey(idx)
	else:
		# empty slot: show where skills come from
		ui.toggle(ui._skills.panel)


func _on_item(i: int) -> void:
	var items := _quick_items()
	if i < items.size():
		var p := _player()
		if p and p.is_alive():
			_buzz(10)
			Game.use_item(items[i])


# ================================================================== attack / interact
## What the big action button does right now (also drives its icon):
## loot close by > NPC / gathering spot close by > current target > nearest monster.
func _context() -> Dictionary:
	var p := _player()
	if p == null:
		return {"mode": "attack"}
	var here: Vector3 = p.global_position
	_drops = _drops.filter(func(x) -> bool: return is_instance_valid(x))
	var best: Node3D = null
	var bd := 3.0
	for d in _drops:
		if (d as Node3D).is_inside_tree() and (d as Node3D).is_visible_in_tree():
			var dist := here.distance_to((d as Node3D).global_position)
			if dist < bd:
				bd = dist
				best = d
	if best:
		return {"mode": "loot", "node": best}
	var npc: Node3D = null
	var nd := 4.5
	for g in ["npc", "gather_node"]:
		for n in get_tree().get_nodes_in_group(g):
			var n3 := n as Node3D
			if n3 == null or not n3.is_visible_in_tree():
				continue
			var dist := Vector2(n3.global_position.x - here.x, n3.global_position.z - here.z).length()
			if dist < nd:
				nd = dist
				npc = n3
	if npc:
		var quest := false
		if npc.is_in_group("npc"):
			var mk = npc.get("_marker")
			quest = mk is Label3D and String((mk as Label3D).text) != ""
		return {"mode": "quest" if quest else ("talk" if npc.is_in_group("npc") else "gather"), "node": npc}
	return {"mode": "attack"}


func _on_attack() -> void:
	var p := _player()
	if p == null or not p.is_alive():
		return
	_buzz(14)
	var ctx := _context()
	if ctx.has("node"):
		# talk_to walks over and talks / picks up / starts gathering
		p.attack_target = null
		p.talk_to(ctx.node)
		return
	var here: Vector3 = p.global_position
	# keep hitting what we already fight
	if p.attack_target and is_instance_valid(p.attack_target) and _alive(p.attack_target) \
			and here.distance_to(p.attack_target.global_position) < 18.0:
		return
	var m = p._nearest_monster(14.0, here)
	if m:
		p.interact_target = null
		p.attack_target = m
		return
	Game.message.emit("ไม่มีมอนสเตอร์อยู่ใกล้ ๆ" if TranslationServer.get_locale().begins_with("th") else "No monster nearby", Color(0.8, 0.8, 0.8))


var _ctx_t := 0.0
var _ctx_mode := "attack"


func _update_context(delta: float) -> void:
	_ctx_t -= delta
	if _ctx_t > 0.0:
		return
	_ctx_t = 0.15
	var mode: String = _context().mode
	if mode == _ctx_mode:
		return
	_ctx_mode = mode
	var th := TranslationServer.get_locale().begins_with("th")
	match mode:
		"quest":
			_attack.glyph = "quest"
			_attack.text = "เควส" if th else "Quest"
			_attack.accent = Color(1.0, 0.85, 0.3)
		"talk":
			_attack.glyph = "talk"
			_attack.text = "คุย" if th else "Talk"
			_attack.accent = Color(0.55, 0.85, 1.0)
		"loot":
			_attack.glyph = "loot"
			_attack.text = "เก็บ" if th else "Pick up"
			_attack.accent = Color(0.6, 1.0, 0.55)
		"gather":
			_attack.glyph = "loot"
			_attack.text = "เก็บ" if th else "Gather"
			_attack.accent = Color(0.6, 1.0, 0.55)
		_:
			_attack.glyph = "sword"
			_attack.text = ""
			_attack.accent = Color(1.0, 0.62, 0.3)
	_attack.queue_redraw()


func _alive(m) -> bool:
	if m.has_method("is_alive"):
		return m.is_alive()
	var hp = m.get("hp")
	return hp == null or hp > 0


# ================================================================== chat + message feed
func _toggle_chat() -> void:
	_buzz(8)
	var cp: Control = ui._chat_panel
	cp.visible = not cp.visible
	if cp.visible:
		cp.move_to_front()
		_unread = 0
		_chat_btn.badge = ""
		_feed.visible = false
	else:
		_feed.visible = true
		ui._chat_input.release_focus()
	_place_chat_btn.call_deferred()
	_chat_btn.queue_redraw()


## Closed: bottom-left next to the stick. Open: just right of the chat box, so it
## is never hidden under it and works as the "close" button.
func _place_chat_btn() -> void:
	var cp: Control = ui._chat_panel
	if cp.visible:
		var r := cp.get_global_rect()
		_chat_btn.place(Vector2(r.end.x + 28.0, r.end.y - 24.0))
	else:
		_chat_btn.place(Vector2(232, size.y - 32))



func _on_message(_text: String, _color := Color(1, 1, 1)) -> void:
	if ui._chat_panel.visible: return
	_unread += 1
	_chat_btn.badge = str(_unread) if _unread < 100 else "99+"
	_chat_btn.queue_redraw()

# ================================================================== touches on the world
func _in_joy_zone(p: Vector2) -> bool:
	var vp := size
	return p.x < vp.x * 0.42 and p.y > vp.y * 0.38


func _gui_input(e: InputEvent) -> void:
	if _ui_blocked: return
	if e is InputEventScreenTouch:
		if e.pressed:
			var mode := "world"
			if _joy_idx == -1 and _in_joy_zone(e.position) and not ui._chat_panel.visible:
				mode = "joy"
				_joy_idx = e.index
				_joy_base = e.position
				_joy_knob = Vector2.ZERO
				_joy_t = 0.0
				var p := _player()
				if p:
					p.attack_target = null
					p.interact_target = null
			_touches[e.index] = {"start": e.position, "pos": e.position, "t0": Time.get_ticks_msec(), "mode": mode, "moved": false}
			if _world_count() == 2:
				_pinch_d = _pinch_dist()
		else:
			var t = _touches.get(e.index)
			_touches.erase(e.index)
			if t != null:
				if t.mode == "joy":
					_joy_idx = -1
					_joy_knob = Vector2.ZERO
					var p := _player()
					if p:
						p.cancel_walk()
				elif not t.moved and Time.get_ticks_msec() - int(t.t0) < tap_time and _world_count() == 0:
					_tap(e.position)
		queue_redraw()
		accept_event()
	elif e is InputEventScreenDrag:
		var t = _touches.get(e.index)
		if t == null:
			accept_event()
			return
		t.pos = e.position
		if t.mode == "joy":
			var off: Vector2 = e.position - _joy_base
			if off.length() > JOY_R * 1.6:
				# finger ran far away: drag the base along (feels like a real stick)
				_joy_base = e.position - off.normalized() * JOY_R * 1.6
				off = e.position - _joy_base
			_joy_knob = off.limit_length(JOY_R)
			queue_redraw()
		else:
			if (e.position - t.start).length() > TAP_MOVE:
				t.moved = true
			var n := _world_count()
			if n >= 2:
				var d := _pinch_dist()
				if _pinch_d > 1.0 and d > 1.0:
					_zoom(_pinch_d / d)
				_pinch_d = d
			elif n == 1 and t.moved and not t.get("hold", false):
				_turn(e.relative)
		accept_event()
	elif e is InputEventMouseButton or e is InputEventMouseMotion:
		# the browser's mouse copy of finger #1 – touches are handled above.
		# A real mouse (tablet with a mouse, or ?mobile=1 on a desktop) still works.
		if e is InputEventMouseButton and e.device != InputEvent.DEVICE_ID_EMULATION:
			if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				_tap(e.position)
			elif e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				_zoom(0.9 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1)
		accept_event()


func _world_count() -> int:
	var n := 0
	for k in _touches:
		if _touches[k].mode == "world":
			n += 1
	return n


func _pinch_dist() -> float:
	var pts := []
	for k in _touches:
		if _touches[k].mode == "world":
			pts.append(_touches[k].pos)
	return (pts[0] as Vector2).distance_to(pts[1]) if pts.size() >= 2 else 0.0


## Phones move only with the joystick: a tap on the world selects / talks to /
## picks up what is under the finger, but tapping bare ground never walks.
func _tap(pos: Vector2) -> void:
	var p := _player()
	if p == null or not p.has_method("_pick"):
		return
	var sp := get_global_transform_with_canvas() * pos
	var hit: Dictionary = p._pick(sp)
	var col = hit.get("collider")
	if col == null:
		return
	if col is Monster or col is NPC or col is DropItem or col is GatherNode or ((col is Node) and (col as Node).has_meta("remote_player")):
		Game.mouse_over_ui = false
		p._click(sp, true)


func _turn(rel: Vector2) -> void:
	var rig := _rig()
	if rig == null:
		return
	rig.yaw_deg = rig.yaw_deg - rel.x * 0.32
	rig.pitch_deg = clampf(rig.pitch_deg - rel.y * 0.18, -78.0, -18.0)


func _zoom(ratio: float) -> void:
	var rig := _rig()
	if rig == null:
		return
	var lo: float = rig.min_distance
	var hi: float = rig.max_distance
	var cur = rig.get("_dist_goal")
	if cur == null:
		cur = rig.distance
	rig.set("_dist_goal", clampf(float(cur) * ratio, lo, hi))


# ================================================================== per frame
func _process(delta: float) -> void:
	if _ui_blocked:
		_update_fling(delta)
		return
	var p := _player()
	if p and not p.get("touch_controls"):
		p.set("touch_controls", true)
	# joystick -> walk a short step ahead, camera-relative
	if _joy_idx != -1 and p and p.is_alive():
		_joy_t -= delta
		var k := _joy_knob / JOY_R
		if k.length() > 0.18 and _joy_t <= 0.0:
			_joy_t = 0.1
			var cam := get_viewport().get_camera_3d()
			if cam:
				var f := -cam.global_transform.basis.z
				f.y = 0.0
				f = f.normalized()
				var r := cam.global_transform.basis.x
				r.y = 0.0
				r = r.normalized()
				var dir := (r * k.x - f * k.y).normalized()
				p.go_to(p.global_position + dir * (1.2 + 2.2 * minf(1.0, k.length())), false)
	_update_context(delta)
	_update_fling(delta)
	# cooldown sweeps
	for i in 4:
		var idx := _page * 4 + i
		var id: String = Game.hotbar[idx] if idx < Game.hotbar.size() else ""
		var b := _skill_btns[i]
		var left := 0.0
		var total := 1.0
		if id != "" and not Items.DB.has(id):
			left = Game.cooldown_left(id)
			total = maxf(0.01, SkillDB.cooldown(id, Game.slv(id)))
		var frac := clampf(left / total, 0.0, 1.0) if left > 0.0 else 0.0
		if frac != b.cd:
			b.cd = frac
			b.cd_text = "" if left <= 0.0 else (("%.1f" % left) if left < 10.0 else str(int(ceil(left))))
			b.queue_redraw()
	if _auto.active != Game.auto_on:
		_auto.active = Game.auto_on
		_auto.queue_redraw()
	# message feed fades out
	for it in _feed_items.duplicate():
		it[1] -= delta
		var l: Label = it[0]
		l.modulate.a = clampf(it[1] / 0.8, 0.0, 1.0)
		if it[1] <= 0.0:
			_feed_items.erase(it)
			l.queue_free()
	if _joy_idx != -1 or _joy_alpha() > 0.0:
		queue_redraw()


func _joy_alpha() -> float:
	return 1.0 if _joy_idx != -1 else 0.55


func _draw() -> void:
	if _ui_blocked: return
	if ui._chat_panel.visible:
		return
	var base := _joy_base if _joy_idx != -1 else _joy_rest
	var a := _joy_alpha()
	draw_circle(base, JOY_R + 14.0, Color(0, 0, 0, 0.16 * a))
	draw_arc(base, JOY_R + 14.0, 0, TAU, 64, Color(1, 1, 1, 0.28 * a), 2.0, true)
	draw_arc(base, JOY_R * 0.55, 0, TAU, 48, Color(1, 1, 1, 0.08 * a), 1.0, true)
	# direction ticks
	for i in 4:
		var ang := i * PI * 0.5
		var d := Vector2(cos(ang), sin(ang))
		var tip := base + d * (JOY_R + 8.0)
		var n := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([tip, tip - d * 7 + n * 5, tip - d * 7 - n * 5]), Color(1, 1, 1, 0.3 * a))
	var knob := base + _joy_knob
	draw_circle(knob + Vector2(0, 2), 30.0, Color(0, 0, 0, 0.3 * a))
	draw_circle(knob, 30.0, Color(0.1, 0.1, 0.13, 0.55 * a + 0.2))
	draw_arc(knob, 29.0, 0, TAU, 48, Color(GOLD, 0.85 * a), 2.0, true)
	draw_circle(knob, 12.0, Color(GOLD, 0.35 * a))


# ================================================================== smooth touch scrolling in windows
## Lists inside windows are full of buttons, which swallow the finger before the
## ScrollContainer can see it. This layer watches touches first: once a finger
## moves more than a few pixels inside a scrollable list it takes over, scrolls
## 1:1 with the finger, cancels the button press it started on, and lets the
## list glide on with momentum after release.
var _sc: ScrollContainer
var _sc_idx := -1
var _sc_start := Vector2.ZERO
var _sc_active := false
var _sc_pos := Vector2.ZERO
var _sc_vel := Vector2.ZERO
var _sc_last := 0
var _fling_sc: ScrollContainer
var _fling_v := Vector2.ZERO
var _fling_pos := Vector2.ZERO
const SCROLL_SLOP := 9.0


func _scroll_at(pos: Vector2) -> ScrollContainer:
	var root: Control = ui._root
	# topmost visible window under the finger
	var top: Control = null
	for i in range(root.get_child_count() - 1, -1, -1):
		var c := root.get_child(i) as Control
		if c == null or c == self or not c.visible or c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if c.get_global_rect().has_point(pos):
			top = c
			break
	if top == null:
		return null
	var best: ScrollContainer = null
	var best_area := INF
	for n in top.find_children("*", "ScrollContainer", true, false):
		var sc := n as ScrollContainer
		if not sc.is_visible_in_tree():
			continue
		sc.scroll_deadzone = 100000          # our handler does the touch scrolling
		var r := sc.get_global_rect()
		if not r.has_point(pos):
			continue
		var vb := sc.get_v_scroll_bar()
		var hb := sc.get_h_scroll_bar()
		var can := (vb.max_value - vb.page > 1.0) or (hb.max_value - hb.page > 1.0)
		if can and r.get_area() < best_area:
			best_area = r.get_area()
			best = sc
	return best


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			if _sc_idx == -1:
				_fling_sc = null
				var sc := _scroll_at(e.position)
				if sc:
					_sc = sc
					_sc_idx = e.index
					_sc_start = e.position
					_sc_active = false
					_sc_vel = Vector2.ZERO
		elif e.index == _sc_idx:
			if _sc_active:
				get_viewport().set_input_as_handled()
				if _sc_vel.length() > 60.0 and is_instance_valid(_sc):
					_fling_sc = _sc
					_fling_v = _sc_vel
					_fling_pos = _sc_pos
			_sc_idx = -1
			_sc_active = false
			_sc = null
	elif e is InputEventScreenDrag and e.index == _sc_idx:
		if _sc == null or not is_instance_valid(_sc) or not _sc.is_visible_in_tree():
			_sc_idx = -1
			return
		if not _sc_active and (e.position - _sc_start).length() > SCROLL_SLOP:
			_sc_active = true
			_sc_pos = Vector2(_sc.get_h_scroll_bar().value, _sc.get_v_scroll_bar().value)
			_sc_last = Time.get_ticks_usec()
			# let go of the button the finger landed on, far away so it does not fire
			var up := InputEventMouseButton.new()
			up.button_index = MOUSE_BUTTON_LEFT
			up.pressed = false
			up.position = Vector2(-10000, -10000)
			up.global_position = up.position
			Input.parse_input_event(up)
		if _sc_active:
			var d: Vector2 = -e.relative
			_scroll_by(_sc, d)
			var now := Time.get_ticks_usec()
			var dt := maxf(0.001, float(now - _sc_last) / 1000000.0)
			_sc_last = now
			_sc_vel = _sc_vel.lerp(d / dt, 0.4)
			get_viewport().set_input_as_handled()
	elif (e is InputEventMouseButton or e is InputEventMouseMotion) and e.device == InputEvent.DEVICE_ID_EMULATION:
		# the browser's mouse copy of a finger that is scrolling a list
		if _sc_active:
			get_viewport().set_input_as_handled()


func _scroll_by(sc: ScrollContainer, d: Vector2) -> void:
	var vb := sc.get_v_scroll_bar()
	var hb := sc.get_h_scroll_bar()
	var vcan := vb.max_value - vb.page > 1.0
	var hcan := hb.max_value - hb.page > 1.0
	if vcan:
		_sc_pos.y = clampf(_sc_pos.y + d.y, 0.0, vb.max_value - vb.page)
		vb.value = _sc_pos.y
	if hcan and (not vcan or absf(d.x) > absf(d.y)):
		_sc_pos.x = clampf(_sc_pos.x + d.x, 0.0, hb.max_value - hb.page)
		hb.value = _sc_pos.x


func _update_fling(delta: float) -> void:
	if _fling_sc == null:
		return
	if not is_instance_valid(_fling_sc) or not _fling_sc.is_visible_in_tree() or _fling_v.length() < 20.0:
		_fling_sc = null
		return
	_sc_pos = _fling_pos
	_scroll_by(_fling_sc, _fling_v * delta)
	_fling_pos = _sc_pos
	_fling_v *= exp(-4.5 * delta)


