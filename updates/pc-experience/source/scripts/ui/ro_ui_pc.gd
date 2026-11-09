extends "res://scripts/ui/ro_ui_base.gd"
## Optional desktop tools preserve the classic HUD and leave the mobile branch alone.
const PC_PATH := "user://desktop_preferences.cfg"
var pc_ready := false
var pc_cfg := ConfigFile.new()
var pc_tools: Dictionary
var pc_compare: PanelContainer
var pc_compare_box: HBoxContainer
var pc_compare_id := ""
var pc_search: LineEdit
var pc_sort: OptionButton
var pc_lock_filter: CheckButton
var pc_locks: Dictionary = {}
var pc_selected: Dictionary = {}
var pc_batch_button: Button
var pc_batch := false
var pc_selected_id := ""
var pc_inventory_notice: Label
var pc_identity := ""
var pc_profile := ""
var pc_key_codes: Dictionary = {}
var pc_capture := ""
var pc_capture_button: Button
var pc_keys_box: VBoxContainer
var pc_key_note: Label
var pc_boxes: Dictionary = {}
var pc_layout := {}
var pc_hidden := {}
var pc_edit_layer: Control
var pc_edit_handles := {}
var pc_edit_original := {}
var pc_edit := false
var pc_layout_scale := 1.0
var pc_fps := 60
var pc_shop_vendor: Node3D
var pc_sell_dialog: ConfirmationDialog
var pc_sell_plan: Array = []
var pc_sell_vendor: WeakRef
var pc_visibility_checks := {}
var pc_map_search: LineEdit
var pc_map_kind: OptionButton
var pc_map_scroll: ScrollContainer
var pc_map_original_scroll: ScrollContainer
var pc_map_results: VBoxContainer
var pc_map_entries: Array = []
var pc_pin: Dictionary = {}
var pc_pin_mark: Label
var pc_pin_note: Label
var pc_log: Dictionary
var pc_log_text: RichTextLabel
var pc_log_rows: Array[String] = []
var pc_record_check: CheckButton
var pc_log_enabled := false
var pc_log_dirty := false
var pc_buff_text: Label
var pc_show_buffs := true
var pc_boss_alert := false
var pc_alert: Label
var pc_boss_names := {}
var pc_bosses: Array = []
var pc_tick := 0.0
var pc_boss_tick := 0.0
var pc_layout_pending := false

func _ready() -> void:
 pc_cfg.load(PC_PATH)
 pc_identity = (CloudAccount.username if not CloudAccount.username.is_empty() else "local")+":"+str(Game.slot)
 pc_profile = Game.job
 pc_locks = pc_cfg.get_value("locks",pc_identity,{})
 pc_layout = pc_cfg.get_value("layout","widgets",{})
 pc_hidden = pc_cfg.get_value("layout","hidden",{})
 pc_fps = int(pc_cfg.get_value("graphics","fps",60))
 pc_log_enabled = bool(pc_cfg.get_value("combat","record",false))
 pc_show_buffs = bool(pc_cfg.get_value("combat","buffs",true))
 pc_boss_alert = bool(pc_cfg.get_value("combat","boss_alert",false))
 pc_pin = pc_cfg.get_value("map","pin",{})
 super._ready()
 pc_boxes={"สถานะ":_info_panel,"เมนู":_menu,"แผนที่ย่อ":_map_panel,"เควส":_tracker.panel,"ปาร์ตี้":_party_frame,"แชท":_chat_panel,"สกิลลัด":_hot_panel,"เงินและน้ำหนัก":_pills,"เวลา":_clock}
 _pc_build_comparison()
 _pc_build_tools()
 _pc_build_log()
 _pc_load_keys()
 _pc_build_map_search()
 _settings.body.add_child(_button("ปรับแต่ง PC · HUD / ปุ่มลัด / ภาพ",func():toggle(pc_tools.panel)))
 pc_ready=true
 Settings.changed.connect(_pc_apply_fps)
 _pc_apply_fps()
 _pc_apply_layout.call_deferred()
 _pc_refresh_inventory_controls()
 for z in load("res://scripts/monsters/spawner.gd").ZONES:
  if z.get("boss",false): pc_boss_names[z.name]=true
 pc_alert=_label("",15,Color("ffd4c8"),true)
 pc_alert.add_theme_stylebox_override("normal",_sb(Color(0.22,0.035,0.025,0.94),Color("df7b55"),1,7,8))
 pc_alert.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 pc_alert.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _root.add_child(pc_alert)
 pc_alert.hide()
 _refresh_inventory()

func _pc_save() -> void:
 pc_cfg.set_value("locks",pc_identity,pc_locks)
 pc_cfg.set_value("keys",pc_profile,pc_key_codes)
 pc_cfg.set_value("layout","widgets",pc_layout)
 pc_cfg.set_value("layout","hidden",pc_hidden)
 pc_cfg.set_value("graphics","fps",pc_fps)
 pc_cfg.set_value("combat","record",pc_log_enabled)
 pc_cfg.set_value("combat","buffs",pc_show_buffs)
 pc_cfg.set_value("combat","boss_alert",pc_boss_alert)
 pc_cfg.set_value("map","pin",pc_pin)
 if pc_cfg.save(PC_PATH)!=OK: add_message("บันทึกการตั้งค่า PC ไม่สำเร็จ",BAD)

func layout_defaults() -> void:
 if pc_edit:_pc_finish_edit(false)
 super.layout_defaults()
 if pc_ready:
  _pc_apply_layout.call_deferred()
  for panel in _popups:
   if panel.visible:_pc_fit_popup.call_deferred(panel,str(panel.get_meta("pc_window_title","")))

