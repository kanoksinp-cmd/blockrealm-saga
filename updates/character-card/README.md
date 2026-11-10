Character card layout and rotating preview

Identity, job level and guild information use a full-width header. Base attributes align their values, increase buttons and point costs; the combat metrics form eight icon/name/value groups in two columns. Integer-valued attributes no longer show a redundant decimal suffix. Mobile uses paired attribute tiles with touch-sized buttons.

The character uses the same live portrait renderer as inventory and rotates at the same 0.6 radians per second. A pause/resume button switches to a single render; hiding the card disables the portrait render target. Camera framing uses visible model bounds and accounts for the turning radius so wings and weapons stay in view. Framing is recalculated when appearance, equipment, class or fashion changes.

Only the shared character-card presentation changes; Game stats, formulas, point costs and saving remain untouched. Native PC/mobile runtime tests cover values, point spending, rotation/pause/resume, closing the render target, grouped combat metrics and window bounds. Native rendered front/turned screenshots are included. No direct phone Safari check was available. Existing baseline Godot shutdown resource warnings remain outside this UI change.
