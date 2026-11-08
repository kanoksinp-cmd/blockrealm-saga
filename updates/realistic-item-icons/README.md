# Realistic item icons (Blender Cycles)

Item icons are now realistic 3D renders instead of flat pixel art.

- 226 icons rendered with Blender 5.2 (Cycles, PBR materials, studio lights).
  They ship in the pack as `assets/icons/hd/<id>.webp` (128 px, about 0.8 MB total).
- `Items.icon()` uses the HD icon when one exists. The pixel art is kept as the
  source for the 3D drop meshes on the ground.
- Inventory slots and icon rects use `NEAREST_WITH_MIPMAPS`, so HD icons scale down
  cleanly. Pixel-art icons have no mipmaps, so they look the same as before.
- Fashion portraits (`*_fashion`) keep their original full-body art.

Re-render: `python3 blender_icons.py -- <item ids>` (needs the `bpy` module and
the source PNGs in /tmp/icons_src).
- `hero_models.py`: gems, potions and weapons (swords, axes, maces, staffs, bows),
  plus shields, rings, necklaces and crowns.
- `wear_models.py`: hats and helmets, armour and clothes, capes, gloves, boots and wings.