func _input(event: InputEvent) -> void:
 if not pc_ready: return
 if pc_capture!="":
  if event is InputEventKey and event.pressed and not event.echo:
   if event.keycode in [KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META]:
    get_viewport().set_input_as_handled()
    return
   if event.keycode==KEY_ESCAPE: _pc_end_capture()
   else: _pc_bind_key(pc_capture,event.get_keycode_with_modifiers())
   get_viewport().set_input_as_handled()
  return
 if not (event is InputEventKey) or not event.pressed or event.echo: return
 var focus=get_viewport().gui_get_focus_owner()
 if focus is LineEdit or focus is TextEdit:
  if event.keycode==KEY_ESCAPE: focus.release_focus();get_viewport().set_input_as_handled()
  return
 if pc_edit:
  if event.keycode==KEY_ESCAPE: _pc_finish_edit(false);get_viewport().set_input_as_handled()
  return
 if event.keycode==KEY_ESCAPE:
  if pc_compare.visible: pc_compare.hide()
  for panel in [pc_tools.panel,pc_log.panel]:
   if panel.visible: panel.hide();get_viewport().set_input_as_handled();return
  super._input(event)
  return
 if event.keycode in [KEY_ENTER,KEY_KP_ENTER]: super._input(event);return
 var code=event.get_keycode_with_modifiers()
 for action in pc_key_codes:
  if int(pc_key_codes[action])==code:
   _pc_action(action)
   get_viewport().set_input_as_handled()
   return
 # The original second-row number keys remain aliases unless reassigned.
 if event.keycode>=KEY_1 and event.keycode<=KEY_8 and not event.ctrl_pressed and not event.alt_pressed:
  activate_hotkey(8+event.keycode-KEY_1)
  get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
 super._process(delta)
 if not pc_ready: return
 pc_tick-=delta
 if pc_tick<=0:
  pc_tick=0.2
  if Game.job!=pc_profile:
   pc_profile=Game.job
   _pc_load_keys()
  if pc_log.panel.visible:
   if pc_log_dirty:
    pc_log_text.text="\n".join(pc_log_rows)
    pc_log_dirty=false
   var buffs: Array[String]=[]
   if pc_show_buffs:
    for id in Game.buffs: buffs.append("%s %.1fs"%[tr(Game.skill_name(id)),float(Game.buffs[id].get("t",0))])
   pc_buff_text.text="บัฟ: "+(" · ".join(buffs) if not buffs.is_empty() else "ไม่มี")
  _pc_update_boss(delta)
  for key in pc_hidden:
   if pc_hidden[key] and pc_boxes.has(key): pc_boxes[key].hide()
 if pc_edit:
  Game.mouse_over_ui=true
  _pc_update_handles()
 if pc_compare.visible:
  var hovered=get_viewport().gui_get_hovered_control()
  if not is_instance_valid(hovered) or str(hovered.get_meta("pc_item",""))!=pc_compare_id: pc_compare.hide()

func _pc_clear(node: Node) -> void:
 for child in node.get_children(): node.remove_child(child);child.queue_free()

# ---------------- inventory and comparison ----------------
func _build_inventory() -> void:
 super._build_inventory()
 var bag=_inv_grid.get_parent()
 var tools:=HBoxContainer.new()
 tools.add_theme_constant_override("separation",5)
 pc_search=LineEdit.new()
 pc_search.placeholder_text="ค้นหาชื่อ / ชนิดไอเทม"
 pc_search.max_length=64
 pc_search.custom_minimum_size.x=160
 pc_search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 pc_search.text_changed.connect(func(_text):_refresh_inventory())
 tools.add_child(pc_search)
 pc_sort=OptionButton.new()
 for text in ["ชื่อ","ชนิด","ราคาขาย","ค่าอุปกรณ์"]: pc_sort.add_item(text)
 pc_sort.item_selected.connect(func(_index):_refresh_inventory())
 tools.add_child(pc_sort)
 bag.add_child(tools)
 bag.move_child(tools,0)
 var actions:=HFlowContainer.new()
 pc_lock_filter=CheckButton.new()
 pc_lock_filter.text="กันขาย"
 pc_lock_filter.toggled.connect(func(_on):_refresh_inventory())
 actions.add_child(pc_lock_filter)
 pc_batch_button=_button("เลือกหลายชิ้น",func():
  pc_batch=not pc_batch
  pc_selected.clear()
  _refresh_inventory())
 pc_batch_button.toggle_mode=true
 actions.add_child(pc_batch_button)
 actions.add_child(_button("ล็อก / ปลดกันขาย",func():_pc_toggle_lock(pc_selected_id)))
 bag.add_child(actions)
 bag.move_child(actions,1)
 var scroll:=ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(275,225)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 var index=_inv_grid.get_index()
 bag.remove_child(_inv_grid)
 bag.add_child(scroll)
 bag.move_child(scroll,index)
 scroll.add_child(_inv_grid)
 pc_inventory_notice=_label("คลิกเลือก · Ctrl+คลิกขวาเพื่อล็อกกันขาย",11,INK_L)
 pc_inventory_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 pc_inventory_notice.custom_minimum_size.x=270
 bag.add_child(pc_inventory_notice)

func _pc_filtered_items() -> Array:
 var ids: Array=[]
 var want: String=INV_TABS[_inv_tab][1]
 var query=pc_search.text.strip_edges().to_lower() if is_instance_valid(pc_search) else ""
 for id in Game.inventory:
  if want!="" and not Items.info(id).type in want.split(","):continue
  if query!="" and not (Items.item_name(id)+" "+str(id)+" "+tr(str(Items.info(id).type))).to_lower().contains(query):continue
  if is_instance_valid(pc_lock_filter) and pc_lock_filter.button_pressed and not pc_locks.get(id,false):continue
  ids.append(id)
 var order=pc_sort.selected if is_instance_valid(pc_sort) else 0
 ids.sort_custom(func(a,b):
  if order==1 and Items.info(a).type!=Items.info(b).type:return str(Items.info(a).type)<str(Items.info(b).type)
  if order==2 and Game.sell_price(a)!=Game.sell_price(b):return Game.sell_price(a)>Game.sell_price(b)
  if order==3 and _gear_score(a)!=_gear_score(b):return _gear_score(a)>_gear_score(b)
  return Items.item_name(a).nocasecmp_to(Items.item_name(b))<0)
 return ids

