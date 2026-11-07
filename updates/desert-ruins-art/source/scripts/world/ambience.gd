class_name Ambience
extends Node3D





const SEASONS: = ["Spring", "Summer", "Autumn", "Winter"]
const DAYS_PER_SEASON: = 2



const LOOKS: = {
	"verdant": { "top": Color(0.35, 0.6, 0.75), "hor": Color(0.7, 0.88, 0.75), "light": Color(0.95, 1.0, 0.85), "sun": 0.95,
		"amb": Color(0.63, 0.76, 0.78), "amb_e": 0.4, "fog": Color(0.6, 0.8, 0.7), "dens": 0.003, "k": 0.7 },
	"desert": { "top": Color(0.4, 0.62, 0.95), "hor": Color(0.98, 0.88, 0.7), "light": Color(1.0, 0.93, 0.78), "sun": 0.72,
		"amb": Color(0.65, 0.72, 0.81), "amb_e": 0.42, "fog": Color(0.9, 0.81, 0.65), "dens": 0.0015, "k": 0.85 },
	"frost": { "top": Color(0.55, 0.7, 0.9), "hor": Color(0.88, 0.93, 1.0), "light": Color(0.85, 0.92, 1.0), "sun": 0.4,
		"amb": Color(0.42, 0.47, 0.6), "fog": Color(0.86, 0.92, 1.0), "dens": 0.01, "k": 0.8 },
	"ember": { "top": Color(0.22, 0.1, 0.08), "hor": Color(0.6, 0.3, 0.18), "light": Color(1.0, 0.78, 0.6), "sun": 0.8,
		"amb": Color(0.75, 0.55, 0.5), "fog": Color(0.38, 0.2, 0.14), "dens": 0.01, "k": 0.85 },
	"verdant_d": { "top": Color(0.01, 0.02, 0.01), "hor": Color(0.02, 0.05, 0.03), "light": Color(0.5, 0.8, 0.55), "sun": 0.32,
		"amb": Color(0.6, 0.85, 0.65), "fog": Color(0.02, 0.06, 0.03), "dens": 0.01, "amb_e": 0.7, "k": 1.0 },
	"desert_d": { "top": Color(0.02, 0.015, 0.01), "hor": Color(0.06, 0.04, 0.02), "light": Color(0.95, 0.75, 0.45), "sun": 0.32,
		"amb": Color(0.95, 0.8, 0.6), "fog": Color(0.07, 0.05, 0.03), "dens": 0.01, "amb_e": 0.7, "k": 1.0 },
	"frost_d": { "top": Color(0.01, 0.02, 0.04), "hor": Color(0.03, 0.06, 0.1), "light": Color(0.6, 0.8, 1.0), "sun": 0.32,
		"amb": Color(0.65, 0.8, 1.0), "fog": Color(0.04, 0.07, 0.12), "dens": 0.01, "amb_e": 0.7, "k": 1.0 },
	"ember_d": { "top": Color(0.03, 0.01, 0.01), "hor": Color(0.1, 0.03, 0.02), "light": Color(1.0, 0.5, 0.3), "sun": 0.32,
		"amb": Color(1.0, 0.65, 0.55), "fog": Color(0.12, 0.03, 0.02), "dens": 0.01, "amb_e": 0.85, "k": 1.0 },
	"smithy": { "k": 1.0, "top": Color(0.15, 0.12, 0.09), "hor": Color(0.2, 0.16, 0.1), "light": Color(1, 0.65, 0.3), "sun": 0.22, "amb": Color(0.65, 0.48, 0.33), "amb_e": 0.55, "fog": Color(0.2, 0.15, 0.1), "dens": 0.002 },
	"guild1": { "k": 0.0 }, "guild2": { "k": 0.0 },
}

