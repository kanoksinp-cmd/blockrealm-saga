extends SceneTree
func _initialize() -> void: call_deferred("check")
func frames(n:=5) -> void:
	for i in n: await process_frame
func wait_gather(player, limit:=600) -> void:
	for i in limit:
		if player.is_gathering(): return
		if i%15==0: player._auto_think()
		await physics_frame
	assert(false,"walk-to-ore did not start mining")
func drain(player,node,limit:=900) -> void:
	for i in limit:
		if not node.is_ready(): return
		if i%15==0: player._auto_think()
		await physics_frame
	assert(false,"ore never harvested")
func check() -> void:
	await process_frame
	var game=root.get_node("Game")
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await frames()
	var ui=game.ui
	root.mode=Window.MODE_WINDOWED
	root.min_size=Vector2i.ZERO
	if ui.get("_touch_ready") == true:
		for size in [Vector2i(1055,488),Vector2i(844,450)]:
			root.size=size
			await frames()
			ui.toggle(ui._wmap.panel)
			await frames(10)
			ui._fit_windows()
			await frames()
			var image:Rect2=ui._wmap_img.get_global_rect()
			var view:Rect2=ui._touch_map_view.get_global_rect()
			var scroll:Rect2=ui._wmap.panel.get_meta("touch_scroll").get_global_rect()
			assert(is_equal_approx(image.size.x,image.size.y))
			assert(image.position.is_equal_approx(view.position))
			assert(image.size.is_equal_approx(view.size))
			assert(scroll.grow(1).encloses(image),"map clipped: "+str(image)+" scroll "+str(scroll))
			assert(ui._wmap_img.size==Vector2(512,512))
			var center:Vector3=ui._wmap_to_world(Vector2(256,256))
			assert(Vector2(center.x,center.z).is_equal_approx(ui._wm_center))
			ui._wmap_world=true
			ui._fill_worldmap()
			await frames()
			assert(ui._wmap_img.get_global_rect().size.is_equal_approx(view.size))
			ui._wmap_world=false
			ui._wmap.panel.hide()
			print("PASS_MAP full image, frame and tap coordinates ",size)
	var player=get_first_node_in_group("player")
	player.set_process(false)
	for monster in get_nodes_in_group("monster"):
		monster.set_process(false)
		monster.set_physics_process(false)
	var ore
	for node in get_nodes_in_group("gather_node"):
		if node.kind=="ore":
			if ore==null:ore=node
			else:node.charges=0
	assert(ore!=null)
	ore.charges=2
	ore.table=[["iron_ore",1.0,1,1]]
	var village=scene.get_node("StarterVillage")
	var start:Vector3=village.safe_position(ore.stand_spot+Vector3(0,0,5),"town",12)
	assert(start!=Vector3.INF)
	player.global_position=start+Vector3(0,0.1,0)
	game.auto_on=false
	player.talk_to(ore)
	ui._set_quest_auto(true)
	game.auto_quest_target="Slime"
	player.toggle_auto()
	assert(not ui._quest_auto and game.auto_quest_target=="")
	assert(player.interact_target==ore,"AUTO erased selected ore")
	assert(player._auto_gather_kind=="ore")
	await wait_gather(player)
	player.toggle_auto()
	assert(not game.auto_on and not player.is_gathering())
	# Enable while already mining: preserve both target and work progress.
	player.talk_to(ore)
	await wait_gather(player)
	player._update_gather(0.4)
	var progress:float=player._gather.t
	var before:int=game.count("iron_ore")
	player.toggle_auto()
	assert(player.is_gathering() and is_equal_approx(player._gather.t,progress))
	player._auto_think()
	assert(player.attack_target==null and player.is_gathering())
	await drain(player,ore)
	assert(game.count("iron_ore")>=before+2)
	print("PASS_GATHER walk, enable AUTO mid-mine, preserve progress, harvest two charges")
	var next=load("res://scripts/world/gather_node.gd").new()
	next.kind="ore"
	next.charges=1
	next.table=[["iron_ore",1.0,1,1]]
	var spot:Vector3=village.safe_position(ore.global_position+Vector3(0,0,7),"town",12)
	assert(spot!=Vector3.INF)
	next.position=spot
	next.stand_spot=village.safe_position(spot+Vector3(2,0,0),"town",12)
	scene.add_child(next)
	var anchor:Vector3=player._auto_gather_anchor
	player._auto_think()
	assert(player.interact_target==next)
	assert(player._auto_gather_anchor==anchor)
	await wait_gather(player)
	await drain(player,next)
	assert(game.count("iron_ore")>=before+3)
	player._auto_think()
	assert(player._auto_gather_waiting and player.attack_target==null)
	next.charges=1
	player._auto_think()
	assert(player.interact_target==next,"ready ore should resume after waiting")
	player._unreachable[next.get_instance_id()]=Time.get_ticks_msec()/1000.0+15
	player._stop_all(true)
	player._auto_think()
	assert(player._auto_gather_kind=="ore" and player.interact_target==null and player.attack_target==null)
	player._unreachable[next.get_instance_id()]=0
	player._auto_think()
	assert(player.interact_target==next)

	player.toggle_auto()
	assert(not game.auto_on and player.interact_target==null)
	player.go_to(player.global_position+Vector3(0,0,3),false)
	assert(player._auto_gather_kind=="")
	print("PASS_AUTO_GATHER next vein, stable area anchor, waiting/resume and explicit cancel")
	player._stop_all()
	player.global_position=Vector3(0,0.1,8)
	game.auto_on=false
	game.auto_cfg.monster=""
	game.auto_cfg.range=30
	game.auto_cfg.skills=false
	game.auto_cfg.buffs=false
	var monster=load("res://scripts/monsters/monster.gd").new()
	monster.display_name="Auto regression"
	monster.level=1
	scene.add_child(monster)
	monster.global_position=player.global_position+Vector3(4,0,0)
	monster.set_process(false)
	monster.set_physics_process(false)
	player.toggle_auto()
	assert(game.auto_on and player._auto_gather_kind=="")
	assert(player.attack_target==monster,"ordinary AUTO hunting must still select monsters")
	print("PASS_AUTO_COMBAT normal hunt mode retained")
	quit()
