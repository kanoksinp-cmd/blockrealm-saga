# Dungeon shop removal

Dungeon maps no longer generate roadside smithies, item stalls, vendor NPCs or their service lights. The same field-only gate also rejects direct placement checks for dungeons. Dungeon monsters, routes, quests and loot remain unchanged.

Outdoor field shops remain available. Placement now excludes the entire monster spawn radius plus its leash radius and a small body/jitter allowance, including alternate spawn spots, canopy edges and NPC approach positions. Existing arrival-point ordering and terrain/navigation checks remain in effect.

Validation: all 7 dungeon maps preserve their original blocks, lights and NPC definitions when the outpost generator is called. All 4 outdoor regions retain both services, with both NPC positions outside every matching monster spawn/leash radius. All 11 map checks pass. The pack overlays only village_builder.gd and retains all other entries.