const SEASON_TINT: = [
	[Color(1.12, 1.15, 1.0), Color(1.08, 1.1, 1.0), 0.0],
	[Color(0.92, 1.02, 0.86), Color(0.98, 1.02, 0.9), 0.0],
	[Color(3.3, 1.05, 0.75), Color(1.05, 0.74, 0.45), 0.0],
	[Color(2.4, 1.65, 3.2), Color(1.5, 1.35, 1.7), 0.82],
]

static var look: = { }
static var season: = 0
static var weather: = ""

var _area: = "town"
var _fx: = { }
var _weather_t: = 0.0
var _season_k: = Vector3(-1, -1, -1)
var _birds: Node3D
var _tint_from: = [Color(1, 1, 1), Color(1, 1, 1), 0.0]
var _tint_to: = [Color(1, 1, 1), Color(1, 1, 1), 0.0]
var _tint_t: = 1.0


func _ready() -> void:
	add_to_group("ambience")
	_build_fx()
	_birds = _make_birds()
	add_child(_birds)
	_weather_t = 2.0
	season = current_season()
	_apply_season_now()


static func current_season() -> int:
	var forced: int = int(Settings.g("season"))
	if forced >= 0:
		return forced
	return int(Game.world_day / DAYS_PER_SEASON) % 4


static func season_name() -> String:
	return SEASONS[season]


func _apply_season_now() -> void:
	var t: Array = SEASON_TINT[season]
	_tint_from = t
	_tint_to = t
	_tint_t = 1.0
	PixelTex.set_season(t[0], t[1], t[2])


func _process(delta: float) -> void:
	var p: = get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return
	global_position = p.global_position
	var a: = VillageBuilder.area_at(p.global_position)
	if a != _area:
		_area = a
		_weather_t = 0.0

	var s: = current_season()
	if s != season:
		season = s
		_tint_from = [_cur_tint(0), _cur_tint(1), _cur_tint(2)]
		_tint_to = SEASON_TINT[s]
		_tint_t = 0.0
		Game.log_msg(tr("The season turns: %s.") % tr(SEASONS[s]), Color(0.75, 0.95, 0.7))
	if _tint_t < 1.0:
		_tint_t = minf(1.0, _tint_t + delta / 6.0)
		PixelTex.set_season(_cur_tint(0), _cur_tint(1), _cur_tint(2))

	_weather_t -= delta
	if _weather_t <= 0.0:
		_weather_t = 120.0
		_roll_weather()
	_update_look()
	_update_fx()


func _cur_tint(i: int):
	if i == 2:
		return lerpf(float(_tint_from[2]), float(_tint_to[2]), _tint_t)
	return (_tint_from[i] as Color).lerp(_tint_to[i], _tint_t)


func _roll_weather() -> void:
	weather = ""
	if not bool(Settings.g("weather")):
		return
	if _area != "town":
		return
	var r: = randf()
	match season:
		0:
			weather = "rain" if r < 0.3 else ""
		1:
			weather = "rain" if r < 0.2 else ""
		2:
			weather = "rain" if r < 0.35 else ""
		3:
			weather = "snow" if r < 0.6 else ""


func _night() -> float:
	var dn: = get_tree().get_first_node_in_group("daynight")
	return dn.night_amount() if dn and dn.has_method("night_amount") else 0.0


