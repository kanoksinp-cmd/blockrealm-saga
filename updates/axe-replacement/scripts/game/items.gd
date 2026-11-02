class_name Items
extends RefCounted
## Item database + procedurally painted 16x16 pixel icons.
## type: use / etc / weapon / armor.  Sell price = price / 2.

const DB := {
	"forest_mage_fashion": {"name":"Forest Mage • ชุดแฟชั่นพงไพร", "type":"etc", "price":0, "weight":0, "icon":["gem",Color(.3,.6,.2)], "desc":"คราฟเพื่อปลดล็อกแฟชั่นนักเวทถาวรสำหรับตัวละครนี้ พร้อมคทาและภูตบินสองตัว ไม่เพิ่มค่าสถานะ"},
	"warp_short": {"name": "Short Warp Scroll", "type": "use", "price": 150, "weight": 1, "warp": "short",
		"desc": "Blink up to 12 m forward to a safe spot. Stops before walls. Not consumed if blocked."},
	"warp_long": {"name": "Long Warp Scroll", "type": "use", "price": 1200, "weight": 1, "warp": "long",
		"desc": "Choose a previously visited region or town. Consumed only after choosing a destination; no Zeny fee."},
	"guarantee_stone": {"name": "Guaranteed Refine Stone", "type": "etc", "price": 12000, "weight": 2,
		"desc": "Select at the blacksmith for 100% refine success. Uses one stone in addition to normal materials and Zeny."},
	"potion_red": {"name": "Healing Potion", "type": "use", "price": 50, "weight": 7, "heal_hp": 70,
		"desc": "A red herbal potion.\nRestores about 70 HP."},
	"potion_blue": {"name": "Mana Potion", "type": "use", "price": 120, "weight": 7, "heal_sp": 40,
		"desc": "A blue crystal tonic.\nRestores 40 SP."},
	"slime_gel": {"name": "Slime Gel", "type": "etc", "price": 16, "weight": 1,
		"desc": "Sticky green jelly dropped by Slimes."},
	"blue_gel": {"name": "Blue Gel", "type": "etc", "price": 32, "weight": 1,
		"desc": "Cool blue jelly from a Blue Slime."},
	"boar_tusk": {"name": "Boar Tusk", "type": "etc", "price": 70, "weight": 2,
		"desc": "A sharp ivory tusk."},
	"boar_hide": {"name": "Boar Hide", "type": "etc", "price": 44, "weight": 3,
		"desc": "Tough bristly hide."},
	"royal_gel": {"name": "Royal Gel", "type": "etc", "price": 900, "weight": 2,
		"desc": "Shimmering gel from the King Slime's crown."},
	"feather": {"name": "Feather", "type": "etc", "price": 14, "weight": 1, "desc": "A soft little feather."},
	"raw_meat": {"name": "Raw Meat", "type": "etc", "price": 24, "weight": 2, "desc": "Fresh meat. Cooks would pay for it."},
	"milk": {"name": "Milk", "type": "use", "price": 40, "weight": 3, "heal_hp": 45, "desc": "A bottle of fresh milk.\nRestores 45 HP."},
	"ferret_pelt": {"name": "Ferret Pelt", "type": "etc", "price": 46, "weight": 2, "desc": "Silky cinnamon fur."},
	"mushroom": {"name": "Red Mushroom", "type": "use", "price": 50, "weight": 1, "heal_sp": 15, "desc": "A spotted mushroom.\nRestores 15 SP."},
	"wool": {"name": "Wool", "type": "etc", "price": 70, "weight": 2, "desc": "A thick tuft of wool."},
	"goat_horn": {"name": "Goat Horn", "type": "etc", "price": 110, "weight": 3, "desc": "A curled, heavy horn."},
	"ice_crystal": {"name": "Ice Crystal", "type": "etc", "price": 160, "weight": 1, "desc": "Never melts, even in the sun."},
	"flower_petal": {"name": "Blossom Petal", "type": "etc", "price": 150, "weight": 1, "desc": "A sweet-smelling magic petal."},
	"spirit_ember": {"name": "Spirit Ember", "type": "etc", "price": 240, "weight": 1, "desc": "A flicker of a wisp's flame."},
	"shadow_shard": {"name": "Shadow Shard", "type": "etc", "price": 300, "weight": 1, "desc": "Glows faintly with rune light."},
	"golem_crystal": {"name": "Golem Crystal", "type": "etc", "price": 420, "weight": 4, "desc": "The living core of a stone golem."},
	"crystal_sword": {"bonus": {"CRIT": 3, "INT": 1}, "name": "Crystal Sword", "type": "weapon", "atk": 25, "price": 800, "weight": 60, "sprite": "sword",
		"desc": "One-handed sword with a blue crystal blade."},
	"steel_broadsword": {"bonus": {"STR": 2}, "name": "Steel Broadsword", "type": "weapon", "atk": 44, "price": 2400, "weight": 80, "sprite": "iron_sword",
		"desc": "Heavy, reliable steel."},
	"iron_sword": {"name": "Iron Sword", "type": "weapon", "atk": 18, "price": 400, "weight": 50, "sprite": "iron_sword",
		"desc": "A sturdy iron sword.\nReliable and easy to use."},
	"hunting_bow": {"two_hand": true, "name": "Hunting Bow", "type": "weapon", "atk": 22, "price": 800, "weight": 50, "sprite": "bow",
		"desc": "A light yew bow for archers."},
	"oak_staff": {"two_hand": true, "bonus": {"INT": 1}, "name": "Oak Staff", "type": "weapon", "atk": 24, "price": 800, "weight": 40, "sprite": "staff",
		"desc": "A staff topped with an amethyst."},
	"iron_mace": {"name": "Iron Mace", "type": "weapon", "atk": 23, "price": 800, "weight": 70, "sprite": "mace",
		"desc": "A blessed flanged mace."},
	"hand_axe": {"name": "Hand Axe", "type": "weapon", "atk": 27, "price": 800, "weight": 80, "sprite": "axe", "model": "reforged_hand_axe",
		"desc": "A heavy merchant's axe."},
	"steel_dagger": {"name": "Steel Dagger", "type": "weapon", "atk": 20, "price": 800, "weight": 30, "sprite": "dagger",
		"desc": "A quick, sharp dagger."},
	"traveler_clothes": {"slot": "armor", "name": "Traveler's Clothes", "type": "armor", "def": 6, "price": 400, "weight": 40,
		"desc": "Sturdy clothes for a new adventurer."},
	"iron_ore": {"name": "Iron Ore", "type": "etc", "price": 300, "weight": 5, "desc": "Raw iron. The blacksmith uses it to refine and craft gear."},
	"composite_bow": {"two_hand": true, "bonus": {"DEX": 2, "HIT": 4}, "name": "Composite Bow", "type": "weapon", "atk": 38, "price": 3000, "weight": 60, "sprite": "bow",
		"desc": "Horn-and-wood bow with a strong pull."},
	"ember_staff": {"two_hand": true, "bonus": {"INT": 3, "MAXSP_PCT": 5}, "name": "Ember Staff", "type": "weapon", "atk": 40, "price": 3200, "weight": 45, "sprite": "staff",
		"desc": "A staff holding a wisp's ember."},
	"war_mace": {"bonus": {"VIT": 2}, "name": "War Mace", "type": "weapon", "atk": 40, "price": 3000, "weight": 85, "sprite": "mace",
		"desc": "A heavy mace set with golem crystal."},
	"battle_axe": {"two_hand": true, "bonus": {"STR": 3}, "name": "Battle Axe", "type": "weapon", "atk": 46, "price": 3400, "weight": 100, "sprite": "axe", "model": "reforged_battle_axe",
		"desc": "A broad double-handed axe."},
	"viper_dagger": {"bonus": {"AGI": 1, "POISON": 6}, "name": "Viper Dagger", "type": "weapon", "atk": 34, "price": 2800, "weight": 35, "sprite": "dagger",
		"desc": "A wicked dagger forged with shadow shards."},
	"leather_vest": {"slot": "armor", "look": {"outfit": 1, "color": 9}, "bonus": {"FLEE": 2}, "name": "Leather Vest", "type": "armor", "def": 9, "price": 900, "weight": 50, "tint": Color(0.75, 0.52, 0.32),
		"desc": "Boar-hide armour stitched with ferret fur."},
	"wool_cloak": {"slot": "armor", "look": {"outfit": 4, "color": 11}, "bonus": {"MAXHP_PCT": 3}, "name": "Wool Cloak", "type": "armor", "def": 13, "price": 1800, "weight": 45, "tint": Color(0.95, 0.9, 0.78),
		"desc": "A thick, warm and surprisingly tough cloak."},
	"knight_plate": {"slot": "armor", "look": {"outfit": 3, "color": 3}, "name": "Knight Plate", "type": "armor", "def": 10, "price": 1000, "weight": 120,
		"desc": "Faceted steel plate armour."},
	"mithril_plate": {"slot": "armor", "look": {"outfit": 3, "color": 11}, "bonus": {"MAXHP_PCT": 5}, "name": "Mithril Plate", "type": "armor", "def": 22, "price": 5000, "weight": 90,
		"desc": "Light silvery mithril armour."},
	# ---------------------------------------------------------------- refine stones
	"weapon_stone": {"name": "Weapon Refine Stone", "type": "etc", "price": 600, "weight": 5,
		"desc": "A dense blue ore. The blacksmith needs it to refine weapons (+7 and up uses 2)."},
	"armor_stone": {"name": "Armor Refine Stone", "type": "etc", "price": 800, "weight": 5,
		"desc": "A heavy red ore. The blacksmith needs it to refine armour, shields and accessories."},
	# ---------------------------------------------------------------- more armour
	"mage_robe": {"name": "Mage Robe", "type": "armor", "slot": "armor", "def": 5, "price": 1200, "weight": 30,
		"look": {"outfit": 2, "color": 5}, "bonus": {"INT": 2, "MAXSP_PCT": 5},
		"desc": "Violet robe woven with rune thread."},
	"priest_vestment": {"name": "Priest Vestment", "type": "armor", "slot": "armor", "def": 8, "price": 1600, "weight": 40,
		"look": {"outfit": 5, "color": 11}, "bonus": {"INT": 1, "HPREGEN": 15},
		"desc": "White vestment blessed at the cathedral."},
	"shadow_garb": {"name": "Shadow Garb", "type": "armor", "slot": "armor", "def": 8, "price": 2200, "weight": 35,
		"look": {"outfit": 7, "color": 10}, "bonus": {"AGI": 2, "FLEE": 4},
		"desc": "Dark, silent clothing for those who strike unseen."},
	# ---------------------------------------------------------------- shields
	"buckler": {"name": "Buckler", "type": "armor", "slot": "shield", "def": 3, "price": 500, "weight": 30,
		"look": {"kind": "buckler"}, "bonus": {"FLEE": 1}, "desc": "A small round wooden shield."},
	"kite_shield": {"name": "Kite Shield", "type": "armor", "slot": "shield", "def": 7, "price": 1600, "weight": 60,
		"look": {"kind": "kite"}, "bonus": {"VIT": 1}, "desc": "A tall steel shield with a blue crest."},
	"tower_shield": {"name": "Tower Shield", "type": "armor", "slot": "shield", "def": 13, "price": 4000, "weight": 120,
		"look": {"kind": "tower"}, "bonus": {"MAXHP_PCT": 5, "MOVE": -8}, "desc": "A massive wall of iron. Slows you down a little."},
	# ---------------------------------------------------------------- headgear
	"leather_cap": {"name": "Leather Cap", "type": "armor", "slot": "head", "def": 2, "price": 300, "weight": 10,
		"look": {"kind": "cap", "color": Color(0.55, 0.36, 0.2)}, "desc": "A simple padded cap."},
	"iron_helm": {"name": "Iron Helm", "type": "armor", "slot": "head", "def": 5, "price": 1400, "weight": 40,
		"look": {"kind": "helm", "color": Color(0.74, 0.76, 0.82)}, "bonus": {"MAXHP_PCT": 2}, "desc": "A sturdy open-faced helmet."},
	"wizard_hat": {"name": "Wizard Hat", "type": "armor", "slot": "head", "def": 2, "price": 1200, "weight": 10,
		"look": {"kind": "wizard", "color": Color(0.36, 0.24, 0.6)}, "bonus": {"INT": 2, "MAXSP_PCT": 5}, "desc": "A pointed hat full of starlight."},
	"feather_bonnet": {"name": "Feather Bonnet", "type": "armor", "slot": "head", "def": 3, "price": 1300, "weight": 15,
		"look": {"kind": "bonnet", "color": Color(0.3, 0.55, 0.35)}, "bonus": {"DEX": 2, "HIT": 3}, "desc": "A ranger's cap with a hawk feather."},
	"royal_crown": {"name": "Royal Crown", "type": "armor", "slot": "head", "def": 4, "price": 6000, "weight": 20,
		"look": {"kind": "crown", "color": Color(0.98, 0.78, 0.25)},
		"bonus": {"STR": 1, "AGI": 1, "VIT": 1, "INT": 1, "DEX": 1, "LUK": 1}, "desc": "The King Slime's golden crown. All stats +1."},
	# ---------------------------------------------------------------- garments
	"travel_cape": {"name": "Travel Cape", "type": "armor", "slot": "garment", "def": 2, "price": 400, "weight": 15,
		"look": {"color": Color(0.62, 0.22, 0.2)}, "bonus": {"FLEE": 2}, "desc": "A red cape that flutters in the wind."},
	"wool_muffler": {"name": "Wool Muffler", "type": "armor", "slot": "garment", "def": 3, "price": 1100, "weight": 15,
		"look": {"color": Color(0.92, 0.88, 0.76)}, "bonus": {"MAXHP_PCT": 4}, "desc": "Thick, warm and cosy."},
	"shadow_mantle": {"name": "Shadow Mantle", "type": "armor", "slot": "garment", "def": 4, "price": 2600, "weight": 20,
		"look": {"color": Color(0.22, 0.16, 0.32)}, "bonus": {"FLEE": 6, "CRIT": 2}, "desc": "A cloak stitched from the dark."},
	# ---------------------------------------------------------------- gloves
	"leather_gloves": {"name": "Leather Gloves", "type": "armor", "slot": "gloves", "def": 1, "price": 350, "weight": 8,
		"look": {"color": Color(0.5, 0.33, 0.2)}, "bonus": {"HIT": 3}, "desc": "Good grip for any weapon."},
	"iron_gauntlets": {"name": "Iron Gauntlets", "type": "armor", "slot": "gloves", "def": 3, "price": 1500, "weight": 30,
		"look": {"color": Color(0.72, 0.74, 0.8)}, "bonus": {"ATK": 6}, "desc": "Heavy steel fists."},
	"thief_gloves": {"name": "Thief Gloves", "type": "armor", "slot": "gloves", "def": 1, "price": 1400, "weight": 6,
		"look": {"color": Color(0.24, 0.2, 0.26)}, "bonus": {"AGI": 2, "CRIT": 3}, "desc": "Thin black gloves for nimble fingers."},
	# ---------------------------------------------------------------- boots
	"sandals": {"name": "Sandals", "type": "armor", "slot": "boots", "def": 1, "price": 200, "weight": 8,
		"look": {"color": Color(0.7, 0.52, 0.3)}, "bonus": {"MOVE": 4}, "desc": "Light and breezy."},
	"leather_boots": {"name": "Leather Boots", "type": "armor", "slot": "boots", "def": 2, "price": 600, "weight": 15,
		"look": {"color": Color(0.42, 0.27, 0.15)}, "bonus": {"AGI": 1}, "desc": "Comfortable boots for long trips."},
	"iron_greaves": {"name": "Iron Greaves", "type": "armor", "slot": "boots", "def": 5, "price": 1700, "weight": 40,
		"look": {"color": Color(0.7, 0.72, 0.78)}, "bonus": {"MAXHP_PCT": 3}, "desc": "Armoured boots that guard the shins."},
	"wind_boots": {"name": "Wind Boots", "type": "armor", "slot": "boots", "def": 3, "price": 3200, "weight": 12,
		"look": {"color": Color(0.35, 0.75, 0.7)}, "bonus": {"MOVE": 10, "FLEE": 3}, "desc": "Enchanted boots that ride the breeze."},
	# ---------------------------------------------------------------- accessories
	"power_ring": {"name": "Power Ring", "type": "armor", "slot": "accessory", "def": 0, "price": 1500, "weight": 2,
		"bonus": {"STR": 2}, "desc": "A heavy iron ring with a red stone."},
	"sage_ring": {"name": "Sage Ring", "type": "armor", "slot": "accessory", "def": 0, "price": 1500, "weight": 2,
		"bonus": {"INT": 2, "MAXSP_PCT": 3}, "desc": "A silver ring with a sapphire."},
	"swift_brooch": {"name": "Swift Brooch", "type": "armor", "slot": "accessory", "def": 0, "price": 1500, "weight": 2,
		"bonus": {"AGI": 2, "ASPD": 3}, "desc": "A winged brooch that quickens the hand."},
	"lucky_rosary": {"name": "Lucky Rosary", "type": "armor", "slot": "accessory", "def": 0, "price": 1500, "weight": 2,
		"bonus": {"LUK": 3, "CRIT": 3}, "desc": "Prayer beads said to bring good fortune."},
	"hawk_clip": {"name": "Hawk Eye Clip", "type": "armor", "slot": "accessory", "def": 0, "price": 1500, "weight": 2,
		"bonus": {"DEX": 2, "HIT": 5}, "desc": "A hair clip shaped like a hawk's eye."},
	"ruby_amulet": {"name": "Ruby Amulet", "type": "armor", "slot": "accessory", "def": 1, "price": 2400, "weight": 3,
		"bonus": {"VIT": 1, "MAXHP_PCT": 8}, "desc": "A warm ruby on a golden chain."},
	# ---------------------------------------------------------------- region materials
	"moss_clump": {"name": "Moss Clump", "type": "etc", "price": 180, "weight": 1, "desc": "Soft green moss from the Verdant Ruins."},
	"jade_scale": {"name": "Jade Scale", "type": "etc", "price": 260, "weight": 1, "desc": "A hard green scale that shines like jade."},
	"living_vine": {"name": "Living Vine", "type": "etc", "price": 230, "weight": 1, "desc": "It still twitches now and then."},
	"rune_stone": {"name": "Rune Stone", "type": "etc", "price": 340, "weight": 4, "desc": "A carved stone from an old sentinel. The rune glows green."},
	"spore_powder": {"name": "Spore Powder", "type": "etc", "price": 300, "weight": 1, "desc": "Purple dust that makes you sneeze."},
	"ancient_bark": {"name": "Ancient Bark", "type": "etc", "price": 420, "weight": 3, "desc": "Bark from a tree older than the kingdom."},
	"treant_heart": {"name": "Treant Heart", "type": "etc", "price": 3000, "weight": 5, "desc": "A warm amber core that hums with life."},
	"scarab_shell": {"name": "Scarab Shell", "type": "etc", "price": 300, "weight": 2, "desc": "Blue shell with a golden rim."},
	"lizard_scale": {"name": "Lizard Scale", "type": "etc", "price": 320, "weight": 1, "desc": "Sandy, rough and very tough."},
	"cactus_needle": {"name": "Cactus Needle", "type": "etc", "price": 280, "weight": 1, "desc": "Sharp enough to sew leather."},
	"djinn_sand": {"name": "Djinn Sand", "type": "etc", "price": 380, "weight": 1, "desc": "Golden sand that floats above your palm."},
	"scorpion_stinger": {"name": "Scorpion Stinger", "type": "etc", "price": 2000, "weight": 3, "desc": "The Scorpion Lord's stinger. Still dripping."},
	"jackal_fang": {"name": "Jackal Fang", "type": "etc", "price": 420, "weight": 1, "desc": "A black fang from a tomb jackal."},
	"mummy_wrap": {"name": "Ancient Wrap", "type": "etc", "price": 400, "weight": 1, "desc": "A linen strip covered in old writing."},
	"pharaoh_gold": {"name": "Pharaoh's Gold", "type": "etc", "price": 4000, "weight": 5, "desc": "A heavy ingot stamped with a sun."},
	"snow_fur": {"name": "Snow Fur", "type": "etc", "price": 380, "weight": 2, "desc": "The warmest fur in the world."},
	"wolf_fang": {"name": "Frost Fang", "type": "etc", "price": 420, "weight": 1, "desc": "A fang as cold as ice."},
	"frost_core": {"name": "Frost Core", "type": "etc", "price": 520, "weight": 3, "desc": "The heart of an ice golem."},
	"yeti_horn": {"name": "Yeti Horn", "type": "etc", "price": 480, "weight": 3, "desc": "Short, blue and very heavy."},
	"mammoth_tusk": {"name": "Mammoth Tusk", "type": "etc", "price": 2600, "weight": 8, "desc": "A huge curved ivory tusk."},
	"bat_wing": {"name": "Crystal Bat Wing", "type": "etc", "price": 460, "weight": 1, "desc": "Thin as glass. Rings when you tap it."},
	"wyrm_scale": {"name": "Wyrm Scale", "type": "etc", "price": 5000, "weight": 4, "desc": "A scale from the Glacier Wyrm. Never melts."},
	"magma_gel": {"name": "Magma Gel", "type": "etc", "price": 480, "weight": 1, "desc": "Still warm. Handle with gloves."},
	"salamander_tail": {"name": "Salamander Tail", "type": "etc", "price": 520, "weight": 2, "desc": "It keeps burning for days."},
	"obsidian_shard": {"name": "Obsidian Shard", "type": "etc", "price": 600, "weight": 2, "desc": "Black volcanic glass with a razor edge."},
	"imp_horn": {"name": "Imp Horn", "type": "etc", "price": 560, "weight": 1, "desc": "A little horn that smells of smoke."},
	"phoenix_feather": {"name": "Phoenix Feather", "type": "etc", "price": 3500, "weight": 1, "desc": "A feather that glows like a sunset."},
	"lava_core": {"name": "Lava Core", "type": "etc", "price": 700, "weight": 4, "desc": "A molten core from a lava golem."},
	"ash_cloth": {"name": "Ash Cloth", "type": "etc", "price": 640, "weight": 1, "desc": "Grey cloth that never catches fire."},
	"drake_heart": {"name": "Drake Heart", "type": "etc", "price": 7000, "weight": 6, "desc": "The burning heart of the Inferno Drake."},
	# ---------------------------------------------------------------- region gear
	"jade_blade": {"bonus": {"DEX": 2, "HIT": 6}, "name": "Jade Blade", "type": "weapon", "atk": 62, "price": 6200, "weight": 70, "sprite": "iron_sword", "pal": "jade",
		"desc": "A sword carved from living jade."},
	"druid_staff": {"two_hand": true, "bonus": {"INT": 4, "HPREGEN": 10}, "name": "Druid Staff", "type": "weapon", "atk": 58, "price": 6200, "weight": 45, "sprite": "staff", "pal": "druid",
		"desc": "Twisted ancient wood with a green crystal."},
	"vine_bow": {"two_hand": true, "bonus": {"DEX": 3, "AGI": 1}, "name": "Vine Bow", "type": "weapon", "atk": 56, "price": 6000, "weight": 50, "sprite": "bow", "pal": "vine",
		"desc": "A bow strung with a living vine."},
	"ranger_hood": {"name": "Ranger Hood", "type": "armor", "slot": "head", "def": 6, "price": 4200, "weight": 12,
		"look": {"kind": "bonnet", "color": Color(0.22, 0.45, 0.25)}, "bonus": {"DEX": 2, "AGI": 1}, "desc": "A mossy hood that hides you in the leaves."},
	"moss_cloak": {"name": "Moss Cloak", "type": "armor", "slot": "garment", "def": 5, "price": 4500, "weight": 18,
		"look": {"color": Color(0.3, 0.5, 0.25)}, "bonus": {"FLEE": 5, "HPREGEN": 10}, "desc": "Soft, green and always a little damp."},
	"sun_scimitar": {"bonus": {"CRIT": 5, "AGI": 2}, "name": "Sun Scimitar", "type": "weapon", "atk": 78, "price": 8800, "weight": 70, "sprite": "iron_sword", "pal": "sun",
		"desc": "A golden curved blade from the desert kings."},
	"scorpion_dagger": {"bonus": {"AGI": 3, "POISON": 10}, "name": "Scorpion Dagger", "type": "weapon", "atk": 70, "price": 8400, "weight": 30, "sprite": "dagger", "pal": "scorpion",
		"desc": "Made from the Scorpion Lord's stinger."},
	"scarab_shield": {"name": "Scarab Shield", "type": "armor", "slot": "shield", "def": 15, "price": 7000, "weight": 70,
		"look": {"kind": "kite"}, "bonus": {"VIT": 2, "MAXHP_PCT": 3}, "desc": "A shield of scarab shell with a golden rim."},
	"desert_robe": {"name": "Desert Robe", "type": "armor", "slot": "armor", "def": 18, "price": 8000, "weight": 40,
		"look": {"outfit": 2, "color": 9}, "bonus": {"FLEE": 6, "INT": 1}, "desc": "Light robes that keep out sun and sand."},
	"sand_boots": {"name": "Sand Striders", "type": "armor", "slot": "boots", "def": 6, "price": 6500, "weight": 15,
		"look": {"color": Color(0.85, 0.7, 0.45)}, "bonus": {"MOVE": 8, "AGI": 1}, "desc": "Wide soles that never sink in sand."},
	"pharaoh_mask": {"name": "Pharaoh's Mask", "type": "armor", "slot": "head", "def": 8, "price": 12000, "weight": 20,
		"look": {"kind": "crown", "color": Color(0.95, 0.75, 0.25)}, "bonus": {"INT": 3, "DEX": 2, "MAXSP_PCT": 8}, "desc": "Golden mask of the Sun Pharaoh."},
	"frost_axe": {"two_hand": true, "bonus": {"STR": 4}, "name": "Frost Axe", "type": "weapon", "atk": 96, "price": 11000, "weight": 110, "sprite": "axe", "model": "reforged_frost_axe", "pal": "frost",
		"desc": "A double axe whose edge is frozen solid."},
	"glacier_mace": {"bonus": {"VIT": 3, "INT": 1}, "name": "Glacier Mace", "type": "weapon", "atk": 88, "price": 10500, "weight": 90, "sprite": "mace", "pal": "frost",
		"desc": "A mace headed with an ever-cold crystal."},
	"yeti_coat": {"name": "Yeti Coat", "type": "armor", "slot": "armor", "def": 28, "price": 12000, "weight": 80,
		"look": {"outfit": 4, "color": 11}, "bonus": {"MAXHP_PCT": 8, "VIT": 1}, "desc": "Thick shaggy fur. Nothing gets through."},
	"frost_gauntlets": {"name": "Frost Gauntlets", "type": "armor", "slot": "gloves", "def": 6, "price": 9000, "weight": 30,
		"look": {"color": Color(0.6, 0.8, 0.95)}, "bonus": {"ATK": 10, "HIT": 4}, "desc": "Gauntlets of packed ice."},
	"wyrm_shield": {"name": "Wyrm Scale Shield", "type": "armor", "slot": "shield", "def": 20, "price": 15000, "weight": 80,
		"look": {"kind": "tower"}, "bonus": {"MAXHP_PCT": 8, "DEF": 4}, "desc": "Built from the Glacier Wyrm's scales."},
	"inferno_sword": {"bonus": {"STR": 3, "CRIT": 4}, "name": "Inferno Sword", "type": "weapon", "atk": 110, "price": 16000, "weight": 85, "sprite": "iron_sword", "pal": "inferno",
		"desc": "Its blade glows red like fresh lava."},
	"phoenix_bow": {"two_hand": true, "bonus": {"DEX": 5, "AGI": 2}, "name": "Phoenix Bow", "type": "weapon", "atk": 104, "price": 16000, "weight": 55, "sprite": "bow", "pal": "phoenix",
		"desc": "Strung with a phoenix feather."},
	"magma_staff": {"two_hand": true, "bonus": {"INT": 6, "MAXSP_PCT": 10}, "name": "Magma Staff", "type": "weapon", "atk": 100, "price": 16000, "weight": 50, "sprite": "staff", "pal": "magma",
		"desc": "A black staff with a lava core."},
	"obsidian_plate": {"name": "Obsidian Plate", "type": "armor", "slot": "armor", "def": 36, "price": 18000, "weight": 110,
		"look": {"outfit": 3, "color": 10}, "bonus": {"MAXHP_PCT": 10, "DEF": 3}, "desc": "Volcanic glass armour, polished black."},
	"drake_helm": {"name": "Drake Helm", "type": "armor", "slot": "head", "def": 10, "price": 20000, "weight": 40,
		"look": {"kind": "helm", "color": Color(0.6, 0.15, 0.12)}, "bonus": {"STR": 2, "VIT": 2, "MAXHP_PCT": 5}, "desc": "Horned helm from the Inferno Drake."},
	"ember_ring": {"name": "Ember Ring", "type": "armor", "slot": "accessory", "def": 1, "price": 9000, "weight": 2,
		"bonus": {"STR": 3, "INT": 3}, "desc": "A ring with a coal that never goes out."},
	# ---------------------------------------------------------------- wyvern wings (garment slot, crafted by Doran)
	"wings_lightning": {"name": "Lightning Wyvern Wings", "type": "armor", "slot": "garment", "def": 8, "price": 30000, "weight": 30,
		"look": {"wings": "lightning"}, "bonus": {"AGI": 3, "ASPD": 6, "FLEE": 6, "MOVE": 5}, "desc": "Violet wings crackling with arc veins.\nFaster attacks and footwork."},
	"wings_ancient": {"name": "Ancient Wyvern Wings", "type": "armor", "slot": "garment", "def": 10, "price": 40000, "weight": 35,
		"look": {"wings": "ancient"}, "bonus": {"STR": 2, "AGI": 2, "VIT": 2, "INT": 2, "DEX": 2, "LUK": 2, "MOVE": 5}, "desc": "Weathered gold wings with an ember fringe.\nAll stats +2."},
	"wings_abyssal": {"name": "Abyssal Wyvern Wings", "type": "armor", "slot": "garment", "def": 8, "price": 25000, "weight": 30,
		"look": {"wings": "abyssal"}, "bonus": {"CRIT": 6, "FLEE": 6, "LUK": 3, "MOVE": 5}, "desc": "Deep violet wings lined with dark thorns.\nCritical hits and dodging."},
	"wings_frozen": {"name": "Frozen Wyvern Wings", "type": "armor", "slot": "garment", "def": 12, "price": 45000, "weight": 40,
		"look": {"wings": "frozen"}, "bonus": {"VIT": 3, "MAXHP_PCT": 10, "DEF": 4, "MOVE": 5}, "desc": "Glacier-blade wings dripping with icicles.\nToughness and Max HP."},
	"wings_fire": {"name": "Fire Wyvern Wings", "type": "armor", "slot": "garment", "def": 10, "price": 50000, "weight": 35,
		"look": {"wings": "fire"}, "bonus": {"STR": 3, "ATK": 15, "CRIT": 3, "MOVE": 5}, "desc": "Scorched wings with a flame edge.\nRaw attack power."},
	"wings_poison": {"name": "Poison Wyvern Wings", "type": "armor", "slot": "garment", "def": 9, "price": 35000, "weight": 30,
		"look": {"wings": "poison"}, "bonus": {"DEX": 3, "POISON": 12, "HIT": 8, "MOVE": 5}, "desc": "Green wings with venom veins and toxic drops.\nAccuracy and poison."},
	# ---- Fourteen Celestial Staves (solid 1/64 voxel models, crafted by the smith)
	"verdant_crescent_staff": {"two_hand": true, "name": "Verdant Crescent Staff", "type": "weapon", "atk": 64, "price": 10000, "weight": 40, "sprite": "staff", "model": "verdant_crescent_staff",
		"bonus": {"INT": 3, "MAXSP_PCT": 5}, "desc": "A green crescent moon over a vine-wrapped shaft."},
	"jade_enchanter_staff": {"two_hand": true, "name": "Jade Enchanter Staff", "type": "weapon", "atk": 70, "price": 13000, "weight": 40, "sprite": "staff", "model": "jade_enchanter_staff",
		"bonus": {"INT": 3, "DEX": 2}, "desc": "A crooked witch-hat crown of jade petals."},
	"violet_moon_staff": {"two_hand": true, "name": "Violet Moon Staff", "type": "weapon", "atk": 76, "price": 16000, "weight": 40, "sprite": "staff", "model": "violet_moon_staff",
		"bonus": {"INT": 4, "MAXSP_PCT": 6}, "desc": "Twin violet crescents cradling a small star."},
	"solar_wand": {"name": "Solar Wand", "type": "weapon", "atk": 80, "price": 18000, "weight": 40, "sprite": "mace", "model": "solar_wand",
		"bonus": {"INT": 4, "CRIT": 3}, "desc": "A short wand crowned with a blazing six-point sun.\nOne-handed."},
	"amber_starfall_staff": {"two_hand": true, "name": "Amber Starfall Staff", "type": "weapon", "atk": 86, "price": 21000, "weight": 40, "sprite": "staff", "model": "amber_starfall_staff",
		"bonus": {"INT": 4, "DEX": 3}, "desc": "An amber ring holding a falling crimson star."},
	"rose_compass_staff": {"two_hand": true, "name": "Rose Compass Staff", "type": "weapon", "atk": 90, "price": 23000, "weight": 40, "sprite": "staff", "model": "rose_compass_staff",
		"bonus": {"INT": 4, "HPREGEN": 10}, "desc": "A compass star nested in a rose crescent."},
	"ivory_moonwing_staff": {"two_hand": true, "name": "Ivory Moonwing Staff", "type": "weapon", "atk": 94, "price": 25000, "weight": 40, "sprite": "staff", "model": "ivory_moonwing_staff",
		"bonus": {"INT": 5, "AGI": 2}, "desc": "An ivory moon with a halo of floating beads."},
	"frost_diadem_staff": {"two_hand": true, "name": "Frost Diadem Staff", "type": "weapon", "atk": 98, "price": 27000, "weight": 40, "sprite": "staff", "model": "frost_diadem_staff",
		"bonus": {"INT": 5, "VIT": 2}, "desc": "A lilac ice crown above a frozen lotus."},
	"sapphire_lotus_staff": {"two_hand": true, "name": "Sapphire Lotus Staff", "type": "weapon", "atk": 102, "price": 29000, "weight": 40, "sprite": "staff", "model": "sapphire_lotus_staff",
		"bonus": {"INT": 5, "MAXSP_PCT": 10}, "desc": "Sapphire lotus petals around a pale star."},
	"azure_orb_staff": {"two_hand": true, "name": "Azure Orb Staff", "type": "weapon", "atk": 106, "price": 31000, "weight": 40, "sprite": "staff", "model": "azure_orb_staff",
		"bonus": {"INT": 6, "DEX": 2}, "desc": "A glowing azure orb in a cloud-scroll frame."},
	"midnight_fleur_staff": {"two_hand": true, "name": "Midnight Fleur Staff", "type": "weapon", "atk": 110, "price": 34000, "weight": 40, "sprite": "staff", "model": "midnight_fleur_staff",
		"bonus": {"INT": 6, "FLEE": 5}, "desc": "Midnight-blue fleur scrolls and a starlit gem."},
	"lunar_familiar_staff": {"two_hand": true, "name": "Lunar Familiar Staff", "type": "weapon", "atk": 114, "price": 37000, "weight": 40, "sprite": "staff", "model": "lunar_familiar_staff",
		"bonus": {"INT": 6, "LUK": 4, "CRIT": 3}, "desc": "A tiny long-eared familiar sleeps in the crescent."},
	"astral_star_staff": {"two_hand": true, "name": "Astral Star Staff", "type": "weapon", "atk": 120, "price": 42000, "weight": 40, "sprite": "staff", "model": "astral_star_staff",
		"bonus": {"INT": 7, "DEX": 3}, "desc": "A six-point star inside a ring of orbiting gems."},
	"ruby_eclipse_staff": {"two_hand": true, "name": "Ruby Eclipse Staff", "type": "weapon", "atk": 128, "price": 48000, "weight": 40, "sprite": "staff", "model": "ruby_eclipse_staff",
		"bonus": {"INT": 8, "MAXSP_PCT": 12}, "desc": "A moon medallion eclipsing a sun of ruby rays."},
	# ---- Seven Arcane Bows (solid 1/64 voxel models, crafted by the smith)
	"verdant_ruby_bow": {"two_hand": true, "name": "Verdant Ruby Bow", "type": "weapon", "atk": 72, "price": 15000, "weight": 50, "sprite": "bow", "model": "verdant_ruby_bow",
		"bonus": {"DEX": 3, "HIT": 6}, "desc": "Leaf-wrapped limbs set with three rubies."},
	"aureate_seraph_bow": {"two_hand": true, "name": "Aureate Seraph Bow", "type": "weapon", "atk": 88, "price": 22000, "weight": 50, "sprite": "bow", "model": "aureate_seraph_bow",
		"bonus": {"DEX": 4, "CRIT": 4}, "desc": "Golden seraph wings around a violet gem."},
	"frost_crescent_bow": {"two_hand": true, "name": "Frost Crescent Bow", "type": "weapon", "atk": 100, "price": 28000, "weight": 50, "sprite": "bow", "model": "frost_crescent_bow",
		"bonus": {"DEX": 4, "AGI": 3}, "desc": "A crescent of frozen steel with an ice jewel."},
	"crimson_thorn_bow": {"two_hand": true, "name": "Crimson Thorn Bow", "type": "weapon", "atk": 108, "price": 32000, "weight": 50, "sprite": "bow", "model": "crimson_thorn_bow",
		"bonus": {"DEX": 4, "CRIT": 4, "POISON": 10}, "desc": "Thorned crimson limbs that drip venom."},
	"astral_silver_bow": {"two_hand": true, "name": "Astral Silver Bow", "type": "weapon", "atk": 118, "price": 40000, "weight": 50, "sprite": "bow", "model": "astral_silver_bow",
		"bonus": {"DEX": 5, "INT": 3, "MAXSP_PCT": 8}, "desc": "Silver feathered wings around a starlit orb."},
	"aether_cyan_bow": {"two_hand": true, "name": "Aether Cyan Bow", "type": "weapon", "atk": 125, "price": 42000, "weight": 50, "sprite": "bow", "model": "aether_cyan_bow",
		"bonus": {"DEX": 6, "AGI": 3, "ASPD": 5}, "desc": "Cyan aether ribs that hum when drawn."},
	"obsidian_dragon_bow": {"two_hand": true, "name": "Obsidian Dragon Bow", "type": "weapon", "atk": 134, "price": 45000, "weight": 50, "sprite": "bow", "model": "obsidian_dragon_bow",
		"bonus": {"DEX": 5, "STR": 3, "CRIT": 5}, "desc": "Black dragon-scale limbs with a burning eye."},
	# ---- Arcane Mage collection (3D models from arcane_mage_set_360.blend, crafted by the smith)
	"arcane_sword": {"name": "Arcane Sword", "type": "weapon", "atk": 124, "price": 30000, "weight": 70, "sprite": "iron_sword", "model": "arcane_sword",
		"bonus": {"STR": 3, "INT": 3, "CRIT": 5}, "desc": "Turquoise blade with a rose energy channel."},
	"arcane_axe": {"two_hand": true, "name": "Crescent Axe", "type": "weapon", "atk": 140, "price": 32000, "weight": 110, "sprite": "axe", "model": "reforged_arcane_axe",
		"bonus": {"STR": 5, "CRIT": 3}, "desc": "Twin crescent blades around an amethyst heart."},
	"arcane_hammer": {"name": "Runic Hammer", "type": "weapon", "atk": 128, "price": 31000, "weight": 100, "sprite": "mace", "model": "arcane_hammer",
		"bonus": {"VIT": 4, "INT": 2, "DEF": 4}, "desc": "A rune-bound hammer with a cyan crystal core."},
	"arcane_dagger": {"name": "Jade Ritual Dagger", "type": "weapon", "atk": 112, "price": 28000, "weight": 30, "sprite": "dagger", "model": "arcane_dagger",
		"bonus": {"AGI": 4, "CRIT": 6, "POISON": 8}, "desc": "Ceremonial jade blade with an icy jewel."},
	"arcane_bow": {"two_hand": true, "name": "Amethyst Bow", "type": "weapon", "atk": 122, "price": 30000, "weight": 55, "sprite": "bow", "model": "arcane_bow",
		"bonus": {"DEX": 5, "AGI": 2, "HIT": 8}, "desc": "Gilded limbs around a long amethyst."},
	"arcane_crossbow": {"two_hand": true, "name": "Crystal Crossbow", "type": "weapon", "atk": 132, "price": 33000, "weight": 70, "sprite": "bow", "model": "arcane_crossbow",
		"bonus": {"DEX": 4, "CRIT": 6, "HIT": 5}, "desc": "Jade limbs and a cyan focus crystal."},
	"arcane_staff": {"two_hand": true, "name": "Amethyst Staff", "type": "weapon", "atk": 118, "price": 32000, "weight": 50, "sprite": "staff", "model": "arcane_staff",
		"bonus": {"INT": 7, "MAXSP_PCT": 12}, "desc": "A pink crystal crowned with floating runes."},
	"glacier_staff": {"two_hand": true, "name": "Glacier Staff", "type": "weapon", "atk": 114, "price": 32000, "weight": 50, "sprite": "staff", "model": "glacier_staff",
		"bonus": {"INT": 5, "VIT": 3, "HPREGEN": 15}, "desc": "A great cyan crystal between golden wings."},
	"arcane_tower_shield": {"name": "Amethyst Tower Shield", "type": "armor", "slot": "shield", "def": 24, "price": 30000, "weight": 90,
		"look": {"model": "arcane_tower_shield"}, "bonus": {"VIT": 3, "MAXHP_PCT": 10, "DEF": 4}, "desc": "A tall shield set with a long amethyst."},
	"arcane_cross_shield": {"name": "Cyan Cross Shield", "type": "armor", "slot": "shield", "def": 18, "price": 28000, "weight": 60,
		"look": {"model": "arcane_cross_shield"}, "bonus": {"INT": 3, "MAXSP_PCT": 8, "FLEE": 4}, "desc": "A light cross-shaped shield with a cyan heart."},
	"arcane_armor": {"name": "Arcane Mage Armor", "type": "armor", "slot": "armor", "def": 32, "price": 45000, "weight": 80,
		"look": {"model_set": "arcane"}, "bonus": {"INT": 6, "DEX": 2, "MAXSP_PCT": 15, "MAXHP_PCT": 8}, "desc": "Full arcane armour: crown helm, gilded pauldrons,\ngauntlets with magenta focus gems and a rear cape."},
	# ---- mining (ore rocks) and fishing (fishing spots): materials for the blacksmith
	"copper_ore": {"name": "Copper Ore", "type": "etc", "price": 60, "weight": 4, "icon": ["ore", Color(0.85, 0.5, 0.25)],
		"desc": "Reddish ore from a rock vein. Mined around Aldenvale and the Verdant Ruins."},
	"coal": {"name": "Coal", "type": "etc", "price": 40, "weight": 3, "icon": ["ore", Color(0.16, 0.16, 0.18)],
		"desc": "Black fuel for the forge. Found in most ore rocks."},
	"silver_ore": {"name": "Silver Ore", "type": "etc", "price": 260, "weight": 4, "icon": ["ore", Color(0.85, 0.88, 0.95)],
		"desc": "Bright ore from the Frostpeak Glacier."},
	"gold_ore": {"name": "Gold Ore", "type": "etc", "price": 420, "weight": 5, "icon": ["ore", Color(1.0, 0.8, 0.25)],
		"desc": "Heavy golden ore from the Sunscorch Desert and Emberfall."},
	"mithril_ore": {"name": "Mithril Ore", "type": "etc", "price": 900, "weight": 3, "icon": ["ore", Color(0.45, 0.85, 0.95)],
		"desc": "Rare blue-silver ore found only near the Emberfall lava."},
	"emerald_gem": {"name": "Emerald", "type": "etc", "price": 1200, "weight": 1, "icon": ["gem", Color(0.25, 0.85, 0.45)],
		"desc": "A green gem, sometimes found while mining in the Verdant Ruins."},
	"ruby_gem": {"name": "Ruby", "type": "etc", "price": 1400, "weight": 1, "icon": ["gem", Color(0.95, 0.2, 0.3)],
		"desc": "A red gem, sometimes found while mining in hot lands."},
	"sapphire_gem": {"name": "Sapphire", "type": "etc", "price": 1400, "weight": 1, "icon": ["gem", Color(0.25, 0.45, 1.0)],
		"desc": "A blue gem, sometimes found while mining in the Frostpeak Glacier."},
	"river_fish": {"name": "River Fish", "type": "use", "price": 30, "weight": 2, "heal_hp": 60, "icon": ["fish", Color(0.55, 0.65, 0.7)],
		"desc": "A fresh catch.\nRestores 60 HP."},
	"golden_carp": {"name": "Golden Carp", "type": "use", "price": 400, "weight": 3, "heal_hp": 250, "icon": ["fish", Color(1.0, 0.72, 0.2)],
		"desc": "A lucky golden fish.\nRestores 250 HP."},
	"ice_trout": {"name": "Ice Trout", "type": "use", "price": 120, "weight": 2, "heal_hp": 90, "heal_sp": 20, "icon": ["fish", Color(0.6, 0.85, 1.0)],
		"desc": "Caught through a hole in the ice.\nRestores 90 HP and 20 SP."},
	"lava_eel": {"name": "Lava Eel", "type": "use", "price": 260, "weight": 2, "heal_sp": 60, "icon": ["fish", Color(0.95, 0.35, 0.1)],
		"desc": "Somehow it swims in lava.\nRestores 60 SP."},
	"fish_scale": {"name": "Fish Scale", "type": "etc", "price": 25, "weight": 1, "icon": ["scale", Color(0.6, 0.85, 0.85)],
		"desc": "Hard shiny scales. Used to make glue and light armour."},
	"pearl": {"name": "Pearl", "type": "etc", "price": 1600, "weight": 1, "icon": ["pearl", Color(0.96, 0.94, 0.98)],
		"desc": "A rare pearl, sometimes found while fishing."},
	"pearl_necklace": {"name": "Pearl Necklace", "type": "armor", "slot": "accessory", "def": 1, "price": 9000, "weight": 2,
		"bonus": {"MAXHP_PCT": 5, "MAXSP_PCT": 5, "LUK": 2}, "icon": ["necklace", Color(0.96, 0.94, 0.98)],
		"desc": "Pearls on a silver chain, crafted from your catches."},

	# ---------------------------------------------------------------- weapon types beyond the six starter kinds
	"worn_knife": {"name": "Worn Knife", "type": "weapon", "wtype": "dagger", "atk": 10, "price": 100, "weight": 20, "sprite": "dagger",
		"desc": "A chipped knife every Novice is handed on day one."},
	"ash_pike": {"name": "Ash Pike", "type": "weapon", "wtype": "spear", "atk": 30, "price": 900, "weight": 70, "sprite": "spear",
		"desc": "A plain ash-wood pike. Reaches a little further than a sword."},
	"steel_glaive": {"two_hand": true, "bonus": {"STR": 2, "HIT": 3}, "name": "Steel Glaive", "type": "weapon", "wtype": "spear", "atk": 54, "price": 3600, "weight": 110,
		"sprite": "spear", "pal": "frost", "desc": "A long blade on a pole for sweeping strikes."},
	"ember_halberd": {"two_hand": true, "bonus": {"STR": 3, "CRIT": 3}, "name": "Ember Halberd", "type": "weapon", "wtype": "spear", "atk": 98, "price": 14000, "weight": 120,
		"sprite": "spear", "pal": "magma", "desc": "Forged in the volcano; the head still glows."},
	"iron_greatsword": {"two_hand": true, "bonus": {"STR": 1}, "name": "Iron Greatsword", "type": "weapon", "wtype": "greatsword", "atk": 42, "price": 2000, "weight": 130,
		"sprite": "greatsword", "desc": "A heavy two-handed blade."},
	"runed_greatsword": {"two_hand": true, "bonus": {"STR": 3, "ATK": 6}, "name": "Runed Greatsword", "type": "weapon", "wtype": "greatsword", "atk": 92, "price": 13000, "weight": 140,
		"sprite": "greatsword", "pal": "jade", "desc": "Old runes along the fuller hum when you swing it."},
	"twin_fang_katar": {"two_hand": true, "bonus": {"CRIT": 4}, "name": "Twin Fang Katar", "type": "weapon", "wtype": "katar", "atk": 38, "price": 2400, "weight": 50,
		"sprite": "katar", "desc": "A punch-blade with two prongs."},
	"nightclaw_katar": {"two_hand": true, "bonus": {"CRIT": 8, "AGI": 2}, "name": "Nightclaw Katar", "type": "weapon", "wtype": "katar", "atk": 82, "price": 12000, "weight": 55,
		"sprite": "katar", "pal": "scorpion", "desc": "Black steel that drinks the light."},
	"leather_knuckles": {"name": "Leather Knuckles", "type": "weapon", "wtype": "knuckle", "atk": 28, "price": 900, "weight": 20, "sprite": "knuckle",
		"desc": "Padded leather wraps with studs."},
	"iron_knuckles": {"bonus": {"AGI": 1, "HIT": 2}, "name": "Iron Knuckles", "type": "weapon", "wtype": "knuckle", "atk": 56, "price": 4200, "weight": 30, "sprite": "knuckle",
		"pal": "frost", "desc": "Iron plates over the fist."},
	"dragonbone_knuckles": {"bonus": {"STR": 2, "CRIT": 4}, "name": "Dragonbone Knuckles", "type": "weapon", "wtype": "knuckle", "atk": 94, "price": 14000, "weight": 35,
		"sprite": "knuckle", "pal": "sun", "desc": "Carved from an old dragon's bone."},
	"worn_tome": {"bonus": {"INT": 1}, "name": "Worn Tome", "type": "weapon", "wtype": "book", "atk": 24, "price": 900, "weight": 30, "sprite": "book",
		"desc": "A heavy book of notes. Hits harder than it looks."},
	"tome_of_embers": {"bonus": {"INT": 3, "MAXSP_PCT": 4}, "name": "Tome of Embers", "type": "weapon", "wtype": "book", "atk": 60, "price": 6000, "weight": 35,
		"sprite": "book", "pal": "inferno", "desc": "Its pages are warm to the touch."},
	"codex_of_stars": {"bonus": {"INT": 5, "DEX": 2}, "name": "Codex of Stars", "type": "weapon", "wtype": "book", "atk": 100, "price": 15000, "weight": 35,
		"sprite": "book", "pal": "frost", "desc": "Star charts that shift as you read them."},
	"braided_whip": {"bonus": {"DEX": 1}, "name": "Braided Whip", "type": "weapon", "wtype": "whip", "atk": 28, "price": 900, "weight": 25, "sprite": "whip",
		"desc": "Three leather cords braided tight."},
	"thornlash_whip": {"bonus": {"DEX": 2, "CRIT": 3}, "name": "Thornlash Whip", "type": "weapon", "wtype": "whip", "atk": 64, "price": 6400, "weight": 30, "sprite": "whip",
		"pal": "vine", "desc": "A vine whip with thorns that never fall off."},
	"travelers_lute": {"bonus": {"LUK": 1}, "name": "Traveler's Lute", "type": "weapon", "wtype": "instrument", "atk": 28, "price": 900, "weight": 40, "sprite": "lute",
		"desc": "A well-loved lute. Also a decent club."},
	"silverstring_lute": {"bonus": {"DEX": 2, "LUK": 2}, "name": "Silverstring Lute", "type": "weapon", "wtype": "instrument", "atk": 66, "price": 6600, "weight": 45,
		"sprite": "lute", "pal": "frost", "desc": "Silver strings that ring for minutes."},
}

