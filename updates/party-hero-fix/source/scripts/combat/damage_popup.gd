extends Control
## Screen-space damage feedback anchored to the 3D point where the hit landed.

const DURATION := 1.15
## Overall size of the numbers (1.0 = the original Ragnarok-style size).
const SIZE := 1.1
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
var lane := 0
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
	# Each hit follows its own arc: rise, fall, then shrink away.
	var launch := 155.0 if _crit else 130.0
	var gravity := 385.0 if _crit else 330.0
	var fall := (-launch * _age + 0.5 * gravity * _age * _age) * 0.7
	var drift := _jitter * (1.0 + phase * 2.0)
	position = camera.unproject_position(anchor) + Vector2(drift, fall)
	var punch := sin(minf(_age / 0.16, 1.0) * PI) * (0.24 if _crit else 0.15)
	var shrink := lerpf(1.0, 0.18, smoothstep(0.27, 1.0, phase))
	scale = Vector2.ONE * (shrink + punch)
	modulate.a = 1.0 - smoothstep(0.72, 1.0, phase)


func _draw() -> void:
	if _crit:
		draw_colored_polygon(_burst_outer, Color("#44201a"))
		draw_colored_polygon(_burst_inner, Color("#ad4b26"))
	var origin := Vector2(-roundf(_width * 0.5), roundf(_baseline))
	draw_string_outline(_retro_font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, 4, Color("#211b20"))
	draw_string(_retro_font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, _ink)
