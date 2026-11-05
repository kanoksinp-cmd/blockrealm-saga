extends Node
## Autoload "Game": the player's character sheet (classic MMORPG style), inventory,
## equipment, quests and the message log.

signal changed
signal inventory_changed
signal quest_changed
signal message(text: String, color: Color)
signal skills_changed
signal save_written(slot_index: int)

const MAX_LEVEL := 99

const STATS := ["STR", "AGI", "VIT", "INT", "DEX", "LUK"]
const HOTBAR_SIZE := 16     ## F1-F8 (top row) + 1-8 (bottom row)

var player_name := "Elf Knight"
var job := "Swordsman"          # display name of the job
var job_id := "swordsman"
var guild_member := false       # registered at the Adventurers' Guild
var guild_rank := 0             # 0 = F ... 6 = S (see Guild.RANKS)
var guild_points := 0           # GP from special quest board bounties
var board_offers: Array = []
var board_active := {}
var board_seed := 1
var board_done := 0
var story_step := 0             # main story progress (index into Story.STEPS)
var job_tier := 1               # 0 = Novice, 1 = first job, 2 = second job, 3 = transcendent
var job_branch := "a"           # which 2nd-job branch was chosen ("a" / "b")
var job_level := 1              # job level inside the current tier (see SkillDB.JOB_MAX)
var job_exp := 0
var past_job_levels: Array = [] # final job level of every earlier tier (skill points)
var bonus_skill_points := 0     # kept from saves made before job levels existed
var planned_job := ""           # 1st job picked at character creation (suggested at Job Lv 10)
var fashion_unlocks: Array = []  # permanently crafted cosmetics, per character
var appearance := {}            # from the character creator (empty = classic knight)
var character_ready := false    # true once a character was created / loaded
var base_level := 1
var base_exp := 0
var stats := {"STR": 5, "AGI": 5, "VIT": 5, "INT": 3, "DEX": 5, "LUK": 3}
var stat_points := 12
var hp := 1
var sp := 1
var zeny := 300
## Regions reached at least once (fast travel via the Warp Crystals).
var visited_areas: Array = []
## Recruited adventurers: [{name, job, look}] (see Party)
var party: Array = []
var party_seed := 0
signal party_changed
## Days passed in the world (seasons change every 2 days).
var world_day := 0
var inventory := {}
var equip := {"weapon": "crystal_sword", "shield": "", "head": "", "armor": "knight_plate", "garment": "", "gloves": "",
	"boots": "", "accessory": ""}
var save_point := Vector3(0, 0.1, 10)
var quests := {}          # id -> {"state": "active"/"done"/"finished", "count": int}
var skill_levels := {}    # skill id -> level (see SkillDB)
var skill_points := 3
var hotbar: Array = ["", "", "", "", "", "", "potion_red", "potion_blue", "", "", "", "", "", "", "", ""]
## skill id -> time (s, engine clock) when it is ready again; not saved
var skill_ready_at := {}
var buffs := {}           # buff skill id -> {"t": seconds left, "lv": level}
var auto_on := false      # auto-hunt mode
## auto-hunt options (Auto Settings window)
var auto_cfg := {"monster": "", "travel_warp": true, "target": "nearest", "range": 20, "skills": true, "aoe": 2, "buffs": true,
	"hp_potion": 40, "sp_potion": 15, "loot": true, "skip_boss": true, "quest_only": false}
var auto_quest_target := ""  # monster name the auto mode is hunting for a quest
var auto_quest_giver := ""
var refine := {}          # item id -> refine level (+1 .. +10)
var world_hour := 9.0     # time of day (DayNight)
var ui: Node              # RO UI (set by the UI itself)
var mouse_over_ui := false


const SAVE_PATH := "user://save.cfg"      # old single-slot save (moved to slot 1)
const MAX_SLOTS := 5
const SLOTS_META := "user://slots.cfg"
var slot := 0                                  # active character slot (0 .. MAX_SLOTS-1)
const SAVE_KEYS := ["player_name", "job", "job_id", "appearance", "fashion_unlocks", "base_level", "base_exp", "stats", "stat_points",
	"hp", "sp", "zeny", "inventory", "equip", "quests", "save_point", "skill_levels", "skill_points", "job_tier", "job_branch", "job_level", "job_exp", "past_job_levels", "bonus_skill_points", "planned_job", "story_step", "guild_member", "guild_rank", "guild_points", "board_offers", "board_active", "board_seed", "board_done", "hotbar", "world_hour", "auto_cfg", "refine", "visited_areas", "world_day", "party", "party_seed"]


func _ready() -> void:
	_migrate_old_save()
	slot = last_slot()
	changed.connect(Story.check)
	inventory_changed.connect(Story.check)
	inventory = {"potion_red": 6, "potion_blue": 2}
	hp = max_hp()
	sp = max_sp()
	var t := Timer.new()
	t.wait_time = 30.0
	t.autostart = true
	t.timeout.connect(func() -> void:
		if character_ready and get_tree().current_scene and get_tree().current_scene.name == "Main":
			save_game())
	add_child(t)
	# live events announced on the website (news.json): EXP / drop / gathering bonuses
	var et := Timer.new()
	et.wait_time = 30.0
	et.autostart = true
	et.timeout.connect(_poll_events)
	add_child(et)
	get_tree().create_timer(3.0).timeout.connect(_poll_events)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and character_ready:
		save_game()


# ------------------------------------------------------------------ character / save
## Creator appearance + equipped gear (what the 3D model should look like).
func dressed_appearance() -> Dictionary:
	var look := appearance.duplicate(true)
	if not fashion_allowed(String(look.get("fashion", ""))):look.fashion=""
	return Avatar.dress(look, equip, refine)


func job_info() -> Dictionary:
	return Avatar.job(job_id)


## Start a brand-new level 1 character from the creator.
func new_character(char_name: String, look: Dictionary) -> void:
	# everyone starts as a Novice; the job picked at creation is suggested at Job Lv 10
	planned_job = String(look.get("job", "swordsman"))
	var j := Avatar.job("novice")
	player_name = char_name
	auto_on = false
	job_tier = 0
	job_id = "novice"
	job = j.name
	job_branch = "a"
	job_level = 1
	job_exp = 0
	past_job_levels = []
	bonus_skill_points = 0
	fashion_unlocks = []
	appearance = look.duplicate(true)
	appearance["fashion"]=""
	appearance.job = "novice"
	base_level = 1
	base_exp = 0
	stats = j.stats.duplicate()
	stat_points = 8
	skill_levels = {}
	skill_points = 0
	story_step = 0
	guild_member = false
	guild_rank = 0
	guild_points = 0
	board_offers = []
	board_active = {}
	board_seed = 1
	board_done = 0
	refine = {}
	visited_areas = []
	world_day = 0
	party = []
	party_seed = 0
	hotbar = ["", "", "", "", "", "", "potion_red", "potion_blue", "", "", "", "", "", "", "", ""]
	skill_ready_at = {}
	buffs = {}
	zeny = 300
	inventory = {"potion_red": 6, "potion_blue": 3}
	equip = _empty_equip()
	equip.weapon = j.weapon
	equip.armor = "traveler_clothes"
	equip.boots = "sandals"
	quests = {}
	save_point = Vector3(0, 0.1, 10)
	hp = max_hp()
	sp = max_sp()
	character_ready = true
	save_game()
	changed.emit()
	inventory_changed.emit()
	quest_changed.emit()


# ------------------------------------------------------------------ character slots (max 5)
func slot_path(i: int) -> String:
	return CloudAccount.storage_prefix() + "save_%d.cfg" % (i + 1)


func _migrate_old_save() -> void:
	if FileAccess.file_exists(SAVE_PATH) and not FileAccess.file_exists(slot_path(0)):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(slot_path(0)))


func last_slot() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(CloudAccount.storage_prefix() + "slots.cfg") == OK:
		return clampi(int(cfg.get_value("slots", "last", 0)), 0, MAX_SLOTS - 1)
	return 0


func _remember_slot() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("slots", "last", slot)
	cfg.save(CloudAccount.storage_prefix() + "slots.cfg")


func has_save(i := -1) -> bool:
	return FileAccess.file_exists(slot_path(slot if i < 0 else i))


func first_free_slot() -> int:
	for i in MAX_SLOTS:
		if not has_save(i):
			return i
	return -1


func slot_count() -> int:
	var n := 0
	for i in MAX_SLOTS:
		if has_save(i):
			n += 1
	return n