## ---------------------------------------------------------------- weapon types and job rules
## Every weapon has a type: "wtype" if set, otherwise from its sprite.
const SPRITE_WTYPE := {"iron_sword": "sword", "sword": "sword", "bow": "bow", "staff": "staff", "mace": "mace",
	"axe": "axe", "dagger": "dagger", "spear": "spear", "greatsword": "greatsword", "katar": "katar",
	"knuckle": "knuckle", "book": "book", "whip": "whip", "lute": "instrument"}
const WEAPON_TYPE_NAMES := {"sword": "One-handed Sword", "greatsword": "Two-handed Sword", "spear": "Spear", "dagger": "Dagger",
	"katar": "Katar", "axe": "Axe", "mace": "Mace", "staff": "Staff", "book": "Tome", "bow": "Bow", "knuckle": "Knuckle",
	"whip": "Whip", "instrument": "Instrument"}
## Which weapon types each job may use: novice, 1st job, then 2nd/3rd job per branch.
const JOB_WEAPONS := {
	"novice": ["dagger", "sword", "mace", "staff"],
	"swordsman": {"1": ["sword", "greatsword", "spear", "dagger", "axe", "mace"],
		"a": ["sword", "greatsword", "spear", "dagger", "axe", "mace"],
		"b": ["sword", "spear", "mace", "dagger"]},
	"archer": {"1": ["bow", "dagger"], "a": ["bow", "dagger"], "b": ["bow", "dagger", "whip", "instrument"]},
	"mage": {"1": ["staff", "dagger"], "a": ["staff", "dagger"], "b": ["staff", "dagger", "book", "sword"]},
	"acolyte": {"1": ["mace", "staff"], "a": ["mace", "staff", "book"], "b": ["mace", "staff", "knuckle"]},
	"merchant": {"1": ["axe", "mace", "dagger", "sword"], "a": ["axe", "mace", "dagger", "sword", "greatsword"],
		"b": ["axe", "mace", "dagger", "sword", "book"]},
	"thief": {"1": ["dagger", "sword", "bow"], "a": ["dagger", "katar", "sword", "axe"], "b": ["dagger", "sword", "bow", "whip"]},
}
## Damage vs small / medium / large monsters, % per weapon type.
const SIZE_MOD := {"sword": [75, 100, 75], "greatsword": [75, 75, 100], "spear": [75, 75, 100], "dagger": [100, 75, 50],
	"katar": [75, 100, 75], "axe": [50, 75, 100], "mace": [75, 100, 100], "staff": [100, 100, 100], "book": [100, 100, 50],
	"bow": [100, 100, 75], "knuckle": [100, 100, 75], "whip": [75, 100, 50], "instrument": [75, 100, 75], "none": [100, 100, 100]}
