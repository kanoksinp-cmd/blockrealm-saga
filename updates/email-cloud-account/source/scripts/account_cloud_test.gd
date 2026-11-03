extends Node
const Store = preload("res://scripts/game/account_save_store.gd")
var checks := 0
var failed := 0
func check(ok:bool,msg:String):
	checks += 1
	if not ok:failed += 1;push_error(msg)
func _ready():call_deferred("run")
func control(route:String, data := {}):
	return await CloudAccount._raw(route,HTTPClient.METHOD_POST,data,"")
func run():
	CloudAccount.set_process(false)
	CloudAccount.endpoint = "http://127.0.0.1:8879";CloudAccount.public_key = "local-test-key"
	await control("/test/reset")
	check(CloudAccount.configured(),"debug-only localhost fixture")
	Game.slot = 0;Game.new_character("Guest",Avatar.default_appearance())
	var guest_path := Game.slot_path(0)
	var guest_hash := FileAccess.get_sha256(guest_path)
	check(not Store.valid_id("../escape") and not Store.valid_id("a/b"),"account path traversal rejected")
	check(Store.valid(Store.capture("")),"guest bundle serializes including Vector3")
	await CloudAccount.request_code("bad-email")
	check(not CloudAccount.busy and CloudAccount.user_id.is_empty(),"invalid email cannot sign in")
	await CloudAccount.request_code("player@example.test")
	check(CloudAccount._otp_after>0,"email OTP requested")
	await CloudAccount.verify_code("player@example.test","999999")
	check(CloudAccount.user_id.is_empty(),"incorrect OTP cannot authenticate")
	check(CloudAccount.verification_body("x@y.test","https://attacker.example/auth/v1/verify?token="+"a".repeat(64)).is_empty(),"email links cannot select an untrusted host")
	check(CloudAccount.verification_body("x@y.test",CloudAccount.endpoint+"/auth/v1/verify?token="+"a".repeat(64)+"&type=recovery").is_empty(),"password recovery links are not accepted as game login")
	await CloudAccount.verify_code("player@example.test",CloudAccount.endpoint+"/auth/v1/verify?token="+"a".repeat(64)+"&type=signup&redirect_to=https://attacker.example")
	check(CloudAccount.hydrated and not CloudAccount.user_id.is_empty(),"verified login hydrates account before play")
	check(Game.slot_count()==0 and FileAccess.get_sha256(guest_path)==guest_hash,"fresh account does not absorb or overwrite guest")
	await CloudAccount.import_guest()
	check(Game.slot_count()==1 and not CloudAccount.pending and CloudAccount.revision==1,"explicit guest migration syncs into empty account")
	check(Game.load_game(0) and Game.player_name=="Guest","imported character loads")
	Game.player_name="เครื่องที่หนึ่ง";Game.inventory={"potion_red":23};Game.zeny=4567;Game.save_point=Vector3(12,.1,-9)
	Game.save_game();await CloudAccount.sync()
	check(not CloudAccount.pending and CloudAccount.revision==2,"account save reaches remote")
	var first_id := CloudAccount.user_id
	# A second device: remote bundle installs into a completely separate cache.
	var remote := await CloudAccount._fetch_remote()
	check(Store.install("device_two",remote.payload),"second device downloads entire bundle")
	CloudAccount.user_id="device_two"
	check(Game.load_game(0) and Game.player_name=="เครื่องที่หนึ่ง" and Game.inventory.potion_red==23 and Game.zeny==4567 and Game.save_point.is_equal_approx(Vector3(12,.1,-9)),"second device preserves Thai name, items, money and position")
	CloudAccount.user_id=first_id
	await control("/test/offline",{"fail":true})
	Game.zeny=9999;Game.save_game();await CloudAccount.sync()
	check(CloudAccount.pending and Game.load_game(0) and Game.zeny==9999,"offline failure keeps durable pending local save")
	await control("/test/offline",{"fail":false})
	await CloudAccount.sync()
	check(not CloudAccount.pending,"retry delivers pending offline changes")
	await control("/test/advance")
	Game.zeny=1111;Game.save_game();await CloudAccount.sync()
	check(CloudAccount.conflict and CloudAccount.pending and not CloudAccount.can_play(),"stale device cannot silently overwrite newer cloud save")
	await CloudAccount.resolve_conflict(false)
	check(not CloudAccount.conflict and Game.load_game(0) and Game.zeny==9999,"cloud conflict choice restores remote data")
	var backups := DirAccess.get_directories_at(CloudAccount.storage_prefix()+"backups")
	check(not backups.is_empty(),"conflict replacement preserves local backup")
	await control("/test/advance")
	Game.zeny=2222;Game.save_game();await CloudAccount.sync()
	await CloudAccount.resolve_conflict(true)
	check(not CloudAccount.conflict and not CloudAccount.pending,"explicit local conflict choice uploads with current revision")
	CloudAccount._expires=0
	Game.zeny=3333;Game.save_game();await CloudAccount.sync()
	check(CloudAccount._expires>Time.get_unix_time_from_system() and not CloudAccount.pending,"expired access token refreshes before sync")
	var malformed := Store.capture(first_id);malformed.slots[0].save_point=["bad",0,0]
	var hash_before := FileAccess.get_sha256(Game.slot_path(0))
	check(not Store.install(first_id,malformed) and FileAccess.get_sha256(Game.slot_path(0))==hash_before,"invalid download cannot mutate valid local character")
	var bad_types := Store.capture(first_id);bad_types.slots[0].inventory=[]
	check(not Store.valid(bad_types),"invalid inventory type rejected")
	await control("/test/delay")
	Game.zeny=4444;Game.save_game();CloudAccount.sync()
	await get_tree().create_timer(.05).timeout
	Game.zeny=5555;Game.save_game()
	while CloudAccount.busy:await get_tree().process_frame
	check(CloudAccount.pending,"save created during upload remains pending")
	await CloudAccount.sync()
	check((await CloudAccount._fetch_remote()).payload.slots[0].zeny==5555,"follow-up upload includes newest state")
	Game.delete_slot(0);await CloudAccount.sync()
	check(not CloudAccount.pending and (await CloudAccount._fetch_remote()).payload.slots[0]==null,"character deletion syncs as empty slot")
	await CloudAccount.sign_out()
	check(CloudAccount.user_id.is_empty() and CloudAccount._token.is_empty() and Game.slot_path(0)==guest_path and FileAccess.get_sha256(guest_path)==guest_hash,"logout clears session and restores untouched guest save")
	# Account separation: a different account cache cannot load the original one.
	CloudAccount.user_id="another_account"
	check(Game.slot_count()==0,"different account cannot read previous account cache")
	CloudAccount.user_id=""
	# Instantiate the real shared UI, including configured sign-in fields.
	var panel=preload("res://scripts/ui/account_panel.gd").new();add_child(panel)
	check(panel.get_child_count()>4,"account UI renders login fields")
	panel.free()
	print("ACCOUNT CLOUD CHECKS: ",checks," FAILED: ",failed)
	get_tree().quit(1 if failed else 0)
