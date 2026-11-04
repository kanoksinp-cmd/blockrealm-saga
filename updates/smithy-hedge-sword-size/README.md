# Smithy front hedge removed, smaller starter sword — 2026-11-05

- village_builder.gd `_town_plots()`: the hedge row at x = 17, z 10–14 stood right in front of the smithy
  doorway; only the west row (x = -17) is kept.
- Starter / basic sword model: voxel size 0.046 → 0.034 m (about 74 %), same design and grip point.
  Total length 1.52 → 1.12 m. Regenerate with `godot --headless -s source/models/gen_basic_iron_sword.gd`.
Builds on updates/starter-sword-fountain-damage. preview.png: sword before / after and the smithy front.
