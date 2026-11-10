extends SceneTree
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(800,500)
 var game=root.get_node("Game");game.new_character("DamageQA",load("res://scripts/voxel/avatar.gd").default_appearance())
 var world:=Node3D.new();root.add_child(world);current_scene=world
 var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(0,3,8);camera.look_at(Vector3(0,1,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=9.0
 var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("1c2939");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=0.8;camera.environment=env
 var model=load("res://scripts/characters/knight_model.gd").new();world.add_child(model)
 var light:=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-40,20,0)
 var p=load("res://scripts/combat/damage_popup.gd").new();p.anchor=Vector3(-0.65,2.0,0);p.setup("1280",Color.WHITE,false,false);world.add_child(p);p.set_process(false);p._age=0.1;p._process(0)
 var q=load("res://scripts/combat/damage_popup.gd").new();q.anchor=Vector3(1,2.2,0);q.setup("2456",Color("ffe26a"),true,false);world.add_child(q);q.set_process(false);q._age=0.1;q._process(0)
 await process_frame;await process_frame;RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE"));print("DAMAGE PREVIEW DONE")
 world.queue_free();await process_frame;quit()
