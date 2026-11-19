# Auto hunt uses every skill

Auto hunt used to fire only attack skills that were on the hotbar, healed only with
Heal, and always picked the first skill in its list. It now uses every skill the
character has learned for the current job line.

- **Attacks:** all melee, bolt, area, trap and steal skills, hotbar or not. They
  rotate: the skill used longest ago goes next, so every skill gets used. Against a
  group (the "AoE from" setting), area skills go first. Against a single monster,
  area skills join the rotation too.
- **Heals:** below 60 % HP, the strongest learned heal (Sanctuary, Heal, then First Aid).
- **Buffs:** every learned buff is recast as soon as it runs out, given the SP.
  Buffs with long delays (Frenzy, Marionette Control) are saved for when a monster is
  targeted, and Martyr's Reckoning only fires above 70 % HP.
- **Costs and safety:** auto checks SP, Zeny and HP costs and cooldowns before using
  a skill. Asura Strike fires only from a nearly full SP bar, and Grand Cross not
  below 60 % HP.
- **Bug fix:** a skill queued during a swing could wait forever in auto hunt, because
  the next normal attack always started first. Normal attacks now hold off while a
  skill, buff or heal is waiting.

Tested with auto hunt on for Knight, Wizard, Priest, Rogue, Alchemist, Hunter, Monk,
Crusader, Sage and Bard lines at tier 3 with every skill learned. Every active skill
was used, except First Aid and Heal when Sanctuary was available, since auto picks
the strongest heal.

Build: `python build_pack.py <base index.pck> <out.pck>`.
