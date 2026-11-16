extends Node
var ui
var vendor: WeakRef
var source := ""
var target := ""
var source_menu: OptionButton
var target_menu: OptionButton
var preview: VBoxContainer
var review := {}
var busy := false
var message := ""
var _last_state := ""
var _clock := 0.0
var _menu_icons := {}

func setup(owner_ui) -> void:
 ui=owner_ui

func _label(text: String, size:=13, color:=Color.WHITE) -> Label:
 var l: Label=ui._label(text,size,color)
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return l

func _gear_ids() -> Array[String]:
 var out: Array[String]=[]
 for id in Game.inventory.keys()+Game.equip.values():
  if id is String and not id.is_empty() and Items.is_gear(id) and (Game.count(id)>0 or id in Game.equip.values()) and not id in out:out.append(id)
 out.sort_custom(func(a,b):return Items.item_name(a)<Items.item_name(b))
 return out

func _vendor() -> Node:
 return vendor.get_ref() if vendor else null

func fill(parent: Control) -> void:
 review.clear();vendor=null;message=""
 var player=get_tree().get_first_node_in_group("player")
 if is_instance_valid(player):
  for npc in get_tree().get_nodes_in_group("npc"):
   if npc.get("role")=="smith" and (npc.npc_name==ui._fashion_vendor_name or tr(npc.npc_name)==ui._fashion_vendor_name) and player.global_position.distance_to(npc.global_position)<=5.0:
    vendor=weakref(npc);break
 parent.add_child(_label("โอนระดับตีบวก · สำเร็จ 100%",17,ui.TITLE))
 parent.add_child(_label("อุปกรณ์ช่องเดียวกัน · อาวุธประเภทเดียวกัน · ต้นทางกลับเป็น +0",12,ui.INK_L))
 parent.add_child(_label("ค่าโอน = 1,000 × ระดับตีบวก² Zeny · +5 = 25,000 · +10 = 100,000",12,ui.GOLD))
 source_menu=_selector(parent,"1. เลือกอุปกรณ์ต้นทาง")
 _sources()
 target_menu=_selector(parent,"2. เลือกอุปกรณ์ที่จะรับระดับตีบวก")
 preview=VBoxContainer.new();preview.add_theme_constant_override("separation",10);parent.add_child(preview)
 source_menu.item_selected.connect(func(index):source=String(source_menu.get_item_metadata(index)) if index>0 else "";review.clear();message="";_targets();_render())
 target_menu.item_selected.connect(func(index):target=String(target_menu.get_item_metadata(index)) if index>0 else "";review.clear();message="";_render())
 if source_menu.selected<=0:source=""
 _targets();_render()
 # Wrap the growing smith tab bar on both mobile and desktop.
 var tabs: Control=ui._smith_tabs[0].get_parent()
 if tabs is HBoxContainer:
  var flow:=HFlowContainer.new();flow.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var outer=tabs.get_parent();outer.add_child(flow);outer.move_child(flow,tabs.get_index())
  for child in tabs.get_children():child.reparent(flow)
  tabs.queue_free()
 if ui._mobile:ui._fit_windows.call_deferred()

func _selector(parent: Control,title: String) -> OptionButton:
 parent.add_child(_label(title,13,ui.ACCENT))
 var menu:=OptionButton.new();menu.custom_minimum_size.y=60 if ui._mobile else 40;menu.clip_text=true;menu.add_theme_constant_override("icon_max_width",32);menu.size_flags_horizontal=Control.SIZE_EXPAND_FILL;menu.get_popup().max_size=Vector2i(420,420);menu.add_theme_font_size_override("font_size",15 if ui._mobile else 14);menu.get_popup().add_theme_font_size_override("font_size",15 if ui._mobile else 14);parent.add_child(menu);return menu

func _sources() -> void:
 source_menu.clear();source_menu.add_item("เลือกอุปกรณ์ที่มีระดับตีบวก")
 for id in _gear_ids():
  if Game.refine_lv(id)<=0:continue
  var i=source_menu.item_count;source_menu.add_icon_item(_menu_icon(id),Game.item_label(id));source_menu.set_item_metadata(i,id)
  if id==source:source_menu.select(i)
 if source_menu.selected<=0:source=""

func _targets() -> void:
 target_menu.clear();target_menu.add_item("เลือกปลายทางที่มีระดับตีบวกต่ำกว่า")
 for id in _gear_ids():
  if source.is_empty() or id==source or Items.slot_of(source)!=Items.slot_of(id):continue
  if Items.slot_of(id)=="weapon" and Items.weapon_type(source)!=Items.weapon_type(id):continue
  if Game.refine_lv(id)>=Game.refine_lv(source):continue
  var i=target_menu.item_count;target_menu.add_icon_item(_menu_icon(id),Game.item_label(id));target_menu.set_item_metadata(i,id)
  if id==target:target_menu.select(i)
 if target_menu.selected<=0:target=""
 target_menu.disabled=target_menu.item_count<=1

