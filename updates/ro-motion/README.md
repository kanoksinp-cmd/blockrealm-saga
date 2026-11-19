# Ragnarok-style attack motions and skill effects

Every job now attacks and uses skills with motions in the spirit of Ragnarok
Online, and every active skill has its own effect. All motions and effects are
original and made in the engine; no Ragnarok sprites or files are used.

## Basic attack per weapon (`knight_model.gd`, `_weapon_attack`)
- **Sword:** the existing 3-hit slash combo.
- **Spear:** thrust from the hip.
- **Axe, mace, book:** overhead chop or bonk, then a side swing.
- **Greatsword:** heavy two-handed diagonal, overhead and rising swings.
- **Dagger:** quick stab, slash, stab.
- **Katar:** alternating left/right jabs (Assassin).
- **Knuckle / fists:** jab, cross, uppercut (Monk).
- **Lute:** strum (Bard).
- **Whip:** whip crack.

## Skill motions (`SkillDB.ANIM`, new poses in `_skill_pose`)
- **thrust:** Pierce
- **spiral:** Spiral Pierce (leap, spin, drive down)
- **sweep:** Brandish Spear and Bowling Bash
- **power_up:** Two-Hand Quicken, Aura Blade, Frenzy, Adrenaline Rush, Over Thrust, EDP, Steel Body, Auto Guard
- **falcon:** Blitz Beat and Falcon Assault
- **set_trap:** traps (kneel)
- **aim_shot:** Sharp Shooting
- **dash:** Cart Termination and Intimidate
- **dash_stab:** Back Stab
- **flurry:** Sonic Blow
- **ground_stab:** Grimtooth
- **cast_ground:** Frost Diver, Earth Spike and Heaven's Drive
- **asura:** Asura Strike (charge up, then a dash-punch)
- **cross_slash:** Holy Cross (an X of light)
- **shield_bash:** Shield Charge
- **cross_pose:** Grand Cross and Gospel
- **uppercut:** Tiger Knuckle Fist
- **chop:** Mammonite

## Effects (`ro_skill_fx.gd`)
- **Ragnarok bolts:**
  - Fire Bolt and Cold Bolt fall from the sky onto the target.
  - Lightning Bolt arrives as real lightning from above.
  - Holy Light comes down as a beam.
- **Frost Diver:** ice runs along the ground and traps the target in a block of ice.
- **Recipes for every other skill,** built from:
  - shockwaves and stun stars;
  - fire rings, dust and smoke;
  - line beams (Pierce, Sharp Shooting) and arcs;
  - a drill spiral, a falcon swoop and trap devices;
  - music notes and ghost bursts;
  - coins (Mammonite, Cart Termination) and poison or acid splashes.
- **3rd and 4th-job skills** pick a fitting recipe from their type.
- **Buffs** raise a coloured aura around the caster.

Build: `python build_pack.py <base index.pck> <out.pck>`. `patch_model.py` and
`fx_recipes.gd.txt` are the inputs that produced the model and effect changes.
