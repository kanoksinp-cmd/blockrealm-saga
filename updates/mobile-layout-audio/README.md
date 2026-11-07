# Mobile layout and web audio repair

Baseline: adcecb4, pack 474b87dc62d875ff. All gameplay, accounts and saves are retained.

Mobile HUD: player card scale 0.86, three navigation buttons, compact location/time,
minimap scale 0.42, no tiny zoom controls (full map remains accessible from Menu),
collapsed party on entry, and a short quest tracker anchored by its actual width
above the action pad. Joystick, skills, potions and attack touch sizes are retained.
Desktop card scale and existing journal behavior are retained.

Audio: the shipped engine has the upstream Bus.addAt(-1) routing defect. The
append sentinel was passed to Bus.move, reordering Master and disconnecting its
output. The patch adds index>=0 to the existing move condition. Keeps sample
playback, mixer volumes and mute settings; no audio-driver or WASM replacement.

Reference: https://github.com/godotengine/godot/issues/119026
Upstream proposed fix: https://github.com/godotengine/godot/pull/119027
Original Godot index.js licensing notices are preserved.

audio-unlock.js loads before the engine in the game iframe. It tracks native
AudioContexts while retaining their prototype, resumes on in-frame gestures,
retries interrupted audio on return, and shows an accessible Open Audio button
only when the browser is blocking audio. It never changes saved volume preferences.
DOM data-br-audio-state supports read-only browser verification.

Validation: Node test reproduces the original bus order defect and verifies four
patched buses, Master destination routing and mute/unmute. A separate test verifies
gesture unlock, interruption recovery and no redundant resume while running.
Godot mobile/desktop checks validate HUD bounds, compact tracker, modal input reset,
audio buses and existing assets. Native rendering verifies the phone layout.
Phone hardware mute/volume settings remain controlled by the user/device.