const SIZE_NAMES := ["Small", "Medium", "Large"]


static func weapon_type(id: String) -> String:
	if id == "":
		return "none"
	var it := info(id)
	if it.has("wtype"):
		return String(it.wtype)
	return String(SPRITE_WTYPE.get(String(it.get("sprite", "")), "sword"))


static func weapon_types_for(job_id: String, tier: int, branch: String) -> Array:
	var rule = JOB_WEAPONS.get(job_id, JOB_WEAPONS.novice)
	if rule is Array:
		return rule
	if tier <= 1:
		return rule["1"]
	return rule.get(branch, rule["1"])


## % damage of a weapon type against a monster size (0 small, 1 medium, 2 large).
static func size_mod(wtype: String, size_class: int) -> float:
	var row: Array = SIZE_MOD.get(wtype, [100, 100, 100])
	return float(row[clampi(size_class, 0, 2)]) / 100.0


## Equipment slots in display order.
const SLOTS := ["weapon", "shield", "head", "armor", "garment", "gloves", "boots", "accessory"]
const SLOT_NAMES := {"weapon": "Weapon", "shield": "Shield", "head": "Headgear", "armor": "Armor", "garment": "Garment",
	"gloves": "Gloves", "boots": "Boots", "accessory": "Accessory"}

static var _icons := {}