func _refresh_inventory() -> void:
 if not is_instance_valid(pc_search):
  super._refresh_inventory()
  return
 for i in _inv_tabs.size():_set_tab(_inv_tabs[i],i==_inv_tab)
 _pc_clear(_inv_grid)
 var ids=_pc_filtered_items()
 for key in pc_selected.keys():
  if Game.count(key)<=0:pc_selected.erase(key)
 var n=maxi(INV_SLOTS,ceili(ids.size()/5.0)*5)
 for i in n:
  var button:=_slot(50)
  if i<ids.size():
   var id: String=ids[i]
   button.icon=Items.icon(id)
   button.set_meta("pc_item",id)
   button.tooltip_text=_item_tip(id)+("\nล็อกกันขาย" if pc_locks.get(id,false) else "")
   _count_label(button,str(Game.count(id)))
   if Items.is_gear(id):
    _refine_glow(button,Game.refine_lv(id))
    _compare_arrow(button,_compare(id))
    button.mouse_entered.connect(func():_pc_show_compare(id,button))
   if pc_locks.get(id,false):
    var lock_icon:=_icon_rect(UiIcons.tex("lock",1),12)
    lock_icon.position=Vector2(2,2)
    lock_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
    button.add_child(lock_icon)
   button.toggle_mode=pc_batch
   button.button_pressed=pc_batch and pc_selected.has(id)
   button.pressed.connect(func():
    pc_selected_id=id
    if pc_batch:
     if pc_selected.has(id):pc_selected.erase(id)
     elif not pc_locks.get(id,false):pc_selected[id]=true
     _refresh_inventory()
    else:_pc_refresh_inventory_controls())
   button.gui_input.connect(func(event):
    if event is InputEventMouseButton and event.pressed:
     if event.button_index==MOUSE_BUTTON_RIGHT and event.ctrl_pressed:
      _pc_toggle_lock(id)
      button.accept_event()
     elif event.double_click or event.button_index==MOUSE_BUTTON_RIGHT:
      Game.use_item(id))
  else:button.disabled=true
  _inv_grid.add_child(button)
 _inv_footer.text="%d / %d · น้ำหนัก %d / %d"%[Game.inventory.size(),INV_SLOTS,Game.weight()/10,Game.max_weight()/10]
 _inv_zeny.text=_commas(Game.zeny)
 _pc_refresh_inventory_controls()
 _refresh_hotbar()
 _refresh_equipment()

func _pc_refresh_inventory_controls() -> void:
 if not is_instance_valid(pc_inventory_notice):return
 if is_instance_valid(pc_batch_button):
  pc_batch_button.text="ยกเลิกเลือก" if pc_batch else "เลือกหลายชิ้น"
  pc_batch_button.set_pressed_no_signal(pc_batch)
 pc_inventory_notice.text=("เลือกขาย %d ชนิด · ขายผ่านร้าน NPC เท่านั้น"%pc_selected.size()) if pc_batch else ((Items.item_name(pc_selected_id)+(" · ล็อกกันขาย" if pc_locks.get(pc_selected_id,false) else "")) if pc_selected_id!="" else "คลิกเลือก · Ctrl+คลิกขวาเพื่อล็อกกันขาย")

func _pc_toggle_lock(id: String) -> void:
 if id=="" or not Items.DB.has(id):return
 if pc_locks.get(id,false):pc_locks.erase(id)
 else:pc_locks[id]=true;pc_selected.erase(id)
 _pc_save()
 _refresh_inventory()
 if _shop.panel.visible:_fill_shop()

func _pc_build_comparison() -> void:
 pc_compare=PanelContainer.new()
 pc_compare.add_theme_stylebox_override("panel",_sb(Color(0.035,0.045,0.065,0.98),GOLD_D,1,8,12))
 pc_compare.mouse_filter=Control.MOUSE_FILTER_IGNORE
 pc_compare_box=HBoxContainer.new()
 pc_compare_box.add_theme_constant_override("separation",16)
 pc_compare.add_child(pc_compare_box)
 _root.add_child(pc_compare)
 pc_compare.hide()

func _pc_comparison_data(id: String) -> Array:
 var equipped: String=Game.equip.get(Items.slot_of(id),"")
 var after=_gear_stats(id)
 var before=_gear_stats(equipped)
 var keys: Array=after.keys()
 for key in before:
  if not key in keys:keys.append(key)
 keys.sort()
 var rows: Array=[]
 for key in keys:
  rows.append({"key":str(key).strip_edges(),"before":before.get(key,0),"after":after.get(key,0),"delta":int(after.get(key,0))-int(before.get(key,0))})
 return rows

func _pc_show_compare(id: String, anchor: Control) -> void:
 if not pc_ready or pc_edit:return
 _pc_clear(pc_compare_box)
 var current: String=Game.equip.get(Items.slot_of(id),"")
 for data in [["กำลังสวมใส่",current],["ชิ้นที่เลือก",id]]:
  var column:=VBoxContainer.new()
  column.custom_minimum_size.x=185
  column.add_child(_label(data[0],12,INK_L))
  var name:=_label(Game.item_label(data[1]) if data[1]!="" else "ช่องว่าง",14,TITLE,true)
  name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  column.add_child(name)
  if data[1]!="":
   var icon:=_icon_rect(Items.icon(data[1]),42)
   column.add_child(icon)
  pc_compare_box.add_child(column)
 var a=pc_compare_box.get_child(0)
 var b=pc_compare_box.get_child(1)
 for row in _pc_comparison_data(id):
  var key=tr(SkillDB.BONUS_LABEL.get(row.key,row.key))
  var unit="%" if row.key in SkillDB.PCT_KEYS else ""
  a.add_child(_label("%s  %d%s"%[key,row.before,unit],12,INK))
  b.add_child(_label("%s  %d%s  (%+d%s)"%[key,row.after,unit,row.delta,unit],12,GOOD if row.delta>0 else (BAD if row.delta<0 else INK_L)))
 var info=Items.info(id)
 var requirement: Array[String]=[]
 for key in ["min_level","level_req","req_level"]:
  if info.has(key):requirement.append("เลเวล %d"%int(info[key]))
 for key in ["job","jobs","job_req"]:
  if info.has(key):requirement.append(str(info[key]))
 if info.get("two_hand",false):requirement.append("สองมือ · ถอดโล่เมื่อสวม")
 b.add_child(_label(" · ".join(requirement) if not requirement.is_empty() else "ใช้งานตามประเภทอุปกรณ์",11,INK_L))
 for control in pc_compare.find_children("*","Control",true,false):control.mouse_filter=Control.MOUSE_FILTER_IGNORE
 pc_compare_id=id
 pc_compare.reset_size()
 var vp=get_viewport().get_visible_rect().size
 var at=anchor.get_global_rect()
 var width=maxf(pc_compare.get_combined_minimum_size().x,410)
 pc_compare.position=Vector2(clampf(at.end.x+10,8,maxf(8,vp.x-width-8)),clampf(at.position.y,8,maxf(8,vp.y-pc_compare.get_combined_minimum_size().y-8)))
 pc_compare.show()
 pc_compare.move_to_front()
 _pc_tight_compare.call_deferred(anchor)

# ---------------- NPC trade safety and explicit bulk sale ----------------
func open_shop(npc_name: String,stock: Array,buy: bool) -> void:
 pc_shop_vendor=Game.near_npc
 super.open_shop(npc_name,stock,buy)

