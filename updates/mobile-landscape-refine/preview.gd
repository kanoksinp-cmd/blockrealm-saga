extends SceneTree
func frames(n:=8) -> void:
 for i in n:await process_frame
func choose(menu: OptionButton,id: String) -> void:
 for i in range(1,menu.item_count):
  if menu.get_item_metadata(i)==id:menu.select(i);menu.item_selected.emit(i);return
func shot(name:String) -> void:
 await frames();RenderingServer.force_draw(false);root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE").path_join(name+".png"))
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(844,390) if OS.get_environment("BR_MOBILE")=="1" else Vector2i(1280,720)
 var game=root.get_node("Game");game.new_character("NovaMoon32",load("res://scripts/voxel/avatar.gd").default_appearance());game.zeny=150000;game.inventory={"crystal_sword":1};game.equip.weapon="iron_sword";game.refine={"iron_sword":6,"crystal_sword":2}
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene;await frames(15)
 var player=get_first_node_in_group("player");player.set_process(false);player.set_physics_process(false)
 await shot("landscape-hud")
 var ui0=game.ui;ui0._wmap.panel.show();if ui0._mobile:ui0._fit_windows()
 await shot("landscape-map");ui0._wmap.panel.hide();await frames()
 var vendor: Node
 for npc in get_nodes_in_group("npc"):
  if npc.get("role")=="smith":vendor=npc;break
 player.global_position=vendor.global_position+Vector3(1,0,0)
 var ui=game.ui;ui.open_smith(vendor.npc_name,11);await frames()
 var transfer=ui._refine_transfer_ui;choose(transfer.source_menu,"iron_sword");choose(transfer.target_menu,"crystal_sword");await shot("transfer-overview")
 transfer._review();await frames();var scroll=ui._smith_list.get_parent();scroll.ensure_control_visible(transfer.preview.get_child(transfer.preview.get_child_count()-1));await shot("transfer-confirm")
 print("TRANSFER PREVIEW DONE")
 scene.queue_free();await frames();quit()

