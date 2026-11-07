extends SceneTree
func _initialize() -> void: call_deferred("check")
func check() -> void:
	await process_frame
	var ZonesType = load("res://scripts/world/zones.gd")
	var WorldType = load("res://scripts/voxel/block_world.gd")
	var builder = load("res://scripts/world/village_builder.gd").new()
	var tested := 0
	for area in ZonesType.CENTER:
		var world = WorldType.new()
		var zone = ZonesType.new(area, world)
		zone.build()
		var before_blocks = world.blocks.duplicate()
		var before_lights = zone.lights.duplicate()
		var before_npcs = zone.npcs.duplicate(true)
		builder._outpost(area, world, zone)
		if ZonesType.is_dungeon(area):
			assert(world.blocks == before_blocks, "Dungeon service geometry added: " + area)
			assert(zone.lights == before_lights)
			assert(zone.npcs == before_npcs)
			for npc in zone.npcs: assert(npc[1] not in ["shop", "smith"])
			assert(not builder._outpost_fits(area, world, zone, int(zone.c.x), int(zone.c.y)))
			print("PASS dungeon ", area, ": no shops, smiths, props or lights")
		else:
			assert(zone.npcs.size() == before_npcs.size() + 2, "No safe field services: " + area)
			for npc in zone.npcs:
				if npc[1] in ["shop", "smith"]:
					var position: Vector3 = npc[2]
					for monster in load("res://scripts/monsters/spawner.gd").ZONES:
						if String(monster.get("area", "town")) != area: continue
						for spot in monster.get("spots", [[monster.pos, monster.r]]):
							assert(Vector2(position.x, position.z).distance_to(spot[0]) > float(spot[1]) + float(monster.r) + 16)
			print("PASS field ", area, ": services outside spawn and leash radii")
		tested += 1
		await process_frame
	assert(tested == ZonesType.CENTER.size())
	builder.free()
	print("PASS_ALL_AREAS ", tested)
	quit()
