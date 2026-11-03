# Fix: account save could not be read on Web (gzip decoded twice) — 2026-11-04

## Cause
The F9 diagnostics from `updates/account-save-diagnostics` showed
`[สาเหตุ: HTTP 200, result 8, empty body]` for account `guide`.
Result 8 is `HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED`. In a Web export the browser's fetch already
decompresses gzip responses but the `Content-Encoding: gzip` header remains, so Godot's
HTTPRequest (accept_gzip = true by default) tried to decompress the body a second time and dropped it.
Small replies (login / whoami) are not compressed by Supabase, so login worked; the larger
`game_read_save` reply is compressed, so the save could never be read.

## Change
`scripts/game/cloud_account.gd` `_raw()`: `req.accept_gzip = false`. The browser still negotiates and
decodes gzip itself, so nothing gets bigger on the wire. This most likely also fixes the in-game
F9 sign-in showing "เชื่อมต่อบัญชีไม่สำเร็จ".

## Validation
`qa/fake_supabase.py gzipheader` sends the save with `Content-Encoding: gzip` on an already-decoded
body (what a browser hands to Godot) — run with `../account-save-loading/qa/login_test.gd`:
- previous pack: `HTTP 200, result 8, empty body`, cannot play (same as the live screen)
- new pack: loads Test Lv 50 and enters the game
`broken` and `norow` cases unchanged (pass).
