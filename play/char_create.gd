extends Node3D
## Title + character creation screen (the game's first scene).
## Left: hairstyle / face / starting outfit / colour palette.
## Right: name / gender / job (+ info card) / accessories.
## Centre: live 3D preview on a wooden pedestal inside an arched window.

const MAIN_SCENE := "res://scenes/main.tscn"

# dark-fantasy palette shared with the in-game HUD (ro_ui.gd)
const PARCH := Color(0.075, 0.08, 0.1, 0.94)   # panels
const PARCH_D := Color(0.17, 0.18, 0.22)       # buttons
const PARCH_L := Color(0.0, 0.0, 0.0, 0.35)    # inset cells / fields
const INK := Color(0.94, 0.93, 0.9)
const INK_L := Color(0.68, 0.7, 0.76)
const WOOD := Color(0.5, 0.42, 0.28)           # bronze borders
const GREEN := Color(0.2, 0.46, 0.32)
const GREEN_D := Color(0.12, 0.28, 0.2)
const RED := Color(0.58, 0.2, 0.18)
const GOLD := Color(0.95, 0.78, 0.45)
const TITLE := Color(0.98, 0.88, 0.66)
const SEL := Color(0.3, 0.23, 0.1)              # selected toggle
const RIBBON := Color(0.95, 0.78, 0.45)
const RIBBON_B := Color(0.42, 0.65, 1.0)

const FRAME_SHADER := """
shader_type canvas_item;
uniform vec2 rect_size = vec2(1280.0, 720.0);
uniform vec2 center = vec2(640.0, 330.0);
uniform float radius = 270.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 p = UV * rect_size;
	float d = (p.y < center.y) ? length(p - center) - radius : abs(p.x - center.x) - radius;
	if (d < 0.0) {
		float sh = smoothstep(-40.0, 0.0, d);
		COLOR = vec4(0.02, 0.02, 0.03, sh * 0.45);
	} else {
		vec3 c = vec3(0.055, 0.06, 0.078);
		c += vec3(0.02, 0.018, 0.012) * (1.0 - UV.y);
		c += (hash(floor(p / 2.0)) - 0.5) * 0.012;
		vec2 e = abs(UV - 0.5) * 2.0;
		c *= 1.0 - 0.3 * pow(max(e.x, e.y), 3.0);
		float a = 0.9;
		if (d < 2.0) { c = vec3(0.62, 0.5, 0.3); a = 1.0; }
		else if (d > 6.0 && d < 7.0) { c = mix(c, vec3(0.62, 0.5, 0.3), 0.35); }
		else if (d < 40.0) { a = mix(0.55, 0.9, (d - 2.0) / 38.0); }
		COLOR = vec4(c, a);
	}
}
"""

var look: Dictionary
var _rng := RandomNumberGenerator.new()
var _pivot: Node3D
var _preview: KnightModel
var _yaw := 0.0
var _yaw_goal := 0.0
var _drag := false
var _cam: Camera3D

var _ui: Control
var _frame: ColorRect
var _create: Control
var _title: Control
var _toast: Label
var _thumb_root: Node
var _thumb_env: Environment
var _grids := {}          # name -> {buttons, count, per, page, pager, thumbs}
var _palette_target := "hair_color"
var _palette_box: GridContainer
var _palette_tabs := {}
var _gender_btns := {}
var _job_btns := {}
var _name_edit: LineEdit
var _card_title: Label
var _card_text: RichTextLabel
var _card_icon: TextureRect
var _dirty := false
var _rebuild_thumbs := false


func _ready() -> void:
	Audio.ensure()
	_rng.randomize()
	look = Avatar.default_appearance()
	var saved := Game.save_summary()
	if not saved.is_empty() and saved.appearance is Dictionary and not saved.appearance.is_empty():
		look = saved.appearance.duplicate(true)
	_build_world()
	_build_ui()
	Settings.changed.connect(_refresh_texts)
	_apply_look()
	if saved.is_empty():
		_show_create()
	else:
		_show_title()


