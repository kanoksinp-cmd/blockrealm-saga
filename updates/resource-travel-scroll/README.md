# Resource travel and mobile window scrolling

Find beside a crafting material now starts automatic gathering and travels through normal map portals to the closest reachable source map. Resource selection filters the actual loot table. Manual movement or stopping AUTO cancels the task. Gathering retains its existing local respawn behavior.

Mobile window lists use direction-locked finger displacement with bounded scroll values. Nested lists pass unused movement to their parent. Scrolling cancels button activation before content moves, stops on release, and pauses window refitting. Inventory/equipment actions open on completed taps. World camera gestures and desktop UI layout are retained.

Validation: qa_gold.gd activates the real fashion recipe Gold Ore Find button inside the smithy, walks smithy -> town -> desert with normal portal travel, begins mining, verifies the node has gold in its original loot table, then uses a deterministic test-only loot table to assert inventory receipt. Enemies are disabled and movement accelerated in the isolated test save. Also verifies a return route to town and cancellation.

qa_scroll.gd injects touch and emulated mouse events: exact up/down movement, no inertia, no accidental button activation, single tap once, nested horizontal/vertical selection, edge handoff, and release-only inventory actions. Verified at landscape viewport 1055x488 with mobile override. These are engine simulations; physical phone testing remains useful.

Existing map/gather regression passes at 1055x488 and 844x450, including full map bounds and taps, mid-mine AUTO activation, multiple harvests, respawn waiting and normal hunting. Sources are overlaid into the existing PCK, preserving other assets. Headless shutdown reports existing renderer/resource cleanup warnings.
