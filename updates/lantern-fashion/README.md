# Hanging lanterns and new fashion promotion — 2026-11-03

Replaces every eligible old street post with the new dark timber / iron hanging amber lantern, inspired by https://www.pinterest.com/pin/589549407514421781/.

All 18 original candidate sites are retained. The actual town places 17 posts; the site occupied by a building remains skipped, matching previous behavior. Bases have physical collision and are blocked for NPC navigation. Rotated light markers align with each lantern cage. Existing day/night pooled lighting is preserved. Interior wall torches remain.

The homepage promotes the existing craftable Forest Mage cosmetic and 21 hats. It shows the real recipe, Mage restriction and character-specific unlock, supports reduced motion, and includes a play button. Existing event data is unchanged.

## Source and Blender
Copy source/ into the complete Godot project. The game also requires the existing TownAssets helper from the prior town equipment update. Hanging_Lantern_Post.blend is the editable native Blender 5.2 source. build_lantern.py regenerates the model in a sibling career_expansion project.

## Validation
183 lantern checks and 313 town equipment regression checks passed. The exported game pack starts without engine errors. Homepage images load, desktop and 390px mobile have no horizontal overflow, and the promo button opens the updated game URL. See the included logs and website_promo.jpg.

play/index.html and play/index.pck contain the updated game. Publishing still requires pushing the local Git commit to GitHub.
