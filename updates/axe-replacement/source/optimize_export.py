import bpy,os,json
from mathutils import Matrix
O=os.path.dirname(os.path.abspath(__file__));bpy.ops.wm.open_mainfile(filepath=os.path.join(O,'Reforged_Axes.blend'))
A=os.path.abspath(os.path.join(O,'../career_expansion/assets/models/arcane'));report={}
for i,id in enumerate(['hand_axe','battle_axe','frost_axe','arcane_axe']):
 col=next(c for c in bpy.data.collections if c.name.startswith('%02d •'%(i+1)));copies=[]
 offset=(i-1.5)*1.12-.17
 for src in list(col.objects):
  o=src.copy();o.data=src.data.copy();bpy.context.scene.collection.objects.link(o);o.matrix_world=Matrix.Translation((-offset,0,-1))@src.matrix_world;copies.append(o)
 bpy.ops.object.select_all(action='DESELECT')
 for o in copies:o.select_set(True)
 bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);bpy.ops.object.join()
 merged=bpy.context.object;merged.name='reforged_'+id
 path=os.path.join(A,merged.name+'.glb');bpy.ops.export_scene.gltf(filepath=path,use_selection=True,export_animations=False)
 report[id]={'authoring_parts':len(copies),'runtime_meshes':1,'material_surfaces':len(merged.data.materials),'bytes':os.path.getsize(path)}
 bpy.data.objects.remove(merged,do_unlink=True)
with open(os.path.join(O,'model_validation.json'),'w') as f:json.dump(report,f,indent=2)
print('OPTIMIZED_AXES_READY',report)
