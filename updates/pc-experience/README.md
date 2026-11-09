PC experience tools

The classic desktop HUD remains the default. Options now links to PC Tools, with saved HUD editing, per-job keyboard profiles, bounded combat history, optional nearby boss wind-up warnings, graphics presets and a frame cap. Existing title-bar windows remember where they were closed and fit the current viewport.

Inventory adds search, category filtering, name/type/price/gear-score sorting, explicit sale locks, multi-selection and a two-column hover comparison. Multi-item selling requires the NPC sell tab and proximity to that same vendor. Its scrollable confirmation snapshots item counts and prices; changed or locked items abort the whole plan before sale. Equipped items are outside the inventory stack and are not sold.

Map search covers loaded NPCs, every monster/boss zone and gather sources. Pins persist locally. Resource pins are area-level. Choosing a gather source passes its area to the existing travel/gather routine; all existing one-argument callers keep their previous behavior.

PC preferences and sale locks are local per browser/device; game-account saves are unchanged. All mobile UI scripts are byte-for-byte preserved. The combat observer runs only for PC and does not alter damage math. Combat history records what happens to monsters, including hits from party members, and does not claim player DPS. Warnings use the shared monster wind-up state and do not predict every bespoke boss skill.

Validation and practical limits are in validation.json. Native captures are in previews/. Existing baseline game shutdown resource warnings are outside this feature change.
