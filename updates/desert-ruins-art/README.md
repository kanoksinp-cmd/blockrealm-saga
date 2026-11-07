# Desert and Verdant art, readable combat

Adds three static ruin courts in Desert and two in Verdant. Terraced side platforms, broken columns, warm/cool stone trim and masonry paving frame a level central corridor. Placement reserves existing routes, gates and full monster spawn radii. Platforms are scenery; central court routes retain the current movement height.

Desert lighting balances warm sunlight with cool ambient fill and a thinner haze. Verdant uses a cooler stone/forest balance. Shared masonry paving uses broad procedural ashlar joints instead of high-frequency texels, without new image assets or extra material passes.

The existing dither cutaway now works on mobile and has a softer edge. Its discard runs before costly world texture shading. The user's x-ray toggle remains respected. This uses the existing camera/player uniforms; no additional ray casts or per-object transparency sorting.

Combat: lower particle counts and opacity, bounded concurrent elemental circles/impacts, shorter outward ice crystals, reduced circle glow, no cosmetic particle/crystal shadows, and no elemental flash lights on mobile. Damage, skill radius, hit callbacks and cooldowns are unchanged. Existing mobile 30 FPS, resolution caps, shadow/MSAA limits and audio/account behavior remain in place.

Validation: both regions retain clear court corridors, warp gates and spawn footprints; all 11 region/dungeon service checks pass; native rendered PC and mobile-profile previews; all elemental effects execute and clean up in both profiles; mobile cutaway toggle updates world materials; particle caps and disabled mobile shadows/MSAA checked. Mobile profiles are simulated on desktop, not a phone thermal benchmark.
