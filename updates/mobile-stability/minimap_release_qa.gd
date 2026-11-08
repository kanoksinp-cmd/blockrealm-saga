extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 for i in 6:await process_frame
 var ui=root.get_node("Game").ui
 ui._update_minimap()
 var before:int=ui._map_dots.get_child_count()
 var keys:int=ui._mon_dots.size()
 var enemy=load("res://scripts/monsters/slime.gd").new();scene.add_child(enemy);enemy.set_physics_process(false)
 ui._update_minimap()
 assert(ui._map_dots.get_child_count()==before+1)
 enemy._enter(load("res://scripts/monsters/monster.gd").State.DEAD)
 ui._update_minimap();enemy.queue_free()
 for i in 3:await process_frame
 ui._update_minimap()
 assert(ui._map_dots.get_child_count()==before and ui._mon_dots.size()==keys,"dead actor minimap entries leaked after unloading")
 print("PASS_MINIMAP_RELEASE dead/freed actor marker and dictionary entry removed")
 quit()