static func slot_of(id: String) -> String:
	var it := info(id)
	if it.type == "weapon":
		return "weapon"
	return it.get("slot", "armor") if it.type == "armor" else ""


static func is_gear(id: String) -> bool:
	return slot_of(id) != ""


## Stats line for tooltips: "ATK 25 · CRIT +3 · INT +1".
static func stat_text(id: String) -> String:
	var it := info(id)
	var parts: PackedStringArray = []
	if it.get("type", "") == "weapon":
		parts.append(TranslationServer.translate(WEAPON_TYPE_NAMES.get(weapon_type(id), "Weapon")))
	if it.get("atk", 0) > 0:
		parts.append("ATK %d" % it.atk)
	if it.get("def", 0) > 0:
		parts.append("DEF %d" % it.def)
	var b: Dictionary = it.get("bonus", {})
	for k in b:
		var v: int = int(b[k])
		parts.append("%s %s%d%s" % [TranslationServer.translate(SkillDB.BONUS_LABEL.get(k, k)), "+" if v >= 0 else "", v,
			"%" if k in SkillDB.PCT_KEYS else ""])
	if it.get("two_hand", false):
		parts.append(TranslationServer.translate("Two-handed"))
	return "  ·  ".join(parts)


static func info(id: String) -> Dictionary:
	return DB.get(id, {"name": id, "type": "etc", "price": 0, "weight": 0, "desc": ""})


