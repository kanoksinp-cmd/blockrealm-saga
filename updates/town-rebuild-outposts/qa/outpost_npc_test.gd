extends SceneTree
func _initialize():
	await process_frame
	var Game = root.get_node("Game")
	Game.slot = 0; Game.new_character("Npc", load("res://scripts/voxel/avatar.gd").default_appearance())
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main); current_scene = main
	for i in 3: await process_frame
	var vb = main.get_node("StarterVillage"); var hud = main.get_node("HUD")
	vb.ensure_area("desert_d")
	var player = main.get_node_or_null("Player")
	for n in vb.get_node("Area_desert_d").get_children():
		if n.get("role") in ["smith", "shop"] and String(n.npc_name) != "":
			n._role_dialog(hud, player)
			var labels := []
			for b in hud._dialog_buttons.get_children(): labels.append(b.text)
			print(n.npc_name, " (", TranslationServer.translate(n.npc_name), ") -> ", hud._dialog_name.text, " ", labels)
			if n.role == "smith":
				hud._dialog_buttons.get_child(5).pressed.emit(); await process_frame
				print("  smith fashion tab opens: ", hud._smith.panel.visible, " tab=", hud._smith_tab)
				hud._smith.panel.hide()
			else:
				hud._dialog_buttons.get_child(0).pressed.emit(); await process_frame
				print("  shop opens: ", hud._shop.panel.visible if hud.get("_shop") else "?")
	quit()
