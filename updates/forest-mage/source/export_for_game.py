import bpy,os,json
from mathutils import Matrix,Vector
BASE=os.path.dirname(os.path.abspath(__file__));OUT=os.path.abspath(os.path.join(BASE,'../career_expansion/assets/models/forest_mage'));os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.path.join(BASE,'forest_mage_flying_pets.blend'))
bpy.context.scene.frame_set(1)
root=bpy.data.objects['FOREST MAGE | pose controls']
def descendants(o):return list(o.children_recursive)
M=Matrix.Diagonal((-0.63,0.63,0.63,1))
# Pivots match the game's humanoid joints; Blender -Y faces Godot +Z.
groups={'head':(['Head'],Vector((0,-.015,1.76))), 'torso':(['Torso','Back cape'],Vector((0,0,1.12))), 'arm_l':(['Arm L'],Vector((-.59,0,1.72))), 'arm_r':(['Arm R'],Vector((.59,0,1.72))), 'leg_l':(['Leg L'],Vector((-.27,0,1.12))), 'leg_r':(['Leg R'],Vector((.27,0,1.12)))}
# Reflection swaps left/right into the game's +Z-facing convention.
report={}
for part,(names,pivot) in groups.items():
 copies=[]
 for name in names:
  for src in descendants(bpy.data.objects[name]):
   if src.type!='MESH':continue
   me=bpy.data.meshes.new_from_object(src.evaluated_get(bpy.context.evaluated_depsgraph_get()))
   me.transform(M @ Matrix.Translation(-pivot) @ src.matrix_world)
   # Reflection changes winding; repair face directions.
   import bmesh
   bm=bmesh.new();bm.from_mesh(me);bmesh.ops.reverse_faces(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
   o=bpy.data.objects.new('Forest_'+src.name,me);bpy.context.scene.collection.objects.link(o);copies.append(o)
 bpy.ops.object.select_all(action='DESELECT')
 for o in copies:o.select_set(True)
 bpy.context.view_layer.objects.active=copies[0]
 bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,part+'.glb'),use_selection=True,export_animations=False,export_materials='EXPORT')
 report[part]={'meshes':len(copies),'bytes':os.path.getsize(os.path.join(OUT,part+'.glb'))}
 for o in copies:bpy.data.objects.remove(o,do_unlink=True)
# Staff, origin at the grip. Cosmetic replacement only; weapon stats stay untouched.
staff=bpy.data.objects['STAFF | rotate to pose'];copies=[]
for src in descendants(staff):
 if src.type!='MESH':continue
 me=bpy.data.meshes.new_from_object(src.evaluated_get(bpy.context.evaluated_depsgraph_get()))
 me.transform(M @ Matrix.Translation(Vector((0,0,-1.3))) @ staff.matrix_world.inverted() @ src.matrix_world)
 bm=bmesh.new();bm.from_mesh(me);bmesh.ops.reverse_faces(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
 o=bpy.data.objects.new('Forest_'+src.name,me);bpy.context.scene.collection.objects.link(o);copies.append(o)
bpy.ops.object.select_all(action='DESELECT')
for o in copies:o.select_set(True)
bpy.context.view_layer.objects.active=copies[0];bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'staff.glb'),use_selection=True,export_animations=False)
for o in copies:bpy.data.objects.remove(o,do_unlink=True)
# Retain the supplied hover and wing animation on the original pet hierarchy.
bpy.ops.object.select_all(action='DESELECT');root.scale=(-.63,.63,.63);root.select_set(True)
for o in descendants(root):
 if o.name.startswith(('PET FOLLOW','SPIRIT')):o.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'pets.glb'),use_selection=True,export_animations=True,export_animation_mode='SCENE',export_frame_range=True,export_force_sampling=True)
report['pets']={'bytes':os.path.getsize(os.path.join(OUT,'pets.glb'))}
with open(os.path.join(BASE,'game_export_validation.json'),'w') as f:json.dump(report,f,indent=2)
print('FOREST_EXPORT_DONE',report)
