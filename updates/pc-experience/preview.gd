extends SceneTree
func frames(n:=6) -> void:
 for i in n:await process_frame
func shot(name:String) -> void:
 await frames(10)
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE").path_join(name+".png"))
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1280,720)
 var g=root.get_node("Game")
 g.new_character("NovaMoon32",load("res://scripts/voxel/avatar.gd").default_appearance())
 g.base_level=40;g.zeny=39090
 var items=load("res://scripts/game/items.gd")
 for id in ["iron_sword","iron_ore","potion_red","potion_blue"]:
  if items.DB.has(id):g.add_item(id,8,true)
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames(15)
 var ui=g.ui
 ui._inv.panel.show();await frames();await shot("inventory")
 var gear="iron_sword" if items.DB.has("iron_sword") else ""
 if gear!="":
  ui.set_process(false)
  ui._pc_show_compare(gear,ui._inv_grid.get_child(0))
  await shot("comparison")
  print("COMPARE SIZE ",ui.pc_compare.size," MIN ",ui.pc_compare.get_combined_minimum_size()," BOX ",ui.pc_compare_box.get_combined_minimum_size())
  ui.pc_compare.hide();ui.set_process(true)
 ui._inv.panel.hide()
 ui._wmap.panel.show();await frames()
 ui.pc_map_search.text="gold_ore";ui._pc_filter_map();await frames();await shot("map-search")
 ui._wmap.panel.hide()
 ui.pc_tools.panel.show();await shot("pc-tools")
 ui.pc_tools.body.get_child(0).current_tab=1;await shot("keybindings")
 ui.pc_tools.body.get_child(0).current_tab=3;await shot("graphics")
 ui.pc_tools.body.get_child(0).current_tab=0
 ui.pc_tools.panel.hide()
 ui._pc_begin_edit();await shot("hud-editor");ui._pc_finish_edit(false)
 ui.pc_log_enabled=true
 var player=get_first_node_in_group("player")
 for i in 8:ui.record_combat_event(player,str(100+i*15),i%3==0,false)
 ui.pc_log.panel.show();await shot("combat-log")
 print("PC PREVIEW DONE")
 scene.queue_free();await frames();quit()