static func item_name(id: String) -> String:
	return TranslationServer.translate(info(id).name)


static func desc(id: String) -> String:
	return TranslationServer.translate(info(id).desc)


## Item icon texture. After the first frame it shows the item's 3D voxel model
## (see ItemModels); flat_icon() is the underlying pixel art.
static func icon(id: String) -> Texture2D:
	var fresh := not _icons.has(id)
	var tex := flat_icon(id)
	if fresh:
		ItemModels.register(id, tex)
	return tex


static func flat_icon(id: String) -> Texture2D:
	if _icons.has(id):
		return _icons[id]
	if id in ["warp_short", "warp_long", "guarantee_stone"]:
		var im := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		im.fill(Color.TRANSPARENT)
		var color := Color(0.4, 0.9, 1.0) if id == "warp_short" else Color(0.75, 0.45, 1.0)
		if id == "guarantee_stone":
			color = Color(1.0, 0.8, 0.2)
		for y in range(2, 14):
			for x in range(2, 14):
				if absi(x - 8) + absi(y - 8) <= 6:
					im.set_pixel(x, y, color.lightened(0.35) if x < 8 else color.darkened(0.2))
		_icons[id] = ImageTexture.create_from_image(im)
		return _icons[id]
	var path := "res://assets/icons/items/%s.png" % id
	if ResourceLoader.exists(path):
		var t := load(path) as Texture2D
		if t:
			var im := t.get_image()
			if im:
				if im.is_compressed():
					im.decompress()
				var it := ImageTexture.create_from_image(im)
				_icons[id] = it
				return it
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if info(id).has("sprite"):
		# weapon sprites already carry their own outline: use them as-is at 32 px
		var wt := ImageTexture.create_from_image(Avatar.weapon_image(info(id).sprite, 32))
		_icons[id] = wt
		return wt
	elif id == "traveler_clothes" or info(id).has("tint"):
		var tint: Color = info(id).get("tint", Color(0.75, 0.62, 0.45))
		for y in 16:
			for x in 16:
				img.set_pixel(x, y, _paint("knight_plate", x, y) * tint if _paint("knight_plate", x, y).a > 0 else Color(0, 0, 0, 0))
	elif info(id).has("icon"):
		var ic: Array = info(id).icon
		for y in 16:
			for x in 16:
				img.set_pixel(x, y, _gather_icon(String(ic[0]), ic[1], x, y))
	elif id == "iron_ore":
		for y in 16:
			for x in 16:
				var d := Vector2((x - 7.5) * 0.9, (y - 8.5) * 1.2).length()
				img.set_pixel(x, y, Color(0, 0, 0, 0) if d > 6.0 else (Color(0.85, 0.6, 0.45) if (x * 7 + y * 3) % 9 == 0 else Color(0.45, 0.45, 0.5).lightened(0.15 if x < 7 and y < 8 else 0.0)))
	else:
		for y in 16:
			for x in 16:
				img.set_pixel(x, y, _paint(id, x, y))
	# dark outline around the shape
	var out := img.duplicate()
	for y in 16:
		for x in 16:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < 16 and q.y < 16 and img.get_pixel(q.x, q.y).a > 0.0:
					out.set_pixel(x, y, Color(0.12, 0.1, 0.12, 1))
					break
	var tex := ImageTexture.create_from_image(out)
	_icons[id] = tex
	return tex