# ================================================================== 3D diorama
func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.36, 0.58, 0.95)
	sky_mat.sky_horizon_color = Color(0.82, 0.88, 0.94)
	sky_mat.ground_bottom_color = Color(0.32, 0.4, 0.25)
	sky_mat.ground_horizon_color = Color(0.82, 0.88, 0.94)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.88, 0.9, 1.0)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.95
	e.fog_enabled = true
	e.fog_light_color = Color(0.8, 0.87, 0.95)
	e.fog_density = 0.006
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation = Vector3(-0.75, 0.55, 0)
	sun.light_color = Color(1, 0.95, 0.86)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)

	var w := BlockWorld.new()
	# lake behind, a path towards the camera
	for x in range(-40, 40):
		for z in range(-40, -9):
			var lx := (x + 3.0) / 30.0
			var lz := (z + 22.0) / 10.0
			if lx * lx + lz * lz < 1.0:
				w.decal(x, z, 13)
			elif lx * lx + lz * lz < 1.12:
				w.decal(x, z, 12 if (x + z) % 3 == 0 else 2)
	for z in range(3, 14):
		for x in range(-1, 1):
			w.decal(x, z, 11)
	# rolling hills far away
	for x in range(-70, 70):
		var hgt := int(3.0 + 2.5 * sin(x * 0.11) + 1.8 * sin(x * 0.27 + 1.0))
		for z in range(-52, -44):
			var hh := hgt - absi(z + 48) / 2
			for y in hh:
				w.setb(x, y, z, 1 if y == hh - 1 else 3)
	# trees around the clearing
	var spots := [Vector2i(-9, -6), Vector2i(8, -7), Vector2i(-14, 2), Vector2i(13, 1), Vector2i(-19, -12),
		Vector2i(18, -14), Vector2i(-6, -36), Vector2i(10, -38), Vector2i(-25, -30), Vector2i(26, -28), Vector2i(-11, 9), Vector2i(12, 9)]
	for i in spots.size():
		var s: Vector2i = spots[i]
		if i % 3 == 2:
			_pine(w, s.x, s.y)
		else:
			_oak(w, s.x, s.y, 9 if i == 4 else 8)
	# a little cottage across the lake
	_cottage(w, -18, -40)
	_cottage(w, 20, -41)
	for i in 140:
		var x := _rng.randi_range(-24, 24)
		var z := _rng.randi_range(-12, 12)
		if Vector2(x, z).length() < 4.5 or (absi(x) <= 1 and z > 2):
			continue
		w.plant(x, z, [PixelTex.TALL_GRASS, PixelTex.TALL_GRASS, PixelTex.FLOWER, PixelTex.FLOWER_RED][_rng.randi() % 4])
	var blocks := Node3D.new()
	blocks.name = "Diorama"
	add_child(blocks)
	var col := Node3D.new()
	add_child(col)
	blocks.add_child(BlockWorld.ground_plane(160.0))
	w.build(blocks, col)
	# floating clouds
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var clouds := Node3D.new()
	clouds.name = "Clouds"
	add_child(clouds)
	clouds.set_script(preload("res://scripts/world/cloud_layer.gd"))
	for i in 18:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(_rng.randi_range(8, 20), 2.5, _rng.randi_range(5, 10))
		mi.mesh = bm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(_rng.randf_range(-150, 150), _rng.randf_range(26, 34), _rng.randf_range(-140, -60))
		clouds.add_child(mi)

	_build_pedestal()
	_pivot = Node3D.new()
	_pivot.position = Vector3(0, 0.46, 0)
	add_child(_pivot)
	_cam = Camera3D.new()
	_cam.name = "Camera3D"
	_cam.fov = 30
	_cam.position = Vector3(0, 2.15, 8.6)
	add_child(_cam)
	_cam.look_at(Vector3(0, 1.3, 0))
	_thumb_root = Node.new()
	_thumb_root.name = "Thumbs"
	add_child(_thumb_root)
	_thumb_env = Environment.new()
	_thumb_env.background_mode = Environment.BG_CLEAR_COLOR
	_thumb_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_thumb_env.ambient_light_color = Color(1, 0.97, 0.92)
	_thumb_env.ambient_light_energy = 0.75


