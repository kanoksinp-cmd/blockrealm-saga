extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 var g=root.get_node("Game")
 var settings=root.get_node("Settings")
 g.new_character("BackgroundQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var scene=Node.new();scene.name="Main";root.add_child(scene);current_scene=scene
 var writes:Array=[0]
 g.save_written.connect(func(_slot):writes[0]+=1)
 settings._set_mobile_background(true)
 settings._set_mobile_background(true)
 assert(writes[0]==1 and Engine.max_fps==5,"background must save once and reduce rendering")
 assert(g.save_summary().name=="BackgroundQA")
 settings._set_mobile_background(false)
 assert(writes[0]==1 and Engine.max_fps==30,"foreground must restore mobile cap")
 scene.name="Menu"
 settings._set_mobile_background(true)
 assert(writes[0]==1,"title must not overwrite a character save")
 print("PASS_BACKGROUND one save per background transition; 5/30 FPS; title protected")
 quit()
