# One-metre guild and smithy interiors — 9 November 2026

Interior wall/floor texture cells now repeat once per metre instead of five times. Static furniture in both guild floors and Doran's workshop is converted to a shared world-aligned one-metre grid, hidden faces are culled, and geometry is batched per room/material class. Tiny mugs, pins, paper sheets and ember pieces are removed instead of expanding each into a full cube. Existing walkable cells are protected at body height. Characters, animated smith workers/bellows, portal coordinates and the exterior facade retain their existing behavior; the outdoor texture repeat remains unchanged.

The BlockWorld source was recovered from the currently deployed tokenized script, preserving its color-vertex and rounding logic. Only the interior UV density changed in that script. VillageBuilder runs the furniture bake before its existing structure-grid processing, so baked ArrayMeshes are skipped by the old 20 cm conversion. The current mobile region-unloading and save changes are retained.

## Measured scene geometry (headless engine comparison)

- GuildProps: 246 -> 3 mesh instances; 55,896 -> 1,512 vertices.
- BlacksmithWorkshop, including exterior details and animated actors: 350 -> 76 mesh instances; 36,140 -> 21,072 vertices.
- Combined: 596 -> 79 meshes (about 87% fewer); 92,036 -> 22,584 vertices (about 75% fewer).
- Static engine memory after scene preparation: 289 -> 286 MiB in this sample. Startup timings varied and no claim of faster startup or a measured Safari FPS increase is made.

## Validation

- Exact navigation comparison across all 6,824 cells in guild1, guild2 and smithy: identical before/after.
- All batched static-furniture vertices align to the one-metre grid; three room groups and five batched meshes.
- One-metre interior UVs and unchanged 20 cm outdoor UV repeat.
- Four portal/exit routes, 15 interior NPCs, all three animated workshop workers, guild/smith windows, and entering/exiting all interiors.
- Native OpenGL previews rendered for both guild floors and workshop and visually inspected.
- Desert/Verdant ruins and mobile performance caps regression; actual Gold Ore Find -> smithy exit -> town -> desert -> mining -> inventory regression.

These checks use isolated saves. Physical mobile smoothness should be confirmed by playing on the affected device. Existing renderer Rect2i/shutdown diagnostics are distinct from script/assertion failures.
