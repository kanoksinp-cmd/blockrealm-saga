class_name Story
extends RefCounted
## Main story + tutorial quest line (Lv 1 -> 30). One step is active at a time.
##
## Step fields:
##   giver   NPC that offers the step ("!" over their head)
##   turnin  NPC you report to ("?" when ready)
##   goal    {type, ...}:
##           talk                         - just go and talk to `turnin`
##           kill     target, need        - defeat monsters (counted by G().on_kill)
##           collect  item, need          - bring items (taken on turn-in)
##           stats    left                - spend status points until <= left remain
##           skills   need                - learn this many skill levels in total
##           gear     need                - wear this many equipment slots
##           refine   need                - refine any worn item to +need
##           level    need                - reach base level
##           job      need                - reach job tier (2 = 2nd job, 3 = transcendent)
##           guild                        - register at the Adventurers' Guild
##           board    need                - finish special quest board bounties
##           rank     need                - reach guild rank (0 = F ... 6 = S)
##   tip     tutorial hint shown in the quest window
##   reward  {exp, zeny, items: {id: n}, skill_points}

const STEPS := [
	# ---------------------------------------------------------------- Chapter 1: A Stranger in Aldenvale
	{"id": "s01", "chapter": 1, "title": "First Steps", "giver": "Guide Lumi", "turnin": "Old Sage Bren",
		"goal": {"type": "talk"},
		"offer": "Welcome to Aldenvale! Strange shadows have been creeping out of the wilds lately and the town needs new heroes.\nGo and meet [b]Old Sage Bren[/b] by the castle gate - he will teach you the basics.",
		"tip": "Click the ground to walk. Click this quest in the tracker (right side) and you will walk there automatically.",
		"done": "Ah, Lumi sent you? Good, good. Sit, young one - an adventurer must first know themselves.",
		"reward": {"exp": 80, "items": {"potion_red": 3}}},
	{"id": "s02", "chapter": 1, "title": "Know Yourself", "giver": "Old Sage Bren", "turnin": "Old Sage Bren",
		"goal": {"type": "stats", "left": 2},
		"offer": "Every hero grows in their own way. Open your [b]Status[/b] window and spend your status points.",
		"tip": "Press S (or the helmet button) and click + next to a stat. STR = attack, AGI = speed, VIT = HP, INT = magic, DEX = hit, LUK = critical.",
		"done": "A fine balance. Remember: every level brings new points to spend.",
		"reward": {"exp": 120}},
	{"id": "s03", "chapter": 1, "title": "Words of Power", "giver": "Old Sage Bren", "turnin": "Old Sage Bren",
		"goal": {"type": "skills", "need": 2},
		"offer": "Strength alone is not enough. Learn [b]2 skill levels[/b] from your Skill window.",
		"tip": "Press K, click + on a skill. Active skills go to the hotbar - press F1..F8 to use them.",
		"done": "I can feel the power stirring in you. Now go to Captain Aldric at the south gate - he needs fighters.",
		"reward": {"exp": 150, "skill_points": 1}},
	{"id": "s04", "chapter": 1, "title": "Slime Patrol", "giver": "Captain Aldric", "turnin": "Captain Aldric",
		"goal": {"type": "kill", "target": "Slime", "need": 8},
		"offer": "Slimes are eating the crops south of the gate - and they keep multiplying. Something is stirring them up.\nDefeat [b]8 Slimes[/b].",
		"tip": "Click a monster to attack. Press Z (AUTO) to let your hero hunt by itself. Click dropped loot to pick it up.",
		"done": "Well fought! Odd... these slimes looked darker than usual. Merchant Toma wanted a word with you.",
		"reward": {"exp": 450, "zeny": 300, "items": {"potion_red": 5}}},
	{"id": "s05", "chapter": 1, "title": "A Sticky Business", "giver": "Merchant Toma", "turnin": "Merchant Toma",
		"goal": {"type": "collect", "item": "slime_gel", "need": 5},
		"offer": "You've been fighting slimes? Their gel makes excellent glue! Bring me [b]5 Slime Gel[/b] and I'll pay handsomely.",
		"tip": "Loot is sold to merchants for Zeny. Talk to Toma and choose Sell to turn junk into money.",
		"done": "Perfect quality! Here's your pay. Spend it on potions - you'll need them.",
		"reward": {"exp": 400, "zeny": 500}},
	{"id": "s06", "chapter": 1, "title": "Feathers for Fletching", "giver": "Merchant Toma", "turnin": "Merchant Toma",
		"goal": {"type": "collect", "item": "feather", "need": 6},
		"offer": "The fletchers need feathers. Ducklings and Fancy Chicks live west and east of the south fields. Bring [b]6 Feathers[/b].",
		"tip": "Open the World Map (M) and click a hunting ground to travel there.",
		"done": "Lovely! Take this cap - a hero should look the part. Oh, and Lumi was looking for you.",
		"reward": {"exp": 700, "items": {"leather_cap": 1}}},
	{"id": "s06g", "chapter": 1, "title": "The Adventurers' Guild", "giver": "Guide Lumi", "turnin": "Guild Clerk Mira",
		"goal": {"type": "guild"},
		"offer": "Every real adventurer is registered at the [b]Adventurers' Guild[/b] - the big timbered hall north-west of the plaza.\nWalk through its door, talk to [b]Clerk Mira[/b] at the counter and register.",
		"tip": "Walk onto the glowing circle at a door to go inside. The Guild Master upstairs gives advice on anything.",
		"done": "Welcome to the Guild! Your rank starts at F. Bounties on the Special Quest Board earn Guild Points to climb the ranks.",
		"reward": {"exp": 300, "zeny": 300}},
	{"id": "s06h", "chapter": 1, "title": "Your First Bounty", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira",
		"goal": {"type": "board", "need": 1},
		"offer": "Take a bounty from the [b]Special Quest Board[/b] by the west wall, finish it and claim your reward.",
		"tip": "The board offers 3 jobs suited to your level. Each one gives Guild Points (GP), EXP and Zeny.",
		"done": "Well done! Keep taking bounties - with enough GP I can raise your rank right here at the counter.",
		"reward": {"exp": 500, "items": {"potion_red": 5}}},
	# ---------------------------------------------------------------- Chapter 2: Steel and Fire
	{"id": "s07", "chapter": 2, "title": "Dress for Battle", "giver": "Blacksmith Doran", "turnin": "Blacksmith Doran",
		"goal": {"type": "gear", "need": 4},
		"offer": "Clang! You fight half-naked! Wear gear in at least [b]4 equipment slots[/b]. Your new cap counts.",
		"tip": "Press I to open Inventory / Equipment. Double-click gear to wear it. Each slot changes how your hero looks.",
		"done": "Much better. Now let me show you the true craft of the forge.",
		"reward": {"exp": 600, "items": {"weapon_stone": 2, "armor_stone": 2}}},
	{"id": "s08", "chapter": 2, "title": "The First Refine", "giver": "Blacksmith Doran", "turnin": "Blacksmith Doran",
		"goal": {"type": "refine", "need": 2},
		"offer": "Refining makes gear stronger - and it glows brighter with every level! Refine any worn item to [b]+2[/b] with the stones I gave you.",
		"tip": "Talk to Doran and choose Refine. Failure keeps the current level.",
		"done": "See that shine? That's the soul of the steel waking up. Go show the Captain.",
		"reward": {"exp": 800, "items": {"weapon_stone": 2}}},
	{"id": "s09", "chapter": 2, "title": "Piglet Panic", "giver": "Captain Aldric", "turnin": "Captain Aldric",
		"goal": {"type": "kill", "target": "Spotted Piglet", "need": 10},
		"offer": "The piglets east of town have gone wild and trample the fences. Calm [b]10 Spotted Piglets[/b].",
		"tip": "Monster names are coloured by difficulty: grey/green easy, black even, orange/red/purple dangerous.",
		"done": "Good. But the reports from the west worry me more...",
		"reward": {"exp": 1200, "zeny": 400}},
	{"id": "s10", "chapter": 2, "title": "The Blue Menace", "giver": "Captain Aldric", "turnin": "Captain Aldric",
		"goal": {"type": "kill", "target": "Blue Slime", "need": 10},
		"offer": "Blue Slimes have appeared to the north-west - slimes that attack on sight! Defeat [b]10 Blue Slimes[/b].",
		"tip": "Open Auto Settings (gear next to AUTO) to make auto-hunt drink potions and use skills.",
		"done": "Aggressive slimes... this is no natural plague. Someone - or something - is behind it.",
		"reward": {"exp": 1800, "zeny": 800, "items": {"potion_blue": 3}}},
	{"id": "s11", "chapter": 2, "title": "Ferret Thieves", "giver": "Merchant Toma", "turnin": "Merchant Toma",
		"goal": {"type": "collect", "item": "ferret_pelt", "need": 5},
		"offer": "Cinnamon Ferrets stole my delivery north of town! Bring back [b]5 Ferret Pelts[/b] as compensation.",
		"tip": "Thieves can use Steal to grab extra items. Everyone else: just keep hunting!",
		"done": "Ha! That'll teach them. This cape was in the stolen crate - keep it.",
		"reward": {"exp": 2200, "items": {"travel_cape": 1}}},
	{"id": "s12", "chapter": 2, "title": "Boar Hunt", "giver": "Captain Aldric", "turnin": "Captain Aldric",
		"goal": {"type": "kill", "target": "Wild Boar", "need": 8},
		"offer": "Wild Boars block the west road. Watch out - they paw the ground before they charge!\nDefeat [b]8 Wild Boars[/b].",
		"tip": "Step aside when a boar paws the ground. Ranged jobs can kite them.",
		"done": "The road is open again. You've grown strong - the Guild should hear of this.",
		"reward": {"exp": 3500, "zeny": 1200}},
	# ---------------------------------------------------------------- Chapter 3: A New Calling
	{"id": "s13", "chapter": 3, "title": "Worthy of the Guild", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira",
		"goal": {"type": "rank", "need": 2},
		"offer": "The Guild only grants advanced jobs to proven adventurers. Reach [b]Guild Rank D[/b] - bounties give GP, then ask me to update your rank.",
		"tip": "Rank D needs 60 GP and Base Lv 10. Good hunting grounds: Sooty Piglets (Lv5), Wild Boars (Lv6), Shroom Hens (Lv7).",
		"done": "Rank D! The Guild recognises your strength.",
		"reward": {"exp": 1500, "items": {"potion_red": 10}}},
	{"id": "s14", "chapter": 3, "title": "A New Calling", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira",
		"goal": {"type": "job", "need": 2},
		"offer": "Open your Skill window and take the [b]Job Change[/b] to your 2nd job. You need 10 skill levels learned.",
		"tip": "Press K, open the 2nd Job tab and press Change Job. Your banner on the profile will change too!",
		"done": "Congratulations! Wear your new title with pride.",
		"reward": {"exp": 3000, "zeny": 2000, "skill_points": 2}},
	{"id": "s15", "chapter": 3, "title": "Horns of the Dark Goat", "giver": "Blacksmith Doran", "turnin": "Blacksmith Doran",
		"goal": {"type": "collect", "item": "goat_horn", "need": 6},
		"offer": "Dark Goats east of town carry horns hard as iron. Bring [b]6 Goat Horns[/b] and I'll forge you something special.",
		"tip": "Craft new gear at Doran from monster materials (Craft tab).",
		"done": "Fine horns! Here - a helm worthy of a veteran.",
		"reward": {"exp": 5000, "items": {"iron_helm": 1, "armor_stone": 3}}},
	{"id": "s16", "chapter": 3, "title": "The Frozen Trail", "giver": "Captain Aldric", "turnin": "Captain Aldric",
		"goal": {"type": "kill", "target": "Emperor Penguin", "need": 10},
		"offer": "Scouts followed the dark trail far north, to the ice fields. Emperor Penguins guard it. Defeat [b]10[/b] of them.",
		"tip": "Higher-level zones are farther from town. Check monster levels on the World Map.",
		"done": "The scouts found black crystals in the ice... the Sage must see this.",
		"reward": {"exp": 8000, "zeny": 2500}},
	# ---------------------------------------------------------------- Chapter 4: The Shadow Blight
	{"id": "s17", "chapter": 4, "title": "Wisps in the Night", "giver": "Old Sage Bren", "turnin": "Old Sage Bren",
		"goal": {"type": "kill", "target": "Pale Wisp", "need": 10},
		"offer": "These crystals are full of shadow. The Pale Wisps to the north-west feed on it. Banish [b]10 Pale Wisps[/b].",
		"tip": "Wisps hit hard - learn your 2nd job skills and keep potions on the hotbar.",
		"done": "Their light fades... but the darkness comes from deeper still.",
		"reward": {"exp": 11000, "items": {"potion_blue": 10}}},
	{"id": "s18", "chapter": 4, "title": "Shards of Shadow", "giver": "Old Sage Bren", "turnin": "Old Sage Bren",
		"goal": {"type": "collect", "item": "shadow_shard", "need": 5},
		"offer": "The Shade Imps in the south-west carry shards of pure shadow. Bring me [b]5 Shadow Shards[/b] to study.",
		"tip": "Refine your weapon higher for more damage - the glow shows how strong it is.",
		"done": "As I feared... these shards were cut from the crown of a slime king. Take this mantle; it hides you from shadow.",
		"reward": {"exp": 14000, "items": {"shadow_mantle": 1}}},
	{"id": "s19", "chapter": 4, "title": "The Crystal Heart", "giver": "Blacksmith Doran", "turnin": "Blacksmith Doran",
		"goal": {"type": "collect", "item": "golem_crystal", "need": 3},
		"offer": "To face a king you'll need my best work. Crystal Golems to the south-east hold living crystal. Bring [b]3 Golem Crystals[/b].",
		"tip": "Golems are slow but very tough. Use your strongest skills and area attacks.",
		"done": "With these I can temper anything. Take these stones - push your gear as far as it will go!",
		"reward": {"exp": 18000, "items": {"weapon_stone": 4, "armor_stone": 4}}},
	{"id": "s20", "chapter": 4, "title": "Crown of the Slime King", "giver": "Captain Aldric", "turnin": "Captain Aldric",
		"goal": {"type": "kill", "target": "King Slime", "need": 1},
		"offer": "It's the [b]King Slime[/b], far to the west, wearing a crown of shadow. It's the source of the blight.\nEnd it.",
		"tip": "The boss is Lv 20 and hits very hard. Turn off 'skip boss' in Auto Settings or attack it yourself.",
		"done": "The King has fallen! Aldenvale is saved! ...But the Guild says your journey is not over.",
		"reward": {"exp": 25000, "zeny": 5000}},
	# ---------------------------------------------------------------- Chapter 5: Transcendence
	{"id": "s21", "chapter": 5, "title": "Path of the Hero", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira",
		"goal": {"type": "level", "need": 24},
		"offer": "Heroes who reach [b]Base Level 24[/b] may attempt transcendence - the highest calling.",
		"tip": "Best EXP: Shade Imps (Lv16) and Crystal Golems (Lv18). The King Slime returns after a while too.",
		"done": "Level 24. You are ready for the final trial.",
		"reward": {"exp": 10000}},
	{"id": "s22", "chapter": 5, "title": "Beyond the Limit", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira",
		"goal": {"type": "job", "need": 3},
		"offer": "Transcend! Change to your [b]Transcendent job[/b] in the Skill window (needs 25 skill levels learned).",
		"tip": "Third-job skill points grow with your level, up to level 99.",
		"done": "Incredible... a transcendent hero in Aldenvale!",
		"reward": {"exp": 20000, "zeny": 5000, "skill_points": 3}},
	{"id": "s23", "chapter": 5, "title": "Golem Breaker", "giver": "Captain Aldric", "turnin": "Captain Aldric",
		"goal": {"type": "kill", "target": "Crystal Golem", "need": 15},
		"offer": "Without the King, the golems wander toward the town. Break [b]15 Crystal Golems[/b].",
		"tip": "Refine to +7 and beyond for a dazzling glow - and much more power.",
		"done": "The walls are safe. There's only one thing left for you to prove.",
		"reward": {"exp": 30000, "zeny": 8000}},
	{"id": "s24", "chapter": 5, "title": "Hero of Aldenvale", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira",
		"goal": {"type": "level", "need": 30},
		"offer": "Reach [b]Base Level 30[/b] and the Guild will name you the Hero of Aldenvale.",
		"tip": "Keep hunting, refining and learning skills. You've got this!",
		"done": "By the authority of the Guild, I name you [b]Hero of Aldenvale[/b]! Thank you, for everything.",
		"reward": {"exp": 0, "zeny": 20000, "items": {"ruby_amulet": 1, "weapon_stone": 5, "armor_stone": 5}}},
	{"id": "c32a", "chapter": 6, "title": "เตรียมพร้อมสู่เลเวล 32", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "level", "need": 32}, "offer": "ภัยจาก Wolf กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 32 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 5645, "zeny": 3840, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c32b", "chapter": 6, "title": "หยุดยั้ง Wolf", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "kill", "target": "Wolf", "need": 10}, "offer": "ภัยจาก Wolf กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 32 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 14113, "zeny": 3840, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c36a", "chapter": 6, "title": "เตรียมพร้อมสู่เลเวล 36", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "level", "need": 36}, "offer": "ภัยจาก Orc Warrior กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 36 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 7141, "zeny": 4320, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c36b", "chapter": 6, "title": "หยุดยั้ง Orc Warrior", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "kill", "target": "Orc Warrior", "need": 11}, "offer": "ภัยจาก Orc Warrior กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 36 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 17853, "zeny": 4320, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c42a", "chapter": 7, "title": "เตรียมพร้อมสู่เลเวล 42", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "level", "need": 42}, "offer": "ภัยจาก Mummy กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 42 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 9715, "zeny": 5040, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c42b", "chapter": 7, "title": "หยุดยั้ง Mummy", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "kill", "target": "Mummy", "need": 12}, "offer": "ภัยจาก Mummy กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 42 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 24288, "zeny": 5040, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c45a", "chapter": 7, "title": "เตรียมพร้อมสู่เลเวล 45", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "level", "need": 45}, "offer": "ภัยจาก Marin กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 45 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 11150, "zeny": 5400, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c45b", "chapter": 7, "title": "หยุดยั้ง Marin", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "kill", "target": "Marin", "need": 13}, "offer": "ภัยจาก Marin กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 45 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 27876, "zeny": 5400, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "job4", "chapter": 7, "title": "วิถีอาชีพขั้น 4", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira", "goal": {"type": "job", "need": 4}, "offer": "ฝึกฝน Base Lv และ Job Lv ให้พร้อม แล้วเลือกอาชีพขั้น 4 ในหน้าสกิล", "tip": "เปิด K เลือกแท็บอาชีพถัดไป เงื่อนไขเปลี่ยนอาชีพแสดงบนการ์ด", "done": "เจ้าได้ก้าวข้ามขีดจำกัดของตนแล้ว", "reward": {"exp": 45000, "zeny": 4500}},
	{"id": "c49a", "chapter": 8, "title": "เตรียมพร้อมสู่เลเวล 49", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "level", "need": 49}, "offer": "ภัยจาก Sohee กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 49 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 13218, "zeny": 5880, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c49b", "chapter": 8, "title": "หยุดยั้ง Sohee", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "kill", "target": "Sohee", "need": 14}, "offer": "ภัยจาก Sohee กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 49 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 33046, "zeny": 5880, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c54a", "chapter": 8, "title": "เตรียมพร้อมสู่เลเวล 54", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "level", "need": 54}, "offer": "ภัยจาก Minorous กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 54 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 16051, "zeny": 6480, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c54b", "chapter": 8, "title": "หยุดยั้ง Minorous", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "kill", "target": "Minorous", "need": 15}, "offer": "ภัยจาก Minorous กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 54 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 40128, "zeny": 6480, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c58a", "chapter": 9, "title": "เตรียมพร้อมสู่เลเวล 58", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "level", "need": 58}, "offer": "ภัยจาก Nightmare กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 58 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 18515, "zeny": 6960, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c58b", "chapter": 9, "title": "หยุดยั้ง Nightmare", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "kill", "target": "Nightmare", "need": 16}, "offer": "ภัยจาก Nightmare กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 58 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 46288, "zeny": 6960, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c62a", "chapter": 9, "title": "เตรียมพร้อมสู่เลเวล 62", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "level", "need": 62}, "offer": "ภัยจาก Raydric กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 62 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 21155, "zeny": 7440, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c62b", "chapter": 9, "title": "หยุดยั้ง Raydric", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "kill", "target": "Raydric", "need": 17}, "offer": "ภัยจาก Raydric กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 62 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 52888, "zeny": 7440, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c65a", "chapter": 10, "title": "เตรียมพร้อมสู่เลเวล 65", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "level", "need": 65}, "offer": "ภัยจาก Wraith กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 65 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 23250, "zeny": 7800, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c65b", "chapter": 10, "title": "หยุดยั้ง Wraith", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "kill", "target": "Wraith", "need": 18}, "offer": "ภัยจาก Wraith กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 65 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 58126, "zeny": 7800, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "job5", "chapter": 10, "title": "วิถีอาชีพขั้น 5", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira", "goal": {"type": "job", "need": 5}, "offer": "ฝึกฝน Base Lv และ Job Lv ให้พร้อม แล้วเลือกอาชีพขั้น 5 ในหน้าสกิล", "tip": "เปิด K เลือกแท็บอาชีพถัดไป เงื่อนไขเปลี่ยนอาชีพแสดงบนการ์ด", "done": "เจ้าได้ก้าวข้ามขีดจำกัดของตนแล้ว", "reward": {"exp": 65000, "zeny": 6500}},
	{"id": "c69a", "chapter": 10, "title": "เตรียมพร้อมสู่เลเวล 69", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "level", "need": 69}, "offer": "ภัยจาก Evil Druid กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 69 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 26198, "zeny": 8280, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c69b", "chapter": 10, "title": "หยุดยั้ง Evil Druid", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "kill", "target": "Evil Druid", "need": 19}, "offer": "ภัยจาก Evil Druid กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 69 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 65496, "zeny": 8280, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c75a", "chapter": 11, "title": "เตรียมพร้อมสู่เลเวล 75", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "level", "need": 75}, "offer": "ภัยจาก Baphomet Jr. กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 75 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 30950, "zeny": 9000, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c75b", "chapter": 11, "title": "หยุดยั้ง Baphomet Jr.", "giver": "Captain Aldric", "turnin": "Captain Aldric", "goal": {"type": "kill", "target": "Baphomet Jr.", "need": 20}, "offer": "ภัยจาก Baphomet Jr. กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 75 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 77376, "zeny": 9000, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c79a", "chapter": 11, "title": "เตรียมพร้อมสู่เลเวล 79", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "level", "need": 79}, "offer": "ภัยจาก Deviruchi กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 79 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 34338, "zeny": 9480, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c79b", "chapter": 11, "title": "หยุดยั้ง Deviruchi", "giver": "Old Sage Bren", "turnin": "Old Sage Bren", "goal": {"type": "kill", "target": "Deviruchi", "need": 21}, "offer": "ภัยจาก Deviruchi กำลังคุกคามเส้นทาง ขอให้เจ้าช่วยปกป้องชาวเมือง", "tip": "เลือกพื้นที่ใกล้เลเวล 79 จากแผนที่ ล่ามอนสเตอร์ระดับใกล้กันเพื่อรับ EXP เต็ม", "done": "เส้นทางปลอดภัยแล้ว แต่เรายังต้องเฝ้าระวังภัยจากห้วงลึก", "reward": {"exp": 85846, "zeny": 9480, "items": {"potion_red": 5, "potion_blue": 3}}},
	{"id": "c80final", "chapter": 11, "title": "ผู้พิทักษ์ห้วงลึก เลเวล 80", "giver": "Guild Clerk Mira", "turnin": "Guild Clerk Mira", "goal": {"type": "level", "need": 80}, "offer": "จงบรรลุเลเวล 80 และกลับมารับตราผู้พิทักษ์จากกิลด์", "tip": "เควสเสริมจากชาวเมืองและใบงานกิลด์ช่วยสะสม EXP เพิ่มเติม", "done": "ในนามกิลด์ เราขอมอบเกียรติแก่ผู้พิทักษ์แห่งห้วงลึก!", "reward": {"exp": 0, "zeny": 80000, "items": {"weapon_stone": 10, "armor_stone": 10}}},

]

