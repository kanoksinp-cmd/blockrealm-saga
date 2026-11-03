extends Node
## Username/password game accounts and account-scoped cloud saves.
signal status_changed
signal saves_changed
signal auth_attention
const Store = preload("res://scripts/game/account_save_store.gd")
var endpoint := ""
var public_key := ""
var user_id := ""
var username := ""
var status := "เล่นด้วยเซฟในเครื่อง"
var busy := false
var hydrated := false
var conflict := false
var pending := false
var revision := 0
var _token := ""
var _remote := {}
var _sequence := 0
var _send_after := 0.0
var _session_expired := false
var _bootstrapping := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load("res://account_config.cfg") == OK:
		endpoint = String(cfg.get_value("supabase", "url", "")).trim_suffix("/")
		public_key = String(cfg.get_value("supabase", "publishable_key", ""))
	if not public_key.begins_with("sb_publishable_"):public_key = ""
	_bootstrapping = OS.has_feature("web")
	call_deferred("_consume_game_bootstrap")

static func valid_username(value: String) -> bool:
	var pattern := RegEx.new();pattern.compile("^[a-z][a-z0-9_]{2,23}$")
	return pattern.search(value) != null

static func valid_password(value: String) -> bool:
	return value.length() >= 8 and value.to_utf8_buffer().size() <= 72

func configured() -> bool:
	return not public_key.is_empty() and (endpoint.begins_with("https://") or (OS.is_debug_build() and endpoint.begins_with("http://127.0.0.1:")))

func on_title() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.name != "Main"

func can_play() -> bool:
	return not busy and not _bootstrapping and (user_id.is_empty() or (hydrated and not conflict and not _session_expired))

func storage_prefix() -> String:return Store.prefix(user_id)

func _set_status(text: String):
	status = text;status_changed.emit()

func _process(delta: float):
	if pending and hydrated and not busy and not conflict and not _session_expired:
		_send_after -= delta
		if _send_after <= 0:sync()

func _meta_path() -> String:return storage_prefix() + "sync.cfg"

func _save_meta():
	if user_id.is_empty():return
	DirAccess.make_dir_recursive_absolute(storage_prefix())
	var cfg := ConfigFile.new()
	cfg.set_value("cloud", "revision", revision);cfg.set_value("cloud", "pending", pending)
	cfg.save(_meta_path())

func mark_dirty():
	if user_id.is_empty():return
	pending = true;_sequence += 1;_send_after = 3.0;_save_meta()
	_set_status("มีเซฟใหม่ รอซิงก์เข้าบัญชี")

func _request(route: String, method: int, body = null, auth := false) -> Dictionary:
	var payload: Dictionary = {} if body == null else body.duplicate(true)
	if auth:payload.p_session_token = _token
	var reply := await _raw(route,method,payload,"")
	if reply.get("data") is Dictionary and reply.data.get("error") == "session_expired":
		reply.ok = false;_session_expired = true
		_set_status("หมดเวลาเข้าสู่ระบบ เซฟยังอยู่ในเครื่อง กลับหน้าเลือกตัวละครแล้วออกและเข้าสู่บัญชีเดิมอีกครั้ง")
	return reply

func _raw(route: String, method: int, body, token: String) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = 20.0
	req.body_size_limit = Store.MAX_BYTES + 16384
	# On Web the browser already decodes gzip; decoding again fails with RESULT_BODY_DECOMPRESS_FAILED.
	req.accept_gzip = false
	add_child(req)
	var headers := PackedStringArray(["apikey: " + public_key, "Content-Type: application/json"])
	if not token.is_empty():headers.append("Authorization: Bearer " + token)
	var err := req.request(endpoint + route, headers, method, "" if body == null else JSON.stringify(body))
	if err != OK:
		req.queue_free()
		return {"ok":false,"code":0}
	var reply = await req.request_completed
	req.queue_free()
	var parsed := JSON.new()
	var data = null
	if not reply[3].is_empty() and parsed.parse(reply[3].get_string_from_utf8()) == OK:data = parsed.data
	return {"ok":reply[0] == HTTPRequest.RESULT_SUCCESS and reply[1] >= 200 and reply[1] < 300,
		"code":reply[1],"result":reply[0],"data":data}

