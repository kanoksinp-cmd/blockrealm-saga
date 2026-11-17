# Realistic held weapons and shields

Characters now hold the same 3D models that the HD inventory icons were rendered
from, instead of extruded pixel sprites (or the older voxel / pixel-art GLBs).

- 82 weapons and 7 shields: `assets/models/real/<item id>.glb` (about 1,800
  triangles each, 2.7 MB imported in total).
- `blender/export_weapons.py` builds each model with the icon builders in
  `updates/realistic-item-icons` (`hero_models.py`, and `blender_icons.relief_object`
  for spears, whips, books, lutes and Amethyst Spire). Knuckles get their own
  builder that matches the icon. Models are stood upright with the grip at the
  origin and scaled per weapon type.
- Material values are baked into the vertices (COLOR = base colour, UV =
  emission and clear-coat/glass, UV2 = metallic and roughness). One shared shader
  (`Avatar.REAL_SHADER`) draws every weapon, with a studio-style reflection so the
  metal reads as polished steel from the game camera.
- `scripts/voxel/avatar.gd`: `dress()` keeps the item ids (`weapon_item`,
  `gear.shield.item`), and `attach_weapon()` and the shield placement use
  `Avatar.real_model(id)` when a model exists. Otherwise they fall back to the
  old visuals.
- The Silverstring Lute HD icon showed a ring, because "silverstring" contains
  "ring". It has been re-rendered as a lute.

Rebuild:

```
python export_weapons.py            # bpy 5.2, needs the pixel icons in /home/claude/wpn/src_icons
godot --headless --import           # in a project holding assets/models/real/*.glb
                                    # (import: no LODs, no shadow meshes, no tangents)
python build_pack.py play/index.pck out.pck
```

Previews: `previews/in-game.png` (characters holding the weapons) and
`previews/model-vs-icon.png` (in-game model on top, inventory icon below).
