extends SceneTree
func _initialize():
	change_scene_to_file("res://scenes/character_create.tscn") if ResourceLoader.exists("res://scenes/character_create.tscn") else null
	await create_timer(3.0).timeout
	var ca = root.get_node("CloudAccount")
	var scene = current_scene
	print("scene=", scene.name if scene else "none", " can_play(guest)=", ca.can_play())
	ca.user_id = "test_user"; ca.hydrated = false; ca.conflict = false
	ca.status = "ยังอ่านเซฟจากบัญชีไม่ได้ (TEST)"
	var before := root.get_child_count() + scene.get_child_count()
	ca.endpoint = "https://127.0.0.1:1"   # keep the retry offline
	scene._slot_action()
	await process_frame
	var dialogs := 0
	for n in scene.get_children(): if n is AcceptDialog: dialogs += 1
	print("entering=", scene._entering_game, " dialogs=", dialogs, " toast='", scene._toast.text, "' busy_after_retry=", ca.busy)
	quit()
