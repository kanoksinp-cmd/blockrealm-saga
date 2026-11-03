# Email accounts and cross-device saves — test rollout

The existing Supabase project gqbqbosjszmlhebbsbmy was resumed and the supplied supabase_setup.sql migration was applied successfully. Only the public publishable key is included in the client; no secret or service-role keys are used.

## Current rollout
Owner testing only. Supabase's default email sender is still in use. It sends to authorized project-team addresses, and custom email templates are disabled until custom SMTP is configured. The default email contains a sign-in/confirmation link, so the test UI accepts a copied link directly. It verifies its token hash through Supabase, without following redirect_to or accepting other origins/recovery links. A real email sign-in and two real devices still need the owner to verify their own email. No actual email or token was read or entered during development.

## How to test
1. Open the game and choose บัญชีอีเมล / เซฟข้ามเครื่อง (or F9 on the character screen). Account management is also under Options → บัญชีอีเมล.
2. Enter the authorized email and select ส่งอีเมลยืนยัน.
3. In the email, right-click Sign in or Confirm your email and copy its link. Do not open it first. Paste that link into the game's verification field and confirm. Do not post the link into a chat.
4. A new account starts with empty cloud slots. Explicitly choose คัดลอกตัวละครเดิมในเครื่องเข้าบัญชี to copy the guest characters into empty slots. The original guest files stay intact.
5. Before changing devices, save/sync and wait for บันทึกเข้าบัญชีแล้ว. On a second device use the same email and verify again, then wait for hydration before playing.

## Save behavior
All five character slots, inventory, currency, equipment, fashion unlocks, quests, skills and position sync together. Guest and account caches use separate directories. Signing out restores guest storage. Tokens remain in memory only; no password, email verification link or session token is stored in game saves. A page reload needs a new email sign-in.

Local writes persist while offline and retry while signed in. Atomic revision checks prevent a stale machine from overwriting another device. Conflicts require a choice at the character screen; replacing local saves makes a backup, and selecting local over remote also preserves a remote snapshot. Wait for successful sync before moving to another device.

## Security and limits
RLS permits authenticated users to read only their own row. Direct REST writes are denied. A security-definer RPC derives the user from auth.uid(), requires confirmed email, validates bundle size/shape and serializes revision checks under a row lock. It accepts no client-supplied user ID. It is a client-driven RPG save sync, not server-authoritative anti-cheat.

## Public launch later
Configure a production email sender in the Supabase dashboard using your own credentials. For numeric OTP emails, customize both Confirm signup and Magic link or OTP templates with {{ .Token }}; keep email confirmation enabled. Then set test_only=false in account_config.cfg and export again. Do not publish secret or service-role keys.

## Validation
30 Godot account-flow checks passed against a local HTTP fixture (no real email): invalid code, valid token-hash login, namespace isolation, guest import, full second-device bundle restore, offline retry, conflict choices, token refresh, writes during upload, deletion sync and logout. 21 real PostgreSQL-compatible security checks passed using PGlite: RLS isolation, no anonymous access, no direct writes, verified email and revision rules. Career regression 1467 and Forest Mage regression 40 passed. Production anonymous reads and RPC writes both returned 401. The web export includes the public account config and the browser UI was inspected. The existing Rect2i startup warning was reproduced in the pre-change baseline.

## Rebuild
Copy source/ into the complete Godot project and export Web. Then run `python version_web_pack.py <export-directory>` before copying index.html and index.pck into play/. This appends the pack content hash to its request URL so browsers do not keep loading an older game. Preserve all existing play/ runtime files.

## References
- https://supabase.com/docs/guides/auth/auth-email-passwordless
- https://supabase.com/docs/guides/auth/auth-email-templates
- https://supabase.com/docs/guides/auth/auth-smtp
- https://supabase.com/docs/guides/database/postgres/row-level-security
