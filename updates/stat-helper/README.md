# Stat point helper

The character card now helps with status points, Ragnarok style.

- **Recommended builds for each job line**, two per line. For example:
  - Knight: AGI-STR or VIT-STR
  - Crusader: Grand Cross INT-VIT or VIT-STR tank
  - Wizard: INT-DEX or INT-VIT
  - Sage: INT-DEX or INT-AGI
  - Priest: INT-VIT support or STR-AGI battle
  - Monk: Asura STR-INT-DEX or STR-AGI combo
  - Hunter/Bard: DEX-AGI, plus DEX-INT traps or DEX-VIT songs
  - Blacksmith: STR-VIT or STR-AGI
  - Alchemist: DEX-INT flasks or STR-AGI
  - Assassin: AGI-LUK critical or STR-DEX Sonic Blow
  - Rogue: AGI-STR or DEX-AGI bow

  First jobs see their branch-A builds, and Novices a balanced build.
- **Auto-allocate button:** spends the points by the chosen build. It always raises the
  stat that is furthest behind its target share. When that stat costs more than the
  points left, it saves them, as Ragnarok players do.
- **"Auto on level up" switch:** spends the new points by the build on every
  base-level-up.
- **Recommended next stat:** marked with a star, and the window shows the build's
  priority order.
- The stat "+" buttons now show a readable "+".

The chosen build and the switch are kept in `auto_cfg` ("stat_build", "auto_stats"),
so older saves load unchanged.

Build: `python build_pack.py <base index.pck> <out.pck>`.