func _update_look() -> void:
	if LOOKS.has(_area):
		look = LOOKS[_area]
	else:

		match season:
			2:
				look = { "top": Color(0.5, 0.62, 0.85), "hor": Color(0.95, 0.82, 0.62), "light": Color(1.0, 0.85, 0.65), "sun": 1.0,
					"amb": Color(0.95, 0.85, 0.75), "fog": Color(0.92, 0.82, 0.7), "dens": 0.0015, "k": 0.35 }
			3:
				look = { "top": Color(0.6, 0.7, 0.85), "hor": Color(0.88, 0.9, 0.95), "light": Color(0.9, 0.94, 1.0), "sun": 0.9,
					"amb": Color(0.85, 0.9, 1.0), "fog": Color(0.9, 0.93, 0.98), "dens": 0.002, "k": 0.45 }
			_:
				look = { "k": 0.0 }
		if weather == "rain":

			look = { "top": Color(0.3, 0.33, 0.4), "hor": Color(0.45, 0.48, 0.54), "light": Color(0.72, 0.78, 0.88), "sun": 0.55,
				"amb": Color(0.55, 0.6, 0.7), "fog": Color(0.32, 0.35, 0.4), "dens": 0.003, "k": 0.75 }
		elif weather == "snow":
			look = { "top": Color(0.65, 0.7, 0.8), "hor": Color(0.85, 0.88, 0.93), "light": Color(0.85, 0.9, 1.0), "sun": 0.75,
				"amb": Color(0.85, 0.9, 1.0), "fog": Color(0.7, 0.73, 0.8), "dens": 0.004, "k": 0.6 }



func _mat(c: Color, glow: = false) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = c
	if glow:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m


func _emitter(key: String, amount: int, size: Vector2, col: Color, extents: Vector3, y: float, vel: Vector3, spread: float,
		grav: Vector3, life: float, glow: = false, colors: = []) -> void:
	var p: = CPUParticles3D.new()
	p.name = key
	var q: = QuadMesh.new()
	q.size = size
	q.material = _mat(col, glow)
	p.mesh = q
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.position = Vector3(0, y, 0)
	p.direction = vel.normalized() if vel.length() > 0.0 else Vector3.DOWN
	p.initial_velocity_min = vel.length() * 0.7
	p.initial_velocity_max = vel.length() * 1.3
	p.spread = spread
	p.gravity = grav
	p.angular_velocity_min = -90.0
	p.angular_velocity_max = 90.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	if colors.size() > 0:
		var g: = Gradient.new()
		var offs: = PackedFloat32Array()
		var cols: = PackedColorArray()
		for i in colors.size():
			offs.append(float(i) / maxf(1.0, colors.size() - 1))
			cols.append(colors[i])
		g.offsets = offs
		g.colors = cols
		p.color_initial_ramp = g
	var fade: = Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	p.color_ramp = fade
	p.emitting = false
	p.visible = false
	add_child(p)
	_fx[key] = p