## The Game autoload (looked up at runtime to avoid a script dependency cycle).
static func G() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Game")


const CHAPTERS := ["", "A Stranger in Aldenvale", "Steel and Fire", "A New Calling", "The Shadow Blight", "Transcendence", "พรมแดนเงา", "สุสานทะเลทราย", "สงครามน้ำแข็ง", "เพลิงภูเขาไฟ", "อัศวินแห่งรัตติกาล", "ประตูห้วงลึก"]


static func step(i: int) -> Dictionary:
	return STEPS[i] if i >= 0 and i < STEPS.size() else {}


static func current() -> Dictionary:
	return step(G().story_step)


## "offer" (waiting at the giver), "active", "done" (report to turn-in NPC) or "finished".
static func state() -> String:
	if G().story_step >= STEPS.size():
		return "finished"
	var q: Dictionary = G().quests.get("story", {})
	if q.is_empty() or q.get("sid", "") != current().id:
		return "offer"
	return q.state


static func progress() -> Array:
	var s := current()
	if s.is_empty():
		return [0, 0]
	var g: Dictionary = s.goal
	var q: Dictionary = G().quests.get("story", {})
	match String(g.type):
		"kill":
			return [mini(int(q.get("count", 0)), int(g.need)), int(g.need)]
		"collect":
			return [mini(G().count(g.item), int(g.need)), int(g.need)]
		"stats":
			return [1 if G().stat_points <= int(g.left) else 0, 1]
		"skills":
			return [mini(G().skills_learned(), int(g.need)), int(g.need)]
		"gear":
			var n := 0
			for k in G().equip:
				if G().equip[k] != "":
					n += 1
			return [mini(n, int(g.need)), int(g.need)]
		"refine":
			var best := 0
			for k in G().equip:
				if G().equip[k] != "":
					best = maxi(best, G().refine_lv(G().equip[k]))
			return [mini(best, int(g.need)), int(g.need)]
		"level":
			return [mini(G().base_level, int(g.need)), int(g.need)]
		"job":
			return [mini(G().job_tier, int(g.need)), int(g.need)]
		"guild":
			return [1 if G().guild_member else 0, 1]
		"board":
			return [mini(int(G().board_done), int(g.need)), int(g.need)]
		"rank":
			return [mini(int(G().guild_rank), int(g.need)), int(g.need)]
	return [0, 1]


