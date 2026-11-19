# Party skill effects and hotbar cooldowns

## Party members use real skills with visible effects
Party members used to fire one fixed skill per job with only a small generic flash.
`party_member.gd` now does the following:
- They rotate through the attack skills of their job line, up to the party's tier,
  for example Bash, Magnum Break, Pierce, Brandish Spear, Bowling Bash and Spiral
  Pierce for a swordsman.
- Each skill plays its own motion and the same Ragnarok-style effect the player's
  skill has (`ro_skill_fx.gd`):
  - Fire and Cold Bolt fall from the sky, and Lightning Bolt strikes from above;
  - magic circles appear under area spells;
  - Storm Gust, Meteor Storm and Lord of Vermilion use their signature effects;
  - Blitz Beat sends the falcon;
  - other skills use their shockwaves and arcs.
- Area skills also hit the monsters around the target.
- A party member's heal shows the healing light and aura on the healed member.

## Hotbar cooldowns (PC)
- A dark clockwise sweep, Ragnarok style, covers the part of the delay still to go,
  with bold seconds in the middle.
- The slot flashes when the skill is ready again.
- Buff skills show the time left on the active buff in green (bottom left).
- The mobile skill buttons already had a sweep; they are unchanged.

Build: `python build_pack.py <base index.pck> <out.pck>`.
