extends Node3D
## Spawns the monster zones around the starter town. Levels rise with the distance
## from the town walls: ring 1 (~55 m) Lv 1-2, ring 2 (~72 m) Lv 3-5,
## ring 3 (~92 m) Lv 6-9, ring 4 (~110 m) Lv 11-18 and a boss far to the west.
## ZONES is also read by the world map and the helper NPC.

const SlimeScript := preload("res://scripts/monsters/slime.gd")
const BoarScript := preload("res://scripts/monsters/boar.gd")
const CritterScript := preload("res://scripts/monsters/critter.gd")

## name, species (slime/boar/beast id), level, count, centre (x, z), radius, aggro range,
## size, drops, colour (slimes)
const ZONES: Array = ROCatalog.ZONES + [
	{"name": "Slime", "species": "slime", "lv": 1, "count": 7, "pos": Vector2(0, 52), "r": 7.0, "aggro": 0.0,
		"drops": [["sandals", 0.02], ["slime_gel", 0.75], ["potion_red", 0.08]], "color": Color(0.45, 0.85, 0.4)},
	{"name": "Duckling", "species": "duck", "lv": 1, "count": 5, "pos": Vector2(-50, 50), "r": 7.0, "aggro": 0.0, "size": 0.9,
		"drops": [["leather_cap", 0.03], ["feather", 0.6], ["potion_red", 0.06]]},
	{"name": "Fancy Chick", "species": "chick", "lv": 2, "count": 5, "pos": Vector2(50, 50), "r": 7.0, "aggro": 0.0, "size": 0.95,
		"drops": [["leather_gloves", 0.03], ["feather", 0.65], ["potion_red", 0.08]]},
	{"name": "Spotted Piglet", "species": "piglet", "lv": 2, "count": 5, "pos": Vector2(58, -12), "r": 7.0, "aggro": 0.0,
		"drops": [["buckler", 0.03], ["raw_meat", 0.55], ["potion_red", 0.1]]},
	{"name": "Blue Slime", "species": "slime", "lv": 3, "count": 5, "pos": Vector2(-62, -30), "r": 7.0, "aggro": 6.0,
		"drops": [["armor_stone", 0.04], ["sage_ring", 0.01], ["blue_gel", 0.7], ["slime_gel", 0.3], ["potion_blue", 0.06]], "color": Color(0.35, 0.6, 0.98)},
	{"name": "Cinnamon Ferret", "species": "ferret", "lv": 4, "count": 5, "pos": Vector2(-36, -70), "r": 7.0, "aggro": 7.0,
		"drops": [["weapon_stone", 0.05], ["thief_gloves", 0.015], ["ferret_pelt", 0.5], ["raw_meat", 0.3], ["iron_ore", 0.08]], "speed": 1.25},
	{"name": "Dairy Calf", "species": "calf", "lv": 4, "count": 4, "pos": Vector2(30, -72), "r": 8.0, "aggro": 0.0, "hp": 1.3,
		"drops": [["wool_muffler", 0.03], ["milk", 0.5], ["raw_meat", 0.35]]},
	{"name": "Sooty Piglet", "species": "sooty", "lv": 5, "count": 5, "pos": Vector2(74, 38), "r": 7.0, "aggro": 6.0,
		"drops": [["leather_boots", 0.03], ["armor_stone", 0.04], ["raw_meat", 0.6], ["potion_red", 0.12]]},
	{"name": "Wild Boar", "species": "boar", "lv": 6, "count": 4, "pos": Vector2(-94, 8), "r": 9.0, "aggro": 6.0,
		"drops": [["weapon_stone", 0.08], ["power_ring", 0.015], ["boar_hide", 0.6], ["boar_tusk", 0.45], ["iron_ore", 0.18], ["potion_red", 0.15]]},
	{"name": "Shroom Hen", "species": "shroomhen", "lv": 7, "count": 5, "pos": Vector2(-64, 72), "r": 8.0, "aggro": 6.0,
		"drops": [["feather_bonnet", 0.02], ["armor_stone", 0.06], ["mushroom", 0.55], ["feather", 0.4]]},
	{"name": "Woolly Calf", "species": "woolly", "lv": 8, "count": 4, "pos": Vector2(62, 76), "r": 8.0, "aggro": 0.0, "size": 1.15, "hp": 1.4,
		"drops": [["wool_muffler", 0.04], ["armor_stone", 0.06], ["wool", 0.6], ["milk", 0.3], ["raw_meat", 0.3]]},
	{"name": "Dark Goat", "species": "goat", "lv": 9, "count": 4, "pos": Vector2(96, -14), "r": 9.0, "aggro": 7.0, "size": 1.1,
		"drops": [["iron_helm", 0.02], ["weapon_stone", 0.08], ["goat_horn", 0.45], ["raw_meat", 0.4], ["iron_ore", 0.25], ["potion_blue", 0.08]]},
	{"name": "Emperor Penguin", "species": "penguin", "lv": 11, "count": 4, "pos": Vector2(0, -110), "r": 8.0, "aggro": 6.0, "size": 1.1,
		"drops": [["iron_greaves", 0.02], ["armor_stone", 0.1], ["ice_crystal", 0.4], ["feather", 0.5], ["iron_ore", 0.2], ["potion_red", 0.2]]},
	{"name": "Blossom Calf", "species": "blossom", "lv": 12, "count": 4, "pos": Vector2(82, -82), "r": 8.0, "aggro": 6.0, "size": 1.1, "hp": 1.3,
		"drops": [["lucky_rosary", 0.015], ["weapon_stone", 0.1], ["flower_petal", 0.5], ["milk", 0.4]]},
	{"name": "Pale Wisp", "species": "wisp", "lv": 14, "count": 4, "pos": Vector2(-84, -82), "r": 8.0, "aggro": 8.0,
		"drops": [["wizard_hat", 0.02], ["swift_brooch", 0.015], ["weapon_stone", 0.1], ["spirit_ember", 0.45], ["potion_blue", 0.2]]},
	{"name": "Shade Imp", "species": "imp", "lv": 16, "count": 4, "pos": Vector2(-82, 88), "r": 8.0, "aggro": 8.0, "size": 1.1,
		"drops": [["shadow_mantle", 0.02], ["shadow_garb", 0.015], ["armor_stone", 0.12], ["shadow_shard", 0.45], ["iron_ore", 0.3], ["potion_blue", 0.2], ["potion_red", 0.2]]},
	{"name": "Crystal Golem", "species": "golem", "lv": 18, "count": 3, "pos": Vector2(84, 88), "r": 8.0, "aggro": 7.0, "size": 1.35, "hp": 1.6, "speed": 0.8,
		"drops": [["iron_gauntlets", 0.025], ["tower_shield", 0.015], ["wind_boots", 0.01], ["weapon_stone", 0.15], ["armor_stone", 0.15], ["golem_crystal", 0.45], ["iron_ore", 0.6], ["mithril_plate", 0.03], ["potion_red", 0.3]]},
	{"name": "King Slime", "species": "slime", "lv": 20, "count": 1, "pos": Vector2(-116, -20), "r": 4.0, "aggro": 8.0, "boss": true,
		"drops": [["royal_crown", 0.25], ["ruby_amulet", 0.3], ["weapon_stone", 1.0, 2], ["armor_stone", 1.0, 2], ["royal_gel", 1.0], ["steel_broadsword", 0.3], ["potion_blue", 1.0, 2], ["potion_red", 1.0, 3]], "color": Color(0.72, 0.4, 0.95)},
	# ================================================================ Verdant Ruins (west portal)
	{"name": "Moss Toad", "species": "moss_toad", "area": "verdant", "lv": 21, "count": 7, "pos": Vector2(1060, 30), "r": 10.0, "aggro": 0.0, "size": 1.1,
		"drops": [["moss_clump", 0.55], ["armor_stone", 0.1], ["potion_red", 0.25], ["ranger_hood", 0.008]]},
	{"name": "Vine Lurker", "species": "vine_lurker", "area": "verdant", "lv": 23, "count": 6, "pos": Vector2(1020, -45), "r": 10.0, "aggro": 7.0,
		"drops": [["living_vine", 0.5], ["weapon_stone", 0.1], ["vine_bow", 0.006], ["moss_cloak", 0.006], ["potion_blue", 0.15]]},
	{"name": "Jade Raptor", "species": "jade_raptor", "area": "verdant", "lv": 25, "count": 6, "pos": Vector2(980, 40), "r": 11.0, "aggro": 8.0, "speed": 1.2,
		"drops": [["jade_scale", 0.5], ["raw_meat", 0.4], ["jade_blade", 0.005], ["weapon_stone", 0.12], ["potion_red", 0.25]]},
	{"name": "Ruin Sentinel", "species": "ruin_sentinel", "area": "verdant", "lv": 27, "count": 5, "pos": Vector2(945, -10), "r": 8.0, "aggro": 7.0, "speed": 0.8, "hp": 1.4,
		"drops": [["rune_stone", 0.45], ["iron_ore", 0.4], ["armor_stone", 0.15], ["druid_staff", 0.005], ["potion_red", 0.3]]},
	{"name": "Great Moss Toad", "species": "great_moss_toad", "area": "verdant", "lv": 32, "count": 1, "pos": Vector2(935, 60), "r": 5.0, "aggro": 9.0, "boss": true, "size": 2.4,
		"drops": [["moss_cloak", 0.3], ["ranger_hood", 0.3], ["moss_clump", 1.0, 5], ["weapon_stone", 1.0, 3], ["armor_stone", 1.0, 3], ["potion_red", 1.0, 5]]},
	{"name": "Spore Puff", "species": "spore_puff", "area": "verdant_d", "lv": 29, "count": 5, "pos": Vector2(968, 422), "r": 6.0, "aggro": 7.0,
		"spots": [[Vector2(968, 422), 6.0, 5], [Vector2(976, 380), 6.0, 3]],
		"drops": [["spore_powder", 0.5], ["mushroom", 0.4], ["potion_blue", 0.25], ["druid_staff", 0.008]]},
	{"name": "Root Golem", "species": "root_golem", "area": "verdant_d", "lv": 31, "count": 5, "pos": Vector2(1028, 408), "r": 6.0, "aggro": 7.0, "speed": 0.85, "hp": 1.4,
		"spots": [[Vector2(1028, 408), 6.0, 5], [Vector2(976, 380), 6.0, 2]],
		"drops": [["ancient_bark", 0.45], ["armor_stone", 0.15], ["weapon_stone", 0.15], ["jade_blade", 0.008], ["potion_red", 0.3]]},
	{"name": "Ancient Treant", "species": "ancient_treant", "area": "verdant_d", "lv": 35, "count": 1, "pos": Vector2(1008, 350), "r": 4.0, "aggro": 10.0, "boss": true, "size": 2.2,
		"drops": [["treant_heart", 1.0], ["druid_staff", 0.35], ["jade_blade", 0.35], ["vine_bow", 0.35], ["weapon_stone", 1.0, 4], ["armor_stone", 1.0, 4], ["potion_blue", 1.0, 4]]},
	# ================================================================ Sunscorch Desert (south portal)
	{"name": "Sand Scarab", "species": "sand_scarab", "area": "desert", "lv": 29, "count": 7, "pos": Vector2(1435, -45), "r": 10.0, "aggro": 6.0,
		"drops": [["scarab_shell", 0.5], ["armor_stone", 0.12], ["scarab_shield", 0.005], ["potion_red", 0.3]]},
	{"name": "Dune Lizard", "species": "dune_lizard", "area": "desert", "lv": 31, "count": 6, "pos": Vector2(1355, -35), "r": 11.0, "aggro": 7.0, "speed": 1.2,
		"drops": [["lizard_scale", 0.5], ["raw_meat", 0.4], ["sand_boots", 0.006], ["weapon_stone", 0.12]]},
	{"name": "Cactus Brute", "species": "cactus_brute", "area": "desert", "lv": 33, "count": 5, "pos": Vector2(1355, 40), "r": 10.0, "aggro": 6.0, "hp": 1.3, "speed": 0.9,
		"drops": [["cactus_needle", 0.5], ["armor_stone", 0.15], ["desert_robe", 0.005], ["potion_red", 0.3]]},
	{"name": "Dust Djinn", "species": "dust_djinn", "area": "desert", "lv": 35, "count": 5, "pos": Vector2(1450, 20), "r": 10.0, "aggro": 8.0,
		"drops": [["djinn_sand", 0.45], ["potion_blue", 0.3], ["sun_scimitar", 0.005], ["weapon_stone", 0.15]]},
	{"name": "Scorpion Lord", "species": "scorpion_lord", "area": "desert", "lv": 40, "count": 1, "pos": Vector2(1468, 70), "r": 5.0, "aggro": 9.0, "boss": true, "size": 2.3,
		"drops": [["scorpion_stinger", 1.0], ["scorpion_dagger", 0.4], ["sand_boots", 0.3], ["weapon_stone", 1.0, 3], ["armor_stone", 1.0, 3], ["potion_red", 1.0, 6]]},
	{"name": "Tomb Jackal", "species": "tomb_jackal", "area": "desert_d", "lv": 37, "count": 5, "pos": Vector2(1368, 422), "r": 6.0, "aggro": 8.0, "speed": 1.25,
		"spots": [[Vector2(1368, 422), 6.0, 5], [Vector2(1376, 380), 6.0, 3]],
		"drops": [["jackal_fang", 0.5], ["weapon_stone", 0.15], ["scorpion_dagger", 0.006], ["potion_red", 0.3]]},
	{"name": "Wrapped Guardian", "species": "wrapped_guardian", "area": "desert_d", "lv": 39, "count": 5, "pos": Vector2(1428, 408), "r": 6.0, "aggro": 7.0, "hp": 1.3,
		"spots": [[Vector2(1428, 408), 6.0, 5], [Vector2(1376, 380), 6.0, 2]],
		"drops": [["mummy_wrap", 0.5], ["armor_stone", 0.15], ["desert_robe", 0.008], ["potion_blue", 0.3]]},
	{"name": "Sun Pharaoh", "species": "sun_pharaoh", "area": "desert_d", "lv": 43, "count": 1, "pos": Vector2(1408, 350), "r": 4.0, "aggro": 10.0, "boss": true, "size": 2.1,
		"drops": [["pharaoh_gold", 1.0], ["pharaoh_mask", 0.35], ["sun_scimitar", 0.35], ["desert_robe", 0.35], ["weapon_stone", 1.0, 4], ["armor_stone", 1.0, 4], ["potion_blue", 1.0, 5]]},
	# ================================================================ Frostpeak Glacier (east portal)
	{"name": "Snow Hare", "species": "snow_hare", "area": "frost", "lv": 37, "count": 7, "pos": Vector2(1745, 32), "r": 10.0, "aggro": 0.0, "speed": 1.3,
		"drops": [["snow_fur", 0.55], ["raw_meat", 0.4], ["potion_red", 0.3]]},
	{"name": "Frost Wolf", "species": "frost_wolf", "area": "frost", "lv": 39, "count": 6, "pos": Vector2(1780, -45), "r": 11.0, "aggro": 9.0, "speed": 1.25,
		"drops": [["wolf_fang", 0.5], ["snow_fur", 0.3], ["weapon_stone", 0.15], ["frost_gauntlets", 0.005]]},
	{"name": "Ice Golem", "species": "ice_golem", "area": "frost", "lv": 41, "count": 5, "pos": Vector2(1830, 40), "r": 9.0, "aggro": 7.0, "speed": 0.8, "hp": 1.4,
		"drops": [["frost_core", 0.45], ["ice_crystal", 0.5], ["armor_stone", 0.18], ["glacier_mace", 0.005]]},
	{"name": "Shaggy Yeti", "species": "shaggy_yeti", "area": "frost", "lv": 43, "count": 5, "pos": Vector2(1862, -12), "r": 10.0, "aggro": 8.0, "hp": 1.2,
		"drops": [["yeti_horn", 0.45], ["snow_fur", 0.4], ["yeti_coat", 0.005], ["weapon_stone", 0.18], ["potion_red", 0.35]]},
	{"name": "Mammoth Tusker", "species": "mammoth_tusker", "area": "frost", "lv": 48, "count": 1, "pos": Vector2(1862, 66), "r": 5.0, "aggro": 9.0, "boss": true, "size": 2.2,
		"drops": [["mammoth_tusk", 1.0], ["yeti_coat", 0.35], ["frost_axe", 0.3], ["weapon_stone", 1.0, 4], ["armor_stone", 1.0, 4], ["potion_red", 1.0, 6]]},
	# big boss from voxel_dragon.blend: lair on the open snowfield east of the yetis
	{"name": "Frost Dragon King", "species": "frost_dragon_king", "area": "frost", "lv": 55, "count": 1, "pos": Vector2(1875, 17), "r": 9.0, "aggro": 12.0, "boss": true, "hp": 3.0, "speed": 0.85,
		"drops": [["wyrm_scale", 1.0, 2], ["frost_core", 1.0, 3], ["ice_crystal", 1.0, 5], ["wyrm_shield", 0.5], ["frost_axe", 0.45], ["glacier_mace", 0.45],
			["weapon_stone", 1.0, 8], ["armor_stone", 1.0, 8], ["potion_blue", 1.0, 8], ["potion_red", 1.0, 8]]},
	{"name": "Frost Wisp", "species": "frost_wisp", "area": "frost_d", "lv": 45, "count": 5, "pos": Vector2(1768, 422), "r": 6.0, "aggro": 8.0,
		"spots": [[Vector2(1768, 422), 6.0, 5], [Vector2(1776, 380), 6.0, 3]],
		"drops": [["ice_crystal", 0.6], ["frost_core", 0.25], ["potion_blue", 0.35], ["glacier_mace", 0.008]]},
	{"name": "Crystal Bat", "species": "crystal_bat", "area": "frost_d", "lv": 47, "count": 5, "pos": Vector2(1828, 408), "r": 6.0, "aggro": 9.0, "speed": 1.3,
		"spots": [[Vector2(1828, 408), 6.0, 5], [Vector2(1776, 380), 6.0, 2]],
		"drops": [["bat_wing", 0.5], ["weapon_stone", 0.18], ["frost_gauntlets", 0.008], ["potion_red", 0.35]]},
	{"name": "Glacier Wyrm", "species": "glacier_wyrm", "area": "frost_d", "lv": 52, "count": 1, "pos": Vector2(1808, 350), "r": 4.0, "aggro": 10.0, "boss": true, "size": 1.9,
		"drops": [["wyrm_scale", 1.0], ["wyrm_shield", 0.35], ["frost_axe", 0.35], ["glacier_mace", 0.35], ["weapon_stone", 1.0, 5], ["armor_stone", 1.0, 5], ["potion_blue", 1.0, 6]]},
	# ================================================================ Emberfall Volcano (from Verdant / Frostpeak)
	{"name": "Magma Slime", "species": "slime", "area": "ember", "lv": 46, "count": 7, "pos": Vector2(2150, 48), "r": 10.0, "aggro": 6.0, "color": Color(1.0, 0.45, 0.12),
		"drops": [["magma_gel", 0.6], ["potion_red", 0.35], ["armor_stone", 0.15]]},
	{"name": "Ember Salamander", "species": "ember_salamander", "area": "ember", "lv": 48, "count": 6, "pos": Vector2(2240, 55), "r": 11.0, "aggro": 7.0, "speed": 1.2,
		"drops": [["salamander_tail", 0.5], ["weapon_stone", 0.18], ["ember_ring", 0.005], ["potion_red", 0.35]]},
	{"name": "Obsidian Brute", "species": "obsidian_brute", "area": "ember", "lv": 50, "count": 5, "pos": Vector2(2155, -30), "r": 9.0, "aggro": 7.0, "hp": 1.4, "speed": 0.85,
		"drops": [["obsidian_shard", 0.5], ["iron_ore", 0.5], ["armor_stone", 0.2], ["obsidian_plate", 0.004]]},
	{"name": "Flame Imp", "species": "flame_imp", "area": "ember", "lv": 52, "count": 5, "pos": Vector2(2255, -15), "r": 10.0, "aggro": 9.0, "speed": 1.15,
		"drops": [["imp_horn", 0.5], ["potion_blue", 0.35], ["magma_staff", 0.005], ["weapon_stone", 0.2]]},
	{"name": "Cinder Phoenix", "species": "cinder_phoenix", "area": "ember", "lv": 56, "count": 1, "pos": Vector2(2130, -70), "r": 5.0, "aggro": 10.0, "boss": true, "size": 1.9,
		"drops": [["phoenix_feather", 1.0], ["phoenix_bow", 0.35], ["ember_ring", 0.3], ["weapon_stone", 1.0, 5], ["armor_stone", 1.0, 5], ["potion_red", 1.0, 8]]},
	{"name": "Lava Golem", "species": "lava_golem", "area": "ember_d", "lv": 54, "count": 5, "pos": Vector2(2168, 422), "r": 6.0, "aggro": 8.0, "speed": 0.85, "hp": 1.4,
		"spots": [[Vector2(2168, 422), 6.0, 5], [Vector2(2176, 380), 6.0, 3]],
		"drops": [["lava_core", 0.5], ["iron_ore", 0.5], ["armor_stone", 0.2], ["inferno_sword", 0.006]]},
	{"name": "Ash Wraith", "species": "ash_wraith", "area": "ember_d", "lv": 56, "count": 5, "pos": Vector2(2228, 408), "r": 6.0, "aggro": 9.0,
		"spots": [[Vector2(2228, 408), 6.0, 5], [Vector2(2176, 380), 6.0, 2]],
		"drops": [["ash_cloth", 0.5], ["potion_blue", 0.4], ["magma_staff", 0.008], ["weapon_stone", 0.2]]},
	{"name": "Inferno Drake", "species": "inferno_drake", "area": "ember_d", "lv": 60, "count": 1, "pos": Vector2(2208, 350), "r": 4.0, "aggro": 10.0, "boss": true, "size": 1.9,
		"drops": [["drake_heart", 1.0], ["drake_helm", 0.35], ["inferno_sword", 0.35], ["obsidian_plate", 0.3], ["weapon_stone", 1.0, 6], ["armor_stone", 1.0, 6], ["potion_red", 1.0, 10]]},
	{"name": "Hobo", "species": "hobo", "area": "ember", "lv": 53, "count": 4, "pos": Vector2(2186, 33), "r": 5.0, "aggro": 8.0, "size": 1.2, "hp": 1.18, "speed": 0.9,
		"spots": [[Vector2(2186, 33), 5.0, 2], [Vector2(2233, 17), 5.0, 2]],
		"drops": [["obsidian_shard", 0.55], ["lava_core", 0.22], ["armor_stone", 0.2], ["potion_red", 0.35]]},
]

