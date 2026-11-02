import bpy,os,shutil
from mathutils import Vector
O=os.path.dirname(os.path.abspath(__file__));bpy.ops.wm.open_mainfile(filepath=os.path.join(O,'Reforged_Axes.blend'))
s=bpy.context.scene
for p in bpy.data.objects['Display ground'].data.polygons:p.material_index=2
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(O,'Reforged_Axes.blend'))
s.cycles.samples=20;s.render.filepath=os.path.join(O,'axes_preview.png');bpy.ops.render.render(write_still=True)
icons=os.path.abspath(os.path.join(O,'../career_expansion/assets/icons/items'));backup=os.path.join(O,'original_icons');os.makedirs(backup,exist_ok=True)
studio=bpy.data.collections['STUDIO'];bpy.data.objects['Display ground'].hide_render=True;bpy.data.objects['Title'].hide_render=True
collections=[c for c in bpy.data.collections if ' • ' in c.name]
s.render.film_transparent=True;s.render.resolution_x=64;s.render.resolution_y=64;s.cycles.samples=16
for i,id in enumerate(['hand_axe','battle_axe','frost_axe','arcane_axe']):
 for c in collections:c.hide_render=not c.name.startswith('%02d'%(i+1))
 ox=(i-1.5)*1.12-.17;target=Vector((ox+.15,0,1.08))
 s.camera.location=target+Vector((.7,-4,1));s.camera.rotation_euler=(target-s.camera.location).to_track_quat('-Z','Y').to_euler();s.camera.data.ortho_scale=[1.42,1.92,1.82,2.32][i]
 path=os.path.join(icons,id+'.png')
 if os.path.exists(path) and not os.path.exists(os.path.join(backup,id+'.png')):shutil.copy2(path,os.path.join(backup,id+'.png'))
 s.render.filepath=path;bpy.ops.render.render(write_still=True)
print('AXE_ICONS_DONE')
