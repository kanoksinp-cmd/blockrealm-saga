from pathlib import Path
from PIL import Image,ImageOps
import json,shutil
r=Path('Fashion_Gallery_Update');repo=Path(r'C:\Users\Guide\Documents\blockrealm-saga-clone');out=r/'resources/assets/ui/fashion_cards';out.mkdir(parents=True,exist_ok=True)
data=json.loads((r/'fashions.json').read_text(encoding='utf-8'));atlas=Image.open(repo/'assets/news/relic-vanguard.webp').convert('RGB')
for i,f in enumerate(data[:12]):
 col=i%4;row=i//4;x=12+282*col;y=12+254*row
 tile=atlas.crop((x,y,x+272,y+242));tile.thumbnail((256,256),Image.Resampling.LANCZOS);tile.save(out/(f['id']+'.png'),optimize=True)
extras={'eternal_armor':('eternal-armor.webp',(20,20,590,600)), 'pumpkin_reaper':('hallow-spectres-fashion-static.png',(10,38,265,400)), 'bone_oracle':('hallow-spectres-fashion-static.png',(266,62,447,400)), 'hollow_scarecrow':('hallow-spectres-fashion-static.png',(441,20,629,400)), 'forest_mage':('forest-mage-fashion.png',None)}
for fid,(source,box) in extras.items():
 image=Image.open(repo/'assets/news'/source).convert('RGB')
 if box:image=image.crop(box)
 image.thumbnail((256,256),Image.Resampling.LANCZOS);image.save(out/(fid+'.png'),optimize=True)
assert {f['id'] for f in data}=={p.stem for p in out.glob('*.png')}
src=r/'source/scripts/ui';src.mkdir(parents=True,exist_ok=True)
p=src/'ro_ui_base.gd';s=(r/'baseline/scripts/ui/ro_ui_base.gd').read_text(encoding='utf-8');a=s.index('func _open_mage_fashion(');b=s.index('# ================================================================== phones / tablets',a)
s=s[:a]+'''var _fashion_gallery: Node

func _fashion_gallery_view() -> Node:
	if not is_instance_valid(_fashion_gallery):
		_fashion_gallery = load("res://scripts/ui/fashion_gallery.gd").new()
		_root.add_child(_fashion_gallery)
		_fashion_gallery.setup(self)
	return _fashion_gallery

func _open_mage_fashion(_page := 0) -> void:
	_dialog.panel.hide()
	_fashion_gallery_view().open()

func _fashion_detail(id: String, _page := 0) -> void:
	_fashion_gallery_view().show_detail(id)


'''+s[b:]
a=s.index('\telif _smith_tab == 7:');b=s.index('\telif _smith_tab == 6:',a)
s=s[:a]+'''\telif _smith_tab == 7:
		_fashion_gallery_view().fill(_smith_list, true)
'''+s[b:];p.write_text(s,encoding='utf-8')
shutil.copy2('Crisp_Text_Update/build_pack.py',r/'build_pack.py')
