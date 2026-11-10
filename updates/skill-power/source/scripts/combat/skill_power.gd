extends Node3D
## Bounded, batched skill accents. Visual-only: no combat state, timers or hit callbacks.
const PALETTE = {
 "physical":Color("ffd18a"), "fire":Color("ff6b20"), "ice":Color("83e5ff"),
 "lightning":Color("fff17c"), "water":Color("49acff"), "wind":Color("8fffc6"),
 "earth":Color("e6b374"), "holy":Color("ffe8a3"), "shadow":Color("c18aff")}
var age := 0.0
var lifetime := 0.65
var span := 1.0
var power := 1.0
var phase := "impact"
var element := "physical"
var style := "melee"
var layers: Array[MeshInstance3D] = []
var inks: Array[StandardMaterial3D] = []

static func emit(from: Node3D, pos: Vector3, el: String, kind: String, strength: float, radius: float, stage := "impact") -> Node3D:
 if not is_instance_valid(from) or not from.is_inside_tree(): return null
 var tree := from.get_tree()
 var mobile: bool = from.get_node("/root/Settings").is_mobile()
 if tree.get_nodes_in_group("skill_power_accents").size() >= (7 if mobile else 18): return null
 var camera := from.get_viewport().get_camera_3d()
 if camera and camera.global_position.distance_to(pos) > 65.0: return null
 # Multi-hit finishers keep their impact; dense simultaneous releases are coalesced.
 var key := StringName("skill_accent_" + stage)
 var now := Time.get_ticks_msec()
 if now - int(from.get_meta(key, -1000)) < (110 if mobile else 65): return null
 from.set_meta(key, now)
 var fx = load("res://scripts/combat/skill_power.gd").new()
 fx.element=el;fx.style=kind;fx.phase=stage
 fx.power=clampf(strength,1.0,2.1)
 fx.span=clampf(radius,0.75,6.0)
 fx.lifetime=0.48 if stage=="release" else (0.8 if kind in ["heal","buff"] else 0.66)
 fx.add_to_group("skill_power_accents")
 var scene := tree.current_scene
 (scene if scene else tree.root).add_child(fx)
 fx.global_position=pos+Vector3(0,0.09,0)
 fx.rotation.y=from.model.rotation.y if from.get("model") is Node3D else from.rotation.y
 fx._build(mobile)
 return fx

func _line(st: SurfaceTool, a: Vector3, b: Vector3, width: float, col: Color) -> void:
 var d := (b-a).normalized()
 var side := d.cross(Vector3.UP)
 if side.length_squared()<0.01: side=Vector3.RIGHT
 side=side.normalized()*width
 for v in [a-side,a+side,b+side,a-side,b+side,b-side]:
  st.set_color(col);st.add_vertex(v)

func _ribbon(st: SurfaceTool, r: float, y: float, start: float, sweep: float, width: float, col: Color, rise := 0.0) -> void:
 var segments := 20
 for i in segments:
  var t0 := float(i)/segments
  var t1 := float(i+1)/segments
  var a := start+sweep*t0
  var b := start+sweep*t1
  var w0 := width*(0.25+0.75*sin(t0*PI))
  var w1 := width*(0.25+0.75*sin(t1*PI))
  for v in [Vector3(cos(a)*(r-w0),y+rise*t0,sin(a)*(r-w0)),Vector3(cos(a)*(r+w0),y+rise*t0,sin(a)*(r+w0)),Vector3(cos(b)*(r+w1),y+rise*t1,sin(b)*(r+w1)),Vector3(cos(a)*(r-w0),y+rise*t0,sin(a)*(r-w0)),Vector3(cos(b)*(r+w1),y+rise*t1,sin(b)*(r+w1)),Vector3(cos(b)*(r-w1),y+rise*t1,sin(b)*(r-w1))]:
   st.set_color(col);st.add_vertex(v)

