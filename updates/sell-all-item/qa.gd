extends SceneTree
func _initialize() -> void:call_deferred("run")
func frames(n:=5) -> void:
 for i in n:await process_frame
func run() -> void:
 await process_frame
 var g=root.get_node("Game")
 g.new_character("SaleQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);current_scene=main
 await frames()
 var ui=g.ui
 g.auto_on=false;g.inventory={"iron_ore":20000,"boar_hide":4,"potion_red":3};g.zeny=100
 var equipped:Dictionary=g.equip.duplicate(true)
 ui.open_shop("Shopkeeper",["potion_red"],false)
 await frames()
 var buttons:Array=[]
 var target:Button
 for button in ui._shop_grid.find_children("*","Button",true,false):
  if button.has_meta("sell_all_item"):
   buttons.append(button)
   if button.get_meta("sell_all_item")=="iron_ore":target=button
 assert(buttons.size()==3 and target!=null,"each sell card needs its own Sell All")
 var price:int=g.sell_price("iron_ore")
 g.add_item("iron_ore",7,true)
 target.pressed.emit()
 assert(g.count("iron_ore")==0,"whole current stack must sell, including amounts over 9999")
 assert(g.zeny==100+20007*price,"wrong total sale proceeds")
 assert(g.count("boar_hide")==4 and g.count("potion_red")==3 and g.equip==equipped,"sale touched other items or equipped gear")
 var balance:int=g.zeny
 target.pressed.emit()
 assert(g.zeny==balance,"duplicate activation paid twice")
 ui._trade_shop_item("boar_hide",1)
 assert(g.count("boar_hide")==3,"quantity-based sell broke")
 ui.open_shop("Shopkeeper",["potion_red"],true)
 await frames()
 for button in ui._shop_grid.find_children("*","Button",true,false):assert(not button.has_meta("sell_all_item"),"Sell All appeared in buy tab")
 balance=g.zeny
 var before:int=g.count("potion_red")
 ui._sell_all_shop_item("potion_red")
 assert(g.zeny==balance and g.count("potion_red")==before,"stale sell action bought items")
 ui.open_shop("Shopkeeper",[],false)
 await frames()
 if ui.get("_touch_ready")==true:
  ui._fit_windows();await frames()
  assert(root.get_visible_rect().grow(1).encloses(ui._shop.panel.get_global_rect()),"mobile shop clipped")
  for button in ui._shop_grid.find_children("*","Button",true,false):
   if button.has_meta("sell_all_item"):assert(button.custom_minimum_size.y>=54,"touch target too small")
 print("PASS_SELL_ALL mobile=",OS.get_environment("BR_MOBILE")," current stack, 20k+ quantity, exact proceeds, other/equipped items retained, repeat safe, quantity sell and buy tab retained")
 quit()
