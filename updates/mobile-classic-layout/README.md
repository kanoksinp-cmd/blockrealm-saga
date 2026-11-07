# Classic PC layout adapted for touch

Mobile now extends the preserved classic PC HUD rather than the modern interface. Six original icon menus stay above the playfield, character and party are on the left, map/clock/quest tracker on the right, and a 4-column / 2-row rectangular skill/item dock in the lower centre. A left joystick and large right attack/context button remain available. All 16 hotbar slots are accessible through four pages.

Touch slots and menu buttons are 54 logical pixels (45 CSS pixels under the normal phone profile). Keyboard hints are hidden. Currency moves below the menu on narrower windows. Mobile account play respects top and bottom device safe-area insets.

Classic inventory, character, skill, shop and settings windows retain the original style and controls. Their contents scroll rather than shrinking the whole window. Close/service buttons remain touch sized. NPC choices wrap into three columns. Opening a window stops current gestures and hides combat controls; closing restores them. Chat hides the dock during typing. Important messages keep a short non-blocking toast. Equipment/fashion portrait refresh remains enabled, with the equipment preview rendered only when it changes.

Validation: desktop classic dispatcher unchanged; native mobile previews at two landscape aspect ratios with three companions; six-menu geometry and quest/dock bounds; inventory/character/skills/settings bounds with scale 1; long NPC choice list; all four hotbar pages; simultaneous movement and slot touch, gesture cancellation on modal open, chat restoration and finger scrolling. Existing performance, world content, account saves and audio are retained.