func _build(mobile: bool) -> void:
 var tint: Color=PALETTE.get(element,PALETTE.physical)
 var support := style in ["heal","buff"]
 if style=="heal": tint=Color("8dffbd")
 for layer in 2:
  var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var core := layer==1
  var col := tint.lightened(0.7) if core else tint
  col.a=0.95 if core else 0.58
  var w := (0.022 if core else 0.085)*(0.85+power*0.18)
  var count := (5 if mobile else 8) + int(power-1.0)
  # Thin broken shockwave leaves the floor and enemies readable.
  for i in (3 if mobile else 5):
   var n := 3.0 if mobile else 5.0
   _ribbon(st,1.0,0.02,float(i)*TAU/n,TAU/n*0.72,w,col)
  if phase=="release" or support:
   for i in (3 if mobile else 5):
    var n := 3.0 if mobile else 5.0
    _ribbon(st,0.62,0.12,float(i)*TAU/n,PI*0.7,w,col,0.9)
   if support:
    for i in count:
     var a := TAU*i/count
     var at := Vector3(cos(a)*0.65,0.65,sin(a)*0.65)
     _line(st,at-Vector3.UP*0.12,at+Vector3.UP*0.12,w,col)
     _line(st,at-Vector3.RIGHT*0.1,at+Vector3.RIGHT*0.1,w,col)
  elif element=="physical" or style=="melee":
   _line(st,Vector3(-0.7,0.2,0),Vector3(0.85,1.7,0),w*1.5,col)
   _line(st,Vector3(0.7,0.2,0),Vector3(-0.85,1.7,0),w*1.1,col)
   _ribbon(st,0.72,0.7,-PI*0.9,PI*1.4,w*2.1,col,0.4)
   _ribbon(st,0.65,1.15,PI*0.2,-PI*1.4,w*1.5,col,-0.65)
   for i in count:
    var a := TAU*i/count
    _line(st,Vector3(cos(a)*0.3,0.7,sin(a)*0.3),Vector3(cos(a)*1.2,0.9+0.12*(i%3),sin(a)*1.2),w,col)
  elif element=="lightning":
   for i in (2 if mobile else 3):
    var base := Vector3((i-1)*0.35,0,0)
    for k in 5:
     var a := base+Vector3(0.18 if k%2==0 else -0.15,float(k)*0.7,0)
     var b := base+Vector3(-0.15 if k%2==0 else 0.18,float(k+1)*0.7,0)
     _line(st,a,b,w*1.3,col)
  elif element in ["wind","water","shadow"]:
   for i in (2 if mobile else 3):
    _ribbon(st,0.8-i*0.12,0.15+i*0.28,i*2.1,PI*1.65,w*1.4,col,1.05)
   if element=="shadow":
    _ribbon(st,0.38,1.5,0,TAU,w*1.5,col)
  elif element=="holy":
   _line(st,Vector3(0,0.2,0),Vector3(0,3.0,0),w*2.0,col)
   _line(st,Vector3(-0.75,2.1,0),Vector3(0.75,2.1,0),w*1.5,col)
   _line(st,Vector3(0,2.1,-0.75),Vector3(0,2.1,0.75),w*1.5,col)
  else:
   if element=="fire":
    _ribbon(st,0.55,0.3,0,TAU,w*1.7,col,0.15)
   for i in count:
    var a := TAU*i/count
    var base := Vector3(cos(a)*0.75,0,sin(a)*0.75)
    var tip := base*1.3+Vector3.UP*(1.1+0.5*(i%3))
    # Tapered energy shards, heavier flame jets / icy and earthen fracture lines.
    _line(st,base,tip,w*2.0,col)
    _line(st,tip,tip+Vector3(cos(a)*0.15,0.2,sin(a)*0.15),w*0.5,col)
  var mi := MeshInstance3D.new();mi.mesh=st.commit()
  mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var mat := StandardMaterial3D.new()
  mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
  mat.cull_mode=BaseMaterial3D.CULL_DISABLED
  mat.vertex_color_use_as_albedo=true
  mi.material_override=mat
  add_child(mi);layers.append(mi);inks.append(mat)
 scale=Vector3.ONE*0.15

func _process(delta: float) -> void:
 age+=delta
 if age>=lifetime: queue_free();return
 var t := age/lifetime
 var grow := 1.0-pow(1.0-minf(t/0.38,1.0),3.0)
 var r := span*(0.22+0.78*grow)
 var h := 0.7+power*0.3
 scale=Vector3(r,h*(0.35+0.65*grow),r)
 if phase=="release": scale*=0.7
 for i in layers.size():
  layers[i].rotation.y=(0.4 if i==0 else -0.2)*t if element in ["wind","shadow","water"] or phase=="release" else 0.0
  inks[i].albedo_color.a=pow(1.0-t,1.2)*(0.7 if i==0 else 1.0)

static func projectile_tail(node: Node3D, tint: Color) -> void:
 # A single batched tapered wake follows skill bolts. No new light or particle emitter.
 var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for axis in [Vector3.RIGHT, Vector3.UP]:
  for v in [-axis*0.11,axis*0.11,Vector3(0,0,-1.4)]:
   st.set_color(Color(tint,0.6) if v.z > -1.0 else Color(tint,0.0))
   st.add_vertex(v)
 var mi := MeshInstance3D.new();mi.mesh=st.commit()
 mi.name="SkillEnergyWake"
 mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var mat := StandardMaterial3D.new()
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mat.vertex_color_use_as_albedo=true
 mi.material_override=mat
 node.add_child(mi)