## Icons for mined / fished materials: ore lump, cut gem, fish, scale, pearl, necklace.
static func _gather_icon(kind: String, c: Color, x: int, y: int) -> Color:
	var none := Color(0, 0, 0, 0)
	match kind:
		"ore":
			var d := Vector2((x - 7.5) * 0.9, (y - 8.5) * 1.15).length() + PixelTex.h(x, y, 21) * 0.8
			if d > 6.3:
				return none
			var rock := Color(0.42, 0.4, 0.42).lightened(0.12 if x < 8 and y < 8 else 0.0)
			if (x * 5 + y * 3) % 7 == 0 or (x * 3 + y * 7) % 11 == 1:
				return c.lightened(0.25) if x < 8 else c
			return rock
		"gem":
			var dx := absf(x - 7.5)
			var dy := y - 2.5
			if dy < 0 or dy > 11:
				return none
			var half := 6.5 if dy <= 3 else 6.5 * (1.0 - (dy - 3.0) / 8.5)
			if dy <= 3 and dx > 3.0 + dy:
				return none
			if dx > half:
				return none
			if dy < 1.5:
				return c.lightened(0.45)
			return c.lightened(0.25) if x < 8 else c.darkened(0.15)
		"fish":
			var fx := x - 6.5
			var fy := y - 8.0
			var body := Vector2(fx / 6.0, fy / 3.4).length() < 1.0
			var tail := x >= 12 and x <= 15 and absf(fy) <= (x - 11.0) * 0.9
			if not body and not tail:
				return none
			if x == 3 and y == 7:
				return Color(0.08, 0.08, 0.1)
			if tail:
				return c.darkened(0.2)
			return c.lightened(0.3) if fy < -1.0 else (c.darkened(0.1) if fy > 1.5 else c)
		"scale":
			var d := Vector2(x - 7.5, (y - 8.0) * 1.2).length()
			if d > 6.0 or y < 3:
				return none
			return c.lightened(0.3) if (x + y) % 4 == 0 else c
		"pearl":
			var d := Vector2(x - 7.5, y - 8.5).length()
			if d > 5.0:
				return none
			if Vector2(x - 6.0, y - 7.0).length() < 1.5:
				return Color(1, 1, 1)
			return c.darkened(0.12) if d > 3.8 else c
		"necklace":
			var d := Vector2(x - 7.5, (y - 6.0) * 1.1).length()
			if absf(d - 5.0) < 0.8 and y >= 4:
				return c if (x + y) % 2 == 0 else Color(0.75, 0.78, 0.85)
			if Vector2(x - 7.5, y - 12.0).length() < 1.8:
				return c.lightened(0.2)
			return none
	return none


