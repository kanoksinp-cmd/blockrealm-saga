# Responsive UI for phones, tablets and PC

Audited the HUD and the main windows (character, bag, equipment, skills, quests,
map, settings, party) plus character select/create at 390x844, 360x740, 844x390,
667x320, 932x430, 768x1024, 1024x768, 1024x600, 1280x720, 1366x768 and 1920x1080.

- **Portrait phones and tablets.** These used to letterbox the landscape canvas into
  a thin strip and show a "rotate your phone" screen. They now get a real portrait
  canvas (`settings.gd`), so the existing portrait HUD and window layouts take
  over. The rotate prompt and the landscape orientation lock are removed from the
  site (`play/index.html`, `assets/game-account.js`, `index.html`).
- **Landscape windows** (`ro_ui_mobile.gd`). Windows grow to fit their content
  instead of clipping tabs and grid columns (bag tabs, the 4th bag column, party
  tabs). They reflow only when even the full width is too narrow.
- **Message toast.** It stays between the status card and the clock / quest
  column, so it no longer covers the money or the clock.
- **Character create/select in landscape** (`char_create.gd`). The option panels
  scroll inside the screen height and scale down slightly when a column is too
  narrow. Randomize sits under the left panel and Confirm/Back under the right
  one, the rotate control is centred under the character, and the account banner
  stays in the middle column. The slot list scrolls, and the logo moves beside it.
  Turning the phone between portrait and landscape keeps the same panels (no
  rebuild, no lost input).
- **"เปิดเสียง" (tap for sound)** moves from the bottom edge, where it covered
  Confirm/Back and the hotbar, to the upper middle of the screen. It still
  disappears on the first touch.

PC layouts were checked at 1024x600 to 1920x1080 and needed no change.

Build: `python build_pack.py <base index.pck> <out.pck>`.
