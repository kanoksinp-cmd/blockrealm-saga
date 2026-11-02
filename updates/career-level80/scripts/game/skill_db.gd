class_name SkillDB
extends RefCounted
## First-job skills in the classic MMORPG style.
## type: passive / melee / bolt / aoe_self / aoe_target / heal / buff / steal
## sp = sp0 + sp1 * level.  Effects are applied by the player (player.gd) and the
## stat bonuses by the Game autoload (game_state.gd).

const SKILLS := {
	# ---------------------------------------------------------------- Swordsman
	"sword_mastery": {"name": "Sword Mastery", "job": "swordsman", "type": "passive", "max": 10, "icon": "sword",
		"desc": "Increases ATK with blades.", "fx": "ATK +%d", "per": 4},
	"hp_recovery": {"name": "Increase HP Recovery", "job": "swordsman", "type": "passive", "max": 10, "icon": "heart",
		"desc": "Recover more HP over time.", "fx": "HP regen +%d%%", "per": 10},
	"bash": {"name": "Bash", "job": "swordsman", "type": "melee", "max": 10, "sp0": 7, "sp1": 0.8, "icon": "bash",
		"desc": "A crushing blow on one enemy.", "fx": "Damage %d%%", "base": 100, "per": 30},
	"magnum_break": {"name": "Magnum Break", "job": "swordsman", "type": "aoe_self", "max": 10, "sp0": 24, "sp1": 0.6, "icon": "fire",
		"desc": "A fiery blast that hits every enemy around you.", "fx": "Damage %d%%", "base": 100, "per": 20, "radius": 3.0, "color": Color(1.0, 0.5, 0.15)},
	"endure": {"name": "Endure", "job": "swordsman", "type": "buff", "max": 10, "sp0": 10, "sp1": 0.0, "icon": "shield",
		"desc": "Steel yourself: raises DEF for a while.", "fx": "DEF +%d", "per": 2, "time0": 10, "time1": 3},
	# ---------------------------------------------------------------- Archer
	"owls_eye": {"name": "Owl's Eye", "job": "archer", "type": "passive", "max": 10, "icon": "star",
		"desc": "Sharper eyes: DEX up.", "fx": "DEX +%d", "per": 1},
	"vultures_eye": {"name": "Vulture's Eye", "job": "archer", "type": "passive", "max": 10, "icon": "bow",
		"desc": "Longer range and better aim with bows.", "fx": "Range +%d, HIT +%d", "per": 1},
	"improve_concentration": {"name": "Improve Concentration", "job": "archer", "type": "buff", "max": 10, "sp0": 20, "sp1": 5, "icon": "star",
		"desc": "Focus: AGI and DEX up for a while.", "fx": "AGI/DEX +%d", "per": 1, "base": 1, "time0": 60, "time1": 20},
	"double_strafe": {"name": "Double Strafe", "job": "archer", "type": "bolt", "max": 10, "sp0": 12, "sp1": 0.0, "icon": "bow",
		"desc": "Fire two arrows at once.", "fx": "2 x %d%%", "base": 100, "per": 10, "hits": 2, "proj": "arrow"},
	"arrow_shower": {"name": "Arrow Shower", "job": "archer", "type": "aoe_target", "max": 10, "sp0": 15, "sp1": 0.0, "icon": "bow",
		"desc": "Rain arrows on the target area.", "fx": "Damage %d%% in an area", "base": 80, "per": 5, "radius": 2.5, "color": Color(0.9, 0.9, 0.8)},
	# ---------------------------------------------------------------- Mage
	"sp_recovery": {"name": "Increase SP Recovery", "job": "mage", "type": "passive", "max": 10, "icon": "drop",
		"desc": "Recover more SP over time.", "fx": "SP regen +%d%%", "per": 10},
	"fire_bolt": {"name": "Fire Bolt", "job": "mage", "type": "bolt", "max": 10, "sp0": 10, "sp1": 2, "icon": "fire",
		"desc": "Bolts of fire strike one enemy (1 bolt per level).", "fx": "%d bolts x 100%%", "base": 100, "per": 0, "hits_per_lv": true, "proj": "fire", "cast0": 0.3, "cast1": 0.15},
	"cold_bolt": {"name": "Cold Bolt", "job": "mage", "type": "bolt", "max": 10, "sp0": 10, "sp1": 2, "icon": "ice",
		"desc": "Bolts of ice; may freeze the target.", "fx": "%d bolts, freeze %d%%", "base": 100, "per": 0, "hits_per_lv": true, "proj": "ice", "cast0": 0.3, "cast1": 0.15, "freeze": 3},
	"lightning_bolt": {"name": "Lightning Bolt", "job": "mage", "type": "bolt", "max": 10, "sp0": 10, "sp1": 2, "icon": "bolt",
		"desc": "Bolts of lightning strike one enemy.", "fx": "%d bolts x 100%%", "base": 100, "per": 0, "hits_per_lv": true, "proj": "lightning", "cast0": 0.3, "cast1": 0.15},
	"fire_ball": {"name": "Fire Ball", "job": "mage", "type": "aoe_target", "max": 10, "sp0": 25, "sp1": 0.0, "icon": "fire",
		"desc": "An exploding ball of fire.", "fx": "Damage %d%% in an area", "base": 70, "per": 10, "radius": 2.5, "proj": "fire", "cast0": 1.0, "cast1": 0.0, "color": Color(1.0, 0.45, 0.1)},
	# ---------------------------------------------------------------- Acolyte
	"heal": {"name": "Heal", "job": "acolyte", "type": "heal", "max": 10, "sp0": 10, "sp1": 3, "icon": "heart",
		"desc": "Restore your HP. Stronger with INT and base level.", "fx": "Heals about %d HP"},
	"divine_protection": {"name": "Divine Protection", "job": "acolyte", "type": "passive", "max": 10, "icon": "shield",
		"desc": "The gods shield you: DEF up.", "fx": "DEF +%d", "per": 2},
	"blessing": {"name": "Blessing", "job": "acolyte", "type": "buff", "max": 10, "sp0": 24, "sp1": 4, "icon": "star",
		"desc": "STR, INT and DEX up for a while.", "fx": "STR/INT/DEX +%d", "per": 1, "time0": 40, "time1": 20},
	"increase_agi": {"name": "Increase AGI", "job": "acolyte", "type": "buff", "max": 10, "sp0": 15, "sp1": 3, "icon": "boot",
		"desc": "AGI and move speed up for a while.", "fx": "AGI +%d, move +25%%", "per": 1, "base": 2, "time0": 40, "time1": 20},
	"holy_light": {"name": "Holy Light", "job": "acolyte", "type": "bolt", "max": 5, "sp0": 15, "sp1": 0.0, "icon": "holy",
		"desc": "A ray of holy light strikes one enemy.", "fx": "Damage %d%%", "base": 125, "per": 25, "hits": 1, "proj": "holy", "cast0": 0.5, "cast1": 0.0},
	# ---------------------------------------------------------------- Merchant
	"enlarge_weight": {"name": "Enlarge Weight Limit", "job": "merchant", "type": "passive", "max": 10, "icon": "bag",
		"desc": "Carry more.", "fx": "Weight +%d", "per": 20},
	"discount": {"name": "Discount", "job": "merchant", "type": "passive", "max": 10, "icon": "coin",
		"desc": "Buy items cheaper from shops.", "fx": "Prices -%d%%", "base": 5, "per": 2},
	"overcharge": {"name": "Overcharge", "job": "merchant", "type": "passive", "max": 10, "icon": "coin",
		"desc": "Sell items for more Zeny.", "fx": "Sell +%d%%", "base": 5, "per": 2},
	"mammonite": {"name": "Mammonite", "job": "merchant", "type": "melee", "max": 10, "sp0": 5, "sp1": 0.0, "icon": "coin",
		"desc": "Smash an enemy with the power of money (costs Zeny).", "fx": "Damage %d%%, %d Zeny", "base": 100, "per": 50, "zeny": 100},
	"cart_revolution": {"name": "Cart Revolution", "job": "merchant", "type": "aoe_target", "max": 5, "sp0": 12, "sp1": 0.0, "icon": "bag",
		"desc": "Spin your cart into the target and everything near it.", "fx": "Damage %d%% in an area", "base": 130, "per": 10, "radius": 2.2, "color": Color(0.85, 0.65, 0.35)},
	# ---------------------------------------------------------------- Thief
	"double_attack": {"name": "Double Attack", "job": "thief", "type": "passive", "max": 10, "icon": "dagger",
		"desc": "Chance to strike twice with normal attacks.", "fx": "%d%% chance", "per": 5},
	"improve_dodge": {"name": "Improve Dodge", "job": "thief", "type": "passive", "max": 10, "icon": "boot",
		"desc": "FLEE up.", "fx": "FLEE +%d", "per": 3},
	"envenom": {"name": "Envenom", "job": "thief", "type": "melee", "max": 10, "sp0": 12, "sp1": 0.0, "icon": "poison",
		"desc": "A poisoned strike; may poison the target.", "fx": "Damage %d%%, poison %d%%", "base": 100, "per": 15, "poison": 4},
	"steal": {"name": "Steal", "job": "thief", "type": "steal", "max": 10, "sp0": 10, "sp1": 0.0, "icon": "bag",
		"desc": "Try to steal an item from a monster (once per monster).", "fx": "Success about %d%%"},
	# ================================================================ 2nd / 3rd job skills
	# tier 2 needs the job change at base Lv 12, tier 3 at base Lv 24 (see TIERS).
	# "bonus": stat bonuses per skill level (passives always, buffs while active).
	# "req": prerequisite skill levels.  "hits0/hits1": hits = hits0 + hits1 * lv.
	# "status": freeze / stun / poison on hit, chance = chance0 + chance1 * lv (%).
	# ---------------------------------------------------------------- Knight
	"spear_mastery": {"name": "Spear Mastery", "job": "swordsman", "tier": 2, "type": "passive", "max": 10,
		"desc": "Training with polearms: ATK and HIT up.", "bonus": {"ATK": 3, "HIT": 1}},
	"pierce": {"name": "Pierce", "job": "swordsman", "tier": 2, "type": "melee", "max": 10, "sp0": 7, "sp1": 0.3,
		"desc": "Run the enemy through three times in a row.", "base": 100, "per": 10, "hits": 3, "req": {"bash": 3}},
	"brandish_spear": {"name": "Brandish Spear", "job": "swordsman", "tier": 2, "type": "aoe_self", "max": 10, "sp0": 12, "sp1": 0.5,
		"desc": "A wide sweeping slash around you.", "base": 100, "per": 30, "radius": 3.5, "color": Color(0.9, 0.85, 0.6), "req": {"pierce": 3}},
	"bowling_bash": {"name": "Bowling Bash", "job": "swordsman", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 10, "sp1": 1,
		"desc": "Smash the target into the monsters behind it.", "base": 100, "per": 40, "radius": 2.5, "color": Color(1.0, 0.75, 0.4),
		"req": {"bash": 5, "magnum_break": 3}},
	"two_hand_quicken": {"name": "Two-Hand Quicken", "job": "swordsman", "tier": 2, "type": "buff", "max": 10, "sp0": 10, "sp1": 2,
		"desc": "Swing faster with a two-handed weapon.", "bonus": {"ASPD": 3, "CRIT": 1, "HIT": 1}, "time0": 30, "time1": 30,
		"req": {"sword_mastery": 3}},
	# ---------------------------------------------------------------- Lord Knight
	"aura_blade": {"name": "Aura Blade", "job": "swordsman", "tier": 3, "type": "buff", "max": 5, "sp0": 18, "sp1": 4,
		"desc": "Wreathe your weapon in aura: big ATK bonus.", "bonus": {"ATK": 12}, "time0": 40, "time1": 20,
		"req": {"two_hand_quicken": 3}},
	"parrying": {"name": "Parrying", "job": "swordsman", "tier": 3, "type": "passive", "max": 10,
		"desc": "Turn blows aside: DEF and FLEE up.", "bonus": {"DEF": 2, "FLEE": 2}, "req": {"two_hand_quicken": 2}},
	"spiral_pierce": {"name": "Spiral Pierce", "job": "swordsman", "tier": 3, "type": "melee", "max": 5, "sp0": 18, "sp1": 2,
		"desc": "A drilling spear thrust that strikes four times.", "base": 150, "per": 50, "hits": 4, "cast0": 0.4, "cast1": 0.0,
		"req": {"pierce": 5}},
	"berserk": {"name": "Frenzy", "job": "swordsman", "tier": 3, "type": "buff", "max": 5, "sp0": 40, "sp1": 0,
		"desc": "Fly into a battle rage: much stronger and faster, but DEF drops.", "bonus": {"ATK_PCT": 8, "ASPD": 4, "DEF": -4},
		"time0": 20, "time1": 6, "req": {"aura_blade": 3}},
	# ---------------------------------------------------------------- Hunter
	"beast_bane": {"name": "Beast Bane", "job": "archer", "tier": 2, "type": "passive", "max": 10,
		"desc": "Know your prey: ATK up.", "bonus": {"ATK": 3}},
	"blitz_beat": {"name": "Blitz Beat", "job": "archer", "tier": 2, "type": "bolt", "max": 5, "sp0": 10, "sp1": 3,
		"desc": "Your falcon dives at the enemy (1 strike per level).", "base": 90, "per": 10, "hits_per_lv": true, "proj": "arrow",
		"req": {"double_strafe": 3}},
	"ankle_snare": {"name": "Ankle Snare", "job": "archer", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 12, "sp1": 0,
		"desc": "A snare trap that pins monsters in place.", "base": 40, "per": 10, "radius": 2.0, "color": Color(0.55, 0.85, 0.4),
		"status": "stun", "chance0": 60, "chance1": 8, "stime0": 2.0, "stime1": 0.6, "req": {"improve_concentration": 1}},
	"land_mine": {"name": "Land Mine", "job": "archer", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 10, "sp1": 0,
		"desc": "An explosive trap that may stun.", "base": 160, "per": 40, "radius": 1.8, "color": Color(0.95, 0.7, 0.35),
		"status": "stun", "chance0": 30, "chance1": 6, "stime0": 1.5, "stime1": 0.0, "req": {"ankle_snare": 1}},
	"claymore_trap": {"name": "Claymore Trap", "job": "archer", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 15, "sp1": 3,
		"desc": "A blazing trap with a large blast radius.", "base": 150, "per": 50, "radius": 3.0, "color": Color(1.0, 0.45, 0.15),
		"cast0": 0.3, "cast1": 0.0, "req": {"land_mine": 2}},
	# ---------------------------------------------------------------- Sniper
	"true_sight": {"name": "True Sight", "job": "archer", "tier": 3, "type": "buff", "max": 10, "sp0": 20, "sp1": 2,
		"desc": "Perfect focus: every stat, HIT and CRIT up.",
		"bonus": {"STR": 1, "AGI": 1, "VIT": 1, "INT": 1, "DEX": 1, "LUK": 1, "HIT": 2, "CRIT": 1}, "time0": 40, "time1": 4,
		"req": {"improve_concentration": 3}},
	"falcon_assault": {"name": "Falcon Assault", "job": "archer", "tier": 3, "type": "bolt", "max": 5, "sp0": 30, "sp1": 4,
		"desc": "Your falcon strikes with all its might.", "base": 300, "per": 80, "hits": 1, "proj": "arrow", "cast0": 0.6, "cast1": 0.0,
		"req": {"blitz_beat": 3}},
	"sharp_shooting": {"name": "Sharp Shooting", "job": "archer", "tier": 3, "type": "aoe_target", "max": 5, "sp0": 18, "sp1": 2,
		"desc": "A piercing shot that tears through a group.", "base": 200, "per": 50, "radius": 2.5, "proj": "arrow",
		"color": Color(0.85, 0.95, 1.0), "cast0": 0.8, "cast1": 0.0, "req": {"double_strafe": 5}},
	"wind_walk": {"name": "Wind Walk", "job": "archer", "tier": 3, "type": "buff", "max": 10, "sp0": 20, "sp1": 2,
		"desc": "Move like the wind: FLEE and move speed up.", "bonus": {"FLEE": 2, "MOVE": 3}, "time0": 60, "time1": 6,
		"req": {"true_sight": 1}},
	# ---------------------------------------------------------------- Wizard
	"frost_diver": {"name": "Frost Diver", "job": "mage", "tier": 2, "type": "bolt", "max": 10, "sp0": 15, "sp1": 1,
		"desc": "A wave of ice that often freezes the target.", "base": 110, "per": 10, "hits": 1, "proj": "ice",
		"status": "freeze", "chance0": 35, "chance1": 3, "stime0": 3.0, "stime1": 0.2, "cast0": 0.4, "cast1": 0.0, "req": {"cold_bolt": 3}},
	"jupitel_thunder": {"name": "Jupitel Thunder", "job": "mage", "tier": 2, "type": "bolt", "max": 10, "sp0": 15, "sp1": 3,
		"desc": "A ball of thunder that strikes several times.", "base": 100, "per": 0, "hits0": 2, "hits1": 0.5, "proj": "lightning",
		"cast0": 0.5, "cast1": 0.1, "req": {"lightning_bolt": 3}},
	"meteor_storm": {"name": "Meteor Storm", "job": "mage", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 30, "sp1": 4,
		"desc": "Call down burning meteors on an area (2 waves).", "base": 125, "per": 25, "hits": 2, "radius": 3.5, "proj": "fire",
		"color": Color(1.0, 0.4, 0.1), "cast0": 1.5, "cast1": 0.05, "req": {"fire_ball": 3}},
	"storm_gust": {"name": "Storm Gust", "job": "mage", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 40, "sp1": 4,
		"desc": "A freezing blizzard over a wide area.", "base": 100, "per": 40, "radius": 3.5, "color": Color(0.6, 0.85, 1.0),
		"status": "freeze", "chance0": 30, "chance1": 2, "stime0": 3.0, "stime1": 0.0, "cast0": 1.5, "cast1": 0.1,
		"req": {"frost_diver": 1, "jupitel_thunder": 1}},
	"lord_of_vermilion": {"name": "Lord of Vermilion", "job": "mage", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 4,
		"desc": "Lightning rains on a huge area (3 waves).", "base": 100, "per": 20, "hits": 3, "radius": 4.0, "color": Color(1.0, 0.95, 0.45),
		"cast0": 2.0, "cast1": 0.05, "req": {"jupitel_thunder": 5}},
	# ---------------------------------------------------------------- High Wizard
	"mystical_amplification": {"name": "Mystical Amplification", "job": "mage", "tier": 3, "type": "buff", "max": 10, "sp0": 20, "sp1": 2,
		"desc": "Amplify your magic for a while.", "bonus": {"ATK_PCT": 5}, "time0": 45, "time1": 0},
	"soul_drain": {"name": "Soul Drain", "job": "mage", "tier": 3, "type": "passive", "max": 10,
		"desc": "Draw on the souls of the fallen: more max SP and SP regen.", "bonus": {"MAXSP_PCT": 2, "SPREGEN": 5}},
	"napalm_vulcan": {"name": "Napalm Vulcan", "job": "mage", "tier": 3, "type": "bolt", "max": 5, "sp0": 20, "sp1": 6,
		"desc": "Spirit bolts strike the enemy three times.", "base": 100, "per": 30, "hits": 3, "proj": "magic", "cast0": 0.5, "cast1": 0.0,
		"req": {"soul_drain": 2}},
	"gravitation_field": {"name": "Gravitation Field", "job": "mage", "tier": 3, "type": "aoe_target", "max": 5, "sp0": 40, "sp1": 10,
		"desc": "Crushing gravity pulses over an area (3 waves).", "base": 250, "per": 60, "hits": 3, "radius": 3.5,
		"color": Color(0.7, 0.45, 1.0), "cast0": 2.5, "cast1": 0.0, "req": {"mystical_amplification": 3}},
	# ---------------------------------------------------------------- Priest
	"sanctuary": {"name": "Sanctuary", "job": "acolyte", "tier": 2, "type": "heal", "max": 10, "sp0": 15, "sp1": 3,
		"desc": "Holy ground that restores a large amount of HP.", "heal_mult": 1.8, "req": {"heal": 3}},
	"kyrie_eleison": {"name": "Kyrie Eleison", "job": "acolyte", "tier": 2, "type": "buff", "max": 10, "sp0": 20, "sp1": 2,
		"desc": "A holy barrier: DEF and max HP up.", "bonus": {"DEF": 3, "MAXHP_PCT": 1}, "time0": 60, "time1": 0,
		"req": {"divine_protection": 3}},
	"magnificat": {"name": "Magnificat", "job": "acolyte", "tier": 2, "type": "buff", "max": 5, "sp0": 40, "sp1": 0,
		"desc": "A hymn that speeds up HP and SP recovery.", "bonus": {"SPREGEN": 20, "HPREGEN": 10}, "time0": 30, "time1": 15},
	"impositio_manus": {"name": "Impositio Manus", "job": "acolyte", "tier": 2, "type": "buff", "max": 5, "sp0": 13, "sp1": 3,
		"desc": "Lay on hands: ATK up for a while.", "bonus": {"ATK": 5}, "time0": 60, "time1": 0, "req": {"blessing": 2}},
	"magnus_exorcismus": {"name": "Magnus Exorcismus", "job": "acolyte", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 40, "sp1": 2,
		"desc": "A holy cross of light purges an area (3 waves).", "base": 100, "per": 30, "hits": 3, "radius": 3.5,
		"color": Color(1.0, 0.95, 0.6), "cast0": 2.0, "cast1": 0.0, "req": {"holy_light": 3}},
	# ---------------------------------------------------------------- High Priest
	"assumptio": {"name": "Assumptio", "job": "acolyte", "tier": 3, "type": "buff", "max": 5, "sp0": 20, "sp1": 10,
		"desc": "Divine wings: DEF and max HP up a lot.", "bonus": {"DEF": 5, "MAXHP_PCT": 3}, "time0": 20, "time1": 20,
		"req": {"kyrie_eleison": 3}},
	"meditatio": {"name": "Meditatio", "job": "acolyte", "tier": 3, "type": "passive", "max": 10,
		"desc": "Deep prayer: more SP regen, max SP and healing.", "bonus": {"SPREGEN": 3, "MAXSP_PCT": 1, "HEAL_PCT": 2}},
	"judex": {"name": "Judex", "job": "acolyte", "tier": 3, "type": "aoe_target", "max": 10, "sp0": 20, "sp1": 2,
		"desc": "Holy judgement falls on the target and its friends.", "base": 120, "per": 30, "radius": 2.2, "proj": "holy",
		"color": Color(1.0, 0.95, 0.7), "cast0": 0.6, "cast1": 0.0, "req": {"magnus_exorcismus": 1}},
	"basilica": {"name": "Basilica", "job": "acolyte", "tier": 3, "type": "buff", "max": 5, "sp0": 60, "sp1": 0,
		"desc": "A sacred sanctum: DEF, FLEE and HP regen up.", "bonus": {"DEF": 6, "FLEE": 4, "HPREGEN": 20}, "time0": 15, "time1": 5,
		"req": {"assumptio": 2}},
	# ---------------------------------------------------------------- Blacksmith
	"weaponry_research": {"name": "Weaponry Research", "job": "merchant", "tier": 2, "type": "passive", "max": 10,
		"desc": "Know your weapons inside out: ATK and HIT up.", "bonus": {"ATK": 2, "HIT": 2}},
	"hammer_fall": {"name": "Hammer Fall", "job": "merchant", "tier": 2, "type": "aoe_self", "max": 5, "sp0": 10, "sp1": 0,
		"desc": "Slam the ground and stun the monsters around you.", "base": 50, "per": 20, "radius": 2.5, "color": Color(0.95, 0.8, 0.45),
		"status": "stun", "chance0": 20, "chance1": 10, "stime0": 2.0, "stime1": 0.0},
	"adrenaline_rush": {"name": "Adrenaline Rush", "job": "merchant", "tier": 2, "type": "buff", "max": 5, "sp0": 17, "sp1": 3,
		"desc": "Get pumped: attack speed up.", "bonus": {"ASPD": 5}, "time0": 30, "time1": 30, "req": {"hammer_fall": 2}},
	"power_thrust": {"name": "Power Thrust", "job": "merchant", "tier": 2, "type": "buff", "max": 5, "sp0": 12, "sp1": 2,
		"desc": "Put your weight behind every swing: ATK up.", "bonus": {"ATK_PCT": 5}, "time0": 20, "time1": 20,
		"req": {"adrenaline_rush": 1}},
	"maximize_power": {"name": "Maximize Power", "job": "merchant", "tier": 2, "type": "buff", "max": 5, "sp0": 15, "sp1": 0,
		"desc": "Always hit with full force: ATK and CRIT up.", "bonus": {"ATK": 3, "CRIT": 3}, "time0": 30, "time1": 10,
		"req": {"weaponry_research": 3}},
	# ---------------------------------------------------------------- Whitesmith
	"cart_termination": {"name": "Cart Termination", "job": "merchant", "tier": 3, "type": "melee", "max": 10, "sp0": 15, "sp1": 0,
		"desc": "Ram the enemy with a cart full of Zeny (costs Zeny).", "base": 150, "per": 60, "zeny": 150, "req": {"mammonite": 5}},
	"maximum_overthrust": {"name": "Maximum Overthrust", "job": "merchant", "tier": 3, "type": "buff", "max": 5, "sp0": 15, "sp1": 0,
		"desc": "Push past your limits: huge ATK bonus.", "bonus": {"ATK_PCT": 8}, "time0": 60, "time1": 0, "req": {"power_thrust": 3}},
	"weapon_perfection": {"name": "Weapon Perfection", "job": "merchant", "tier": 3, "type": "passive", "max": 5,
		"desc": "Masterwork technique: ATK and HIT up.", "bonus": {"ATK": 5, "HIT": 3}, "req": {"weaponry_research": 5}},
	"meltdown": {"name": "Meltdown", "job": "merchant", "tier": 3, "type": "buff", "max": 10, "sp0": 20, "sp1": 2,
		"desc": "White-hot blows: ATK and CRIT up.", "bonus": {"ATK": 4, "CRIT": 2}, "time0": 15, "time1": 5,
		"req": {"maximum_overthrust": 2}},
	# ---------------------------------------------------------------- Assassin
	"katar_mastery": {"name": "Katar Mastery", "job": "thief", "tier": 2, "type": "passive", "max": 10,
		"desc": "Training with katars: ATK and CRIT up.", "bonus": {"ATK": 3, "CRIT": 1}},
	"sonic_blow": {"name": "Sonic Blow", "job": "thief", "tier": 2, "type": "melee", "max": 10, "sp0": 14, "sp1": 1,
		"desc": "A storm of eight lightning-fast stabs.", "base": 40, "per": 6, "hits": 8, "req": {"katar_mastery": 4}},
	"grimtooth": {"name": "Grimtooth", "job": "thief", "tier": 2, "type": "aoe_target", "max": 5, "sp0": 3, "sp1": 0,
		"desc": "Blades burst from the ground under the target.", "base": 120, "per": 20, "radius": 1.8, "color": Color(0.7, 0.9, 0.5),
		"req": {"sonic_blow": 3}},
	"cloaking": {"name": "Cloaking", "job": "thief", "tier": 2, "type": "buff", "max": 10, "sp0": 15, "sp1": 0,
		"desc": "Blend into the shadows: FLEE and move speed up.", "bonus": {"FLEE": 4, "MOVE": 2}, "time0": 20, "time1": 10,
		"req": {"improve_dodge": 2}},
	"enchant_poison": {"name": "Enchant Poison", "job": "thief", "tier": 2, "type": "buff", "max": 10, "sp0": 20, "sp1": 0,
		"desc": "Coat your blade: normal attacks may poison.", "bonus": {"ATK": 2, "POISON": 3}, "time0": 30, "time1": 15,
		"req": {"envenom": 1}},
	# ---------------------------------------------------------------- Assassin Cross
	"enchant_deadly_poison": {"name": "Enchant Deadly Poison", "job": "thief", "tier": 3, "type": "buff", "max": 5, "sp0": 60, "sp1": 0,
		"desc": "A deadly venom: big ATK bonus and poison on hit.", "bonus": {"ATK_PCT": 10, "POISON": 4}, "time0": 20, "time1": 8,
		"req": {"enchant_poison": 3}},
	"soul_destroyer": {"name": "Soul Destroyer", "job": "thief", "tier": 3, "type": "bolt", "max": 10, "sp0": 20, "sp1": 2,
		"desc": "Hurl a blade of shadow at a distant enemy.", "base": 150, "per": 40, "hits": 1, "proj": "magic", "cast0": 0.4, "cast1": 0.0,
		"req": {"grimtooth": 3}},
	"meteor_assault": {"name": "Meteor Assault", "job": "thief", "tier": 3, "type": "aoe_self", "max": 10, "sp0": 10, "sp1": 2,
		"desc": "Lash out at everything around you; may stun.", "base": 120, "per": 40, "radius": 3.0, "color": Color(0.75, 0.45, 1.0),
		"status": "stun", "chance0": 5, "chance1": 3, "stime0": 1.5, "stime1": 0.0, "req": {"katar_mastery": 5}},
	"advanced_katar": {"name": "Advanced Katar Research", "job": "thief", "tier": 3, "type": "passive", "max": 5,
		"desc": "Perfect your katar style: ATK% and CRIT up.", "bonus": {"ATK_PCT": 2, "CRIT": 1}, "req": {"katar_mastery": 5}},

	# ================================================================ Novice (tier 0)
	"basic_training": {"name": "Basic Training", "job": "novice", "tier": 0, "type": "passive", "max": 9, "icon": "star",
		"desc": "The fundamentals every adventurer learns. Level 9 is needed for the first job change.", "bonus": {"HIT": 1}},
	"field_dressing": {"name": "Field Dressing", "job": "novice", "tier": 0, "type": "heal", "max": 1, "sp0": 3, "sp1": 0, "icon": "heart",
		"desc": "Wrap a quick bandage around a wound.", "heal_mult": 0.6, "req": {"basic_training": 3}},
	# ================================================================ 2nd job, branch B (and its 3rd job)
	# ---------------------------------------------------------------- Paladin / Highguard (swordsman)
	"bulwark_training": {"name": "Bulwark Training", "job": "swordsman", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "shield",
		"desc": "Drills behind a shield wall: DEF up.", "bonus": {"DEF": 2}},
	"shield_rush": {"name": "Shield Rush", "job": "swordsman", "branch": "b", "tier": 2, "type": "melee", "max": 10, "sp0": 8, "sp1": 0.5, "icon": "shield",
		"desc": "Charge shield-first into one enemy; may stun it.", "base": 100, "per": 25, "status": "stun", "chance0": 10, "chance1": 3,
		"stime0": 1.5, "stime1": 0.0, "req": {"bash": 3}},
	"aegis_vow": {"name": "Aegis Vow", "job": "swordsman", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 14, "sp1": 1, "icon": "shield",
		"desc": "Swear to hold the line: DEF and max HP up.", "bonus": {"DEF": 3, "MAXHP_PCT": 1}, "time0": 60, "time1": 0,
		"req": {"bulwark_training": 3}},
	"radiant_cross": {"name": "Radiant Cross", "job": "swordsman", "branch": "b", "tier": 2, "type": "aoe_self", "max": 10, "sp0": 18, "sp1": 1, "icon": "holy",
		"desc": "A cross of light bursts out around you.", "base": 120, "per": 25, "radius": 3.0, "color": Color(1.0, 0.92, 0.55),
		"req": {"shield_rush": 3}},
	"lance_charge": {"name": "Lance Charge", "job": "swordsman", "branch": "b", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 12, "sp1": 1, "icon": "bash",
		"desc": "Drive your lance through the target and those beside it.", "base": 140, "per": 30, "radius": 2.0, "color": Color(0.95, 0.85, 0.6),
		"req": {"shield_rush": 5}},
	"holy_bastion": {"name": "Holy Bastion", "job": "swordsman", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 30, "sp1": 4, "icon": "holy",
		"desc": "A wall of faith: DEF and HP regen up a lot.", "bonus": {"DEF": 4, "HPREGEN": 10}, "time0": 30, "time1": 10, "req": {"aegis_vow": 3}},
	"judgement_lance": {"name": "Judgement Lance", "job": "swordsman", "branch": "b", "tier": 3, "type": "melee", "max": 5, "sp0": 22, "sp1": 3, "icon": "holy",
		"desc": "Three blazing lance thrusts.", "base": 200, "per": 50, "hits": 3, "cast0": 0.3, "cast1": 0.0, "req": {"lance_charge": 3}},
	"sanctified_ground": {"name": "Sanctified Ground", "job": "swordsman", "branch": "b", "tier": 3, "type": "aoe_self", "max": 5, "sp0": 35, "sp1": 5, "icon": "holy",
		"desc": "Consecrate the ground around you; may stun.", "base": 160, "per": 40, "radius": 3.5, "color": Color(1.0, 0.95, 0.65),
		"status": "stun", "chance0": 15, "chance1": 5, "stime0": 1.5, "stime1": 0.0, "req": {"radiant_cross": 5}},
	"guardian_spirit": {"name": "Guardian Spirit", "job": "swordsman", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "heart",
		"desc": "A watchful spirit: max HP and DEF up.", "bonus": {"MAXHP_PCT": 2, "DEF": 1}},
	# ---------------------------------------------------------------- Songweaver / Virtuoso (archer)
	"resonant_strings": {"name": "Resonant Strings", "job": "archer", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "star",
		"desc": "Practice with instruments and whips: ATK and attack speed up.", "bonus": {"ATK": 3, "ASPD": 1}},
	"dissonant_chord": {"name": "Dissonant Chord", "job": "archer", "branch": "b", "tier": 2, "type": "bolt", "max": 10, "sp0": 10, "sp1": 1, "icon": "bolt",
		"desc": "A jarring note that strikes one enemy; may stun.", "base": 110, "per": 15, "hits": 1, "proj": "magic",
		"status": "stun", "chance0": 5, "chance1": 2, "stime0": 1.2, "stime1": 0.0},
	"rhythm_of_haste": {"name": "Rhythm of Haste", "job": "archer", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 18, "sp1": 2, "icon": "boot",
		"desc": "A quick beat: attack and move speed up.", "bonus": {"ASPD": 2, "MOVE": 2}, "time0": 60, "time1": 0, "req": {"resonant_strings": 3}},
	"briar_lullaby": {"name": "Briar Lullaby", "job": "archer", "branch": "b", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 20, "sp1": 2, "icon": "poison",
		"desc": "A thorny song over an area; may stun.", "base": 80, "per": 20, "radius": 3.0, "color": Color(0.6, 0.9, 0.5),
		"status": "stun", "chance0": 20, "chance1": 5, "stime0": 2.0, "stime1": 0.0, "req": {"dissonant_chord": 3}},
	"stage_presence": {"name": "Stage Presence", "job": "archer", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "star",
		"desc": "All eyes on you: LUK and CRIT up.", "bonus": {"LUK": 1, "CRIT": 1}},
	"crescendo": {"name": "Crescendo", "job": "archer", "branch": "b", "tier": 3, "type": "aoe_self", "max": 5, "sp0": 30, "sp1": 4, "icon": "bolt",
		"desc": "Your song swells into a blast of sound around you.", "base": 160, "per": 40, "radius": 4.0, "color": Color(0.85, 0.75, 1.0),
		"req": {"briar_lullaby": 3}},
	"ballad_of_vigor": {"name": "Ballad of Vigor", "job": "archer", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 30, "sp1": 4, "icon": "heart",
		"desc": "A rousing ballad: max HP and HP regen up.", "bonus": {"MAXHP_PCT": 2, "HPREGEN": 10}, "time0": 60, "time1": 0,
		"req": {"rhythm_of_haste": 3}},
	"whiplash_volley": {"name": "Whiplash Volley", "job": "archer", "branch": "b", "tier": 3, "type": "melee", "max": 10, "sp0": 14, "sp1": 1, "icon": "dagger",
		"desc": "Four cracks of the whip in a blur.", "base": 60, "per": 15, "hits": 4, "req": {"resonant_strings": 5}},
	"virtuoso_focus": {"name": "Virtuoso Focus", "job": "archer", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "star",
		"desc": "Perfect timing: DEX and HIT up.", "bonus": {"DEX": 1, "HIT": 2}},
	# ---------------------------------------------------------------- Arcanist / Archon (mage)
	"tome_study": {"name": "Tome Study", "job": "mage", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "star",
		"desc": "Long nights over old books: INT and max SP up.", "bonus": {"INT": 1, "MAXSP_PCT": 1}},
	"stone_lance": {"name": "Stone Lance", "job": "mage", "branch": "b", "tier": 2, "type": "bolt", "max": 10, "sp0": 12, "sp1": 1, "icon": "bash",
		"desc": "Spears of stone burst up under the enemy; may stun.", "base": 120, "per": 20, "hits0": 1, "hits1": 0.3, "proj": "magic",
		"color": Color(0.8, 0.65, 0.4), "status": "stun", "chance0": 5, "chance1": 2, "stime0": 1.2, "stime1": 0.0, "cast0": 0.4, "cast1": 0.05},
	"elemental_infusion": {"name": "Elemental Infusion", "job": "mage", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 16, "sp1": 2, "icon": "fire",
		"desc": "Charge your weapon with raw element: ATK up.", "bonus": {"ATK": 4}, "time0": 60, "time1": 0, "req": {"tome_study": 2}},
	"quicksand_pit": {"name": "Quicksand Pit", "job": "mage", "branch": "b", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 22, "sp1": 2, "icon": "poison",
		"desc": "Turn the ground to sucking sand; often stuns.", "base": 60, "per": 15, "radius": 3.0, "color": Color(0.85, 0.7, 0.4),
		"status": "stun", "chance0": 30, "chance1": 4, "stime0": 2.0, "stime1": 0.0, "cast0": 0.8, "cast1": 0.0, "req": {"stone_lance": 3}},
	"spell_ward": {"name": "Spell Ward", "job": "mage", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 15, "sp1": 1, "icon": "shield",
		"desc": "A shimmering ward: DEF and FLEE up.", "bonus": {"DEF": 2, "FLEE": 2}, "time0": 45, "time1": 0},
	"arcane_comet": {"name": "Arcane Comet", "job": "mage", "branch": "b", "tier": 3, "type": "aoe_target", "max": 5, "sp0": 45, "sp1": 6, "icon": "star",
		"desc": "Pull a comet of pure mana down on an area.", "base": 260, "per": 60, "radius": 3.5, "proj": "magic", "color": Color(0.7, 0.6, 1.0),
		"cast0": 1.8, "cast1": 0.0, "req": {"quicksand_pit": 3}},
	"mana_flow": {"name": "Mana Flow", "job": "mage", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "drop",
		"desc": "Mana moves through you freely: SP regen and max SP up.", "bonus": {"SPREGEN": 4, "MAXSP_PCT": 2}},
	"chain_spark": {"name": "Chain Spark", "job": "mage", "branch": "b", "tier": 3, "type": "bolt", "max": 5, "sp0": 24, "sp1": 4, "icon": "bolt",
		"desc": "A spark that jumps through the enemy four times.", "base": 90, "per": 20, "hits": 4, "proj": "lightning",
		"cast0": 0.5, "cast1": 0.0, "req": {"stone_lance": 5}},
	"runic_aegis": {"name": "Runic Aegis", "job": "mage", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 30, "sp1": 4, "icon": "shield",
		"desc": "Runes circle you: DEF and max HP up.", "bonus": {"DEF": 4, "MAXHP_PCT": 2}, "time0": 40, "time1": 10, "req": {"spell_ward": 3}},
	# ---------------------------------------------------------------- Ascetic / Exalted Ascetic (acolyte)
	"iron_fist": {"name": "Iron Fist Discipline", "job": "acolyte", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "bash",
		"desc": "Hardened hands: ATK and HIT up.", "bonus": {"ATK": 3, "HIT": 1}},
	"palm_strike": {"name": "Palm Strike", "job": "acolyte", "branch": "b", "tier": 2, "type": "melee", "max": 10, "sp0": 9, "sp1": 0.5, "icon": "bash",
		"desc": "Two quick open-palm blows.", "base": 110, "per": 20, "hits": 2, "req": {"iron_fist": 2}},
	"inner_spheres": {"name": "Inner Spheres", "job": "acolyte", "branch": "b", "tier": 2, "type": "buff", "max": 5, "sp0": 10, "sp1": 2, "icon": "star",
		"desc": "Gather spirit spheres: ATK and CRIT up.", "bonus": {"ATK": 3, "CRIT": 1}, "time0": 120, "time1": 0},
	"chi_burst": {"name": "Chi Burst", "job": "acolyte", "branch": "b", "tier": 2, "type": "aoe_self", "max": 10, "sp0": 16, "sp1": 1, "icon": "holy",
		"desc": "Release your chi in a ring around you.", "base": 110, "per": 30, "radius": 3.0, "color": Color(0.7, 0.95, 1.0),
		"req": {"palm_strike": 3}},
	"steady_breath": {"name": "Steady Breath", "job": "acolyte", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "drop",
		"desc": "Calm breathing: HP and SP regen up.", "bonus": {"HPREGEN": 5, "SPREGEN": 3}},
	"thousand_palms": {"name": "Thousand Palms", "job": "acolyte", "branch": "b", "tier": 3, "type": "melee", "max": 10, "sp0": 18, "sp1": 2, "icon": "bash",
		"desc": "A flurry of six palm strikes.", "base": 50, "per": 12, "hits": 6, "req": {"palm_strike": 5}},
	"rising_dragon_kick": {"name": "Rising Dragon Kick", "job": "acolyte", "branch": "b", "tier": 3, "type": "melee", "max": 5, "sp0": 30, "sp1": 5, "icon": "bash",
		"desc": "A soaring kick; may stun.", "base": 300, "per": 70, "status": "stun", "chance0": 10, "chance1": 3, "stime0": 1.5, "stime1": 0.0,
		"cast0": 0.3, "cast1": 0.0, "req": {"chi_burst": 3}},
	"zen_guard": {"name": "Zen Guard", "job": "acolyte", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 24, "sp1": 3, "icon": "shield",
		"desc": "Empty mind, ready body: FLEE and DEF up.", "bonus": {"FLEE": 4, "DEF": 2}, "time0": 45, "time1": 0, "req": {"steady_breath": 3}},
	"sky_resolve": {"name": "Sky Resolve", "job": "acolyte", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "star",
		"desc": "Unshakable will: ATK and max HP up.", "bonus": {"ATK_PCT": 2, "MAXHP_PCT": 1}},
	# ---------------------------------------------------------------- Artificer / Grand Artificer (merchant)
	"potion_lore": {"name": "Potion Lore", "job": "merchant", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "drop",
		"desc": "Know your brews: healing and HP regen up.", "bonus": {"HEAL_PCT": 3, "HPREGEN": 5}},
	"acid_flask": {"name": "Acid Flask", "job": "merchant", "branch": "b", "tier": 2, "type": "bolt", "max": 10, "sp0": 10, "sp1": 1, "icon": "poison",
		"desc": "Throw a flask of acid; may poison.", "base": 130, "per": 20, "hits": 1, "proj": "magic", "color": Color(0.6, 0.95, 0.35),
		"status": "poison", "chance0": 20, "chance1": 5, "stime0": 5.0, "stime1": 0.0},
	"fire_flask": {"name": "Fire Flask", "job": "merchant", "branch": "b", "tier": 2, "type": "aoe_target", "max": 10, "sp0": 15, "sp1": 1, "icon": "fire",
		"desc": "A flask that bursts into flames.", "base": 110, "per": 25, "radius": 2.5, "proj": "fire", "color": Color(1.0, 0.5, 0.15),
		"req": {"acid_flask": 3}},
	"alloy_coating": {"name": "Alloy Coating", "job": "merchant", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 14, "sp1": 1, "icon": "shield",
		"desc": "Coat your gear in fresh alloy: DEF up.", "bonus": {"DEF": 3}, "time0": 60, "time1": 0, "req": {"potion_lore": 2}},
	"clockwork_sights": {"name": "Clockwork Sights", "job": "merchant", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "star",
		"desc": "Precision lenses: HIT and CRIT up.", "bonus": {"HIT": 2, "CRIT": 1}},
	"golem_smash": {"name": "Golem Smash", "job": "merchant", "branch": "b", "tier": 3, "type": "aoe_target", "max": 5, "sp0": 35, "sp1": 5, "icon": "bash",
		"desc": "A clockwork golem pounds the target area; may stun.", "base": 220, "per": 50, "radius": 3.0, "color": Color(0.85, 0.75, 0.55),
		"status": "stun", "chance0": 15, "chance1": 5, "stime0": 1.5, "stime1": 0.0, "cast0": 0.6, "cast1": 0.0, "req": {"fire_flask": 3}},
	"elixir_rush": {"name": "Elixir Rush", "job": "merchant", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 25, "sp1": 4, "icon": "drop",
		"desc": "Down a bubbling elixir: ATK and attack speed up.", "bonus": {"ATK_PCT": 3, "ASPD": 2}, "time0": 40, "time1": 10, "req": {"potion_lore": 5}},
	"shrapnel_bomb": {"name": "Shrapnel Bomb", "job": "merchant", "branch": "b", "tier": 3, "type": "aoe_self", "max": 5, "sp0": 30, "sp1": 4, "icon": "fire",
		"desc": "Set off a bomb at your feet - shrapnel everywhere.", "base": 180, "per": 40, "radius": 3.5, "color": Color(1.0, 0.6, 0.25),
		"req": {"acid_flask": 5}},
	"master_alchemy": {"name": "Master Alchemy", "job": "merchant", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "drop",
		"desc": "The great work: max HP and max SP up.", "bonus": {"MAXHP_PCT": 2, "MAXSP_PCT": 2}},
	# ---------------------------------------------------------------- Trickster / Phantom Trickster (thief)
	"sleight_of_hand": {"name": "Sleight of Hand", "job": "thief", "branch": "b", "tier": 2, "type": "passive", "max": 10, "icon": "dagger",
		"desc": "Quick fingers: AGI and CRIT up.", "bonus": {"AGI": 1, "CRIT": 1}},
	"dirty_trick": {"name": "Dirty Trick", "job": "thief", "branch": "b", "tier": 2, "type": "melee", "max": 10, "sp0": 9, "sp1": 0.5, "icon": "dagger",
		"desc": "Sand in the eyes, then a stab; may stun.", "base": 110, "per": 20, "status": "stun", "chance0": 15, "chance1": 3,
		"stime0": 1.5, "stime1": 0.0, "req": {"envenom": 2}},
	"smoke_veil": {"name": "Smoke Veil", "job": "thief", "branch": "b", "tier": 2, "type": "buff", "max": 10, "sp0": 15, "sp1": 1, "icon": "boot",
		"desc": "Vanish in smoke: FLEE and move speed up.", "bonus": {"FLEE": 4, "MOVE": 2}, "time0": 30, "time1": 0, "req": {"improve_dodge": 2}},
	"knife_fan": {"name": "Knife Fan", "job": "thief", "branch": "b", "tier": 2, "type": "aoe_self", "max": 10, "sp0": 14, "sp1": 1, "icon": "dagger",
		"desc": "Throw a fan of knives all around you.", "base": 100, "per": 25, "radius": 3.0, "color": Color(0.85, 0.85, 0.95),
		"req": {"dirty_trick": 3}},
	"trick_shot": {"name": "Trick Shot", "job": "thief", "branch": "b", "tier": 2, "type": "bolt", "max": 10, "sp0": 11, "sp1": 1, "icon": "bow",
		"desc": "A bank shot that finds a gap in the armour.", "base": 140, "per": 25, "hits": 1, "proj": "arrow", "req": {"sleight_of_hand": 3}},
	"phantom_blades": {"name": "Phantom Blades", "job": "thief", "branch": "b", "tier": 3, "type": "aoe_target", "max": 5, "sp0": 30, "sp1": 4, "icon": "dagger",
		"desc": "Ghostly blades rain down twice on the target area.", "base": 200, "per": 45, "hits": 2, "radius": 3.0, "color": Color(0.7, 0.5, 1.0),
		"req": {"knife_fan": 3}},
	"shadow_step": {"name": "Shadow Step", "job": "thief", "branch": "b", "tier": 3, "type": "buff", "max": 5, "sp0": 24, "sp1": 3, "icon": "boot",
		"desc": "Step between shadows: FLEE, CRIT and move speed up.", "bonus": {"FLEE": 3, "CRIT": 2, "MOVE": 2}, "time0": 40, "time1": 5,
		"req": {"smoke_veil": 3}},
	"ambush_combo": {"name": "Ambush Combo", "job": "thief", "branch": "b", "tier": 3, "type": "melee", "max": 10, "sp0": 18, "sp1": 2, "icon": "dagger",
		"desc": "Strike from hiding three times.", "base": 120, "per": 30, "hits": 3, "req": {"dirty_trick": 5}},
	"lucky_charm": {"name": "Lucky Charm", "job": "thief", "branch": "b", "tier": 3, "type": "passive", "max": 10, "icon": "coin",
		"desc": "A trinket that never fails you: LUK and CRIT up.", "bonus": {"LUK": 1, "CRIT": 1}},
	"swordsman_a_4_strike": {"name": "จู่โจมพิฆาต", "job": "swordsman", "branch": "a", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"swordsman_a_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "swordsman", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"swordsman_a_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "swordsman", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"swordsman_a_5_strike": {"name": "จู่โจมพิฆาต", "job": "swordsman", "branch": "a", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"swordsman_a_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "swordsman", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"swordsman_a_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "swordsman", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"swordsman_b_4_strike": {"name": "จู่โจมพิฆาต", "job": "swordsman", "branch": "b", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"swordsman_b_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "swordsman", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"swordsman_b_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "swordsman", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"swordsman_b_5_strike": {"name": "จู่โจมพิฆาต", "job": "swordsman", "branch": "b", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"swordsman_b_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "swordsman", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"swordsman_b_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "swordsman", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"archer_a_4_strike": {"name": "จู่โจมพิฆาต", "job": "archer", "branch": "a", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"archer_a_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "archer", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"archer_a_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "archer", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"archer_a_5_strike": {"name": "จู่โจมพิฆาต", "job": "archer", "branch": "a", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"archer_a_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "archer", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"archer_a_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "archer", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"archer_b_4_strike": {"name": "จู่โจมพิฆาต", "job": "archer", "branch": "b", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"archer_b_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "archer", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"archer_b_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "archer", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"archer_b_5_strike": {"name": "จู่โจมพิฆาต", "job": "archer", "branch": "b", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"archer_b_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "archer", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"archer_b_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "archer", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"mage_a_4_strike": {"name": "เวททำลายล้าง", "job": "mage", "branch": "a", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "fire", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"mage_a_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "mage", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"mage_a_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "mage", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"mage_a_5_strike": {"name": "เวททำลายล้าง", "job": "mage", "branch": "a", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "fire", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"mage_a_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "mage", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"mage_a_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "mage", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"mage_b_4_strike": {"name": "เวททำลายล้าง", "job": "mage", "branch": "b", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "fire", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"mage_b_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "mage", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"mage_b_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "mage", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"mage_b_5_strike": {"name": "เวททำลายล้าง", "job": "mage", "branch": "b", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "fire", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"mage_b_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "mage", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"mage_b_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "mage", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"acolyte_a_4_strike": {"name": "เวททำลายล้าง", "job": "acolyte", "branch": "a", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "fire", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"acolyte_a_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "acolyte", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"acolyte_a_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "acolyte", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"acolyte_a_5_strike": {"name": "เวททำลายล้าง", "job": "acolyte", "branch": "a", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "fire", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"acolyte_a_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "acolyte", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"acolyte_a_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "acolyte", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"acolyte_b_4_strike": {"name": "เวททำลายล้าง", "job": "acolyte", "branch": "b", "tier": 4, "type": "aoe_target", "max": 10, "sp0": 46, "sp1": 3, "icon": "fire", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"acolyte_b_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "acolyte", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"acolyte_b_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "acolyte", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"acolyte_b_5_strike": {"name": "เวททำลายล้าง", "job": "acolyte", "branch": "b", "tier": 5, "type": "aoe_target", "max": 10, "sp0": 50, "sp1": 3, "icon": "fire", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"acolyte_b_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "acolyte", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"acolyte_b_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "acolyte", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"merchant_a_4_strike": {"name": "จู่โจมพิฆาต", "job": "merchant", "branch": "a", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"merchant_a_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "merchant", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"merchant_a_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "merchant", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"merchant_a_5_strike": {"name": "จู่โจมพิฆาต", "job": "merchant", "branch": "a", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"merchant_a_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "merchant", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"merchant_a_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "merchant", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"merchant_b_4_strike": {"name": "จู่โจมพิฆาต", "job": "merchant", "branch": "b", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"merchant_b_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "merchant", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"merchant_b_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "merchant", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"merchant_b_5_strike": {"name": "จู่โจมพิฆาต", "job": "merchant", "branch": "b", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"merchant_b_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "merchant", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"merchant_b_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "merchant", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"thief_a_4_strike": {"name": "จู่โจมพิฆาต", "job": "thief", "branch": "a", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"thief_a_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "thief", "branch": "a", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"thief_a_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "thief", "branch": "a", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"thief_a_5_strike": {"name": "จู่โจมพิฆาต", "job": "thief", "branch": "a", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"thief_a_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "thief", "branch": "a", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"thief_a_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "thief", "branch": "a", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"thief_b_4_strike": {"name": "จู่โจมพิฆาต", "job": "thief", "branch": "b", "tier": 4, "type": "aoe_self", "max": 10, "sp0": 46, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 210, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"thief_b_4_guard": {"name": "เกราะผู้พิทักษ์", "job": "thief", "branch": "b", "tier": 4, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"thief_b_4_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "thief", "branch": "b", "tier": 4, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},
	"thief_b_5_strike": {"name": "จู่โจมพิฆาต", "job": "thief", "branch": "b", "tier": 5, "type": "aoe_self", "max": 10, "sp0": 50, "sp1": 3, "icon": "sword", "desc": "สายโจมตี: ทำความเสียหายหมู่ เพิ่มพลังตามระดับสกิล", "base": 225, "per": 20, "radius": 3.5, "color": Color(0.7, 0.8, 1.0), "req": {}},
	"thief_b_5_guard": {"name": "เกราะผู้พิทักษ์", "job": "thief", "branch": "b", "tier": 5, "type": "buff", "max": 10, "sp0": 35, "sp1": 2, "icon": "shield", "desc": "สายป้องกัน: เพิ่มเกราะและพลังชีวิตชั่วคราว", "bonus": {"DEF": 2, "MAXHP_PCT": 2}, "time0": 30, "time1": 3},
	"thief_b_5_mastery": {"name": "สมาธิเชี่ยวชาญ", "job": "thief", "branch": "b", "tier": 5, "type": "passive", "max": 10, "icon": "star", "desc": "สายสนับสนุน: เพิ่มความแม่นยำและการฟื้นพลังจิต", "bonus": {"HIT": 2, "SPREGEN": 5}},

}

## Skill lists per base job and tier (tier 1 = first job, 2 = second job, 3 = transcendent).
const JOB_SKILLS := {
	"swordsman": [["bash", "magnum_break", "endure", "sword_mastery", "hp_recovery"],
		["pierce", "brandish_spear", "bowling_bash", "two_hand_quicken", "spear_mastery"],
		["spiral_pierce", "aura_blade", "berserk", "parrying"]],
	"archer": [["double_strafe", "arrow_shower", "improve_concentration", "owls_eye", "vultures_eye"],
		["blitz_beat", "ankle_snare", "land_mine", "claymore_trap", "beast_bane"],
		["falcon_assault", "sharp_shooting", "true_sight", "wind_walk"]],
	"mage": [["fire_bolt", "cold_bolt", "lightning_bolt", "fire_ball", "sp_recovery"],
		["frost_diver", "jupitel_thunder", "meteor_storm", "storm_gust", "lord_of_vermilion"],
		["napalm_vulcan", "gravitation_field", "mystical_amplification", "soul_drain"]],
	"acolyte": [["heal", "holy_light", "blessing", "increase_agi", "divine_protection"],
		["sanctuary", "magnus_exorcismus", "kyrie_eleison", "magnificat", "impositio_manus"],
		["judex", "assumptio", "basilica", "meditatio"]],
	"merchant": [["mammonite", "cart_revolution", "discount", "overcharge", "enlarge_weight"],
		["hammer_fall", "adrenaline_rush", "power_thrust", "maximize_power", "weaponry_research"],
		["cart_termination", "maximum_overthrust", "meltdown", "weapon_perfection"]],
	"thief": [["envenom", "steal", "double_attack", "improve_dodge"],
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
	"swordsman": ["Paladin", "Highguard"],
	"archer": ["Songweaver", "Virtuoso"],
	"mage": ["Arcanist", "Archon"],
	"acolyte": ["Ascetic", "Exalted Ascetic"],
	"merchant": ["Artificer", "Grand Artificer"],
	"thief": ["Trickster", "Phantom Trickster"],
}
## One line about each 2nd job, shown when choosing a branch.
const BRANCH_DESC := {
	"swordsman": {"a": "Two-handed swords and spears; heavy single-target and sweeping attacks.",
		"b": "Shield and lance; holy area attacks, stuns and strong defence."},
	"archer": {"a": "Bows, traps and a falcon; long-range burst damage.",
		"b": "Instruments and whips; songs that buff you and stun groups."},
	"mage": {"a": "Staves; huge elemental area spells.",
		"b": "Tomes; earth and arcane spells, wards and weapon infusions."},
	"acolyte": {"a": "Maces and staves; healing, holy light and protective prayers.",
		"b": "Knuckles; fast martial-arts combos and inner focus."},
	"merchant": {"a": "Axes and maces; forging, raw power and attack-speed buffs.",
		"b": "Axes and tomes; acid and fire flasks, bombs and a clockwork golem."},
	"thief": {"a": "Katars and daggers; critical hits and deadly poison.",
		"b": "Daggers and bows; dirty tricks, knife fans and evasion."},
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
const THROWN := ["acid_flask", "fire_flask", "knife_fan", "trick_shot", "cart_revolution", "soul_destroyer", "grimtooth",
	"phantom_blades", "golem_smash", "shrapnel_bomb", "land_mine", "ankle_snare", "claymore_trap"]
const KICKS := ["rising_dragon_kick"]
const SONGS := ["dissonant_chord", "briar_lullaby", "rhythm_of_haste", "crescendo", "ballad_of_vigor"]


static func anim_kind(id: String, weapon_kind: String, style: String) -> String:
	var s := info(id)
	if s.has("anim"):
		return String(s.anim)
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


static func sp_cost(id: String, lv: int) -> int:
	var s := info(id)
	return int(s.get("sp0", 0) + s.get("sp1", 0.0) * lv)


static func mult(id: String, lv: int) -> float:
	var s := info(id)
	return (s.get("base", 100) + s.get("per", 0) * lv) / 100.0


static func hits(id: String, lv: int) -> int:
	var s := info(id)
	if s.get("hits_per_lv", false):
		return maxi(1, lv)
	if s.has("hits0"):
		return int(s.hits0 + s.get("hits1", 0.0) * lv)
	return int(s.get("hits", 1))


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


static func cooldown(id: String, _lv: int) -> float:
	var s := info(id)
	return float(s.get("cd", TYPE_CD.get(s.get("type", ""), 0.0)))


static func cast_time(id: String, lv: int) -> float:
	var s := info(id)
	return s.get("cast0", 0.0) + s.get("cast1", 0.0) * lv


static func duration(id: String, lv: int) -> float:
	var s := info(id)
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
			return t % int(mult(id, lv) * 100)
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
	"STR": "STR", "AGI": "AGI", "VIT": "VIT", "INT": "INT", "DEX": "DEX", "LUK": "LUK"}
const PCT_KEYS := ["ATK_PCT", "ASPD", "MOVE", "MAXHP_PCT", "MAXSP_PCT", "HPREGEN", "SPREGEN", "HEAL_PCT", "POISON"]


static func _tr(t: String) -> String:
	return TranslationServer.translate(t)


## Effect line built from the skill data (2nd / 3rd job skills).
static func _auto_effect(id: String, lv: int) -> String:
	var s := info(id)
	var parts: PackedStringArray = []
	match s.type:
		"melee", "bolt", "aoe_self", "aoe_target":
			var h := hits(id, lv)
			var pct := int(mult(id, lv) * 100)
			parts.append(_tr("%d hits x %d%%") % [h, pct] if h > 1 else _tr("Damage %d%%") % pct)
			if s.type.begins_with("aoe"):
				parts.append(_tr("area"))
			if s.has("status"):
				parts.append("%s %d%%" % [_tr({"freeze": "Freeze", "stun": "Stun", "poison": "Poison"}[s.status]), int(status_chance(id, lv))])
			if s.has("zeny"):
				parts.append("%d Zeny" % (int(s.zeny) * lv))
		"heal":
			parts.append(_tr("Heals about %d HP") % int(lv * 30 * s.get("heal_mult", 1.0)))
	var b := bonus(id)
	for k in b:
		var v: int = int(b[k]) * lv
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
