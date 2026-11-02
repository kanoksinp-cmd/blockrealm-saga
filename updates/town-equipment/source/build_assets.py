import bpy,math,os,json,random
from mathutils import Vector,Matrix
O=os.path.dirname(os.path.abspath(__file__));R=os.path.abspath(os.path.join(O,'../career_expansion'));A=os.path.join(R,'assets/models/town');I=os.path.join(R,'assets/icons/items');os.makedirs(A,exist_ok=True);os.makedirs(I,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False);random.seed(62)
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=12;s.cycles.use_denoising=True;s.view_settings.view_transform='AgX'
def mat(name,c,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=.75;p.inputs['Metallic'].default_value=metal;return m
M={n:mat(n,c,.2 if n in ['silver','gold'] else 0) for n,c in {'red':(.48,.025,.02),'blue':(.015,.19,.33),'cyan':(.012,.48,.58),'black':(.015,.022,.027),'white':(.80,.87,.84),'silver':(.37,.49,.49),'gold':(.79,.48,.06),'wood':(.17,.075,.027),'tan':(.43,.25,.10),'straw':(.68,.46,.10),'green':(.11,.28,.12),'purple':(.22,.035,.40),'pink':(.66,.25,.40),'pale':(.49,.66,.70)}.items()}
col=None;parts=[];catalog=[];collections=[]
def box(n,p,d,m,ang=0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.name=n;o.dimensions=d;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.rotation_euler.y=ang
 for c in list(o.users_collection):c.objects.unlink(o)
 col.objects.link(o);o.data.materials.append(M[m] if isinstance(m,str) else m);parts.append(o);return o
def rod(n,a,b,w,d,m):
 a,b=Vector(a),Vector(b);o=box(n,(a+b)/2,(w,d,(b-a).length),m);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def ring(n,z,w=.51,depth=.51,h=.075,m='black'):
 for sign in [-1,1]:box(n,(sign*(w/2-.025),0,z),(.05,depth,h),m);box(n,(0,sign*(depth/2-.025),z),(w-.10,.05,h),m)
def new(id,label):
 global col,parts
 col=bpy.data.collections.new(id);s.collection.children.link(col);parts=[];collections.append(col);catalog.append({'id':id,'label':label})
def export(id):
 bpy.ops.object.select_all(action='DESELECT');copies=[]
 for src in parts:
  o=src.copy();o.data=src.data.copy();s.collection.objects.link(o);o.select_set(True);copies.append(o)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);bpy.ops.object.join();merged=bpy.context.object;merged.name=id
 bpy.ops.export_scene.gltf(filepath=os.path.join(A,id+'.glb'),use_selection=True,export_animations=False)
 bpy.data.objects.remove(merged,do_unlink=True)
def cap(m,z=.52,w=.46,d=.46):box('Cap',(0,0,z),(w,d,.18),m)
def brim(m,w=.6,d=.58):box('Brim',(0,-.025,.45),(w,d,.055),m)
styles=[('red_bandana','Red Bandana'),('dragon_mask','Dusk Dragon Mask'),('winter_ushanka','Winter Ushanka'),('royal_crown','Jewel Crown'),('horned_helm','Horned Helm'),('blue_bandana','Blue Bandana'),('rice_straw_hat','Rice Straw Hat'),('straw_boater','Straw Boater'),('black_headband','Black Headband'),('gold_hardhat','Golden Hardhat'),('silver_headphones','Silver Headphones'),('black_headphones','Black Headphones'),('captain_cap','Captain Cap'),('red_beret','Red Beret'),('black_top_hat','Black Top Hat'),('leather_fedora','Leather Fedora'),('sailor_cap','Sailor Cap'),('bunny_ears','Bunny Ears'),('robot_visor','Robot Visor'),('chef_hat','Chef Hat'),('indigo_wizard_hat','Indigo Witch Hat')]
for idx,(id,label) in enumerate(styles):
 new(id,label)
 if 'bandana' in id or id=='black_headband':
  color='red' if id.startswith('red') else ('blue' if id.startswith('blue') else 'black');ring('Cloth head wrap',.43,.51,.51,.10,color)
  if id!='black_headband':
   for sign in [-1,1]:box('Tied ribbon',(sign*.07,.29,.32),(.07,.055,.23),color,sign*.12)
 elif id=='dragon_mask':
  cap('black',.46,.52,.53);box('Long dragon snout',(0,-.36,.31),(.49,.29,.16),'black')
  for sign in [-1,1]:
   box('Purple eye',(sign*.19,-.275,.47),(.10,.04,.09),'purple');rod('Tall dragon horn',(sign*.17,.10,.53),(sign*.19,.20,.85),.09,.10,'black');box('White fang',(sign*.16,-.42,.20),(.045,.06,.07),'white')
 elif id=='winter_ushanka':
  cap('blue',.57);box('Fur forehead',(0,-.25,.47),(.51,.06,.14),'white')
  for sign in [-1,1]:box('Ear flap',(sign*.25,.01,.34),(.075,.34,.30),'blue')
 elif id=='royal_crown':
  ring('Gold crown ring',.49,.53,.53,.13,'gold');brim('gold',.57,.56)
  for x,y in [(-.22,-.22),(.22,-.22),(-.22,.22),(.22,.22),(0,-.22),(0,.22)]:box('Crown point',(x,y,.64),(.075,.075,.20),'gold')
  for x,c in [(-.15,'blue'),(0,'red'),(.15,'green')]:box('Crown jewel',(x,-.282,.52),(.075,.035,.09),c)
 elif id=='horned_helm':
  cap('silver',.50);box('Leather helmet band',(0,-.25,.46),(.48,.05,.09),'tan')
  for sign in [-1,1]:rod('Ivory horn',(sign*.23,0,.52),(sign*.36,0,.70),.11,.13,'pale');rod('Horn tip',(sign*.36,0,.70),(sign*.34,0,.82),.07,.09,'white')
 elif id in ['rice_straw_hat','straw_boater','gold_hardhat','leather_fedora','black_top_hat','captain_cap','sailor_cap','red_beret','chef_hat','indigo_wizard_hat']:
  if id=='rice_straw_hat':
   for j in range(5):box('Layered rice straw',(0,0,.46+j*.055),(.72-j*.12,.70-j*.12,.06),'straw')
  elif id=='indigo_wizard_hat':
   brim('purple',.7,.65)
   for j in range(5):box('Stepped witch cone',(-j*.022,j*.018,.52+j*.09),(.43-j*.072,.43-j*.072,.105),'purple')
   box('Witch hat band',(0,-.232,.53),(.42,.035,.065),'black')
  elif id=='chef_hat':
   cap('white',.52,.50,.48);box('Chef puff',(0,0,.68),(.59,.54,.22),'white')
   for x in [-.18,0,.18]:box('Chef fold',(x,-.28,.68),(.04,.025,.19),'pale')
  elif id=='red_beret':
   cap('red',.5,.56,.52);box('Beret crown',(.04,0,.62),(.41,.40,.08),'red');box('Beret pip',(.03,0,.69),(.04,.04,.06),'black')
  else:
   color={'straw_boater':'straw','gold_hardhat':'gold','leather_fedora':'tan','black_top_hat':'black','captain_cap':'white','sailor_cap':'white'}[id]
   brim(color,.65 if id in ['straw_boater','black_top_hat'] else .58,.60)
   cap(color,.62 if id=='black_top_hat' else .54)
   if id=='black_top_hat':box('Tall top hat crown',(0,0,.75),(.45,.43,.36),'black')
   if id in ['black_top_hat','straw_boater','leather_fedora']:box('Hat ribbon',(0,-.242,.52),(.47,.035,.065),'red' if id!='leather_fedora' else 'wood')
   if id=='gold_hardhat':box('Hardhat top ridge',(0,0,.68),(.08,.46,.07),'gold')
   if id=='captain_cap':box('Captain dark brim',(0,-.17,.44),(.52,.39,.05),'black');box('Captain badge',(0,-.253,.56),(.10,.025,.10),'gold')
 elif 'headphones' in id:
  color='silver' if id.startswith('silver') else 'black';box('Headphone band',(0,0,.69),(.54,.12,.06),color)
  for sign in [-1,1]:box('Headphone arch',(sign*.26,0,.52),(.055,.12,.35),color);box('Ear cup',(sign*.30,0,.31),(.11,.24,.22),color);box('Red ear accent',(sign*.36,-.02,.31),(.025,.18,.14),'red')
 elif id=='bunny_ears':
  ring('Bunny headband',.48,.50,.50,.06,'white')
  for sign in [-1,1]:box('Rabbit ear',(sign*.15,0,.78),(.12,.10,.56),'white',sign*-.08);box('Pink ear inset',(sign*.15,-.06,.78),(.06,.025,.43),'pink',sign*-.08)
 elif id=='robot_visor':
  box('Robot face frame',(0,-.27,.30),(.58,.08,.53),'silver');box('Robot screen',(0,-.32,.31),(.45,.035,.39),'black')
  for x,z in [(-.09,.38),(.08,.38),(-.09,.22),(.08,.22)]:box('Amber display',(x,-.35,z),(.05,.022,.075),'gold')
  box('Robot antenna',(0,0,.72),(.045,.045,.40),'silver');box('Antenna tip',(0,0,.94),(.11,.11,.10),'red')
 export(id)
 # Authoring layout keeps all headgear visible in one sheet.
 dx=(idx%7-3)*1.05;dz=(2-idx//7)*1.15
 for o in parts:o.location.x+=dx;o.location.z+=dz
# Cubic potion flasks, with a thick pale frame and colored liquid panels.
def potion(color,prefix='',scale=1,origin=(0,0,0)):
 start=len(parts)
 box(prefix+'Liquid core',(0,0,.16),(.23,.23,.25),color)
 for x in [-.15,.15]:
  for y in [-.15,.15]:box(prefix+'Glass corner',(x,y,.16),(.065,.065,.31),'pale')
 for z in [.015,.31]:box(prefix+'Glass rim',(0,0,z),(.36,.36,.055),'white')
 box(prefix+'Neck',(0,0,.39),(.22,.22,.14),'pale');box(prefix+'Neck lip',(0,0,.47),(.29,.29,.05),'white');box(prefix+'Cork stopper',(0,0,.53),(.23,.23,.10),'tan')
 for o in parts[start:]:o.location=Vector(origin)+o.location*scale;o.scale*=scale
for idx,(id,label,c) in enumerate([('potion_red','Healing flask','red'),('potion_blue','Mana flask','blue'),('potion_green_prop','Herbal flask','green'),('potion_amber_prop','Amber flask','gold')]):
 new(id,label);potion(c);export(id)
 for o in parts:o.location+=Vector((4.3+idx*.6,0,.05))
new('basic_iron_sword','Forged basic sword')
box('Leather hilt',(0,0,-.18),(.10,.14,.36),'wood')
for z in [-.32,-.22,-.11,0]:box('Hilt wrap',(0,-.005,z),(.13,.16,.04),'tan')
box('Iron pommel',(0,0,-.39),(.16,.18,.11),'silver')
box('Crossguard',(0,0,.035),(.49,.17,.10),'silver')
for sign in [-1,1]:box('Angled guard end',(sign*.23,0,.055),(.14,.17,.085),'silver',sign*-.28)
box('Straight blade',(0,0,.49),(.18,.09,.82),'pale');box('Blade central ridge',(0,-.059,.49),(.07,.028,.82),'silver')
for sign in [-1,1]:box('Honed edge',(sign*.083,-.004,.49),(.026,.105,.82),'white')
box('Blade tip',(0,0,.94),(.13,.08,.13),'white');export('basic_iron_sword')
for o in parts:o.location+=Vector((7.2,0,.5))
new('potion_stall','Apothecary stall')
box('Timber counter base',(0,0,.44),(1.50,.70,.86),'wood')
for x in [-.65,-.39,-.13,.13,.39,.65]:box('Counter planks',(x,-.37,.44),(.23,.055,.81),'tan')
box('Counter top',(0,-.03,.91),(1.77,.91,.12),'tan')
for sign in [-1,1]:box('Canopy post',(sign*.70,.26,1.39),(.11,.11,1.46),'wood')
box('Turquoise canopy',(0,0,2.10),(1.98,1.18,.12),'cyan')
for x in [-.86,-.55,-.24,.07,.38,.69]:box('Scalloped canopy fringe',(x,-.60,2.00),(.29,.08,.20),'blue')
for sign in [-1,1]:box('Shelf tray',(sign*.43,-.06,1.01),(.70,.68,.075),'wood')
for idx,(x,y,c) in enumerate([(-.60,-.18,'blue'),(-.28,-.18,'green'),(.20,-.18,'red'),(.53,-.18,'pink'),(-.52,.16,'purple'),(.38,.16,'gold')]):potion(c,'Display bottle '+str(idx)+' ',.55,(x,y,1.04))
for sign in [-1,1]:box('Lower herb crate',(sign*.9,-.08,.32),(.36,.55,.47),'wood');box('Crate cloth',(sign*.9,-.08,.58),(.39,.57,.06),'green')
box('Medicine sign',(0,-.49,.66),(.39,.05,.35),'green');box('Cross horizontal',(0,-.527,.66),(.25,.025,.065),'white');box('Cross vertical',(0,-.529,.66),(.065,.025,.25),'white')
export('potion_stall')
for o in parts:o.location.x+=5.3;o.location.y+=2.5
# Studio and orthographic cameras.
col=bpy.data.collections.new('STUDIO');s.collection.children.link(col);parts=[]
for name,loc,power,size in [('Key',(-4,-6,8),1200,8),('Fill',(8,-4,5),900,7),('Rim',(3,5,7),1400,8)]:
 data=bpy.data.lights.new(name,'AREA');data.energy=power;data.size=size;o=bpy.data.objects.new(name,data);col.objects.link(o);o.location=loc;o.rotation_euler=(Vector((1,0,1.6))-o.location).to_track_quat('-Z','Y').to_euler()
s.world.color=(.10,.13,.16)
camd=bpy.data.cameras.new('Catalog camera');cam=bpy.data.objects.new('Catalog camera',camd);col.objects.link(cam);s.camera=cam;camd.type='ORTHO'
def camera_at(target,size):
 target=Vector(target);cam.location=target+Vector((3,-13,6));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();camd.ortho_scale=size
camera_at((0,0,1.6),8.5);s.render.resolution_x=1800;s.render.resolution_y=1150;s.render.film_transparent=False
s['reference_pins']='620441286173168067,989103136886269635,411305378491514323,858709853986140361,758293656054507108'
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(O,'Town_Equipment_Update.blend'))
for c in collections:c.hide_render=c.name not in [x[0] for x in styles]
s.render.filepath=os.path.join(O,'hats_preview.png');bpy.ops.render.render(write_still=True)
for c in collections:c.hide_render=c.name in [x[0] for x in styles]
camera_at((5.5,1,1.0),5.5);s.render.resolution_x=1500;s.render.resolution_y=1100;s.render.filepath=os.path.join(O,'town_props_preview.png');bpy.ops.render.render(write_still=True)
# Matching small icons, rendered from the same geometry.
s.render.film_transparent=True;s.render.resolution_x=64;s.render.resolution_y=64;s.cycles.samples=6
for idx,entry in enumerate(catalog):
 id=entry['id']
 if id in ['potion_stall','potion_green_prop','potion_amber_prop']:continue
 for c in collections:c.hide_render=c.name!=id
 if idx<len(styles):target=((idx%7-3)*1.05,0,(2-idx//7)*1.15+.50);size=1.28
 elif id.startswith('potion_'):target=(4.3+(0 if id=='potion_red' else 1)*.6,0,.30);size=.78
 else:target=(7.2,0,.83);size=1.6
 camera_at(target,size);s.render.filepath=os.path.join(I,id+'.png');bpy.ops.render.render(write_still=True)
with open(os.path.join(O,'asset_catalog.json'),'w',encoding='utf8') as f:json.dump(catalog,f,ensure_ascii=False,indent=2)
print('TOWN_ASSETS_DONE',len(catalog))
