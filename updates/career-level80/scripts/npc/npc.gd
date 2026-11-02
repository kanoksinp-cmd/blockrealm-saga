class_name NPC
extends StaticBody3D
## Town NPC: click to talk. Roles: guild (heal / save point), shop, quest, sage.

@export var npc_name := "Villager"
@export var role := "sage"
@export var skin := 0
## Adventurer-style NPCs use the player avatar (look = creator appearance, gear = equip dict).
var look := {}
var gear := {}
## Where the player walks to before talking (NPCs behind counters / desks), and how far they can talk from.
var talk_spot := Vector3.INF
var reach := 0.0

var model: Node3D
var _label: Label3D
var _marker: Label3D
var _t := 0.0
var _name_hovered := false
var _name_height := 2.2

const SHOP_STOCK := ["warp_short", "warp_long", "potion_red", "potion_blue", "crystal_sword", "steel_broadsword", "ash_pike", "iron_greatsword", "leather_knuckles", "worn_tome", "braided_whip", "travelers_lute", "knight_plate", "mithril_plate",
	"mage_robe", "priest_vestment", "buckler", "kite_shield", "leather_cap", "iron_helm", "wizard_hat", "feather_bonnet",
	"travel_cape", "wool_muffler", "leather_gloves", "leather_boots", "sandals", "power_ring", "sage_ring", "hawk_clip"]
const SMITH_STOCK := ["guarantee_stone", "weapon_stone", "armor_stone", "iron_ore"]


