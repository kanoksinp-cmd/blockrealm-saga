# RPG feel pack (2026-11-05)

- **Profile card** (top-left) rebuilt ~30% smaller: round portrait + level badge, name / job on one line,
  slim HP / SP bars, thin EXP bar with % (exact numbers in the tooltip).
- **Damage numbers** stack upward like Ragnarok Online: each new hit appears at the bottom and pushes the
  earlier numbers one row up (combat/damage_popup.gd, combat/fx.gd).
- **Stat change popups**: equip / unequip, buffs, stat points, level up ... any change to ATK, DEF, HIT,
  FLEE, CRIT, ASPD, MaxHP, MaxSP or STR..LUK floats "ATK +12" (green) / "DEF -3" (red) by the hero.
- **Level up**: Ragnarok-style feathered angel wings open behind the hero, flap under a golden halo and
  light rays, then rise and fade with drifting feathers (combat/level_up_fx.gd).
- **Auto Quest** button on the quest tracker: walks to every quest, accepts / completes quest dialogs on
  a short countdown, hunts, reports back and continues; steps that need a choice (skills, stats, gear,
  job change) open the right window and pause.
- **Running**: trips longer than 16 m switch to a run (x1.6 speed, forward lean, longer stride, dust).
- **Elemental skills**: every element has its own glyph magic circle (cast + impact) and impact —
  fire flames/embers, water geyser/splash/ripples, wind tornado/leaves, earth rock spikes/dust,
  lightning bolts from the sky, ice crystal bloom/frost (combat/element_fx.gd; mapping in player.gd).
- **Refine aura**: +7 gear wraps the body in light (rim glow shell, veil, rising motes, ring);
  +9 adds a crackling lightning aura (voxel/refine_aura.gd).
- **Cape** rebuilt as a thin double-sided cloth that ripples all the time and billows when running
  (characters/cape_flow.gd).
- **New game icon / splash**: voxel block + hero sword + angel wings on a starry sky (tools/make_icon.py),
  favicon, apple-touch icon, PWA 192/512 + maskable, loading splash.

Sources here are the editable scripts; the pack is built with tools/build2.py (compiled scripts are
recovered with tools/gdc_decomp.py, which round-trips all 68 .gdc files byte-for-byte).
