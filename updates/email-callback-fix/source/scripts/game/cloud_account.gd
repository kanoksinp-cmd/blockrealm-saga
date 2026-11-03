extends Node
## Email OTP and revision-checked account saves. Session tokens stay in memory.
signal status_changed
signal saves_changed
signal auth_attention
const Store = preload("res://scripts/game/account_save_store.gd")
var endpoint := ""
var public_key := ""
var test_only := true
var redirect_url := "https://kanoksinp-cmd.github.io/blockrealm-saga/play/index.html"
var user_id := ""
var email := ""
var status := "เล่นด้วยเซฟในเครื่อง"
var busy := false
var hydrated := false
var conflict := false
var pending := false
var revision := 0
var _token := ""
var _refresh_token := ""
var _expires := 0.0
var _remote := {}
var _sequence := 0
var _send_after := 0.0
var _otp_after := 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load("res://account_config.cfg") == OK:
		endpoint = String(cfg.get_value("supabase", "url", "")).trim_suffix("/")
		public_key = String(cfg.get_value("supabase", "publishable_key", ""))
		test_only = bool(cfg.get_value("supabase", "test_only", true))
	# Never accept a secret/service-role key as a public client setting.
	if public_key.begins_with("sb_secret_"):public_key = ""
	if public_key.begins_with("eyJ"):
		var parts := public_key.split(".")
		if parts.size() != 3:public_key = ""
		else:
			var encoded := parts[1].replace("-", "+").replace("_", "/")
			while encoded.length() % 4 != 0:encoded += "="
			var claims = JSON.parse_string(Marshalls.base64_to_utf8(encoded))
			if not claims is Dictionary or claims.get("role") != "anon":public_key = ""
	call_deferred("_consume_email_callback")

func _bridge_js(action: String, value := ""):
	if not OS.has_feature("web"):return null
	var js := "(function(){try{var b=window.BlockrealmAccountBridge;if(!b)return '';"
	if action == "remember":js += "return b.remember(" + JSON.stringify(value) + ");"
	elif action == "clear":js += "b.clear();return '';"
	else:js += "return b.take();"
	return JavaScriptBridge.eval(js + "}catch(e){return '';}})()", true)

func _consume_email_callback():
	if not OS.has_feature("web"):return
	await get_tree().process_frame
	var raw = _bridge_js("take")
	if not raw is String or raw.is_empty():return
	var parsed := JSON.new()
	if parsed.parse(raw) != OK or not parsed.data is Dictionary:return
	var grant: Dictionary = parsed.data
	if grant.has("error"):
		_set_status("ลิงก์ยืนยันหมดอายุหรือถูกใช้แล้ว กรุณาขออีเมลฉบับใหม่และเปิดเฉพาะลิงก์ล่าสุด" if grant.error != "request_missing" else "กรุณาขออีเมลจากเกมในเบราว์เซอร์นี้ แล้วเปิดอีเมลฉบับใหม่ในเบราว์เซอร์เดียวกัน")
	else:
		await accept_email_callback(grant)
	auth_attention.emit()

func accept_email_callback(grant: Dictionary) -> bool:
	if busy or not on_title():return false
	if not grant.get("expected_email") is String or grant.expected_email.is_empty():return false
	if not grant.get("access_token") is String or grant.access_token.is_empty() or grant.access_token.length() > 16384:return false
	if not grant.get("refresh_token") is String or grant.refresh_token.length() > 16384:return false
	if not grant.get("type") in ["email","signup","magiclink"]:return false
	busy = true;_set_status("กำลังตรวจยืนยันอีเมลและโหลดเซฟบัญชี")
	# Verify the callback's bearer with Supabase; never trust URL identity claims.
	var reply := await _raw("/auth/v1/user", HTTPClient.METHOD_GET, null, grant.access_token)
	if not reply.ok or not reply.get("data") is Dictionary:
		busy = false;_set_status("ตรวจยืนยันอีเมลไม่ได้ กรุณาขออีเมลใหม่");return false
	var user: Dictionary = reply.data
	if String(user.get("email", "")).to_lower() != String(grant.expected_email).to_lower() or user.get("email_confirmed_at") == null:
		busy = false;_set_status("อีเมลที่ยืนยันไม่ตรงกับคำขอในเครื่องนี้ กรุณาขออีเมลใหม่จากเกม");return false
	var duration = grant.get("expires_in",3600)
	if not (duration is int or duration is float):duration = 3600
	if not _accept_session({"user":user,"access_token":grant.access_token,"refresh_token":grant.refresh_token,"expires_in":clampf(float(duration),1,86400)}):
		busy = false;_set_status("ข้อมูลยืนยันบัญชีไม่ถูกต้อง กรุณาขออีเมลใหม่");return false
	_bridge_js("clear")
	await _finish_login()
	busy = false;status_changed.emit()
	return true

