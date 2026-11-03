extends SceneTree
func _initialize():
	change_scene_to_file("res://scenes/character_create.tscn")
	await create_timer(2.0).timeout
	var ca = root.get_node("CloudAccount"); var Game = root.get_node("Game")
	ca.endpoint = "http://127.0.0.1:8099"
	if OS.get_environment("PENDING") == "1":
		# simulate unsynced local changes from an older revision on this device
		var meta := ConfigFile.new(); meta.set_value("cloud","revision",3); meta.set_value("cloud","pending",true)
		DirAccess.make_dir_recursive_absolute("user://accounts/11111111-2222-3333-4444-555555555555/")
		meta.save("user://accounts/11111111-2222-3333-4444-555555555555/sync.cfg")
	var ok = await ca.accept_game_session({"session_token":"a".repeat(64),"expected_username":"guide"})
	print("login=",ok," hydrated=",ca.hydrated," conflict=",ca.conflict," can_play=",ca.can_play()," status=",ca.status)
	print("slot0=",Game.save_summary(0))
	var scene = current_scene
	scene._select_slot(0); scene._slot_action()
	await process_frame
	print("entering_game=",scene._entering_game," level=",Game.base_level," name=",Game.player_name)
	quit()
