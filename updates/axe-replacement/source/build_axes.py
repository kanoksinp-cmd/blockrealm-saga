import bpy,math,os,random,json
from mathutils import Vector
O=os.path.dirname(os.path.abspath(__file__));AS=os.path.abspath(os.path.join(O,'../career_expansion/assets/models/arcane'));os.makedirs(AS,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=24;s.cycles.use_denoising=True;s.render.resolution_x=1800;s.render.resolution_y=1400;s.render.resolution_percentage=100;s.view_settings.view_transform='AgX';s.view_settings.look='AgX - Medium High Contrast'
random.seed(972)
def palette(name,c,metal):
 out=[]
 for j in range(5):
  q=(j-2)*.045;m=bpy.data.materials.new(name+' '+str(j));m.diffuse_color=tuple(max(.002,min(1,v+q)) for v in c)+(1,);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=m.diffuse_color;p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.68;out.append(m)
 return out
wood=palette('Weathered walnut',(.12,.075,.058),.04);wrap=palette('Oxide teal leather',(.025,.085,.09),.02);iron=palette('Blue grey steel',(.22,.29,.32),.5);edge=palette('Honed steel',(.49,.59,.62),.5);dark=palette('Deep joint',(.026,.031,.036),.15);band=palette('Riveted collar',(.16,.21,.24),.55)
collection=None;objects=[]
def box(name,pos,dim,pal,angle=0):
 # Face-level pixel variation stays intact in glTF; no texture dependency.
 vs=[];fs=[]
 axes=[(0,1,2),(0,2,1),(1,2,0)]
 for u,v,w in axes:
  nu=min(32,max(1,round(dim[u]/.045)));nv=min(32,max(1,round(dim[v]/.045)))
  for side in [-1,1]:
   for i in range(nu):
    for j in range(nv):
     quad=[]
     for du,dv in [(0,0),(1,0),(1,1),(0,1)]:
      co=[0,0,0];co[u]=((i+du)/nu-.5)*dim[u];co[v]=((j+dv)/nv-.5)*dim[v];co[w]=side*dim[w]/2;quad.append(tuple(co))
     start=len(vs);vs.extend(quad)
     # Winding follows the outward normal for each plane.
     reverse=(u,v,w)==(0,2,1)
     ids=tuple(range(start,start+4));fs.append(ids[::-1] if (side<0)^reverse else ids)
 me=bpy.data.meshes.new(name);me.from_pydata(vs,[],fs);me.update()
 o=bpy.data.objects.new(name,me);collection.objects.link(o);o.location=pos;o.rotation_euler.y=angle
 for m in pal:me.materials.append(m)
 for f in me.polygons:f.material_index=random.choices(range(5),[1,2,7,2,1])[0]
 objects.append(o);return o
def bar(name,a,b,w,d,pal):
 a,b=Vector(a),Vector(b);o=box(name,(a+b)/2,(w,d,(b-a).length),pal);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
report={}
for index,(id,label,total,blue,kind) in enumerate([('hand_axe','HAND AXE',1.20,False,0),('battle_axe','BATTLE AXE',1.62,False,1),('frost_axe','FROST AXE',1.48,True,2),('arcane_axe','CRESCENT AXE',1.95,True,3)]):
 collection=bpy.data.collections.new('%02d • %s'%(index+1,label));s.collection.children.link(collection);objects=[]
 low=-total*.40;high=total*.60;hz=high-.22
 box('Continuous timber haft',(0,0,(low+high)/2),(.09,.115,total),wood)
 # Leather is overlaid on the wood, with alternating exposed timber sections.
 for a,b in [(low+.07,-.10),(.12,hz-.14)]:
  if b>a:box('Wrapped hand grip',(0,-.001,(a+b)/2),(.108,.132,b-a),wrap if blue else dark)
 for z in [low+.06,-.12,.13,hz-.16]:box('Steel binding collar',(0,0,z),(.14,.155,.045),band)
 if blue:
  box('Squared diamond pommel',(0,0,low),(.18,.17,.18),iron,math.pi/4)
  box('Pommel front facet',(0,-.091,low),(.095,.018,.095),edge,math.pi/4)
 else:box('Flat iron pommel',(0,0,low),(.14,.16,.065),band)
 # Socket and rectangular neck carry the asymmetric crescent blade.
 box('Axle socket',(0,0,hz),(.20,.23,.28),iron if blue else band)
 box('Socket face',(0,-.125,hz),(.12,.035,.23),edge if not blue else iron)
 box('Blade neck',(.19,0,hz+.03),(.32,.15,.15),iron)
 if kind==0:
  box('Single wedge blade',(.34,0,hz),(.17,.17,.31),iron,.38)
  bar('Honed cutting edge',(.34,-.015,hz-.21),(.47,-.015,hz+.10),.055,.19,edge)
  box('Small upper ridge',(.38,0,hz+.17),(.11,.17,.12),edge,.38)
 else:
  # Segmented crescent: broad central cheek, receding stepped lower edge.
  width=.23 if kind==1 else .25
  box('Broad blade cheek',(.38,0,hz+.015),(width,.20,.39),iron)
  box('Raised cheek front',(.38,-.115,hz+.02),(width*.75,.045,.30),edge if kind==1 else iron)
  for j,(x,z,ang) in enumerate([(.46,.24,-.30),(.47,-.22,.30),(.39,-.35,.45)]):
   if kind==1 and j==0:continue
   box('Crescent stepped segment', (x,0,hz+z),(.15,.17,.20 if j<2 else .16),iron,ang)
   box('Segment edge highlight',(x+.055,-.01,hz+z),(.045,.20,.19 if j<2 else .12),edge,ang)
  box('Outer cutting edge',(.51,0,hz+.015),(.048,.23,.38),edge)
  bar('Upper sharpened point',(.39,0,hz+.24),(.31,0,hz+.39),.09,.18,edge)
  if blue:
   bar('Rear hammer neck',(-.06,0,hz+.02),(-.22,0,hz+.18),.085,.14,dark)
   box('Angled rear hammer',(-.25,0,hz+.22),(.17,.19,.21),iron,-.72)
   box('Hammer strike face',(-.31,-.01,hz+.27),(.055,.21,.16),edge,-.72)
   if kind==3:
    box('Rear counterweight',(-.24,0,hz-.12),(.16,.17,.16),iron,-.65)
    for zz in [-.04,.035]:box('Grip crossing band',(0,-.087,zz),(.15,.025,.035),edge,.4 if zz<0 else -.4)
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 path=os.path.join(AS,'reforged_'+id+'.glb');bpy.ops.export_scene.gltf(filepath=path,use_selection=True,export_animations=False)
 report[id]={'model':'reforged_'+id,'parts':len(objects),'faces':sum(len(o.data.polygons) for o in objects),'bytes':os.path.getsize(path)}
 # Place the editable collection on the preview stage after exporting at grip zero.
 for o in objects:o.location.x+=(index-1.5)*1.12-.17;o.location.z+=1.00
# Studio presentation.
collection=bpy.data.collections.new('STUDIO');s.collection.children.link(collection)
floor=palette('Slate backdrop',(.045,.075,.11),.02)
box('Display ground',(0,0,-.025),(200,200,.04),floor)
def lamp(name,loc,power,size,col):
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;data.color=col;o=bpy.data.objects.new(name,data);collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
lamp('Key',(-3,-5,6),650,5,(.82,.91,1));lamp('Fill',(4,-3,3),450,4,(1,.88,.73));lamp('Rim',(0,3,5),900,4,(.40,.65,1))
camd=bpy.data.cameras.new('Axes camera');cam=bpy.data.objects.new('Axes camera',camd);collection.objects.link(cam);cam.location=(3,-11,5);cam.rotation_euler=(Vector((0,0,1.18))-cam.location).to_track_quat('-Z','Y').to_euler();camd.type='ORTHO';camd.ortho_scale=5.7;s.camera=cam
m=palette('Lettering',(.6,.73,.82),0)[2]
cu=bpy.data.curves.new('Title','FONT');cu.body='AXES / REFORGED';cu.align_x='CENTER';cu.size=.19;o=bpy.data.objects.new('Title',cu);collection.objects.link(o);o.location=(0,0,2.75);o.rotation_euler=(math.pi/2,0,0);o.data.materials.append(m)
s['reference_url']='https://www.pinterest.com/pin/972777588259266302/';s['model_origins']='All glTF models have their origin at the hand grip.'
for sc in bpy.data.screens:
 for a in sc.areas:
  if a.type=='VIEW_3D':a.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(O,'Reforged_Axes.blend'))
s.render.filepath=os.path.join(O,'axes_preview.png');bpy.ops.render.render(write_still=True)
with open(os.path.join(O,'model_validation.json'),'w') as f:json.dump(report,f,indent=2)
print('AXES_BUILD_DONE',report)

