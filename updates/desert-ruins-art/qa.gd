extends SceneTree
func _initialize() -> void: call_deferred("check")
func check() -> void:
	await process_frame
	var ZonesType = load("res://scripts/world/zones.gd")
	var WorldType = load("res://scripts/voxel/block_world.gd")
	var effects = load("res://scripts/combat/element_fx.gd")
	var settings = root.get_node("Settings")
	for mobile in [false, true]:
		settings._mobile = mobile
		assert(effects.particle_count(1000) <= (18 if mobile else 40))
		assert(effects.particle_count(0) == 1)
		if mobile:
			assert(settings.g("shadows") == 0)
			assert(settings.g("msaa") == 0)
			assert(settings.g("xray") == settings.data.xray)
	settings._mobile = false
	for area in ["desert", "verdant"]:
		var world = WorldType.new()
		var zone = ZonesType.new(area, world)
		zone.build()
		var plots: Array = world.get_meta("ruin_plots", [])
		assert(plots.size() >= 2, "Not enough ruins in " + area)
		for plot: Rect2 in plots:
			var center := plot.get_center()
			# A level central passage connects both sides of every courtyard.
			for x in range(int(center.x) - 1, int(center.x) + 2):
				for y in range(int(plot.position.y), int(plot.end.y)):
					assert(world.getb(x, 0, y) == 0, "Court passage obstructed")
			for monster in load("res://scripts/monsters/spawner.gd").ZONES:
				if String(monster.get("area", "town")) != area: continue
				for spot in monster.get("spots", [[monster.pos, monster.r]]):
					var point: Vector2 = spot[0]
					assert(point.distance_to(point.clamp(plot.position, plot.end)) >= float(spot[1]) + 4)
		for warp in load("res://scripts/world/village_builder.gd").WARPS:
			if warp.area == area:
				assert(world.getb(int(warp.pos.x),0,int(warp.pos.y)) == 0, "Gate obstructed")
		print("PASS_RUINS ", area, " courts=", plots.size(), " clear paths, spawns and gates")
	print("PASS_BUDGET particle caps and mobile shadow/MSAA limits preserved")
	quit()
