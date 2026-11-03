# Account save read errors show their cause — 2026-11-04

After `updates/account-save-loading` went live, the account `guide` still showed
"ยังอ่านเซฟจากบัญชีไม่ได้", so the cause is not a malformed save field. To stop guessing, the
account panel (F9) now appends `[สาเหตุ: ...]` when `game_read_save` fails:
- HTTP status, transport result, and the server's `error` / `code` / `message` / `hint`
- or the response shape (`String`, `empty body`, `revision=...`, `payload ...`)
No session token, password or save contents are shown.

Changed: `scripts/game/cloud_account.gd` (`_read_error`, `_raw` returns `result`),
`scripts/game/account_save_store.gd` (`why_invalid`). Godot 4.7.2, only these .gdc replaced in play/index.pck.

Tested with `qa/fake_supabase.py <broken|norow|http500|text>` + `../account-save-loading/qa/login_test.gd`:
broken/norow load as before; http500 shows `HTTP 500, code=..., message=...`; text shows `HTTP 200, String`.
