Mobile portrait layout

Mobile uses a 480x800 logical base with dynamic aspect expansion, preserving existing drawing limits and 30 FPS. The web host requests portrait where supported and removes its rotate-to-landscape blocker. The HUD reserves the top for status and menus, and the bottom for separated joystick, action and touch-sized skill/item buttons. Wide popup split panes reflow vertically; large tables remain scrollable. The map stacks above its destination list without changing its 512-coordinate interactions. Character selection and creation use vertical scrolling and a fitted 3D preview. Desktop layout and viewport snapshots match the previous build.

Validation details in validation.json; native viewport emulation does not replace a real iPhone Safari check. Existing baseline game shutdown resource warnings remain outside this UI change.