## Round two-tier wooden pedestal with a pixel-art plank / tree-ring texture.
func _build_pedestal() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length()
			var ring := int(d) % 5 == 0
			var c := Color(0.72, 0.52, 0.3) if not ring else Color(0.56, 0.38, 0.21)
			if d > 14.5:
				c = Color(0.42, 0.27, 0.15)
			img.set_pixel(x, y, PixelTex.jit(c, x, y, 3, 0.05))
	var top_tex := ImageTexture.create_from_image(img)
	var side := Image.create(32, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 32:
			var c := Color(0.45, 0.3, 0.17) if x % 8 != 0 else Color(0.32, 0.2, 0.11)
			side.set_pixel(x, y, PixelTex.jit(c, x, y, 5, 0.06))
	var side_tex := ImageTexture.create_from_image(side)
	var tiers := [[1.25, 0.26, 0.13, 0.0], [1.5, 0.2, 0.0, 0.2]]
	for t in tiers:
		var cyl := CylinderMesh.new()
		cyl.top_radius = t[0]
		cyl.bottom_radius = t[0]
		cyl.height = t[1]
		cyl.radial_segments = 16
		cyl.rings = 1
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		var m := StandardMaterial3D.new()
		m.albedo_texture = side_tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.uv1_scale = Vector3(4, 1, 1)
		m.roughness = 1.0
		mi.material_override = m
		mi.position.y = t[2] + t[1] * 0.5 + 0.06
		add_child(mi)
		# flat textured cap
		var cap := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(t[0] * 2.0, t[0] * 2.0)
		q.orientation = PlaneMesh.FACE_Y
		cap.mesh = q
		var cm := StandardMaterial3D.new()
		cm.albedo_texture = top_tex
		cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		cm.roughness = 1.0
		var circle := img.duplicate() as Image
		for y in 32:
			for x in 32:
				if Vector2(x - 15.5, y - 15.5).length() > 16.0:
					circle.set_pixel(x, y, Color(0, 0, 0, 0))
		cm.albedo_texture = ImageTexture.create_from_image(circle)
		cap.material_override = cm
		cap.position.y = t[2] + t[1] + 0.062
		add_child(cap)


func _oak(w: BlockWorld, x: int, z: int, leaf: int) -> void:
	var hgt := 4 + _rng.randi() % 2
	for y in hgt:
		w.setb(x, y, z, 7)
	for y in [hgt - 2, hgt - 1]:
		for dx in range(-2, 3):
			for dz in range(-2, 3):
				if absi(dx) == 2 and absi(dz) == 2 and _rng.randf() < 0.7:
					continue
				if w.getb(x + dx, y, z + dz) == 0:
					w.setb(x + dx, y, z + dz, leaf)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if not (absi(dx) == 1 and absi(dz) == 1 and _rng.randf() < 0.4):
				w.setb(x + dx, hgt, z + dz, leaf)
	w.setb(x, hgt + 1, z, leaf)


func _pine(w: BlockWorld, x: int, z: int) -> void:
	var hgt := 6 + _rng.randi() % 3
	for y in hgt:
		w.setb(x, y, z, 7)
	for y in range(2, hgt + 1):
		var r := 2 if (hgt - y) % 3 == 2 and y < hgt - 2 else (1 if y < hgt else 0)
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if not (r == 2 and absi(dx) == 2 and absi(dz) == 2) and w.getb(x + dx, y, z + dz) == 0:
					w.setb(x + dx, y, z + dz, 10)
	w.setb(x, hgt + 1, z, 10)


func _cottage(w: BlockWorld, cx: int, cz: int) -> void:
	for x in range(cx - 3, cx + 4):
		for z in range(cz - 2, cz + 3):
			for y in 4:
				var edge := x == cx - 3 or x == cx + 3 or z == cz - 2 or z == cz + 2
				if edge:
					var corner := (x == cx - 3 or x == cx + 3) and (z == cz - 2 or z == cz + 2)
					w.setb(x, y, z, 7 if corner else (18 if y == 2 and (x - cx) % 2 == 0 else 14))
	for i in 4:
		for x in range(cx - 4 + i, cx + 5 - i):
			for z in range(cz - 3, cz + 4):
				if i == 3 or x == cx - 4 + i or x == cx + 4 - i:
					w.setb(x, 4 + i, z, 15)


# ================================================================== UI helpers
func _sb(bg: Color, border := WOOD, bw := 1, radius := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s


func _label(text: String, size := 14, color := INK, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", load("res://assets/fonts/ui_font_bold.tres"))
	return l


func _style_button(b: Button, bg: Color, fg := INK, size := 14) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", _sb(bg, bg.lightened(0.25), 1, 6))
	b.add_theme_stylebox_override("hover", _sb(bg.lightened(0.1), GOLD, 1, 6))
	b.add_theme_stylebox_override("pressed", _sb(bg.darkened(0.2), GOLD, 1, 6))
	b.add_theme_stylebox_override("disabled", _sb(bg.darkened(0.3), bg, 1, 6))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", load("res://assets/fonts/ui_font_bold.tres"))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(k, fg)
	b.add_theme_font_size_override("font_size", size)


func _button(text: String, cb: Callable, bg := PARCH_D, fg := INK, size := 14) -> Button:
	var b := Button.new()
	b.text = text
	_style_button(b, bg, fg, size)
	b.pressed.connect(cb)
	return b


func _big_button(text: String, cb: Callable, bg: Color) -> Button:
	var b := _button(text, cb, bg, Color(1, 0.97, 0.9), 20)
	b.add_theme_font_override("font", load("res://assets/fonts/ui_font_bold.tres"))
	for st in ["normal", "hover", "pressed"]:
		var s := b.get_theme_stylebox(st) as StyleBoxFlat
		s.border_color = bg.lightened(0.35) if st == "normal" else GOLD
		s.set_border_width_all(1)
		s.set_corner_radius_all(8)
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 4
		s.content_margin_left = 22
		s.content_margin_right = 22
	b.custom_minimum_size = Vector2(160, 46)
	return b


func _ribbon(text: String, color := RIBBON) -> Control:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)
	s.border_color = Color(color, 0.8)
	s.border_width_bottom = 2
	s.content_margin_left = 2
	s.content_margin_right = 2
	s.content_margin_top = 0
	s.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", s)
	var l := _label(text, 14, TITLE, true)
	p.add_child(l)
	return p


func _panel(pos: Vector2, size: Vector2, anchor_right := false) -> VBoxContainer:
	var p := PanelContainer.new()
	var s := _sb(PARCH, WOOD, 1, 8)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", s)
	if anchor_right:
		p.anchor_left = 1.0
		p.anchor_right = 1.0
		p.offset_left = -pos.x - size.x
		p.offset_right = -pos.x
	else:
		p.offset_left = pos.x
		p.offset_right = pos.x + size.x
	p.offset_top = pos.y
	p.custom_minimum_size = size
	_create.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	return v


func _sep(v: VBoxContainer) -> void:
	var c := Control.new()
	c.custom_minimum_size.y = 2
	v.add_child(c)


# ================================================================== build UI
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/ui_font.tres")
	theme.default_font_size = 14
	var tip := _sb(Color(0.06, 0.065, 0.085, 0.97), WOOD, 1, 6)
	tip.content_margin_left = 10
	tip.content_margin_right = 10
	tip.content_margin_top = 6
	tip.content_margin_bottom = 7
	theme.set_stylebox("panel", "TooltipPanel", tip)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	theme.set_constant("shadow_offset_x", "Label", 0)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_color("font_color", "TooltipLabel", INK)
	_ui.theme = theme

	_frame = ColorRect.new()
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = FRAME_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = sh
	_frame.material = sm
	_ui.add_child(_frame)
	get_viewport().size_changed.connect(_layout_frame)

	_create = Control.new()
	_create.set_anchors_preset(Control.PRESET_FULL_RECT)
	_create.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_create)
	_build_banner()
	_build_left()
	_build_right()
	_build_bottom()

	_toast = _label("", 16, Color(1, 0.95, 0.85), true)
	_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_toast.add_theme_constant_override("outline_size", 4)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_left = -300
	_toast.offset_right = 300
	_toast.offset_top = 24
	_toast.modulate.a = 0.0
	_ui.add_child(_toast)

	_build_title()
	_layout_frame()


func _layout_frame() -> void:
	var vs := get_viewport().get_visible_rect().size
	var m := _frame.material as ShaderMaterial
	m.set_shader_parameter("rect_size", vs)
	m.set_shader_parameter("center", Vector2(vs.x * 0.5, vs.y * 0.43))
	m.set_shader_parameter("radius", clampf(minf(vs.x * 0.5 - 360.0, vs.y * 0.4), 200.0, 330.0))


func _build_banner() -> void:
	var p := PanelContainer.new()
	var s := _sb(PARCH, WOOD, 1, 8)
	s.border_width_bottom = 2
	s.border_color = GOLD
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.shadow_color = Color(0, 0, 0, 0.4)
	s.shadow_size = 5
	p.add_theme_stylebox_override("panel", s)
	p.position = Vector2(18, 12)
	var l := _label("Create Your Adventurer", 22, TITLE)
	l.add_theme_font_override("font", load("res://assets/fonts/ui_font_title.tres"))
	l.name = "Title"
	p.add_child(l)
	_create.add_child(p)


func _build_left() -> void:
	var v := _panel(Vector2(16, 66), Vector2(340, 0))
	v.add_child(_ribbon("Hairstyle"))
	_grid(v, "hair", Avatar.HAIRSTYLES.size(), 8, 4, Vector2(64, 60), func(i: int) -> void: _set_opt("hair", i))
	_sep(v)
	v.add_child(_ribbon("Face"))
	_grid(v, "face", Avatar.FACES.size(), 6, 6, Vector2(46, 46), func(i: int) -> void: _set_opt("face", i))
	_sep(v)
	v.add_child(_ribbon("Starting Outfit"))
	_grid(v, "outfit", Avatar.OUTFITS.size(), 4, 4, Vector2(64, 64), func(i: int) -> void: _set_opt("outfit", i))
	_sep(v)
	v.add_child(_ribbon("Color Palette"))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	for t in [["skin", "Skin"], ["hair_color", "Hair"], ["eye_color", "Eyes"], ["outfit_color", "Outfit"], ["accent_color", "Accessory"]]:
		var b := _button(t[1], func() -> void:
			_palette_target = t[0]
			_fill_palette(), PARCH_D, INK, 12)
		b.custom_minimum_size = Vector2(0, 24)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
		_palette_tabs[t[0]] = b
	v.add_child(tabs)
	_palette_box = GridContainer.new()
	_palette_box.columns = 6
	_palette_box.add_theme_constant_override("h_separation", 6)
	_palette_box.add_theme_constant_override("v_separation", 6)
	v.add_child(_palette_box)


func _build_right() -> void:
	var v := _panel(Vector2(16, 12), Vector2(330, 0), true)
	v.add_child(_ribbon("Name", RIBBON_B))
	_name_edit = LineEdit.new()
	_name_edit.max_length = 16
	_name_edit.placeholder_text = "Enter a name"
	_name_edit.add_theme_stylebox_override("normal", _sb(PARCH_L, Color(1, 1, 1, 0.12), 1, 6))
	_name_edit.add_theme_stylebox_override("focus", _sb(PARCH_L, GOLD, 1, 6))
	_name_edit.add_theme_color_override("font_color", INK)
	_name_edit.add_theme_color_override("font_placeholder_color", Color(INK_L, 0.6))
	_name_edit.add_theme_color_override("caret_color", GOLD)
	_name_edit.add_theme_font_size_override("font_size", 16)
	_name_edit.custom_minimum_size.y = 34
	_name_edit.text = ""
	v.add_child(_name_edit)
	_sep(v)
	v.add_child(_ribbon("Gender", RIBBON_B))
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 8)
	for gpair in [["male", "Male"], ["female", "Female"]]:
		var b := _button(gpair[1], func() -> void: _set_opt("gender", gpair[0]), PARCH_D, INK, 15)
		b.custom_minimum_size = Vector2(0, 34)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gh.add_child(b)
		_gender_btns[gpair[0]] = b
	v.add_child(gh)
	_sep(v)
	v.add_child(_ribbon("Job", RIBBON_B))
	var jg := GridContainer.new()
	jg.columns = 3
	jg.add_theme_constant_override("h_separation", 6)
	jg.add_theme_constant_override("v_separation", 6)
	for id in Avatar.JOB_ORDER:
		var b := Button.new()
		b.text = Avatar.JOBS[id].name
		b.icon = ImageTexture.create_from_image(Avatar.weapon_image(Avatar.JOBS[id].sprite, 32))
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.expand_icon = false
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_style_button(b, PARCH_D, INK, 12)
		b.custom_minimum_size = Vector2(98, 56)
		b.pressed.connect(func() -> void:
			_set_opt("job", id)
			_preview.attack())
		jg.add_child(b)
		_job_btns[id] = b
	v.add_child(jg)
	# info card for the selected job
	var card := PanelContainer.new()
	var cs := _sb(PARCH_L, Color(1, 1, 1, 0.08), 1, 6)
	cs.content_margin_left = 10
	cs.content_margin_right = 10
	cs.content_margin_top = 6
	cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 8)
	card.add_child(ch)
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cv.add_theme_constant_override("separation", 2)
	ch.add_child(cv)
	var tp := PanelContainer.new()
	var ts := _sb(Color(RIBBON_B, 0.2), Color(RIBBON_B, 0.6), 1, 4)
	tp.add_theme_stylebox_override("panel", ts)
	tp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_card_title = _label("", 14, Color(1, 0.97, 0.9), true)
	tp.add_child(_card_title)
	cv.add_child(tp)
	_card_text = RichTextLabel.new()
	_card_text.bbcode_enabled = true
	_card_text.fit_content = true
	_card_text.scroll_active = false
	_card_text.custom_minimum_size = Vector2(220, 20)
	_card_text.add_theme_color_override("default_color", INK)
	_card_text.add_theme_font_size_override("normal_font_size", 12)
	_card_text.add_theme_font_size_override("bold_font_size", 12)
	_card_text.add_theme_font_override("bold_font", load("res://assets/fonts/ui_font_bold.tres"))
	cv.add_child(_card_text)
	_card_icon = TextureRect.new()
	_card_icon.custom_minimum_size = Vector2(56, 56)
	_card_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_card_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_card_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ch.add_child(_card_icon)
	v.add_child(card)
	_sep(v)
	v.add_child(_ribbon("Accessories", RIBBON_B))
	_grid(v, "acc", Avatar.ACCESSORIES.size(), 8, 4, Vector2(64, 50), func(i: int) -> void: _toggle_acc(Avatar.ACCESSORIES[i]))