static func goal_text(s: Dictionary) -> String:
	var g: Dictionary = s.goal
	var t := func(x: String) -> String: return TranslationServer.translate(x)
	match String(g.type):
		"talk":
			return t.call("Talk to %s.") % t.call(s.turnin)
		"kill":
			return t.call("Defeat %d %s.") % [int(g.need), t.call(g.target)]
		"collect":
			return t.call("Bring %d %s to %s.") % [int(g.need), Items.item_name(g.item), t.call(s.turnin)]
		"stats":
			return t.call("Spend your status points (S).")
		"skills":
			return t.call("Learn %d skill levels (K).") % int(g.need)
		"gear":
			return t.call("Wear gear in %d equipment slots (I).") % int(g.need)
		"refine":
			return t.call("Refine any worn item to +%d at the Blacksmith.") % int(g.need)
		"level":
			return t.call("Reach Base Level %d.") % int(g.need)
		"job":
			if G().job_tier < 1 and int(g.need) >= 1:
				return t.call("Reach Job Lv 10 and choose your first job (K).")
			return t.call("Change job to %s (K).") % t.call(G().tier_title(int(g.need)))
		"guild":
			return t.call("Register at the Adventurers' Guild.")
		"board":
			return t.call("Finish %d bounty from the Special Quest Board.") % int(g.need)
		"rank":
			return t.call("Reach Guild Rank %s.") % Guild.RANKS[int(g.need)]
	return ""


