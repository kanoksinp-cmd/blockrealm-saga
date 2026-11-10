extends Node
## Website artwork, cached static thumbnails and the existing fashion recipes.
var ui
var catalog: Dictionary = {}
var detail: Dictionary = {}
var craft_context := false
var vendor: WeakRef
var textures := {}
var status_labels: Array = []
var selected := ""
var craft_button: Button
var wear_button: Button
var detail_status: Label
var detail_wallet: Label
var material_rows: Array = []
var refresh_left := 0.0

func setup(owner_ui) -> void:
 ui=owner_ui

func _art(id: String) -> Texture2D:
 if not textures.has(id):
  var image=Image.load_from_file("res://assets/ui/fashion_cards/"+id+".png")
  textures[id]=ImageTexture.create_from_image(image) if image!=null else null
 return textures[id]

func _picture(id: String,height: float) -> TextureRect:
 var image:=TextureRect.new()
 image.texture=_art(id)
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size=Vector2(0,height)
 image.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 image.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 return image

func open() -> void:
 craft_context=false
 vendor=null
 if catalog.is_empty():
  catalog=ui._window("แฟชั่น · เลือกจากภาพชุด",Vector2(180,65),Vector2(860,0),ui.R_TEAL)
  var header:=HBoxContainer.new()
  header.add_child(ui._label("เลือกชุดเพื่อดูภาพ วัตถุดิบ และค่าสถานะ",12,ui.INK_L))
  var space:=Control.new();space.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(space)
  header.add_child(ui._button("ถอดแฟชั่น",func():Game.set_fashion("");ui._refresh_equipment();_refresh()))
  catalog.body.add_child(header)
  var scroll:=ScrollContainer.new()
  scroll.custom_minimum_size=Vector2(0,380)
  scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
  var holder:=VBoxContainer.new();holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  scroll.add_child(holder);catalog.body.add_child(scroll)
  catalog.panel.set_meta("fashion_holder",holder)
 var holder: Control=catalog.panel.get_meta("fashion_holder")
 _clear(holder)
 fill(holder,false)
 catalog.panel.show();catalog.panel.move_to_front()
 if ui._mobile:ui._fit_windows.call_deferred()

func _clear(node: Node) -> void:
 for child in node.get_children():node.remove_child(child);child.queue_free()

func fill(parent: Control,crafting: bool) -> void:
 craft_context=crafting
 if crafting:
  _wrap_smith_tabs()
  vendor=null
  var player=get_tree().get_first_node_in_group("player")
  var nearest:=5.0
  if is_instance_valid(player):
   for npc in get_tree().get_nodes_in_group("npc"):
    if npc.npc_name!=ui._fashion_vendor_name and tr(npc.npc_name)!=ui._fashion_vendor_name:continue
    var distance=player.global_position.distance_to(npc.global_position)
    if distance<nearest:nearest=distance;vendor=weakref(npc)
 status_labels=status_labels.filter(func(pair):return is_instance_valid(pair[0]))
 parent.add_child(ui._label("ภาพเดียวกับหน้าเว็บ · กดรูปชุดเพื่อดูรายละเอียด"+("และคราฟ" if crafting else ""),12,ui.INK_L))
 var grid:=GridContainer.new()
 var width=ui.get_viewport().get_visible_rect().size.x-64 if ui._mobile else 800.0
 grid.columns=clampi(floori(width/175.0),1,4)
 grid.add_theme_constant_override("h_separation",10)
 grid.add_theme_constant_override("v_separation",10)
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(grid)
 for id in Game.FASHION_ORDER:
  var f: Dictionary=Game.FASHIONS[id]
  var card:=Button.new()
  card.set_meta("fashion_id",id)
  card.custom_minimum_size=Vector2(158,264)
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  card.add_theme_stylebox_override("normal",ui._sb(Color("14212d"),Color("3e5260"),1,8,6))
  card.add_theme_stylebox_override("hover",ui._sb(Color("203443"),ui.GOLD,2,8,6))
  card.add_theme_stylebox_override("pressed",ui._sb(Color("2d3b37"),ui.GOLD,2,8,6))
  var content:=VBoxContainer.new()
  content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,7)
  content.mouse_filter=Control.MOUSE_FILTER_IGNORE
  content.add_theme_constant_override("separation",4)
  card.add_child(content)
  content.add_child(_picture(id,156))
  var name: Label=ui._label(f.name,13,ui.TITLE,true)
  name.custom_minimum_size.y=34
  name.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  content.add_child(name)
  var status: Label=ui._label("",11,ui.INK_L)
  status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  content.add_child(status)
  var price: Label=ui._label(ui._commas(int(f.recipe.zeny))+" Zeny",11,ui.GOLD,true)
  price.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  content.add_child(price)
  for node in content.find_children("*","Control",true,false):node.mouse_filter=Control.MOUSE_FILTER_IGNORE
  status_labels.append([status,id])
  card.pressed.connect(func():show_detail(id))
  grid.add_child(card)
 _refresh()

