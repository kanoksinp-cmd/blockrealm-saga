extends SceneTree
var clicks:=0
var ui
var hud
func _initialize() -> void: call_deferred("check")
func frames(n:=5) -> void:
	for i in n: await process_frame
func touch(id:int,down:bool,pos:Vector2) -> void:
	var event:=InputEventScreenTouch.new()
	event.index=id
	event.pressed=down
	event.position=pos
	root.push_input(event,true)
func mouse(down:bool,pos:Vector2) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.device=InputEvent.DEVICE_ID_EMULATION
	motion.position=pos
	motion.global_position=pos
	root.push_input(motion,true)
	var event:=InputEventMouseButton.new()
	event.device=InputEvent.DEVICE_ID_EMULATION
	event.button_index=MOUSE_BUTTON_LEFT
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed=down
	event.position=pos
	event.global_position=pos
	root.push_input(event,true)
func drag(id:int,pos:Vector2,relative:Vector2) -> void:
	var event:=InputEventScreenDrag.new()
	event.index=id
	event.position=pos
	event.relative=relative
	root.push_input(event,true)
func begin(id:int,pos:Vector2) -> void:
	touch(id,true,pos)
	mouse(true,pos)
func finish(id:int,pos:Vector2) -> void:
	touch(id,false,pos)
	mouse(false,pos)
func check() -> void:
	await process_frame
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await frames()
	ui=root.get_node("Game").ui
	hud=ui._mobile_hud
	var fixture=ui._window("Scroll regression",Vector2.ZERO,Vector2(650,0))
	fixture.panel.hide()
	var horizontal:=ScrollContainer.new()
	horizontal.custom_minimum_size=Vector2(500,72)
	horizontal.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var row:=HBoxContainer.new()
	for i in 12:
		row.add_child(ui._button("H"+str(i),func():clicks+=1,90))
	horizontal.add_child(row)
	fixture.body.add_child(horizontal)
	var vertical:=ScrollContainer.new()
	vertical.custom_minimum_size=Vector2(500,72)
	vertical.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var column:=VBoxContainer.new()
	for i in 10:column.add_child(ui._button("V"+str(i),func():clicks+=1,200))
	vertical.add_child(column)
	fixture.body.add_child(vertical)
	var buttons:Array=[]
	for i in 12:
		var button=ui._button("Find regression "+str(i),func():clicks+=1,450)
		buttons.append(button)
		fixture.body.add_child(button)
	fixture.panel.show()
	ui._fit_windows()
	await frames(10)
	var outer:ScrollContainer=fixture.panel.get_meta("touch_scroll")
	outer.get_v_scroll_bar().value=100
	await frames()
	var start:Vector2=buttons[1].get_global_rect().get_center()
	assert(outer.get_global_rect().has_point(start))
	var origin:Vector2=fixture.panel.position
	begin(0,start)
	drag(0,start+Vector2(2,-50),Vector2(2,-50))
	assert(hud._sc_active and hud._sc_axis==1)
	assert(absf(outer.get_v_scroll_bar().value-150)<1.1)
	ui._fit_windows()
	assert(fixture.panel.position==origin,"window moved during finger drag")
	drag(0,start+Vector2(-4,-20),Vector2(-6,30))
	assert(absf(outer.get_v_scroll_bar().value-120)<1.1)
	finish(0,start+Vector2(-4,-20))
	var stopped:=outer.get_v_scroll_bar().value
	for i in 30:hud._update_fling(0.033)
	assert(outer.get_v_scroll_bar().value==stopped)
	assert(clicks==0,"swiping over buttons activated a button")
	print("PASS_SCROLL exact up/down displacement, no inertia jump, fixed panel and no accidental button")
	start=buttons[1].get_global_rect().get_center()
	begin(1,start)
	finish(1,start)
	await frames()
	assert(clicks==1,"a stationary tap must activate exactly once")
	clicks=0
	outer.get_v_scroll_bar().value=0
	await frames()
	start=horizontal.get_global_rect().get_center()
	begin(2,start)
	drag(2,start+Vector2(3,-40),Vector2(3,-40))
	assert(hud._sc==outer,"vertical swipe chose nested horizontal list")
	assert(outer.get_v_scroll_bar().value>0 and horizontal.get_h_scroll_bar().value==0)
	finish(2,start+Vector2(3,-40))
	outer.get_v_scroll_bar().value=0
	await frames()
	start=horizontal.get_global_rect().get_center()
	begin(3,start)
	drag(3,start+Vector2(-60,3),Vector2(-60,3))
	assert(hud._sc==horizontal and hud._sc_axis==2)
	assert(horizontal.get_h_scroll_bar().value>0 and outer.get_v_scroll_bar().value==0)
	finish(3,start+Vector2(-60,3))
	outer.get_v_scroll_bar().value=0
	vertical.get_v_scroll_bar().value=vertical.get_v_scroll_bar().max_value-vertical.get_v_scroll_bar().page
	await frames()
	start=vertical.get_global_rect().get_center()
	begin(4,start)
	drag(4,start+Vector2(0,-40),Vector2(0,-40))
	assert(outer.get_v_scroll_bar().value>0,"nested edge did not pass movement to enclosing list")
	finish(4,start+Vector2(0,-40))
	assert(clicks==0)
	print("PASS_NESTED axis lock, parent selection, horizontal controls and edge handoff")
	fixture.panel.hide()
	ui.toggle(ui._inv.panel)
	await frames(10)
	var item=ui._inv_grid.get_child(0)
	start=item.get_global_rect().get_center()
	begin(5,start)
	assert(not is_instance_valid(ui._menu_layer),"item opened on finger-down")
	finish(5,start)
	await frames()
	assert(is_instance_valid(ui._menu_layer),"item did not open on completed tap")
	ui._close_item_menu()
	print("PASS_ITEM release-only item actions")
	quit()