func _auth_error(code: String) -> String:
	match code:
		"username_taken":return "ชื่อบัญชีนี้ถูกใช้แล้ว กรุณาเลือกชื่ออื่น"
		"invalid_username":return "ชื่อบัญชีใช้ a-z, 0-9 และ _ ยาว 3–24 ตัว โดยขึ้นต้นด้วยตัวอักษร"
		"invalid_password":return "รหัสผ่านต้องมีอย่างน้อย 8 ตัว และยาวไม่เกิน 72 ไบต์"
		"rate_limited":return "ลองเข้าสู่ระบบหรือสมัครบ่อยเกินไป กรุณารอสักครู่"
		"invalid_credentials":return "ชื่อบัญชีหรือรหัสผ่านไม่ถูกต้อง"
	return "เชื่อมต่อบัญชีไม่สำเร็จ กรุณาลองใหม่"

func register_account(name: String, password: String, confirmation: String):
	if busy or not on_title() or not user_id.is_empty():return
	if password != confirmation:_set_status("ยืนยันรหัสผ่านไม่ตรงกัน");return
	await _authenticate("game_register",name,password)

func sign_in(name: String, password: String):
	if busy or not on_title() or not user_id.is_empty():return
	await _authenticate("game_sign_in",name,password)

func _authenticate(action: String, name: String, password: String):
	if not configured():_set_status("ระบบบัญชียังไม่พร้อมใช้งาน");return
	name = name.strip_edges().to_lower()
	if not valid_username(name):_set_status(_auth_error("invalid_username"));return
	if not valid_password(password):_set_status(_auth_error("invalid_password"));return
	busy = true;_set_status("กำลังสร้างบัญชีเกม" if action == "game_register" else "กำลังเข้าสู่ระบบ")
	var reply := await _request("/rest/v1/rpc/" + action,HTTPClient.METHOD_POST,{"p_username":name,"p_password":password})
	password = ""
	if not reply.ok or not reply.get("data") is Dictionary or not reply.data.get("ok",false):
		busy = false;_set_status(_auth_error(String(reply.get("data",{}).get("error","") if reply.get("data") is Dictionary else "")));return
	if not _accept_session(reply.data):busy = false;_set_status("ข้อมูลบัญชีไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่");return
	await _finish_login()
	busy = false;status_changed.emit()

func _accept_session(data: Dictionary) -> bool:
	if not data.get("user") is Dictionary or not data.get("session_token") is String:return false
	var id := String(data.user.get("id",""));var name := String(data.user.get("username",""))
	var pattern := RegEx.new();pattern.compile("^[a-f0-9]{64}$")
	if not Store.valid_id(id) or not valid_username(name) or pattern.search(data.session_token) == null:return false
	user_id = id;username = name;_token = data.session_token;_session_expired = false
	_notify_web_account()
	return true

func _notify_web_account():
	if not OS.has_feature("web"):return
	var js := "(function(){try{var p=window.parent;if(p!==window&&p.location.origin===location.origin&&p.BlockrealmGameAccountBridge)p.BlockrealmGameAccountBridge.update("
	JavaScriptBridge.eval(js + JSON.stringify(_token) + "," + JSON.stringify(username) + ");}catch(e){}})()",true)

func _consume_game_bootstrap():
	if not OS.has_feature("web"):return
	await get_tree().process_frame
	var raw = JavaScriptBridge.eval("(function(){try{var p=window.parent;if(p!==window&&p.location.origin===location.origin&&p.BlockrealmGameAccountBridge)return p.BlockrealmGameAccountBridge.take();}catch(e){}return '';})()",true)
	_bootstrapping = false
	if not raw is String or raw.is_empty():return
	var parsed := JSON.new()
	if parsed.parse(raw) != OK or not parsed.data is Dictionary:return
	if not await accept_game_session(parsed.data):auth_attention.emit()

