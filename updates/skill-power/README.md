Skill power accents

Visual-only integration into release, real impact and support paths for all 151 active skills. Element-specific batched geometry adds physical cross-slashes and force rays, fire eruption rings, lightning forks, icy/earthen fractures, water/wind/shadow spirals, holy crosses, healing motes and buff helixes. Big skill projectiles receive a tapered energy wake using their existing travel and hit callback. Strength modestly scales height and thickness from skill multiplier and learned level; this does not change hit areas or damage.

Each accent has two mesh batches, no particles, lights, shadows, extra timers or hit callbacks. Scene budgets: seven on mobile, eighteen on desktop. Per-source stage coalescing: 110/65 ms; distant effects beyond 65 m are omitted. Lifetime 0.48-0.8 seconds. Existing elemental visuals and reduced mobile particle profiles are preserved. AoE accents stay inside their original radius (subject to existing baseline radius clamp).

QA enumerates 151 active database skills, every element, grouped draw count, geometric bounds, budget saturation, time-based cleanup, coalescing and exactly-once original projectile callback. PC and emulated mobile passed. Existing damage-number arc regression passed. Native compatibility-renderer PC/mobile effect-board captures were reviewed. No physical iPhone thermal/performance test was available. Baseline whole-scene shutdown resource warnings remain; no script/runtime errors occurred before PASS.

Source guard removes only the four inserted player calls/helper and the projectile-tail hook and requires byte-identical baseline code. Exact pack diff allows only player.gd, fx.gd and new skill_power.gd. All combat tables, maps, UI, saves and prior updates remain unchanged.
