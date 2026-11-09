extends SceneTree
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO
 root.size=Vector2i(1280,720)
 var g=root.get_node("Game")
 g.new_character("DesktopTest",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 current_scene=scene
 for i in 16: await process_frame
 var ui=g.ui
 ui.layout_defaults()
 for i in 8: await process_frame
 var snapshot={"script":ui.get_script().resource_path,"viewport":str(root.get_visible_rect().size),"scale":root.content_scale_factor}
 for name in ["_info_panel","_map_panel","_menu","_pills","_chat_panel","_hot_panel","_party_frame","_clock"]:
  var c=ui.get(name)
  snapshot[name]=[str(c.position),str(c.size),str(c.scale)]
 var f=FileAccess.open(OS.get_environment("BR_SNAPSHOT"),FileAccess.WRITE)
 f.store_string(JSON.stringify(snapshot,"  "))
 f.close()
 scene.queue_free()
 for i in 6: await process_frame
 print("PC SNAPSHOT DONE")
 quit()