func configured() -> bool:
	var secure := endpoint.begins_with("https://")
	var local_test := OS.is_debug_build() and endpoint.begins_with("http://127.0.0.1:")
	return (secure or local_test) and not public_key.is_empty()

func on_title() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.name != "Main"

func can_play() -> bool:
	return not busy and (user_id.is_empty() or (hydrated and not conflict))

func storage_prefix() -> String:
	return Store.prefix(user_id)

func _set_status(text: String):
	status = text
	status_changed.emit()

func _process(delta: float):
	if pending and hydrated and not busy and not conflict:
		_send_after -= delta
		if _send_after <= 0:sync()

func _meta_path() -> String:return storage_prefix() + "sync.cfg"

func _save_meta():
	if user_id.is_empty():return
	DirAccess.make_dir_recursive_absolute(storage_prefix())
	var cfg := ConfigFile.new()
	cfg.set_value("cloud", "revision", revision)
	cfg.set_value("cloud", "pending", pending)
	cfg.save(_meta_path())

func mark_dirty():
	if user_id.is_empty():return
	pending = true
	_sequence += 1
	_send_after = 3.0
	_save_meta()
	_set_status("มีเซฟใหม่ รอซิงก์เข้าบัญชี")

func _request(route: String, method: int, body = null, auth := false) -> Dictionary:
	if auth and Time.get_unix_time_from_system() >= _expires - 30:
		if not await _renew():return {"ok":false,"code":401}
	var reply := await _raw(route, method, body, _token if auth else "")
	if auth and int(reply.code) == 401 and await _renew():
		return await _raw(route, method, body, _token)
	return reply

func _raw(route: String, method: int, body, token: String) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = 20.0
	req.body_size_limit = Store.MAX_BYTES + 16384
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
		"code":reply[1],"data":data}

func _renew() -> bool:
	if _refresh_token.is_empty():return false
	var r := await _raw("/auth/v1/token?grant_type=refresh_token", HTTPClient.METHOD_POST, {"refresh_token":_refresh_token}, "")
	if not r.ok or not _accept_session(r.get("data"), user_id):
		_set_status("การเข้าสู่ระบบหมดอายุ เซฟยังอยู่ในเครื่อง กรุณากลับหน้าเลือกตัวละครและเข้าสู่ระบบใหม่")
		return false
	return true

func _accept_session(data, expected_id := "") -> bool:
	if not data is Dictionary or not data.get("user") is Dictionary:return false
	var id := String(data.user.get("id", ""))
	if not Store.valid_id(id) or (expected_id != "" and id != expected_id):return false
	if not data.get("access_token") is String or data.access_token.is_empty():return false
	_token = data.access_token
	_refresh_token = String(data.get("refresh_token", ""))
	_expires = Time.get_unix_time_from_system() + float(data.get("expires_in", 3600))
	user_id = id
	email = String(data.user.get("email", ""))
	return true

func request_code(address: String):
	if busy or not configured() or not on_title():return
	address = address.strip_edges().to_lower()
	if address.length() > 254 or address.count("@") != 1 or address.contains(" ") or not address.get_slice("@", 1).contains("."):
		_set_status("กรุณากรอกอีเมลให้ถูกต้อง");return
	if Time.get_ticks_msec() / 1000.0 < _otp_after:
		_set_status("กรุณารออย่างน้อย 60 วินาทีก่อนขอรหัสใหม่");return
	busy = true;_set_status("กำลังส่งอีเมลยืนยัน")
	# Remember the requested identity before dispatch: callbacks must match it.
	if OS.has_feature("web") and _bridge_js("remember",address) != true:
		busy = false;_set_status("เบราว์เซอร์ไม่อนุญาตให้จดจำคำขอยืนยัน กรุณาเปิดที่เก็บข้อมูลสำหรับเว็บเกม");return
	var route := "/auth/v1/otp?redirect_to=" + redirect_url.uri_encode()
	var r := await _request(route, HTTPClient.METHOD_POST, {"email":address,"create_user":true})
	busy = false
	if r.ok:
		_otp_after = Time.get_ticks_msec() / 1000.0 + 60
		_set_status("ส่งคำขอแล้ว เปิดอีเมลฉบับล่าสุดแล้วกดปุ่มยืนยัน ระบบจะกลับเข้าเว็บเกมให้" if OS.has_feature("web") else "ส่งคำขอแล้ว ตรวจอีเมลและสแปม แล้วคัดลอกลิงก์ยืนยันมาวางในเกม")
	else:
		var error_code := ""
		if r.get("data") is Dictionary:error_code = String(r.data.get("error_code", r.data.get("code", "")))
		if error_code == "email_address_not_authorized":_set_status("ช่วงทดสอบนี้ยังรับเฉพาะอีเมลที่ได้รับอนุญาต")
		elif r.code == 429:_set_status("ถึงขีดจำกัดการส่งอีเมล กรุณารอแล้วลองใหม่ภายหลัง")
		else:_set_status("ส่งรหัสไม่สำเร็จ กรุณาลองใหม่ภายหลัง")