func _build_shop() -> void:
 super._build_shop()
 var row:=HBoxContainer.new()
 row.add_child(_button("เลือกของในกระเป๋า",func():pc_batch=true;_refresh_inventory();_inv.panel.show();_inv.panel.move_to_front()))
 row.add_child(_button("ขายรายการที่เลือก…",_pc_prepare_sale))
 _shop.body.add_child(row)

func _fill_shop() -> void:
 super._fill_shop()
 if _shop_buy:return
 var ids=Game.inventory.keys()
 var cards=_shop_grid.get_children()
 for i in mini(ids.size(),cards.size()):
  if pc_locks.get(ids[i],false):
   cards[i].tooltip_text+="\nล็อกกันขาย"
   for button in cards[i].find_children("*","Button",true,false):button.disabled=true

func _trade_shop_item(id: String,quantity: int) -> void:
 if not _shop_buy and pc_locks.get(id,false):
  add_message("ชิ้นนี้ล็อกกันขายอยู่",BAD)
  return
 super._trade_shop_item(id,quantity)

func _pc_can_sell() -> bool:
 var player=get_tree().get_first_node_in_group("player")
 return _shop.panel.visible and not _shop_buy and is_instance_valid(pc_shop_vendor) and is_instance_valid(player) and player.global_position.distance_to(pc_shop_vendor.global_position)<5.0

func _pc_sale_plan() -> Array:
 var plan: Array=[]
 for id in pc_selected:
  if pc_locks.get(id,false) or Game.count(id)<=0:continue
  plan.append({"id":str(id),"count":Game.count(id),"price":Game.sell_price(id)})
 return plan

func _pc_prepare_sale() -> void:
 if not _pc_can_sell():add_message("เปิดแท็บขายกับร้าน NPC และอยู่ใกล้ร้านก่อน",BAD);return
 pc_sell_plan=_pc_sale_plan()
 pc_sell_vendor=weakref(pc_shop_vendor)
 if pc_sell_plan.is_empty():add_message("เลือกรายการที่ไม่ได้ล็อกกันขายก่อน",INK_L);return
 if is_instance_valid(pc_sell_dialog):pc_sell_dialog.queue_free()
 pc_sell_dialog=ConfirmationDialog.new()
 pc_sell_dialog.title="ตรวจรายการขาย"
 pc_sell_dialog.ok_button_text="ยืนยันขาย"
 pc_sell_dialog.cancel_button_text="ยกเลิก"
 var lines: Array[String]=[]
 var total:=0
 for row in pc_sell_plan:
  total+=row.count*row.price
  lines.append("%s ×%d · %s z"%[Items.item_name(row.id),row.count,_commas(row.count*row.price)])
 pc_sell_dialog.dialog_text="ขาย %d ชนิด · รวม %s z\nไม่รวมของที่สวมอยู่และของล็อกกันขาย"%[pc_sell_plan.size(),_commas(total)]
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(450,200);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 var receipt:=Label.new();receipt.text="\n".join(lines);receipt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;receipt.custom_minimum_size.x=420
 scroll.add_child(receipt);pc_sell_dialog.add_child(scroll)
 add_child(pc_sell_dialog)
 pc_sell_dialog.confirmed.connect(_pc_commit_sale)
 pc_sell_dialog.popup_centered(Vector2i(480,240))

func _pc_commit_sale() -> bool:
 if pc_sell_plan.is_empty():return false
 if not _pc_can_sell() or pc_sell_vendor==null or pc_sell_vendor.get_ref()!=pc_shop_vendor:add_message("ร้านเปลี่ยนหรืออยู่ไกลเกินไป กรุณาตรวจรายการใหม่",BAD);return false
 for row in pc_sell_plan:
  if pc_locks.get(row.id,false) or Game.count(row.id)!=row.count or Game.sell_price(row.id)!=row.price:
   add_message("รายการเปลี่ยนแล้ว กรุณาตรวจรายการขายใหม่",BAD)
   return false
 var total:=0
 for row in pc_sell_plan:
  if not Game.remove_item(row.id,row.count):return false
  total+=row.count*row.price
 Game.add_zeny(total)
 pc_selected.clear()
 pc_sell_plan.clear()
 Game.save_game()
 _fill_shop()
 _refresh_inventory()
 add_message("ขายรายการที่เลือกแล้ว · "+_commas(total)+" z",GOOD)
 return true

# ---------------- saved HUD layouts and per-class keyboard profiles ----------------
func _pc_build_tools() -> void:
 pc_tools=_window("เครื่องมือ PC",Vector2(320,90),Vector2(650,0),R_GRAY)
 var tabs:=TabContainer.new()
 tabs.custom_minimum_size=Vector2(620,430)
 pc_tools.body.add_child(tabs)
 var hud:=VBoxContainer.new();hud.name="HUD";tabs.add_child(hud)
 hud.add_child(_label("จัดตำแหน่ง HUD · ลากแถบชื่อและหมุนล้อเมาส์เพื่อย่อ/ขยาย",13,TITLE))
 hud.add_child(_button("เริ่มจัด HUD",_pc_begin_edit))
 hud.add_child(_button("คืนค่า HUD เดิม",_pc_reset_layout))
 var grid:=GridContainer.new();grid.columns=3;hud.add_child(grid)
 for key in pc_boxes:
  var check:=CheckButton.new();check.text=key;check.button_pressed=not pc_hidden.get(key,false)
  check.toggled.connect(func(on):pc_hidden[key]=not on;pc_boxes[key].visible=on;_pc_save())
  grid.add_child(check)
  pc_visibility_checks[key]=check
 hud.add_child(_label("ตำแหน่งและขนาด HUD เก็บบนเครื่องนี้ แยกจากมือถือ",12,INK_L))
 var keys_scroll:=ScrollContainer.new();keys_scroll.name="ปุ่มลัด";keys_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;tabs.add_child(keys_scroll)
 pc_keys_box=VBoxContainer.new();pc_keys_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;keys_scroll.add_child(pc_keys_box)
 var combat:=VBoxContainer.new();combat.name="การต่อสู้";tabs.add_child(combat)
 var recording:=CheckButton.new();pc_record_check=recording;recording.text="เก็บประวัติดาเมจ (สูงสุด 150 เหตุการณ์)";recording.button_pressed=pc_log_enabled
 recording.toggled.connect(func(on):pc_log_enabled=on;_pc_save())
 combat.add_child(recording)
 var buff_check:=CheckButton.new();buff_check.text="แสดงเวลาบัฟในหน้าประวัติ";buff_check.button_pressed=pc_show_buffs
 buff_check.toggled.connect(func(on):pc_show_buffs=on;_pc_save())
 combat.add_child(buff_check)
 var warning:=CheckButton.new();warning.text="เตือนจังหวะโจมตีของบอสใกล้ตัว";warning.button_pressed=pc_boss_alert
 warning.toggled.connect(func(on):pc_boss_alert=on;_pc_save())
 combat.add_child(warning)
 combat.add_child(_button("เปิดประวัติดาเมจ · F10",func():toggle(pc_log.panel)))
 combat.add_child(_label("ประวัติแสดงดาเมจที่ได้รับและที่เกิดกับมอนสเตอร์ รวมฮิตจากสมาชิกปาร์ตี้\nการเตือนใช้จังหวะโจมตีจริงของบอส ไม่ครอบคลุมท่าพิเศษที่ไม่มีช่วงเตรียม",12,INK_L))
 var graphics:=VBoxContainer.new();graphics.name="ภาพ";tabs.add_child(graphics)
 graphics.add_child(_label("เลือกโหมดภาพ · ใช้ระบบตั้งค่าของเกมเดิม",13,TITLE))
 var presets:=HBoxContainer.new();graphics.add_child(presets)
 for preset in ["เน้นความลื่น","สมดุล","เน้นความสวย"]:
  presets.add_child(_button(preset,func():_pc_graphics_preset(preset)))
 var cap:=OptionButton.new()
 for text in ["30 FPS","60 FPS","90 FPS","120 FPS","ไม่จำกัด"]:cap.add_item(text)
 cap.select([30,60,90,120,0].find(pc_fps) if pc_fps in [30,60,90,120,0] else 1)
 cap.item_selected.connect(func(index):pc_fps=[30,60,90,120,0][index];_pc_apply_fps();_pc_save())
 graphics.add_child(_label("เพดานเฟรมเรต",12,INK_L));graphics.add_child(cap)
 graphics.add_child(_label("ลดเพดานเฟรมเพื่อประหยัดพลังงาน · ความลื่นขึ้นกับเครื่องและเบราว์เซอร์",12,INK_L))
 pc_tools.panel.hide()
 pc_tools.panel.visibility_changed.connect(func():
  if not pc_tools.panel.visible and pc_capture!="":_pc_end_capture())