func _near_vendor() -> bool:
 var npc=vendor.get_ref() if vendor!=null else null
 var player=get_tree().get_first_node_in_group("player")
 return craft_context and is_instance_valid(npc) and is_instance_valid(player) and player.global_position.distance_to(npc.global_position)<5.0

func show_detail(id: String) -> void:
 if not Game.FASHIONS.has(id):return
 selected=id
 if detail.is_empty():detail=ui._window("รายละเอียดแฟชั่น",Vector2(230,90),Vector2(740,0),ui.R_TEAL)
 _clear(detail.body)
 material_rows.clear()
 var f: Dictionary=Game.FASHIONS[id]
 detail.title.text=f.name
 var portrait=ui._mobile and ui.get_viewport().get_visible_rect().size.y>ui.get_viewport().get_visible_rect().size.x
 var row: BoxContainer=VBoxContainer.new() if portrait else HBoxContainer.new()
 row.add_theme_constant_override("separation",16)
 detail.body.add_child(row)
 var artwork:=_picture(id,240)
 artwork.custom_minimum_size.x=0 if portrait else 230
 row.add_child(artwork)
 var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.add_theme_constant_override("separation",8)
 row.add_child(info)
 detail_status=ui._label("",13,ui.TITLE,true);info.add_child(detail_status)
 var stats: Label=ui._label(Items.stat_text(f.recipe.id),12,ui.ACCENT)
 stats.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 stats.custom_minimum_size.x=250 if not portrait else 0
 info.add_child(stats)
 var about: Label=ui._label(Items.desc(f.recipe.id),12,ui.INK)
 about.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;about.custom_minimum_size.x=250 if not portrait else 0;info.add_child(about)
 info.add_child(ui._label("วัตถุดิบสำหรับคราฟทั้งเซ็ต",13,ui.TITLE,true))
 for material in f.recipe.mats:
  var need=int(f.recipe.mats[material])
  var line:=HBoxContainer.new()
  var count: Label=ui._label("",12,ui.INK)
  count.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  line.add_child(count)
  line.add_child(ui._button("ไปหา",func():_find_material(material)))
  info.add_child(line)
  material_rows.append([count,material,need])
 detail_wallet=ui._label("",12,ui.GOLD,true);info.add_child(detail_wallet)
 var actions:=HFlowContainer.new()
 actions.add_theme_constant_override("h_separation",8);actions.add_theme_constant_override("v_separation",8)
 detail.body.add_child(actions)
 craft_button=ui._button("คราฟทั้งเซ็ต",_craft)
 craft_button.custom_minimum_size=Vector2(160,60 if ui._mobile else 36)
 actions.add_child(craft_button)
 wear_button=ui._button("สวมชุด",_wear)
 wear_button.custom_minimum_size=Vector2(120,60 if ui._mobile else 36)
 actions.add_child(wear_button)
 actions.add_child(ui._button("กลับไปเลือกชุด",_back))
 _refresh()
 detail.panel.show();detail.panel.move_to_front()
 if ui._mobile:ui._fit_windows.call_deferred()

