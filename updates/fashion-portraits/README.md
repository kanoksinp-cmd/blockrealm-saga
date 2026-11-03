# Fashion profile shows the full outfit — 2026-11-04

The Hallow Spectres recipe cards and fashion dialogs used a generic gem icon. They now show a
full-body picture of a character wearing the outfit (rendered from the game, no weapon so it fits every job).

- `source/assets/icons/items/<id>_fashion.png` (96×128): loaded by `Items.flat_icon()` from `res://assets/icons/items/`.
- `items.gd`: the 3 fashion items have `"portrait": true`; `Items.icon()` does not hand portraits to
  ItemModels, so the picture is not turned into a 3D voxel icon.
- `ro_ui.gd`: smithy fashion cards show the picture in a 96×128 frame; the fashion menu/detail dialog
  shows it as the dialog portrait.
- `render_portraits.gd`: re-renders the pictures (`xvfb-run godot --rendering-driver opengl3 --main-pack play/index.pck -s render_portraits.gd`).

Builds on updates/hallow-spectres-fashion. Fashion test 139/139 pass, UI test pass, startup log unchanged,
account login/load still passes. See smithy_fashion_tab.png.
