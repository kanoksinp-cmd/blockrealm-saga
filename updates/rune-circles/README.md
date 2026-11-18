# Rune circles (Ragnarok-style casting circles, original art)

- The casting circle under the caster is now a glowing rune circle. A ring of
  generated runes turns slowly one way, and an element sigil turns the other way
  (fire hexagram, water ripples, wind swirl, earth squares, lightning star, ice
  flake, holy sun, shadow pentagram, physical compass). Under them sit a tinted
  glow, a faint column of light and rising motes. The circle opens with a small
  spin-in and fades out at the end.
- Area spells (type `aoe…`) also show a rune circle on the target's ground while
  casting.
- The textures are pre-made (`assets/fx/rune_*.webp`, about 400 KB, made by
  `tools/make_circles.py`) instead of the old per-pixel GDScript drawing, which
  makes them faster on phones too.
- Code: `ElementFX.rune_circle()` (`element_fx.gd`). `ElementFX.circle()` and
  `FX.magic_circle()` now use it, and the area-target circle is in `player.gd`.