func _build_bottom() -> void:
	var c := HBoxContainer.new()
	c.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	c.offset_left = -170
	c.offset_right = 170
	c.offset_top = -132
	c.offset_bottom = -96
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	var pill := PanelContainer.new()
	var ps := _sb(PARCH, WOOD, 1, 18)
	ps.content_margin_left = 4
	ps.content_margin_right = 4
	pill.add_theme_stylebox_override("panel", ps)
	var ph := HBoxContainer.new()
	ph.add_theme_constant_override("separation", 10)
	pill.add_child(ph)
	var lb := _button("<", func() -> void: _yaw_goal -= PI / 4.0, GREEN, Color(1, 0.97, 0.9), 16)
	lb.custom_minimum_size = Vector2(34, 28)
	ph.add_child(lb)
	var lab := _label("Drag to rotate", 13, INK_L)
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ph.add_child(lab)
	var rb := _button(">", func() -> void: _yaw_goal += PI / 4.0, GREEN, Color(1, 0.97, 0.9), 16)
	rb.custom_minimum_size = Vector2(34, 28)
	ph.add_child(rb)
	c.add_child(pill)
	_create.add_child(c)

	var bh := HBoxContainer.new()
	bh.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bh.offset_left = -200
	bh.offset_right = 200
	bh.offset_top = -78
	bh.offset_bottom = -22
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_theme_constant_override("separation", 22)
	bh.add_child(_big_button("Confirm", _confirm, GREEN))
	bh.add_child(_big_button("Back", _back, RED))
	_create.add_child(bh)

	var rnd := _button("Randomize", _randomize, PARCH_D, INK, 15)
	rnd.add_theme_font_override("font", load("res://assets/fonts/ui_font_bold.tres"))
	rnd.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	rnd.offset_left = 16
	rnd.offset_right = 356
	rnd.offset_top = -58
	rnd.offset_bottom = -20
	_create.add_child(rnd)