func _refresh() -> void:
 status_labels=status_labels.filter(func(pair):return is_instance_valid(pair[0]))
 for pair in status_labels:
  var id: String=pair[1]
  pair[0].text="สวมอยู่" if Game.worn_fashion()==id else ("ปลดล็อกแล้ว" if Game.owns_fashion(id) else ("ยังไม่ปลดล็อก" if Game.fashion_job_ok(id) else "สำหรับอาชีพอื่น"))
  pair[0].add_theme_color_override("font_color",ui.GOOD if Game.owns_fashion(id) else ui.INK_L)
 if selected=="" or not is_instance_valid(detail_status):return
 var f: Dictionary=Game.FASHIONS[selected]
 var owned=Game.owns_fashion(selected)
 detail_status.text="สวมอยู่" if Game.worn_fashion()==selected else ("ปลดล็อกแล้ว" if owned else "ยังไม่ปลดล็อก · คราฟครั้งเดียวต่อเซ็ต")
 if not Game.fashion_job_ok(selected):detail_status.text+=" · อาชีพปัจจุบันสวมไม่ได้"
 for pair in material_rows:
  if not is_instance_valid(pair[0]):continue
  var have=Game.count(pair[1])
  pair[0].text="%s  %d / %d"%[Items.item_name(pair[1]),have,pair[2]]
  pair[0].add_theme_color_override("font_color",ui.GOOD if have>=pair[2] else ui.BAD)
 detail_wallet.add_theme_color_override("font_color",ui.GOOD if Game.zeny>=int(f.recipe.zeny) else ui.BAD)
 detail_wallet.text="ค่าใช้จ่าย %s Zeny · มี %s"%[ui._commas(int(f.recipe.zeny)),ui._commas(Game.zeny)]
 if craft_context:
  craft_button.text="ปลดล็อกแล้ว" if owned else ("คราฟทั้งเซ็ต" if _near_vendor() else "ต้องอยู่ใกล้ช่าง")
  craft_button.disabled=owned or not _near_vendor() or not Game.fashion_job_ok(selected) or not Game.can_craft(f.recipe)
 else:
  craft_button.text="ไปหาช่างเพื่อคราฟ"
  craft_button.disabled=owned
 wear_button.disabled=not owned or not Game.fashion_job_ok(selected) or Game.worn_fashion()==selected

func _craft() -> void:
 if selected=="":return
 if not craft_context:
  _close_popups()
  ui._quest_go({"npc":"Blacksmith Doran"})
  return
 if not _near_vendor() or Game.owns_fashion(selected) or not Game.fashion_job_ok(selected):return
 var recipe: Dictionary=Game.FASHIONS[selected].recipe
 if not Game.can_craft(recipe):_refresh();return
 if Game.craft(recipe):
  Game.save_game()
  ui._refresh_equipment()
  _refresh()

func _wear() -> void:
 if selected!="" and Game.owns_fashion(selected) and Game.fashion_job_ok(selected):
  Game.set_fashion(selected)
  ui._refresh_equipment()
  _refresh()

func _back() -> void:
 detail.panel.hide()
 if craft_context:ui._smith.panel.show();ui._smith.panel.move_to_front()
 else:
  if catalog.is_empty():open()
  else:catalog.panel.show();catalog.panel.move_to_front()
 if ui._mobile:ui._fit_windows.call_deferred()

func _close_popups() -> void:
 for panel in ui._popups:panel.hide()

func _find_material(id: String) -> void:
 _close_popups()
 if not Gathering.sources(id).is_empty():ui._find_gather(id)
 else:ui._gather(id)

func _process(delta: float) -> void:
 refresh_left-=delta
 if refresh_left>0:return
 refresh_left=0.25
 if (not detail.is_empty() and detail.panel.visible) or (not catalog.is_empty() and catalog.panel.visible):_refresh()


func _wrap_smith_tabs() -> void:
 if not ui._mobile or ui.get_viewport().get_visible_rect().size.y<=ui.get_viewport().get_visible_rect().size.x:return
 if ui._smith_tabs.is_empty():return
 var original=ui._smith_tabs[0].get_parent()
 if not original is HBoxContainer:return
 var parent=original.get_parent()
 var index=original.get_index()
 var flow:=HFlowContainer.new()
 flow.add_theme_constant_override("h_separation",5)
 flow.add_theme_constant_override("v_separation",5)
 parent.add_child(flow);parent.move_child(flow,index)
 for child in original.get_children():child.reparent(flow)
 parent.remove_child(original);original.queue_free()
