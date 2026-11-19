# Icons for every skill

133 skills had no icon file and showed a small generic pixel symbol instead:
- every skill of the Crusader, Bard, Sage, Monk, Alchemist and Rogue lines and their
  transcendent jobs;
- every 3rd/4th-job skill;
- the new first-job skills: Napalm Beat, Soul Strike, Fire Wall, Angelus, Sand Attack.

`make_icons.py` draws them in the style of the existing icons: 64x64, a bronze
frame, a coloured radial background and a glowing light glyph. Each skill gets a glyph
that fits it (shield, cross, fist, spirit spheres, music note, lute, flask, bomb,
book, spikes, comet, dice for Abracadabra, puppet for Marionette Control and so on),
coloured by its element or job.

The icons ship as plain PNGs in `assets/icons/skills_ro/`. `SkillDB.icon()` loads them
when no imported icon exists. All 216 skills now have an icon.

Build: `python make_icons.py` (writes `resources/`), then
`python build_pack.py <base index.pck> <out.pck>`.