@export var enabled := true

var _spawned := {}
var _area_t := 0.0
var _last_area := ""


func _ready() -> void:
	add_to_group("spawner")
	if Engine.is_editor_hint() or not enabled:
		return
	call_deferred("_spawn_all")


static func level_range_text(z: Dictionary) -> String:
	return "Lv %d" % z.lv


static func zone_area(z: Dictionary) -> String:
	return String(z.get("area", "town"))


func _spawn_all() -> void:
	spawn_area("town")


## Monsters of one map are created the first time that map is built.
func spawn_area(area: String) -> void:
	if _spawned.has(area):
		return
	_spawned[area] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 + area.hash() % 1000
	for z in ZONES:
		if zone_area(z) != area:
			continue
		var spots: Array = z.get("spots", [[z.pos, z.r, z.count]])
		for sp in spots:
			for i in int(sp[2]):
				var m := _make(z)
				_stats(m, z)
				m.set_meta("area", area)
				var c := Vector3(sp[0].x, 0, sp[0].y)
				_spawn(m, _around(rng, c, float(sp[1])) if int(z.count) > 1 else c + Vector3(0, 0.3, 0))


## Only the map the player stands in runs its monsters.
func _process(delta: float) -> void:
	_area_t -= delta
	if _area_t > 0.0:
		return
	_area_t = 0.5
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return
	var a := VillageBuilder.area_at(p.global_position)
	if a.begins_with("guild"):
		a = "town"
	if a == _last_area:
		return
	_last_area = a
	for m in get_children():
		var ma := String(m.get_meta("area", "town"))
		m.process_mode = Node.PROCESS_MODE_INHERIT if ma == a else Node.PROCESS_MODE_DISABLED
		(m as Node3D).visible = ma == a


