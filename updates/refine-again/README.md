# Refine again

When a refine attempt finishes, the result window now shows a green
"ตีบวกอีกครั้ง" (refine again) button beside "กลับไปโรงตีเหล็ก". It starts the
next attempt on the same slot straight away, using the same guarantee-stone
setting. Missing ore or zeny opens the usual blacksmith message. The button is
hidden once the item reaches the maximum refine level.

Changed: `scripts/ui/refine_popup.gd`, `scripts/ui/ro_ui_base.gd` (`_begin_refine`).

Build: `python build_pack.py <base index.pck> <out.pck>`.