## Start the current step (called from the giver's dialog).
static func accept() -> void:
	var s := current()
	if s.is_empty():
		return
	var g: Dictionary = s.goal
	G().quests["story"] = {"sid": s.id, "state": "active", "title": s.title, "need": int(g.get("need", 1)), "count": 0,
		"target": String(g.get("target", "")), "giver": s.turnin}
	G().log_msg(TranslationServer.translate("[Quest] Accepted: %s") % TranslationServer.translate(s.title), Color(1.0, 0.85, 0.3))
	check()
	G().quest_changed.emit()


## Re-evaluate condition goals (stats, level, gear ...). Kill goals are counted by G().on_kill.
static func check() -> void:
	var q: Dictionary = G().quests.get("story", {})
	var s := current()
	if q.is_empty() or s.is_empty() or q.get("sid") != s.id:
		return
	var t: String = s.goal.type
	if t == "talk" or t == "kill":
		return
	var pr := progress()
	if q.get("state") == "done":
		if t == "collect" and pr[0] < pr[1]:
			q.state = "active"
			G().quest_changed.emit()
		return
	if pr[0] >= pr[1]:
		q.state = "done"
		G().log_msg(TranslationServer.translate("[Quest] %s complete! Report back to %s.") % [TranslationServer.translate(s.title),
			TranslationServer.translate(s.turnin)], Color(1.0, 0.85, 0.3))
		G().quest_changed.emit()