func verification_body(address: String, code: String) -> Dictionary:
	code = code.strip_edges()
	if code.begins_with(endpoint + "/auth/v1/verify?"):
		var query := {}
		for pair in code.get_slice("?",1).split("&"):
			var at := pair.find("=")
			if at > 0:query[pair.substr(0,at).uri_decode()] = pair.substr(at+1).uri_decode()
		if not String(query.get("type", "email")) in ["email","signup","magiclink"]:return {}
		var hash := String(query.get("token",query.get("token_hash","")))
		var pattern := RegEx.new();pattern.compile("^[a-fA-F0-9]{40,256}$")
		if pattern.search(hash) == null:return {}
		# Verify with Supabase directly; never follow the link's redirect_to value.
		return {"token_hash":hash,"type":"email"}
	var digits := RegEx.new();digits.compile("^[0-9]{6,10}$")
	if digits.search(code) == null:return {}
	return {"email":address.strip_edges().to_lower(),"token":code,"type":"email"}

func verify_code(address: String, code: String):
	if busy or not configured() or not on_title():return
	var body := verification_body(address,code)
	if body.is_empty():_set_status("กรุณาวางลิงก์ยืนยันของเกมนี้ หรือรหัสจากอีเมล");return
	busy = true;_set_status("กำลังยืนยันบัญชี")
	var r := await _request("/auth/v1/verify", HTTPClient.METHOD_POST, body)
	if r.ok and r.get("data") is Dictionary and r.data.get("user") is Dictionary:
		if String(r.data.user.get("email", "")).to_lower() != address.strip_edges().to_lower():
			busy = false;_set_status("อีเมลที่กรอกไม่ตรงกับลิงก์ยืนยัน กรุณาตรวจอีเมลอีกครั้ง");return
	if not r.ok or not _accept_session(r.get("data")):
		busy = false;_set_status("ลิงก์หรือรหัสไม่ถูกต้อง หรือถูกใช้แล้ว กรุณาขออีเมลใหม่");return
	_bridge_js("clear")
	await _finish_login()
	busy = false;status_changed.emit()

func _finish_login():
	var cfg := ConfigFile.new()
	cfg.load(_meta_path())
	revision = int(cfg.get_value("cloud", "revision", 0))
	pending = bool(cfg.get_value("cloud", "pending", false))
	hydrated = false;conflict = false
	await _download()

func _fetch_remote() -> Dictionary:
	var r := await _request("/rest/v1/account_saves?select=revision,payload&user_id=eq." + user_id, HTTPClient.METHOD_GET, null, true)
	if not r.ok or not r.get("data") is Array:return {"ok":false}
	if r.data.is_empty():return {"ok":true,"revision":0,"payload":{"schema":1,"slots":[null,null,null,null,null],"last_slot":0}}
	var row = r.data[0]
	if not row is Dictionary or not row.get("revision") is float and not row.get("revision") is int:return {"ok":false}
	if not Store.valid(row.get("payload")):return {"ok":false}
	return {"ok":true,"revision":int(row.revision),"payload":row.payload}

func _download():
	_set_status("กำลังตรวจเซฟในบัญชี")
	var row := await _fetch_remote()
	if not row.ok:
		_set_status("ยังอ่านเซฟจากบัญชีไม่ได้ เซฟในเครื่องยังปลอดภัย กดซิงก์เพื่อลองใหม่");return
	_remote = row
	if pending:
		if int(row.revision) != revision:
			conflict = true;_set_status("มีเซฟต่างกันระหว่างเครื่อง กรุณาเลือกเซฟที่จะใช้ในหน้าเลือกตัวละคร")
		else:
			hydrated = true
			await _upload()
		return
	if not Store.install(user_id, row.payload):_set_status("เขียนเซฟในเครื่องไม่สำเร็จ ยังไม่เปลี่ยนเซฟในบัญชี");return
	revision = int(row.revision);hydrated = true
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
	var r := await _request("/rest/v1/rpc/save_account", HTTPClient.METHOD_POST, {"expected_revision":revision,"new_payload":data}, true)
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
	# Revoke only this device; other machines remain signed in.
	await _raw("/auth/v1/logout?scope=local", HTTPClient.METHOD_POST, null, _token)
	user_id = "";email = "";_token = "";_refresh_token = "";_expires = 0
	hydrated = false;pending = false;conflict = false;revision = 0;_remote = {}
	Game.character_ready = false;Game.slot = Game.last_slot()
	busy = false;saves_changed.emit();_set_status("ออกจากบัญชีแล้ว กลับมาใช้เซฟเดิมของเครื่องนี้")
