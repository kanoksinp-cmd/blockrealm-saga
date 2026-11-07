# Full viewport play and platform HUD selection

- Account play fills the available browser viewport, without a permanent account header. A compact expandable account menu provides fullscreen and website links. Mobile keeps its existing fullscreen, orientation and safe-area behavior.
- Both loading stages use navy/gold branding, a restrained logo and a slim progress bar. Browser progress reflects transferred bytes; world loading preserves its existing threaded scene transition.
- Desktop `ro_ui.gd` uses the preserved classic base (six icon menus, classic windows and hotbar). Touch devices switch to `ro_ui_mobile.gd`, copied unchanged from the latest mobile layout/audio release. Narrow desktop windows do not select the mobile HUD based on width alone.
- Existing account/session bridge, save flow, audio unlock, patched web audio engine, mobile resolution and frame limits are preserved.

Validation: native rendered loading at 1440x900, 800x600 and 1055x488; main-scene transition reaches 100% and removes the overlay; desktop original menu count and absent modern UI state; mobile compact layout, quest bounds, party default and audio-resource regression checks.

The pack builder overlays raw changed scripts onto the current pack and retains every other original entry. It removes compiled/remap entries for overridden scripts. Do not export the older full Godot project over this release.