# ------------------------------------------------------------------ icon grids
func _grid(v: VBoxContainer, key: String, count: int, per: int, cols: int, cell: Vector2, cb: Callable) -> void:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	v.add_child(g)
	var info := {"grid": g, "count": count, "per": per, "page": 0, "buttons": [], "thumbs": [], "pager": null, "cb": cb}
	for slot in per:
		var b := Button.new()
		b.custom_minimum_size = cell
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_button(b, PARCH_L)
		b.pressed.connect(func() -> void:
			var i: int = info.page * info.per + slot
			if i < info.count:
				cb.call(i))
		g.add_child(b)
		info.buttons.append(b)
	for i in count:
		info.thumbs.append(_new_thumb())
	if count > per:
		var ph := HBoxContainer.new()
		ph.alignment = BoxContainer.ALIGNMENT_CENTER
		ph.add_theme_constant_override("separation", 10)
		var pl := _button("<", func() -> void: _page(key, -1), GREEN, Color(1, 0.97, 0.9), 12)
		pl.custom_minimum_size = Vector2(26, 20)
		ph.add_child(pl)
		var lbl := _label("1 / 2", 12, INK_L)
		ph.add_child(lbl)
		var pr := _button(">", func() -> void: _page(key, 1), GREEN, Color(1, 0.97, 0.9), 12)
		pr.custom_minimum_size = Vector2(26, 20)
		ph.add_child(pr)
		v.add_child(ph)
		info.pager = lbl
	_grids[key] = info


func _page(key: String, d: int) -> void:
	var info: Dictionary = _grids[key]
	var pages := int(ceil(float(info.count) / info.per))
	info.page = posmod(info.page + d, pages)
	_refresh_grid(key)


func _selected(key: String, i: int) -> bool:
	match key:
		"acc":
			return Avatar.has(look, Avatar.ACCESSORIES[i])
	return int(look.get(key, -1)) == i


func _item_name(key: String, i: int) -> String:
	match key:
		"hair":
			return Avatar.HAIRSTYLES[i]
		"face":
			return Avatar.FACES[i]
		"outfit":
			return Avatar.OUTFITS[i]
		"acc":
			return Avatar.ACC_NAMES[Avatar.ACCESSORIES[i]]
	return ""


