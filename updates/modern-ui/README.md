# Modern game interface

Baseline: a92a53f (current published mobile performance release).
The release preserves packed content and gameplay/account data; new ro_ui.gd
extends the preserved interface controller in ro_ui_base.gd.

Implemented:
- Shared charcoal/gold theme, pinned window header/close/footer and scrollable body.
- One active primary window, input cancellation, hidden mobile controls during modals.
- Labeled compact navigation, collapsed party option, indoor location instead of empty minimap.
- Character tabs for stats, equipment and actual fashion catalog.
- Inventory search, sorting, item selection/details/comparison and use/equip controls.
- Skill career tabs wrap, tree and detail share adaptive columns; existing skill callbacks retained.
- Main/side/completed quest journal backed by Story/SideQuests, compact active tracker.
- Smith category flow and equipment/detail refine view, primary refine action pinned in footer.
- NPC choices use contained grid, small portrait and wrapped dialogue.
- Shop buy/sell, category filter, selected details, quantity and total from actual prices.
- World/local map uses existing data; zoom and projection use actual displayed dimensions.
- Existing AI/online party, guild, profile, invitation and gift contents share the new window shell.
- Settings retain real controls and account panel; mobile effective constraints are explicit.
- Unified bounded message queue, existing automatic respawn countdown, cached portraits.
- Compact refine result presentation, single committed roll, no world pause; loading/title palette.
- Account web page colors match game; auth and cloud-save logic unchanged.

Proposed features without underlying game support (e.g. dismantling) are not exposed
as fake working buttons. The existing blacksmith services and actual recipe categories
are retained. Death remains the existing automatic three-second respawn.

Validation:
- Headless mobile and desktop: window bounds, one-modal rule, touch input reset,
  inventory search/fashion, shop price and item counts, every smith category,
  one refine charge on repeated input, result completion without pausing the world,
  dialogue grid and map coordinate roundtrip; narrow landscape layout.
- Character creation -> loading -> main scene regression.
- Native OpenGL renders of HUD, character, inventory, skills, quests, map, settings,
  party, guild, smith, shop, dialogue and chat on mobile layout.
- Existing exit-only renderer resource warnings are still present.
- Phone sustained temperature is not measurable from desktop tests.

Use build_pack.py with the source directory to rebuild only the affected packed scripts.
The original engine JS/WASM, mobile performance bootstrap and game content are retained.