func delete_slot(i: int) -> void:
	if has_save(i):
		if DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(i))) == OK:
			CloudAccount.mark_dirty()


## Short summary of a saved character for the title screen ({} if the slot is empty).
func save_summary(i := -1) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot if i < 0 else i)) != OK:
		return {}
	return {"name": cfg.get_value("char", "player_name", "?"), "job": cfg.get_value("char", "job", "Swordsman"),
		"job_id": cfg.get_value("char", "job_id", "swordsman"), "tier": cfg.get_value("char", "job_tier", 1), "branch": cfg.get_value("char", "job_branch", "a"),
		"level": cfg.get_value("char", "base_level", 1), "zeny": cfg.get_value("char", "zeny", 0),
		"appearance": cfg.get_value("char", "appearance", {})}


func save_game() -> void:
	var cfg := ConfigFile.new()
	for k in SAVE_KEYS:
		cfg.set_value("char", k, get(k))
	DirAccess.make_dir_recursive_absolute(CloudAccount.storage_prefix())
	if cfg.save(slot_path(slot)) != OK:
		log_msg("บันทึกเซฟในเครื่องไม่สำเร็จ กรุณาตรวจพื้นที่จัดเก็บ", Color.ORANGE_RED)
		return
	_remember_slot()
	CloudAccount.mark_dirty()
	save_written.emit(slot)


func load_game(i := -1) -> bool:
	if i >= 0:
		slot = i
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return false
	_remember_slot()
	auto_on = false
	auto_quest_target = ""
	auto_quest_giver = ""
	equip = _empty_equip()
	quests = {}
	fashion_unlocks = []
	story_step = 0
	guild_member = false
	guild_rank = 0
	guild_points = 0
	board_offers = []
	board_active = {}
	board_seed = 1
	board_done = 0
	inventory = {}
	refine = {}
	visited_areas = []
	world_day = 0
	party = []
	party_seed = 0
	auto_cfg = auto_cfg.duplicate()
	var auto_defaults := auto_cfg.duplicate()
	skill_levels = {}
	skill_points = -1
	job_tier = 1
	job_branch = "a"
	job_level = -1
	job_exp = 0
	past_job_levels = []
	bonus_skill_points = 0
	planned_job = ""
	hotbar = ["", "", "", "", "", "", "potion_red", "potion_blue", "", "", "", "", "", "", "", ""]
	skill_ready_at = {}
	buffs = {}
	for k in SAVE_KEYS:
		if cfg.has_section_key("char", k):
			set(k, cfg.get_value("char", k))
	var known_unlocks: Array = []
	for f_id in fashion_unlocks:
		if f_id is String and FASHIONS.has(f_id) and not f_id in known_unlocks:known_unlocks.append(f_id)
	fashion_unlocks = known_unlocks
	if not fashion_allowed(String(appearance.get("fashion", ""))):appearance.fashion=""
	for k in auto_defaults:
		if not auto_cfg.has(k):
			auto_cfg[k] = auto_defaults[k]
	if skill_points < 0:   # save from before the skill system
		skill_points = 2 + base_level
	base_level = clampi(base_level, 1, MAX_LEVEL)
	if base_level == MAX_LEVEL: base_exp = 0
	job_tier = clampi(job_tier, 0, 5)
	if job_id == "novice":
		job_tier = 0
	if job_level < 0:
		_migrate_job_levels()
	job_level = clampi(job_level, 1, SkillDB.JOB_MAX[job_tier])
	job = SkillDB.tier_name(job_id, job_tier, job_branch)
	sync_skill_budget()
	quests.erase("slimes")   # quests from before the story line
	quests.erase("boars")
	var eq := _empty_equip()
	for k in equip:
		var id: String = equip[k]
		if id != "" and Items.is_gear(id):
			eq[Items.slot_of(id)] = id
	equip = eq
	while hotbar.size() < HOTBAR_SIZE:
		hotbar.append("")
	hp = clampi(hp, 1, max_hp())
	sp = clampi(sp, 0, max_sp())
	character_ready = true
	changed.emit()
	inventory_changed.emit()
	quest_changed.emit()
	return true


func skill_name(id: String) -> String:
	return SkillDB.info(id).get("name", id)


# ------------------------------------------------------------------ skills, buffs, effective stats
func slv(id: String) -> int:
	return int(skill_levels.get(id, 0))


## Every skill the character can use / learn right now (all unlocked tiers).
func job_skills() -> Array:
	var out: Array = SkillDB.NOVICE_SKILLS.duplicate()
	if job_id == "novice":
		return out
	for t in range(1, job_tier + 1):
		out.append_array(SkillDB.tier_skills(job_id, t, job_branch))
	return out


## Current job title (branch-aware).
func tier_title(t: int) -> String:
	return SkillDB.tier_name(job_id, t, job_branch)


## Why a skill can't be learned yet ("" when it can).
func learn_block(id: String) -> String:
	var s := SkillDB.info(id)
	if s.is_empty():
		return "?"
	if not (id in job_skills()):
		if SkillDB.tier(id) > job_tier:
			return tr("Requires job change: %s") % tr(SkillDB.tier_name(job_id, SkillDB.tier(id), job_branch))
		return tr("Another job's skill")
	if slv(id) >= int(s.max):
		return tr("Max level")
	var need := []
	for r in s.get("req", {}):
		if slv(r) < int(s.req[r]):
			need.append("%s Lv %d" % [tr(skill_name(r)), int(s.req[r])])
	if need.size() > 0:
		return tr("Requires: %s") % ", ".join(need)
	if skill_points <= 0:
		return tr("No skill points")
	return ""


## Skill points come from job levels: 1 per job level gained in every tier
## (Novice Lv 10 gives 9), plus story rewards and points kept from old saves.
func skill_budget() -> int:
	var total := bonus_skill_points
	for lv in past_job_levels:
		total += maxi(0, int(lv) - 1)
	total += maxi(0, job_level - 1)
	for index in range(mini(story_step, Story.STEPS.size())):
		total += int(Story.STEPS[index].get("reward", {}).get("skill_points", 0))
	var capacity := 0
	for id in job_skills():
		capacity += int(SkillDB.info(id).max)
	return mini(total, capacity)


## Old saves (before job levels): give the job level that matches their base
## level, and keep every skill they had learned.
func _migrate_job_levels() -> void:
	if job_id == "novice":
		job_tier = 0
	past_job_levels = []
	if job_tier >= 1:
		past_job_levels.append(SkillDB.JOB_MAX[0])
	for t in range(1, job_tier):
		past_job_levels.append(SkillDB.JOB_CHANGE_AT[t])
	job_level = 1
	var band: Array = SkillDB.JOB_BAND[job_tier]
	var k := clampf(float(base_level - int(band[0])) / float(int(band[1]) - int(band[0])), 0.0, 1.0)
	job_level = clampi(1 + int(k * (SkillDB.JOB_MAX[job_tier] - 1)), 1, SkillDB.JOB_MAX[job_tier])
	job_exp = 0
	bonus_skill_points = 0
	var learned := skills_learned()
	var budget := skill_budget()
	if learned > budget:
		bonus_skill_points = learned - budget
	elif skill_points > 0:
		bonus_skill_points = maxi(0, skill_points - (budget - learned))


func sync_skill_budget() -> void:
	var budget := skill_budget()
	if skills_learned() > budget:
		# never take learned skills away: keep the difference as bonus points
		bonus_skill_points += skills_learned() - budget
		budget = skill_budget()
	skill_points = maxi(0, budget - skills_learned())

func skills_learned() -> int:
	var n := 0
	for id in skill_levels:
		n += int(skill_levels[id])
	return n


## "" when the next job change is possible, otherwise the reason.
func advance_block() -> String:
	if job_tier >= 5:
		return tr("Highest job reached")
	var parts := []
	var need_job: int = SkillDB.JOB_CHANGE_AT[job_tier]
	if job_level < need_job:
		parts.append(tr("Job Lv %d") % need_job)
	var need_base: int = SkillDB.JOB_CHANGE_BASE[job_tier]
	if base_level < need_base:
		parts.append(tr("Base Lv %d") % need_base)
	if job_tier == 0 and slv("basic_training") < 9:
		parts.append(tr("%s Lv 9") % tr(skill_name("basic_training")))
	return tr("Requires: %s") % ", ".join(parts) if parts.size() > 0 else ""