func _refresh_grid(key: String) -> void:
	var info: Dictionary = _grids[key]
	for slot in info.per:
		var b: Button = info.buttons[slot]
		var i: int = info.page * info.per + slot
		if i >= info.count:
			b.icon = null
			b.disabled = true
			b.tooltip_text = ""
			b.modulate.a = 0.35
			continue
		b.disabled = false
		b.modulate.a = 1.0
		b.icon = (info.thumbs[i] as SubViewport).get_texture()
		b.tooltip_text = tr(_item_name(key, i))
		var sel := _selected(key, i)
		var s := _sb(Color(GOLD, 0.18) if sel else PARCH_L, GOLD if sel else Color(1, 1, 1, 0.1), 2 if sel else 1, 6)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", _sb(Color(1, 1, 1, 0.08), GOLD, 1, 6))
	if info.pager:
		info.pager.text = "%d / %d" % [info.page + 1, int(ceil(float(info.count) / info.per))]


# ------------------------------------------------------------------ thumbnails
func _new_thumb() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(96, 96)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.environment = _thumb_env
	cam.fov = 30
	vp.add_child(cam)
	var l := DirectionalLight3D.new()
	l.rotation = Vector3(-0.6, 0.5, 0)
	l.light_energy = 0.8
	vp.add_child(l)
	var holder := Node3D.new()
	holder.name = "Holder"
	vp.add_child(holder)
	_thumb_root.add_child(vp)
	return vp


func _render_thumb(vp: SubViewport, a: Dictionary, framing: String) -> void:
	if not vp.is_inside_tree():
		return
	var holder := vp.get_node("Holder") as Node3D
	for c in holder.get_children():
		holder.remove_child(c)
		c.queue_free()
	var body := Node3D.new()
	holder.add_child(body)
	Avatar.assemble(body, a, false)
	var cam := vp.get_node("Cam") as Camera3D
	holder.rotation.y = 0.45
	match framing:
		"head":
			cam.position = Vector3(0, 1.58, 1.75)
			cam.look_at(Vector3(0, 1.56, 0))
		"face":
			holder.rotation.y = 0.2
			cam.position = Vector3(0, 1.53, 1.25)
			cam.look_at(Vector3(0, 1.53, 0))
		"back":
			holder.rotation.y = PI + 0.5
			cam.position = Vector3(0, 1.1, 3.6)
			cam.look_at(Vector3(0, 0.98, 0))
		"upper":
			cam.position = Vector3(0, 1.3, 2.4)
			cam.look_at(Vector3(0, 1.22, 0))
		_:
			cam.position = Vector3(0, 1.0, 4.1)
			cam.look_at(Vector3(0, 0.92, 0))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func _render_all_thumbs() -> void:
	var base := look.duplicate(true)
	base.job = "swordsman"
	for i in Avatar.HAIRSTYLES.size():
		var a := base.duplicate(true)
		a.hair = i
		a.acc = (a.acc as Array).filter(func(x: String) -> bool: return x in ["elf_ears", "glasses"])
		_render_thumb(_grids.hair.thumbs[i], a, "head")
	for i in Avatar.FACES.size():
		var a := base.duplicate(true)
		a.face = i
		a.acc = []
		_render_thumb(_grids.face.thumbs[i], a, "face")
	for i in Avatar.OUTFITS.size():
		var a := base.duplicate(true)
		a.outfit = i
		a.acc = []
		_render_thumb(_grids.outfit.thumbs[i], a, "body")
	for i in Avatar.ACCESSORIES.size():
		var id: String = Avatar.ACCESSORIES[i]
		var a := base.duplicate(true)
		a.acc = [id]
		var framing := "head"
		if id == "cape":
			framing = "back"
		elif id == "scarf" or id == "satchel":
			framing = "upper"
		_render_thumb(_grids.acc.thumbs[i], a, framing)


# ------------------------------------------------------------------ palette
func _palette_colors() -> Array:
	match _palette_target:
		"skin":
			return Avatar.SKIN_TONES
		"hair_color":
			return Avatar.HAIR_COLORS
		"eye_color":
			return Avatar.EYE_COLORS
	return Avatar.CLOTH_COLORS


func _fill_palette() -> void:
	for c in _palette_box.get_children():
		_palette_box.remove_child(c)
		c.queue_free()
	var cols := _palette_colors()
	for i in cols.size():
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(40, 30)
		var sel: bool = int(look[_palette_target]) == i
		var s := _sb(cols[i], Color(1, 1, 1) if sel else INK_L, 3 if sel else 1, 4)
		if sel:
			s.shadow_color = GOLD
			s.shadow_size = 3
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", _sb((cols[i] as Color).lightened(0.15), GOLD, 2, 4))
		b.add_theme_stylebox_override("pressed", s)
		b.pressed.connect(func() -> void: _set_opt(_palette_target, i))
		_palette_box.add_child(b)
	for k in _palette_tabs:
		var b: Button = _palette_tabs[k]
		_style_button(b, SEL if k == _palette_target else PARCH_D, GOLD if k == _palette_target else INK, 12)


# ================================================================== state
func _set_opt(key: String, value) -> void:
	look[key] = value
	_apply_look()


func _toggle_acc(id: String) -> void:
	var acc: Array = (look.get("acc", []) as Array).duplicate()
	if id in acc:
		acc.erase(id)
	else:
		acc.append(id)
	look.acc = acc
	_apply_look()


func _randomize() -> void:
	look = Avatar.random_appearance(_rng)
	_apply_look()
	_preview.attack()


