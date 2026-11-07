extends Node



signal changed

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"language": "th",
	"damage_numbers": true,
	"npc_names": true,
	"nameplate_scale": 1.0,
	"outlines": true,
	"xray": true,
	"fullscreen": false,
	"vsync": true,
	"shadows": 2,
	"msaa": 1,
	"render_scale": 1.0,
	"view_distance": 250.0,
	"clouds": true,
	"ui_scale": 1.0,
	"chat_opacity": 0.92,
	"minimap": true,
	"cam_rotate_speed": 1.0,
	"zoom_step": 2.0,
	"invert_drag": false,
	"season": -1,
	"weather": true,
	"vol_master": 0.8,
	"vol_music": 0.55,
	"vol_sfx": 0.8,
	"vol_ambient": 0.6,
}

var data := { }
var _mobile := false
var _budget_t := 0.0


func _init() -> void:
	_migrate_old_user_dir()




static func _migrate_old_user_dir() -> void:
	var new_dir := OS.get_user_data_dir()
	if FileAccess.file_exists(new_dir.path_join(".migrated")):
		return
	var old_dir := new_dir.get_base_dir().path_join("RagnarokG")
	if old_dir != new_dir and DirAccess.dir_exists_absolute(old_dir):
		var d := DirAccess.open(old_dir)
		if d:
			for f in d.get_files():
				if f.get_extension() == "cfg" and not FileAccess.file_exists(new_dir.path_join(f)):
					d.copy(old_dir.path_join(f), new_dir.path_join(f))
	var m := FileAccess.open(new_dir.path_join(".migrated"), FileAccess.WRITE)
	if m:
		m.store_string("from RagnarokG")


func _ready() -> void:
	var th := Translation.new()
	th.locale = "th"
	for k in LocTH.TEXT:
		th.add_message(k, LocTH.TEXT[k])
	TranslationServer.add_translation(th)
	_mobile = _detect_mobile()
	data = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for k in DEFAULTS:
			data[k] = cfg.get_value("settings", k, DEFAULTS[k])
	apply()
	get_tree().node_added.connect(_on_node_added)

	if DisplayServer.get_name() != "headless" and OS.get_name() != "Web" and not g("fullscreen") \
			and not Engine.is_embedded_in_editor():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


func g(key: String):
	var value = data.get(key, DEFAULTS.get(key))
	if _mobile:
		match key:
			"shadows", "msaa":
				return 0
			"clouds", "weather", "outlines":
				return false
			"view_distance":
				return minf(float(value), 120.0)
			"render_scale":
				return 1.0
	return value


func is_mobile() -> bool:
	return _mobile


static func _detect_mobile() -> bool:
	if OS.get_environment("BR_MOBILE") != "":
		return OS.get_environment("BR_MOBILE") == "1"
	if OS.get_name() == "Web":
		return bool(JavaScriptBridge.eval("!!(window.BlockrealmMobileProfile && window.BlockrealmMobileProfile.mobile)", true))
	return OS.has_feature("mobile")


func _process(delta: float) -> void:
	if not _mobile:
		return
	_budget_t += delta
	if _budget_t < 1.0:
		return
	_budget_t = 0.0
	var hidden := false
	if OS.get_name() == "Web":
		hidden = bool(JavaScriptBridge.eval("document.hidden", true))
	Engine.max_fps = 10 if hidden else 30



func set_value(key: String, value) -> void:
	if data.get(key) == value:
		return
	data[key] = value
	apply()
	save()
	changed.emit()


func reset() -> void:
	data = DEFAULTS.duplicate()
	apply()
	save()
	changed.emit()


func save() -> void:
	var cfg := ConfigFile.new()
	for k in data:
		cfg.set_value("settings", k, data[k])
	cfg.save(PATH)


func apply() -> void:
	Engine.max_fps = 30 if _mobile else 0
	TranslationServer.set_locale(g("language"))
	var root := get_tree().root


	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_factor = g("ui_scale")
	root.scaling_3d_scale = g("render_scale")
	root.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][clampi(g("msaa"), 0, 2)]
	if DisplayServer.get_name() != "headless":
		var want_fs: bool = g("fullscreen")
		var is_fs := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		if OS.get_name() != "Web" and want_fs != is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if want_fs else DisplayServer.WINDOW_MODE_WINDOWED)
		var vs := DisplayServer.VSYNC_ENABLED if g("vsync") else DisplayServer.VSYNC_DISABLED
		if DisplayServer.window_get_vsync_mode() != vs:
			DisplayServer.window_set_vsync_mode(vs)
	_apply_scene()


func _apply_scene() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var sun := scene.find_child("Sun", true, false) as DirectionalLight3D
	if sun:
		var q: int = g("shadows")
		sun.shadow_enabled = q > 0
		RenderingServer.directional_shadow_atlas_set_size(512 if _mobile else (2048 if q == 1 else 4096), true)
		sun.directional_shadow_max_distance = 50.0 if q == 1 else 90.0
	var cam := scene.find_child("Camera3D", true, false) as Camera3D
	if cam:
		cam.far = g("view_distance")
	var clouds := scene.find_child("Clouds", true, false) as Node3D
	if clouds:
		clouds.visible = g("clouds")


func _on_node_added(n: Node) -> void:
	if _mobile and (n is CPUParticles3D or n is Light3D):
		_apply_mobile_node.call_deferred(n)

	if n.name == "Clouds" or n.name == "Sun" or n.name == "Camera3D":
		_apply_scene.call_deferred()


func _apply_mobile_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is CPUParticles3D:
		var particles := node as CPUParticles3D
		particles.amount = mini(particles.amount, maxi(4, mini(32, ceili(particles.amount * 0.4))))
	elif node is Light3D:
		(node as Light3D).shadow_enabled = false
