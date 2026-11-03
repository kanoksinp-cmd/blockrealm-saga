extends RefCounted
## JSON-only cloud format. Never deserialize objects from downloaded data.
const MAX_BYTES := 2 * 1024 * 1024

static func valid_id(id: String) -> bool:
	var re := RegEx.new()
	re.compile("^[a-zA-Z0-9_-]{1,128}$")
	return re.search(id) != null

static func prefix(id: String) -> String:
	return "user://accounts/%s/" % id if valid_id(id) else "user://"

static func encode_value(value):
	if value is Vector3:return [value.x, value.y, value.z]
	return value

static func capture(id: String) -> Dictionary:
	var slots: Array = []
	var defaults = load("res://scripts/game/game_state.gd").new()
	for i in Game.MAX_SLOTS:
		var cfg := ConfigFile.new()
		if cfg.load(prefix(id) + "save_%d.cfg" % (i + 1)) != OK:
			slots.append(null)
			continue
		var data := {}
		for key in Game.SAVE_KEYS:
			data[key] = encode_value(cfg.get_value("char", key, defaults.get(key)))
		slots.append(data)
	defaults.free()
	var meta := ConfigFile.new()
	meta.load(prefix(id) + "slots.cfg")
	return {"schema":1, "slots":slots, "last_slot":int(meta.get_value("slots", "last", 0))}

static func valid(data) -> bool:
	if not data is Dictionary or data.get("schema") != 1:return false
	if JSON.stringify(data).to_utf8_buffer().size() > MAX_BYTES:return false
	if not data.get("slots") is Array or data.slots.size() != Game.MAX_SLOTS:return false
	if not (data.get("last_slot") is int or data.get("last_slot") is float):return false
	if data.last_slot < 0 or data.last_slot >= Game.MAX_SLOTS:return false
	if float(data.last_slot) != floorf(float(data.last_slot)):return false
	for entry in data.slots:
		if entry == null:continue
		if not entry is Dictionary:return false
		for key in Game.SAVE_KEYS:
			if not entry.has(key):return false
			var value = entry[key]
			if key == "save_point":
				if not value is Array or value.size() != 3:return false
				for n in value:
					if not (n is int or n is float) or not is_finite(float(n)) or absf(float(n)) > 100000:return false
				continue
			var expected = Game.get(key)
			if expected is int or expected is float:
				if not (value is int or value is float) or not is_finite(float(value)):return false
			elif typeof(value) != typeof(expected):return false
		if entry.player_name.length() > 128 or entry.job_id.length() > 64:return false
	return true

## Repairs a downloaded bundle field by field instead of rejecting all of it.
## Returns {} when the data is not a save bundle at all.
static func sanitize(data) -> Dictionary:
	if data == null:
		return {"schema":1, "slots":[null, null, null, null, null], "last_slot":0}
	if not data is Dictionary or not data.get("slots") is Array:
		return {}
	if JSON.stringify(data).to_utf8_buffer().size() > MAX_BYTES:
		return {}
	var defaults = load("res://scripts/game/game_state.gd").new()
	var slots: Array = []
	for i in Game.MAX_SLOTS:
		var entry = data.slots[i] if i < data.slots.size() else null
		if not entry is Dictionary or not entry.get("player_name") is String or String(entry.player_name).strip_edges().is_empty():
			slots.append(null)
			continue
		var fixed := {}
		for key in Game.SAVE_KEYS:
			var fallback = encode_value(defaults.get(key))
			var value = entry.get(key)
			if key == "save_point":
				var ok: bool = value is Array and value.size() == 3
				if ok:
					for n in value:
						if not (n is int or n is float) or not is_finite(float(n)) or absf(float(n)) > 100000:ok = false
				fixed[key] = value if ok else fallback
			elif fallback is int or fallback is float:
				fixed[key] = value if (value is int or value is float) and is_finite(float(value)) else fallback
			else:
				fixed[key] = value if typeof(value) == typeof(fallback) else fallback
		fixed.player_name = String(fixed.player_name).left(128)
		if String(fixed.job_id).length() > 64:fixed.job_id = encode_value(defaults.get("job_id"))
		slots.append(fixed)
	defaults.free()
	var last = data.get("last_slot")
	var last_slot := clampi(int(last), 0, Game.MAX_SLOTS - 1) if (last is int or last is float) else 0
	return {"schema":1, "slots":slots, "last_slot":last_slot}

## First reason a raw downloaded bundle is not a save bundle (for diagnostics only).
static func why_invalid(data) -> String:
	if data == null:return "null"
	if not data is Dictionary:return "type " + type_string(typeof(data))
	if not data.get("slots") is Array:return "slots " + type_string(typeof(data.get("slots")))
	var size := JSON.stringify(data).to_utf8_buffer().size()
	if size > MAX_BYTES:return "too large (%d bytes)" % size
	return "rejected after repair"

static func install(id: String, data: Dictionary) -> bool:
	if not valid_id(id) or not valid(data):return false
	var base := prefix(id)
	if DirAccess.make_dir_recursive_absolute(base) != OK:return false
	# Stage the complete bundle before switching any live saves.
	for i in Game.MAX_SLOTS:
		if data.slots[i] == null:continue
		var cfg := ConfigFile.new()
		for key in Game.SAVE_KEYS:
			var value = data.slots[i][key]
			if key == "save_point":value = Vector3(value[0], value[1], value[2])
			elif Game.get(key) is int:value = int(value)
			cfg.set_value("char", key, value)
		if cfg.save(base + "incoming_%d.cfg" % i) != OK:return false
	var stamp := str(Time.get_unix_time_from_system()).replace(".", "_") + "_" + str(Time.get_ticks_usec())
	var backup := base + "backups/" + stamp + "/"
	if DirAccess.make_dir_recursive_absolute(backup) != OK:return false
	for i in Game.MAX_SLOTS:
		var target := base + "save_%d.cfg" % (i + 1)
		if FileAccess.file_exists(target):
			if DirAccess.copy_absolute(target, backup + "save_%d.cfg" % (i + 1)) != OK:return false
	# A recovery copy is kept until all replacements succeed.
	for i in Game.MAX_SLOTS:
		var target := base + "save_%d.cfg" % (i + 1)
		if FileAccess.file_exists(target):DirAccess.remove_absolute(target)
		if data.slots[i] != null:
			if DirAccess.rename_absolute(base + "incoming_%d.cfg" % i, target) != OK:
				for j in Game.MAX_SLOTS:
					var restore := backup + "save_%d.cfg" % (j + 1)
					var dest := base + "save_%d.cfg" % (j + 1)
					if FileAccess.file_exists(restore):DirAccess.copy_absolute(restore, dest)
					elif FileAccess.file_exists(dest):DirAccess.remove_absolute(dest)
				return false
	var meta := ConfigFile.new()
	meta.set_value("slots", "last", int(data.last_slot))
	return meta.save(base + "slots.cfg") == OK
