class_name SkillDB
extends RefCounted
## Skills modelled on Ragnarok Online: names, levels, SP, cast times, delays and prerequisites.
## type: passive / melee / bolt / aoe_self / aoe_target / heal / buff / steal
## sp = sp0 + sp1 * level.  Effects are applied by the player (player.gd) and the
## stat bonuses by the Game autoload (game_state.gd).

const SKILLS := {
	# Numbers follow Ragnarok Online (pre-renewal) where the game can express them.
	# Per-level tables: "sp", "dmg" (%), "cast" (s), "cd" (after-cast delay, s), "time" (s), "hits_t".
	# Otherwise sp = sp0 + sp1*lv, dmg = base + per*lv, cast = cast0 + cast1*lv, time = time0 + time1*lv.
	# Cast time shrinks with DEX like Ragnarok: cast * (1 - DEX/150).
	# "bonus": {KEY: per-level} or {KEY: [base, per-level]}.
	# ================================================================ Swordsman
	"sword_mastery": {"name": "Sword Mastery", "job": "swordsman", "type": "passive", "max": 10, "icon": "sword",
		"desc": "Increases ATK with daggers and one-handed swords.", "fx": "ATK +%d", "per": 4},
	"hp_recovery": {"name": "Increase HP Recovery", "job": "swordsman", "type": "passive", "max": 10, "icon": "heart",
		"desc": "Recover more HP over time.", "fx": "HP regen +%d%%", "per": 10},
	"bash": {"name": "Bash", "job": "swordsman", "type": "melee", "max": 10, "sp": [8, 8, 8, 8, 8, 15, 15, 15, 15, 15], "icon": "bash",
		"desc": "A crushing blow on one enemy.", "fx": "Damage %d%%", "base": 100, "per": 30, "cd": 0.6},
	"magnum_break": {"name": "Magnum Break", "job": "swordsman", "type": "aoe_self", "max": 10, "sp0": 30, "sp1": 0, "icon": "fire",
		"desc": "A fire blast that hits every enemy around you.", "fx": "Damage %d%%", "base": 100, "per": 20, "radius": 2.5,
		"color": Color(1.0, 0.5, 0.15), "cd": 2.0, "req": {"bash": 5}},
	"endure": {"name": "Endure", "job": "swordsman", "type": "buff", "max": 10, "sp0": 10, "sp1": 0.0, "icon": "shield",
		"desc": "Keep fighting through hits: MDEF up for a while.", "fx": "DEF +%d", "per": 2, "time0": 7, "time1": 3, "cd": 10.0,
		"req": {"hp_recovery": 5}},
	# ---------------------------------------------------------------- Archer
	"owls_eye": {"name": "Owl's Eye", "job": "archer", "type": "passive", "max": 10, "icon": "star",
		"desc": "Sharper eyes: DEX up.", "fx": "DEX +%d", "per": 1},
	"vultures_eye": {"name": "Vulture's Eye", "job": "archer", "type": "passive", "max": 10, "icon": "bow",
		"desc": "Longer range and better aim with bows.", "fx": "Range +%d, HIT +%d", "per": 1, "req": {"owls_eye": 3}},
	"improve_concentration": {"name": "Improve Concentration", "job": "archer", "type": "buff", "max": 10, "sp0": 20, "sp1": 5, "icon": "star",
		"desc": "Focus: AGI and DEX up for a while.", "fx": "AGI/DEX +%d", "per": 1, "base": 1, "time0": 40, "time1": 20,
		"req": {"vultures_eye": 1}},
	"double_strafe": {"name": "Double Strafe", "job": "archer", "type": "bolt", "max": 10, "sp0": 12, "sp1": 0.0, "icon": "bow",
		"desc": "Fire two arrows at once.", "fx": "2 x %d%%", "base": 90, "per": 10, "hits": 2, "proj": "arrow", "cd": 0.5},
	"arrow_shower": {"name": "Arrow Shower", "job": "archer", "type": "aoe_target", "max": 10, "sp0": 15, "sp1": 0.0, "icon": "bow",
		"desc": "Rain arrows on a 5x5 area.", "fx": "Damage %d%% in an area", "base": 80, "per": 5, "radius": 2.5,
		"color": Color(0.9, 0.9, 0.8), "cd": 1.0, "req": {"double_strafe": 5}},
	# ---------------------------------------------------------------- Mage
	"sp_recovery": {"name": "Increase SP Recovery", "job": "mage", "type": "passive", "max": 10, "icon": "drop",
		"desc": "Recover more SP over time.", "fx": "SP regen +%d%%", "per": 10},
	"napalm_beat": {"name": "Napalm Beat", "job": "mage", "type": "aoe_target", "max": 10, "icon": "magic",
		"sp": [9, 9, 9, 12, 12, 12, 15, 15, 15, 18], "cast": [1.0], "cd": [1.0, 0.9, 0.9, 0.8, 0.8, 0.7, 0.7, 0.6, 0.5, 0.5],
		"desc": "A ghost-element blast on the target and the enemies right next to it.", "base": 70, "per": 10, "radius": 1.5,
		"color": Color(0.75, 0.6, 1.0)},
	"soul_strike": {"name": "Soul Strike", "job": "mage", "type": "bolt", "max": 10, "icon": "magic", "proj": "magic",
		"sp": [18, 14, 24, 20, 30, 26, 36, 32, 42, 38], "cast": [0.5], "hits_t": [1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
		"cd": [1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4, 2.6, 2.8, 2.7],
		"desc": "Ghost-element spirit orbs strike one enemy.", "base": 100, "per": 0, "req": {"napalm_beat": 4}},
	"fire_bolt": {"name": "Fire Bolt", "job": "mage", "type": "bolt", "max": 10, "sp0": 10, "sp1": 2, "icon": "fire",
		"desc": "Bolts of fire strike one enemy (1 bolt per level).", "fx": "%d bolts x 100%%", "base": 100, "per": 0, "hits_per_lv": true,
		"proj": "fire", "cast0": 0.0, "cast1": 0.7, "cd0": 0.8, "cd1": 0.2},
	"cold_bolt": {"name": "Cold Bolt", "job": "mage", "type": "bolt", "max": 10, "sp0": 10, "sp1": 2, "icon": "ice",
		"desc": "Bolts of ice strike one enemy (1 bolt per level); may freeze it.", "fx": "%d bolts, freeze %d%%", "base": 100, "per": 0,
		"hits_per_lv": true, "proj": "ice", "cast0": 0.0, "cast1": 0.7, "cd0": 0.8, "cd1": 0.2, "freeze": 3},
	"lightning_bolt": {"name": "Lightning Bolt", "job": "mage", "type": "bolt", "max": 10, "sp0": 10, "sp1": 2, "icon": "bolt",
		"desc": "Bolts of lightning strike one enemy (1 bolt per level).", "fx": "%d bolts x 100%%", "base": 100, "per": 0, "hits_per_lv": true,
		"proj": "lightning", "cast0": 0.0, "cast1": 0.7, "cd0": 0.8, "cd1": 0.2},
	"fire_ball": {"name": "Fire Ball", "job": "mage", "type": "aoe_target", "max": 10, "sp0": 25, "sp1": 0.0, "icon": "fire",
		"desc": "An exploding ball of fire that hits a 5x5 area.", "fx": "Damage %d%% in an area", "base": 70, "per": 10, "radius": 2.5,
		"proj": "fire", "cast": [1.5, 1.5, 1.5, 1.5, 1.5, 1.0, 1.0, 1.0, 1.0, 1.0], "cd": [1.5, 1.5, 1.5, 1.5, 1.5, 1.0, 1.0, 1.0, 1.0, 1.0],
		"color": Color(1.0, 0.45, 0.1), "req": {"fire_bolt": 4}},
	"fire_wall": {"name": "Fire Wall", "job": "mage", "type": "aoe_target", "max": 10, "sp0": 40, "sp1": 0, "icon": "fire",
		"desc": "A wall of flames that burns everything standing in it, again and again.", "base": 50, "per": 0, "hits0": 3, "hits1": 1,
		"radius": 1.6, "cast0": 2.15, "cast1": -0.15, "cd": 1.0, "color": Color(1.0, 0.4, 0.08), "req": {"fire_ball": 5}},
	# ---------------------------------------------------------------- Acolyte
	"heal": {"name": "Heal", "job": "acolyte", "type": "heal", "max": 10, "sp0": 10, "sp1": 3, "icon": "heart",
		"desc": "Restore your HP. Stronger with INT and base level.", "fx": "Heals about %d HP", "cd": 1.0},
	"divine_protection": {"name": "Divine Protection", "job": "acolyte", "type": "passive", "max": 10, "icon": "shield",
		"desc": "The gods shield you: DEF up.", "fx": "DEF +%d", "per": 2},
	"angelus": {"name": "Angelus", "job": "acolyte", "type": "buff", "max": 10, "sp0": 20, "sp1": 3, "icon": "shield",
		"desc": "An angel's blessing hardens your body: DEF up for a while.", "bonus": {"DEF": 2}, "time0": 0, "time1": 30, "cd": 3.5,
		"req": {"divine_protection": 3}},
	"blessing": {"name": "Blessing", "job": "acolyte", "type": "buff", "max": 10, "sp0": 24, "sp1": 4, "icon": "star",
		"desc": "STR, INT and DEX up for a while.", "fx": "STR/INT/DEX +%d", "per": 1, "time0": 40, "time1": 20, "req": {"divine_protection": 5}},
	"increase_agi": {"name": "Increase AGI", "job": "acolyte", "type": "buff", "max": 10, "sp0": 15, "sp1": 3, "icon": "boot",
		"desc": "AGI and move speed up for a while (costs 15 HP).", "fx": "AGI +%d, move +25%%", "per": 1, "base": 2, "time0": 40, "time1": 20,
		"cd": 1.0, "req": {"heal": 3}},
	"holy_light": {"name": "Holy Light", "job": "acolyte", "type": "bolt", "max": 1, "sp0": 15, "sp1": 0.0, "icon": "holy",
		"desc": "A ray of holy light strikes one enemy.", "fx": "Damage %d%%", "base": 125, "per": 0, "hits": 1, "proj": "holy",
		"cast0": 2.0, "cast1": 0.0},
	# ---------------------------------------------------------------- Merchant
	"enlarge_weight": {"name": "Enlarge Weight Limit", "job": "merchant", "type": "passive", "max": 10, "icon": "bag",
		"desc": "Carry more.", "fx": "Weight +%d", "per": 20},
	"discount": {"name": "Discount", "job": "merchant", "type": "passive", "max": 10, "icon": "coin",
		"desc": "Buy items cheaper from shops.", "fx": "Prices -%d%%", "base": 5, "per": 2, "req": {"enlarge_weight": 3}},
	"overcharge": {"name": "Overcharge", "job": "merchant", "type": "passive", "max": 10, "icon": "coin",
		"desc": "Sell items for more Zeny.", "fx": "Sell +%d%%", "base": 5, "per": 2, "req": {"discount": 3}},
	"mammonite": {"name": "Mammonite", "job": "merchant", "type": "melee", "max": 10, "sp0": 5, "sp1": 0.0, "icon": "coin",
		"desc": "Smash an enemy with the power of money (costs Zeny).", "fx": "Damage %d%%, %d Zeny", "base": 100, "per": 50, "zeny": 100, "cd": 0.6},
	"cart_revolution": {"name": "Cart Revolution", "job": "merchant", "type": "aoe_target", "max": 1, "sp0": 12, "sp1": 0.0, "icon": "bag",
		"desc": "Swing your cart into the target and everything around it.", "fx": "Damage %d%% in an area", "base": 150, "per": 0, "radius": 1.6,
		"color": Color(0.85, 0.65, 0.35), "cd": 0.6},
	# ---------------------------------------------------------------- Thief
	"double_attack": {"name": "Double Attack", "job": "thief", "type": "passive", "max": 10, "icon": "dagger",
		"desc": "Chance to strike twice with normal attacks.", "fx": "%d%% chance", "per": 5},
	"improve_dodge": {"name": "Improve Dodge", "job": "thief", "type": "passive", "max": 10, "icon": "boot",
		"desc": "FLEE up.", "fx": "FLEE +%d", "per": 3},
	"envenom": {"name": "Envenom", "job": "thief", "type": "melee", "max": 10, "sp0": 12, "sp1": 0.0, "icon": "poison",
		"desc": "A poisoned strike; may poison the target.", "fx": "Damage %d%%, poison %d%%", "base": 100, "per": 15, "poison": 4, "cd": 0.6},
	"steal": {"name": "Steal", "job": "thief", "type": "steal", "max": 10, "sp0": 10, "sp1": 0.0, "icon": "bag",
		"desc": "Try to steal an item from a monster (once per monster).", "fx": "Success about %d%%", "cd": 1.0},
	"sand_attack": {"name": "Sand Attack", "job": "thief", "type": "melee", "max": 1, "sp0": 9, "sp1": 0, "icon": "poison",
		"desc": "Throw a fistful of sand: earth damage that may blind and stun.", "base": 130, "per": 0, "status": "stun",
		"chance0": 20, "chance1": 0, "stime0": 2.0, "stime1": 0.0, "color": Color(0.85, 0.7, 0.4), "cd": 0.6},
	# ================================================================ 2nd / transcendent jobs, branch A
	# ---------------------------------------------------------------- Knight
	"spear_mastery": {"name": "Spear Mastery", "job": "swordsman", "tier": 2, "type": "passive", "max": 10,
		"desc": "Training with spears: ATK up.", "bonus": {"ATK": 4}},
	"pierce": {"name": "Pierce", "job": "swordsman", "tier": 2, "type": "melee", "max": 10, "sp0": 7, "sp1": 0,
		"desc": "Run the enemy through: 1 hit on small, 2 on medium, 3 on large monsters.", "base": 100, "per": 10, "hits_size": true,
		"cd": 0.6, "req": {"spear_mastery": 1}},
	"brandish_spear": {"name": "Brandish Spear", "job": "swordsman", "tier": 2, "type": "aoe_self", "max": 10, "sp0": 12, "sp1": 0,
		"desc": "A wide sweep of the spear that hits everything in front of and around you.", "base": 100, "per": 20, "radius": 3.0,
		"cast0": 0.7, "cast1": 0.0, "cd": 0.6, "color": Color(0.9, 0.85, 0.6), "req": {"pierce": 3}},
	"bowling_bash": {"name": "Bowling Bash", "job": "swordsman", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 12, "sp1": 1,
		"desc": "Smash the target twice and knock it into the monsters behind it.", "base": 100, "per": 40, "hits": 2, "radius": 1.6,
		"cast0": 0.7, "cast1": 0.0, "cd": 0.8, "color": Color(1.0, 0.75, 0.4), "req": {"bash": 10, "magnum_break": 3, "two_hand_quicken": 1}},
	"two_hand_quicken": {"name": "Two-Hand Quicken", "job": "swordsman", "tier": 2, "type": "buff", "max": 10, "sp0": 10, "sp1": 4,
		"desc": "Swing a two-handed sword much faster.", "bonus": {"ASPD": [30, 0]}, "time0": 0, "time1": 30, "cd": 1.0,
		"req": {"sword_mastery": 1}},
	# ---------------------------------------------------------------- Lord Knight
	"aura_blade": {"name": "Aura Blade", "job": "swordsman", "tier": 3, "type": "buff", "max": 5, "sp0": 14, "sp1": 4,
		"desc": "Wreathe your weapon in aura: big ATK bonus that ignores armour.", "bonus": {"ATK": 20}, "time0": 40, "time1": 20,
		"cd": 1.0, "req": {"two_hand_quicken": 5}},
	"parrying": {"name": "Parrying", "job": "swordsman", "tier": 3, "type": "buff", "max": 10, "sp0": 50, "sp1": 0,
		"desc": "Turn melee blows aside with a two-handed sword for a while.", "bonus": {"FLEE": [20, 3]}, "time0": 10, "time1": 5,
		"cd": 1.0, "req": {"two_hand_quicken": 10}},
	"spiral_pierce": {"name": "Spiral Pierce", "job": "swordsman", "tier": 3, "type": "melee", "max": 5, "sp0": 15, "sp1": 3,
		"desc": "A drilling spear thrust that strikes five times.", "base": 150, "per": 50, "hits": 5,
		"cast": [0.3, 0.5, 0.7, 0.9, 1.0], "cd": [1.0, 1.2, 1.4, 1.6, 2.0], "req": {"pierce": 5}},
	"berserk": {"name": "Frenzy", "job": "swordsman", "tier": 3, "type": "buff", "max": 1, "sp0": 100, "sp1": 0,
		"desc": "Fly into a battle rage: max HP and ATK way up, attack speed maxed, DEF and FLEE drop.",
		"bonus": {"ATK_PCT": [100, 0], "ASPD": [30, 0], "MAXHP_PCT": [200, 0], "DEF": [-20, 0], "FLEE": [-20, 0]}, "time0": 30, "time1": 0,
		"cd": 60.0, "req": {"aura_blade": 5}},
	# ---------------------------------------------------------------- Hunter
	"beast_bane": {"name": "Beast Bane", "job": "archer", "tier": 2, "type": "passive", "max": 10,
		"desc": "Know your prey: ATK up against brutes and insects.", "bonus": {"ATK": 4}},
	"blitz_beat": {"name": "Blitz Beat", "job": "archer", "tier": 2, "type": "bolt", "max": 5, "sp0": 7, "sp1": 3,
		"desc": "Your falcon dives at the enemy (1 strike per level).", "base": 100, "per": 0, "hits_per_lv": true, "proj": "arrow",
		"cast0": 1.5, "cast1": 0.0, "cd": 1.0, "req": {"beast_bane": 1}},
	"ankle_snare": {"name": "Ankle Snare", "job": "archer", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 12, "sp1": 0,
		"desc": "A snare trap that pins monsters in place (no damage).", "nodmg": true, "base": 0, "per": 0, "radius": 1.0,
		"color": Color(0.55, 0.85, 0.4), "status": "stun", "chance0": 100, "chance1": 0, "stime0": 0.0, "stime1": 4.0, "cd": 1.0},
	"land_mine": {"name": "Land Mine", "job": "archer", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 10, "sp1": 0,
		"desc": "An earth trap that explodes and may stun.", "base": 160, "per": 40, "radius": 1.0, "color": Color(0.95, 0.7, 0.35),
		"status": "stun", "chance0": 30, "chance1": 5, "stime0": 2.0, "stime1": 0.0, "cd": 1.0},
	"claymore_trap": {"name": "Claymore Trap", "job": "archer", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 15, "sp1": 0,
		"desc": "A fire trap with a large blast.", "base": 150, "per": 50, "radius": 2.5, "color": Color(1.0, 0.45, 0.15),
		"cd": 1.0, "req": {"land_mine": 1}},
	# ---------------------------------------------------------------- Sniper
	"true_sight": {"name": "True Sight", "job": "archer", "tier": 3, "type": "buff", "max": 10, "sp0": 18, "sp1": 2,
		"desc": "Perfect focus: every stat +5, ATK, HIT and CRIT up.",
		"bonus": {"STR": [5, 0], "AGI": [5, 0], "VIT": [5, 0], "INT": [5, 0], "DEX": [5, 0], "LUK": [5, 0], "ATK_PCT": 2, "HIT": 3, "CRIT": 1},
		"time0": 30, "time1": 0, "cd": 1.0, "req": {"improve_concentration": 1}},
	"falcon_assault": {"name": "Falcon Assault", "job": "archer", "tier": 3, "type": "bolt", "max": 5, "sp0": 26, "sp1": 4,
		"desc": "Your falcon strikes with all its might.", "base": 300, "per": 80, "hits": 1, "proj": "arrow",
		"cast0": 1.0, "cast1": 0.0, "cd": 3.0, "req": {"blitz_beat": 5}},
	"sharp_shooting": {"name": "Sharp Shooting", "job": "archer", "tier": 3, "type": "aoe_target", "max": 5, "sp0": 18, "sp1": 2,
		"desc": "A piercing shot that tears through a line of enemies; high critical chance.", "base": 200, "per": 50, "radius": 2.0,
		"proj": "arrow", "color": Color(0.85, 0.95, 1.0), "cast0": 2.0, "cast1": 0.0, "cd": 1.5, "req": {"double_strafe": 5}},
	"wind_walk": {"name": "Wind Walk", "job": "archer", "tier": 3, "type": "buff", "max": 10, "sp0": 44, "sp1": 2,
		"desc": "Move like the wind: FLEE and move speed up.", "bonus": {"FLEE": 1, "MOVE": 2}, "time0": 120, "time1": 10,
		"cast0": 2.0, "cast1": 0.0, "cd": 1.0, "req": {"true_sight": 1}},
	# ---------------------------------------------------------------- Wizard
	"frost_diver": {"name": "Frost Diver", "job": "mage", "tier": 2, "type": "bolt", "max": 10, "sp0": 26, "sp1": -1,
		"desc": "A wave of ice that often freezes the target.", "base": 100, "per": 10, "hits": 1, "proj": "ice",
		"status": "freeze", "chance0": 35, "chance1": 3, "stime0": 0.0, "stime1": 3.0, "cast0": 0.8, "cast1": 0.0, "cd": 1.5,
		"req": {"cold_bolt": 5}},
	"jupitel_thunder": {"name": "Jupitel Thunder", "job": "mage", "tier": 2, "type": "bolt", "max": 10, "sp0": 17, "sp1": 3,
		"desc": "A ball of thunder that strikes many times and pushes the enemy back.", "base": 100, "per": 0, "hits0": 2, "hits1": 1,
		"proj": "lightning", "cast0": 2.0, "cast1": 0.5, "cd": 0.5, "req": {"lightning_bolt": 1}},
	"meteor_storm": {"name": "Meteor Storm", "job": "mage", "tier": 2, "type": "aoe_target", "max": 10,
		"sp": [20, 24, 30, 34, 40, 44, 50, 54, 60, 64], "hits_t": [1, 2, 2, 3, 3, 4, 4, 5, 5, 6],
		"desc": "Meteors crash down on a wide area; may stun.", "base": 125, "per": 0, "radius": 3.5, "color": Color(1.0, 0.4, 0.1),
		"status": "stun", "chance0": 3, "chance1": 3, "stime0": 2.0, "stime1": 0.0, "cast": [15.0],
		"cd": [2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 7.0], "req": {"fire_ball": 5}},
	"storm_gust": {"name": "Storm Gust", "job": "mage", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 78, "sp1": 0,
		"desc": "A freezing blizzard over a wide area; strikes 10 times and freezes on the third hit.", "base": 100, "per": 40,
		"hits": 10, "radius": 3.5, "color": Color(0.6, 0.85, 1.0), "status": "freeze", "chance0": 100, "chance1": 0, "stime0": 3.0,
		"stime1": 0.0, "status_hit": 3, "cast0": 5.0, "cast1": 1.0, "cd": 5.0, "req": {"frost_diver": 1, "jupitel_thunder": 3}},
	"lord_of_vermilion": {"name": "Lord of Vermilion", "job": "mage", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 56, "sp1": 4,
		"desc": "Thunder rains on a huge area (4 waves); may blind and stun.", "base": 100, "per": 20, "hits": 4, "radius": 4.0,
		"color": Color(1.0, 0.95, 0.45), "status": "stun", "chance0": 4, "chance1": 4, "stime0": 2.0, "stime1": 0.0,
		"cast0": 15.5, "cast1": -0.5, "cd": 5.0, "req": {"jupitel_thunder": 5}},
	# ---------------------------------------------------------------- High Wizard
	"mystical_amplification": {"name": "Mystical Amplification", "job": "mage", "tier": 3, "type": "buff", "max": 10, "sp0": 18, "sp1": 4,
		"desc": "Amplify your next spells: magic power up.", "bonus": {"ATK_PCT": 5}, "time0": 30, "time1": 0, "cast0": 0.7, "cast1": 0.0,
		"cd": 1.0, "req": {"sp_recovery": 5}},
	"soul_drain": {"name": "Soul Drain", "job": "mage", "tier": 3, "type": "passive", "max": 10,
		"desc": "Draw on the souls of the fallen: more max SP and SP regen.", "bonus": {"MAXSP_PCT": 2, "SPREGEN": 5}, "req": {"soul_strike": 7}},
	"napalm_vulcan": {"name": "Napalm Vulcan", "job": "mage", "tier": 3, "type": "aoe_target", "max": 5, "sp0": 10, "sp1": 0,
		"desc": "Ghost-element blasts rain on the target and those near it.", "base": 70, "per": 10, "hits0": 0, "hits1": 1,
		"radius": 1.6, "proj": "magic", "color": Color(0.75, 0.6, 1.0), "cast0": 1.0, "cast1": 0.0, "cd": 1.0, "req": {"napalm_beat": 5}},
	"gravitation_field": {"name": "Gravitation Field", "job": "mage", "tier": 3, "type": "aoe_target", "max": 5, "sp0": 40, "sp1": 10,
		"desc": "Crushing gravity pulses over an area; damage ignores defence.", "base": 200, "per": 50, "hits": 4, "radius": 2.5,
		"color": Color(0.7, 0.45, 1.0), "cast0": 5.0, "cast1": 0.0, "cd": 2.0, "req": {"mystical_amplification": 10, "storm_gust": 1}},
	# ---------------------------------------------------------------- Priest
	"sanctuary": {"name": "Sanctuary", "job": "acolyte", "tier": 2, "type": "heal", "max": 10, "sp0": 12, "sp1": 3,
		"desc": "Holy ground that restores a large amount of HP.", "heal_mult": 1.8, "cast0": 5.0, "cast1": 0.0, "cd": 2.0, "req": {"heal": 1}},
	"kyrie_eleison": {"name": "Kyrie Eleison", "job": "acolyte", "tier": 2, "type": "buff", "max": 10,
		"sp": [20, 20, 20, 25, 25, 25, 30, 30, 30, 35], "cast0": 2.0, "cast1": 0.0, "cd": 2.0,
		"desc": "A holy barrier that soaks up hits: DEF and max HP up.", "bonus": {"DEF": 3, "MAXHP_PCT": 2}, "time0": 120, "time1": 0,
		"req": {"angelus": 2}},
	"magnificat": {"name": "Magnificat", "job": "acolyte", "tier": 2, "type": "buff", "max": 5, "sp0": 40, "sp1": 0,
		"desc": "A hymn that doubles HP and SP recovery.", "bonus": {"SPREGEN": [100, 0], "HPREGEN": [100, 0]}, "time0": 15, "time1": 15,
		"cast0": 4.0, "cast1": 0.0, "cd": 2.0},
	"impositio_manus": {"name": "Impositio Manus", "job": "acolyte", "tier": 2, "type": "buff", "max": 5, "sp0": 10, "sp1": 3,
		"desc": "Lay on hands: ATK up for a while.", "bonus": {"ATK": 5}, "time0": 60, "time1": 0, "cd": 3.0},
	"magnus_exorcismus": {"name": "Magnus Exorcismus", "job": "acolyte", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 40, "sp1": 0,
		"desc": "A great cross of holy light purges an area again and again.", "base": 100, "per": 0, "hits0": 0, "hits1": 1, "radius": 3.5,
		"color": Color(1.0, 0.95, 0.6), "cast0": 15.0, "cast1": 0.0, "cd": 4.0, "req": {"holy_light": 1, "sanctuary": 3}},
	# ---------------------------------------------------------------- High Priest
	"assumptio": {"name": "Assumptio", "job": "acolyte", "tier": 3, "type": "buff", "max": 5, "sp0": 10, "sp1": 10,
		"desc": "Divine wings that halve the damage you take.", "bonus": {"DEF": 5, "MAXHP_PCT": 3}, "time0": 0, "time1": 20,
		"cast0": 0.5, "cast1": 0.5, "cd": 1.1, "req": {"increase_agi": 3, "angelus": 1}},
	"meditatio": {"name": "Meditatio", "job": "acolyte", "tier": 3, "type": "passive", "max": 10,
		"desc": "Deep prayer: more SP regen, max SP and healing.", "bonus": {"SPREGEN": 3, "MAXSP_PCT": 1, "HEAL_PCT": 2}},
	"judex": {"name": "Mana Recharge", "job": "acolyte", "tier": 3, "type": "passive", "max": 5,
		"desc": "Your prayers need less mana: SP cost of every skill down.", "bonus": {"SPCOST": 4}, "req": {"meditatio": 5}},
	"basilica": {"name": "Basilica", "job": "acolyte", "tier": 3, "type": "buff", "max": 5, "sp0": 70, "sp1": 10,
		"desc": "A sacred sanctum around you: DEF, FLEE and HP regen up.", "bonus": {"DEF": 6, "FLEE": 4, "HPREGEN": 20}, "time0": 15, "time1": 5,
		"cast0": 5.0, "cast1": 0.0, "cd": 2.0, "req": {"assumptio": 3}},
	# ---------------------------------------------------------------- Blacksmith
	"weaponry_research": {"name": "Weaponry Research", "job": "merchant", "tier": 2, "type": "passive", "max": 10,
		"desc": "Know your weapons inside out: ATK and HIT up.", "bonus": {"ATK": 2, "HIT": 2}},
	"hammer_fall": {"name": "Hammer Fall", "job": "merchant", "tier": 2, "type": "aoe_self", "max": 5, "sp0": 10, "sp1": 0,
		"desc": "Slam the ground and stun the monsters around you (no damage).", "nodmg": true, "base": 0, "per": 0, "radius": 2.5,
		"color": Color(0.95, 0.8, 0.45), "status": "stun", "chance0": 20, "chance1": 10, "stime0": 5.0, "stime1": 0.0, "cd": 1.0},
	"adrenaline_rush": {"name": "Adrenaline Rush", "job": "merchant", "tier": 2, "type": "buff", "max": 5, "sp0": 17, "sp1": 3,
		"desc": "Get pumped: axe and mace attack speed way up.", "bonus": {"ASPD": [30, 0]}, "time0": 0, "time1": 30, "cd": 1.0,
		"req": {"hammer_fall": 2}},
	"power_thrust": {"name": "Over Thrust", "job": "merchant", "tier": 2, "type": "buff", "max": 5, "sp0": 20, "sp1": -2,
		"desc": "Put your weight behind every swing: ATK up.", "bonus": {"ATK_PCT": 5}, "time0": 0, "time1": 20, "cd": 1.0,
		"req": {"adrenaline_rush": 3}},
	"maximize_power": {"name": "Maximize Power", "job": "merchant", "tier": 2, "type": "buff", "max": 5, "sp0": 10, "sp1": 0,
		"desc": "Always hit with full force: ATK and CRIT up.", "bonus": {"ATK": 3, "CRIT": 3}, "time0": 30, "time1": 10,
		"cd": 1.0, "req": {"weaponry_research": 1, "power_thrust": 2}},
	# ---------------------------------------------------------------- Whitesmith
	"cart_termination": {"name": "Cart Termination", "job": "merchant", "tier": 3, "type": "melee", "max": 10, "sp0": 15, "sp1": 0,
		"desc": "Ram the enemy with a cart full of Zeny (costs Zeny); may stun.", "base": 150, "per": 60, "zeny": 60,
		"status": "stun", "chance0": 5, "chance1": 2.5, "stime0": 2.0, "stime1": 0.0, "cd": 0.6, "req": {"mammonite": 10}},
	"maximum_overthrust": {"name": "Maximum Over Thrust", "job": "merchant", "tier": 3, "type": "buff", "max": 5, "sp0": 15, "sp1": 0,
		"desc": "Push past your limits: huge ATK bonus (costs 3,000 Zeny).", "bonus": {"ATK_PCT": 20}, "time0": 180, "time1": 0,
		"zeny": 600, "cd": 1.0, "req": {"power_thrust": 5}},
	"weapon_perfection": {"name": "Weapon Perfection", "job": "merchant", "tier": 3, "type": "passive", "max": 5,
		"desc": "Masterwork technique: full damage on every monster size.", "bonus": {"ATK": 5, "HIT": 3}, "req": {"weaponry_research": 2}},
	"meltdown": {"name": "Meltdown", "job": "merchant", "tier": 3, "type": "buff", "max": 10, "sp0": 20, "sp1": 0,
		"desc": "White-hot blows that can break weapons and armour: ATK and CRIT up.", "bonus": {"ATK": 4, "CRIT": 2}, "time0": 15, "time1": 5,
		"cd": 1.0, "req": {"maximum_overthrust": 2}},
	# ---------------------------------------------------------------- Assassin
	"katar_mastery": {"name": "Katar Mastery", "job": "thief", "tier": 2, "type": "passive", "max": 10,
		"desc": "Training with katars: ATK up.", "bonus": {"ATK": 3}},
	"sonic_blow": {"name": "Sonic Blow", "job": "thief", "tier": 2, "type": "melee", "max": 10, "sp0": 14, "sp1": 2,
		"desc": "Eight lightning-fast stabs; may stun.", "base": 38, "per": 6, "hits": 8, "status": "stun", "chance0": 10, "chance1": 2,
		"stime0": 2.0, "stime1": 0.0, "cd": 2.0, "req": {"katar_mastery": 4}},
	"grimtooth": {"name": "Grimtooth", "job": "thief", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 3, "sp1": 0,
		"desc": "Blades burst from the ground under the target and the enemies around it.", "base": 100, "per": 20, "radius": 1.6,
		"color": Color(0.7, 0.9, 0.5), "cd": 0.6, "req": {"cloaking": 2, "sonic_blow": 5}},
	"cloaking": {"name": "Cloaking", "job": "thief", "tier": 2, "type": "buff", "max": 10, "sp0": 15, "sp1": 0,
		"desc": "Blend into the shadows: FLEE and move speed up.", "bonus": {"FLEE": 4, "MOVE": 2}, "time0": 20, "time1": 10, "cd": 1.0},
	"enchant_poison": {"name": "Enchant Poison", "job": "thief", "tier": 2, "type": "buff", "max": 10, "sp0": 20, "sp1": 0,
		"desc": "Coat your weapon in poison: normal attacks may poison.", "bonus": {"ATK": 2, "POISON": [2.5, 0.5]}, "time0": 30, "time1": 15,
		"cd": 1.0},
	# ---------------------------------------------------------------- Assassin Cross
	"enchant_deadly_poison": {"name": "Enchant Deadly Poison", "job": "thief", "tier": 3, "type": "buff", "max": 5, "sp0": 60, "sp1": 0,
		"desc": "A deadly venom that multiplies your weapon damage; poisons on hit.", "bonus": {"ATK_PCT": [50, 50], "POISON": 4},
		"time0": 30, "time1": 10, "cd": 1.0, "req": {"enchant_poison": 6}},
	"soul_destroyer": {"name": "Soul Breaker", "job": "thief", "tier": 3, "type": "bolt", "max": 10, "sp0": 18, "sp1": 2,
		"desc": "Hurl a blade of shadow at a distant enemy: weapon and magic damage at once.", "base": 150, "per": 40, "hits": 1,
		"proj": "magic", "cast0": 0.5, "cast1": 0.0, "cd": 1.0, "req": {"grimtooth": 3}},
	"meteor_assault": {"name": "Meteor Assault", "job": "thief", "tier": 3, "type": "aoe_self", "max": 10, "sp0": 10, "sp1": 4,
		"desc": "Lash out at everything around you; may stun, curse or blind.", "base": 80, "per": 40, "radius": 2.5, "color": Color(0.75, 0.45, 1.0),
		"status": "stun", "chance0": 5, "chance1": 5, "stime0": 2.0, "stime1": 0.0, "cast0": 0.5, "cast1": 0.0, "cd": 0.5,
		"req": {"katar_mastery": 5, "sonic_blow": 5}},
	"advanced_katar": {"name": "Advanced Katar Research", "job": "thief", "tier": 3, "type": "passive", "max": 5,
		"desc": "Perfect your katar style: katar damage up.", "bonus": {"ATK_PCT": [10, 2]}, "req": {"katar_mastery": 10}},

	# ================================================================ Novice (tier 0)
	"basic_training": {"name": "Basic Skill", "job": "novice", "tier": 0, "type": "passive", "max": 9, "icon": "star",
		"desc": "The fundamentals every adventurer learns. Level 9 is needed for the first job change.", "bonus": {"HIT": 1}},
	"field_dressing": {"name": "First Aid", "job": "novice", "tier": 0, "type": "heal", "max": 1, "sp0": 3, "sp1": 0, "icon": "heart",
		"desc": "Wrap a quick bandage around a wound.", "heal_mult": 0.6, "cd": 1.0},
	# ================================================================ 2nd job, branch B (and its transcendent job)
	# ---------------------------------------------------------------- Crusader / Paladin (swordsman)
	"bulwark_training": {"name": "Faith", "job": "swordsman", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "holy",
		"desc": "Unshakable faith: max HP up and holy damage taken down.", "bonus": {"MAXHP_PCT": 2, "DEF": 1}},
	"shield_rush": {"name": "Shield Charge", "job": "swordsman", "branch": "b", "tier": 2, "type": "melee", "max": 5, "sp0": 10, "sp1": 0, "icon": "shield",
		"desc": "Slam your shield into one enemy and knock it back; may stun.", "base": 100, "per": 20, "status": "stun", "chance0": 15, "chance1": 5,
		"stime0": 2.0, "stime1": 0.0, "cd": 0.6, "req": {"aegis_vow": 5}},
	"aegis_vow": {"name": "Auto Guard", "job": "swordsman", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 10, "sp1": 2, "icon": "shield",
		"desc": "Block physical attacks with your shield for a while.", "bonus": {"FLEE": 3, "DEF": 1}, "time0": 300, "time1": 0, "cd": 1.0},
	"radiant_cross": {"name": "Grand Cross", "job": "swordsman", "branch": "b", "tier": 2, "type": "aoe_self", "max": 10, "sp0": 30, "sp1": 7, "icon": "holy",
		"desc": "A blazing holy cross bursts out around you (costs 20% HP).", "base": 100, "per": 40, "hits": 3, "radius": 2.5,
		"color": Color(1.0, 0.92, 0.55), "hp_pct": 20, "cast0": 3.0, "cast1": 0.0, "cd": 1.5, "req": {"bulwark_training": 10, "lance_charge": 6}},
	"lance_charge": {"name": "Holy Cross", "job": "swordsman", "branch": "b", "tier": 2, "type": "melee", "max": 10, "sp0": 10, "sp1": 1, "icon": "holy",
		"desc": "Two holy slashes in the shape of a cross; may blind and stun.", "base": 100, "per": 35, "hits": 2, "status": "stun",
		"chance0": 0, "chance1": 3, "stime0": 2.0, "stime1": 0.0, "cd": 0.6, "req": {"bulwark_training": 7}},
	"holy_bastion": {"name": "Defending Aura", "job": "swordsman", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 30, "sp1": 0, "icon": "shield",
		"desc": "Raise your shield against ranged attacks: DEF up, but you move slower.", "bonus": {"DEF": 4, "MOVE": -5}, "time0": 180, "time1": 0,
		"cd": 0.8, "req": {"aegis_vow": 5}},
	"judgement_lance": {"name": "Shield Chain", "job": "swordsman", "branch": "b", "tier": 3, "type": "bolt", "max": 5, "sp0": 25, "sp1": 3, "icon": "shield",
		"desc": "Hurl your shield again and again: five crushing hits.", "base": 60, "per": 20, "hits": 5, "proj": "magic", "color": Color(0.9, 0.85, 0.7),
		"cast0": 1.0, "cast1": 0.0, "cd": 1.0, "req": {"shield_rush": 5}},
	"sanctified_ground": {"name": "Gospel", "job": "swordsman", "branch": "b", "tier": 3, "type": "aoe_self", "max": 10, "sp0": 80, "sp1": 0, "icon": "holy",
		"desc": "Sing a battle hymn: holy power strikes enemies around you; may stun.", "base": 100, "per": 30, "hits": 2, "radius": 3.5,
		"color": Color(1.0, 0.95, 0.65), "status": "stun", "chance0": 10, "chance1": 3, "stime0": 2.0, "stime1": 0.0, "cast0": 3.0,
		"cast1": 0.0, "cd": 1.0, "req": {"radiant_cross": 5}},
	"guardian_spirit": {"name": "Martyr's Reckoning", "job": "swordsman", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 100, "sp1": 0, "icon": "heart",
		"desc": "Burn your own life for power: ATK way up for a few attacks.", "bonus": {"ATK_PCT": [10, 10], "MAXHP_PCT": [-10, 0]},
		"time0": 30, "time1": 0, "cd": 3.0, "req": {"holy_bastion": 3}},
	# ---------------------------------------------------------------- Bard / Minstrel (archer)
	"resonant_strings": {"name": "Music Lessons", "job": "archer", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "star",
		"desc": "Practice with instruments: ATK and song strength up.", "bonus": {"ATK": 3, "ASPD": 1}},
	"dissonant_chord": {"name": "Melody Strike", "job": "archer", "branch": "b", "tier": 2, "type": "bolt", "max": 5, "sp0": -1, "sp1": 2, "icon": "bolt",
		"desc": "Fire a sharp note from your instrument at one enemy.", "base": 120, "per": 40, "hits": 1, "proj": "magic",
		"cast0": 1.5, "cast1": 0.0, "cd": 0.5, "req": {"resonant_strings": 3}},
	"rhythm_of_haste": {"name": "Impressive Riff", "job": "archer", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 36, "sp1": 2, "icon": "boot",
		"desc": "A driving song: attack speed up.", "bonus": {"ASPD": [10, 1]}, "time0": 180, "time1": 0, "cd": 1.0, "req": {"resonant_strings": 3}},
	"briar_lullaby": {"name": "Unbarring Octave", "job": "archer", "branch": "b", "tier": 2, "type": "aoe_self", "max": 5, "sp0": 10, "sp1": 2, "icon": "ice",
		"desc": "A joke so cold every monster nearby may freeze solid.", "nodmg": true, "base": 0, "per": 0, "radius": 5.0,
		"color": Color(0.7, 0.9, 1.0), "status": "freeze", "chance0": 15, "chance1": 5, "stime0": 4.0, "stime1": 0.0, "cd": 4.0},
	"stage_presence": {"name": "Perfect Tablature", "job": "archer", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 22, "sp1": 2, "icon": "star",
		"desc": "A whistled tune: FLEE and perfect dodge up.", "bonus": {"FLEE": 1, "LUK": 1}, "time0": 180, "time1": 0, "cd": 1.0,
		"req": {"resonant_strings": 3}},
	"crescendo": {"name": "Arrow Vulcan", "job": "archer", "branch": "b", "tier": 3, "type": "bolt", "max": 10, "sp0": 10, "sp1": 2, "icon": "bow",
		"desc": "Nine arrows in a blur at one enemy.", "base": 22, "per": 11, "hits": 9, "proj": "arrow",
		"cast0": 2.0, "cast1": 0.2, "cd": 3.0, "req": {"dissonant_chord": 3}},
	"ballad_of_vigor": {"name": "Apple of Idun", "job": "archer", "branch": "b", "tier": 3, "type": "buff", "max": 10, "sp0": 35, "sp1": 5, "icon": "heart",
		"desc": "A healing song: max HP and HP regen up.", "bonus": {"MAXHP_PCT": [5, 2], "HPREGEN": 10}, "time0": 180, "time1": 0,
		"cd": 1.0, "req": {"resonant_strings": 10}},
	"whiplash_volley": {"name": "Marionette Control", "job": "archer", "branch": "b", "tier": 3, "type": "buff", "max": 1, "sp0": 100, "sp1": 0, "icon": "star",
		"desc": "Pull invisible strings: every stat up for a while.",
		"bonus": {"STR": [10, 0], "AGI": [10, 0], "VIT": [10, 0], "INT": [10, 0], "DEX": [10, 0], "LUK": [10, 0]}, "time0": 60, "time1": 0,
		"cast0": 2.0, "cast1": 0.0, "cd": 30.0, "req": {"ballad_of_vigor": 5}},
	"virtuoso_focus": {"name": "Magic Strings", "job": "archer", "branch": "b", "tier": 3, "type": "buff", "max": 10, "sp0": 35, "sp1": 5, "icon": "magic",
		"desc": "A Poem of Bragi: cast times and skill delays shorter.", "bonus": {"CAST": [3, 3]}, "time0": 180, "time1": 0, "cd": 1.0,
		"req": {"resonant_strings": 10}},
	# ---------------------------------------------------------------- Sage / Professor (mage)
	"tome_study": {"name": "Advanced Book", "job": "mage", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "star",
		"desc": "Fight with heavy books: ATK and attack speed up.", "bonus": {"ATK": 3, "ASPD": 0.5}},
	"stone_lance": {"name": "Earth Spike", "job": "mage", "branch": "b", "tier": 2, "type": "bolt", "max": 5, "sp0": 10, "sp1": 2, "icon": "bash",
		"desc": "Spikes of stone burst up under one enemy (1 spike per level).", "base": 100, "per": 0, "hits_per_lv": true, "proj": "magic",
		"color": Color(0.8, 0.65, 0.4), "cast0": 0.0, "cast1": 0.7, "cd": 0.8, "req": {"tome_study": 1}},
	"elemental_infusion": {"name": "Endow Blaze", "job": "mage", "branch": "b", "tier": 2, "type": "buff", "max": 5, "sp0": 40, "sp1": 0, "icon": "fire",
		"desc": "Enchant your weapon with fire: ATK up.", "bonus": {"ATK": 4}, "time0": 0, "time1": 300, "cast0": 3.0, "cast1": 0.0, "cd": 1.0,
		"req": {"tome_study": 2}},
	"quicksand_pit": {"name": "Heaven's Drive", "job": "mage", "branch": "b", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 24, "sp1": 4, "icon": "bash",
		"desc": "The ground heaves up under a 5x5 area (1 hit per level).", "base": 125, "per": 0, "hits0": 0, "hits1": 1, "radius": 2.5,
		"color": Color(0.85, 0.7, 0.4), "cast0": 0.0, "cast1": 1.0, "cd": 1.0, "req": {"stone_lance": 3}},
	"spell_ward": {"name": "Magic Rod", "job": "mage", "branch": "b", "tier": 2, "type": "buff", "max": 5, "sp0": 2, "sp1": 0, "icon": "shield",
		"desc": "Absorb incoming magic as SP: DEF and SP regen up.", "bonus": {"DEF": 2, "SPREGEN": 20}, "time0": 0, "time1": 6, "cd": 1.0},
	"arcane_comet": {"name": "Abracadabra", "job": "mage", "branch": "b", "tier": 3, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 0, "icon": "star",
		"desc": "Cast a random spell of a random element on an area: anything can happen.", "base": 100, "per": 30, "random": true, "radius": 3.0,
		"proj": "magic", "color": Color(0.7, 0.6, 1.0), "cd": 3.0, "req": {"quicksand_pit": 3}},
	"mana_flow": {"name": "Indulge", "job": "mage", "branch": "b", "tier": 3, "type": "passive", "max": 5, "icon": "drop",
		"desc": "Turn your own vitality into mana: SP regen and max SP up.", "bonus": {"SPREGEN": 6, "MAXSP_PCT": 3}},
	"chain_spark": {"name": "Double Bolt", "job": "mage", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 30, "sp1": 10, "icon": "bolt",
		"desc": "Double Casting: your bolt spells may fire a second volley.", "bonus": {"DOUBLECAST": [30, 10]}, "time0": 90, "time1": 0,
		"cd": 1.0, "req": {"stone_lance": 5}},
	"runic_aegis": {"name": "Memorize", "job": "mage", "branch": "b", "tier": 3, "type": "buff", "max": 1, "sp0": 1, "sp1": 0, "icon": "star",
		"desc": "Memorise your spells: cast times halved for a while.", "bonus": {"CAST": [50, 0]}, "time0": 30, "time1": 0,
		"cast0": 5.0, "cast1": 0.0, "cd": 60.0, "req": {"tome_study": 5}},
	# ---------------------------------------------------------------- Monk / Champion (acolyte)
	"iron_fist": {"name": "Iron Hand", "job": "acolyte", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "bash",
		"desc": "Hardened fists: ATK up with knuckles.", "bonus": {"ATK": 3}},
	"palm_strike": {"name": "Occult Impaction", "job": "acolyte", "branch": "b", "tier": 2, "type": "melee", "max": 5, "icon": "bash",
		"sp": [10, 14, 17, 19, 20], "desc": "Strike through armour with your spirit: the tougher the enemy, the harder it hits.",
		"base": 100, "per": 75, "cast0": 1.0, "cast1": 0.0, "cd": 0.5, "req": {"inner_spheres": 5}},
	"inner_spheres": {"name": "Summon Spirit Sphere", "job": "acolyte", "branch": "b", "tier": 2, "type": "buff", "max": 5, "sp0": 8, "sp1": 0, "icon": "star",
		"desc": "Call spirit spheres to circle you: +3 ATK per sphere.", "bonus": {"ATK": 3}, "time0": 600, "time1": 0, "cast0": 1.0, "cast1": 0.0,
		"cd": 0.5, "req": {"iron_fist": 2}},
	"chi_burst": {"name": "Finger Offensive", "job": "acolyte", "branch": "b", "tier": 2, "type": "bolt", "max": 5, "sp0": 10, "sp1": 0, "icon": "holy",
		"desc": "Flick your spirit spheres at one enemy (1 sphere per level).", "base": 150, "per": 50, "hits_per_lv": true, "proj": "magic",
		"color": Color(0.7, 0.95, 1.0), "cast0": 0.0, "cast1": 1.0, "cd": 0.5, "req": {"palm_strike": 3}},
	"steady_breath": {"name": "Spirits Recovery", "job": "acolyte", "branch": "b", "tier": 2, "type": "passive", "max": 5, "icon": "drop",
		"desc": "Calm breathing: HP and SP regen up, even when overweight.", "bonus": {"HPREGEN": 8, "SPREGEN": 6}},
	"thousand_palms": {"name": "Asura Strike", "job": "acolyte", "branch": "b", "tier": 3, "type": "melee", "max": 5, "sp0": 10, "sp1": 0, "icon": "bash",
		"desc": "Pour every last point of SP into one devastating blow. Damage grows with the SP spent.", "base": 800, "per": 0,
		"sp_all": true, "flat0": 250, "flat1": 150, "cast0": 4.5, "cast1": -0.5, "cd": 3.0, "req": {"chi_burst": 3, "zen_guard": 3}},
	"rising_dragon_kick": {"name": "Tiger Knuckle Fist", "job": "acolyte", "branch": "b", "tier": 3, "type": "melee", "max": 5, "sp0": 2, "sp1": 2, "icon": "bash",
		"desc": "A crushing punch that pins the enemy in place.", "base": 140, "per": 60, "status": "stun", "chance0": 50, "chance1": 10,
		"stime0": 2.0, "stime1": 0.5, "cd": 0.8, "req": {"palm_strike": 3}},
	"zen_guard": {"name": "Steel Body", "job": "acolyte", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 200, "sp1": 0, "icon": "shield",
		"desc": "Harden your body like iron: DEF hugely up, but you move and swing slower.", "bonus": {"DEF": [40, 10], "MOVE": [-25, 0], "ASPD": [-25, 0]},
		"time0": 0, "time1": 30, "cast0": 5.0, "cast1": 0.0, "cd": 3.0, "req": {"inner_spheres": 5}},
	"sky_resolve": {"name": "Raging Trifecta Blow", "job": "acolyte", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "star",
		"desc": "Normal attacks may turn into a three-hit combo.", "bonus": {"TRIPLE": [30, -1]}},
	# ---------------------------------------------------------------- Alchemist / Creator (merchant)
	"potion_lore": {"name": "Potion Research", "job": "merchant", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "drop",
		"desc": "Know your brews: healing and HP regen up.", "bonus": {"HEAL_PCT": 5, "HPREGEN": 5}},
	"acid_flask": {"name": "Acid Terror", "job": "merchant", "branch": "b", "tier": 2, "type": "bolt", "max": 5, "sp0": 15, "sp1": 0, "icon": "poison",
		"desc": "Throw a flask of acid that eats through armour; may cause bleeding.", "base": 140, "per": 40, "hits": 1, "proj": "magic",
		"color": Color(0.6, 0.95, 0.35), "status": "poison", "chance0": 3, "chance1": 3, "stime0": 6.0, "stime1": 0.0, "cast0": 1.0, "cast1": 0.0,
		"cd": 0.5, "req": {"potion_lore": 5}},
	"fire_flask": {"name": "Bomb", "job": "merchant", "branch": "b", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 10, "sp1": 0, "icon": "fire",
		"desc": "Demonstration: a fire bomb that keeps burning the ground.", "base": 120, "per": 20, "hits0": 1, "hits1": 0.5, "radius": 1.6,
		"proj": "fire", "color": Color(1.0, 0.5, 0.15), "cast0": 1.0, "cast1": 0.0, "cd": 0.5, "req": {"potion_lore": 4}},
	"alloy_coating": {"name": "Chemical Protection Armor", "job": "merchant", "branch": "b", "tier": 2, "type": "buff", "max": 5, "sp0": 25, "sp1": 0, "icon": "shield",
		"desc": "Coat your armour so nothing can break it: DEF up.", "bonus": {"DEF": 3}, "time0": 0, "time1": 120, "cast0": 2.0, "cast1": 0.0,
		"cd": 1.0, "req": {"potion_lore": 2}},
	"clockwork_sights": {"name": "Axe Mastery", "job": "merchant", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "star",
		"desc": "Training with axes: ATK up.", "bonus": {"ATK": 3}},
	"golem_smash": {"name": "Acid Demonstration", "job": "merchant", "branch": "b", "tier": 3, "type": "bolt", "max": 10, "sp0": 30, "sp1": 0, "icon": "poison",
		"desc": "Acid Bomb: flasks of acid and fire burst on one enemy (1 per level).", "base": 70, "per": 0, "hits_per_lv": true, "proj": "magic",
		"color": Color(0.75, 0.95, 0.4), "cast0": 1.0, "cast1": 0.0, "cd": 1.0, "req": {"acid_flask": 5, "fire_flask": 5}},
	"elixir_rush": {"name": "Berserk Pitcher", "job": "merchant", "branch": "b", "tier": 3, "type": "buff", "max": 1, "sp0": 30, "sp1": 0, "icon": "drop",
		"desc": "Down an Aid Berserk Potion: ATK and attack speed up.", "bonus": {"ATK_PCT": [10, 0], "ASPD": [10, 0]}, "time0": 300, "time1": 0,
		"cast0": 0.5, "cast1": 0.0, "cd": 1.0, "req": {"potion_lore": 10}},
	"shrapnel_bomb": {"name": "Sphere Mine", "job": "merchant", "branch": "b", "tier": 3, "type": "aoe_self", "max": 5, "sp0": 10, "sp1": 0, "icon": "fire",
		"desc": "Summon a marine sphere that explodes around you.", "base": 150, "per": 50, "radius": 3.0, "color": Color(1.0, 0.6, 0.25),
		"cast0": 2.0, "cast1": 0.0, "cd": 1.0, "req": {"fire_flask": 3}},
	"master_alchemy": {"name": "Bioethics", "job": "merchant", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "drop",
		"desc": "The study of life: max HP and max SP up.", "bonus": {"MAXHP_PCT": 2, "MAXSP_PCT": 2}},
	# ---------------------------------------------------------------- Rogue / Stalker (thief)
	"sleight_of_hand": {"name": "Snatcher", "job": "thief", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "dagger",
		"desc": "Gank: normal attacks may steal an item.", "bonus": {"SNATCH": [5, 1]}, "req": {"steal": 1}},
	"dirty_trick": {"name": "Back Stab", "job": "thief", "branch": "b", "tier": 2, "type": "melee", "max": 10, "sp0": 16, "sp1": 0, "icon": "dagger",
		"desc": "Slip behind the enemy and stab; never misses.", "base": 340, "per": 40, "cd": 0.5, "req": {"steal": 4}},
	"smoke_veil": {"name": "Tunnel Drive", "job": "thief", "branch": "b", "tier": 2, "type": "buff", "max": 5, "sp0": 10, "sp1": 0, "icon": "boot",
		"desc": "Move while hidden: FLEE and move speed up.", "bonus": {"FLEE": 4, "MOVE": 3}, "time0": 60, "time1": 0, "cd": 1.0,
		"req": {"improve_dodge": 1}},
	"knife_fan": {"name": "Raid", "job": "thief", "branch": "b", "tier": 2, "type": "aoe_self", "max": 5, "sp0": 20, "sp1": 0, "icon": "dagger",
		"desc": "Leap from hiding and strike everything around you; may stun and blind.", "base": 100, "per": 40, "radius": 1.6,
		"color": Color(0.85, 0.85, 0.95), "status": "stun", "chance0": 10, "chance1": 3, "stime0": 2.0, "stime1": 0.0, "cd": 0.5,
		"req": {"dirty_trick": 2, "smoke_veil": 2}},
	"trick_shot": {"name": "Double Strafe", "job": "thief", "branch": "b", "tier": 2, "type": "bolt", "max": 10, "sp0": 12, "sp1": 0, "icon": "bow",
		"desc": "A rogue's bow trick: two arrows at once.", "base": 90, "per": 10, "hits": 2, "proj": "arrow", "cd": 0.5,
		"req": {"sleight_of_hand": 1}},
	"phantom_blades": {"name": "Reject Sword", "job": "thief", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 10, "sp1": 5, "icon": "shield",
		"desc": "Turn sword blows back on their owner: DEF and FLEE up.", "bonus": {"DEF": 3, "FLEE": 2}, "time0": 300, "time1": 0, "cd": 1.0},
	"shadow_step": {"name": "Chase Walk", "job": "thief", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 10, "sp1": 0, "icon": "boot",
		"desc": "Walk unseen and quick; your next blows are stronger.", "bonus": {"FLEE": 3, "CRIT": 2, "MOVE": 4, "STR": 2}, "time0": 30, "time1": 0,
		"cd": 1.0, "req": {"smoke_veil": 3}},
	"ambush_combo": {"name": "Intimidate", "job": "thief", "branch": "b", "tier": 3, "type": "melee", "max": 5, "sp0": 9, "sp1": 4, "icon": "dagger",
		"desc": "Snatch: strike the enemy and drag it away with you.", "base": 100, "per": 30, "cd": 0.5, "req": {"dirty_trick": 5}},
	"lucky_charm": {"name": "Plagiarism", "job": "thief", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "coin",
		"desc": "Copy what you see others do: attack speed up.", "bonus": {"ASPD": 1, "CRIT": 1}},

	"swordsman_a_4_strike": {"name": "Ignition Break", "job": "swordsman", "branch": "a", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "A burst of rune fire that hits every enemy around you.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"swordsman_a_4_guard": {"name": "Stonehard Skin", "job": "swordsman", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Rune of stone: DEF and max HP up.", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"swordsman_a_4_mastery": {"name": "Rune Mastery", "job": "swordsman", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Know your runes: HIT and SP regen up.", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"swordsman_a_5_strike": {"name": "Storm Slash", "job": "swordsman", "branch": "a", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "A storm of sword slashes all around you.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"swordsman_a_5_guard": {"name": "Vigor", "job": "swordsman", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Dragon blood boils: ATK and max HP up.", "bonus": {"ATK_PCT": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"swordsman_a_5_mastery": {"name": "Two-Handed Weapon Mastery", "job": "swordsman", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Masters of the great sword: ATK and HIT up.", "bonus": {"ATK": 3, "HIT": 2}},
	"swordsman_b_4_strike": {"name": "Earth Drive", "job": "swordsman", "branch": "b", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "Smash your shield into the ground: holy shockwave around you.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"swordsman_b_4_guard": {"name": "Prestige", "job": "swordsman", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "A royal guard's pride: DEF and max HP up.", "bonus": {"DEF": 3, "MAXHP_PCT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"swordsman_b_4_mastery": {"name": "Force of Vanguard", "job": "swordsman", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Stand in front: max HP and HP regen up.", "bonus": {"MAXHP_PCT": 2, "HPREGEN": 5}},
	"swordsman_b_5_strike": {"name": "Grand Judgement", "job": "swordsman", "branch": "b", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "Swing your spear in a wide holy arc around you.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"swordsman_b_5_guard": {"name": "Guard Stance", "job": "swordsman", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Plant your shield: DEF way up.", "bonus": {"DEF": 4, "MAXHP_PCT": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"swordsman_b_5_mastery": {"name": "Shield Mastery", "job": "swordsman", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Shield training: DEF and HIT up.", "bonus": {"DEF": 1, "HIT": 2}},
	"archer_a_4_strike": {"name": "Arrow Storm", "job": "archer", "branch": "a", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "A storm of arrows on the target area.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"archer_a_4_guard": {"name": "Camouflage", "job": "archer", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Blend into the field: FLEE and CRIT up.", "bonus": {"FLEE": 3, "CRIT": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"archer_a_4_mastery": {"name": "Trap Research", "job": "archer", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Study traps: max SP and SP regen up.", "bonus": {"MAXSP_PCT": 2, "SPREGEN": 5}},
	"archer_a_5_strike": {"name": "Gale Storm", "job": "archer", "branch": "a", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "A whirlwind of arrows tears through an area.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"archer_a_5_guard": {"name": "Wind Sign", "job": "archer", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "The wind is with you: ASPD and FLEE up.", "bonus": {"ASPD": 2, "FLEE": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"archer_a_5_mastery": {"name": "Hawk Mastery", "job": "archer", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Train your hawk: DEX and HIT up.", "bonus": {"DEX": 1, "HIT": 2}},
	"archer_b_4_strike": {"name": "Severe Rainstorm", "job": "archer", "branch": "b", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "A downpour of arrows on the target area.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"archer_b_4_guard": {"name": "Echo Song", "job": "archer", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "A song that echoes off your armour: DEF up.", "bonus": {"DEF": 3, "MAXHP_PCT": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"archer_b_4_mastery": {"name": "Song of Mana", "job": "archer", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Your voice restores mana: SP regen and max SP up.", "bonus": {"SPREGEN": 6, "MAXSP_PCT": 1}},
	"archer_b_5_strike": {"name": "Rose Blossom", "job": "archer", "branch": "b", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "Arrows bloom like roses over an area.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"archer_b_5_guard": {"name": "Mystic Symphony", "job": "archer", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "A soaring symphony: DEF and max HP up.", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"archer_b_5_mastery": {"name": "Stage Manner", "job": "archer", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Perform like a star: DEX and HIT up.", "bonus": {"DEX": 1, "HIT": 2}},
	"mage_a_4_strike": {"name": "Comet", "job": "mage", "branch": "a", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "fire", "desc": "Pull a blazing comet down on the target area.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"mage_a_4_guard": {"name": "Recognized Spell", "job": "mage", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Every spell hits at full power: ATK up.", "bonus": {"ATK_PCT": 2, "DEF": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"mage_a_4_mastery": {"name": "Radius", "job": "mage", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Shorter casts and wider spells.", "bonus": {"CAST": 2, "SPREGEN": 3}},
	"mage_a_5_strike": {"name": "Rain of Crystal", "job": "mage", "branch": "a", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "fire", "desc": "Shards of crystal rain on an area.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"mage_a_5_guard": {"name": "Climax", "job": "mage", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Push your magic to its peak: ATK and cast speed up.", "bonus": {"ATK_PCT": 2, "CAST": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"mage_a_5_mastery": {"name": "Spell Enchanting", "job": "mage", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Magic soaks into your gear: INT and SP regen up.", "bonus": {"INT": 1, "SPREGEN": 5}},
	"mage_b_4_strike": {"name": "Psychic Wave", "job": "mage", "branch": "b", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "fire", "desc": "Waves of mind force crash over an area.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"mage_b_4_guard": {"name": "Striking", "job": "mage", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Charge your weapon with elemental power: ATK and DEF up.", "bonus": {"ATK": 3, "DEF": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"mage_b_4_mastery": {"name": "Elemental Analysis", "job": "mage", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Read the elements around you: SP regen and max SP up.", "bonus": {"SPREGEN": 6, "MAXSP_PCT": 1}},
	"mage_b_5_strike": {"name": "Elemental Buster", "job": "mage", "branch": "b", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "fire", "desc": "Your elemental spirits blast an area.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"mage_b_5_guard": {"name": "Elemental Veil", "job": "mage", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "A veil of spirits: DEF and max HP up.", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"mage_b_5_mastery": {"name": "Spirit Mastery", "job": "mage", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Bond with your spirits: INT and SP regen up.", "bonus": {"INT": 1, "SPREGEN": 5}},
	"acolyte_a_4_strike": {"name": "Adoramus", "job": "acolyte", "branch": "a", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "fire", "desc": "A spear of holy light strikes an area and blinds.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"acolyte_a_4_guard": {"name": "Praefatio", "job": "acolyte", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "A holy barrier for you and your party: DEF and max HP up.", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"acolyte_a_4_mastery": {"name": "Clementia", "job": "acolyte", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Mercy of the gods: healing and SP regen up.", "bonus": {"HEAL_PCT": 3, "SPREGEN": 5}},
	"acolyte_a_5_strike": {"name": "Pneumaticus Procella", "job": "acolyte", "branch": "a", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "fire", "desc": "A storm of holy wind over an area.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"acolyte_a_5_guard": {"name": "Presens Acies", "job": "acolyte", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Sharpened senses: DEF and CRIT up.", "bonus": {"DEF": 2, "CRIT": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"acolyte_a_5_mastery": {"name": "Mace Book Mastery", "job": "acolyte", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Fight with mace and book: ATK and HIT up.", "bonus": {"ATK": 3, "HIT": 2}},
	"acolyte_b_4_strike": {"name": "Rampage Blast", "job": "acolyte", "branch": "b", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "fire", "desc": "Release your spheres in a blast over an area.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"acolyte_b_4_guard": {"name": "Lightning Walk", "job": "acolyte", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Step aside like lightning: FLEE and DEF up.", "bonus": {"FLEE": 3, "DEF": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"acolyte_b_4_mastery": {"name": "Raising Dragon", "job": "acolyte", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "The dragon within: max HP and SP regen up.", "bonus": {"MAXHP_PCT": 2, "SPREGEN": 5}},
	"acolyte_b_5_strike": {"name": "Massive Flame Blaster", "job": "acolyte", "branch": "b", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "fire", "desc": "Holy flames explode across an area.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"acolyte_b_5_guard": {"name": "Second Faith", "job": "acolyte", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Faith made solid: DEF and max HP up.", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"acolyte_b_5_mastery": {"name": "Will of Faith", "job": "acolyte", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Fists of the faithful: ATK and HIT up.", "bonus": {"ATK": 3, "HIT": 2}},
	"merchant_a_4_strike": {"name": "Axe Tornado", "job": "merchant", "branch": "a", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "Spin your axe in a tornado around you.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"merchant_a_4_guard": {"name": "Mainframe Restructure", "job": "merchant", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Reinforce your mado gear: DEF and max HP up.", "bonus": {"DEF": 3, "MAXHP_PCT": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"merchant_a_4_mastery": {"name": "Madogear License", "job": "merchant", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Pilot like a pro: HIT and move speed up.", "bonus": {"HIT": 2, "MOVE": 1}},
	"merchant_a_5_strike": {"name": "Axe Stomp", "job": "merchant", "branch": "a", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "Stomp the ground with your axe: shockwave around you.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"merchant_a_5_guard": {"name": "Two Axe Defending", "job": "merchant", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Guard with two axes: DEF and FLEE up.", "bonus": {"DEF": 2, "FLEE": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"merchant_a_5_mastery": {"name": "Two-Axe Mastery", "job": "merchant", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Master the axe: ATK and HIT up.", "bonus": {"ATK": 3, "HIT": 2}},
	"merchant_b_4_strike": {"name": "Cart Tornado", "job": "merchant", "branch": "b", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "Swing your cart in a full circle.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"merchant_b_4_guard": {"name": "Cart Boost", "job": "merchant", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Push your cart hard: move and attack speed up.", "bonus": {"MOVE": 2, "ASPD": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"merchant_b_4_mastery": {"name": "Research Report", "job": "merchant", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Notes from the lab: max HP and SP regen up.", "bonus": {"MAXHP_PCT": 1, "SPREGEN": 5}},
	"merchant_b_5_strike": {"name": "Explosive Powder", "job": "merchant", "branch": "b", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "A blast of alchemical powder around you.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"merchant_b_5_guard": {"name": "Mayhemic Thorns", "job": "merchant", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "A barrier of thorny vines: DEF up.", "bonus": {"DEF": 3, "MAXHP_PCT": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"merchant_b_5_mastery": {"name": "Bionic Pharmacy", "job": "merchant", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Brew better medicine: healing and HP regen up.", "bonus": {"HEAL_PCT": 3, "HPREGEN": 5}},
	"thief_a_4_strike": {"name": "Counter Slash", "job": "thief", "branch": "a", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "Whirl your blades through every enemy nearby.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"thief_a_4_guard": {"name": "Hallucination Walk", "job": "thief", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Leave phantoms behind: FLEE way up.", "bonus": {"FLEE": 4, "DEF": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"thief_a_4_mastery": {"name": "Research New Poison", "job": "thief", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Brew new poisons: ATK and poison chance up.", "bonus": {"ATK": 2, "POISON": 1}},
	"thief_a_5_strike": {"name": "Impact Crater", "job": "thief", "branch": "a", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "Spin into the ground and blast a crater around you.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"thief_a_5_guard": {"name": "Shadow Exceed", "job": "thief", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Wrap yourself in shadow: FLEE and CRIT up.", "bonus": {"FLEE": 3, "CRIT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"thief_a_5_mastery": {"name": "Dagger and Throwing Mastery", "job": "thief", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Knives in hand and in the air: ATK and CRIT up.", "bonus": {"ATK": 3, "CRIT": 1}},
	"thief_b_4_strike": {"name": "Fatal Menace", "job": "thief", "branch": "b", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "Slash everything around you and vanish.", "base": 210, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"thief_b_4_guard": {"name": "Shadow Form", "job": "thief", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Let your shadow take the hits: FLEE and DEF up.", "bonus": {"FLEE": 3, "DEF": 1}, "time0": 30, "time1": 3, "cd": 1.0},
	"thief_b_4_mastery": {"name": "Auto Shadow Spell", "job": "thief", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "Copied spells fire on their own: CRIT and SP regen up.", "bonus": {"CRIT": 1, "SPREGEN": 5}},
	"thief_b_5_strike": {"name": "Abyss Square", "job": "thief", "branch": "b", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "Open the abyss under everyone around you.", "base": 225, "per": 20, "radius": 3.5, "cast0": 1.0, "cast1": 0.0, "cd": 1.0},
	"thief_b_5_guard": {"name": "From the Abyss", "job": "thief", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "Power from the abyss: DEF and max HP up.", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3, "cd": 1.0},
	"thief_b_5_mastery": {"name": "Abyss Mastery", "job": "thief", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "Fight like a chaser: ATK and CRIT up.", "bonus": {"ATK": 3, "CRIT": 1}},
}

## Thai text for the Ragnarok skill names, descriptions and the skill window (added on top of LocTH).
const TH := {
	"Napalm Beat": "นาปาล์มบีท", "Soul Strike": "โซลสไตรค์", "Fire Wall": "ไฟร์วอลล์", "Angelus": "แองเจลัส",
	"Sand Attack": "แซนด์แอทแทค", "Mana Recharge": "มานารีชาร์จ", "Over Thrust": "โอเวอร์ทรัสต์",
	"Maximum Over Thrust": "แม็กซิมัมโอเวอร์ทรัสต์", "Soul Breaker": "โซลเบรกเกอร์", "Basic Skill": "เบสิกสกิล",
	"First Aid": "ปฐมพยาบาล", "Faith": "เฟธ", "Shield Charge": "ชิลด์ชาร์จ", "Auto Guard": "ออโต้การ์ด",
	"Grand Cross": "แกรนด์ครอส", "Holy Cross": "โฮลี่ครอส", "Defending Aura": "ดีเฟนดิ้งออร่า",
	"Shield Chain": "ชิลด์เชน", "Gospel": "กอสเปล", "Martyr's Reckoning": "มาร์เทียร์สเรคคอนนิ่ง",
	"Music Lessons": "มิวสิคเลสซัน", "Melody Strike": "เมโลดี้สไตรค์", "Impressive Riff": "อิมเพรสซีฟริฟฟ์",
	"Unbarring Octave": "อันแบร์ริ่งออกเทฟ", "Perfect Tablature": "เพอร์เฟคแท็บเลเจอร์", "Arrow Vulcan": "แอร์โรว์วัลแคน",
	"Apple of Idun": "แอปเปิลออฟอิดุน", "Marionette Control": "แมริโอเนตต์คอนโทรล", "Magic Strings": "เมจิกสตริงส์",
	"Advanced Book": "แอดวานซ์บุ๊ก", "Earth Spike": "เอิร์ธสไปค์", "Endow Blaze": "เอ็นโดว์เบลซ",
	"Heaven's Drive": "เฮฟเวนส์ไดรฟ์", "Magic Rod": "เมจิกร็อด", "Abracadabra": "อะบราคาดาบรา", "Indulge": "อินดัลจ์",
	"Double Bolt": "ดับเบิลโบลต์", "Memorize": "เมมโมไรซ์", "Iron Hand": "ไอรอนแฮนด์", "Occult Impaction": "อ็อกคัลท์อิมแพคชั่น",
	"Summon Spirit Sphere": "ซัมมอนสปิริตสเฟียร์", "Finger Offensive": "ฟิงเกอร์ออฟเฟนซีฟ", "Spirits Recovery": "สปิริตรีคัฟเวอรี่",
	"Asura Strike": "อสุราสไตรค์", "Tiger Knuckle Fist": "ไทเกอร์นัคเคิลฟิสต์", "Steel Body": "สตีลบอดี้",
	"Raging Trifecta Blow": "เรจจิ้งไตรเฟคต้าโบลว์", "Potion Research": "โพชั่นรีเสิร์ช", "Acid Terror": "แอซิดเทอร์เรอร์",
	"Bomb": "บอมบ์", "Chemical Protection Armor": "เคมิคอลโพรเทคชั่นอาร์เมอร์", "Axe Mastery": "ความชำนาญขวาน",
	"Acid Demonstration": "แอซิดเดมอนสเตรชั่น", "Berserk Pitcher": "เบอร์เซิร์กพิตเชอร์", "Sphere Mine": "สเฟียร์ไมน์",
	"Bioethics": "ไบโอเอธิกส์", "Snatcher": "สแนทเชอร์", "Back Stab": "แบ็คสแตบ", "Tunnel Drive": "ทันเนลไดรฟ์",
	"Raid": "เรด", "Reject Sword": "รีเจกต์ซอร์ด", "Chase Walk": "เชสวอล์ก", "Intimidate": "อินทิมิเดท", "Plagiarism": "เพลจิอาริซึม",
	"Increases ATK with daggers and one-handed swords.": "เพิ่ม ATK เมื่อใช้มีดสั้นและดาบมือเดียว",
	"A fire blast that hits every enemy around you.": "ระเบิดเพลิงใส่ศัตรูทุกตัวรอบตัว",
	"Keep fighting through hits: MDEF up for a while.": "สู้ต่อแม้โดนตี: เพิ่มพลังป้องกันชั่วคราว",
	"Rain arrows on a 5x5 area.": "ยิงห่าธนูลงพื้นที่ 5x5",
	"A ghost-element blast on the target and the enemies right next to it.": "ระเบิดธาตุผีใส่เป้าหมายและศัตรูที่อยู่ติดกัน",
	"Ghost-element spirit orbs strike one enemy.": "ลูกวิญญาณธาตุผีพุ่งใส่ศัตรูหนึ่งตัว",
	"Bolts of ice strike one enemy (1 bolt per level); may freeze it.": "ลูกศรน้ำแข็งพุ่งใส่ศัตรูหนึ่งตัว (เลเวลละ 1 ลูก) อาจทำให้แข็ง",
	"Bolts of lightning strike one enemy (1 bolt per level).": "สายฟ้าฟาดศัตรูหนึ่งตัว (เลเวลละ 1 ลูก)",
	"An exploding ball of fire that hits a 5x5 area.": "ลูกไฟระเบิดโดนพื้นที่ 5x5",
	"A wall of flames that burns everything standing in it, again and again.": "กำแพงไฟเผาทุกสิ่งที่ยืนอยู่ในนั้นซ้ำแล้วซ้ำเล่า",
	"An angel's blessing hardens your body: DEF up for a while.": "พรจากเทวดาทำให้ร่างแกร่ง: เพิ่ม DEF ชั่วคราว",
	"AGI and move speed up for a while (costs 15 HP).": "เพิ่ม AGI และความเร็วเดินชั่วคราว (ใช้ HP 15)",
	"Swing your cart into the target and everything around it.": "เหวี่ยงรถเข็นใส่เป้าหมายและทุกสิ่งรอบๆ",
	"Throw a fistful of sand: earth damage that may blind and stun.": "สาดทรายใส่: ความเสียหายธาตุดิน อาจทำให้ตาบอดและมึนงง",
	"Training with spears: ATK up.": "ฝึกใช้หอก: เพิ่ม ATK",
	"Run the enemy through: 1 hit on small, 2 on medium, 3 on large monsters.": "แทงทะลุศัตรู: มอนเล็ก 1 ครั้ง กลาง 2 ครั้ง ใหญ่ 3 ครั้ง",
	"A wide sweep of the spear that hits everything in front of and around you.": "กวาดหอกเป็นวงกว้าง โดนทุกสิ่งด้านหน้าและรอบตัว",
	"Smash the target twice and knock it into the monsters behind it.": "ฟาดเป้าหมายสองครั้งให้กระเด็นชนมอนด้านหลัง",
	"Swing a two-handed sword much faster.": "ฟันดาบสองมือได้เร็วขึ้นมาก",
	"Wreathe your weapon in aura: big ATK bonus that ignores armour.": "ห่ออาวุธด้วยออร่า: เพิ่ม ATK มากแบบทะลุเกราะ",
	"Turn melee blows aside with a two-handed sword for a while.": "ปัดการโจมตีระยะประชิดด้วยดาบสองมือชั่วคราว",
	"A drilling spear thrust that strikes five times.": "แทงหอกหมุนเป็นสว่าน โดน 5 ครั้ง",
	"Fly into a battle rage: max HP and ATK way up, attack speed maxed, DEF and FLEE drop.": "คลั่งในสนามรบ: HP สูงสุดและ ATK เพิ่มมาก ความเร็วโจมตีสุด แต่ DEF และ FLEE ลด",
	"Know your prey: ATK up against brutes and insects.": "รู้จักเหยื่อ: เพิ่ม ATK ต่อสัตว์ป่าและแมลง",
	"A snare trap that pins monsters in place (no damage).": "กับดักบ่วงตรึงมอนไว้กับที่ (ไม่มีความเสียหาย)",
	"An earth trap that explodes and may stun.": "กับดักธาตุดินระเบิด อาจทำให้มึนงง",
	"A fire trap with a large blast.": "กับดักไฟระเบิดวงกว้าง",
	"Perfect focus: every stat +5, ATK, HIT and CRIT up.": "สมาธิสมบูรณ์: ทุกสเตตัส +5 เพิ่ม ATK, HIT และ CRIT",
	"A piercing shot that tears through a line of enemies; high critical chance.": "ยิงทะลุแถวศัตรู โอกาสคริติคอลสูง",
	"A ball of thunder that strikes many times and pushes the enemy back.": "ลูกบอลสายฟ้าโดนหลายครั้งและผลักศัตรูถอยหลัง",
	"Meteors crash down on a wide area; may stun.": "อุกกาบาตถล่มพื้นที่กว้าง อาจทำให้มึนงง",
	"A freezing blizzard over a wide area; strikes 10 times and freezes on the third hit.": "พายุหิมะเยือกแข็งพื้นที่กว้าง โดน 10 ครั้ง แข็งตั้งแต่ครั้งที่ 3",
	"Thunder rains on a huge area (4 waves); may blind and stun.": "สายฟ้าถล่มพื้นที่ใหญ่ (4 ระลอก) อาจทำให้ตาบอดและมึนงง",
	"Amplify your next spells: magic power up.": "ขยายพลังเวทครั้งถัดไป: เพิ่มพลังเวท",
	"Ghost-element blasts rain on the target and those near it.": "ระเบิดธาตุผีถล่มเป้าหมายและศัตรูใกล้ๆ",
	"Crushing gravity pulses over an area; damage ignores defence.": "แรงโน้มถ่วงบดขยี้พื้นที่ ความเสียหายทะลุเกราะ",
	"A holy barrier that soaks up hits: DEF and max HP up.": "บาเรียศักดิ์สิทธิ์ดูดซับการโจมตี: เพิ่ม DEF และ HP สูงสุด",
	"A hymn that doubles HP and SP recovery.": "บทสวดที่ทำให้ HP และ SP ฟื้นเร็วขึ้นสองเท่า",
	"A great cross of holy light purges an area again and again.": "กางเขนแสงศักดิ์สิทธิ์ขนาดใหญ่ชำระล้างพื้นที่ซ้ำแล้วซ้ำเล่า",
	"Divine wings that halve the damage you take.": "ปีกศักดิ์สิทธิ์ลดความเสียหายที่ได้รับลงครึ่งหนึ่ง",
	"Your prayers need less mana: SP cost of every skill down.": "บทสวดใช้มานาน้อยลง: ทุกสกิลใช้ SP น้อยลง",
	"A sacred sanctum around you: DEF, FLEE and HP regen up.": "วิหารศักดิ์สิทธิ์รอบตัว: เพิ่ม DEF, FLEE และการฟื้น HP",
	"Slam the ground and stun the monsters around you (no damage).": "ทุบพื้นให้มอนรอบตัวมึนงง (ไม่มีความเสียหาย)",
	"Get pumped: axe and mace attack speed way up.": "ฮึกเหิม: ความเร็วโจมตีด้วยขวานและกระบองเพิ่มมาก",
	"Ram the enemy with a cart full of Zeny (costs Zeny); may stun.": "พุ่งชนศัตรูด้วยรถเข็นเต็มเซนี (ใช้เซนี) อาจทำให้มึนงง",
	"Push past your limits: huge ATK bonus (costs 3,000 Zeny).": "ก้าวข้ามขีดจำกัด: เพิ่ม ATK มหาศาล (ใช้ 3,000 เซนี)",
	"Masterwork technique: full damage on every monster size.": "ฝีมือระดับปรมาจารย์: ทำความเสียหายเต็มกับมอนทุกขนาด",
	"White-hot blows that can break weapons and armour: ATK and CRIT up.": "การโจมตีร้อนแรงจนทำลายอาวุธและเกราะได้: เพิ่ม ATK และ CRIT",
	"Training with katars: ATK up.": "ฝึกใช้คาตาร์: เพิ่ม ATK",
	"Eight lightning-fast stabs; may stun.": "แทงเร็วดั่งสายฟ้า 8 ครั้ง อาจทำให้มึนงง",
	"Blades burst from the ground under the target and the enemies around it.": "ใบมีดพุ่งจากพื้นใต้เป้าหมายและศัตรูรอบๆ",
	"Coat your weapon in poison: normal attacks may poison.": "เคลือบอาวุธด้วยพิษ: การโจมตีปกติอาจทำให้ติดพิษ",
	"A deadly venom that multiplies your weapon damage; poisons on hit.": "พิษร้ายแรงทวีความเสียหายของอาวุธ โจมตีแล้วติดพิษ",
	"Hurl a blade of shadow at a distant enemy: weapon and magic damage at once.": "ขว้างใบมีดเงาใส่ศัตรูระยะไกล: ความเสียหายกายภาพและเวทพร้อมกัน",
	"Lash out at everything around you; may stun, curse or blind.": "ฟาดทุกสิ่งรอบตัว อาจทำให้มึนงง ต้องคำสาป หรือตาบอด",
	"Perfect your katar style: katar damage up.": "ขัดเกลาวิชาคาตาร์: เพิ่มความเสียหายคาตาร์",
	"Unshakable faith: max HP up and holy damage taken down.": "ศรัทธาไม่สั่นคลอน: เพิ่ม HP สูงสุดและลดความเสียหายธาตุศักดิ์สิทธิ์",
	"Slam your shield into one enemy and knock it back; may stun.": "กระแทกโล่ใส่ศัตรูให้กระเด็น อาจทำให้มึนงง",
	"Block physical attacks with your shield for a while.": "ใช้โล่ปัดป้องการโจมตีกายภาพชั่วคราว",
	"A blazing holy cross bursts out around you (costs 20% HP).": "กางเขนศักดิ์สิทธิ์ลุกโชนระเบิดรอบตัว (ใช้ HP 20%)",
	"Two holy slashes in the shape of a cross; may blind and stun.": "ฟันศักดิ์สิทธิ์สองครั้งเป็นรูปกางเขน อาจทำให้ตาบอดและมึนงง",
	"Raise your shield against ranged attacks: DEF up, but you move slower.": "ยกโล่กันการโจมตีระยะไกล: เพิ่ม DEF แต่เดินช้าลง",
	"Hurl your shield again and again: five crushing hits.": "ขว้างโล่ซ้ำแล้วซ้ำเล่า: โดนหนัก 5 ครั้ง",
	"Sing a battle hymn: holy power strikes enemies around you; may stun.": "ร้องเพลงสวดแห่งสงคราม: พลังศักดิ์สิทธิ์โจมตีศัตรูรอบตัว อาจทำให้มึนงง",
	"Burn your own life for power: ATK way up for a few attacks.": "เผาพลังชีวิตตัวเองแลกพลัง: เพิ่ม ATK มากชั่วครู่",
	"Practice with instruments: ATK and song strength up.": "ฝึกเล่นเครื่องดนตรี: เพิ่ม ATK และพลังเพลง",
	"Fire a sharp note from your instrument at one enemy.": "ยิงตัวโน้ตแหลมคมจากเครื่องดนตรีใส่ศัตรูหนึ่งตัว",
	"A driving song: attack speed up.": "เพลงจังหวะเร้าใจ: เพิ่มความเร็วโจมตี",
	"A joke so cold every monster nearby may freeze solid.": "มุกตลกฝืดจนมอนรอบตัวอาจแข็งเป็นน้ำแข็ง",
	"A whistled tune: FLEE and perfect dodge up.": "ผิวปากเป็นเพลง: เพิ่ม FLEE และการหลบสมบูรณ์",
	"Nine arrows in a blur at one enemy.": "ยิงธนูรัว 9 ดอกใส่ศัตรูหนึ่งตัว",
	"A healing song: max HP and HP regen up.": "เพลงรักษา: เพิ่ม HP สูงสุดและการฟื้น HP",
	"Pull invisible strings: every stat up for a while.": "ดึงเส้นด้ายล่องหน: เพิ่มทุกสเตตัสชั่วคราว",
	"A Poem of Bragi: cast times and skill delays shorter.": "บทกวีแห่งบรากิ: ลดเวลาร่ายและดีเลย์สกิล",
	"Fight with heavy books: ATK and attack speed up.": "ต่อสู้ด้วยหนังสือหนัก: เพิ่ม ATK และความเร็วโจมตี",
	"Spikes of stone burst up under one enemy (1 spike per level).": "หนามหินพุ่งขึ้นใต้ศัตรูหนึ่งตัว (เลเวลละ 1 อัน)",
	"Enchant your weapon with fire: ATK up.": "เสกอาวุธให้เป็นธาตุไฟ: เพิ่ม ATK",
	"The ground heaves up under a 5x5 area (1 hit per level).": "พื้นดินปะทุขึ้นในพื้นที่ 5x5 (เลเวลละ 1 ครั้ง)",
	"Absorb incoming magic as SP: DEF and SP regen up.": "ดูดซับเวทที่โดนเป็น SP: เพิ่ม DEF และการฟื้น SP",
	"Cast a random spell of a random element on an area: anything can happen.": "ร่ายเวทสุ่มธาตุสุ่มลงพื้นที่: อะไรก็เกิดขึ้นได้",
	"Turn your own vitality into mana: SP regen and max SP up.": "เปลี่ยนพลังชีวิตเป็นมานา: เพิ่มการฟื้น SP และ SP สูงสุด",
	"Double Casting: your bolt spells may fire a second volley.": "ร่ายซ้อน: เวทโบลต์อาจยิงซ้ำอีกชุด",
	"Memorise your spells: cast times halved for a while.": "จดจำเวท: เวลาร่ายลดครึ่งชั่วคราว",
	"Hardened fists: ATK up with knuckles.": "หมัดเหล็ก: เพิ่ม ATK เมื่อใช้สนับมือ",
	"Strike through armour with your spirit: the tougher the enemy, the harder it hits.": "ใช้พลังจิตทะลุเกราะ: ศัตรูยิ่งแกร่งยิ่งเจ็บ",
	"Call spirit spheres to circle you: +3 ATK per sphere.": "เรียกลูกพลังวิญญาณมาวนรอบตัว: ลูกละ +3 ATK",
	"Flick your spirit spheres at one enemy (1 sphere per level).": "ดีดลูกพลังวิญญาณใส่ศัตรูหนึ่งตัว (เลเวลละ 1 ลูก)",
	"Calm breathing: HP and SP regen up, even when overweight.": "หายใจอย่างสงบ: เพิ่มการฟื้น HP และ SP แม้ของหนักเกิน",
	"Pour every last point of SP into one devastating blow. Damage grows with the SP spent.": "ทุ่ม SP ทั้งหมดในหมัดเดียว ยิ่งใช้ SP มากยิ่งแรง",
	"A crushing punch that pins the enemy in place.": "หมัดบดขยี้ตรึงศัตรูไว้กับที่",
	"Harden your body like iron: DEF hugely up, but you move and swing slower.": "ร่างแกร่งดั่งเหล็ก: เพิ่ม DEF มหาศาล แต่เดินและโจมตีช้าลง",
	"Normal attacks may turn into a three-hit combo.": "การโจมตีปกติอาจกลายเป็นคอมโบ 3 ครั้ง",
	"Throw a flask of acid that eats through armour; may cause bleeding.": "ขว้างขวดกรดกัดกร่อนเกราะ อาจทำให้เลือดไหล",
	"Demonstration: a fire bomb that keeps burning the ground.": "เดมอนสเตรชั่น: ระเบิดไฟที่เผาพื้นต่อเนื่อง",
	"Coat your armour so nothing can break it: DEF up.": "เคลือบเกราะจนไม่มีใครทำลายได้: เพิ่ม DEF",
	"Training with axes: ATK up.": "ฝึกใช้ขวาน: เพิ่ม ATK",
	"Acid Bomb: flasks of acid and fire burst on one enemy (1 per level).": "ระเบิดกรด: ขวดกรดและไฟระเบิดใส่ศัตรูหนึ่งตัว (เลเวลละ 1 ขวด)",
	"Down an Aid Berserk Potion: ATK and attack speed up.": "ดื่มยาคลั่ง: เพิ่ม ATK และความเร็วโจมตี",
	"Summon a marine sphere that explodes around you.": "เรียกมารีนสเฟียร์มาระเบิดรอบตัว",
	"The study of life: max HP and max SP up.": "ศาสตร์แห่งชีวิต: เพิ่ม HP และ SP สูงสุด",
	"Gank: normal attacks may steal an item.": "แกงค์: การโจมตีปกติอาจขโมยไอเทมได้",
	"Slip behind the enemy and stab; never misses.": "ลอบไปด้านหลังแล้วแทง ไม่มีพลาด",
	"Move while hidden: FLEE and move speed up.": "เคลื่อนที่ขณะซ่อนตัว: เพิ่ม FLEE และความเร็วเดิน",
	"Leap from hiding and strike everything around you; may stun and blind.": "กระโจนจากที่ซ่อนโจมตีทุกสิ่งรอบตัว อาจทำให้มึนงงและตาบอด",
	"A rogue's bow trick: two arrows at once.": "ลูกเล่นธนูของโร้ก: ยิงสองดอกพร้อมกัน",
	"Turn sword blows back on their owner: DEF and FLEE up.": "สะท้อนคมดาบกลับคืนเจ้าของ: เพิ่ม DEF และ FLEE",
	"Walk unseen and quick; your next blows are stronger.": "เดินล่องหนอย่างรวดเร็ว การโจมตีถัดไปแรงขึ้น",
	"Snatch: strike the enemy and drag it away with you.": "สแนตช์: โจมตีศัตรูแล้วลากหายไปด้วยกัน",
	"Copy what you see others do: attack speed up.": "ลอกเลียนสิ่งที่เห็นผู้อื่นทำ: เพิ่มความเร็วโจมตี",
	# 2nd / transcendent job titles (branch B) and their summaries
	"Crusader": "ครูเซเดอร์", "Paladin": "พาลาดิน", "Bard": "บาร์ด", "Clown": "คลาวน์", "Sage": "เซจ", "Professor": "โปรเฟสเซอร์",
	"Monk": "มังค์", "Champion": "แชมเปี้ยน", "Alchemist": "อัลเคมิสต์", "Creator": "ครีเอเตอร์", "Rogue": "โร้ก", "Stalker": "สตอล์กเกอร์",
	"Shield and spear; holy attacks like Grand Cross, stuns and strong defence.": "โล่และหอก: โจมตีธาตุศักดิ์สิทธิ์อย่างแกรนด์ครอส สตัน และป้องกันแกร่ง",
	"Instruments; songs that boost you, freeze groups and a nine-arrow volley.": "เครื่องดนตรี: เพลงเสริมพลัง แช่แข็งกลุ่มมอน และยิงธนูรัว 9 ดอก",
	"Books; Earth Spike, Heaven's Drive, weapon endows and Abracadabra.": "หนังสือ: เอิร์ธสไปค์ เฮฟเวนส์ไดรฟ์ เสกธาตุอาวุธ และอะบราคาดาบรา",
	"Knuckles; spirit spheres, combos and the all-out Asura Strike.": "สนับมือ: ลูกพลังวิญญาณ คอมโบ และอสุราสไตรค์",
	"Axes and flasks; Acid Terror, fire bombs and marine spheres.": "ขวานและขวดยา: แอซิดเทอร์เรอร์ ระเบิดไฟ และมารีนสเฟียร์",
	"Daggers and bows; Back Stab, Raid, Snatcher and Plagiarism.": "มีดสั้นและธนู: แบ็คสแตบ เรด สแนทเชอร์ และเพลจิอาริซึม",
	# skill window
	"Apply": "ยืนยัน", "Reset": "รีเซ็ต", "Pending: %d": "รอยืนยัน: %d", "Type": "ประเภท", "Offensive": "โจมตี", "Supportive": "สนับสนุน",
	"Max Lv": "เลเวลสูงสุด", "Cast": "เวลาร่าย", "Delay": "ดีเลย์", "Duration": "ระยะเวลา", "Requires": "ต้องการ",
	"Next level": "เลเวลถัดไป", "Current level": "เลเวลปัจจุบัน", "Drag the icon onto the hotbar, or tap it to add.": "ลากไอคอนไปวางที่ฮอตคีย์ หรือแตะเพื่อเพิ่ม",
	"Cast shrinks with DEX": "เวลาร่ายลดลงตาม DEX", "Instant": "ทันที", "Target": "เป้าหมาย", "Self": "ตัวเอง", "Single enemy": "ศัตรูตัวเดียว",
	"Area around you": "พื้นที่รอบตัว", "Ground / area": "พื้นที่เป้าหมาย", "Uses all SP": "ใช้ SP ทั้งหมด", "HP cost %d%%": "ใช้ HP %d%%",
	"%d Zeny": "%d เซนี", "%.1fs": "%.1f วิ", "Asura Strike!": "อสุราสไตรค์!", "Triple!": "สามครั้ง!", "Double Cast!": "ร่ายซ้อน!", "Snatched!": "ฉกได้!",
	"Not enough HP": "HP ไม่พอ", "Hits on medium/large": "ตีหลายครั้งกับมอนกลาง/ใหญ่", "Random": "สุ่ม",
	"Ignition Break": "อิกนิชั่นเบรก",
	"A burst of rune fire that hits every enemy around you.": "ระเบิดพลังรูนเพลิงใส่ศัตรูทุกตัวรอบตัว",
	"Stonehard Skin": "สโตนฮาร์ดสกิน",
	"Rune of stone: DEF and max HP up.": "รูนหิน: เพิ่ม DEF และ HP สูงสุด",
	"Rune Mastery": "รูนมาสเตอรี",
	"Know your runes: HIT and SP regen up.": "เข้าใจพลังรูน: เพิ่ม HIT และการฟื้น SP",
	"Storm Slash": "สตอร์มสแลช",
	"A storm of sword slashes all around you.": "ฟาดดาบเป็นพายุรอบตัว โดนศัตรูทุกตัว",
	"Vigor": "วิกอร์",
	"Dragon blood boils: ATK and max HP up.": "เลือดมังกรเดือด: เพิ่ม ATK และ HP สูงสุด",
	"Two-Handed Weapon Mastery": "ความชำนาญอาวุธสองมือ",
	"Masters of the great sword: ATK and HIT up.": "เชี่ยวชาญอาวุธสองมือ: เพิ่ม ATK และ HIT",
	"Earth Drive": "เอิร์ธไดรฟ์",
	"Smash your shield into the ground: holy shockwave around you.": "กระแทกโล่ลงพื้น เกิดคลื่นศักดิ์สิทธิ์รอบตัว",
	"Prestige": "เพรสทีจ",
	"A royal guard's pride: DEF and max HP up.": "ศักดิ์ศรีองครักษ์: เพิ่ม DEF และ HP สูงสุด",
	"Force of Vanguard": "ฟอร์สออฟแวนการ์ด",
	"Stand in front: max HP and HP regen up.": "ยืนแนวหน้า: เพิ่ม HP สูงสุดและการฟื้น HP",
	"Grand Judgement": "แกรนด์จัดจ์เมนต์",
	"Swing your spear in a wide holy arc around you.": "กวาดหอกเป็นวงศักดิ์สิทธิ์รอบตัว",
	"Guard Stance": "การ์ดสแตนซ์",
	"Plant your shield: DEF way up.": "ตั้งโล่มั่น: เพิ่ม DEF มาก",
	"Shield Mastery": "ความชำนาญโล่",
	"Shield training: DEF and HIT up.": "ฝึกใช้โล่: เพิ่ม DEF และ HIT",
	"Arrow Storm": "แอร์โรว์สตอร์ม",
	"A storm of arrows on the target area.": "ยิงลูกธนูเป็นพายุลงพื้นที่เป้าหมาย",
	"Camouflage": "คาโมฟลาจ",
	"Blend into the field: FLEE and CRIT up.": "พรางตัว: เพิ่ม FLEE และ CRIT",
	"Trap Research": "แทร็ปรีเสิร์ช",
	"Study traps: max SP and SP regen up.": "ศึกษากับดัก: เพิ่ม SP สูงสุดและการฟื้น SP",
	"Gale Storm": "เกลสตอร์ม",
	"A whirlwind of arrows tears through an area.": "ลูกธนูหมุนเป็นพายุลมฉีกพื้นที่",
	"Wind Sign": "วินด์ไซน์",
	"The wind is with you: ASPD and FLEE up.": "ลมอยู่ข้างเรา: เพิ่มความเร็วโจมตีและ FLEE",
	"Hawk Mastery": "ฮอว์กมาสเตอรี",
	"Train your hawk: DEX and HIT up.": "ฝึกเหยี่ยว: เพิ่ม DEX และ HIT",
	"Severe Rainstorm": "ซีเวียร์เรนสตอร์ม",
	"A downpour of arrows on the target area.": "ห่าฝนลูกธนูลงพื้นที่เป้าหมาย",
	"Echo Song": "เอคโค่ซอง",
	"A song that echoes off your armour: DEF up.": "เพลงสะท้อนเกราะ: เพิ่ม DEF",
	"Song of Mana": "ซองออฟมานา",
	"Your voice restores mana: SP regen and max SP up.": "เสียงเพลงคืนมานา: เพิ่มการฟื้น SP และ SP สูงสุด",
	"Rose Blossom": "โรสบลอสซัม",
	"Arrows bloom like roses over an area.": "ลูกธนูผลิบานดั่งกุหลาบทั่วพื้นที่",
	"Mystic Symphony": "มิสติกซิมโฟนี",
	"A soaring symphony: DEF and max HP up.": "ซิมโฟนีลึกลับ: เพิ่ม DEF และ HP สูงสุด",
	"Stage Manner": "สเตจแมนเนอร์",
	"Perform like a star: DEX and HIT up.": "แสดงอย่างซูเปอร์สตาร์: เพิ่ม DEX และ HIT",
	"Comet": "โคเม็ท",
	"Pull a blazing comet down on the target area.": "ดึงดาวหางลุกไฟลงพื้นที่เป้าหมาย",
	"Recognized Spell": "เรคคอกไนซ์สเปล",
	"Every spell hits at full power: ATK up.": "เวททุกบทแรงเต็มที่: เพิ่ม ATK",
	"Radius": "เรเดียส",
	"Shorter casts and wider spells.": "ร่ายเร็วขึ้นและเวทกว้างขึ้น",
	"Rain of Crystal": "เรนออฟคริสตัล",
	"Shards of crystal rain on an area.": "เศษคริสตัลโปรยลงพื้นที่",
	"Climax": "ไคลแมกซ์",
	"Push your magic to its peak: ATK and cast speed up.": "เวทถึงจุดสูงสุด: เพิ่ม ATK และร่ายเร็วขึ้น",
	"Spell Enchanting": "สเปลเอนแชนติ้ง",
	"Magic soaks into your gear: INT and SP regen up.": "เวทซึมเข้าอุปกรณ์: เพิ่ม INT และการฟื้น SP",
	"Psychic Wave": "ไซคิกเวฟ",
	"Waves of mind force crash over an area.": "คลื่นพลังจิตซัดใส่พื้นที่",
	"Striking": "สไตรค์กิ้ง",
	"Charge your weapon with elemental power: ATK and DEF up.": "อัดพลังธาตุใส่อาวุธ: เพิ่ม ATK และ DEF",
	"Elemental Analysis": "เอเลเมนทัลอนาไลซิส",
	"Read the elements around you: SP regen and max SP up.": "อ่านธาตุรอบตัว: เพิ่มการฟื้น SP และ SP สูงสุด",
	"Elemental Buster": "เอเลเมนทัลบัสเตอร์",
	"Your elemental spirits blast an area.": "วิญญาณธาตุระเบิดพื้นที่",
	"Elemental Veil": "เอเลเมนทัลเวล",
	"A veil of spirits: DEF and max HP up.": "ม่านวิญญาณธาตุ: เพิ่ม DEF และ HP สูงสุด",
	"Spirit Mastery": "สปิริตมาสเตอรี",
	"Bond with your spirits: INT and SP regen up.": "ผูกพันกับวิญญาณ: เพิ่ม INT และการฟื้น SP",
	"Adoramus": "อโดรามุส",
	"A spear of holy light strikes an area and blinds.": "หอกแสงศักดิ์สิทธิ์ทิ่มพื้นที่และทำให้ตาบอด",
	"Praefatio": "พรีฟาติโอ",
	"A holy barrier for you and your party: DEF and max HP up.": "บาเรียศักดิ์สิทธิ์: เพิ่ม DEF และ HP สูงสุด",
	"Clementia": "เคลเมนเทีย",
	"Mercy of the gods: healing and SP regen up.": "เมตตาแห่งเทพ: เพิ่มการรักษาและการฟื้น SP",
	"Pneumaticus Procella": "นิวแมติคัสโพรเซลลา",
	"A storm of holy wind over an area.": "พายุลมศักดิ์สิทธิ์ทั่วพื้นที่",
	"Presens Acies": "พรีเซนส์อาซีส",
	"Sharpened senses: DEF and CRIT up.": "ประสาทสัมผัสเฉียบคม: เพิ่ม DEF และ CRIT",
	"Mace Book Mastery": "ความชำนาญคทาและคัมภีร์",
	"Fight with mace and book: ATK and HIT up.": "สู้ด้วยคทาและคัมภีร์: เพิ่ม ATK และ HIT",
	"Rampage Blast": "แรมเพจบลาสต์",
	"Release your spheres in a blast over an area.": "ปล่อยลูกพลังระเบิดใส่พื้นที่",
	"Lightning Walk": "ไลท์นิ่งวอล์ก",
	"Step aside like lightning: FLEE and DEF up.": "หลบเร็วดั่งสายฟ้า: เพิ่ม FLEE และ DEF",
	"Raising Dragon": "เรซซิ่งดราก้อน",
	"The dragon within: max HP and SP regen up.": "มังกรในกาย: เพิ่ม HP สูงสุดและการฟื้น SP",
	"Massive Flame Blaster": "แมสซีฟเฟลมบลาสเตอร์",
	"Holy flames explode across an area.": "เปลวไฟศักดิ์สิทธิ์ระเบิดทั่วพื้นที่",
	"Second Faith": "เซคันด์เฟธ",
	"Faith made solid: DEF and max HP up.": "ศรัทธาเป็นเกราะ: เพิ่ม DEF และ HP สูงสุด",
	"Will of Faith": "วิลออฟเฟธ",
	"Fists of the faithful: ATK and HIT up.": "หมัดแห่งศรัทธา: เพิ่ม ATK และ HIT",
	"Axe Tornado": "แอกซ์ทอร์นาโด",
	"Spin your axe in a tornado around you.": "หมุนขวานเป็นพายุรอบตัว",
	"Mainframe Restructure": "เมนเฟรมรีสตรัคเจอร์",
	"Reinforce your mado gear: DEF and max HP up.": "เสริมโครงมาโดเกียร์: เพิ่ม DEF และ HP สูงสุด",
	"Madogear License": "ใบขับขี่มาโดเกียร์",
	"Pilot like a pro: HIT and move speed up.": "ขับเก่ง: เพิ่ม HIT และความเร็วเดิน",
	"Axe Stomp": "แอกซ์สตอมป์",
	"Stomp the ground with your axe: shockwave around you.": "กระทืบขวานลงพื้น เกิดคลื่นกระแทกรอบตัว",
	"Two Axe Defending": "ทูแอกซ์ดีเฟนดิ้ง",
	"Guard with two axes: DEF and FLEE up.": "ป้องกันด้วยขวานคู่: เพิ่ม DEF และ FLEE",
	"Two-Axe Mastery": "ความชำนาญขวานคู่",
	"Master the axe: ATK and HIT up.": "เชี่ยวชาญขวาน: เพิ่ม ATK และ HIT",
	"Cart Tornado": "คาร์ททอร์นาโด",
	"Swing your cart in a full circle.": "เหวี่ยงรถเข็นหมุนรอบตัว",
	"Cart Boost": "คาร์ทบูสต์",
	"Push your cart hard: move and attack speed up.": "เข็นรถเต็มแรง: เพิ่มความเร็วเดินและโจมตี",
	"Research Report": "รีเสิร์ชรีพอร์ต",
	"Notes from the lab: max HP and SP regen up.": "บันทึกจากห้องแล็บ: เพิ่ม HP สูงสุดและการฟื้น SP",
	"Explosive Powder": "เอ็กซ์โพลซีฟพาวเดอร์",
	"A blast of alchemical powder around you.": "ผงเล่นแร่ระเบิดรอบตัว",
	"Mayhemic Thorns": "เมย์เฮมมิกธอร์นส์",
	"A barrier of thorny vines: DEF up.": "บาเรียเถาหนาม: เพิ่ม DEF",
	"Bionic Pharmacy": "ไบโอนิกฟาร์มาซี",
	"Brew better medicine: healing and HP regen up.": "ปรุงยาได้ดีขึ้น: เพิ่มการรักษาและการฟื้น HP",
	"Counter Slash": "เคาน์เตอร์สแลช",
	"Whirl your blades through every enemy nearby.": "หมุนใบมีดฟันศัตรูรอบตัว",
	"Hallucination Walk": "ฮาลูซิเนชั่นวอล์ก",
	"Leave phantoms behind: FLEE way up.": "ทิ้งเงาลวงตา: เพิ่ม FLEE มาก",
	"Research New Poison": "รีเสิร์ชนิวพอยซัน",
	"Brew new poisons: ATK and poison chance up.": "คิดค้นยาพิษใหม่: เพิ่ม ATK และโอกาสติดพิษ",
	"Impact Crater": "อิมแพกต์เครเตอร์",
	"Spin into the ground and blast a crater around you.": "หมุนตัวกระแทกพื้นจนเป็นหลุมรอบตัว",
	"Shadow Exceed": "แชโดว์เอ็กซีด",
	"Wrap yourself in shadow: FLEE and CRIT up.": "ห่อหุ้มด้วยเงา: เพิ่ม FLEE และ CRIT",
	"Dagger and Throwing Mastery": "ความชำนาญมีดและอาวุธขว้าง",
	"Knives in hand and in the air: ATK and CRIT up.": "มีดในมือและมีดขว้าง: เพิ่ม ATK และ CRIT",
	"Fatal Menace": "เฟทัลเมนาซ",
	"Slash everything around you and vanish.": "ฟันทุกสิ่งรอบตัวแล้วหายตัว",
	"Shadow Form": "แชโดว์ฟอร์ม",
	"Let your shadow take the hits: FLEE and DEF up.": "ให้เงารับแทน: เพิ่ม FLEE และ DEF",
	"Auto Shadow Spell": "ออโต้แชโดว์สเปล",
	"Copied spells fire on their own: CRIT and SP regen up.": "เวทที่ก๊อปมาร่ายเอง: เพิ่ม CRIT และการฟื้น SP",
	"Abyss Square": "อะบิสสแควร์",
	"Open the abyss under everyone around you.": "เปิดหุบเหวใต้ศัตรูรอบตัว",
	"From the Abyss": "ฟรอมดิอะบิส",
	"Power from the abyss: DEF and max HP up.": "พลังจากหุบเหว: เพิ่ม DEF และ HP สูงสุด",
	"Abyss Mastery": "อะบิสมาสเตอรี",
	"Fight like a chaser: ATK and CRIT up.": "สู้แบบผู้ไล่ล่า: เพิ่ม ATK และ CRIT",
}

## Skill lists per base job and tier (tier 1 = first job, 2 = second job, 3 = transcendent).
const JOB_SKILLS := {
	"swordsman": [["bash", "magnum_break", "endure", "sword_mastery", "hp_recovery"],
		["pierce", "brandish_spear", "bowling_bash", "two_hand_quicken", "spear_mastery"],
		["spiral_pierce", "aura_blade", "berserk", "parrying"]],
	"archer": [["double_strafe", "arrow_shower", "improve_concentration", "owls_eye", "vultures_eye"],
		["blitz_beat", "ankle_snare", "land_mine", "claymore_trap", "beast_bane"],
		["falcon_assault", "sharp_shooting", "true_sight", "wind_walk"]],
	"mage": [["napalm_beat", "soul_strike", "fire_bolt", "cold_bolt", "lightning_bolt", "fire_ball", "fire_wall", "sp_recovery"],
		["frost_diver", "jupitel_thunder", "meteor_storm", "storm_gust", "lord_of_vermilion"],
		["napalm_vulcan", "gravitation_field", "mystical_amplification", "soul_drain"]],
	"acolyte": [["heal", "holy_light", "blessing", "increase_agi", "angelus", "divine_protection"],
		["sanctuary", "magnus_exorcismus", "kyrie_eleison", "magnificat", "impositio_manus"],
		["assumptio", "basilica", "meditatio", "judex"]],
	"merchant": [["mammonite", "cart_revolution", "discount", "overcharge", "enlarge_weight"],
		["hammer_fall", "adrenaline_rush", "power_thrust", "maximize_power", "weaponry_research"],
		["cart_termination", "maximum_overthrust", "meltdown", "weapon_perfection"]],
	"thief": [["envenom", "sand_attack", "steal", "double_attack", "improve_dodge"],
		["sonic_blow", "grimtooth", "cloaking", "enchant_poison", "katar_mastery"],
		["soul_destroyer", "meteor_assault", "enchant_deadly_poison", "advanced_katar"]],
}

## Branch B 2nd / 3rd job skill lists (branch A uses JOB_SKILLS[1] and [2]).
const JOB_SKILLS_B := {
	"swordsman": [["shield_rush", "radiant_cross", "lance_charge", "aegis_vow", "bulwark_training"],
		["judgement_lance", "sanctified_ground", "holy_bastion", "guardian_spirit"]],
	"archer": [["dissonant_chord", "briar_lullaby", "rhythm_of_haste", "resonant_strings", "stage_presence"],
		["whiplash_volley", "crescendo", "ballad_of_vigor", "virtuoso_focus"]],
	"mage": [["stone_lance", "quicksand_pit", "elemental_infusion", "spell_ward", "tome_study"],
		["chain_spark", "arcane_comet", "runic_aegis", "mana_flow"]],
	"acolyte": [["palm_strike", "chi_burst", "inner_spheres", "iron_fist", "steady_breath"],
		["thousand_palms", "rising_dragon_kick", "zen_guard", "sky_resolve"]],
	"merchant": [["acid_flask", "fire_flask", "alloy_coating", "potion_lore", "clockwork_sights"],
		["golem_smash", "shrapnel_bomb", "elixir_rush", "master_alchemy"]],
	"thief": [["dirty_trick", "trick_shot", "knife_fan", "smoke_veil", "sleight_of_hand"],
		["ambush_combo", "phantom_blades", "shadow_step", "lucky_charm"]],
}
const NOVICE_SKILLS := ["basic_training", "field_dressing"]

## Branch B job titles: [2nd job, 3rd job].
const TIERS_B := {
	"swordsman": ["Crusader", "Paladin"],
	"archer": ["Bard", "Clown"],
	"mage": ["Sage", "Professor"],
	"acolyte": ["Monk", "Champion"],
	"merchant": ["Alchemist", "Creator"],
	"thief": ["Rogue", "Stalker"],
}
## One line about each 2nd job, shown when choosing a branch.
const BRANCH_DESC := {
	"swordsman": {"a": "Two-handed swords and spears; heavy single-target and sweeping attacks.",
		"b": "Shield and spear; holy attacks like Grand Cross, stuns and strong defence."},
	"archer": {"a": "Bows, traps and a falcon; long-range burst damage.",
		"b": "Instruments; songs that boost you, freeze groups and a nine-arrow volley."},
	"mage": {"a": "Staves; huge elemental area spells.",
		"b": "Books; Earth Spike, Heaven's Drive, weapon endows and Abracadabra."},
	"acolyte": {"a": "Maces and staves; healing, holy light and protective prayers.",
		"b": "Knuckles; spirit spheres, combos and the all-out Asura Strike."},
	"merchant": {"a": "Axes and maces; forging, raw power and attack-speed buffs.",
		"b": "Axes and flasks; Acid Terror, fire bombs and marine spheres."},
	"thief": {"a": "Katars and daggers; critical hits and deadly poison.",
		"b": "Daggers and bows; Back Stab, Raid, Snatcher and Plagiarism."},
}

## Job levels: max job level per tier (0 = Novice) and the job level needed to change job.
const ADVANCED_SKILLS = {"swordsman:a:4": ["swordsman_a_4_strike", "swordsman_a_4_guard", "swordsman_a_4_mastery"], "swordsman:a:5": ["swordsman_a_5_strike", "swordsman_a_5_guard", "swordsman_a_5_mastery"], "swordsman:b:4": ["swordsman_b_4_strike", "swordsman_b_4_guard", "swordsman_b_4_mastery"], "swordsman:b:5": ["swordsman_b_5_strike", "swordsman_b_5_guard", "swordsman_b_5_mastery"], "archer:a:4": ["archer_a_4_strike", "archer_a_4_guard", "archer_a_4_mastery"], "archer:a:5": ["archer_a_5_strike", "archer_a_5_guard", "archer_a_5_mastery"], "archer:b:4": ["archer_b_4_strike", "archer_b_4_guard", "archer_b_4_mastery"], "archer:b:5": ["archer_b_5_strike", "archer_b_5_guard", "archer_b_5_mastery"], "mage:a:4": ["mage_a_4_strike", "mage_a_4_guard", "mage_a_4_mastery"], "mage:a:5": ["mage_a_5_strike", "mage_a_5_guard", "mage_a_5_mastery"], "mage:b:4": ["mage_b_4_strike", "mage_b_4_guard", "mage_b_4_mastery"], "mage:b:5": ["mage_b_5_strike", "mage_b_5_guard", "mage_b_5_mastery"], "acolyte:a:4": ["acolyte_a_4_strike", "acolyte_a_4_guard", "acolyte_a_4_mastery"], "acolyte:a:5": ["acolyte_a_5_strike", "acolyte_a_5_guard", "acolyte_a_5_mastery"], "acolyte:b:4": ["acolyte_b_4_strike", "acolyte_b_4_guard", "acolyte_b_4_mastery"], "acolyte:b:5": ["acolyte_b_5_strike", "acolyte_b_5_guard", "acolyte_b_5_mastery"], "merchant:a:4": ["merchant_a_4_strike", "merchant_a_4_guard", "merchant_a_4_mastery"], "merchant:a:5": ["merchant_a_5_strike", "merchant_a_5_guard", "merchant_a_5_mastery"], "merchant:b:4": ["merchant_b_4_strike", "merchant_b_4_guard", "merchant_b_4_mastery"], "merchant:b:5": ["merchant_b_5_strike", "merchant_b_5_guard", "merchant_b_5_mastery"], "thief:a:4": ["thief_a_4_strike", "thief_a_4_guard", "thief_a_4_mastery"], "thief:a:5": ["thief_a_5_strike", "thief_a_5_guard", "thief_a_5_mastery"], "thief:b:4": ["thief_b_4_strike", "thief_b_4_guard", "thief_b_4_mastery"], "thief:b:5": ["thief_b_5_strike", "thief_b_5_guard", "thief_b_5_mastery"]}
const ADVANCED_NAMES = {"swordsman:a:4": "Rune Knight", "swordsman:a:5": "Dragon Knight", "swordsman:b:4": "Royal Guard", "swordsman:b:5": "Imperial Guard", "archer:a:4": "Ranger", "archer:a:5": "Windhawk", "archer:b:4": "Minstrel", "archer:b:5": "Troubadour", "mage:a:4": "Warlock", "mage:a:5": "Arch Mage", "mage:b:4": "Sorcerer", "mage:b:5": "Elemental Master", "acolyte:a:4": "Arch Bishop", "acolyte:a:5": "Cardinal", "acolyte:b:4": "Sura", "acolyte:b:5": "Inquisitor", "merchant:a:4": "Mechanic", "merchant:a:5": "Meister", "merchant:b:4": "Genetic", "merchant:b:5": "Biolo", "thief:a:4": "Guillotine Cross", "thief:a:5": "Shadow Cross", "thief:b:4": "Shadow Chaser", "thief:b:5": "Abyss Chaser"}
const JOB_MAX := [10, 50, 50, 50, 40, 40]
const JOB_CHANGE_AT := [10, 40, 40, 40, 30]
## Base level also needed for the 2nd / 3rd job change (keeps the old pacing).
const JOB_CHANGE_BASE := [1, 12, 24, 45, 65]
## The base-level band each tier's job levels are paced against (job EXP curve).
const JOB_BAND := [[1, 4], [4, 14], [12, 28], [24, 45], [45, 65], [65, 99]]


## Job titles per tier and what the job change needs:
## base level and the number of skill levels already learned.
const TIERS := {
	"swordsman": ["Swordsman", "Knight", "Lord Knight"],
	"archer": ["Archer", "Hunter", "Sniper"],
	"mage": ["Mage", "Wizard", "High Wizard"],
	"acolyte": ["Acolyte", "Priest", "High Priest"],
	"merchant": ["Merchant", "Blacksmith", "Whitesmith"],
	"thief": ["Thief", "Assassin", "Assassin Cross"],
}
const TIER_LEVEL := [1, 12, 24]
const TIER_POINTS := [0, 10, 25]
const TIER_LABEL := ["ขั้น 1", "ขั้น 2", "ขั้น 3", "ขั้น 4", "ขั้น 5"]


static func tier(id: String) -> int:
	return int(info(id).get("tier", 1))


static func tier_skills(job_id: String, t: int, branch := "a") -> Array:
	if t <= 0 or job_id == "novice":
		return NOVICE_SKILLS if t <= 0 else []
	if t >= 4:
		return ADVANCED_SKILLS.get("%s:%s:%d" % [job_id, branch, t], [])
	if t >= 2 and branch == "b" and JOB_SKILLS_B.has(job_id):
		return JOB_SKILLS_B[job_id][t - 2]
	var all: Array = JOB_SKILLS.get(job_id, [[]])
	return all[t - 1] if t - 1 < all.size() else []


static func tier_name(job_id: String, t: int, branch := "a") -> String:
	if t <= 0 or job_id == "novice":
		return "Novice"
	if t >= 4:
		return ADVANCED_NAMES.get("%s:%s:%d" % [job_id, branch, t], "?")
	if t >= 2 and branch == "b" and TIERS_B.has(job_id):
		return TIERS_B[job_id][t - 2]
	var names: Array = TIERS.get(job_id, ["Novice"])
	return names[clampi(t - 1, 0, names.size() - 1)]


## Branch a skill belongs to ("" for 1st job / novice skills).
static func branch_of(id: String) -> String:
	if tier(id) < 2:
		return ""
	return String(info(id).get("branch", "a"))


## Tier label: Novice / 1st Job / 2nd Job / 3rd Job.
static func tier_label(t: int) -> String:
	return "Novice" if t <= 0 else TIER_LABEL[clampi(t - 1, 0, 4)]


## Body motion for a skill (KnightModel.SKILL_MOVES), chosen from the skill's
## kind, the weapon in hand and the job's fighting style. A skill may set "anim".
const THROWN := ["acid_flask", "fire_flask", "cart_revolution", "soul_destroyer", "grimtooth", "golem_smash", "shrapnel_bomb",
	"land_mine", "ankle_snare", "claymore_trap", "judgement_lance", "sand_attack"]
const KICKS := []
const SONGS := ["dissonant_chord", "briar_lullaby", "rhythm_of_haste", "stage_presence", "ballad_of_vigor", "whiplash_volley",
	"virtuoso_focus", "sanctified_ground"]


## Ragnarok-style motion for each skill (anything not listed falls back to the type rules below).
const ANIM := {
	"bash": "power_strike", "magnum_break": "slam", "endure": "power_up", "pierce": "thrust", "brandish_spear": "sweep",
	"bowling_bash": "sweep", "two_hand_quicken": "power_up", "aura_blade": "power_up", "parrying": "power_up",
	"spiral_pierce": "spiral", "berserk": "power_up", "shield_rush": "shield_bash", "lance_charge": "cross_slash",
	"radiant_cross": "cross_pose", "sanctified_ground": "cross_pose", "guardian_spirit": "power_up", "aegis_vow": "power_up",
	"holy_bastion": "power_up", "blitz_beat": "falcon", "falcon_assault": "falcon", "ankle_snare": "set_trap",
	"land_mine": "set_trap", "claymore_trap": "set_trap", "sharp_shooting": "aim_shot", "crescendo": "volley",
	"frost_diver": "cast_ground", "stone_lance": "cast_ground", "quicksand_pit": "cast_ground", "fire_wall": "cast_area",
	"mammonite": "chop", "cart_revolution": "spin", "hammer_fall": "slam", "cart_termination": "dash",
	"adrenaline_rush": "power_up", "power_thrust": "power_up", "maximize_power": "power_up", "maximum_overthrust": "power_up",
	"meltdown": "power_up", "envenom": "quick", "sonic_blow": "flurry", "grimtooth": "ground_stab",
	"enchant_deadly_poison": "power_up", "meteor_assault": "spin", "dirty_trick": "dash_stab", "knife_fan": "spin",
	"ambush_combo": "dash", "palm_strike": "palm", "thousand_palms": "asura", "rising_dragon_kick": "uppercut",
	"zen_guard": "power_up", "chi_burst": "throw",
}


static func anim_kind(id: String, weapon_kind: String, style: String) -> String:
	var s := info(id)
	if s.has("anim"):
		return String(s.anim)
	if ANIM.has(id):
		return String(ANIM[id])
	if id in SONGS:
		return "song"
	if id in KICKS:
		return "kick"
	var fists := weapon_kind in ["knuckle", "none"]
	var bow := weapon_kind == "bow"
	var caster := style == "cast" or weapon_kind in ["staff", "book"]
	match String(s.get("type", "")):
		"buff":
			return "buff"
		"heal":
			return "pray"
		"steal":
			return "quick"
		"melee":
			if fists:
				return "palm"
			return "thrust_combo" if hits(id, 5) >= 3 else "power_strike"
		"bolt":
			if id in THROWN:
				return "throw"
			if bow or String(s.get("proj", "")) == "arrow":
				return "volley" if bow else "throw"
			return "cast_bolt"
		"aoe_self":
			if id in THROWN:
				return "throw"
			if caster:
				return "cast_area"
			if fists:
				return "palm"
			return "slam" if float(s.get("radius", 3.0)) >= 3.5 or weapon_kind in ["mace", "axe", "greatsword"] else "spin"
		"aoe_target":
			if id in THROWN:
				return "throw"
			if bow:
				return "sky_shot"
			if caster or s.has("proj"):
				return "cast_area"
			return "slam"
	return "power_strike"


static func bonus(id: String) -> Dictionary:
	return info(id).get("bonus", {})


static func info(id: String) -> Dictionary:
	return SKILLS.get(id, {})


static func is_active(id: String) -> bool:
	return info(id).get("type", "passive") != "passive"


## Value of a per-level table (the last entry repeats) or a plain number.
static func _at(v, lv: int) -> float:
	if v is Array:
		return float(v[clampi(lv - 1, 0, v.size() - 1)]) if v.size() > 0 else 0.0
	return float(v)


## SP cost before skill bonuses (what the tables say).
static func base_sp(id: String, lv: int) -> int:
	var s := info(id)
	if s.has("sp"):
		return int(_at(s.sp, lv))
	return maxi(0, int(s.get("sp0", 0) + s.get("sp1", 0.0) * lv))


static func sp_cost(id: String, lv: int) -> int:
	var cost := base_sp(id, lv)
	var g := _game()
	if g and cost > 1:
		cost = maxi(1, int(round(cost * (1.0 - clampf(g.skill_bonus("SPCOST"), 0.0, 50.0) / 100.0))))
	return cost


static func _game() -> Node:
	var ml := Engine.get_main_loop() as SceneTree
	return ml.root.get_node_or_null("Game") if ml else null


static func mult(id: String, lv: int) -> float:
	var s := info(id)
	if s.has("dmg"):
		return _at(s.dmg, lv) / 100.0
	return (s.get("base", 100) + s.get("per", 0) * lv) / 100.0


static func hits(id: String, lv: int) -> int:
	var s := info(id)
	if s.get("hits_per_lv", false):
		return maxi(1, lv)
	if s.has("hits_t"):
		return maxi(1, int(_at(s.hits_t, lv)))
	if s.has("hits0"):
		return maxi(1, int(s.hits0 + s.get("hits1", 0.0) * lv))
	return int(s.get("hits", 1))


## Stat bonus of one skill at a level: {KEY: per-level} or {KEY: [base, per-level]}.
static func bonus_value(id: String, key: String, lv: int) -> float:
	var v = bonus(id).get(key, 0.0)
	if v is Array:
		return float(v[0]) + float(v[1]) * lv if v.size() > 1 else float(v[0])
	return float(v) * lv


## Chance (%) and duration of the on-hit status effect.
static func status_chance(id: String, lv: int) -> float:
	var s := info(id)
	return s.get("chance0", 0.0) + s.get("chance1", 0.0) * lv


static func status_time(id: String, lv: int) -> float:
	var s := info(id)
	return s.get("stime0", 2.0) + s.get("stime1", 0.0) * lv


## Seconds before a skill can be used again (shown as a sweep on the hotbar).
## A skill may set "cd"; otherwise it depends on the kind of skill.
const TYPE_CD := {"melee": 1.5, "bolt": 2.0, "aoe_self": 5.0, "aoe_target": 6.0, "buff": 8.0, "heal": 3.0, "steal": 3.0}


static func cooldown(id: String, lv: int) -> float:
	var s := info(id)
	if s.has("cd"):
		return _at(s.cd, lv)
	if s.has("cd0"):
		return float(s.cd0) + float(s.get("cd1", 0.0)) * lv
	return float(TYPE_CD.get(s.get("type", ""), 0.0))


## Base cast time from the tables (before DEX).
static func cast_time(id: String, lv: int) -> float:
	var s := info(id)
	if s.has("cast"):
		return maxf(0.0, _at(s.cast, lv))
	return maxf(0.0, s.get("cast0", 0.0) + s.get("cast1", 0.0) * lv)


## Real cast time like Ragnarok: shrinks with DEX (none at 150 DEX) and cast-time bonuses.
static func cast_for(id: String, lv: int, dex: int, bonus_pct := 0.0) -> float:
	var ct := cast_time(id, lv) * maxf(0.0, 1.0 - dex / 150.0) * (1.0 - clampf(bonus_pct, 0.0, 90.0) / 100.0)
	return 0.0 if ct < 0.05 else ct


static func duration(id: String, lv: int) -> float:
	var s := info(id)
	if s.has("time"):
		return _at(s.time, lv)
	return s.get("time0", 0) + s.get("time1", 0) * lv


## One-line effect text for the skill window.
static func effect(id: String, lv: int) -> String:
	var s := info(id)
	lv = maxi(lv, 1)
	if not s.has("fx"):
		return _auto_effect(id, lv)
	var t: String = TranslationServer.translate(s.get("fx", ""))
	match id:
		"bash", "magnum_break", "arrow_shower", "fire_ball", "holy_light", "cart_revolution":
			return t % int(round(mult(id, lv) * 100))
		"double_strafe":
			return t % int(mult(id, lv) * 100)
		"fire_bolt", "lightning_bolt":
			return t % lv
		"cold_bolt":
			return t % [lv, lv * 3]
		"mammonite":
			return t % [int(mult(id, lv) * 100), lv * 100]
		"envenom":
			return t % [int(mult(id, lv) * 100), 10 + lv * 4]
		"vultures_eye":
			return t % [lv, lv]
		"heal":
			return t % (lv * 30)
		"steal":
			return t % (10 + lv * 6)
		"discount", "overcharge":
			return t % (5 + 2 * lv)
		"improve_concentration", "increase_agi":
			return t % (int(s.get("base", 0)) + lv)
		"enlarge_weight":
			return t % (lv * 20)
	return t % (int(s.get("per", 1)) * lv) if t.contains("%d") else t


const BONUS_LABEL := {"ATK": "ATK", "ATK_PCT": "ATK", "DEF": "DEF", "HIT": "HIT", "FLEE": "FLEE", "CRIT": "CRIT",
	"ASPD": "Attack speed", "MOVE": "Move speed", "MAXHP_PCT": "Max HP", "MAXSP_PCT": "Max SP", "HPREGEN": "HP regen",
	"SPREGEN": "SP regen", "HEAL_PCT": "Healing", "POISON": "Poison chance",
	"STR": "STR", "AGI": "AGI", "VIT": "VIT", "INT": "INT", "DEX": "DEX", "LUK": "LUK",
	"CAST": "Cast time -", "SPCOST": "SP cost -", "TRIPLE": "Triple attack", "DOUBLECAST": "Double cast", "SNATCH": "Steal on hit"}
const PCT_KEYS := ["ATK_PCT", "ASPD", "MOVE", "MAXHP_PCT", "MAXSP_PCT", "HPREGEN", "SPREGEN", "HEAL_PCT", "POISON",
	"CAST", "SPCOST", "TRIPLE", "DOUBLECAST", "SNATCH"]


static func _tr(t: String) -> String:
	return TranslationServer.translate(t)


## Effect line built from the skill data (2nd / 3rd job skills).
static func _auto_effect(id: String, lv: int) -> String:
	var s := info(id)
	var parts: PackedStringArray = []
	match s.type:
		"melee", "bolt", "aoe_self", "aoe_target":
			var h := hits(id, lv)
			var pct := int(round(mult(id, lv) * 100))
			if s.get("sp_all", false):
				parts.append(_tr("Uses all SP"))
			elif s.get("random", false):
				parts.append("%s %d%%" % [_tr("Random"), pct])
			elif s.get("hits_size", false):
				parts.append(_tr("Damage %d%%") % pct + " (" + _tr("Hits on medium/large") + ")")
			elif not s.get("nodmg", false):
				parts.append(_tr("%d hits x %d%%") % [h, pct] if h > 1 else _tr("Damage %d%%") % pct)
			if s.type.begins_with("aoe"):
				parts.append(_tr("area"))
			if s.has("status"):
				parts.append("%s %d%%" % [_tr({"freeze": "Freeze", "stun": "Stun", "poison": "Poison"}[s.status]), int(status_chance(id, lv))])
			if s.has("hp_pct"):
				parts.append(_tr("HP cost %d%%") % int(s.hp_pct))
			if s.has("zeny"):
				parts.append("%d Zeny" % (int(s.zeny) * lv))
		"heal":
			parts.append(_tr("Heals about %d HP") % int(lv * 30 * s.get("heal_mult", 1.0)))
	var b := bonus(id)
	for k in b:
		var v: int = int(round(bonus_value(id, k, lv)))
		parts.append("%s %s%d%s" % [_tr(BONUS_LABEL.get(k, k)), "+" if v >= 0 else "", v, "%" if k in PCT_KEYS else ""])
	if s.type == "buff":
		parts.append(_tr("%ds") % int(duration(id, lv)))
	return ", ".join(parts)


static var _icon_cache := {}


## Skill icon (painted 64x64 art in assets/icons/skills, scaled to `px`).
static func icon(id: String, px := 32) -> Texture2D:
	var key := "%s@%d" % [id, px]
	if _icon_cache.has(key):
		return _icon_cache[key]
	var path := "res://assets/icons/skills/%s.png" % id
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var src := load(path) as Texture2D
		if src:
			var img := src.get_image()
			if img:
				if img.is_compressed():
					img.decompress()
				img.resize(px, px, Image.INTERPOLATE_LANCZOS)
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		# icons added later ship as plain PNG files (no import step)
		var raw := "res://assets/icons/skills_ro/%s.png" % id
		if FileAccess.file_exists(raw):
			var img := Image.new()
			if img.load_png_from_buffer(FileAccess.get_file_as_bytes(raw)) == OK:
				img.resize(px, px, Image.INTERPOLATE_LANCZOS)
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		tex = _pixel_icon(id)
	_icon_cache[key] = tex
	return tex


## Fallback: small procedural pixel icon.
static func _pixel_icon(id: String) -> Texture2D:
	var kind: String = info(id).get("icon", "star")
	if UiIcons.ICONS.has(kind):
		return UiIcons.tex(kind, 2)
	if kind in ["sword", "bow", "dagger"]:
		return ImageTexture.create_from_image(Avatar.weapon_image("iron_sword" if kind == "sword" else kind, 32))
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5)
			var l := d.length()
			var a := atan2(d.y, d.x)
			var c := Color(0, 0, 0, 0)
			match kind:
				"bash":
					if l < 4.5 + 2.5 * absf(sin(a * 4.0)):
						c = Color(1.0, 0.55 + 0.3 * (1.0 - l / 7.0), 0.15)
				"fire":
					var fy := 15 - y
					if absf(d.x) < (fy * 0.45 if fy < 10 else (15 - fy) * 0.9) and fy > 1:
						c = Color(1.0, 0.85, 0.3) if absf(d.x) < fy * 0.2 else Color(1.0, 0.4, 0.1)
				"ice":
					if (absi(x - 7) <= 1 or absi(y - 7) <= 1 or absi(x - y) <= 1 or absi(x + y - 15) <= 1) and l < 7.5:
						c = Color(0.75, 0.92, 1.0) if l < 3 else Color(0.35, 0.7, 1.0)
				"bolt":
					var zx := 9 - y * 0.6 if y < 8 else 13 - y * 0.6
					if absf(x - zx) < 1.6 and y > 0 and y < 15:
						c = Color(1.0, 0.95, 0.4)
				"holy":
					if (absi(x - 7) <= 1 and y >= 1 and y <= 14) or (absi(y - 5) <= 1 and x >= 3 and x <= 12):
						c = Color(1.0, 0.95, 0.6)
					elif l < 7.5 and l > 6.0:
						c = Color(1.0, 0.85, 0.3, 0.8)
				"poison":
					if l < 5.0:
						c = Color(0.55, 0.85, 0.25) if l > 2 else Color(0.85, 1.0, 0.5)
					elif y < 6 and absi(x - 7) <= 1:
						c = Color(0.4, 0.7, 0.2)
			img.set_pixel(x, y, c)
	img.resize(32, 32, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)