## Hand in the current step and advance the story.
static func complete() -> void:
	check()
	if state() != "done" and not (state() == "active" and current().goal.type == "talk"):return
	var s := current()
	if s.is_empty():
		return
	var g: Dictionary = s.goal
	if g.type == "collect":
		G().remove_item(g.item, int(g.need))
	var r: Dictionary = s.reward
	G().quests.erase("story")
	G().story_step += 1
	Audio.play("quest_done", null, 0.0, 0.0)
	if r.has("zeny"):
		G().add_zeny(int(r.zeny))
	for id in r.get("items", {}):
		G().add_item(id, int(r.items[id]))
	if r.has("skill_points"):
		G().sync_skill_budget()
		G().skills_changed.emit()
	if int(r.get("exp", 0)) > 0:
		var p := (Engine.get_main_loop() as SceneTree).get_first_node_in_group("player")
		if p and p.has_method("gain_exp"):
			p.gain_exp(int(r.exp))
		else:
			G().add_exp(int(r.exp))
	G().log_msg(TranslationServer.translate("[Quest] Completed: %s") % TranslationServer.translate(s.title), Color(1.0, 0.85, 0.3))
	G().save_game()
	G().quest_changed.emit()
	G().changed.emit()


static func reward_text(s: Dictionary) -> String:
	var r: Dictionary = s.reward
	var parts: PackedStringArray = []
	if int(r.get("exp", 0)) > 0:
		parts.append("%d EXP" % int(r.exp))
	if r.has("zeny"):
		parts.append("%d Zeny" % int(r.zeny))
	for id in r.get("items", {}):
		parts.append("%s x%d" % [Items.item_name(id), int(r.items[id])])
	if r.has("skill_points"):
		parts.append(TranslationServer.translate("Skill points +%d") % int(r.skill_points))
	return ", ".join(parts)