static func _bottle(x: int, y: int, c: Color) -> Color:
	if y >= 2 and y <= 4 and x >= 7 and x <= 8:
		return Color(0.65, 0.45, 0.3) if y == 2 else Color(0.85, 0.88, 0.95)
	var d := Vector2(x - 7.5, y - 10.0).length()
	if d < 4.6:
		if d < 1.6 and x < 7 and y < 10:
			return Color(1, 1, 1)
		return c.darkened(0.25) if y > 12 else c
	if y == 5 and x >= 6 and x <= 9:
		return Color(0.85, 0.88, 0.95)
	return Color(0, 0, 0, 0)


static func _blob(x: int, y: int, c: Color) -> Color:
	var d := Vector2((x - 7.5) * 0.85, (y - 9.5) * 1.15).length()
	if d < 5.2:
		if (x == 5 or x == 6) and (y == 7 or y == 8):
			return c.lightened(0.5)
		return c if y < 12 else c.darkened(0.2)
	return Color(0, 0, 0, 0)


static func _paint(id: String, x: int, y: int) -> Color:
	match id:
		"potion_red":
			return _bottle(x, y, Color(0.85, 0.15, 0.15))
		"potion_blue":
			return _bottle(x, y, Color(0.2, 0.4, 0.95))
		"slime_gel":
			return _blob(x, y, Color(0.45, 0.85, 0.4))
		"blue_gel":
			return _blob(x, y, Color(0.35, 0.6, 0.98))
		"royal_gel":
			if y <= 4 and (x == 4 or x == 7 or x == 10) and y >= 2:
				return Color(0.95, 0.75, 0.2)
			if y == 5 and x >= 4 and x <= 10:
				return Color(0.95, 0.75, 0.2)
			return _blob(x, y, Color(0.75, 0.42, 0.95))
		"boar_tusk":
			var t := (x - 3) + (12 - y)
			if x >= 3 and x <= 12 and y >= 3 and y <= 13 and absi(y - (14 - int(pow(x - 3, 1.25)))) <= (2 if x < 8 else 1):
				return Color(0.96, 0.93, 0.84).darkened(0.02 * t)
			return Color(0, 0, 0, 0)
		"boar_hide":
			if x >= 3 and x <= 12 and y >= 4 and y <= 12 and not ((x == 3 or x == 12) and (y == 4 or y == 12)):
				return Color(0.42, 0.28, 0.18) if (x + y) % 3 else Color(0.32, 0.21, 0.13)
			return Color(0, 0, 0, 0)
		"feather":
			if absi(x - y) <= 1 and x >= 3 and x <= 12:
				return Color(0.95, 0.95, 0.92) if x != y else Color(0.75, 0.72, 0.68)
			if x + 1 == y and x < 4:
				return Color(0.6, 0.55, 0.5)
			return Color(0, 0, 0, 0)
		"raw_meat":
			if x >= 11 and y <= 4 and x <= 13 and y >= 2:
				return Color(0.95, 0.93, 0.88)
			return _blob(x, y, Color(0.85, 0.3, 0.3))
		"milk":
			return _bottle(x, y, Color(0.97, 0.96, 0.93))
		"ferret_pelt", "wool":
			var fc := Color(0.65, 0.4, 0.3) if id == "ferret_pelt" else Color(0.95, 0.9, 0.8)
			if x >= 3 and x <= 12 and y >= 4 and y <= 12 and not ((x == 3 or x == 12) and (y == 4 or y == 12)):
				return fc if (x + y) % 3 else fc.darkened(0.15)
			return Color(0, 0, 0, 0)
		"mushroom":
			if y >= 4 and y <= 8 and absf(x - 7.5) <= 6.5 - (8 - y) * 0.6:
				return Color(1, 1, 1) if (x * 3 + y) % 5 == 0 else Color(0.85, 0.15, 0.12)
			if y > 8 and y <= 13 and x >= 6 and x <= 9:
				return Color(0.95, 0.92, 0.85)
			return Color(0, 0, 0, 0)
		"goat_horn":
			if x >= 3 and x <= 12 and y >= 3 and y <= 13 and absi(y - (14 - int(pow(x - 3, 1.25)))) <= (2 if x < 8 else 1):
				return Color(0.6, 0.58, 0.56).darkened(0.02 * (x - 3))
			return Color(0, 0, 0, 0)
		"ice_crystal", "spirit_ember", "shadow_shard", "golem_crystal":
			var gc: Color = {"ice_crystal": Color(0.6, 0.88, 1.0), "spirit_ember": Color(1.0, 0.6, 0.2),
				"shadow_shard": Color(0.55, 0.35, 0.9), "golem_crystal": Color(0.3, 0.95, 0.75)}[id]
			var dx := absi(x * 2 - 15)
			if y >= 2 and y <= 13 and dx <= (y - 1) * 2 and dx <= (14 - y) * 3 and dx <= 9:
				return gc.lightened(0.35) if x < 7 and y < 8 else gc
			return Color(0, 0, 0, 0)
		"flower_petal":
			var d2 := Vector2(x - 7.5, y - 7.5)
			if d2.length() < 2.0:
				return Color(1.0, 0.85, 0.2)
			if d2.length() < 6.0 and int((atan2(d2.y, d2.x) + PI) * 5.0 / TAU * 2.0) % 2 == 0:
				return Color(0.98, 0.6, 0.78)
			return Color(0, 0, 0, 0)
		"crystal_sword", "steel_broadsword":
			var blade := Color(0.4, 0.72, 1.0) if id == "crystal_sword" else Color(0.8, 0.82, 0.86)
			if x + y == 15 and x >= 5:
				return blade.lightened(0.3)
			if absi(x + y - 15) <= 1 and x >= 5 and x <= 13:
				return blade
			if (x == 3 and y == 10) or (x == 5 and y == 12) or (x == 4 and y == 11):
				return Color(0.2, 0.22, 0.3)
			if x + y == 15 and x < 5 and x >= 1:
				return Color(0.6, 0.15, 0.18)
			if (x == 2 and y == 9) or (x == 6 and y == 13):
				return Color(0.2, 0.22, 0.3)
			return Color(0, 0, 0, 0)
		"knight_plate", "mithril_plate":
			var c := Color(0.78, 0.8, 0.85) if id == "knight_plate" else Color(0.72, 0.9, 0.95)
			var inside := x >= 3 and x <= 12 and y >= 3 and y <= 13
			if (y == 3 or y == 4) and x >= 6 and x <= 9:
				inside = false
			if y <= 5 and (x <= 3 or x >= 12):
				inside = y >= 3
			if inside:
				return c.lightened(0.15) if x == 7 or x == 8 else c
			return Color(0, 0, 0, 0)
	return Color(0, 0, 0, 0)