## Choices for the next job change: [[key, title]] (key = job id for a Novice,
## branch "a"/"b" for a 1st job, "" for the 3rd job).
func advance_choices() -> Array:
	match job_tier:
		0:
			var out := []
			for id in Avatar.JOB_ORDER:
				out.append([id, SkillDB.tier_name(id, 1)])
			return out
		1:
			return [["a", SkillDB.tier_name(job_id, 2, "a")], ["b", SkillDB.tier_name(job_id, 2, "b")]]
		2, 3, 4:
			return [[job_branch, SkillDB.tier_name(job_id, job_tier + 1, job_branch)]]
	return []


func advance_job(choice := "") -> bool:
	if advance_block() != "":
		return false
	var options := advance_choices()
	if choice == "":
		choice = String(options[0][0]) if options.size() > 0 else ""
	var valid := false
	for o in options:
		if String(o[0]) == choice:
			valid = true
	if not valid:
		return false
	past_job_levels.append(job_level)
	match job_tier:
		0:
			job_id = choice
			appearance.job = choice
			# swap the novice knife for the new job's starter weapon
			var starter: String = Avatar.job(choice).weapon
			if equip.weapon == "" or equip.weapon == Avatar.job("novice").weapon:
				if equip.weapon != "":
					inventory[equip.weapon] = count(equip.weapon) + 1
				equip.weapon = starter
		1:
			job_branch = choice
	job_tier += 1
	job_level = 1
	job_exp = 0
	job = SkillDB.tier_name(job_id, job_tier, job_branch)
	_drop_forbidden_weapon()
	sync_skill_budget()
	hp = max_hp()
	sp = max_sp()
	log_msg(tr("Job change! You are now a %s. Skill budget updated.") % tr(job), Color(1.0, 0.85, 0.3))
	save_game()
	skills_changed.emit()
	inventory_changed.emit()
	changed.emit()
	return true


# ------------------------------------------------------------------ job levels
func job_exp_to_next() -> int:
	var band: Array = SkillDB.JOB_BAND[job_tier]
	var jmax: int = SkillDB.JOB_MAX[job_tier]
	var span := float(int(band[1]) - int(band[0]))
	var b := int(band[0]) + int(float(job_level - 1) / float(jmax - 1) * span)
	return maxi(10, int(exp_required(b) * span / float(jmax - 1)))


func add_job_exp(amount: int) -> void:
	var jmax: int = SkillDB.JOB_MAX[job_tier]
	if job_level >= jmax:
		job_exp = 0
		return
	job_exp += maxi(0, amount)
	var up := 0
	while job_level < jmax and job_exp >= job_exp_to_next():
		job_exp -= job_exp_to_next()
		job_level += 1
		up += 1
	if job_level >= jmax:
		job_exp = 0
	if up > 0:
		sync_skill_budget()
		log_msg(tr("Job Level Up!  Job Lv %d  (+%d skill points)") % [job_level, up], Color(0.75, 0.9, 1.0))
		if job_tier < 5 and advance_block() == "":
			var nxt := tr("a 1st job") if job_tier == 0 else tr(SkillDB.tier_name(job_id, job_tier + 1, job_branch if job_tier >= 2 else "a"))
			if job_tier == 1:
				nxt = "%s / %s" % [tr(SkillDB.tier_name(job_id, 2, "a")), tr(SkillDB.tier_name(job_id, 2, "b"))]
			log_msg(tr("You can now change job to %s! Open the Skill window (K).") % nxt, Color(1.0, 0.75, 0.3))
		skills_changed.emit()
		changed.emit()


## Unequip a weapon the current job may not use (after a job change).
func _drop_forbidden_weapon() -> void:
	var w: String = equip.get("weapon", "")
	if w != "" and not can_use_weapon(w):
		inventory[w] = count(w) + 1
		equip.weapon = ""
		log_msg(tr("%s can't be used by a %s and was unequipped.") % [Items.item_name(w), tr(job)], Color(0.9, 0.8, 0.6))


## Weapon types this character's job may equip (see Items.JOB_WEAPONS).
func weapon_types() -> Array:
	return Items.weapon_types_for(job_id, job_tier, job_branch)


func can_use_weapon(id: String) -> bool:
	return Items.weapon_type(id) in weapon_types()


## Sum of a stat bonus from learned passives and active buffs (see SkillDB "bonus").
func skill_bonus(key: String) -> float:
	var v := 0.0
	for id in skill_levels:
		var b := SkillDB.bonus(id)
		if b.has(key) and SkillDB.info(id).type == "passive":
			v += float(b[key]) * int(skill_levels[id])
	for id in buffs:
		var b := SkillDB.bonus(id)
		if b.has(key):
			v += float(b[key]) * int(buffs[id].lv)
	return v + gear_bonus(key)


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func start_cooldown(id: String) -> void:
	var cd := SkillDB.cooldown(id, slv(id))
	if cd > 0.0:
		skill_ready_at[id] = _now() + cd


## Seconds left before `id` can be used again (0 = ready).
func cooldown_left(id: String) -> float:
	return maxf(0.0, float(skill_ready_at.get(id, 0.0)) - _now())


func learn_skill(id: String) -> bool:
	var s := SkillDB.info(id)
	if learn_block(id) != "" or not (id in job_skills()):
		return false
	skill_levels[id] = slv(id) + 1
	skill_points -= 1
	if SkillDB.is_active(id) and not (id in hotbar):
		for i in HOTBAR_SIZE:
			if hotbar[i] == "":
				hotbar[i] = id
				break
	log_msg(tr("Learned %s Lv %d.") % [tr(s.name), slv(id)], Color(0.6, 0.85, 1.0))
	skills_changed.emit()
	changed.emit()
	return true


func buff_lv(id: String) -> int:
	return int(buffs[id].lv) if buffs.has(id) else 0


func add_buff(id: String, lv: int, seconds: float) -> void:
	buffs[id] = {"t": seconds, "lv": lv}
	changed.emit()


func _process(delta: float) -> void:
	if buffs.is_empty():
		return
	var gone := []
	for id in buffs:
		buffs[id].t -= delta
		if buffs[id].t <= 0.0:
			gone.append(id)
	for id in gone:
		buffs.erase(id)
		log_msg(tr("%s has worn off.") % tr(skill_name(id)), Color(0.7, 0.7, 0.75))
	if gone.size() > 0:
		changed.emit()


## Stat including skill / buff bonuses.
func st(s: String) -> int:
	var v: int = stats[s]
	match s:
		"DEX":
			v += slv("owls_eye") + buff_lv("blessing")
			if buffs.has("improve_concentration"):
				v += 1 + buff_lv("improve_concentration")
		"AGI":
			if buffs.has("improve_concentration"):
				v += 1 + buff_lv("improve_concentration")
			if buffs.has("increase_agi"):
				v += 2 + buff_lv("increase_agi")
		"STR", "INT":
			v += buff_lv("blessing")
	return v + int(skill_bonus(s))


func move_mult() -> float:
	return (1.25 if buffs.has("increase_agi") else 1.0) * (1.0 + skill_bonus("MOVE") / 100.0)


func range_bonus() -> float:
	return slv("vultures_eye") * 0.5


func hp_regen_mult() -> float:
	return 1.0 + slv("hp_recovery") * 0.1 + (0.5 if job_id == "acolyte" else 0.0) + skill_bonus("HPREGEN") / 100.0


func sp_regen_mult() -> float:
	return 1.0 + slv("sp_recovery") * 0.1 + (0.5 if job_id == "acolyte" else 0.0) + skill_bonus("SPREGEN") / 100.0


func sell_price(id: String) -> int:
	var p: int = Items.info(id).price / 2
	var oc := slv("overcharge")
	return int(p * (1.0 + (5 + 2 * oc) / 100.0)) if oc > 0 else p


func buy_price(id: String) -> int:
	var p: int = Items.info(id).price
	var dc := slv("discount")
	return int(p * (1.0 - (5 + 2 * dc) / 100.0)) if dc > 0 else p


# ------------------------------------------------------------------ derived stats
func max_hp() -> int:
	return int((90 + st("VIT") * 12 + base_level * 20) * (1.0 + skill_bonus("MAXHP_PCT") / 100.0))


func max_sp() -> int:
	return int((20 + st("INT") * 5 + base_level * 3) * (1.0 + skill_bonus("MAXSP_PCT") / 100.0))


func _empty_equip() -> Dictionary:
	var e := {}
	for k in Items.SLOTS:
		e[k] = ""
	return e


