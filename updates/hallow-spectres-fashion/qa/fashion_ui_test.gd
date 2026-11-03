extends SceneTree
func _initialize():
	await process_frame
	var Game = root.get_node("Game")
	var a = load("res://scripts/voxel/avatar.gd").default_appearance(); a.job = "archer"
	Game.slot = 0; Game.new_character("UI", a)
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main); current_scene = main
	for i in 3: await process_frame
	var hud = main.get_node("HUD")
	hud._open_mage_fashion()
	print("menu title=", hud._dialog_name.text, " visible=", hud._dialog.panel.visible, " buttons=", hud._dialog_buttons.get_child_count())
	print("menu text=", hud._dialog_text.text.replace("\n"," / "))
	var labels := []
	for b in hud._dialog_buttons.get_children(): labels.append(b.text)
	print("choices=", labels)
	hud._fashion_detail("bone_oracle")
	print("detail(locked)=", hud._dialog_name.text, " | ", hud._dialog_text.text.replace("\n"," / ").left(300))
	Game.fashion_unlocks.append("bone_oracle")
	hud._fashion_detail("bone_oracle")
	var b0: Button = hud._dialog_buttons.get_child(0); print("detail(owned) first button=", b0.text)
	b0.pressed.emit()
	await process_frame
	print("worn after click=", Game.worn_fashion(), " INT=", Game.st("INT"))
	hud._smith_tab = 7
	hud._fill_smith()
	var names := []
	for c in hud._smith_list.find_children("*", "Label", true, false):
		if "•" in c.text or "Hallow" in c.text: names.append(c.text.left(70))
	print("smith fashion tab labels=", names)
	quit()
