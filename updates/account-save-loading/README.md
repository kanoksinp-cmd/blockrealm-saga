# Signed-in play loads the account save — 2026-11-04

## Problem
After signing in, the account panel said "ยังอ่านเซฟจากบัญชีไม่ได้" and Play stayed blocked.
`_fetch_remote()` rejected the whole downloaded bundle if any single field failed `Store.valid()`
(wrong type / missing key), and also failed when `game_read_save` returned `null` (no saves row).
A device with unsynced local changes could also be blocked by a save conflict.

## Change
- `account_save_store.gd`: new `Store.sanitize()` repairs a downloaded bundle field by field
  (wrong-typed or missing fields fall back to the game default) instead of rejecting it.
  Healthy saves pass through unchanged.
- `cloud_account.gd`:
  - `game_read_save` returning `null` is treated as an empty account.
  - On sign-in the account save is always used (account-only). The previous local copy is
    backed up by `Store.install()` under `user://accounts/<id>/backups/`; pending/conflict are cleared.
- Builds on `updates/play-button-account-status` (char_create.gd from there is included in the pack).

## Build
`scripts/game/account_save_store.gdc` and `scripts/game/cloud_account.gdc` (and char_create.gdc)
replaced in `play/index.pck`, compiled with Godot 4.7.2-stable. `play/index.html` points to the new pack.

## Validation (godot --headless --main-pack play/index.pck, fake server: python qa/fake_supabase.py <broken|norow>)
| case | old pack | new pack |
|---|---|---|
| account save with broken fields | can't read, can't play | loads Test Lv 50, enters game |
| no saves row (`null`) | can't read, can't play | empty account, create character |
| local unsynced changes (old revision) | can't read, can't play | account save used, enters game |
Healthy save round trip: unchanged except `last_slot` 0.0 → 0. Startup log identical to old pack.

## Not changed
Supabase SQL. If an account has no saves row, uploads cannot be stored until the row exists
(`game_write_save` updates, it does not insert).
