# Aldenvale rebuild + forge & item stall on every map — 2026-11-04

Styles inspired by the user's Pinterest references (medieval tavern, librarian hall, mossy stone
cottage). The game versions are new block builds made with the existing block set; no assets copied.

## Town (scripts/world/village_builder.gd, scripts/world/smithy.gd)
- Fountain: pool radius 3.6 → 2.2 blocks, rim 4.6 → 2.9; round model scaled to 0.62; spray, spouts and
  ripples scaled to match (`FOUNTAIN_POOL`, `FOUNTAIN_RIM`, `FOUNTAIN_SCALE`).
- Smithy (`smithy.gd` build): stone ground floor with log corners, dark-wood jetty, white plaster upper floor
  in a timber frame, steep grey stone roof with log ridge and dark verges, red brick chimney (smoke kept),
  barrels by the door. Same footprint x14–21 z0–8 and doorway, so the warp into the workshop is unchanged.
- Guild office (`_guild_office()` after `GuildHall.build_exterior`): clears the old shell (blocks, plants,
  20 cm detail) and builds red brick panels between log pillars, jetty, plank upper floor, slate-blue roof
  and a front belfry spire with gold finial. Same footprint and door cells (warp unchanged).
- Houses (`_house`): mossy cobble cottages, log corners, dark eave beam, stone-tile roof with moss patches,
  log ridge, chimney with red cap, wall lantern, crates/barrels, hedges behind, flowers at the door.
  Uses exactly the same two `_rng` draws per house as before, so forest and fishing pond placement are unchanged.

## Every field and dungeon map (11 maps)
`_outpost()` runs in `ensure_area()` and places, at the nearest free spot to the arrival point
(no water/magma/ice, walls, warps or blocked cells; dungeons search the whole map for a big enough room):
- a small forge hut (stone, slate roof, chimney, glowing coals, anvil) with **Wandering Smith Garrick**
  (role "smith": refine, craft weapons/hats/armour, wings, fashion, refine stones)
- an item stall with a red/white awning and **Peddler Lina** (role "shop": same stock as Merchant Toma, buy & sell)
Thai names added to `loc_th.gd`.



## Validation
- qa/outpost_test.gd: 11/11 maps have both NPCs, reachable by path from the arrival point.
- qa/outpost_npc_test.gd: Garrick opens the smith menu (fashion tab works), Lina opens the shop.
- Fishing pond still at (-80, 46); fashion test 139/139; account login/load pass; startup log unchanged.
- Town load time unchanged (old vs new measured interleaved on the same machine: ~6.0–6.2 s headless).
- previews/: rendered from the game (OpenGL).