func _pc_default_keys() -> Dictionary:
 var keys={"status":KEY_S,"inventory":KEY_I,"skills":KEY_K,"quests":KEY_J,"map":KEY_M,"options":KEY_O,"party":KEY_P,"auto":KEY_Z,"target":KEY_TAB,"combat":KEY_F10}
 for i in 16:keys["hot_"+str(i)]=KEY_F1+(i%8)+(KEY_MASK_SHIFT if i>=8 else 0)
 return keys

func _pc_load_keys() -> void:
 _pc_end_capture()
 pc_key_codes=_pc_default_keys()
 var stored=pc_cfg.get_value("keys",pc_profile,{})
 if stored is Dictionary:
  var seen: Dictionary={}
  for action in pc_key_codes:
   var candidate=int(stored.get(action,pc_key_codes[action]))
   if candidate>0 and not seen.has(candidate) and not candidate in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_F9]:
    pc_key_codes[action]=candidate;seen[candidate]=true
 _pc_key_rows()
 _pc_key_hints()

func _pc_key_rows() -> void:
 if not is_instance_valid(pc_keys_box):return
 _pc_clear(pc_keys_box)
 pc_keys_box.add_child(_label("โปรไฟล์อาชีพ: "+pc_profile,14,TITLE,true))
 pc_key_note=_label("คลิกปุ่มแล้วกดปุ่มใหม่ · Esc ยกเลิก · ไม่แย่งปุ่มขณะพิมพ์ข้อความ",12,INK_L)
 pc_keys_box.add_child(pc_key_note)
 var names={"status":"ตัวละคร","inventory":"กระเป๋า","skills":"สกิล","quests":"เควส","map":"แผนที่","options":"ตั้งค่า","party":"ปาร์ตี้","auto":"ออโต้","target":"เป้าหมายถัดไป","combat":"ประวัติดาเมจ"}
 for action in pc_key_codes:
  var row:=HBoxContainer.new();pc_keys_box.add_child(row)
  var label:=_label(names.get(action,"สกิลช่อง "+str(int(str(action).trim_prefix("hot_"))+1)) if str(action).begins_with("hot_") else names.get(action,action),12,INK)
  label.custom_minimum_size.x=220;row.add_child(label)
  var button:=_button(OS.get_keycode_string(int(pc_key_codes[action])),func():
   pc_capture=action
   pc_capture_button=row.get_child(1)
   pc_capture_button.text="กดปุ่มใหม่…"
   pc_key_note.text="กด Esc เพื่อยกเลิกการตั้งปุ่ม")
  button.custom_minimum_size.x=150;row.add_child(button)
 pc_keys_box.add_child(_button("คืนปุ่มลัดอาชีพนี้",func():pc_key_codes=_pc_default_keys();_pc_save();_pc_key_rows();_pc_key_hints()))

func _pc_bind_key(action: String,code: int) -> bool:
 if not pc_key_codes.has(action):return false
 var plain=code & KEY_CODE_MASK
 var browser_key=((code & (KEY_MASK_CTRL|KEY_MASK_META))!=0 and plain in [KEY_R,KEY_L,KEY_T,KEY_N,KEY_P,KEY_S,KEY_O,KEY_Q]) or ((code & KEY_MASK_ALT)!=0 and plain==KEY_F4)
 if plain in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_F9,KEY_W,KEY_A,KEY_D] or code<=0 or browser_key:
  if is_instance_valid(pc_key_note):pc_key_note.text="ปุ่มนี้สงวนไว้สำหรับการควบคุมหรือบัญชี"
  return false
 for other in pc_key_codes:
  if other!=action and int(pc_key_codes[other])==code:
   if is_instance_valid(pc_key_note):pc_key_note.text="ปุ่มนี้ถูกใช้อยู่แล้ว กรุณาเลือกปุ่มอื่น"
   return false
 pc_key_codes[action]=code
 _pc_end_capture()
 _pc_save()
 _pc_key_rows()
 _pc_key_hints()
 return true

func _pc_end_capture() -> void:
 var previous=pc_capture
 pc_capture=""
 if is_instance_valid(pc_capture_button):pc_capture_button.text=OS.get_keycode_string(int(pc_key_codes.get(previous,0)))
 pc_capture_button=null

