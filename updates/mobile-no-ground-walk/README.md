# Phones: no ground marker / walking from touches (2026-11-06)

The player kept walking (and drawing the ground arrow) while a finger was held, because the hold-to-walk check reads the mouse state that the browser emulates from touches. With the touch HUD active the player now sets `touch_controls`, which disables mouse click / hold walking; movement is joystick-only, taps on monsters / NPCs / loot still work.
