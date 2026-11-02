# Replacement axes

Reference: https://www.pinterest.com/pin/972777588259266302/
Original Blender 5.2.2 models interpreted from the four axes in the user-provided reference.

Replaces active meshes and inventory icons for Hand Axe, Battle Axe, Frost Axe and Crescent Axe.
Existing item IDs, ATK, bonus stats, prices, weights, crafting recipes and refine levels remain unchanged.
The default Merchant preview also uses the new Hand Axe model.

The Blender file keeps independently editable parts. Runtime exports combine each axe into one mesh,
with a grip origin aligned to the existing humanoid rig. Exports use res://assets/models/arcane/reforged_*.glb.
Rendered 64px transparent icons replace the corresponding inventory art.

Apply this source patch after the Forest Mage crafting patch. It includes the current items.gd and avatar.gd.
Build source: build_axes.py, then optimize_export.py, then render_icons.py (paths target the local career_expansion project).

Validation: axe integration 38 checks; Forest Mage craft-before-wear 40 checks;
career/quest regression 1,467 checks. All pass. Tests use isolated user data.
Axes checks cover all four resource mappings, original item stats, existing equipment/refine,
actual replacement mesh assembly, swing animation, inventory icons and saved item IDs.
The web export is rebuilt from the updated project. Publication is separate from the local build.