func _apply_look() -> void:
	if _preview == null:
		_preview = KnightModel.new()
		_preview.appearance = look.duplicate(true)
		_pivot.add_child(_preview)
	else:
		_preview.set_appearance(look.duplicate(true))
	if not _rebuild_thumbs:
		_rebuild_thumbs = true
		_deferred_refresh.call_deferred()


func _deferred_refresh() -> void:
	_rebuild_thumbs = false
	if not is_inside_tree():
		return
	_render_all_thumbs()
	for k in _grids:
		_refresh_grid(k)
	_fill_palette()
	_refresh_texts()


func _refresh_texts() -> void:
	for g in _gender_btns:
		var b: Button = _gender_btns[g]
		_style_button(b, SEL if look.gender == g else PARCH_D, GOLD if look.gender == g else INK, 15)
	for id in _job_btns:
		var b: Button = _job_btns[id]
		var sel: bool = look.job == id
		_style_button(b, SEL if sel else PARCH_D, GOLD if sel else INK, 12)
		if sel:
			for st in ["normal", "hover"]:
				var s := b.get_theme_stylebox(st) as StyleBoxFlat
				s.border_color = GOLD
				s.set_border_width_all(2)
	var j := Avatar.job(look.job)
	_card_title.text = tr(j.name)
	var st := ""
	for s in Game.STATS:
		st += "%s [b]%d[/b]  " % [s, j.stats[s]]
	_card_text.text = "%s\n[color=#b8bcc8]%s[/color]\n[color=#f2c773]%s[/color] %s / %s\n[color=#f2c773]%s[/color] %s" % [
		tr(j.desc), st.strip_edges(), tr("Skills:"), tr(j.skills[0]), tr(j.skills[1]), tr("Weapon:"), Items.item_name(j.weapon)]
	_card_icon.texture = ImageTexture.create_from_image(Avatar.weapon_image(j.sprite, 48))
	for k in _grids:
		_refresh_grid(k)


# ================================================================== flow
func _toast_msg(t: String) -> void:
	_toast.text = tr(t)
	_toast.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _confirm() -> void:
	if _entering_game:
		return
	var nm := _name_edit.text.strip_edges()
	if nm.length() < 2:
		_toast_msg("Please enter a name (at least 2 letters).")
		_name_edit.grab_focus()
		return
	Game.slot = _sel_slot
	Game.new_character(nm, look)
	_enter_game()


func _back() -> void:
	_show_title()


func _show_create() -> void:
	_title.hide()
	_create.show()


func _show_title() -> void:
	_create.hide()
	_title.show()
	_del_armed = -1
	_select_slot(_sel_slot)


func _build_title() -> void:
	_title = Control.new()
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_title)
	var logo := _label("Blockrealm Saga", 68, TITLE)
	logo.add_theme_font_override("font", load("res://assets/fonts/ui_font_title.tres"))
	logo.add_theme_color_override("font_outline_color", Color(0.16, 0.1, 0.04))
	logo.add_theme_constant_override("outline_size", 10)
	logo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	logo.add_theme_constant_override("shadow_offset_y", 5)
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.offset_left = -400
	logo.offset_right = 400
	logo.offset_top = 22
	_title.add_child(logo)
	var sub := _label("The Adventures of Aldenvale", 19, INK, true)
	sub.name = "Subtitle"
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	sub.add_theme_constant_override("outline_size", 5)
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.offset_left = -400
	sub.offset_right = 400
	sub.offset_top = 112
	_title.add_child(sub)
	# character select: up to Game.MAX_SLOTS characters
	var p := PanelContainer.new()
	var s := _sb(PARCH, WOOD, 1, 10)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 12
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", s)
	p.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	p.offset_left = 28
	p.offset_right = 28 + 360
	p.offset_top = -230
	p.offset_bottom = 230
	_title.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var head := HBoxContainer.new()
	var ht := _label("Select Character", 17, TITLE)
	ht.add_theme_font_override("font", load("res://assets/fonts/ui_font_title.tres"))
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(ht)
	_slot_count = _label("", 13, INK_L, true)
	_slot_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_slot_count)
	v.add_child(head)
	var line := ColorRect.new()
	line.color = Color(GOLD, 0.6)
	line.custom_minimum_size = Vector2(0, 2)
	v.add_child(line)
	_slot_box = VBoxContainer.new()
	_slot_box.add_theme_constant_override("separation", 6)
	v.add_child(_slot_box)
	var info := _label("", 12, INK_L)
	info.name = "SaveInfo"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = 320
	v.add_child(info)
	var play := _big_button("Play", _slot_action, GREEN)
	play.name = "Continue"
	play.custom_minimum_size = Vector2(0, 46)
	v.add_child(play)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var del := _button("Delete", _delete_slot, PARCH_D, Color(1.0, 0.6, 0.55), 14)
	del.name = "Delete"
	del.custom_minimum_size = Vector2(0, 36)
	del.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(del)
	if OS.get_name() != "Web":
		var ex := _button("Exit Game", func() -> void: get_tree().quit(), PARCH_D, INK, 14)
		ex.custom_minimum_size = Vector2(0, 36)
		ex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ex)
	v.add_child(row)
	_sel_slot = Game.slot


var _slot_box: VBoxContainer
var _slot_count: Label
var _sel_slot := 0
var _del_armed := -1