## Stat bonuses from every equipped item (same keys as skill bonuses).
func gear_bonus(key: String) -> float:
	var v := 0.0
	for slot in equip:
		var id: String = equip[slot]
		if id != "":
			v += float(Items.info(id).get("bonus", {}).get(key, 0))
	var worn := worn_fashion()
	if worn != "":
		v += float(FASHIONS[worn].bonus.get(key, 0))
	return v


func weapon_atk() -> int:
	if equip.weapon == "":
		return 0
	var r := refine_lv(equip.weapon)
	return Items.info(equip.weapon).get("atk", 0) + refine_bonus(equip.weapon, r)


func armor_def() -> int:
	var d := 0
	for slot in equip:
		var id: String = equip[slot]
		if id == "" or slot == "weapon":
			continue
		d += int(Items.info(id).get("def", 0)) + refine_bonus(id)
	return d


# ------------------------------------------------------------------ refining (blacksmith)
const REFINE_MAX := 10
const REFINE_SAFE := 3          # +1..+3 never fail; from +4 a failure drops the level by 1
## success % for reaching +1 .. +10 (index = target level)
const REFINE_RATE := [100, 100, 100, 100, 90, 75, 60, 45, 30, 18, 8]


func refine_lv(id: String) -> int:
	return int(refine.get(id, 0))


## Name with its refine level, e.g. "+3 Iron Sword".
func item_label(id: String) -> String:
	var r := refine_lv(id)
	return ("+%d " % r if r > 0 else "") + Items.item_name(id)


func refine_cost(id: String) -> int:
	return 200 + 150 * refine_lv(id) * (refine_lv(id) + 1)


## Which refine stone an item needs, and how many (2 from +7 up).
func refine_stone(id: String) -> String:
	return "weapon_stone" if Items.slot_of(id) == "weapon" else "armor_stone"


func refine_stones(id: String) -> int:
	return 2 if refine_lv(id) >= 6 else 1


## Refine bonus of an item at level r: weapons ATK, everything else DEF.
func refine_bonus(id: String, r := -1) -> int:
	if r < 0:
		r = refine_lv(id)
	var slot := Items.slot_of(id)
	if slot == "weapon":
		return r * 4 + maxi(0, r - 4) * 3
	return r * (2 if slot == "armor" else 1)


func refine_chance(id: String) -> int:
	return REFINE_RATE[mini(refine_lv(id) + 1, REFINE_MAX)]


## Raise equipped gear by one, or keep its level on failure. Materials are consumed once.
func try_refine(slot: String, guaranteed := false) -> String:
	var id: String = equip.get(slot, "")
	if id == "":
		return "empty"
	if refine_lv(id) >= REFINE_MAX:
		return "max"
	var stone := refine_stone(id)
	if count(stone) < refine_stones(id):
		return "ore"
	if guaranteed and count("guarantee_stone") < 1:
		return "guarantee"
	var cost := refine_cost(id)
	if zeny < cost:
		return "zeny"
	remove_item(stone, refine_stones(id))
	zeny -= cost
	if guaranteed:
		remove_item("guarantee_stone", 1)
	var previous := refine_lv(id)
	var ok := guaranteed or randi() % 100 < refine_chance(id)
	if ok:
		refine[id] = refine_lv(id) + 1
		log_msg(tr("Refine success! %s") % item_label(id), Color(0.95, 0.75, 0.2))
	else:
		refine[id] = previous
		log_msg(tr("Refine failed, but the item is safe. %s") % item_label(id), Color(0.9, 0.6, 0.4))
	changed.emit()
	inventory_changed.emit()
	return "ok" if ok else "fail"


const ARSENAL_RECIPES := [
	{"id": "sunseal_maul", "zeny": 56000, "mats": {"gold_ore": 12, "mithril_ore": 5, "spirit_ember": 8}},
	{"id": "frostskull_mace", "zeny": 68000, "mats": {"frost_core": 12, "ice_crystal": 12, "wyrm_scale": 1}},
	{"id": "stormgear_hammer", "zeny": 84000, "mats": {"mithril_ore": 14, "gold_ore": 8, "obsidian_shard": 10}},
	{"id": "vineforged_maul", "zeny": 88000, "mats": {"rune_stone": 16, "ancient_bark": 12, "treant_heart": 1}},
	{"id": "venomwyrm_staff", "zeny": 74000, "mats": {"jade_scale": 14, "shadow_shard": 10, "emerald_gem": 2}},
	{"id": "amethyst_spire", "zeny": 110000, "mats": {"shadow_shard": 20, "mithril_ore": 12, "drake_heart": 1}},
	{"id": "lionheart_blade", "zeny": 80000, "mats": {"gold_ore": 14, "sapphire_gem": 3, "rune_stone": 10}},
	{"id": "dreadfang_katar", "zeny": 94000, "mats": {"shadow_shard": 16, "obsidian_shard": 12, "ruby_gem": 2}},
	{"id": "violetshard_dagger", "zeny": 63000, "mats": {"shadow_shard": 10, "silver_ore": 12, "golem_crystal": 6}},
	{"id": "gravewarden_greatsword", "zeny": 100000, "mats": {"rune_stone": 18, "obsidian_shard": 14, "ancient_bark": 12}},
	{"id": "goldcrescent_dagger", "zeny": 84000, "mats": {"gold_ore": 14, "djinn_sand": 12, "emerald_gem": 2}},
	{"id": "jade_dragon_greatsword", "zeny": 112000, "mats": {"jade_scale": 20, "emerald_gem": 4, "drake_heart": 1}},
]

const RECIPES := [
	{"id": "steel_broadsword", "zeny": 500, "mats": {"iron_ore": 4, "boar_tusk": 3}},
	{"id": "crystal_sword", "zeny": 300, "mats": {"ice_crystal": 2, "iron_ore": 2}},
	{"id": "composite_bow", "zeny": 600, "mats": {"goat_horn": 3, "feather": 6, "iron_ore": 1}},
	{"id": "ember_staff", "zeny": 600, "mats": {"spirit_ember": 2, "flower_petal": 3, "iron_ore": 1}},
	{"id": "war_mace", "zeny": 600, "mats": {"golem_crystal": 1, "iron_ore": 4}},
	{"id": "battle_axe", "zeny": 700, "mats": {"goat_horn": 2, "iron_ore": 5}},
	{"id": "viper_dagger", "zeny": 600, "mats": {"shadow_shard": 2, "iron_ore": 3}},
	{"id": "leather_vest", "zeny": 200, "mats": {"boar_hide": 4, "ferret_pelt": 2}},
	{"id": "wool_cloak", "zeny": 400, "mats": {"wool": 5, "ferret_pelt": 2}},
	{"id": "knight_plate", "zeny": 300, "mats": {"iron_ore": 6}},
	{"id": "iron_gauntlets", "zeny": 400, "mats": {"iron_ore": 4, "boar_hide": 2}},
	{"id": "iron_greaves", "zeny": 400, "mats": {"iron_ore": 4, "ferret_pelt": 2}},
	{"id": "shadow_mantle", "zeny": 800, "mats": {"shadow_shard": 3, "wool": 3}},
	{"id": "wind_boots", "zeny": 900, "mats": {"spirit_ember": 2, "feather": 8, "boar_hide": 2}},
	{"id": "swift_brooch", "zeny": 700, "mats": {"feather": 10, "ice_crystal": 1}},
	{"id": "weapon_stone", "zeny": 300, "mats": {"iron_ore": 3}},
	{"id": "armor_stone", "zeny": 400, "mats": {"iron_ore": 3, "boar_hide": 1}},
]


