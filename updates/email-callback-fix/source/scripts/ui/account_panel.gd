extends VBoxContainer
## Shared account UI for the title screen and Options.
var _address := ""
var _code := ""
var _show_manual := false
var _confirm: ConfirmationDialog

func _ready():
	add_theme_constant_override("separation", 9)
	CloudAccount.status_changed.connect(_render)
	_render()

func _label(text: String, size := 15):
	var l := Label.new();l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	add_child(l)
	return l

func _button(text: String, action: Callable, disabled := false):
	var b := Button.new();b.text = text;b.custom_minimum_size.y = 38
	b.disabled = disabled or CloudAccount.busy
	b.pressed.connect(action);add_child(b)
	return b

func _ask(text: String, action: Callable):
	if is_instance_valid(_confirm):_confirm.queue_free()
	_confirm = ConfirmationDialog.new();_confirm.dialog_text = text
	_confirm.title = "ยืนยันการเลือกเซฟ"
	_confirm.ok_button_text = "ยืนยัน";_confirm.cancel_button_text = "ยกเลิก"
	_confirm.confirmed.connect(action)
	add_child(_confirm);_confirm.popup_centered(Vector2i(430,180))

func _render():
	for c in get_children():
		if c == _confirm:continue
		remove_child(c);c.queue_free()
	_label("บัญชีอีเมลและเซฟข้ามเครื่อง",20)
	_label(CloudAccount.status)
	if not CloudAccount.configured():
		_label("การเชื่อมบัญชียังไม่เปิดให้บริการ เล่นด้วยเซฟในเครื่องได้ตามเดิม")
		return
	if CloudAccount.test_only:_label("อยู่ระหว่างทดสอบกับอีเมลที่ได้รับอนุญาต ยังไม่เปิดรับผู้เล่นทั่วไป",13)
	if not CloudAccount.on_title():
		_label("กลับหน้าเลือกตัวละครเพื่อเข้าสู่ระบบ เปลี่ยนบัญชี หรือจัดการเซฟ")
		if not CloudAccount.user_id.is_empty():
			_label(CloudAccount.email)
			_button("บันทึกและซิงก์ตอนนี้", CloudAccount.sync, CloudAccount.conflict)
		return
	if CloudAccount.user_id.is_empty():
		_label("ยืนยันอีเมลเพื่อเชื่อมบัญชี ไม่ต้องตั้งรหัสผ่าน")
		var address := LineEdit.new();address.placeholder_text = "อีเมล";address.text = _address
		address.max_length = 254;address.editable = not CloudAccount.busy
		address.text_changed.connect(func(value):_address = value)
		add_child(address)
		_button("ส่งอีเมลยืนยัน",func():CloudAccount.request_code(_address))
		if OS.has_feature("web"):_label("เปิดอีเมลฉบับล่าสุด แล้วกด Confirm email address หรือ Sign in ระบบจะกลับเข้าเกมเอง ใช้เบราว์เซอร์เดียวกับที่ขออีเมล",13)
		else:_label("ในอีเมล คลิกขวาปุ่ม Sign in หรือ Confirm your email → คัดลอกลิงก์ แล้ววางด้านล่าง โดยยังไม่กดเปิดลิงก์",13)
		if OS.has_feature("web"):_button("ซ่อนช่องยืนยันด้วยตนเอง" if _show_manual else "กรอกรหัสหรือลิงก์ด้วยตนเอง",func():_show_manual = not _show_manual;_render())
		if _show_manual or not OS.has_feature("web"):
			var code := LineEdit.new();code.placeholder_text = "วางลิงก์ยืนยันจากอีเมล" if CloudAccount.test_only else "รหัสยืนยันจากอีเมล";code.text = _code
			code.max_length = 2048;code.secret = true;code.editable = not CloudAccount.busy
			code.text_changed.connect(func(value):_code = value)
			add_child(code)
			_button("ยืนยันและเข้าสู่ระบบ",func():CloudAccount.verify_code(_address,_code))
		_label("เซฟเดิมในเครื่องจะยังอยู่ หลังเข้าสู่ระบบสามารถเลือกคัดลอกเข้าบัญชีได้",13)
	else:
		_code = ""
		_label(CloudAccount.email)
		_label("ใช้บัญชีอีเมลเดียวกันบนเครื่องอื่น แล้วรอให้ดาวน์โหลดเซฟก่อนเข้าเล่น",13)
		_label("ก่อนเปลี่ยนเครื่อง กดซิงก์และรอข้อความ ‘บันทึกเข้าบัญชีแล้ว’",13)
		if CloudAccount.conflict:
			_label("เลือกเซฟที่จะใช้ ระบบจะเก็บสำเนาเซฟเดิมในเครื่องไว้ก่อนเปลี่ยน")
			_button("ใช้เซฟล่าสุดจากบัญชี",func():_ask("ใช้เซฟจากบัญชีแทนเซฟที่ค้างอยู่ในเครื่องนี้?",func():CloudAccount.resolve_conflict(false)))
			_button("ใช้เซฟเครื่องนี้แทนในบัญชี",func():_ask("ส่งเซฟเครื่องนี้แทนเซฟในบัญชี? เครื่องอื่นจะต้องดาวน์โหลดฉบับนี้ใหม่",func():CloudAccount.resolve_conflict(true)))
		else:
			_button("ซิงก์เซฟตอนนี้",CloudAccount.sync)
			_button("คัดลอกตัวละครเดิมในเครื่องเข้าบัญชี",func():_ask("คัดลอกตัวละครจากเซฟเดิมของเครื่องนี้ลงช่องว่างในบัญชี? เซฟต้นฉบับจะยังอยู่ และตัวละครในบัญชีจะไม่ถูกเขียนทับ",CloudAccount.import_guest),not CloudAccount.hydrated)
		_button("ออกจากบัญชี",func():_ask("ออกจากบัญชีบนเครื่องนี้? หากยังมีเซฟค้างซิงก์ จะเก็บไว้ในเครื่องเพื่อส่งเมื่อเข้าสู่บัญชีเดิมอีกครั้ง",CloudAccount.sign_out))

static func open(owner: Node):
	var dialog := AcceptDialog.new();dialog.title = "บัญชีอีเมล"
	dialog.ok_button_text = "ปิด";dialog.min_size = Vector2i(510,450)
	var scroll := ScrollContainer.new();scroll.custom_minimum_size = Vector2(480,400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog.add_child(scroll)
	var panel = load("res://scripts/ui/account_panel.gd").new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL;scroll.add_child(panel)
	owner.add_child(dialog);dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free)