func _state() -> String:
 var player=get_tree().get_first_node_in_group("player")
 var npc=_vendor()
 var near=is_instance_valid(player) and is_instance_valid(npc) and player.global_position.distance_to(npc.global_position)<=5.0
 return str([Game.zeny,Game.refine,Game.inventory,Game.equip,near,is_instance_valid(player) and player.is_alive()])

func _render() -> void:
 if not is_instance_valid(preview):return
 for node in preview.get_children():preview.remove_child(node);node.queue_free()
 _last_state=_state()
 source_menu.disabled=not review.is_empty();target_menu.disabled=not review.is_empty() or target_menu.item_count<=1
 var quote=Game.refine_transfer_quote(source,target,_vendor())
 if not source.is_empty():_item_card(source,0,"ต้นทางหลังโอน")
 if not target.is_empty():_item_card(target,Game.refine_lv(source),"ปลายทางหลังโอน")
 if not source.is_empty() and not target.is_empty():
  preview.add_child(_label("ระดับเดิมของปลายทางจะถูกแทนที่ ไม่ใช่การบวกรวมระดับ",12,ui.R_YELLOW))
  preview.add_child(_label("เกมนี้ใช้ระดับตีบวกร่วมกันสำหรับอุปกรณ์ชื่อเดียวกัน การโอนจะมีผลกับทุกชิ้นของทั้งสองชื่อ",12,ui.INK_L))
 preview.add_child(_label("ค่าโอน: %s Zeny · มีอยู่ %s Zeny" % [ui._commas(quote.cost),ui._commas(Game.zeny)],14,ui.GOLD))
 preview.add_child(_label(message if not message.is_empty() else quote.reason,13,ui.GOOD if quote.ok or message.begins_with("โอนระดับตีบวกสำเร็จ") else ui.BAD))
 if review.is_empty():
  var button=ui._button("ตรวจสอบก่อนโอน",_review,0);button.custom_minimum_size.y=60 if ui._mobile else 42;button.disabled=not quote.ok;preview.add_child(button)
 else:
  preview.add_child(_label("ยืนยันการโอน +%d ไปยัง %s?" % [review.source_level,Items.item_name(target)],15,ui.TITLE))
  var confirm=ui._button("ยืนยัน · จ่าย %s Zeny" % ui._commas(review.cost),_commit,0);confirm.custom_minimum_size.y=60 if ui._mobile else 42;confirm.disabled=not quote.ok or busy;ui._color_button(confirm,ui.BTN_GREEN);preview.add_child(confirm)
  var cancel=ui._button("กลับไปเลือกใหม่",func():review.clear();_render(),0);cancel.custom_minimum_size.y=60 if ui._mobile else 36;preview.add_child(cancel)
 if ui._mobile:ui._fit_windows.call_deferred()

func _item_card(id: String, after: int, title: String) -> void:
 var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",ui._sb(Color("17232e"),ui.LINE,1,8,10));preview.add_child(panel)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);panel.add_child(row)
 var icon=ui._icon_rect(Items.icon(id),48);row.add_child(icon)
 var box:=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(box)
 box.add_child(_label(title+" · "+Items.item_name(id),13,ui.ACCENT))
 box.add_child(_label("+%d → +%d" % [Game.refine_lv(id),after],20,ui.TITLE))
 var stat="ATK" if Items.slot_of(id)=="weapon" else "DEF"
 box.add_child(_label("โบนัสตีบวก %s: +%d → +%d" % [stat,Game.refine_bonus(id),Game.refine_bonus(id,after)],12,ui.INK_L))

func _review() -> void:
 review=Game.refine_transfer_quote(source,target,_vendor())
 if not review.ok:review.clear()
 _render()
 _show_confirmation.call_deferred()

func _commit() -> void:
 if busy or review.is_empty():return
 busy=true
 var result=Game.try_transfer_refine(source,target,review.source_level,review.target_level,_vendor())
 review.clear();busy=false
 message="โอนระดับตีบวกสำเร็จ · %s → %s · บันทึกแล้ว" % [Items.item_name(source),Items.item_name(target)] if result=="ok" else result
 if result=="ok":
  source="";target="";_sources();_targets()
 ui._smith_msg.text=message
 _render()

func _process(delta: float) -> void:
 _clock+=delta
 if _clock<0.5:return
 _clock=0
 if not is_instance_valid(preview) or not ui._smith.panel.visible or ui._smith_tab!=11:return
 if _state()!=_last_state:
  review.clear();message="ข้อมูลอุปกรณ์หรือเงินเปลี่ยนแล้ว กรุณาตรวจสอบอีกครั้ง";_sources();_targets();_render()


func _menu_icon(id: String) -> Texture2D:
 if not _menu_icons.has(id):
  var image=Items.icon(id).get_image()
  image.resize(32,32,Image.INTERPOLATE_LANCZOS)
  _menu_icons[id]=ImageTexture.create_from_image(image)
 return _menu_icons[id]

func _show_confirmation() -> void:
 await get_tree().process_frame
 if review.is_empty() or not is_instance_valid(preview) or not ui._smith.panel.visible:return
 var scroll=ui._smith_list.get_parent() as ScrollContainer
 if scroll and preview.get_child_count()>0:scroll.ensure_control_visible(preview.get_child(preview.get_child_count()-1))