func _pc_key_hints() -> void:
 var actions=["status","inventory","skills","quests","map","options"]
 for i in _menu.get_child_count():
  var button=_menu.get_child(i)
  button.tooltip_text=tr(["Status","Items","Skills","Quests","World Map","Options"][i])+" · "+OS.get_keycode_string(int(pc_key_codes[actions[i]]))
  for child in button.get_children():
   if child is Label and child!=_skill_badge and child.text.length()<=8:child.text=OS.get_keycode_string(int(pc_key_codes[actions[i]]))
 for i in mini(16,_hot_slots.size()):
  var button=_hot_slots[i].get_parent()
  var text=OS.get_keycode_string(int(pc_key_codes["hot_"+str(i)]))
  if i>=8 and int(pc_key_codes["hot_"+str(i)])==KEY_F1+(i%8)+KEY_MASK_SHIFT:text=str(i-7)
  for child in button.get_children():
   if child is Label and child.position==Vector2(4,0):child.text=text

func _pc_action(action: String) -> void:
 if action.begins_with("hot_"):activate_hotkey(int(action.trim_prefix("hot_")));return
 match action:
  "status":toggle(_status.panel)
  "inventory":toggle(_inv.panel)
  "skills":toggle(_skills.panel)
  "quests":toggle(_quests.panel)
  "map":toggle(_wmap.panel)
  "options":toggle(_settings.panel)
  "party":
   if _party.panel.visible:_party.panel.hide()
   else:open_party(_party_tab)
  "auto":
   var player=get_tree().get_first_node_in_group("player")
   if player:player.toggle_auto()
  "combat":toggle(pc_log.panel)
  "target":_pc_cycle_target()

func _pc_cycle_target() -> void:
 var player=get_tree().get_first_node_in_group("player")
 if not is_instance_valid(player) or not player.is_alive():return
 var candidates: Array=[]
 for monster in get_tree().get_nodes_in_group("monster"):
  if monster.is_alive() and monster.global_position.distance_squared_to(player.global_position)<900.0 and VillageBuilder.area_at(monster.global_position)==VillageBuilder.area_at(player.global_position):candidates.append(monster)
 candidates.sort_custom(func(a,b):return a.global_position.distance_squared_to(player.global_position)<b.global_position.distance_squared_to(player.global_position))
 if candidates.is_empty():return
 var next=(candidates.find(player.attack_target)+1)%candidates.size()
 if is_instance_valid(player.attack_target):player.attack_target.set_locked(false)
 player.cancel_walk()
 player.attack_target=candidates[next]
 candidates[next].set_locked(true)
 player.interact_target=null

func _pc_apply_layout() -> void:
 if not pc_ready:return
 var vp=get_viewport().get_visible_rect().size
 for key in pc_boxes:
  var box: Control=pc_boxes[key]
  if pc_layout.has(key):
   var data=pc_layout[key]
   box.scale=Vector2.ONE*clampf(float(data.get("scale",1.0)),0.6,1.5)
   var point: Vector2=data.get("at",Vector2.ZERO)
   box.position=point*vp
  box.position=box.position.clamp(Vector2.ZERO,(vp-_sz(box)*box.scale).max(Vector2.ZERO))
  box.visible=not pc_hidden.get(key,false) and (bool(Settings.g("minimap")) if key=="แผนที่ย่อ" else true)

func _pc_begin_edit() -> void:
 if pc_edit:return
 pc_edit=true
 pc_tools.panel.hide()
 _settings.panel.hide()
 pc_edit_original={}
 pc_edit_layer=Control.new();pc_edit_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);pc_edit_layer.mouse_filter=Control.MOUSE_FILTER_STOP
 _root.add_child(pc_edit_layer);_windows.append(pc_edit_layer)
 for key in pc_boxes:
  var box: Control=pc_boxes[key]
  pc_edit_original[key]={"position":box.position,"scale":box.scale}
  if not box.visible:continue
  var handle:=PanelContainer.new()
  handle.add_theme_stylebox_override("panel",_sb(Color(0.05,0.12,0.2,0.28),Color("80c1ee"),2,5,3))
  var caption:=_label(key+" · ลาก / ล้อเมาส์",11,Color("b9dcf6"),true)
  caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
  handle.add_child(caption)
  handle.mouse_filter=Control.MOUSE_FILTER_STOP
  handle.gui_input.connect(func(event):
   if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
    box.position+=event.relative
    _pc_clamp_widget(box)
    handle.accept_event()
   if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
    box.scale=Vector2.ONE*clampf(box.scale.x+(0.05 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -0.05),0.6,1.5)
    _pc_clamp_widget(box)
    handle.accept_event())
  pc_edit_layer.add_child(handle)
  pc_edit_handles[key]=handle
 var footer:=HBoxContainer.new()
 footer.position=Vector2(get_viewport().get_visible_rect().size.x*0.5-180,get_viewport().get_visible_rect().size.y-50)
 footer.add_child(_button("บันทึก HUD",func():_pc_finish_edit(true)))
 footer.add_child(_button("ยกเลิก · Esc",func():_pc_finish_edit(false)))
 pc_edit_layer.add_child(footer)
 _pc_update_handles()

func _pc_clamp_widget(box: Control) -> void:
 var vp=get_viewport().get_visible_rect().size
 box.position=box.position.clamp(Vector2.ZERO,(vp-_sz(box)*box.scale).max(Vector2.ZERO))

func _pc_update_handles() -> void:
 for key in pc_edit_handles:
  var handle: Control=pc_edit_handles[key]
  var box: Control=pc_boxes[key]
  handle.position=box.position
  handle.custom_minimum_size=Vector2.ZERO
  handle.size=_sz(box)*box.scale

func _pc_finish_edit(commit: bool) -> void:
 if not pc_edit:return
 var vp=get_viewport().get_visible_rect().size
 for key in pc_boxes:
  var box: Control=pc_boxes[key]
  if commit:pc_layout[key]={"at":box.position/vp,"scale":box.scale.x}
  elif pc_edit_original.has(key):box.position=pc_edit_original[key].position;box.scale=pc_edit_original[key].scale
 if commit:_pc_save()
 _windows.erase(pc_edit_layer)
 pc_edit_layer.queue_free()
 pc_edit_handles.clear()
 pc_edit=false

func _pc_graphics_preset(preset: String) -> void:
 var data: Dictionary
 match preset:
  "เน้นความลื่น":data={"shadows":0,"msaa":0,"render_scale":0.8,"view_distance":140.0,"clouds":false,"outlines":false}
  "เน้นความสวย":data={"shadows":2,"msaa":2,"render_scale":1.0,"view_distance":300.0,"clouds":true,"outlines":true}
  _:data={"shadows":1,"msaa":1,"render_scale":1.0,"view_distance":220.0,"clouds":true,"outlines":true}
 for key in data:Settings.data[key]=data[key]
 Settings.apply();Settings.save();Settings.changed.emit()
 add_message("ใช้โหมดภาพ: "+preset,GOOD)

