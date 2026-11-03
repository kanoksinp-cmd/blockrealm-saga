import bpy,math,os,json
from mathutils import Vector
O=os.path.dirname(os.path.abspath(__file__));R=os.path.abspath(os.path.join(O,'../career_expansion'));A=os.path.join(R,'assets/models/town');os.makedirs(A,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=True;s.render.resolution_x=1300;s.render.resolution_y=1400;s.render.resolution_percentage=100
col=bpy.data.collections.new('HANGING LANTERN POST');s.collection.children.link(col);parts=[]
def mat(n,c,metal=0,glow=0):
 m=bpy.data.materials.new(n);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.78
 if glow:p.inputs['Emission Color'].default_value=(*c,1);p.inputs['Emission Strength'].default_value=glow
 return m
wood=mat('Charred oak',(.052,.025,.013));grain=mat('Oak grain',(.11,.063,.031));iron=mat('Blackened iron',(.022,.029,.034),.4);steel=mat('Pale weathered stone',(.37,.41,.37));stone=mat('Dark stone foot',(.13,.15,.14));gold=mat('Warm brass',(.36,.19,.035),.3);glass=mat('Amber light',(.95,.32,.025),0,1.8);core=mat('Warm lantern core',(1,.72,.20),0,3)
def box(n,p,d,m,ang=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=n;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.rotation_euler.y=ang
 for c in list(o.users_collection):c.objects.unlink(o)
 col.objects.link(o);o.data.materials.append(m);parts.append(o);return o
def bar(n,a,b,w,d,m):
 a,b=Vector(a),Vector(b);o=box(n,(a+b)/2,(w,d,(b-a).length),m);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
box('Square stone footing',(0,0,.13),(.48,.48,.26),stone);box('Stone cap',(0,0,.30),(.40,.40,.12),steel)
box('Tall dark timber post',(0,0,1.51),(.145,.145,2.38),wood)
box('Front timber grain',(-.04,-.078,1.62),(.025,.012,1.81),grain)
for z in [.44,2.55]:box('Iron collar',(0,0,z),(.17,.17,.07),iron)
box('Horizontal hanging arm',(.36,0,2.70),(1.0,.16,.14),iron)
box('Post end cap',(0,0,2.82),(.19,.19,.12),wood)
bar('Angled brace',(.03,0,2.37),(.36,0,2.64),.075,.10,iron)
for z in [2.59,2.48]:
 box('Chain side A',(.68,-.035,z),(.028,.028,.13),iron);box('Chain side B',(.77,-.035,z),(.028,.028,.13),iron);box('Chain link',(.725,-.035,z+.055),(.12,.035,.025),iron)
box('Lantern roof',(.725,0,2.35),(.37,.34,.07),iron)
box('Stepped roof crown',(.725,0,2.41),(.24,.23,.07),iron)
box('Amber glass body',(.725,0,2.15),(.245,.225,.32),glass)
box('Glowing inner pane',(.725,-.123,2.15),(.105,.025,.23),core)
for x in [.575,.875]:
 for y in [-.14,.14]:box('Lantern iron corner',(x,y,2.15),(.045,.04,.36),iron)
for z in [1.96,2.33]:box('Lantern frame rim',(.725,0,z),(.35,.32,.055),iron)
box('Brass bottom knob',(.725,0,1.90),(.09,.09,.075),gold)
# Export one optimized mesh and an explicit light-location marker.
bpy.ops.object.select_all(action='DESELECT');copies=[]
for src in parts:
 o=src.copy();o.data=src.data.copy();s.collection.objects.link(o);o.select_set(True);copies.append(o)
bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);bpy.ops.object.join();merged=bpy.context.object;merged.name='hanging_lantern_post'
marker=bpy.data.objects.new('LightCenter',None);s.collection.objects.link(marker);marker.location=(.725,0,2.15);marker.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(A,'hanging_lantern_post.glb'),use_selection=True,export_animations=False)
bpy.data.objects.remove(merged,do_unlink=True);bpy.data.objects.remove(marker,do_unlink=True)
# Night studio preview.
col=bpy.data.collections.new('DISPLAY');s.collection.children.link(col);parts=[]
floor=mat('Blue slate ground',(.055,.073,.095));box('Ground',(0,0,-.06),(30,30,.10),floor)
for name,location,power,size,color in [('Moon',(-3,-4,6),400,5,(.36,.55,1)),('Fill',(3,-4,3),180,4,(.75,.80,1))]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.size=size;data.color=color;o=bpy.data.objects.new(name,data);col.objects.link(o);o.location=location;o.rotation_euler=(Vector((.3,0,1.4))-o.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.lights.new('Warm lamp light','POINT');data.energy=32;data.color=(1,.52,.16);data.shadow_soft_size=.20;o=bpy.data.objects.new('Warm lamp light',data);col.objects.link(o);o.location=(.725,-.1,2.12)
s.world.color=(.035,.045,.07)
data=bpy.data.cameras.new('Lantern camera');camera=bpy.data.objects.new('Lantern camera',data);col.objects.link(camera);camera.location=(4,-7,4.5);camera.rotation_euler=(Vector((.35,0,1.45))-camera.location).to_track_quat('-Z','Y').to_euler();data.type='ORTHO';data.ortho_scale=3.7;s.camera=camera
s['reference_url']='https://www.pinterest.com/pin/589549407514421781/';s['game_light_center']='Vector3(0.725,2.15,0)'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(O,'Hanging_Lantern_Post.blend'));s.render.filepath=os.path.join(O,'lantern_preview.png');bpy.ops.render.render(write_still=True)
print('LANTERN_MODEL_DONE',len(bpy.data.objects))