func _make(z: Dictionary) -> Monster:
	match z.species:
		"slime":
			var s: Monster = SlimeScript.new()
			s.color = z.color
			if zone_area(z) != "town":
				s.size = 1.3
			if z.get("boss", false):
				s.crown = true
				s.size = 2.2
				s.attack_range = 2.6
				s.respawn_time = 40.0
			return s
		"boar":
			return BoarScript.new()
		"hobo":
			return preload("res://scripts/monsters/hobo.gd").new()
		"frost_dragon_king":
			return FrostDragonBoss.new()
	var c: Monster = CritterScript.new()
	c.species = z.species
	c.attack_range = 1.5
	c.attack_time = 1.0
	c.hit_time = 0.55
	c.attack_cooldown = 1.6
	var sz := {"duck": [0.32, 0.6], "chick": [0.3, 0.6], "piglet": [0.4, 0.75], "sooty": [0.4, 0.75], "calf": [0.5, 1.0],
		"woolly": [0.5, 1.0], "blossom": [0.5, 1.0], "ferret": [0.3, 0.45], "shroomhen": [0.34, 0.7], "goat": [0.45, 1.1],
		"penguin": [0.4, 1.3], "wisp": [0.45, 1.6], "imp": [0.4, 1.4], "golem": [0.6, 1.8]}
	var d: Array = ROCatalog.dims(z.species) if ROCatalog.SPECIES.has(z.species) else (ZoneBeasts.dims(z.species) if ZoneBeasts.has(z.species) else sz.get(z.species, [0.45, 0.9]))
	c.body_radius = d[0]
	c.body_height = d[1]
	if ZoneBeasts.has(z.species) or ROCatalog.SPECIES.has(z.species):
		c.attack_range = 1.3 + d[0] * float(z.get("size", 1.0)) * 1.2
		if z.get("boss", false):
			c.respawn_time = 120.0 if zone_area(z).ends_with("_d") else 90.0
			c.attack_cooldown = 1.3
	return c


