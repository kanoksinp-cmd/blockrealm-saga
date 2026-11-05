# Mobile: full screen + touch HUD (2026-11-05)

Phones / tablets (touch + coarse pointer, or `?mobile=1`; `?mobile=0` forces desktop):

- account.html / assets/game-account.js: after sign-in the game goes full screen and
  locks landscape. If the browser refuses (no user gesture), a "แตะเพื่อเล่นเต็มจอ" screen
  asks for one tap. Rotate-phone screen in portrait, ⛶ button when the browser drops
  full screen, tap-in-game re-enters it (not while typing), screen wake lock,
  safe-area padding, no page zoom/scroll. iPhone Safari (no full-screen API): fixed
  full-viewport layout + one-time "Add to Home Screen" tip.
- scripts/ui/mobile_hud.gd (new): floating left joystick (camera-relative), tap = click,
  hold = walk toward finger, drag = turn camera, pinch = zoom; action pad with sword
  (loot > current target > nearest monster > NPC/gather spot), 4 hotbar skills x 4 pages
  with cooldown sweep, 2 quick items, AUTO, chat button with unread badge, message feed.
  Multi-touch: every button reads raw touches.
- scripts/ui/ro_ui.gd: UI scaled by the phone's short side (~1.2x a 720p desktop),
  desktop hotbar/pills/key hints hidden, compact minimap/menu/tracker layout, windows
  shrink to fit the screen, bigger close buttons. Desktop is unchanged.
