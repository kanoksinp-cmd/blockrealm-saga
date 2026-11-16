extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=4) -> void:
 for i in n:await process_frame
func choose(menu: OptionButton,id: String) -> void:
 for i in range(1,menu.item_count):
  if menu.get_item_metadata(i)==id:menu.select(i);menu.item_selected.emit(i);return
 check(false,"selector contains "+id)
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.size=Vector2i(844,390) if OS.get_environment("BR_MOBILE")=="1" else Vector2i(1280,720)
 var game=root.get_node("Game");var items=load("res://scripts/game/items.gd")
 game.new_character("TransferQA",load("res://scripts/voxel/avatar.gd").default_appearance());game.zeny=2000000
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(14)
 var player=get_first_node_in_group("player");player.set_process(false);player.set_physics_process(false)
 var vendor: Node
 for npc in get_nodes_in_group("npc"):
  if npc.get("role")=="smith":vendor=npc;break
 check(vendor!=null,"real smith available");player.global_position=vendor.global_position+Vector3(1,0,0)
 var groups:={}
 for id in items.DB:
  if not items.is_gear(id):continue
  var key=items.slot_of(id)+("-"+items.weapon_type(id) if items.slot_of(id)=="weapon" else "")
  if not groups.has(key):groups[key]=[]
  groups[key].append(id)
 var covered:=0
 for key in groups:
  if groups[key].size()<2:continue
  var a:String=groups[key][0];var b:String=groups[key][1]
  game.equip=game._empty_equip();game.inventory={a:1,b:1,"weapon_stone":7,"armor_stone":8};game.refine={a:5,b:2};game.zeny=100000
  var before=game.inventory.duplicate(true);var quote=game.refine_transfer_quote(a,b,vendor)
  check(quote.ok and quote.cost==25000,key+" quote and fee")
  check(game.try_transfer_refine(a,b,5,2,vendor)=="ok",key+" transfer succeeds")
  check(game.refine_lv(a)==0 and game.refine_lv(b)==5 and game.zeny==75000,key+" moves rather than copies levels and charges once")
  check(game.inventory==before,key+" keeps gear and materials")
  check(game.try_transfer_refine(a,b,5,2,vendor)!="ok" and game.zeny==75000,key+" repeated click cannot double spend")
  covered+=1
 print("TRANSFER CATEGORIES ",covered)
 var a:="iron_sword";var b:="crystal_sword"
 game.equip=game._empty_equip();game.equip.weapon=a;game.inventory={b:1,"hunting_bow":1,"knight_plate":1};game.refine={a:10,b:0};game.zeny=100000
 check(game.refine_transfer_quote(a,b,vendor).ok,"equipped source is accepted")
 check(not game.refine_transfer_quote(a,"hunting_bow",vendor).ok,"cross weapon type blocked")
 check(not game.refine_transfer_quote(a,"knight_plate",vendor).ok,"cross slot blocked")
 check(not game.refine_transfer_quote(a,a,vendor).ok,"same item ID blocked")
 game.zeny=99999;check(not game.refine_transfer_quote(a,b,vendor).ok,"insufficient money blocked");game.zeny=100000
 check(game.try_transfer_refine(a,b,9,0,vendor)!="ok" and game.zeny==100000,"stale level blocked without money loss")
 player.global_position+=Vector3(12,0,0);check(game.try_transfer_refine(a,b,10,0,vendor)!="ok","remote smith operation blocked");player.global_position=vendor.global_position+Vector3(1,0,0)
 game.inventory.erase(b);check(game.try_transfer_refine(a,b,10,0,vendor)!="ok" and game.zeny==100000,"sold target rejected without charging");game.inventory[b]=1
 player._dead=true;check(not game.refine_transfer_quote(a,b,vendor).ok,"dead player cannot transfer");player._dead=false
 var failed=load(OS.get_environment("BR_FAIL_STUB")).new();root.add_child(failed);failed.equip=game._empty_equip();failed.inventory={a:1,b:1};failed.refine={a:7,b:1};failed.zeny=100000
 check(failed.try_transfer_refine(a,b,7,1,vendor)!="ok" and failed.refine_lv(a)==7 and failed.refine_lv(b)==1 and failed.zeny==100000,"save failure rolls back refine and money");failed.free()
 var ui=game.ui;ui.open_smith(vendor.npc_name,11);await frames(6)
 var sample=ui._label("ภาษาไทย ABC 123",9);check(sample.get_theme_font_size("font_size")== (15 if ui._mobile else 13),"readable label size floor");sample.free()
 var transfer=ui._refine_transfer_ui
 check(is_instance_valid(transfer),"transfer tab creates UI")
 choose(transfer.source_menu,a);choose(transfer.target_menu,b);transfer._review()
 check(transfer.review.cost==100000,"confirmation shows exact +10 fee")
 transfer._commit();await frames(6)
 check(game.refine_lv(a)==0 and game.refine_lv(b)==10 and game.zeny==0,"UI confirmation commits once")
 check(transfer.review.is_empty() and transfer.source.is_empty(),"success clears stale selections")
 var cfg=ConfigFile.new();cfg.load(game.slot_path(game.slot));check(cfg.get_value("char","refine")[b]==10 and cfg.get_value("char","zeny")==0,"transfer saved before success")
 var rect=ui._smith.panel.get_global_rect();var vp=root.get_visible_rect().size
 check(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=vp.x+2 and rect.end.y<=vp.y+2,"smith window fits viewport")
 print("REFINE TRANSFER ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)

