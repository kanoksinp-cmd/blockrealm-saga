# Play button explains account state — 2026-11-04

## Problem
On the character-select screen, "เข้าเล่น" (Play) and "สร้างตัวละคร" silently did nothing whenever
`CloudAccount.can_play()` was false: account save still loading, account save could not be read,
local/account save conflict, or session expired. The reason was only visible in the F9 panel, so the
button looked broken.

## Change (source/scripts/ui/char_create.gd)
New `_account_blocked()` used by `_slot_action()` and `_confirm()`:
- While the account is loading: shows "กำลังโหลดบัญชีและเซฟ รอสักครู่แล้วกดอีกครั้ง".
- Otherwise: shows `CloudAccount.status`, opens the account panel (F9) so a save conflict can be
  resolved there, and if signed in but the account save was never read, retries reading it.
- Guest play and normal account play are unchanged.

## Build
Only `scripts/ui/char_create.gdc` inside `play/index.pck` was replaced. It was compiled with
Godot 4.7.2-stable; the previous `updates/game-accounts/source` scripts compile byte-identical to the
previous live pack, so this file is the merge base. `play/index.html` points at the new pack hash.

## Validation
`play_button_test.gd` (run: `godot --headless --main-pack play/index.pck -s play_button_test.gd`)
simulates a signed-in account whose save is not loaded and presses Play:
- old pack: no dialog, no message
- new pack: account panel opened, status message shown, save read retried, game not entered
Headless startup of the new pack shows the same output as the old pack (no new script errors).