func accept_game_session(grant: Dictionary) -> bool:
	if busy or not on_title() or not user_id.is_empty():return false
	if not grant.get("session_token") is String or grant.session_token.length() != 64:return false
	busy = true;_set_status("กำลังโหลดบัญชีเกมและตัวละคร")
	var r := await _request("/rest/v1/rpc/game_whoami",HTTPClient.METHOD_POST,{"p_session_token":grant.session_token})
	if not r.ok or not r.get("data") is Dictionary or not r.data.get("ok",false) or not r.data.get("user") is Dictionary:
		busy = false;_set_status("บัญชีหมดเวลาหรือเชื่อมต่อไม่ได้ กรุณาเข้าสู่ระบบอีกครั้ง");return false
	if String(r.data.user.get("username","")) != String(grant.get("expected_username","")):
		busy = false;_set_status("บัญชีไม่ตรงกับหน้าสมัคร กรุณาเข้าสู่ระบบใหม่");return false
	r.data.session_token = grant.session_token
	if not _accept_session(r.data):busy = false;return false
	await _finish_login();busy = false;status_changed.emit()
	return true

func _finish_login():
	var cfg := ConfigFile.new();cfg.load(_meta_path())
	revision = int(cfg.get_value("cloud","revision",0));pending = bool(cfg.get_value("cloud","pending",false))
	hydrated = false;conflict = false
	await _download()

func _fetch_remote() -> Dictionary:
	var r := await _request("/rest/v1/rpc/game_read_save",HTTPClient.METHOD_POST,{},true)
	if r.ok and r.get("data") == null:r.data = {"ok":true,"revision":0,"payload":null}
	if not r.ok or not r.get("data") is Dictionary or not r.data.get("ok",false):
		return {"ok":false,"why":_read_error(r)}
	var row: Dictionary = r.data
	if not (row.get("revision") is float or row.get("revision") is int):return {"ok":false,"why":"revision=" + type_string(typeof(row.get("revision")))}
	var payload := Store.sanitize(row.get("payload"))
	if not Store.valid(payload):return {"ok":false,"why":"payload " + Store.why_invalid(row.get("payload"))}
	return {"ok":true,"revision":int(row.revision),"payload":payload}

## Short, secret-free reason shown in the account panel when the account save cannot be read.
func _read_error(r: Dictionary) -> String:
	var parts: Array = ["HTTP %d" % int(r.get("code", 0))]
	if int(r.get("result", 0)) != 0:parts.append("result %d" % int(r.result))
	var d = r.get("data")
	if d is Dictionary:
		for k in ["error", "code", "message", "hint"]:
			if d.has(k) and d[k] != null:parts.append("%s=%s" % [k, String(str(d[k])).left(90)])
	elif d == null:parts.append("empty body")
	else:parts.append(type_string(typeof(d)))
	return ", ".join(parts)

func _download():
	_set_status("กำลังตรวจเซฟในบัญชี")
	var row := await _fetch_remote()
	if not row.ok:
		_set_status("ยังอ่านเซฟจากบัญชีไม่ได้ เซฟในเครื่องยังปลอดภัย กดซิงก์เพื่อลองใหม่\n[สาเหตุ: %s]" % String(row.get("why", "?")));return
	_remote = row
	# Signed-in play uses the account save only. Install() keeps a backup of the old local copy.
	if not Store.install(user_id, row.payload):_set_status("เขียนเซฟในเครื่องไม่สำเร็จ ยังไม่เปลี่ยนเซฟในบัญชี");return
	revision = int(row.revision);hydrated = true;pending = false;conflict = false
	_save_meta();Game.slot = Game.last_slot();Game.character_ready = false
	saves_changed.emit();_set_status("เชื่อมบัญชีแล้ว เซฟพร้อมเล่น")

func sync():
	if busy or user_id.is_empty():return
	busy = true;status_changed.emit()
	if not hydrated and not conflict:
		if on_title():await _download()
	elif not conflict:
		if Game.character_ready and not on_title():Game.save_game()
		if pending:await _upload()
		else:_set_status("เซฟในเครื่องตรงกับบัญชีแล้ว")
	busy = false;status_changed.emit()

