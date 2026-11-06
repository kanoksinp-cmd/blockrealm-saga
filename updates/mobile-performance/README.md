# Mobile performance and target display

Based on 24e0c2d; preserves the current pack, account system, touch controls and content.
Release: c278be444f6708b9 (17552016 bytes).

Mobile uses 30 FPS (10 while the document is hidden), no dynamic shadows/MSAA,
no cloud/weather/outlines/xray, camera distance capped at 120, cosmetic particles
capped at 40% / 32 per emitter, and no continuously rotating item thumbnails.
Saved desktop settings are retained; physics ticks and save/account code are unchanged.
The web canvas is capped at DPR 1.25 and 1280 by 800, preserving aspect ratio and
CSS input coordinates. Uses canvasResizePolicy=0; 3D resolution remains 1.0.

Mobile target panel: 190 wide instead of 304, portrait 36 instead of 64,
HP bar 16 instead of 22; monster overhead bars scale 0.62 including billboard updates.
Project application icon now uses the same 512px artwork as web/PWA icons,
with a root favicon.ico fallback and versioned favicon URLs.

Validation: Node tests for phone/iPad/desktop detection, pixel caps and rotation;
Godot mobile/desktop settings, unmodified preferences, HP ratios/billboards,
particles/lights/icon checks; target HP/portrait/switch/death regression;
native rendered mobile HUD preview. Existing shutdown resource warnings remain.
Actual phone temperature and sustained FPS need measurement on the device.
