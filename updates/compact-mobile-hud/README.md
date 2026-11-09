Compact portrait combat HUD

The phone HUD now has a dedicated compact status card, a three-action navigation row and a party entry button. A closed-by-default 3x2 menu drawer retains all six navigation actions. A two-line primary quest card keeps one-tap travel and quest-auto behavior; the full quest log is still available in the drawer. The old portrait, currency pills, clock, quest tracker and party roster are collapsed in portrait.

Skills use separated circular targets around the attack button, with quick items, auto and hotbar paging in the bottom utility row. The large rectangular hotbar backing is suppressed, including after modal windows close. Joystick travel uses a smaller radius without changing movement speed or combat. Existing portrait viewports and cached icons are reused. Polling runs at five updates per second and button styles rebuild only on auto-state changes.

Only mobile UI and the mobile target-profile position change inside the pack. Desktop layout snapshots remain identical. Multi-size native viewport tests cover bounds, touch separation, all six drawer actions and existing popup layouts. No direct iPhone Safari or real-device performance test was available. Baseline shutdown resource warnings remain outside this change.
