extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 root.get_node("Game").world_hour=11.0
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 for i in 8:await process_frame
 root.get_node("Game").ui.hide()
 scene.get_node("Player").set_process(false);scene.get_node("Player").set_physics_process(false)
 var rig=scene.get_node("CameraRig");rig.set_process(false);rig.set_physics_process(false)
 var view:=SubViewport.new();view.size=Vector2i(1000,700);view.world_3d=scene.get_world_3d();view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
 var camera:=Camera3D.new();view.add_child(camera);camera.current=true;camera.fov=43;camera.far=80
 for entry in [["guild1",Vector3(187,25,23),Vector3(165,1,-1)],["guild2",Vector3(184,23,63),Vector3(163,1,39)],["smithy",Vector3(182,23,105),Vector3(160,1,79)]]:
  camera.position=entry[1];camera.look_at(entry[2])
  for i in 12:await process_frame
  RenderingServer.force_draw(false)
  view.get_texture().get_image().save_png(OS.get_environment("BR_PREVIEW_DIR").path_join(str(entry[0])+".png"))
 print("PASS_PREVIEW three furnished interiors rendered")
 quit()