## Gear forged from what you mine and fish ("Ore & Fish" tab at Doran's forge).
const GATHER_RECIPES := [
	{"id": "iron_sword", "zeny": 200, "mats": {"copper_ore": 6, "iron_ore": 2, "coal": 2}},
	{"id": "buckler", "zeny": 200, "mats": {"copper_ore": 8, "iron_ore": 2}},
	{"id": "hunting_bow", "zeny": 300, "mats": {"copper_ore": 4, "fish_scale": 8}},
	{"id": "steel_dagger", "zeny": 400, "mats": {"iron_ore": 5, "coal": 3, "fish_scale": 4}},
	{"id": "iron_mace", "zeny": 500, "mats": {"iron_ore": 8, "coal": 4}},
	{"id": "hand_axe", "zeny": 500, "mats": {"iron_ore": 6, "copper_ore": 6, "coal": 3}},
	{"id": "oak_staff", "zeny": 600, "mats": {"copper_ore": 6, "coal": 2, "emerald_gem": 1}},
	{"id": "twin_fang_katar", "zeny": 800, "mats": {"iron_ore": 8, "coal": 4, "fish_scale": 6}},
	{"id": "steel_glaive", "zeny": 1400, "mats": {"iron_ore": 12, "silver_ore": 2, "coal": 5}},
	{"id": "iron_knuckles", "zeny": 1200, "mats": {"iron_ore": 10, "silver_ore": 2, "coal": 4}},
	{"id": "thornlash_whip", "zeny": 1800, "mats": {"silver_ore": 4, "emerald_gem": 2, "fish_scale": 10}},
	{"id": "silverstring_lute", "zeny": 1800, "mats": {"silver_ore": 6, "pearl": 1, "copper_ore": 6}},
	{"id": "tome_of_embers", "zeny": 2000, "mats": {"gold_ore": 2, "ruby_gem": 1, "coal": 6}},
	{"id": "runed_greatsword", "zeny": 4500, "mats": {"mithril_ore": 4, "iron_ore": 14, "emerald_gem": 2}},
	{"id": "nightclaw_katar", "zeny": 4500, "mats": {"mithril_ore": 4, "silver_ore": 4, "sapphire_gem": 1}},
	{"id": "ember_halberd", "zeny": 5000, "mats": {"mithril_ore": 5, "gold_ore": 3, "ruby_gem": 2}},
	{"id": "dragonbone_knuckles", "zeny": 5000, "mats": {"mithril_ore": 4, "gold_ore": 3, "pearl": 2}},
	{"id": "codex_of_stars", "zeny": 5500, "mats": {"mithril_ore": 3, "sapphire_gem": 2, "pearl": 2}},
	{"id": "iron_helm", "zeny": 900, "mats": {"iron_ore": 8, "coal": 3}},
	{"id": "iron_gauntlets", "zeny": 700, "mats": {"iron_ore": 6, "coal": 2}},
	{"id": "iron_greaves", "zeny": 700, "mats": {"iron_ore": 6, "copper_ore": 4}},
	{"id": "kite_shield", "zeny": 1200, "mats": {"iron_ore": 10, "silver_ore": 3, "coal": 4}},
	{"id": "knight_plate", "zeny": 1800, "mats": {"iron_ore": 12, "silver_ore": 2, "coal": 6}},
	{"id": "tower_shield", "zeny": 5000, "mats": {"iron_ore": 12, "mithril_ore": 4, "coal": 6}},
	{"id": "mithril_plate", "zeny": 12000, "mats": {"mithril_ore": 10, "silver_ore": 6, "gold_ore": 3, "coal": 8}},
	{"id": "power_ring", "zeny": 2500, "mats": {"gold_ore": 3, "ruby_gem": 1}},
	{"id": "sage_ring", "zeny": 2500, "mats": {"silver_ore": 3, "sapphire_gem": 1}},
	{"id": "lucky_rosary", "zeny": 3000, "mats": {"pearl": 2, "silver_ore": 2, "emerald_gem": 1}},
	{"id": "ruby_amulet", "zeny": 6000, "mats": {"gold_ore": 4, "ruby_gem": 2, "pearl": 1}},
	{"id": "pearl_necklace", "zeny": 7000, "mats": {"pearl": 5, "silver_ore": 3}},
	{"id": "weapon_stone", "zeny": 200, "mats": {"iron_ore": 3, "coal": 2}},
	{"id": "armor_stone", "zeny": 300, "mats": {"iron_ore": 3, "coal": 2, "fish_scale": 2}},
]


## Wyvern wings (crafted at Doran's forge, "Wings" tab).
const WING_RECIPES := [
	{"id": "wings_abyssal", "zeny": 25000, "mats": {"shadow_shard": 10, "spore_powder": 8, "bat_wing": 4}},
	{"id": "wings_lightning", "zeny": 30000, "mats": {"djinn_sand": 8, "bat_wing": 6, "golem_crystal": 6}},
	{"id": "wings_poison", "zeny": 35000, "mats": {"living_vine": 10, "spore_powder": 8, "scorpion_stinger": 1}},
	{"id": "wings_ancient", "zeny": 40000, "mats": {"ancient_bark": 8, "rune_stone": 8, "pharaoh_gold": 1}},
	{"id": "wings_frozen", "zeny": 45000, "mats": {"frost_core": 8, "wolf_fang": 8, "wyrm_scale": 1}},
	{"id": "wings_fire", "zeny": 50000, "mats": {"salamander_tail": 8, "magma_gel": 10, "phoenix_feather": 1}},
]


## Arcane Mage collection: late-game gear from zone materials + one boss trophy.
const ARCANE_RECIPES := [
	{"id": "arcane_dagger", "zeny": 40000, "mats": {"jackal_fang": 10, "jade_scale": 8, "bat_wing": 6, "scorpion_stinger": 1}},
	{"id": "arcane_sword", "zeny": 45000, "mats": {"golem_crystal": 8, "rune_stone": 8, "lava_core": 6, "drake_heart": 1}},
	{"id": "arcane_axe", "zeny": 48000, "mats": {"obsidian_shard": 10, "yeti_horn": 8, "frost_core": 6, "mammoth_tusk": 1}},
	{"id": "arcane_hammer", "zeny": 46000, "mats": {"rune_stone": 10, "obsidian_shard": 8, "golem_crystal": 6, "treant_heart": 1}},
	{"id": "arcane_bow", "zeny": 45000, "mats": {"living_vine": 10, "salamander_tail": 8, "spirit_ember": 6, "phoenix_feather": 1}},
	{"id": "arcane_crossbow", "zeny": 48000, "mats": {"ancient_bark": 10, "lizard_scale": 8, "imp_horn": 6, "scorpion_stinger": 1}},
	{"id": "arcane_staff", "zeny": 46000, "mats": {"spore_powder": 10, "ash_cloth": 8, "spirit_ember": 8, "pharaoh_gold": 1}},
	{"id": "glacier_staff", "zeny": 46000, "mats": {"ice_crystal": 12, "frost_core": 8, "snow_fur": 8, "wyrm_scale": 1}},
	{"id": "arcane_cross_shield", "zeny": 40000, "mats": {"scarab_shell": 10, "mummy_wrap": 8, "ice_crystal": 6, "pharaoh_gold": 1}},
	{"id": "arcane_tower_shield", "zeny": 50000, "mats": {"obsidian_shard": 12, "scarab_shell": 8, "lava_core": 6, "wyrm_scale": 1}},
	{"id": "arcane_armor", "zeny": 80000, "mats": {"ash_cloth": 12, "mummy_wrap": 10, "snow_fur": 10, "drake_heart": 1, "royal_gel": 1}},
]


## Fourteen Celestial Staves, cheapest first.
const STAFF_RECIPES := [
	{"id": "verdant_crescent_staff", "zeny": 10000, "mats": {"flower_petal": 8, "living_vine": 6, "royal_gel": 1}},
	{"id": "jade_enchanter_staff", "zeny": 13000, "mats": {"jade_scale": 8, "spore_powder": 6, "moss_clump": 1}},
	{"id": "violet_moon_staff", "zeny": 16000, "mats": {"shadow_shard": 8, "ancient_bark": 6, "treant_heart": 1}},
	{"id": "solar_wand", "zeny": 18000, "mats": {"djinn_sand": 8, "cactus_needle": 6, "scorpion_stinger": 1}},
	{"id": "amber_starfall_staff", "zeny": 21000, "mats": {"scarab_shell": 8, "jackal_fang": 6, "pharaoh_gold": 1}},
	{"id": "rose_compass_staff", "zeny": 23000, "mats": {"flower_petal": 10, "mummy_wrap": 6, "pharaoh_gold": 1}},
	{"id": "ivory_moonwing_staff", "zeny": 25000, "mats": {"snow_fur": 8, "bat_wing": 6, "mammoth_tusk": 1}},
	{"id": "frost_diadem_staff", "zeny": 27000, "mats": {"ice_crystal": 10, "frost_core": 6, "wyrm_scale": 1}},
	{"id": "sapphire_lotus_staff", "zeny": 29000, "mats": {"frost_core": 8, "yeti_horn": 6, "wyrm_scale": 1}},
	{"id": "azure_orb_staff", "zeny": 31000, "mats": {"ice_crystal": 8, "golem_crystal": 6, "mammoth_tusk": 1}},
	{"id": "midnight_fleur_staff", "zeny": 34000, "mats": {"shadow_shard": 10, "imp_horn": 6, "phoenix_feather": 1}},
	{"id": "lunar_familiar_staff", "zeny": 37000, "mats": {"spirit_ember": 10, "ash_cloth": 6, "phoenix_feather": 1}},
	{"id": "astral_star_staff", "zeny": 42000, "mats": {"golem_crystal": 8, "lava_core": 6, "drake_heart": 1}},
	{"id": "ruby_eclipse_staff", "zeny": 48000, "mats": {"magma_gel": 10, "salamander_tail": 8, "drake_heart": 1}},
]