func _build_fx() -> void:
	var ext: = Vector3(22, 1, 22)
	_emitter("petals", 70, Vector2(0.12, 0.12), Color(1, 0.75, 0.85), ext, 12.0, Vector3(0.6, -0.6, 0.2), 25.0, Vector3(0.3, -0.25, 0), 12.0, false,
		[Color(1, 0.8, 0.88), Color(1, 0.68, 0.8), Color(1, 0.92, 0.95)])
	_emitter("leaves", 60, Vector2(0.16, 0.16), Color(0.95, 0.55, 0.2), ext, 12.0, Vector3(0.5, -0.8, 0.3), 30.0, Vector3(0.4, -0.3, 0), 10.0, false,
		[Color(0.95, 0.55, 0.15), Color(0.85, 0.3, 0.12), Color(0.95, 0.8, 0.25)])
	_emitter("snow", 220, Vector2(0.09, 0.09), Color(1, 1, 1, 0.95), ext, 14.0, Vector3(0.2, -1.2, 0.1), 20.0, Vector3(0.1, -0.4, 0), 11.0)
	_emitter("rain", 320, Vector2(0.025, 0.55), Color(0.62, 0.7, 0.82, 0.32), ext, 16.0, Vector3(0.6, -14.0, 0.0), 3.0, Vector3(0, -6, 0), 1.2)
	_emitter("fireflies", 40, Vector2(0.09, 0.09), Color(0.85, 1.0, 0.45), Vector3(16, 1.5, 16), 1.2, Vector3(0, 0.15, 0), 180.0, Vector3.ZERO, 5.0, true)
	_emitter("butterflies", 18, Vector2(0.18, 0.12), Color(1, 1, 1), Vector3(14, 0.8, 14), 1.0, Vector3(0.4, 0.3, 0), 180.0, Vector3(0, 0, 0), 7.0, false,
		[Color(1.0, 0.85, 0.25), Color(0.6, 0.8, 1.0), Color(1.0, 0.55, 0.75), Color(1, 1, 1)])
	_emitter("spores", 70, Vector2(0.07, 0.07), Color(0.7, 1.0, 0.6), Vector3(18, 2.5, 18), 1.5, Vector3(0, 0.25, 0), 180.0, Vector3(0, 0.05, 0), 8.0, true)
	_emitter("dust", 120, Vector2(0.1, 0.06), Color(0.95, 0.85, 0.6, 0.6), Vector3(4, 2, 22), 1.0, Vector3(6.0, 0.2, 0.0), 8.0, Vector3.ZERO, 7.0)
	_emitter("embers", 110, Vector2(0.08, 0.08), Color(1.0, 0.55, 0.15), Vector3(18, 0.5, 18), 0.2, Vector3(0, 1.6, 0), 20.0, Vector3(0.2, 0.3, 0), 6.0, true,
		[Color(1, 0.8, 0.3), Color(1, 0.45, 0.12), Color(1, 0.3, 0.1)])
	_emitter("ash", 130, Vector2(0.08, 0.08), Color(0.45, 0.43, 0.43, 0.8), ext, 12.0, Vector3(0.2, -0.7, 0), 25.0, Vector3(0.1, -0.2, 0), 14.0)
	_emitter("motes", 50, Vector2(0.06, 0.06), Color(1, 1, 1, 0.6), Vector3(10, 1.5, 10), 1.5, Vector3(0, 0.1, 0), 180.0, Vector3.ZERO, 7.0, true)
	_emitter("sparkle", 60, Vector2(0.07, 0.07), Color(0.7, 0.9, 1.0), Vector3(14, 2.0, 14), 1.5, Vector3(0, 0.1, 0), 180.0, Vector3.ZERO, 4.0, true)


func _toggle(key: String, on: bool) -> void:
	var p: CPUParticles3D = _fx[key]
	if p.emitting != on:
		p.emitting = on
		if on:
			p.visible = true
	if not on and p.visible and not p.emitting:

		if p.get_meta("off_t", 0.0) <= 0.0:
			p.set_meta("off_t", p.lifetime)
		p.set_meta("off_t", float(p.get_meta("off_t")) - get_process_delta_time())
		if float(p.get_meta("off_t")) <= 0.0:
			p.visible = false
			p.set_meta("off_t", 0.0)


func _update_fx() -> void:
	var night: = _night()
	var town: = _area == "town"
	var on: = { }
	if town:
		on.petals = season == 0 and weather == ""
		on.leaves = season == 2
		on.snow = weather == "snow"
		on.rain = weather == "rain"
		on.fireflies = night > 0.5 and season in [0, 1] and weather == ""
		on.butterflies = night < 0.3 and season in [0, 1] and weather == ""
	match _area:
		"verdant":
			on.spores = true
			on.fireflies = night > 0.4
			on.butterflies = night < 0.3
		"desert":
			on.dust = true
		"frost":
			on.snow = true
			on.sparkle = night < 0.5
		"ember":
			on.embers = true
			on.ash = true
		"verdant_d":
			on.spores = true
			on.motes = true
		"desert_d":
			on.motes = true
		"frost_d":
			on.sparkle = true
			on.motes = true
		"ember_d":
			on.embers = true
			on.motes = true
	for k in _fx:
		_toggle(k, bool(on.get(k, false)))
	_birds.visible = night < 0.4 and weather == "" and (town or _area == "verdant") and season != 3



func _make_birds() -> Node3D:
	var root: = Node3D.new()
	root.name = "Birds"
	root.set_script(preload("res://scripts/world/bird_flock.gd"))
	return root
