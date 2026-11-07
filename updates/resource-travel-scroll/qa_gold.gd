extends SceneTree
var ui
var player
var game
var items
func _initialize() -> void: call_deferred("check")
func frames(n:=5) -> void:
	for i in n: await process_frame
func check() -> void:
	await process_frame
	game=root.get_node("Game")
	items=load("res://scripts/game/items.gd")
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await frames()
	ui=game.ui
	player=get_first_node_in_group("player")
	player.set_process(false)
	player.move_speed=24
	game.auto_cfg.travel_warp=false
	game.auto_on=false
	await player.warp({"to":"smithy","dest":Vector3(160.5,0,85.5)})
	game.job="swordsman"
	game.base_level=49
	game.hp=game.max_hp()
	ui.open_smith("Blacksmith Doran")
	ui._smith_tab=7
	ui._fill_smith()
	await frames()
	var find_button:Button
	for label in ui._smith_list.find_children("*","Label",true,false):
		if not label.text.contains(items.item_name("gold_ore")):continue
		for child in label.get_parent().get_parent().get_children():
			if child is Button and child.text=="Find":
				find_button=child
		if find_button:break
	assert(find_button!=null,"no actual gold Find button in fashion recipes")
	find_button.pressed.emit()
	assert(game.auto_on and player._auto_gather_item=="gold_ore")
	assert(player._auto_gather_area=="desert")
	assert(not ui._smith.panel.visible)
	var visited:Array[String]=[player.area]
	var vein
	for i in 4000:
		for enemy in get_nodes_in_group("monster"):
			enemy.set_process(false)
			enemy.set_physics_process(false)
		if i%10==0:player._auto_think()
		if not player.area in visited:visited.append(player.area)
		if player.is_gathering():
			vein=player._gather.node
			break
		await physics_frame
	assert(vein!=null,"Find failed to reach gold vein; area="+player.area+" target="+str(player._target))
	assert(visited.has("town") and visited.has("desert"),str(visited))
	var has_gold:=false
	for entry in vein.table:
		if entry[0]=="gold_ore":has_gold=true
	assert(has_gold)
	assert(player._auto_gather_item=="gold_ore")
	vein.table=[["gold_ore",1.0,1,1]]
	vein.charges=1
	var before:int=game.count("gold_ore")
	for i in 300:
		if game.count("gold_ore")>before:break
		if i%10==0:player._auto_think()
		await physics_frame
	assert(game.count("gold_ore")>before,"gold harvest did not reach inventory")
	print("PASS_GOLD_FIND actual fashion recipe button -> smithy exit -> town -> desert -> mine -> gold inventory; ",visited)
	player._stop_all()
	game.auto_on=false
	assert(player._auto_gather_item=="")
	assert(player.start_resource_trip("copper_ore"))
	assert(player._auto_gather_area=="town")
	assert(player._has_target)
	player.go_to(player.global_position+Vector3(1,0,0),false)
	assert(player._auto_gather_item=="", "manual walking must cancel material trip")
	print("PASS_RESOURCE_ROUTE town fallback and manual cancellation")
	quit()