func _pc_apply_fps() -> void:
 if Settings.is_mobile():return
 Engine.max_fps=pc_fps if pc_fps in [0,30,60,90,120] else 60

# ---------------- search, pins and existing travel paths ----------------
func _pc_build_map_search() -> void:
 var row:=HBoxContainer.new()
 pc_map_search=LineEdit.new();pc_map_search.max_length=64;pc_map_search.placeholder_text="ค้นหา NPC / แร่ / มอนสเตอร์ / บอส ทุกแผนที่";pc_map_search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 pc_map_search.text_changed.connect(func(_text):_pc_filter_map())
 row.add_child(pc_map_search)
 pc_map_kind=OptionButton.new()
 for text in ["ทั้งหมด","NPC","วัตถุดิบ","มอนสเตอร์","บอส"]:pc_map_kind.add_item(text)
 pc_map_kind.item_selected.connect(func(_index):_pc_filter_map())
 row.add_child(pc_map_kind)
 _wmap.body.add_child(row);_wmap.body.move_child(row,0)
 var search_scroll:=ScrollContainer.new();search_scroll.custom_minimum_size=Vector2(270,WMAP_PX-40);search_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 pc_map_scroll=search_scroll
 pc_map_original_scroll=_wmap_list.get_parent()
 pc_map_results=VBoxContainer.new();pc_map_results.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search_scroll.add_child(pc_map_results)
 _wmap_list.get_parent().get_parent().add_child(search_scroll)
 search_scroll.hide()
 var pin_row:=HBoxContainer.new();_wmap.body.add_child(pin_row)
 pc_pin_note=_label("ค้นหาเพื่อเลือกปลายทาง · ปักหมุดได้ครั้งละหนึ่งจุด",11,INK_L)
 pc_pin_note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 pin_row.add_child(pc_pin_note)
 pin_row.add_child(_button("ล้างหมุด",func():pc_pin.clear();_pc_save();_fill_worldmap()))
 _wmap.panel.visibility_changed.connect(func():
  if _wmap.panel.visible:_pc_index_map();_pc_filter_map())

func _pc_index_map() -> void:
 pc_map_entries.clear()
 for npc in get_tree().get_nodes_in_group("npc"):
  if not npc is Node3D:continue
  var area=VillageBuilder.area_at(npc.global_position)
  pc_map_entries.append({"name":tr(npc.npc_name),"kind":1,"area":area,"position":npc.global_position,"npc":weakref(npc)})
 for zone in load("res://scripts/monsters/spawner.gd").ZONES:
  pc_map_entries.append({"name":tr(zone.name)+" · Lv."+str(zone.lv),"kind":4 if zone.get("boss",false) else 3,"area":str(zone.get("area","town")),"position":Vector3(zone.pos.x,0,zone.pos.y),"zone":zone})
 for id in Items.DB:
  var sources: Array=Gathering.sources(id)
  for source in sources:
   var area=str(source[1])
   var center=VillageBuilder.AREAS[area].get_center() if VillageBuilder.AREAS.has(area) else Vector2.ZERO
   pc_map_entries.append({"name":Items.item_name(id),"id":str(id),"kind":2,"area":area,"position":Vector3(center.x,0,center.y),"approximate":true})

func _pc_filter_map() -> void:
 if not is_instance_valid(pc_map_results):return
 _pc_clear(pc_map_results)
 var query=pc_map_search.text.strip_edges().to_lower()
 var searching=query!="" or pc_map_kind.selected!=0
 pc_map_scroll.visible=searching
 pc_map_original_scroll.visible=not searching
 if not searching:
  pc_map_results.add_child(_label("พิมพ์ชื่อ หรือเลือกประเภท เพื่อค้นหาจากทุกแผนที่",12,INK_L))
  return
 var count:=0
 for entry in pc_map_entries:
  if pc_map_kind.selected!=0 and entry.kind!=pc_map_kind.selected:continue
  var area_name=tr(VillageBuilder.AREA_NAMES.get(entry.area,entry.area))
  if query!="" and not (entry.name+" "+area_name+" "+str(entry.get("id",""))).to_lower().contains(query):continue
  count+=1
  if count>80:continue
  var row:=VBoxContainer.new();row.add_theme_constant_override("separation",4)
  var text:=_label(entry.name+" · "+area_name+(" (พื้นที่พบ)" if entry.get("approximate",false) else ""),12,TITLE)
  text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.custom_minimum_size.x=240
  row.add_child(text)
  var actions:=HBoxContainer.new();row.add_child(actions)
  actions.add_child(_button("ปักหมุด",func():_pc_set_pin(entry)))
  actions.add_child(_button("ไป",func():_pc_travel(entry)))
  pc_map_results.add_child(row)
 if count==0:pc_map_results.add_child(_label("ไม่พบปลายทางที่ตรงกัน",12,INK_L))
 elif count>80:pc_map_results.add_child(_label("พบ %d รายการ · แสดง 80 รายการแรก กรุณาระบุชื่อเพิ่ม"%count,11,INK_L))

func _pc_set_pin(entry: Dictionary) -> void:
 pc_pin={"name":str(entry.name),"area":str(entry.area),"position":entry.position,"approximate":entry.get("approximate",false)}
 _pc_save()
 _fill_worldmap()

func _fill_worldmap() -> void:
 super._fill_worldmap()
 if not pc_ready:return
 if is_instance_valid(pc_pin_note):pc_pin_note.text="ค้นหาเพื่อเลือกปลายทาง · ปักหมุดได้ครั้งละหนึ่งจุด"
 if pc_pin.is_empty():return
 var point: Vector2
 if _wmap_world:
  point=WORLD_SPOTS.get(pc_pin.area,WORLD_SPOTS.town)*WMAP_PX
 else:
  var player=get_tree().get_first_node_in_group("player")
  if not is_instance_valid(player) or VillageBuilder.area_at(player.global_position)!=pc_pin.area:
   if is_instance_valid(pc_pin_note):pc_pin_note.text="หมุด: "+pc_pin.name+" · "+tr(VillageBuilder.AREA_NAMES.get(pc_pin.area,pc_pin.area))+" (เปิดแท็บโลกเพื่อดู)"
   return
  point=_world_to_wmap(pc_pin.position)
 var mark:=_label("◆",22,Color("7be6ee"),true)
 mark.position=point-Vector2(10,15);mark.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _wmap_marks.add_child(mark)
 pc_pin_mark=mark
 if is_instance_valid(pc_pin_note):pc_pin_note.text="หมุด: "+pc_pin.name+(" · ระบุตำแหน่งระดับพื้นที่" if pc_pin.get("approximate",false) else "")