## Rebuild the 5 slot cards.
func _refresh_slots() -> void:
	for c in _slot_box.get_children():
		_slot_box.remove_child(c)
		c.queue_free()
	for i in Game.MAX_SLOTS:
		var sm := Game.save_summary(i)
		var sel := i == _sel_slot
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 58)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var bg := SEL if sel else (Color(0, 0, 0, 0.3) if not sm.is_empty() else Color(0, 0, 0, 0.15))
		b.add_theme_stylebox_override("normal", _sb(bg, GOLD if sel else Color(1, 1, 1, 0.1), 2 if sel else 1, 6))
		b.add_theme_stylebox_override("hover", _sb(bg.lightened(0.06), GOLD, 1, 6))
		b.add_theme_stylebox_override("pressed", _sb(bg, GOLD, 2, 6))
		b.pressed.connect(func() -> void: _select_slot(i))
		var h := HBoxContainer.new()
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		h.offset_left = 10
		h.offset_right = -10
		h.add_theme_constant_override("separation", 10)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(h)
		var num := _label("%d" % (i + 1), 18, GOLD if sel else INK_L, true)
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.custom_minimum_size.x = 16
		h.add_child(num)
		if sm.is_empty():
			var e := _label("Empty slot  -  create a new character", 13, Color(INK_L, 0.8))
			e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			e.size_flags_vertical = Control.SIZE_FILL
			h.add_child(e)
		else:
			var bp := "res://assets/ui/banners/%s_%d.png" % [sm.job_id, int(sm.tier)]
			if ResourceLoader.exists(bp):
				var ban := TextureRect.new()
				ban.texture = load(bp)
				ban.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				ban.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				ban.custom_minimum_size = Vector2(26, 44)
				ban.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				ban.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				h.add_child(ban)
			var tv := VBoxContainer.new()
			tv.alignment = BoxContainer.ALIGNMENT_CENTER
			tv.add_theme_constant_override("separation", -2)
			tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tv.add_child(_label(String(sm.name), 15, GOLD if sel else INK, true))
			tv.add_child(_label("%s  ·  %s" % [tr(String(sm.job)), tr("Base Lv. %d") % int(sm.level)], 12, INK_L))
			h.add_child(tv)
		_slot_box.add_child(b)
	_slot_count.text = "%d / %d" % [Game.slot_count(), Game.MAX_SLOTS]
	var sm := Game.save_summary(_sel_slot)
	var play := _title.find_child("Continue", true, false) as Button
	var del := _title.find_child("Delete", true, false) as Button
	var info := _title.find_child("SaveInfo", true, false) as Label
	play.text = tr("Play") if not sm.is_empty() else tr("Create Character")
	_style_big(play, GREEN if not sm.is_empty() else Color(0.2, 0.32, 0.52))
	del.disabled = sm.is_empty()
	del.text = tr("Click again to delete") if _del_armed == _sel_slot else tr("Delete")
	if sm.is_empty():
		info.text = tr("Slot %d is empty.") % (_sel_slot + 1)
	else:
		info.text = tr("%s  -  Zeny %d") % [String(sm.name), int(sm.zeny)]


func _style_big(b: Button, bg: Color) -> void:
	for st in ["normal", "hover", "pressed"]:
		var s := _sb(bg if st == "normal" else (bg.lightened(0.1) if st == "hover" else bg.darkened(0.2)),
			bg.lightened(0.35) if st == "normal" else GOLD, 1, 8)
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = 4
		s.content_margin_left = 22
		s.content_margin_right = 22
		b.add_theme_stylebox_override(st, s)


func _select_slot(i: int) -> void:
	if _sel_slot != i:
		_del_armed = -1
	_sel_slot = i
	var sm := Game.save_summary(i)
	if not sm.is_empty() and sm.appearance is Dictionary and not sm.appearance.is_empty():
		look = sm.appearance.duplicate(true)
	else:
		look = Avatar.default_appearance()
	_apply_look()
	_refresh_slots()


func _slot_action() -> void:
	if _entering_game:
		return
	Game.slot = _sel_slot
	if Game.has_save(_sel_slot):
		if Game.load_game(_sel_slot):
			_enter_game()
		return
	look = Avatar.default_appearance()
	_apply_look()
	_name_edit.text = ""
	_show_create()


func _delete_slot() -> void:
	if not Game.has_save(_sel_slot):
		return
	if _del_armed != _sel_slot:
		_del_armed = _sel_slot
		_refresh_slots()
		return
	var nm: String = Game.save_summary(_sel_slot).get("name", "")
	Game.delete_slot(_sel_slot)
	_del_armed = -1
	_toast_msg(tr("Deleted %s.") % nm)
	_select_slot(_sel_slot)


# ================================================================== input / update
func _unhandled_input(event: InputEvent) -> void:
	if not _create.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag = event.pressed
		if event.pressed and _name_edit.has_focus():
			_name_edit.release_focus()
	elif event is InputEventMouseMotion and _drag:
		_yaw_goal += event.relative.x * 0.012
		_yaw = _yaw_goal
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		_confirm()


func _process(delta: float) -> void:
	if not _drag:
		_yaw = lerpf(_yaw, _yaw_goal, 1.0 - exp(-8.0 * delta))
		if _title.visible:
			_yaw_goal += delta * 0.4
	_pivot.rotation.y = _yaw


var _entering_game := false

func _enter_game() -> void:
	if _entering_game:
		return
	_entering_game = true
	var overlay := preload("res://scripts/ui/game_loading.gd").new()
	get_tree().root.add_child(overlay)
	process_mode = Node.PROCESS_MODE_DISABLED
	overlay.start(MAIN_SCENE)