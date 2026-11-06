class_name HpBar3D
extends Node3D


@export var width := 0.8
@export var height := 0.09
@export var fill_color := Color(0.25, 0.85, 0.3)

var _fg: MeshInstance3D
var _label: Label3D
var ratio := 1.0
var _mobile_scale := 1.0


func _ready() -> void:
	var bg := _quad(Color(0.05, 0.05, 0.05, 0.85), Vector2(width + 0.04, height + 0.04), 0)
	add_child(bg)
	_fg = _quad(fill_color, Vector2(width, height), 1)
	_fg.position.z = 0.002
	add_child(_fg)
	_label = Label3D.new()
	_label.font = load("res://assets/fonts/ui_font_bold.tres")
	_label.font_size = 38
	_label.outline_size = 12
	_label.modulate = Color(0.05, 0.05, 0.07)
	_label.outline_modulate = Color(1, 1, 1)
	_label.pixel_size = 0.005
	_label.no_depth_test = true
	_label.position = Vector3(0, height + 0.12, 0)
	_label.render_priority = 6
	add_child(_label)
	Settings.changed.connect(_apply_name_size)
	_apply_name_size()
	set_ratio(1.0)


func _apply_name_size() -> void:
	_mobile_scale = 0.62 if Settings.is_mobile() and get_parent().is_in_group("monster") else 1.0
	scale = Vector3.ONE * _mobile_scale
	var scale_factor := clampf(float(Settings.g("nameplate_scale")), 0.5, 2.0)
	_label.font_size = roundi(38 * scale_factor)
	_label.outline_size = maxi(2, roundi(12 * scale_factor))
	_label.position.y = height + 0.08 + float(_label.font_size) * _label.pixel_size * 0.5


func set_label(t: String) -> void:
	if _label:
		_label.text = t


func set_label_color(c: Color) -> void:
	if _label:
		_label.modulate = c


func _quad(c: Color, size: Vector2, prio: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	m.no_depth_test = true
	m.render_priority = 4 + prio
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func set_ratio(r: float) -> void:
	ratio = clampf(r, 0.0, 1.0)
	if _fg == null:
		return
	_fg.scale.x = maxf(ratio, 0.001)
	_fg.position.x = - (1.0 - ratio) * width * 0.5
	var c := fill_color
	if ratio < 0.3:
		c = Color(0.95, 0.25, 0.2)
	elif ratio < 0.6:
		c = Color(0.95, 0.75, 0.2)
	(_fg.material_override as StandardMaterial3D).albedo_color = c


func _process(_d: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		global_basis = cam.global_basis.scaled(Vector3.ONE * _mobile_scale)