func _pc_travel(entry: Dictionary) -> void:
 if entry.has("npc"):
  var npc=entry.npc.get_ref()
  if is_instance_valid(npc):_go_npc(npc)
 elif entry.has("zone"):_go_zone(entry.zone)
 elif entry.has("id"):
  _wmap.panel.hide()
  var player=get_tree().get_first_node_in_group("player")
  if is_instance_valid(player):player.start_resource_trip(entry.id,str(entry.area))

# ---------------- bounded combat feedback, optional boss wind-up warning ----------------
func _pc_build_log() -> void:
 pc_log=_window("ประวัติการต่อสู้",Vector2(350,170),Vector2(560,0),R_TEAL)
 var toolbar:=HBoxContainer.new()
 toolbar.add_child(_button("ล้างประวัติ",func():pc_log_rows.clear();pc_log_dirty=true))
 toolbar.add_child(_button("เริ่ม / หยุดบันทึก",_pc_toggle_record))
 pc_log.body.add_child(toolbar)
 pc_buff_text=_label("",12,ACCENT)
 pc_buff_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;pc_buff_text.custom_minimum_size.x=520
 pc_log.body.add_child(pc_buff_text)
 pc_log_text=RichTextLabel.new();pc_log_text.custom_minimum_size=Vector2(520,240);pc_log_text.scroll_following=true
 pc_log_text.add_theme_font_size_override("normal_font_size",12)
 pc_log.body.add_child(pc_log_text)
 pc_log.body.add_child(_label("150 เหตุการณ์ล่าสุด · ตั้งค่าการบันทึกและคำเตือนในเครื่องมือ PC",11,INK_L))
 pc_log.panel.hide()

func record_combat_event(victim: Node,text: String,crit: bool,miss: bool) -> void:
 if not pc_ready or not pc_log_enabled:return
 var who="ตัวละคร" if victim.is_in_group("player") else (tr(str(victim.get("display_name"))) if victim is Monster else str(victim.name))
 var seconds=Time.get_ticks_msec()/1000.0
 var label="ได้รับ" if victim.is_in_group("player") else "เกิดกับ"
 pc_log_rows.append("[%02d:%02d] %s %s · %s%s"%[int(seconds)/60,int(seconds)%60,label,who,"MISS" if miss else text," CRITICAL" if crit else ""])
 if pc_log_rows.size()>150:pc_log_rows.pop_front()
 pc_log_dirty=true

func _pc_update_boss(_delta: float) -> void:
 if not pc_boss_alert:
  pc_alert.hide()
  return
 pc_boss_tick-=0.2
 if pc_boss_tick<=0:
  pc_boss_tick=1.0
  pc_bosses.clear()
  for monster in get_tree().get_nodes_in_group("monster"):
   if pc_boss_names.has(monster.display_name):pc_bosses.append(weakref(monster))
 var player=get_tree().get_first_node_in_group("player")
 if not is_instance_valid(player):pc_alert.hide();return
 var warning=""
 for reference in pc_bosses:
  var monster=reference.get_ref()
  if not is_instance_valid(monster) or not monster.is_alive():continue
  if monster.state==Monster.State.ATTACK and not monster._hit_done and monster.global_position.distance_to(player.global_position)<monster.attack_range+2.0:
   var left=maxf(0.0,monster.hit_time-monster._state_t)
   if left>0:warning="⚠ "+tr(monster.display_name)+" กำลังโจมตี · %.1fs"%left;break
 pc_alert.visible=warning!=""
 if pc_alert.visible:
  pc_alert.text=warning
  var vp=get_viewport().get_visible_rect().size
  pc_alert.position=Vector2(vp.x*0.5-180,174)
  pc_alert.size=Vector2(360,36)


func _pc_reset_layout() -> void:
 pc_layout.clear();pc_hidden.clear()
 for box in pc_boxes.values():box.scale=Vector2.ONE
 for check in pc_visibility_checks.values():check.set_pressed_no_signal(true)
 _pc_save();super.layout_defaults();_pc_apply_layout()


# Existing title-bar dragging now restores a window where it was last closed.
func _window(title: String,pos: Vector2,min_size: Vector2,accent:=R_BROWN,closable:=true) -> Dictionary:
 var result=super._window(title,pos,min_size,accent,closable)
 result.panel.set_meta("pc_window_title",title)
 result.panel.visibility_changed.connect(func():
  if not pc_ready:return
  if result.panel.visible:_pc_fit_popup.call_deferred(result.panel,title)
  else:
   var vp=get_viewport().get_visible_rect().size
   pc_cfg.set_value("windows",title,result.panel.position/vp)
   _pc_save())
 return result

func _pc_fit_popup(panel: Control,title: String) -> void:
 if not is_instance_valid(panel) or not panel.visible:return
 var vp=get_viewport().get_visible_rect().size
 var size=panel.size.max(panel.get_combined_minimum_size())
 panel.scale=Vector2.ONE*minf(1.0,minf((vp.x-24)/maxf(size.x,1),(vp.y-24)/maxf(size.y,1)))
 var restored=pc_cfg.get_value("windows",title,Vector2(-1,-1))
 if restored is Vector2 and restored.x>=0 and restored.y>=0:panel.position=restored*vp
 panel.position=panel.position.clamp(Vector2(8,8),(vp-size*panel.scale-Vector2(8,8)).max(Vector2(8,8)))


func _pc_toggle_record() -> void:
 pc_log_enabled=not pc_log_enabled
 if is_instance_valid(pc_record_check):pc_record_check.set_pressed_no_signal(pc_log_enabled)
 _pc_save()
 add_message("บันทึกดาเมจ: "+("เปิด" if pc_log_enabled else "ปิด"),INK_L)


func _pc_tight_compare(anchor: Control) -> void:
 if not is_instance_valid(anchor) or not pc_compare.visible:return
 pc_compare.size=pc_compare.get_combined_minimum_size()
 var vp=get_viewport().get_visible_rect().size
 var point=anchor.get_global_rect()
 pc_compare.position=Vector2(clampf(point.end.x+10,8,maxf(8,vp.x-pc_compare.size.x-8)),clampf(point.position.y,8,maxf(8,vp.y-pc_compare.size.y-8)))