## Seven Arcane Bows, from the verdant forest to the ember wastes.
const BOW_RECIPES := [
	{"id": "verdant_ruby_bow", "zeny": 15000, "mats": {"living_vine": 8, "jade_scale": 6, "treant_heart": 1}},
	{"id": "aureate_seraph_bow", "zeny": 22000, "mats": {"djinn_sand": 8, "scarab_shell": 6, "pharaoh_gold": 1}},
	{"id": "frost_crescent_bow", "zeny": 28000, "mats": {"ice_crystal": 10, "wolf_fang": 6, "wyrm_scale": 1}},
	{"id": "crimson_thorn_bow", "zeny": 32000, "mats": {"spore_powder": 8, "salamander_tail": 6, "scorpion_stinger": 1}},
	{"id": "astral_silver_bow", "zeny": 40000, "mats": {"spirit_ember": 10, "ash_cloth": 6, "phoenix_feather": 1}},
	{"id": "aether_cyan_bow", "zeny": 42000, "mats": {"frost_core": 8, "bat_wing": 8, "golem_crystal": 6, "mammoth_tusk": 1}},
	{"id": "obsidian_dragon_bow", "zeny": 45000, "mats": {"obsidian_shard": 10, "imp_horn": 6, "drake_heart": 1}},
]


func can_craft(r: Dictionary) -> bool:
	var level := int(Items.info(String(r.get("id", ""))).get("equip_lv", 0))
	if level > 0 and (base_level < level or r not in ARSENAL_RECIPES):
		return false
	var fashion_id := fashion_for_recipe(String(r.get("id", "")))
	if fashion_id != "":
		if r != FASHIONS[fashion_id].recipe or owns_fashion(fashion_id) or not fashion_job_ok(fashion_id):return false
	if zeny < int(r.zeny):
		return false
	for m in r.mats:
		if count(m) < int(r.mats[m]):
			return false
	return true


func craft(r: Dictionary) -> bool:
	if not can_craft(r):
		return false
	for m in r.mats:
		remove_item(m, int(r.mats[m]))
	zeny -= int(r.zeny)
	var unlocked := fashion_for_recipe(String(r.id))
	if unlocked != "":
		fashion_unlocks.append(unlocked)
		save_game()
	else:add_item(r.id, 1)
	log_msg(tr("Crafted %s!") % Items.item_name(r.id), Color(0.95, 0.75, 0.2))
	Audio.play("craft")
	changed.emit()
	save_game()
	return true


func atk() -> int:
	var main: String = job_info().main
	var second: int = st("STR") / 5 if main != "STR" else st("DEX") / 5
	var base := st(main) * 2 + second + st("LUK") / 5 + weapon_atk() + slv("sword_mastery") * 4 + int(skill_bonus("ATK"))
	return int(base * (1.0 + skill_bonus("ATK_PCT") / 100.0))


func def() -> int:
	return maxi(0, armor_def() + st("VIT") / 2 + slv("divine_protection") * 2 + buff_lv("endure") * 2 + int(skill_bonus("DEF")))


func hit() -> int:
	return base_level + st("DEX") + 10 + slv("vultures_eye") + int(skill_bonus("HIT"))


func flee() -> int:
	return base_level + st("AGI") + 5 + slv("improve_dodge") * 3 + int(skill_bonus("FLEE"))


func crit_rate() -> float:
	return 1.0 + st("LUK") * 0.3 + skill_bonus("CRIT")


func attack_interval() -> float:
	return clampf((1.05 - st("AGI") * 0.012 - st("DEX") * 0.003) / (1.0 + skill_bonus("ASPD") / 100.0), 0.25, 1.2)


func aspd() -> int:
	return int(200.0 - attack_interval() * 50.0)


func weight() -> int:
	var w := 0
	for id in inventory:
		w += Items.info(id).weight * inventory[id]
	for slot in equip:
		if equip[slot] != "":
			w += Items.info(equip[slot]).weight
	return w


func max_weight() -> int:
	return 2000 + st("STR") * 30 + (1000 if job_id == "merchant" else 0) + slv("enlarge_weight") * 200


func exp_to_next() -> int:
	return exp_required(base_level)


func stat_cost(s: String) -> int:
	return int((stats[s] - 1) / 10) + 2


# ------------------------------------------------------------------ actions
func raise_stat(s: String) -> bool:
	var c := stat_cost(s)
	if stat_points < c or stats[s] >= 99:
		return false
	stat_points -= c
	stats[s] += 1
	hp = mini(hp, max_hp())
	sp = mini(sp, max_sp())
	changed.emit()
	return true


func add_exp(amount: int) -> int:
	add_job_exp(amount)
	if base_level >= MAX_LEVEL:
		base_level = MAX_LEVEL
		base_exp = 0
		return 0
	base_exp += maxi(0, amount)
	log_msg(tr("You gained %d Base EXP.") % amount, Color(0.55, 0.85, 1.0))
	var gained := 0
	while base_level < MAX_LEVEL and base_exp >= exp_to_next():
		base_exp -= exp_to_next()
		base_level += 1
		gained += 1
		stat_points += 3 + base_level / 5
		sync_skill_budget()
		hp = max_hp()
		sp = max_sp()
		log_msg(tr("Base Level Up!  Lv %d  (+%d status points)") % [base_level, 3 + base_level / 5], Color(1.0, 0.85, 0.25))
	if base_level >= MAX_LEVEL: base_exp = 0
	skills_changed.emit()
	changed.emit()
	return gained


func heal(dhp: int, dsp := 0) -> void:
	hp = clampi(hp + dhp, 0, max_hp())
	sp = clampi(sp + dsp, 0, max_sp())
	changed.emit()


func add_zeny(z: int) -> void:
	zeny += z
	changed.emit()


func count(id: String) -> int:
	return inventory.get(id, 0)


func add_item(id: String, n := 1, quiet := false) -> void:
	inventory[id] = count(id) + n
	if not quiet:
		log_msg(tr("Item obtained: %s x%d") % [Items.item_name(id), n], Color(0.6, 1.0, 0.6))
	inventory_changed.emit()
	changed.emit()


func remove_item(id: String, n := 1) -> bool:
	if count(id) < n:
		return false
	inventory[id] = count(id) - n
	if inventory[id] <= 0:
		inventory.erase(id)
	inventory_changed.emit()
	changed.emit()
	return true


func use_item(id: String) -> bool:
	var it := Items.info(id)
	match it.type:
		"use":
			if count(id) <= 0:
				return false
			if it.has("warp"):
				var traveler := get_tree().get_first_node_in_group("player")
				return traveler != null and traveler.use_warp_item(id)
			if hp >= max_hp() and it.has("heal_hp") and not it.has("heal_sp"):
				log_msg("HP is already full.", Color(0.8, 0.8, 0.8))
				return false
			remove_item(id)
			heal(it.get("heal_hp", 0), it.get("heal_sp", 0))
			Audio.play("potion")
			var p := get_tree().get_first_node_in_group("player") as Node3D
			if p:
				FX.popup(p, p.global_position + Vector3(0, 2.0, 0), "+%d" % it.get("heal_hp", it.get("heal_sp", 0)),
						Color(0.4, 1.0, 0.4) if it.has("heal_hp") else Color(0.45, 0.65, 1.0))
			return true
		"weapon", "armor":
			return equip_item(id)
	return false


