extends SceneTree
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.mode=Window.MODE_WINDOWED;root.size=Vector2i(1200,800)
 var world:=Node3D.new();root.add_child(world);current_scene=world
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("111b29");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("b6c8e4");env.environment.ambient_light_energy=0.65;world.add_child(env)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-25,0);sun.light_energy=0.8;world.add_child(sun)
 var cam:=Camera3D.new();world.add_child(cam);cam.position=Vector3(0,17,20);cam.look_at(Vector3(0,0.7,0));cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=21
 var accent=load("res://scripts/combat/skill_power.gd")
 var element=load("res://scripts/combat/element_fx.gd")
 var fx=load("res://scripts/combat/fx.gd")
 var els=["physical","fire","lightning","ice","holy","shadow"]
 var sources:=[]
 for i in 6:
  var at:=Vector3((i%3-1)*6.0,0,(i/3)*7.0-3.5)
  var emitter:=Node3D.new();world.add_child(emitter);emitter.position=at;sources.append(emitter)
  var tile:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(5.6,0.15,6.0);tile.mesh=box;tile.position=at-Vector3.UP*0.1
  var mat:=StandardMaterial3D.new();mat.albedo_color=Color("253447");tile.material_override=mat;world.add_child(tile)
  # Neutral blocky training target establishes impact scale and readability.
  for part in [Vector3(0,0.45,0),Vector3(0,1.15,0),Vector3(0,1.78,0)]:
   var mi:=MeshInstance3D.new();var bm:=BoxMesh.new();bm.size=Vector3(0.72,0.65,0.45) if part.y<1.7 else Vector3.ONE*0.48;mi.mesh=bm
   var m:=StandardMaterial3D.new();m.albedo_color=Color("8493a5");mi.material_override=m;world.add_child(mi);mi.position=at+part
  var label:=Label3D.new();label.text=String(els[i]).to_upper();label.font_size=44;label.pixel_size=0.012;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;world.add_child(label);label.position=at+Vector3(0,0.2,2.8);label.no_depth_test=true
 await process_frame
 for i in 6:
  var el:String=els[i];var at:Vector3=sources[i].position
  if el in ["fire","lightning","ice"]:element.impact(sources[i],el,at,1.4)
  elif el=="holy":fx.pillar(sources[i],at,Color("ffe8a3"),0.7,5.0,0.5)
  elif el=="shadow":fx.flash(sources[i],at+Vector3.UP*0.5,Color("b16dff"),1.2)
  else:fx.slash_x(sources[i],at+Vector3.UP*0.8,Color("ffd18a"),1.0)
  accent.emit(sources[i],at,el,"melee" if el=="physical" else "aoe_target",2.0,1.5)
 await create_timer(0.14).timeout
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("BR_CAPTURE"))
 print("SKILL VISUAL DONE")
 await create_timer(3.0).timeout
 world.queue_free();await process_frame;quit()
