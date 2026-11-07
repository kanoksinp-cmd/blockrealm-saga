extends SceneTree
var taps := 0
func _initialize() -> void: call_deferred("check")
func frames(n:=5) -> void:
	for i in n: await process_frame
func finger(id: int, pressed: bool, at: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index=id
	event.pressed=pressed
	event.position=at
	return event
func check() -> void:
	await process_frame
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await frames()
	var ui=root.get_node("Game").ui
	var mobile := OS.get_environment("BR_MOBILE")=="1"
	assert(ui._menu.get_child_count()==6)
	if not mobile:
		assert(ui.get("_touch_ready")==null)
		assert(ui.get_script().resource_path=="res://scripts/ui/ro_ui.gd")
		print("PASS_PC classic desktop path unchanged")
		quit()
		return
	assert(ui._touch_ready)
	var hud=ui._mobile_hud
	assert(hud._skill_btns.size()==4)
	assert(hud._item_btns.size()==2)
	for button in hud._skill_btns+hud._item_btns+[hud._page_btn,hud._auto]:
		assert(button.square and button.size==Vector2(54,54))
	for i in 3: hud._page_btn.tapped.emit()
	assert(hud._page==3)
	hud._page_btn.tapped.emit()
	assert(hud._page==0)
	root.get_node("Game").hotbar[0]="potion_red"
	hud._skill_btns[0].tapped.connect(func(): taps+=1)
	hud._gui_input(finger(0,true,Vector2(100,hud.size.y-115)))
	assert(hud._joy_idx==0)
	hud._skill_btns[0]._gui_input(finger(1,true,Vector2(27,27)))
	assert(taps==1 and hud._joy_idx==0)
	hud._skill_btns[0]._gui_input(finger(1,false,Vector2(27,27)))
	assert(hud._joy_idx==0)
	ui._menu.get_child(1).pressed.emit()
	await frames()
	assert(ui._inv.panel.visible and hud._ui_blocked)
	assert(hud._joy_idx==-1 and hud._skill_btns[0]._down==-1)
	assert(ui._inv.panel.scale==Vector2.ONE)
	ui._inv.panel.hide()
	await frames()
	assert(not hud._ui_blocked)
	hud._toggle_chat()
	assert(ui._chat_panel.visible and not hud._dock.visible and not hud._attack.visible)
	hud._toggle_chat()
	assert(hud._dock.visible and hud._attack.visible)
	ui.toggle(ui._settings.panel)
	await frames()
	var scroll=ui._settings.panel.get_meta("touch_scroll")
	scroll.get_v_scroll_bar().value=0
	hud._sc=scroll
	hud._sc_idx=3
	hud._sc_start=scroll.get_global_rect().get_center()
	var drag:=InputEventScreenDrag.new()
	drag.index=3
	drag.position=hud._sc_start+Vector2(0,-120)
	drag.relative=Vector2(0,-120)
	hud._input(drag)
	assert(scroll.get_v_scroll_bar().value>0,"settings must scroll by finger")
	ui._settings.panel.hide()
	await frames()
	root.get_node("Game").message.emit("ทดสอบข้อความ",Color.WHITE)
	await frames()
	assert(ui._toast.visible)
	print("PASS_TOUCH four skill pages, simultaneous fingers, gesture reset, modal/input block, chat and scrolling")
	quit()
