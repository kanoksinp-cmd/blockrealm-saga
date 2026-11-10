Party skills, readable damage and larger hero cards

Damage display scale rises from 0.7 to 1.1; ordinary/critical fonts become 38/46 instead of 25/29. Shrinking starts later for readability; the original ballistic path, 1.15-second lifetime, color rules and eight-popup-per-target budget remain.

Character Card: enlarged preview column, orthographic framing of the complete rotating silhouette, and viewport resolution matched to the displayed image aspect to avoid stretching. Portrait mobile stacks the figure above paired stat tiles. Online profiles also have larger previews and the same framing helper. Rotation/pause and disabled-when-hidden rendering remain. No changes to combat attributes or stat spending.

NPC party members now schedule explicit profession skill animations before normal attacks when their existing skill cooldown is ready and their target is in range. The actual animation hit marker invokes the shipped original skill-hit implementation exactly once, preserving its damage formulas, projectiles and random 6-9-second cooldown. Out-of-range, dead, busy and invalid-target checks prevent spurious skills. Abandoned animation queues are cleared. Skill-name feedback and bounded elemental accents make their casts visible. Healer behavior remains and gains visible feedback.

The original shipped party AI is retained as party_member_original.gdc; its class identifier alone is renamed PartyMember -> PartyBaseAI to avoid collision with the replacement global script. No navigation, follow/warp, stats, damage or healing logic is recreated from older source. prepare_base.py asserts the decompressed bytecode differs only in that identifier. The wrapper inherits this shipped base.

Tests: automatic skills for all six professions, no pre-impact damage, exactly-once hit, cooldown, range, knocked-out behavior and healer restoration; passed both desktop and emulated mobile. Character-card point spending, grouping, rotation/pause, hidden rendering and viewport bounds passed on both. Enlarged damage fonts and rise/fall/shrink lifetime regression passed. Native PC/mobile portrait and damage-render screenshots reviewed. No physical iPhone testing was available. Existing full-scene shutdown resource warnings remain; tests reported no script/runtime errors before their PASS markers.

The pack-diff guard permits only the party script/remap/base replacement, damage_popup.gd and ro_ui_base.gd. All maps, saved-data fields, combat tables, other scripts, and the previous skill-effect update are preserved.
