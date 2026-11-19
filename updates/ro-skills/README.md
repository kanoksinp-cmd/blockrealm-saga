# Ragnarok-style skills

All job skills now follow Ragnarok Online (pre-renewal): names, max levels, SP
costs, cast times, after-cast delays, damage, hit counts and prerequisites. The
skills window works like Ragnarok's, and the best-known skills have their own effects.
All art is original and built in the engine; no Ragnarok assets are used.

## Skills
- **Branch B second jobs are now the Ragnarok jobs:** Crusader → Paladin, Bard → Clown,
  Sage → Professor, Monk → Champion, Alchemist → Creator, Rogue → Stalker. Their
  skills are Ragnarok skills, for example Grand Cross, Holy Cross, Shield Chain,
  Unbarring Octave, Arrow Vulcan, Earth Spike, Heaven's Drive, Abracadabra, Double Bolt,
  Asura Strike, Steel Body, Acid Terror, Back Stab, Raid, Snatcher and Plagiarism.
- **Third and fourth jobs** (Rune Knight, Royal Guard, Warlock, Sura, Genetic and the
  rest) have real skill names instead of the placeholders (for example Ignition Break,
  Prestige, Comet and Rampage Blast).
- **New first-job skills:** Napalm Beat, Soul Strike and Fire Wall (Mage), Angelus
  (Acolyte), Sand Attack (Thief).
- **Ragnarok numbers.** Some examples:
  - Bash costs 8 SP at levels 1–5 and 15 SP at 6–10.
  - Fire, Cold and Lightning Bolt cost 12–30 SP, take 0.7 s of cast per level and
    have a 1–2.8 s delay.
  - Storm Gust costs 78 SP, casts in 6–15 s, hits 10 times and freezes on the third hit.
  - Meteor Storm casts in 15 s, Magnus Exorcismus in 15 s, Lord of Vermilion in 15 s.
  - Holy Light and Cart Revolution are level 1 only.
  - Pierce hits once on small, twice on medium and three times on large monsters.
- **DEX shortens casts** like in Ragnarok: cast × (1 − DEX/150), so 150 DEX means no
  cast time. Magic Strings (Bragi), Memorize, Radius and Climax shorten casts further.
- **New mechanics:**
  - Grand Cross costs 20 % HP.
  - Asura Strike spends all SP, and its damage grows with the SP spent.
  - Ankle Snare, Hammer Fall and Unbarring Octave only disable; they deal no damage.
  - Abracadabra rolls a random element and strength.
  - Double Bolt can fire a second volley of a bolt spell.
  - Raging Trifecta Blow turns normal attacks into three hits.
  - Snatcher steals on normal hits.
  - Mana Recharge lowers the SP cost of every skill.
- **Saves:** skill ids are unchanged, so learned levels and hotbars keep working.
  Levels above a skill's new maximum are refunded as skill points. Skills that became
  passive are removed from the hotbar.

## Skill window (Ragnarok style)
- Every skill in the tree has its own **+** button.
- Points wait as "Pending" until **Apply**; **Reset** cancels them. Pending points count
  toward prerequisites, so you can plan a whole branch before applying.
- A slot grid sits behind the tree, and the prerequisite lines turn gold when met.
- The info panel shows:
  - type (offensive, supportive or passive), max level and target;
  - for the current and next level: effect, SP, cast time after your DEX, delay,
    duration and Zeny cost;
  - each requirement, in green or red.
- **Drag a skill icon onto the hotbar** (PC). Tapping the icon still adds it to the
  first free slot.

## Effects (`scripts/combat/ro_skill_fx.gd`)
- **Storm Gust:** a blizzard with whirling ice shards and a wall of wind.
- **Lord of Vermilion:** thunderbolts raining down.
- **Meteor Storm:** falling meteors with fiery tails.
- **Magnus Exorcismus:** a golden cross on the ground with light columns.
- **Grand Cross:** a cross of holy beams.
- **Fire Wall:** a line of fire across the target.
- **Gravitation Field:** a purple vortex.
- **Heaven's Drive and Grimtooth:** rock spikes.
- **Napalm Beat:** a ghost burst.
- **Asura Strike:** a shockwave and a pillar of light.
- **Sonic Blow:** eight slashes.
- **Holy Cross:** a cross of light.
- **Unbarring Octave:** an icy ring.
- **Gospel:** a golden hymn.
- **Self skills:** Sanctuary's healing grid, Kyrie and Steel Body barriers,
  Assumptio's wings, falling light for blessings, a red aura for Frenzy, and orbiting
  spirit spheres.

Thai text for every new name, description and window label is in `SkillDB.TH`,
registered by `settings.gd`.

Build: `python build_pack.py <base index.pck> <out.pck>`.
