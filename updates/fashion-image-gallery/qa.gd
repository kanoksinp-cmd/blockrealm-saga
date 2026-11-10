extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=6) -> void:
 for i in n:await process_frame
func _initialize() -> void:
 await process_frame
 var game=root.get_node("Game")
 game.new_character("FashionQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames(15)
 Engine.max_fps=0
 var ui=game.ui
 ui._open_mage_fashion()
 await frames()
 var gallery=ui._fashion_gallery
 check(gallery.catalog.panel.visible,"wardrobe opens image gallery")
 var holder=gallery.catalog.panel.get_meta("fashion_holder")
 var cards=holder.get_child(1).get_children()
 check(cards.size()==game.FASHION_ORDER.size(),"one card per fashion")
 for i in cards.size():
  check(cards[i].get_meta("fashion_id")==game.FASHION_ORDER[i],"card matches fashion order")
  check(gallery._art(game.FASHION_ORDER[i])!=null,"website artwork present")
 gallery.show_detail("crimson_bastion")
 await frames()
 check(gallery.selected=="crimson_bastion" and gallery.detail.panel.visible,"card opens correct detail")
 var old_gold=game.zeny
 gallery._craft()
 check(game.zeny==old_gold and not game.owns_fashion("crimson_bastion"),"inventory gallery cannot craft remotely")
 var player=get_first_node_in_group("player")
 var vendors=get_nodes_in_group("npc").filter(func(n):return n.npc_name=="Blacksmith Doran")
 check(not vendors.is_empty(),"blacksmith exists")
 var vendor=vendors[0]
 player.global_position=vendor.global_position+Vector3(1,0,0)
 if not ui._mobile:
  ui.open_shop(vendor.npc_name,[],false)
  check(ui.pc_shop_vendor==vendor,"shop resolves actual NPC")
  ui._shop.panel.hide()
 ui.open_smith("Blacksmith Doran",7)
 await frames()
 check(gallery.craft_context,"NPC fashion tab uses gallery crafting context")
 gallery.show_detail("crimson_bastion")
 var recipe=game.FASHIONS.crimson_bastion.recipe
 game.zeny=50000
 for material in recipe.mats:game.add_item(material,int(recipe.mats[material])+3,true)
 gallery._refresh()
 check(not gallery.craft_button.disabled,"craft enables when materials and zeny ready")
 var materials=game.inventory.duplicate()
 old_gold=game.zeny
 gallery._craft()
 check(game.owns_fashion("crimson_bastion"),"craft unlocks permanent fashion")
 check(game.zeny==old_gold-int(recipe.zeny),"craft charges exact zeny")
 for material in recipe.mats:check(game.count(material)==int(materials[material])-int(recipe.mats[material]),"craft consumes exact materials")
 var after_gold=game.zeny
 gallery._craft();check(game.zeny==after_gold,"owned outfit cannot be crafted twice")
 gallery._wear();check(game.worn_fashion()=="crimson_bastion","unlocked card equips matching outfit")
 gallery.show_detail("iron_warden")
 vendor.global_position+=Vector3(20,0,0)
 game.zeny=50000
 for material in game.FASHIONS.iron_warden.recipe.mats:game.add_item(material,20,true)
 gallery._refresh();check(gallery.craft_button.disabled,"craft disabled when away from NPC")
 gallery._craft();check(not game.owns_fashion("iron_warden"),"remote craft blocked at activation")
 for dimensions in [Vector2i(1280,720),Vector2i(390,844)]:
  root.min_size=Vector2i.ZERO;root.size=dimensions
  await frames()
  gallery.open();await frames()
  if ui._mobile:ui._fit_windows();await frames()
  var rect=gallery.catalog.panel.get_global_rect();var vp=root.get_visible_rect().size
  check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=vp.x+2 and rect.end.y<=vp.y+2,"gallery fits viewport")
 gallery._find_material("gold_ore")
 check(player._auto_gather_item=="gold_ore","material find starts resource auto travel after closing dialogs")
 player._stop_all();game.auto_on=false
 print("FASHION GALLERY ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)