func equip_item(id: String) -> bool:
	var slot := Items.slot_of(id)
	if slot == "" or count(id) <= 0:
		return false
	var level := int(Items.info(id).get("equip_lv", 0))
	if base_level < level:
		log_msg("ต้องการ Base Lv %d เพื่อสวม %s" % [level, Items.item_name(id)], Color(1.0, 0.55, 0.45))
		Audio.play("ui_error")
		return false
	if slot == "weapon" and not can_use_weapon(id):
		log_msg(tr("A %s can't use %s.") % [tr(job), tr(Items.WEAPON_TYPE_NAMES.get(Items.weapon_type(id), "this weapon"))], Color(1.0, 0.55, 0.45))
		Audio.play("ui_error")
		return false
	remove_item(id)
	if equip[slot] != "":
		inventory[equip[slot]] = count(equip[slot]) + 1
	equip[slot] = id
	# two-handed weapons and shields don't mix
	if slot == "weapon" and Items.info(id).get("two_hand", false) and equip.shield != "":
		inventory[equip.shield] = count(equip.shield) + 1
		log_msg(tr("Two-handed weapon: %s was unequipped.") % Items.item_name(equip.shield), Color(0.9, 0.8, 0.6))
		equip.shield = ""
	elif slot == "shield" and equip.weapon != "" and Items.info(equip.weapon).get("two_hand", false):
		inventory[equip.weapon] = count(equip.weapon) + 1
		log_msg(tr("Two-handed weapon: %s was unequipped.") % Items.item_name(equip.weapon), Color(0.9, 0.8, 0.6))
		equip.weapon = ""
	log_msg(tr("Equipped %s.") % Items.item_name(id), Color(0.9, 0.9, 0.9))
	Audio.play("ui_equip")
	inventory_changed.emit()
	changed.emit()
	return true


func unequip(slot: String) -> void:
	if equip[slot] == "":
		return
	add_item(equip[slot], 1, true)
	log_msg(tr("Unequipped %s.") % Items.item_name(equip[slot]), Color(0.9, 0.9, 0.9))
	equip[slot] = ""
	inventory_changed.emit()
	changed.emit()


# ------------------------------------------------------------------ quests
func on_kill(monster_name: String) -> void:
	Guild.on_kill(monster_name)
	for qid in quests:
		var q: Dictionary = quests[qid]
		if q.state == "active" and q.target == monster_name:
			q.count += 1
			log_msg(tr("[Quest] %s: %d / %d") % [tr(q.title), mini(q.count, q.need), q.need], Color(1.0, 0.8, 0.5))
			if q.count >= q.need:
				q.state = "done"
				log_msg(tr("[Quest] %s complete! Report back to %s.") % [tr(q.title), tr(q.giver)], Color(1.0, 0.85, 0.3))
				Audio.play("coin", null, 2.0)
			quest_changed.emit()


func start_quest(qid: String, title: String, target: String, need: int, giver: String) -> void:
	quests[qid] = {"state": "active", "title": title, "target": target, "need": need, "count": 0, "giver": giver}
	log_msg(tr("[Quest] Accepted: %s") % tr(title), Color(1.0, 0.85, 0.3))
	quest_changed.emit()


func log_msg(text: String, color := Color(1, 1, 1)) -> void:
	message.emit(text, color)


# ------------------------------------------------------------------ live events (from the website)
signal events_changed
var event_bonus := {"exp": 1.0, "drop": 1.0, "gather": 1.0}
var active_events: Array = []      # [{id, title, bonus}]


func event_mult(key: String) -> float:
	return float(event_bonus.get(key, 1.0))


## The web page keeps window.BLOCKREALM_EVENTS = the events running right now.
func _poll_events() -> void:
	if not OS.has_feature("web"):
		return
	var js := "(function(){try{var e=(window.parent&&window.parent!==window&&window.parent.BLOCKREALM_EVENTS)||window.BLOCKREALM_EVENTS;return e?JSON.stringify(e):'[]';}catch(x){return '[]';}})()"
	var txt = JavaScriptBridge.eval(js, true)
	var arr = JSON.parse_string(String(txt)) if txt is String else []
	if not arr is Array:
		return
	var bonus := {"exp": 1.0, "drop": 1.0, "gather": 1.0}
	var list := []
	var known := {}
	for e in active_events:
		known[e.id] = true
	for e in arr:
		if not e is Dictionary:
			continue
		var b = e.get("bonus", {})
		var d := {"id": String(e.get("id", "")), "title": String(e.get("title", "")).left(80), "bonus": {}}
		if b is Dictionary:
			for k in bonus:
				if b.has(k):
					var v := clampf(float(b[k]), 1.0, 3.0)
					bonus[k] *= v
					d.bonus[k] = v
		list.append(d)
		if not known.has(d.id) and character_ready:
			var parts := PackedStringArray()
			for k in d.bonus:
				parts.append("%s x%s" % [tr({"exp": "EXP", "drop": "Drop rate", "gather": "Mining & fishing"}[k]), str(snappedf(float(d.bonus[k]), 0.01)).trim_suffix(".0")])
			log_msg(tr("Event: %s") % d.title + ("  (" + ", ".join(parts) + ")" if not parts.is_empty() else ""), Color(1.0, 0.8, 0.3))
	for k in bonus:
		bonus[k] = minf(bonus[k], 3.0)
	var changed_now := var_to_str(bonus) != var_to_str(event_bonus) or list.size() != active_events.size()
	event_bonus = bonus
	active_events = list
	if changed_now:
		events_changed.emit()


## Smooth curve; early levels teach quickly, later levels require sustained hunts.
static func exp_required(lv: int) -> int:
	return int((60 + lv * lv * 25) * (1.0 + maxf(0, lv - 30) * 0.012))

func monster_exp_multiplier(monster_level: int) -> float:
	var gap := monster_level - base_level
	if gap < -20:return 0.1
	if gap < -10:return 0.35
	if gap < -5:return 0.65
	if gap > 15:return 0.5
	return 1.15 if gap >= 3 else 1.0

## Spend all available points along a chosen build; prerequisites remain enforced.
func allocate_build(mode: String) -> void:
	if mode not in ["attack", "support", "balanced"]:return
	var available := job_skills()
	var remaining := skill_points
	for pass_index in range(remaining):
		var best := ""
		var score := -100000.0
		for id in available:
			if learn_block(id) != "":continue
			var spec := SkillDB.info(id)
			var attack: bool = spec.type in ["melee", "bolt", "aoe_self", "aoe_target"]
			var candidate := -float(slv(id))
			if mode == "attack" and attack:candidate += 20
			if mode == "support" and not attack:candidate += 20
			if id == "basic_training":candidate += 100
			if candidate > score:score=candidate;best=id
		if best == "":break
		skill_levels[best] = slv(best) + 1
		skill_points -= 1
	skills_changed.emit()
	changed.emit()
	save_game()


## Cosmetic only: saved inside appearance and shared with other players.
func set_mage_fashion(id: String) -> bool:
	return set_fashion(id)


func set_fashion(id: String) -> bool:
	if id != "" and not FASHIONS.has(id):return false
	if id != "" and not fashion_job_ok(id):return false
	if id != "" and not owns_fashion(id):
		log_msg("ต้องคราฟชุด %s กับ Blacksmith Doran ก่อน" % FASHIONS[id].name, Color(1,.7,.4));return false
	if appearance.is_empty():appearance=Avatar.default_appearance();appearance.job=job_id
	appearance["fashion"]=id
	changed.emit()
	inventory_changed.emit()
	save_game()
	return true


const FOREST_MAGE_RECIPE := {"id":"forest_mage_fashion", "zeny":10000, "mats":{"living_vine":12,"moss_clump":15,"flower_petal":8,"treant_heart":1}}
func owns_mage_fashion() -> bool:return "forest_mage" in fashion_unlocks

