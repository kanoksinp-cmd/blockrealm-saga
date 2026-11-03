# Game accounts and web-backed saves — 2026-11-04

The default Play button now opens account.html. Players register or sign in with a game username and password, then the same-origin page starts the game and hands it a session in memory. Direct F9 account management is also supported. The homepage retains an explicit local-save play button. Email verification, magic links and SMTP are not involved in game-account login.

## Account and data design
Accounts are stored in the existing Supabase PostgreSQL database under game_private. Passwords are salted bcrypt hashes with work factor 10; passwords are never saved in game files or browser storage. Usernames are canonical lowercase ASCII, 3–24 characters, starting with a letter. Passwords have an 8-character minimum and 72 UTF-8 byte maximum (bcrypt input limit).

Sessions are random 256-bit tokens, stored as SHA-256 hashes on the server, expire after 24 hours, and are kept only in page/game memory. Up to 16 sessions per account are allowed. Refreshing the whole account page requires signing in again. Reloading the embedded game preserves its current account; signing out clears that handoff. Password recovery and password-change UI are not included in this change.

No private table is exposed to anonymous/authenticated direct access. Public RPCs derive the owner from the session token, accept no client-selected account ID, and run with a fixed empty search path. Invalid login responses are generic and use a dummy bcrypt comparison for absent usernames. Server-side attempt budgets cover global, per-IP and per-username auth requests; failed attempts return normally so counters remain committed. An opaque token does not grant Supabase administrative access.

## Saves
All five slots and the full existing Game.SAVE_KEYS bundle are synchronized: character name, level, EXP, currency, inventory, equipment, skills, quests, fashion unlocks and position. Guests and each account have separate local caches. Save writes compare the server revision under a row lock; stale-device conflicts require choosing a version. The previous local copy and remote conflict snapshot are backed up before replacement. Offline changes remain queued locally. Guest characters are copied only after the player explicitly selects that action, without overwriting occupied account slots. Existing email-system tables/data are preserved independently.

Game saves remain client-driven, as in the original RPG; this is not a server-authoritative anti-cheat implementation. Wait for successful sync before changing devices.

## Installation and rebuilding
1. Run game_accounts.sql in the intended Supabase SQL Editor. The project used here already had pgcrypto installed in the extensions schema. The migration was applied successfully without changing Supabase Auth settings or disabling email confirmation.
2. Merge source/ into the complete Godot project and export Web.
3. Keep prepare_web.py beside account-bridge.js and run python prepare_web.py <export-directory>. Copy index.html, index.pck and account-bridge.js into play/.
4. Keep account.html and assets/game-account.js from the repository. The frontend and Godot config contain the same public publishable key; never put a secret/service-role key into either.

The bridge removes obsolete email callback fragments. Game credentials and sessions are never placed in URLs. The HTML form uses POST even if JavaScript fails, and its submit buttons are enabled only after the script is initialized.

## Validation
- 39 PostgreSQL/PGlite database checks passed: bcrypt hashes, duplicate names, incorrect credentials, account isolation, token forgery/expiry, scoped logout, revision conflicts, invalid saves, direct-access denial and persistent login throttling.
- 31 Godot checks passed against an HTTP fixture backed by the real SQL migration and pgcrypto: registration, guest copying, full character restoration on a second cache/session, offline retry, both conflict choices, in-flight changes, deletion and portal-session verification.
- 18 frontend checks passed: registration validation, safe password handling, account handoff, reload/logout handoff behavior and login errors.
- 14 production API checks passed using two isolated generated QA accounts: registration, stable-ID login across sessions, write/read restoration, other-account isolation, stale-revision rejection, session-scoped revocation and private-schema denial. QA passwords/tokens were generated only in memory and were not logged; all sessions from that test were revoked. QA account names are recorded in live_validation.json.
- Forest Mage save regression: 40 checks passed. Browser inspection confirmed the registration fields and no horizontal overflow at desktop and 390px mobile width. Production CORS permits the game site.

Sources: https://www.postgresql.org/docs/current/pgcrypto.html and https://pglite.dev/extensions/.