func _ready() -> void:
	add_to_group("npc")
	collision_layer = 8
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.9
	cs.shape = cap
	cs.position.y = 0.95
	add_child(cs)
	if look.is_empty() and role not in ["board", "ranking", "warp"]:
		look = preload("res://scripts/npc/npc_costume.gd").appearance(role)
	model = Node3D.new()
	model.name = "Model"
	add_child(model)
	if role in ["board", "ranking"]:
		pass                                  # the notice board itself is a prop
	elif role == "warp":
		_crystal_model()
	elif not look.is_empty():
		var km := KnightModel.new()
		km.appearance = Avatar.dress(look, gear, {})
		km.name = "Avatar"
		model.add_child(km)
		preload("res://scripts/npc/npc_costume.gd").decorate(km,role)
	else:
		Skins.build_villager(model, skin)
	_label = Label3D.new()
	_label.font = load("res://assets/fonts/ui_font_bold.tres")
	refresh_label()
	_apply_name_size()
	_label.outline_size = 12
	_label.modulate = Color(0.05, 0.05, 0.07)
	_label.outline_modulate = Color(1, 1, 1)
	_label.pixel_size = 0.005
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_name_height = 0.5 if role in ["board", "ranking"] else (2.9 if role == "warp" else 2.2)
	if role not in ["board", "ranking", "warp"]:
		for node in model.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh.mesh:
				var box: AABB = (global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
				_name_height = maxf(_name_height, box.end.y + 0.25)
	_apply_name_size()
	add_child(_label)
	_marker = Label3D.new()
	_marker.font_size = 90
	_marker.outline_size = 14
	_marker.modulate = Color(1.0, 0.85, 0.2)
	_marker.pixel_size = 0.006
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.position.y = 2.45
	add_child(_marker)
	Settings.changed.connect(refresh_label)
	Game.quest_changed.connect(_update_marker)
	_update_marker()


func refresh_label() -> void:
	_label.text = tr(npc_name)
	_label.visible = Settings.g("npc_names")
	_apply_name_size()


func set_hovered(b: bool) -> void:
	_name_hovered = b
	_label.modulate = Color(0.55, 0.32, 0.0) if b else Color(0.05, 0.05, 0.07)
	_apply_name_size()


func _apply_name_size() -> void:
	var scale_factor := clampf(float(Settings.g("nameplate_scale")), 0.5, 2.0)
	_label.font_size = roundi((44 if _name_hovered else 38) * scale_factor)
	_label.outline_size = maxi(2, roundi(12 * scale_factor))
	_label.position.y = _name_height + maxf(0, scale_factor - 1.0) * 0.15


func _process(delta: float) -> void:
	_t += delta
	var mark_base := 4.3 if role in ["board", "ranking"] else _label.position.y + 0.35 + float(_label.font_size) * _label.pixel_size * 0.5   # board: name at its feet, marker over the roof
	_marker.position.y = mark_base + sin(_t * 3.0) * 0.08
	var body := model.get_node_or_null("Body/Hips/Torso/Head")
	if body:
		body.rotation.y = sin(_t * 0.7) * 0.25
	var gem := model.get_node_or_null("Gem") as Node3D
	if gem:
		gem.rotation.y = _t * 0.9
		gem.position.y = 1.55 + sin(_t * 1.6) * 0.12


func _update_marker() -> void:
	_marker.text = Story.marker_for(npc_name)
	if _marker.text == "":_marker.text = SideQuests.marker(npc_name)
	_marker.modulate = Color(1.0, 0.85, 0.2) if _marker.text == "!" else Color(0.55, 0.9, 1.0)


func face(target: Vector3) -> void:
	var d := target - global_position
	model.rotation.y = atan2(d.x, d.z)


# ------------------------------------------------------------------ dialog
func interact(player: Node3D) -> void:
	face(player.global_position)
	var ui = Game.ui
	if ui == null:
		return
	if Story.interact(self, ui, func() -> void: _role_dialog(ui, player)):
		return
	if SideQuests.interact(self, ui, func() -> void: _role_dialog(ui, player)):return
	_role_dialog(ui, player)


func _role_dialog(ui, player: Node3D) -> void:
	match role:
		"warp":
			_warp_menu(ui, player)
		"guild":
			_registrar(ui, player)
		"board":
			ui.open_guild_board(0)
		"ranking":
			ui.open_guild_board(1)
		"master":
			_master(ui)
		"adventurer":
			_chatter(ui)
		"shop":
			ui.dialog(npc_name, "Potions, blades, armour... fine wares for brave souls!\nI also buy anything you pick up outside the walls.",
				["Buy", "Sell", "Cancel"], func(i: int) -> void:
					if i == 0:
						ui.open_shop(npc_name, SHOP_STOCK, true)
					elif i == 1:
						ui.open_shop(npc_name, SHOP_STOCK, false))
		"quest":
			_quest_dialog(ui, player)
		"helper":
			_helper(ui, player)
		"smith":
			ui.dialog(npc_name, "Clang! Need your gear made stronger?\nI refine weapons and armour with [b]Refine Stones[/b] (the higher the refine, the brighter it shines!) and I can forge new gear from monster materials.",
				["Refine", "Craft", "Wyvern Wings", "Arcane Gear", "Arcane Bows", "Celestial Staves", "Buy Stones", "Close"], func(i: int) -> void:
					if i <= 5:
						ui.open_smith(npc_name, i)
					elif i == 6:
						ui.open_shop(npc_name, SMITH_STOCK, true))
		_:
			_sage(ui, 0)


func _quest_dialog(ui, _player: Node3D) -> void:
	var s := Story.current()
	if s.is_empty():
		ui.dialog(npc_name, "Aldenvale owes you everything, Hero. The gates are always open for you.", ["Close"], Callable())
	elif Story.state() == "active":
		ui.dialog(npc_name, tr("Current task: %s") % Story.goal_text(s), ["Close"], Callable())
	else:
		ui.dialog(npc_name, "Keep your blade sharp. The town is counting on you.", ["Close"], Callable())


# ------------------------------------------------------------------ guild: registrar (Mira)
func _registrar(ui, player: Node3D) -> void:
	if not Game.guild_member:
		ui.dialog(npc_name, "Welcome to the [b]Adventurers' Guild[/b]!\nRegister with us and you'll get a Guild Card, access to the Special Quest Board and a rank from [b]F[/b] up to the legendary [b]S[/b].",
			["Register", "Heal me", "Save respawn point", "Find party members", "Close"], func(i: int) -> void:
				if i == 0:
					Guild.register()
					FX.level_up(player)
					if not Story.interact(self, ui, Callable()):
						ui.dialog(npc_name, "Here is your Guild Card - Rank [b]F[/b]. Take bounties from the board by the west wall to earn Guild Points. When you have enough, come back and I'll update your rank!", ["Close"], Callable())
				else:
					_service(ui, player, i))
		return
	var r := Guild.letter()
	var info := tr("Rank %s (%s)  ·  %d GP") % [r, tr(Guild.RANK_TITLES[Game.guild_rank]), Game.guild_points]
	ui.dialog(npc_name, tr("Welcome back! How can the Guild help you today?") + "\n[color=#f2c773]" + info + "[/color]",
		["Update Rank", "Heal me", "Save respawn point", "Find party members", "Close"], func(i: int) -> void:
			if i == 0:
				var block := Guild.rank_up_block()
				if block == "":
					Guild.rank_up()
					FX.level_up(player)
					FX.popup(player, player.global_position + Vector3(0, 3.0, 0), tr("RANK UP!  %s") % Guild.letter(), Color(1.0, 0.85, 0.3), 80, 1.6)
					var rw: Dictionary = Guild.RANK_REWARD[Game.guild_rank]
					ui.dialog(npc_name, tr("Congratulations! You are now a [b]Rank %s[/b] adventurer - %s.\nThe Guild rewards you: %s") % [Guild.letter(),
						tr(Guild.RANK_TITLES[Game.guild_rank]), Guild.reward_text(rw)], ["Close"], Callable())
				else:
					var nr := mini(Game.guild_rank + 1, Guild.RANKS.size() - 1)
					ui.dialog(npc_name, tr("Not yet. For Rank %s you need %d GP and Base Lv %d.") % [Guild.RANKS[nr], Guild.RANK_REQ[nr][0], Guild.RANK_REQ[nr][1]]
						+ "\n" + block, ["Close"], Callable())
			else:
				_service(ui, player, i))


func _service(ui, player: Node3D, i: int) -> void:
	if i == 1:
		Game.heal(9999, 9999)
		for m in Party.members():
			m.heal(99999)
		FX.popup(player, player.global_position + Vector3(0, 2.1, 0), tr("Healed!"), Color(0.5, 1.0, 0.6), 48)
		FX.ring(player, player.global_position, Color(0.5, 1.0, 0.6, 0.8), 1.6)
		ui.dialog(npc_name, "There you go - fully restored. Take care out there!", ["Close"], Callable())
	elif i == 2:
		Game.save_point = Vector3(-11.0, 0.1, 0.5)
		ui.dialog(npc_name, "Your respawn point has been saved in front of the Guild.", ["Close"], Callable())
	elif i == 3:
		ui.open_party(1)


# ------------------------------------------------------------------ guild master: advice on everything
func _master(ui) -> void:
	ui.dialog(npc_name, "Ah, an adventurer. Sit, sit. I have guided heroes for thirty years - ask me anything.",
		["What should I do next?", "Ask about...", "Guild ranks", "Close"], func(i: int) -> void: _master_choice(ui, i))


func _master_choice(ui, i: int) -> void:
	if i == 0:
		ui.dialog(npc_name, _advice_next(), ["Thanks", "More..."], func(j: int) -> void: _master_back(ui, j == 1))
	elif i == 1:
		_master_topics(ui)
	elif i == 2:
		ui.dialog(npc_name, _advice_ranks(), ["Back", "Close"], func(j: int) -> void: _master_back(ui, j == 0))


func _master_back(ui, again: bool) -> void:
	if again:
		_master(ui)


const MASTER_TOPICS := [
	"[b]Stats:[/b] STR = melee power and carry weight, AGI = attack speed and dodge, VIT = HP and defence, INT = magic power and SP, DEX = accuracy (and casting for mages), LUK = criticals.\nPut most points into your job's main stat, then VIT for safety.\n[b]Skills:[/b] press K. Learn your main attack skill first, then a buff and a passive. You need 10 skill levels for the 2nd job and 25 for transcendence.",
	"[b]Gear:[/b] you have 8 slots - weapon, shield, head, armour, garment, gloves, boots, accessory. Every piece adds stats; fill them all!\n[b]Refining:[/b] Doran refines with Refine Stones. Failure never lowers the refine level. Weapons from +7 shine brightly and hit much harder. Two-handed weapons can't be used with a shield.",
	"[b]Hunting:[/b] monsters near town are weak; the farther you go, the stronger they get. Look at the colour of a monster's name: grey/green is easy, black is even, orange/red/purple is dangerous.\n[b]Auto (Z):[/b] your hero hunts by itself. In Auto Settings choose targets, potions and skills. Click a quest to hunt for it automatically.",
]


func _master_topics(ui) -> void:
	ui.dialog(npc_name, "What would you like to know about?",
		["Stats & Skills", "Gear & Refining", "Hunting & Auto", "Back"], func(i: int) -> void: _master_topic(ui, i))


func _master_topic(ui, i: int) -> void:
	if i >= MASTER_TOPICS.size():
		_master(ui)
		return
	ui.dialog(npc_name, MASTER_TOPICS[i], ["Back", "Close"], func(j: int) -> void: _master_topics_back(ui, j == 0))


func _master_topics_back(ui, again: bool) -> void:
	if again:
		_master_topics(ui)


func _advice_next() -> String:
	var tips: PackedStringArray = []
	if Game.stat_points >= 3:
		tips.append(tr("You have [b]%d status points[/b] unspent - press S.") % Game.stat_points)
	if Game.skill_points > 0:
		tips.append(tr("You have [b]%d skill points[/b] waiting - press K.") % Game.skill_points)
	if Game.advance_block() == "":
		tips.append(tr("You are ready for a [b]job change[/b]! Open the Skill window (K)."))
	if not Game.guild_member:
		tips.append(tr("Register with Clerk Mira downstairs to join the Guild."))
	elif Guild.rank_up_block() == "":
		tips.append(tr("You've earned a [b]rank up[/b] - see Clerk Mira at the counter."))
	elif Game.board_active.is_empty():
		tips.append(tr("Take a bounty from the [b]Special Quest Board[/b] to earn Guild Points."))
	var empty := 0
	for k in Game.equip:
		if Game.equip[k] == "":
			empty += 1
	if empty >= 3:
		tips.append(tr("%d of your equipment slots are empty. Buy or craft some gear!") % empty)
	elif Game.equip.weapon != "" and Game.refine_lv(Game.equip.weapon) < 4:
		tips.append(tr("Refine your weapon at Doran's forge - up to +3 can't fail."))
	if Game.count("potion_red") < 5:
		tips.append(tr("You're low on Healing Potions. Barkeep Hugo sells them."))
	var s := Story.current()
	if not s.is_empty():
		tips.append(tr("Story: [b]%s[/b] - %s") % [tr(s.title), Story.goal_text(s)])
	var best := ""
	var best_lv := 0
	for z in load("res://scripts/monsters/spawner.gd").ZONES:
		if not z.get("boss", false) and int(z.lv) <= Game.base_level + 1 and int(z.lv) >= best_lv:
			best_lv = int(z.lv)
			best = "%s (Lv %d)" % [tr(z.name), int(z.lv)]
			var za := String(z.get("area", "town"))
			if za != "town":
				best += " - " + tr(VillageBuilder.AREA_NAMES[za])
	if best != "":
		tips.append(tr("Best hunting ground for you now: [b]%s[/b].") % best)
	if tips.is_empty():
		return tr("You're doing everything right. Keep going, hero!")
	return "\n".join(tips.slice(0, 5))


func _advice_ranks() -> String:
	var lines: PackedStringArray = [tr("Guild ranks rise from F to S. Earn GP from bounties, then ask Clerk Mira to update your rank. Each rank also gives +3% EXP from monsters.")]
	for i in Guild.RANKS.size():
		if i == 0:
			continue
		var mark := "→ " if i == Game.guild_rank + 1 else ""
		lines.append("%s[b]%s[/b] %s - %d GP, Lv %d" % [mark, Guild.RANKS[i], tr(Guild.RANK_TITLES[i]), Guild.RANK_REQ[i][0], Guild.RANK_REQ[i][1]])
	return "\n".join(lines)


# ------------------------------------------------------------------ other adventurers
const CHATTER := {
	"Kael the Knight": ["A shield on your arm is worth two potions in your bag.", "Rank B already! The golems in the south-east are tough, though."],
	"Lyra the Hunter": ["Keep your distance and the boars will never touch you.", "Falcons are the best friends an archer can have."],
	"Bram the Smith": ["I sold all my loot to Toma and bought Refine Stones. Best investment ever!", "Two-handed axes hit like a landslide."],
	"Nessa the Priest": ["Never go hunting without Heal on your hotbar.", "Blessing before every fight - it's a habit!"],
	"Orin the Wizard": ["The board has a bounty for Pale Wisps... I'd rather not.", "Storm Gust freezes whole groups. Learn it if you can."],
	"Vex the Thief": ["Psst... steal from monsters, you get twice the loot.", "Don't tell Mira, but I took two bounties at once. Kidding."],
	"Tilda the Rookie": ["I just got my Guild Card! Rank F... everyone starts somewhere, right?", "The fire is so warm. I'll go hunt slimes after this mug."],
	"Sir Roland [A]": ["The King Slime to the west - I've beaten it three times. It always comes back.", "Rank S is for legends. Prove yourself on the board."],
	"Seraphine [A]": ["The Guild Master has seen it all. Ask him anything.", "Assumptio and Kyrie together make you nearly untouchable."],
}


func _chatter(ui) -> void:
	var lines: Array = CHATTER.get(npc_name, ["Good luck out there!"])
	ui.dialog(npc_name, lines[randi() % lines.size()], ["Close"], Callable())


const SAGE_PAGES := [
	"Greetings, young knight. Let an old man share some wisdom.",
	"Press [b]S[/b] (or Alt+A) to open your [b]Status[/b] window.\nSpend status points on STR (attack), AGI (attack speed, flee), VIT (HP, defence), INT (SP), DEX (hit) and LUK (critical).",
	"Press [b]I[/b] (or Alt+E) for your [b]Inventory[/b]. Double-click potions to drink them, or equipment to wear it.",
	"Your skills live on the hotbar: [b]F1 Bash[/b] strikes your target hard, [b]F2 Whirl Slash[/b] hits everything around you. Both cost SP.",
	"Click a monster to attack it. Click the loot it drops to pick it up, then sell it to the merchant for Zeny.",
	"Press [b]O[/b] or [b]Esc[/b] for [b]Options[/b]: language, graphics, interface and controls.",
]


func _sage(ui, page: int) -> void:
	var last := page >= SAGE_PAGES.size() - 1
	ui.dialog(npc_name, SAGE_PAGES[page], ["Close"] if last else ["Next", "Close"], func(i: int) -> void:
		if not last and i == 0:
			_sage(ui, page + 1))


# ------------------------------------------------------------------ helper (support) NPC
func _helper(ui, player: Node3D) -> void:
	ui.dialog(npc_name, "Hello, adventurer! I'm here to help new heroes.\nI can bless you, send you to a hunting ground that suits your level, or give you some advice.",
		["Blessings", "Warp", "Advice", "Close"], func(i: int) -> void: _helper_choice(ui, player, i))


func _helper_choice(ui, player: Node3D, i: int) -> void:
	if i == 0:
		if Game.base_level > 40:
			ui.dialog(npc_name, "You are strong enough now - my blessings are for those under level 40.", ["Close"], Callable())
			return
		Game.add_buff("blessing", 5, 300.0)
		Game.add_buff("increase_agi", 5, 300.0)
		Game.heal(9999, 9999)
		FX.ring(player, player.global_position, Color(1.0, 0.95, 0.6, 0.9), 2.0)
		FX.popup(player, player.global_position + Vector3(0, 2.3, 0), "Blessing!", Color(1.0, 0.95, 0.6), 48)
		ui.dialog(npc_name, "Blessing and Increase AGI for 5 minutes, and your HP / SP are full. Good luck out there!", ["Close"], Callable())
	elif i == 1:
		_helper_warp(ui, player)
	elif i == 2:
		_helper_advice(ui)


func _suggested_zones() -> Array:
	var zones: Array = load("res://scripts/monsters/spawner.gd").ZONES
	var lv := Game.base_level
	var out := []
	for z in zones:
		if not z.get("boss", false) and z.lv >= lv - 3 and z.lv <= lv + 3:
			out.append(z)
	out.sort_custom(func(a, b) -> bool: return absi(a.lv - lv) < absi(b.lv - lv))
	if out.is_empty():
		out = [zones[0]]
	return out.slice(0, 3)


func _helper_warp(ui, player: Node3D) -> void:
	var zs := _suggested_zones()
	var names := []
	for z in zs:
		names.append("%s (Lv %d)" % [tr(z.name), z.lv])
	names.append("Back")
	ui.dialog(npc_name, "Where would you like to go? These hunting grounds suit your level.", names, func(i: int) -> void:
		if i >= zs.size():
			_helper(ui, player)
			return
		var z: Dictionary = zs[i]
		var c := Vector3(z.pos.x, 0, z.pos.y)
		var dest := c - c.normalized() * (float(z.r) + 3.0)
		FX.ring(player, player.global_position, Color(0.6, 0.85, 1.0, 0.9), 1.6)
		player.global_position = dest + Vector3(0, 0.1, 0)
		player.velocity = Vector3.ZERO
		player.go_to(c, false)
		FX.ring(player, dest, Color(0.6, 0.85, 1.0, 0.9), 1.6)
		Game.log_msg(tr("Warped to %s.") % tr(z.name), Color(0.6, 0.85, 1.0)))


func _helper_advice(ui) -> void:
	var zs := _suggested_zones()
	var z: Dictionary = zs[0]
	var text := tr("At level %d, try hunting [b]%s[/b] (Lv %d).") % [Game.base_level, tr(z.name), z.lv]
	text += "\n" + tr("Monsters get stronger the further you go from town. Press [b]M[/b] for the world map, [b]K[/b] for skills and [b]Z[/b] for auto-hunt.")
	if Game.skill_points > 0:
		text += "\n" + tr("You have %d unused skill points!") % Game.skill_points
	if Game.stat_points > 0:
		text += "\n" + tr("You have %d unused status points (press S).") % Game.stat_points
	ui.dialog(npc_name, text, ["Close"], Callable())


# ------------------------------------------------------------------ warp crystal (fast travel)
## Destination per map: [area, arrival position, yaw, zeny]. Regions unlock once visited.
const WARP_DEST := [
	["town", Vector3(9.5, 0, 13.6), 0.0, 0],
	["verdant", Vector3(1084.5, 0, 10.6), 0.0, 400],
	["desert", Vector3(1408.5, 0, -81.4), 0.0, 600],
	["frost", Vector3(1716.5, 0, 10.6), 0.0, 800],
	["ember", Vector3(2116.5, 0, 40.6), 0.0, 1000],
]


func _crystal_model() -> void:
	var gem := MeshInstance3D.new()
	gem.name = "Gem"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.55, 0.55, 0.55)
	gem.mesh = bm
	gem.rotation_degrees = Vector3(45, 0, 35)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.8, 1.0, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = Color(0.35, 0.7, 1.0)
	m.emission_energy_multiplier = 1.4
	m.roughness = 0.15
	gem.material_override = m
	gem.position.y = 1.55
	model.add_child(gem)
	var base := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.7
	cm.height = 0.5
	cm.radial_segments = 8
	base.mesh = cm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.55, 0.56, 0.6)
	base.material_override = bmat
	base.position.y = 0.25
	model.add_child(base)
	var p := CPUParticles3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3.ONE * 0.05
	var ppm := StandardMaterial3D.new()
	ppm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ppm.albedo_color = Color(0.6, 0.9, 1.0)
	pm.material = ppm
	p.mesh = pm
	p.amount = 16
	p.lifetime = 1.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.6
	p.gravity = Vector3(0, 0.4, 0)
	p.position.y = 1.4
	model.add_child(p)


func _warp_menu(ui, player: Node3D) -> void:
	var opts := []
	var dests := []
	var here := VillageBuilder.area_at(global_position)
	for d in WARP_DEST:
		if d[0] == here:
			continue
		if d[0] != "town" and not (d[0] in Game.visited_areas):
			continue
		dests.append(d)
		var nm := tr(VillageBuilder.AREA_NAMES[d[0]])
		opts.append(nm if int(d[3]) == 0 else tr("%s  (%d Zeny)") % [nm, int(d[3])])
	opts.append("Close")
	var txt := "The crystal hums softly. Touch it to travel to any place you have already visited."
	if dests.size() <= 1:
		txt += "\n" + tr("Walk through the stone gates at the ends of the roads to discover new regions.")
	ui.dialog(npc_name, txt, opts, func(i: int) -> void:
		if i < 0 or i >= dests.size():
			return
		var d: Array = dests[i]
		if Game.zeny < int(d[3]):
			Game.log_msg(tr("Not enough Zeny."), Color(1.0, 0.5, 0.4))
			return
		Game.zeny -= int(d[3])
		Game.changed.emit()
		if player.has_method("warp"):
			player.warp({"to": d[0], "dest": d[1], "yaw": d[2]}))
