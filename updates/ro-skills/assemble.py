"""Build source/scripts/game/skill_db.gd from the old file plus skills_table.txt, adv_table.txt and th_table.txt."""
import json
from pathlib import Path

root = Path(__file__).parent
old = (root.parent / 'career-level80/scripts/game/skill_db.gd').read_text()
head = old[:old.index('const SKILLS := {')]
rest = old[old.index('\n## Skill lists per base job'):]
table = (root / 'skills_table.txt').read_text().rstrip()
assert table.endswith('}')
table = table[:-1] + '\n' + (root / 'adv_table.txt').read_text() + '}\n'
th = (root / 'th_table.txt').read_text().rstrip()
adv = json.loads((root / 'adv_th.json').read_text())
th = th[:-1] + ''.join('\t%s: %s,\n' % (json.dumps(k, ensure_ascii=False), json.dumps(v, ensure_ascii=False)) for k, v in adv.items()) + '}\n'
head = head.replace('## First-job skills in the classic MMORPG style.',
                    '## Skills modelled on Ragnarok Online: names, levels, SP, cast times, delays and prerequisites.')
R = [
('''	"mage": [["fire_bolt", "cold_bolt", "lightning_bolt", "fire_ball", "sp_recovery"],''',
 '''	"mage": [["napalm_beat", "soul_strike", "fire_bolt", "cold_bolt", "lightning_bolt", "fire_ball", "fire_wall", "sp_recovery"],'''),
('''	"acolyte": [["heal", "holy_light", "blessing", "increase_agi", "divine_protection"],''',
 '''	"acolyte": [["heal", "holy_light", "blessing", "increase_agi", "angelus", "divine_protection"],'''),
('''	"thief": [["envenom", "steal", "double_attack", "improve_dodge"],''',
 '''	"thief": [["envenom", "sand_attack", "steal", "double_attack", "improve_dodge"],'''),
('''		["judex", "assumptio", "basilica", "meditatio"]],''', '''		["assumptio", "basilica", "meditatio", "judex"]],'''),
('''	"swordsman": ["Paladin", "Highguard"],
	"archer": ["Songweaver", "Virtuoso"],
	"mage": ["Arcanist", "Archon"],
	"acolyte": ["Ascetic", "Exalted Ascetic"],
	"merchant": ["Artificer", "Grand Artificer"],
	"thief": ["Trickster", "Phantom Trickster"],''', '''	"swordsman": ["Crusader", "Paladin"],
	"archer": ["Bard", "Clown"],
	"mage": ["Sage", "Professor"],
	"acolyte": ["Monk", "Champion"],
	"merchant": ["Alchemist", "Creator"],
	"thief": ["Rogue", "Stalker"],'''),
('"b": "Shield and lance; holy area attacks, stuns and strong defence."', '"b": "Shield and spear; holy attacks like Grand Cross, stuns and strong defence."'),
('"b": "Instruments and whips; songs that buff you and stun groups."', '"b": "Instruments; songs that boost you, freeze groups and a nine-arrow volley."'),
('"b": "Tomes; earth and arcane spells, wards and weapon infusions."', '"b": "Books; Earth Spike, Heaven\'s Drive, weapon endows and Abracadabra."'),
('"b": "Knuckles; fast martial-arts combos and inner focus."', '"b": "Knuckles; spirit spheres, combos and the all-out Asura Strike."'),
('"b": "Axes and tomes; acid and fire flasks, bombs and a clockwork golem."', '"b": "Axes and flasks; Acid Terror, fire bombs and marine spheres."'),
('"b": "Daggers and bows; dirty tricks, knife fans and evasion."', '"b": "Daggers and bows; Back Stab, Raid, Snatcher and Plagiarism."'),
('''const THROWN := ["acid_flask", "fire_flask", "knife_fan", "trick_shot", "cart_revolution", "soul_destroyer", "grimtooth",
	"phantom_blades", "golem_smash", "shrapnel_bomb", "land_mine", "ankle_snare", "claymore_trap"]
const KICKS := ["rising_dragon_kick"]
const SONGS := ["dissonant_chord", "briar_lullaby", "rhythm_of_haste", "crescendo", "ballad_of_vigor"]''',
 '''const THROWN := ["acid_flask", "fire_flask", "cart_revolution", "soul_destroyer", "grimtooth", "golem_smash", "shrapnel_bomb",
	"land_mine", "ankle_snare", "claymore_trap", "judgement_lance", "sand_attack"]
const KICKS := []
const SONGS := ["dissonant_chord", "briar_lullaby", "rhythm_of_haste", "stage_presence", "ballad_of_vigor", "whiplash_volley",
	"virtuoso_focus", "sanctified_ground"]'''),
('''static func sp_cost(id: String, lv: int) -> int:
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
	return int(s.get("hits", 1))''', '''## Value of a per-level table (the last entry repeats) or a plain number.
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
	return float(v) * lv'''),
('''static func cooldown(id: String, _lv: int) -> float:
	var s := info(id)
	return float(s.get("cd", TYPE_CD.get(s.get("type", ""), 0.0)))


static func cast_time(id: String, lv: int) -> float:
	var s := info(id)
	return s.get("cast0", 0.0) + s.get("cast1", 0.0) * lv


static func duration(id: String, lv: int) -> float:
	var s := info(id)
	return s.get("time0", 0) + s.get("time1", 0) * lv''', '''static func cooldown(id: String, lv: int) -> float:
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
	return s.get("time0", 0) + s.get("time1", 0) * lv'''),
('''		"bash", "magnum_break", "arrow_shower", "fire_ball", "holy_light", "cart_revolution":
			return t % int(mult(id, lv) * 100)''', '''		"bash", "magnum_break", "arrow_shower", "fire_ball", "holy_light", "cart_revolution":
			return t % int(round(mult(id, lv) * 100))'''),
('''		"melee", "bolt", "aoe_self", "aoe_target":
			var h := hits(id, lv)
			var pct := int(mult(id, lv) * 100)
			parts.append(_tr("%d hits x %d%%") % [h, pct] if h > 1 else _tr("Damage %d%%") % pct)''', '''		"melee", "bolt", "aoe_self", "aoe_target":
			var h := hits(id, lv)
			var pct := int(round(mult(id, lv) * 100))
			if s.get("sp_all", false):
				parts.append(_tr("Uses all SP"))
			elif s.get("random", false):
				parts.append("%s %d%%" % [_tr("Random"), pct])
			elif s.get("hits_size", false):
				parts.append(_tr("Damage %d%%") % pct + " (" + _tr("Hits on medium/large") + ")")
			elif not s.get("nodmg", false):
				parts.append(_tr("%d hits x %d%%") % [h, pct] if h > 1 else _tr("Damage %d%%") % pct)'''),
('''	var b := bonus(id)
	for k in b:
		var v: int = int(b[k]) * lv
		parts.append''', '''	var b := bonus(id)
	for k in b:
		var v: int = int(round(bonus_value(id, k, lv)))
		parts.append'''),
('''			parts.append("%s %d%%" % [_tr({"freeze": "Freeze", "stun": "Stun", "poison": "Poison"}[s.status]), int(status_chance(id, lv))])
			if s.has("zeny"):''', '''			parts.append("%s %d%%" % [_tr({"freeze": "Freeze", "stun": "Stun", "poison": "Poison"}[s.status]), int(status_chance(id, lv))])
			if s.has("hp_pct"):
				parts.append(_tr("HP cost %d%%") % int(s.hp_pct))
			if s.has("zeny"):'''),
('''	"STR": "STR", "AGI": "AGI", "VIT": "VIT", "INT": "INT", "DEX": "DEX", "LUK": "LUK"}
const PCT_KEYS := ["ATK_PCT", "ASPD", "MOVE", "MAXHP_PCT", "MAXSP_PCT", "HPREGEN", "SPREGEN", "HEAL_PCT", "POISON"]''',
 '''	"STR": "STR", "AGI": "AGI", "VIT": "VIT", "INT": "INT", "DEX": "DEX", "LUK": "LUK",
	"CAST": "Cast time -", "SPCOST": "SP cost -", "TRIPLE": "Triple attack", "DOUBLECAST": "Double cast", "SNATCH": "Steal on hit"}
const PCT_KEYS := ["ATK_PCT", "ASPD", "MOVE", "MAXHP_PCT", "MAXSP_PCT", "HPREGEN", "SPREGEN", "HEAL_PCT", "POISON",
	"CAST", "SPCOST", "TRIPLE", "DOUBLECAST", "SNATCH"]'''),
]
for a, b in R:
    assert a in rest, a[:90]
    rest = rest.replace(a, b)
out = head + table + '\n' + th + rest
(root / 'source/scripts/game/skill_db.gd').write_text(out)
print(len(out.split('\n')), 'lines')