## Stats grow with level (RO-like curve); zones can scale HP / speed.
func _stats(m: Monster, z: Dictionary) -> void:
	var lv: int = z.lv
	var boss: bool = z.get("boss", false)
	m.display_name = z.name
	m.level = lv
	# HP grows a little slower past Lv 20 so the outer regions stay brisk
	var quad := 3.0 - clampf((lv - 20) / 40.0, 0.0, 1.0)
	m.max_hp = int((30 + lv * 26 + lv * lv * quad) * float(z.get("hp", 1.0)) * (6.0 if boss else 1.0))
	m.damage_min = int(3 + lv * 2.2 * (1.3 if boss else 1.0))
	m.damage_max = int(6 + lv * 3.0 * (1.3 if boss else 1.0))
	m.def = lv / 2 + (4 if boss else 0)
	m.hit = 14 + lv * 4
	m.flee = 3 + lv * 2
	m.exp_reward = int(18.0 * pow(lv, 1.45) * (8.0 if boss else 1.0))
	m.aggro_range = z.aggro
	if boss:
		m.set_meta("boss", true)
	m.drops = z.drops
	var sp: float = z.get("speed", 1.0)
	m.move_speed = 1.5 * sp
	m.chase_speed = (2.6 + lv * 0.06) * sp
	if z.has("size"):
		m.size = z.size
	m.wander_radius = z.r
	m.leash_range = z.r + 16.0


func _around(rng: RandomNumberGenerator, c: Vector3, r: float) -> Vector3:
	var a := rng.randf() * TAU
	var d := sqrt(rng.randf()) * r
	return c + Vector3(cos(a) * d, 0.3, sin(a) * d)


func _spawn(m: Monster, pos: Vector3) -> void:
	m.position = pos
	add_child(m)
