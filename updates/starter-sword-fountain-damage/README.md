# Smaller damage numbers, solid fountain, new starter sword — 2026-11-05

## Damage numbers (scripts/combat/damage_popup.gd, from updates/ro-damage-popups)
`SIZE := 0.7` scales the pixel digits (35/42/29 px → 25/29/20 px), the crit burst, outline (6 → 4 px),
hop and lane spacing. Colours, timing and combat math unchanged. previews/dmg_cmp.png: left old, right new.

## Fountain collision (scripts/world/village_builder.gd)
After the fountain was made smaller, its collision ring had gaps, and the guild plot rebuild (which
clears a strip next to the plaza) also removed some fountain cells. Now `_fountain_solids()` makes every
cell within 3.05 blocks of the centre solid, 2 blocks high and hidden (visual rim is 2.93 m), and it runs
again after the guild office is rebuilt. qa/fountain_collision_test.gd prints physics hits and nav cells:
a full symmetric disc, no walkable cell inside.

## Starter sword (Iron Sword, swordsman default; shared basic sword model)
New chunky voxel sword in the style of the user's reference (https://www.pinterest.com/pin/790944753349467898/):
wide steel blade with a fuller and pointed tip, wooden crossguard and wrapped grip, gold guard caps and pommel.
`source/models/gen_basic_iron_sword.gd` generates it (`godot --headless -s gen_basic_iron_sword.gd`) as
`basic_iron_sword.scn`; it replaces the imported scene of assets/models/town/basic_iron_sword.glb in the pack
(same frame: blade +Y, grip on the origin), so the held sword, drops and the iron_sword icon all use it.
Note: every sword that has no model of its own (e.g. Crystal Sword) also uses this basic sword model.

## Build
Based on the current live pack; only 3 entries change: scripts/world/village_builder.gd,
scripts/combat/damage_popup.gd (both plain text like the live pack) and the basic sword .scn.
Outposts 11/11, fishing pond (-80, 46), login/load, startup log and town load time unchanged.
