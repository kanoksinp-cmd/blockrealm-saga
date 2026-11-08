# Mobile Safari stability — 9 November 2026

User symptom: page unexpectedly reloads or returns to login in Safari. The physical device and Safari process logs are unavailable, so this is a fix for a reproduced memory-pressure condition, not proof of every possible reload cause.

## Reproduction

Using the deployed 5abb217ddec99b57 PCK, Godot 4.7.2 headless with mobile override, 844x390 and an isolated save: travel town -> verdant -> desert -> frost -> ember -> verdant. Performance.MEMORY_STATIC (MiB) after each transition:

| Map | Before | After |
| --- | ---: | ---: |
| Town | 289 | 289 |
| Verdant | 434 | 434 |
| Desert | 532 | 397 |
| Frost | 664 | 432 |
| Ember | 774 | 414 |
| Verdant revisited | 774 | 446 |

Previously all built region geometry, colliders, navigation grids and monsters stayed allocated. The fix keeps the base town and one region on mobile. Old region nodes are released and a frame is allowed to complete before the next region builds. Monster HP, stolen state, status timers, death state and respawn progress are kept in lightweight dictionaries. Ore charges and respawn time are retained, including time elapsed while the map is unloaded. Minimap entries for freed actors are removed safely. Respawn can rebuild an unloaded save-point map. Desktop retains its region cache.

Mobile canvas density is capped at 1x, 1024 long / 640 short, compared with 1.25x, 1280/800. At 844x390 CSS pixels, the framebuffer drops from 1055x488 to 844x390 (about 36% fewer pixels). CSS display dimensions and the existing logical UI/touch layout remain in use. Existing shadow, MSAA, particle and 30 FPS limits are retained. On detecting a transition to background, an active character saves once and the background cap drops to 5 FPS; foreground returns to 30. Abrupt OS termination before visibility processing can still prevent a last-second save.

## Validation

- Eight repeated field transitions: only one region/world/nav remains, memory stabilizes near 446 MiB on repeated warm route, bosses are unique and retain HP/stolen/death/respawn state, depleted veins do not refresh by re-entry, elapsed ore timers regrow normally.
- Death and respawn reload an unloaded save-point region; returning to town releases foreign worlds/navs.
- Repeated dungeon loading/unloading; no shops added to dungeons.
- Desktop still retains two visited region worlds.
- Background saves once per hide, restores foreground FPS, and does not save over characters on title/menu.
- Runtime script load of 89 scripts; regression checks for cross-map Gold Ore Find, AUTO gathering and combat, complete map bounds, mobile list scrolling, Sell All transactions, skill costs/death/respawn and 11 mobile windows at landscape/portrait sizes.
- JavaScript checks for iPhone/iPad/touch/desktop detection, portrait resize, pixel caps, and forced modes.

These memory figures are engine-side desktop simulations, not a measurement of iPhone total RAM, Safari GPU memory, or WebAssembly peak linear-memory size. Existing headless renderer/resource shutdown diagnostics are recorded separately from script/assertion failures. Physical Safari confirmation is still needed.
