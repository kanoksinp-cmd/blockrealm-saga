extends RefCounted

static var materials: = { }
static func aura_material(level: int) -> StandardMaterial3D:
	level = clampi(level, 1, 10)
	if materials.has(level): return materials[level]
	var material: = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	var high: = maxf(0.0, float(level - 5))
	material.albedo_color = Color(1.0, 0.45, 0.03)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.38, 0.09)
	material.emission_energy_multiplier = 0.7 + level * 0.18 + high * 0.5
	materials[level] = material
	return material

static func slot_for(mesh: Node, root: Node) -> String:
	var node: = mesh
	while node != null and node != root:
		var key: = String(node.name).to_lower()
		if key == "weapon": return "weapon"
		if key == "shield": return "shield"
		if key == "wings": return "garment"
		if "_armor_" in key: return "armor"
		node = node.get_parent()
	var key: = String(mesh.name).to_lower()
	if key.begins_with("g_glove"): return "gloves"
	if key.begins_with("g_boot") or key.begins_with("g_toe"): return "boots"
	if key.begins_with("g_cape") or key.begins_with("g_scarf") or key.begins_with("g_clasp"): return "garment"
	if key.begins_with("g_"): return "head"
	if key in ["body", "hem", "pauldron"]: return "armor"
	return ""

static func mesh_scale(mesh: Node3D, root: Node3D) -> Vector3:
	var transform: = Transform3D.IDENTITY
	var node: Node = mesh
	while node != root and node is Node3D:
		transform = node.transform * transform
		node = node.get_parent()
	return transform.basis.get_scale().abs().max(Vector3.ONE * 0.001)

static func apply(root: Node3D, rig: Dictionary, appearance: Dictionary) -> void:
	var levels: Dictionary = appearance.get("refine_slots", { "weapon": appearance.get("glow_w", 0), "armor": appearance.get("glow_a", 0) })
	var targets: = { }
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		var slot: = slot_for(mesh, root)
		var level: = clampi(int(levels.get(slot, 0)), 0, 10)
		if level <= 0: continue

		mesh.material_overlay = Avatar.glow_overlay(Color(1, 0.38, 0.09), level)
		if not targets.has(slot): targets[slot] = []
		if not String(mesh.name).begins_with("g_toe"):
			targets[slot].append(mesh)
	for slot in levels:
		var level: = clampi(int(levels[slot]), 0, 10)
		if level <= 0: continue
		var candidates: Array = targets.get(slot, [])
		candidates.sort_custom(func (a, b): return (a.get_aabb().size * mesh_scale(a, root)).length_squared() > (b.get_aabb().size * mesh_scale(b, root)).length_squared())
		var limit: = 2 if slot in ["boots", "gloves"] else 1
		for index in range(mini(limit, candidates.size())):
			var mesh: MeshInstance3D = candidates[index]
			var scale: = mesh_scale(mesh, root)
			var anchor: = Node3D.new()
			anchor.name = "RefineMount_" + slot
			mesh.add_child(anchor)
			anchor.position = mesh.get_aabb().get_center()
			anchor.scale = Vector3.ONE / scale
			var extent: = (mesh.get_aabb().size * scale * 0.5).clamp(Vector3.ONE * 0.03, Vector3.ONE * 0.35)
			add_effect(anchor, slot, level, extent)
		if candidates.is_empty() and slot == "accessory":

			var anchor: = Node3D.new()
			anchor.name = "RefineMount_accessory"
			rig.arm_l.add_child(anchor)
			anchor.position = Vector3(0, -0.43, 0)
			add_effect(anchor, slot, level, Vector3.ONE * 0.05)

	# heavy refines light up the whole body (+7) and then crackle with lightning (+9)
	var top: = 0
	for slot in levels:
		top = maxi(top, clampi(int(levels[slot]), 0, 10))
	preload("res://scripts/voxel/refine_aura.gd").attach(root, top)

static func add_effect(anchor: Node3D, slot: String, level: int, extent: Vector3) -> void:
		var light: = OmniLight3D.new()
		light.name = "RefineLight_" + slot
		light.set_meta("refine_slot", slot)
		light.light_color = Color(1, 0.38, 0.09)
		light.light_energy = 0.25 + level * 0.08 + maxf(0, level - 5) * 0.35
		light.omni_range = 0.35 + extent.length() + level * 0.025
		light.shadow_enabled = false
		anchor.add_child(light)
		var aura: = CPUParticles3D.new()
		aura.name = "RefineAura_" + slot
		aura.set_meta("refine_slot", slot)
		aura.set_meta("refine_level", level)
		var high: = maxi(0, level - 5)
		aura.amount = 2 + level * 2 + (12 + high * 4 if high > 0 else 0)
		aura.lifetime = 0.45
		aura.preprocess = 0.45
		aura.local_coords = true
		aura.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		aura.emission_box_extents = extent
		aura.direction = Vector3.UP
		aura.spread = 20
		aura.gravity = Vector3.ZERO
		aura.initial_velocity_min = 0.08
		aura.initial_velocity_max = 0.2 + level * 0.01
		aura.scale_amount_min = 0.5 + high * 0.07
		aura.scale_amount_max = 1.0 + level * 0.06
		var fade: = Gradient.new()
		fade.set_color(0, Color(1, 1, 1, 0))
		fade.set_color(1, Color(1, 1, 1, 0))
		fade.add_point(0.2, Color.WHITE)
		aura.color_ramp = fade
		var mote: = BoxMesh.new()
		mote.size = Vector3(0.025, 0.055, 0.025) * (1.0 + high * 0.12)
		aura.mesh = mote
		aura.material_override = aura_material(level)
		aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		aura.position = Vector3.ZERO
		anchor.add_child(aura)
