extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=5) -> void:
 for i in n:await process_frame
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.size=Vector2i(1280,720)
 var g=root.get_node("Game")
 var items=load("res://scripts/game/items.gd")
 g.new_character("DesktopQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames(15)
 var ui=g.ui
 check(ui!=null and ui.pc_ready,"PC branch ready")
 Engine.max_fps=0
 print("PC READY ",ui.get_script().resource_path)
 ui.pc_tools.panel.show();await frames();ui.pc_tools.panel.hide()
 ui.pc_search.text="potion";await frames()
 check(ui._pc_filtered_items().all(func(id):return (items.item_name(id)+id).to_lower().contains("potion")),"search filters inventory")
 ui.pc_search.text=""
 var ids=g.inventory.keys()
 check(not ids.is_empty(),"test inventory exists")
 var id:String=ids[0]
 ui._pc_toggle_lock(id);check(ui.pc_locks.get(id,false),"lock persisted in memory")
 ui.pc_selected[id]=true
 check(ui._pc_sale_plan().all(func(row):return row.id!=id),"locked item excluded from batch sale")
 var before=g.count(id);var zeny=g.zeny
 ui._shop_buy=false
 ui._trade_shop_item(id,1)
 check(g.count(id)==before and g.zeny==zeny,"locked single sale blocked")
 ui._pc_toggle_lock(id)
 var candidate=""
 for item in items.DB:
  if items.is_gear(item):candidate=item;break
 if candidate!="":
  var rows=ui._pc_comparison_data(candidate)
  check(rows.all(func(row):return row.delta==int(row.after)-int(row.before)),"comparison deltas exact")
  ui._pc_show_compare(candidate,ui._inv_grid.get_child(0));await frames();check(ui.pc_compare_box.get_child_count()==2,"two comparison columns")
 check(not ui._pc_bind_key("inventory",int(ui.pc_key_codes.skills)),"duplicate shortcut rejected")
 var original_key=ui.pc_key_codes.inventory
 check(ui._pc_bind_key("inventory",KEY_B),"shortcut rebound")
 check(ui.pc_key_codes.inventory==KEY_B,"shortcut stored")
 ui._inv.panel.hide()
 var event:=InputEventKey.new();event.keycode=KEY_B;event.pressed=true
 ui._input(event);check(ui._inv.panel.visible,"new key opens inventory")
 ui.pc_search.grab_focus();ui._input(event);check(ui._inv.panel.visible,"typing does not toggle windows")
 ui.pc_search.release_focus();ui.pc_key_codes.inventory=original_key
 ui._pc_index_map()
 check(ui.pc_map_entries.any(func(entry):return entry.kind==1),"NPC destinations indexed")
 check(ui.pc_map_entries.any(func(entry):return entry.kind==2),"resource destinations indexed")
 check(ui.pc_map_entries.any(func(entry):return entry.kind==4),"boss destinations indexed")
 ui._pc_set_pin(ui.pc_map_entries[0]);check(not ui.pc_pin.is_empty(),"pin saved")
 ui._pc_begin_edit();check(ui.pc_edit,"HUD edit active")
 var old:Vector2=ui._info_panel.position
 ui._info_panel.position=Vector2(100,110)
 ui._pc_finish_edit(false);check(ui._info_panel.position==old,"cancel restores HUD")
 ui._pc_begin_edit();ui._info_panel.position=Vector2(100,110);ui._pc_finish_edit(true)
 check(ui.pc_layout.has("สถานะ"),"HUD persisted")
 ui._pc_apply_layout();check(ui._info_panel.position.distance_to(Vector2(100,110))<0.1,"saved HUD restored")
 ui.pc_log_enabled=true
 var player=get_first_node_in_group("player")
 for i in 170:ui.record_combat_event(player,"123",false,false)
 check(ui.pc_log_rows.size()==150,"combat log bounded")
 ui.pc_fps=30;ui._pc_apply_fps();check(Engine.max_fps==30,"FPS cap applied");Engine.max_fps=0
 # Selling is explicit, blocks stale confirmations, and changes stock/gold exactly once.
 ui._shop.panel.show();ui._shop_buy=false
 var vendor=Node3D.new();scene.add_child(vendor);vendor.global_position=player.global_position
 ui.pc_shop_vendor=vendor;ui.pc_sell_vendor=weakref(vendor)
 var item="potion_red"
 g.add_item(item,5,true)
 ui.pc_selected={item:true}
 ui.pc_sell_plan=ui._pc_sale_plan()
 var amount=g.count(item);var gold=g.zeny;var price=g.sell_price(item)
 g.add_item(item,1,true)
 check(not ui._pc_commit_sale(),"changed inventory rejects stale confirmation")
 check(g.zeny==gold,"stale sale does not credit money")
 ui.pc_sell_plan=ui._pc_sale_plan();amount=g.count(item)
 check(ui._pc_commit_sale(),"confirmed NPC batch sale succeeds")
 check(g.count(item)==0 and g.zeny==gold+amount*price,"batch sale count and gold exact")
 var after_gold=g.zeny
 check(not ui._pc_commit_sale() or g.zeny==after_gold,"repeated confirm does not credit twice")
 ui.pc_log_rows.clear();ui.pc_log_enabled=true
 root.get_node("Settings").set_value("damage_numbers",false)
 load("res://scripts/combat/fx.gd").popup(player,player.global_position,"77",Color.RED)
 check(ui.pc_log_rows.size()==1,"combat log works with floating numbers disabled")
 var monster=load("res://scripts/monsters/slime.gd").new();scene.add_child(monster);monster.set_physics_process(false)
 var boss_name=ui.pc_boss_names.keys()[0]
 monster.display_name=boss_name;monster.global_position=player.global_position+Vector3(1,0,0)
 monster.state=monster.State.ATTACK;monster._state_t=0.0;monster._hit_done=false;monster.hit_time=1.0
 ui.pc_boss_alert=true;ui.pc_boss_tick=0;ui._pc_update_boss(0.2)
 check(ui.pc_alert.visible,"boss wind-up shows warning")
 monster._hit_done=true;ui._pc_update_boss(0.2);check(not ui.pc_alert.visible,"warning clears after hit")
 ui._pc_reset_layout();check(ui._info_panel.scale==Vector2.ONE and ui.pc_layout.is_empty(),"reset restores HUD scale and layout")
 ui._pc_graphics_preset("เน้นความลื่น")
 check(root.get_node("Settings").g("shadows")==0 and root.get_node("Settings").g("msaa")==0,"low preset applied")
 ui.pc_fps=60;ui._pc_apply_fps();check(Engine.max_fps==60,"FPS cap survives graphics changes")
 var disk=ConfigFile.new();disk.load(ui.PC_PATH)
 check(disk.get_value("keys",ui.pc_profile,{}).has("inventory"),"keyboard profile persisted to disk")
 # Search chooses the requested source map and the existing route handles travel.
 var resource={}
 for entry in ui.pc_map_entries:
  if entry.kind==2 and entry.get("id","")=="gold_ore":resource=entry;break
 check(not resource.is_empty(),"gold ore searchable")
 if not resource.is_empty():
  ui._pc_travel(resource)
  check(player._auto_gather_area==resource.area,"resource travel respects selected source area")
  player._stop_all();g.auto_on=false
 ui.pc_map_search.text="gold_ore";ui._pc_filter_map()
 check(ui.pc_map_scroll.visible and not ui.pc_map_original_scroll.visible,"search results replace local list")
 check(ui.pc_map_results.get_child_count()>0,"search renders results")
 var original_profile=ui.pc_profile
 ui._pc_bind_key("inventory",KEY_B)
 ui._pc_load_keys();check(ui.pc_key_codes.inventory==KEY_B,"key profile reloads")
 ui.pc_profile="TemporaryQAClass";ui._pc_load_keys();check(ui.pc_key_codes.inventory==KEY_I,"other class has own key profile")
 ui.pc_profile=original_profile;ui._pc_load_keys();check(ui.pc_key_codes.inventory==KEY_B,"returning class restores keys")
 ui.pc_capture="inventory"
 var modifier:=InputEventKey.new();modifier.keycode=KEY_SHIFT;modifier.pressed=true
 ui._input(modifier);check(ui.pc_capture=="inventory","modifier alone does not finish key capture")
 ui._pc_end_capture()
 ui._inv.panel.show();await frames();ui._inv.panel.position=Vector2(50,60);ui._inv.panel.hide();ui._inv.panel.show();await frames()
 check(ui._inv.panel.position.distance_to(Vector2(50,60))<1,"window remembers last position")
 print("PC EXPERIENCE ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)