## Marker over an NPC: "!" offer, "?" ready to hand in, "" nothing.
static func marker_for(npc_name: String) -> String:
	var s := current()
	if s.is_empty():
		return ""
	var st := state()
	if st == "offer" and s.giver == npc_name:
		return "!"
	if s.turnin == npc_name and (st == "done" or (st == "active" and s.goal.type == "talk")):
		return "?"
	return ""


## Story dialog when talking to an NPC. Returns true if the story took over the conversation.
static func interact(npc: Node, ui, fallback := Callable()) -> bool:
	var s := current()
	if s.is_empty():
		return false
	var nm: String = npc.npc_name
	var st := state()
	var tr_ := func(x: String) -> String: return TranslationServer.translate(x)
	if st == "offer" and s.giver == nm:
		var head := "[color=#f2c773]%s %d - %s[/color]\n" % [tr_.call("Chapter"), int(s.chapter), tr_.call(CHAPTERS[int(s.chapter)])]
		ui.dialog(nm, head + tr_.call(s.offer) + "\n[color=#9fd0ff]%s[/color] %s" % [tr_.call("Reward:"), reward_text(s)],
			["Accept", "Later"], func(i: int) -> void:
				if i == 0:
					Story.accept()
					if s.goal.type == "talk" and s.turnin == nm:
						Story.interact(npc, ui, fallback)
					else:
						ui.dialog(nm, "[color=#f2c773]%s[/color]\n%s\n[color=#9fd0ff]%s[/color] %s" % [tr_.call(s.title), Story.goal_text(s),
							tr_.call("Tip:"), tr_.call(s.tip)], ["Close"], Callable())
				elif fallback.is_valid():
					fallback.call())
		return true
	if s.turnin == nm and st == "active" and s.goal.type == "collect":
		check()
		st = state()
	if s.turnin == nm and (st == "done" or (st == "active" and s.goal.type == "talk")):
		ui.dialog(nm, tr_.call(s.done) + "\n[color=#9fd0ff]%s[/color] %s" % [tr_.call("Reward:"), reward_text(s)],
			["Complete"], func(_i: int) -> void:
				Story.complete()
				var nx := Story.current()
				if not nx.is_empty() and nx.giver == nm:
					Story.interact(npc, ui, fallback))
		return true
	return false
