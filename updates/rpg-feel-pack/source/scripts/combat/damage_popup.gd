extends Control
## Screen-space damage feedback anchored to the 3D point where the hit landed.

const DURATION := 1.15
## Vertical step between stacked numbers (Ragnarok-style ladder: every new hit
## appears at the bottom and pushes the earlier numbers one step up).
const ROW_H := 30.0
## Overall size of the numbers (1.0 = the original Ragnarok-style size).
const SIZE := 0.7
const BURST := [
	Vector2(-1, -0.08), Vector2(-0.75, -0.30), Vector2(-0.94, -0.69),
	Vector2(-0.57, -0.60), Vector2(-0.58, -1), Vector2(-0.25, -0.75),
	Vector2(-0.06, -0.98), Vector2(0.13, -0.76), Vector2(0.39, -0.99),
	Vector2(0.49, -0.63), Vector2(0.84, -0.81), Vector2(0.77, -0.40),
	Vector2(1, -0.27), Vector2(0.83, 0.08), Vector2(1, 0.42),
	Vector2(0.69, 0.45), Vector2(0.69, 0.89), Vector2(0.34, 0.68),
	Vector2(0.13, 0.98), Vector2(-0.11, 0.73), Vector2(-0.38, 1),
	Vector2(-0.50, 0.68), Vector2(-0.81, 0.86), Vector2(-0.73, 0.43),
	Vector2(-1, 0.37), Vector2(-0.87, 0.15),
]

static var _retro_font: Font
var anchor := Vector3.ZERO
var lane := 0                 # kept for callers; the stack row is what moves the number
var row := 0                  # 0 = newest; earlier numbers climb as new hits land
var _row_vis := 0.0
var _jitter := 0.0
var _text := ""
var _ink := Color.WHITE
var _crit := false
var _font_size := 33
var _width := 0.0
var _baseline := 0.0
var _age := 0.0
var _burst_outer := PackedVector2Array()
var _burst_inner := PackedVector2Array()


func setup(text: String, ink: Color, crit: bool, miss: bool) -> void:
	_text = text
	_ink = ink
	_crit = crit
	_font_size = roundi((42 if crit else (29 if miss else 35)) * SIZE)
	if _retro_font == null:
		_retro_font = load("res://assets/fonts/BlockrealmPixel.ttf") as Font
		if _retro_font == null:
			_retro_font = ThemeDB.fallback_font
	_width = _retro_font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
	_baseline = (_retro_font.get_ascent(_font_size) - _retro_font.get_descent(_font_size)) * 0.5
	if _crit:
		var radius := Vector2(_width * 0.5 + 18.0 * SIZE, 23.0 * SIZE)
		for point in BURST:
			_burst_outer.append((point * radius).round())
			_burst_inner.append((point * (radius - Vector2(2, 2))).round())
	mouse_filter = MOUSE_FILTER_IGNORE
	_jitter = [0.0, 7.0, -7.0, 4.0, -4.0][lane % 5] * SIZE


## A newer hit landed on the same target: climb one step.
func push_up() -> void:
	row += 1
	# keep the ladder short and readable
	if row >= 6:
		_age = maxf(_age, DURATION - 0.18)


func _process(delta: float) -> void:
	_age += delta
	if _age >= DURATION:
		queue_free()
		return
	var camera := get_viewport().get_camera_3d()
	visible = camera != null and not camera.is_position_behind(anchor)
	if not visible:
		return
	var phase := _age / DURATION
	# pop up on arrival, then drift gently upward while the ladder grows
	var hop := sin(minf(phase * 3.2, 1.0) * PI) * (16.0 if _crit else 11.0) * SIZE
	_row_vis = lerpf(_row_vis, float(row), minf(1.0, get_process_delta_time() * 16.0))
	var offset := Vector2(_jitter, -_row_vis * (_font_size + 4.0))
	position = (camera.unproject_position(anchor) + offset + Vector2(0, -hop - phase * 22.0 * SIZE)).round()
	var punch := sin(minf(_age / 0.22, 1.0) * PI) * (0.24 if _crit else 0.15)
	scale = Vector2.ONE * (1.0 + punch)
	modulate.a = 1.0 - smoothstep(0.64, 1.0, phase)


func _draw() -> void:
	if _crit:
		draw_colored_polygon(_burst_outer, Color("#44201a"))
		draw_colored_polygon(_burst_inner, Color("#ad4b26"))
	var origin := Vector2(-roundf(_width * 0.5), roundf(_baseline))
	draw_string_outline(_retro_font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, 4, Color("#211b20"))
	draw_string(_retro_font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _ink)