## Every craftable fashion. `jobs` empty = any job. `bonus` uses the same keys as gear bonuses
## and only applies while the fashion is worn.
const FASHIONS := {
	"crimson_bastion": {"name": "Crimson Bastion", "jobs": [], "bonus": {"STR": 2, "VIT": 3, "DEF": 8, "MAXHP_PCT": 5}, "recipe": {"id": "crimson_bastion_fashion", "zeny": 12000, "mats": {"iron_ore": 8, "ruby_gem": 4}}},
	"iron_warden": {"name": "Iron Warden", "jobs": [], "bonus": {"VIT": 3, "STR": 2, "DEF": 10, "HPREGEN": 15}, "recipe": {"id": "iron_warden_fashion", "zeny": 12000, "mats": {"iron_ore": 8, "silver_ore": 4}}},
	"cinder_ranger": {"name": "Cinder Ranger", "jobs": [], "bonus": {"DEX": 3, "AGI": 2, "ATK": 10, "CRIT": 2}, "recipe": {"id": "cinder_ranger_fashion", "zeny": 12000, "mats": {"ash_cloth": 8, "spirit_ember": 4}}},
	"gilded_wayfarer": {"name": "Gilded Wayfarer", "jobs": [], "bonus": {"AGI": 3, "LUK": 2, "MOVE": 5, "FLEE": 6}, "recipe": {"id": "gilded_wayfarer_fashion", "zeny": 12000, "mats": {"gold_ore": 8, "wool": 4}}},
	"verdigris_arcanist": {"name": "Verdigris Arcanist", "jobs": [], "bonus": {"INT": 3, "DEX": 2, "MAXSP_PCT": 8, "SPREGEN": 10}, "recipe": {"id": "verdigris_arcanist_fashion", "zeny": 12000, "mats": {"silver_ore": 8, "emerald_gem": 4}}},
	"azure_bulwark": {"name": "Azure Bulwark", "jobs": [], "bonus": {"VIT": 3, "STR": 2, "DEF": 12, "MAXHP_PCT": 3}, "recipe": {"id": "azure_bulwark_fashion", "zeny": 12000, "mats": {"mithril_ore": 8, "gold_ore": 4}}},
	"solar_regalia": {"name": "Solar Regalia", "jobs": [], "bonus": {"INT": 2, "VIT": 2, "LUK": 1, "HEAL_PCT": 10, "MAXSP_PCT": 5}, "recipe": {"id": "solar_regalia_fashion", "zeny": 12000, "mats": {"gold_ore": 8, "spirit_ember": 4}}},
	"amethyst_oracle": {"name": "Amethyst Oracle", "jobs": [], "bonus": {"INT": 3, "LUK": 2, "MAXSP_PCT": 10, "CRIT": 2}, "recipe": {"id": "amethyst_oracle_fashion", "zeny": 12000, "mats": {"silver_ore": 8, "shadow_shard": 4}}},
	"infernal_executioner": {"name": "Infernal Executioner", "jobs": [], "bonus": {"STR": 3, "LUK": 2, "ATK": 14, "CRIT": 3}, "recipe": {"id": "infernal_executioner_fashion", "zeny": 12000, "mats": {"iron_ore": 8, "lava_core": 4}}},
	"rosewing_paladin": {"name": "Rosewing Paladin", "jobs": [], "bonus": {"STR": 2, "VIT": 2, "INT": 1, "DEF": 6, "HEAL_PCT": 8}, "recipe": {"id": "rosewing_paladin_fashion", "zeny": 12000, "mats": {"silver_ore": 8, "flower_petal": 4}}},
	"evergreen_giftkeeper": {"name": "Evergreen Giftkeeper", "jobs": [], "bonus": {"LUK": 3, "VIT": 2, "HPREGEN": 15, "SPREGEN": 10}, "recipe": {"id": "evergreen_giftkeeper_fashion", "zeny": 12000, "mats": {"living_vine": 8, "wool": 4}}},
	"celestial_falcon": {"name": "Celestial Falcon", "jobs": [], "bonus": {"DEX": 3, "AGI": 2, "HIT": 10, "ASPD": 5}, "recipe": {"id": "celestial_falcon_fashion", "zeny": 12000, "mats": {"gold_ore": 8, "sapphire_gem": 4}}},
	"eternal_armor": {"name": "Eternal Armor", "jobs": [], "bonus": {"STR": 2, "AGI": 2, "VIT": 2, "INT": 2, "DEX": 2, "LUK": 2, "DEF": 8, "MAXHP_PCT": 5},
		"recipe": {"id": "eternal_armor_fashion", "zeny": 15000, "mats": {"gold_ore": 8, "mithril_ore": 4, "sapphire_gem": 2}}},
	"forest_mage": {"name": "Forest Mage", "jobs": ["mage"], "bonus": {"INT": 3, "DEX": 2, "MAXSP_PCT": 8, "SPREGEN": 10}, "recipe": FOREST_MAGE_RECIPE},
	"pumpkin_reaper": {"name": "Pumpkin Reaper", "jobs": [], "bonus": {"STR": 3, "VIT": 2, "ATK": 12, "MAXHP_PCT": 5},
		"recipe": {"id": "pumpkin_reaper_fashion", "zeny": 15000, "mats": {"spirit_ember": 10, "ash_cloth": 8, "imp_horn": 4, "boar_hide": 6}}},
	"bone_oracle": {"name": "Bone Oracle", "jobs": [], "bonus": {"INT": 3, "DEX": 2, "MAXSP_PCT": 10, "SPREGEN": 15},
		"recipe": {"id": "bone_oracle_fashion", "zeny": 15000, "mats": {"shadow_shard": 10, "bat_wing": 8, "ash_cloth": 6, "spirit_ember": 4}}},
	"hollow_scarecrow": {"name": "Hollow Scarecrow", "jobs": [], "bonus": {"AGI": 3, "LUK": 2, "FLEE": 8, "CRIT": 3},
		"recipe": {"id": "hollow_scarecrow_fashion", "zeny": 15000, "mats": {"living_vine": 10, "wool": 10, "spore_powder": 6, "boar_hide": 4}}},
}
const FASHION_ORDER := ["crimson_bastion", "iron_warden", "cinder_ranger", "gilded_wayfarer", "verdigris_arcanist", "azure_bulwark", "solar_regalia", "amethyst_oracle", "infernal_executioner", "rosewing_paladin", "evergreen_giftkeeper", "celestial_falcon", "eternal_armor", "pumpkin_reaper", "bone_oracle", "hollow_scarecrow", "forest_mage"]

func owns_fashion(id: String) -> bool:return id in fashion_unlocks
func fashion_job_ok(id: String) -> bool:
	return FASHIONS.has(id) and (FASHIONS[id].jobs.is_empty() or job_id in FASHIONS[id].jobs)
func fashion_allowed(id: String) -> bool:
	return id == "" or (owns_fashion(id) and fashion_job_ok(id))
func worn_fashion() -> String:
	var id := String(appearance.get("fashion", ""))
	return id if id != "" and fashion_allowed(id) else ""
func fashion_for_recipe(recipe_id: String) -> String:
	for id in FASHIONS:
		if FASHIONS[id].recipe.id == recipe_id:return id
	return ""
func fashion_recipes() -> Array:
	var out: Array = []
	for id in FASHION_ORDER:
		if fashion_job_ok(id):out.append(FASHIONS[id].recipe)
	return out


const HAT_RECIPES := [{"id": "hat_red_bandana", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_dragon_mask", "zeny": 7000, "mats": {"shadow_shard": 8, "imp_horn": 2, "boar_hide": 4}}, {"id": "hat_winter_ushanka", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_royal_crown", "zeny": 5000, "mats": {"gold_ore": 3, "emerald_gem": 1}}, {"id": "hat_horned_helm", "zeny": 2400, "mats": {"iron_ore": 5, "goat_horn": 2}}, {"id": "hat_blue_bandana", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_rice_straw_hat", "zeny": 900, "mats": {"living_vine": 5, "wool": 3}}, {"id": "hat_straw_boater", "zeny": 900, "mats": {"living_vine": 5, "wool": 3}}, {"id": "hat_black_headband", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_gold_hardhat", "zeny": 2500, "mats": {"iron_ore": 5, "silver_ore": 2}}, {"id": "hat_silver_headphones", "zeny": 2500, "mats": {"iron_ore": 5, "silver_ore": 2}}, {"id": "hat_black_headphones", "zeny": 2500, "mats": {"iron_ore": 5, "silver_ore": 2}}, {"id": "hat_captain_cap", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_red_beret", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_black_top_hat", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_leather_fedora", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_sailor_cap", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_bunny_ears", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_robot_visor", "zeny": 2500, "mats": {"iron_ore": 5, "silver_ore": 2}}, {"id": "hat_chef_hat", "zeny": 1200, "mats": {"wool": 6, "boar_hide": 2}}, {"id": "hat_indigo_wizard_hat", "zeny": 2200, "mats": {"wool": 6, "spirit_ember": 3}}]

## One canonical recipe per item, organized by the item that is produced.
func crafting_recipes(category: String, weapon_kind: String="all") -> Array:
	var result:=[];var seen:Dictionary={}
	for recipes in [ARSENAL_RECIPES,RECIPES,GATHER_RECIPES,ARCANE_RECIPES,STAFF_RECIPES,BOW_RECIPES,HAT_RECIPES]:
		for recipe in recipes:
			if seen.has(recipe.id):continue
			seen[recipe.id]=true
			var item:=Items.info(recipe.id);var type:String=item.type;var slot:String=item.get("slot", "")
			var target:="materials"
			if type=="weapon":target="weapons"
			elif type=="armor":target="hats" if slot=="head" else ("accessories" if slot=="accessory" else "armor")
			if target!=category:continue
			if target=="weapons" and weapon_kind!="all" and Items.weapon_type(recipe.id)!=weapon_kind:continue
			result.append(recipe)
	return result