func _upload():
	var data := Store.capture(user_id)
	if not Store.valid(data):_set_status("รูปแบบเซฟไม่ถูกต้อง ยังไม่ส่งขึ้นบัญชี");_send_after = 30;return
	var sent_sequence := _sequence
	var r := await _request("/rest/v1/rpc/game_write_save", HTTPClient.METHOD_POST, {"p_expected_revision":revision,"p_payload":data}, true)
	if not r.ok:
		_send_after = 30;_set_status("ซิงก์ไม่สำเร็จ เก็บเซฟในเครื่องแล้ว และจะลองใหม่เมื่อเชื่อมต่อได้");return
	var result = r.get("data")
	if not result is Dictionary or not result.get("revision") is float and not result.get("revision") is int:
		_send_after = 30;_set_status("ยังยืนยันการซิงก์ไม่ได้ เก็บเซฟในเครื่องไว้แล้ว");return
	if not result.get("ok", false):
		conflict = true;_remote = await _fetch_remote()
		_set_status("อีกเครื่องมีเซฟใหม่กว่า กลับหน้าเลือกตัวละครเพื่อเลือกเซฟ โดยยังไม่เขียนทับกัน");return
	revision = int(result.revision)
	pending = _sequence != sent_sequence
	_send_after = 3.0;_save_meta()
	_set_status("บันทึกเข้าบัญชีแล้ว — เล่นต่อจากเครื่องอื่นได้" if not pending else "กำลังรอซิงก์การเปลี่ยนแปลงล่าสุด")

func resolve_conflict(use_local: bool):
	if busy or not conflict or not on_title():return
	busy = true;status_changed.emit()
	var row := await _fetch_remote()
	if not row.ok:busy = false;_set_status("ตรวจเซฟล่าสุดไม่ได้ กรุณาลองใหม่");return
	if use_local:
		var backup_path := storage_prefix() + "remote_conflict_%d.json" % Time.get_ticks_usec()
		var backup := FileAccess.open(backup_path, FileAccess.WRITE)
		if backup == null:busy = false;_set_status("สร้างสำเนาเซฟบัญชีไม่สำเร็จ ยังไม่เขียนทับ");return
		backup.store_string(JSON.stringify(row.payload));backup.close()
		revision = int(row.revision);conflict = false;hydrated = true
		mark_dirty();await _upload()
	else:
		if Store.install(user_id, row.payload):
			revision = int(row.revision);pending = false;conflict = false;hydrated = true
			_save_meta();Game.character_ready = false;Game.slot = Game.last_slot();saves_changed.emit()
			_set_status("ใช้เซฟจากบัญชีแล้ว เก็บสำเนาเซฟเดิมในเครื่องไว้ให้")
		else:_set_status("เขียนเซฟไม่สำเร็จ เซฟเดิมยังมีสำเนาเก็บไว้")
	busy = false;status_changed.emit()

func import_guest():
	if busy or not hydrated or conflict or not on_title():return
	var local := Store.capture("")
	var account := Store.capture(user_id)
	var incoming: Array = []
	var free: Array = []
	for i in Game.MAX_SLOTS:
		if local.slots[i] != null:incoming.append(local.slots[i])
		if account.slots[i] == null:free.append(i)
	if incoming.is_empty():_set_status("ไม่มีตัวละครจากเซฟเดิมในเครื่องนี้");return
	if incoming.size() > free.size():_set_status("ช่องตัวละครในบัญชีไม่พอ ยังไม่คัดลอกหรือเขียนทับตัวละครใด");return
	for i in incoming.size():account.slots[free[i]] = incoming[i]
	if not Store.install(user_id, account):_set_status("คัดลอกไม่สำเร็จ เซฟเดิมยังอยู่");return
	Game.character_ready = false;mark_dirty();saves_changed.emit()
	await sync()

func sign_out():
	if busy or user_id.is_empty() or not on_title():return
	busy = true;status_changed.emit()
	await _request("/rest/v1/rpc/game_sign_out",HTTPClient.METHOD_POST,{"p_session_token":_token})
	user_id = "";username = "";_token = "";_session_expired = false
	_notify_web_account()
	hydrated = false;pending = false;conflict = false;revision = 0;_remote = {}
	Game.character_ready = false;Game.slot = Game.last_slot()
	busy = false;saves_changed.emit();_set_status("ออกจากบัญชีแล้ว กลับมาใช้เซฟเดิมของเครื่องนี้")
