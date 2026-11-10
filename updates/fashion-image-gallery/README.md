Fashion artwork gallery

Both inventory fashion selection and the blacksmith fashion crafting tab now show cards with the existing website artwork. Twelve Relic Vanguard cards are cropped from assets/news/relic-vanguard.webp; the other five use the existing Eternal Armor, Hallow Spectres and Forest Mage website artwork. Static thumbnail images are bounded to 256 pixels and cached; no additional animated 3D preview viewports are created.

Selecting a card opens its image, stats, original material quantities and original Zeny cost. Owned and worn states update without rebuilding the grid. Crafting uses Game.craft and requires a nearby captured blacksmith NPC, class eligibility, an unowned outfit and the existing can_craft checks. Inventory browsing routes to the blacksmith instead of enabling remote crafting. Material finding closes modal windows before starting the existing gather/travel path.

A related PC shop vendor lookup was corrected: Game.near_npc is not an NPC object in this game. Both paths now resolve the actual nearby named NPC from its existing group. Mobile blacksmith tabs wrap to keep the two-column image grid within the screen. Prices, recipes, models, stats, ownership saves and all game data remain unchanged.

Runtime checks and native captures are documented in validation.json and previews-pc/ and previews-mobile/.
