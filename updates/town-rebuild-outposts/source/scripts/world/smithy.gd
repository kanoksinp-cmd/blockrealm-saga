extends RefCounted
## Reference-inspired orange-roof forge, and a walk-in cutaway workshop.
const WOOD := Color(0.28,0.16,0.085)
const STONE := Color(0.3,0.29,0.25)
const IRON := Color(0.16,0.18,0.2)
const HOT := Color(1,0.23,0.025)

static func build(vb) -> void:
	var w: BlockWorld = vb.w
	# Medieval tavern-style forge: stone ground floor, jettied white plaster upper floor
	# with a timber frame, steep grey stone roof with a wooden ridge, red brick chimney.
	# Footprint x 14..21, z 0..8; the doorway stays at x 17..18 on the z = 8 side.
	for x in range(13,23):
		for z in range(-1,11):
			for y in 18:
				w.setb(x,y,z,0)
	for x in range(14,22):
		for z in range(0,9):
			w.decal(x,z,41)
			if not (x in [14,21] or z in [0,8]):
				continue
			var corner := x in [14,21] and z in [0,8]
			for y in 4:
				var id := 5 if (x+y+z) % 4 else 4          # stone brick with cobble
				if corner:
					id = 7
				w.setb(x,y,z,id)
	for x in [17,18]:
		for y in 3:
			w.setb(x,y,8,0)
	w.setb(17,3,8,34)
	w.setb(18,3,8,34)
	# ground floor windows
	for x in [15,20]:
		w.setb(x,2,8,18)
	for z in [3,5]:
		w.setb(14,2,z,18)
		w.setb(21,2,z,18)
	# jetty beam: the upper floor sticks out one block at the front and sides
	for x in range(13,23):
		for z in range(-1,10):
			if x in [13,22] or z in [-1,9]:
				w.setb(x,4,z,34)
	# upper floor: plaster between log posts, cross beams and leaded windows
	for x in range(13,23):
		for z in range(-1,10):
			if not (x in [13,22] or z in [-1,9]):
				continue
			var post := (x in [13,22] and (z+1) % 3 == 0) or (z in [-1,9] and (x-13) % 3 == 0)
			for y in range(5,8):
				var id := 7 if post else (27 if y == 7 else 14)
				w.setb(x,y,z,id)
	for x in [15,16,19,20]:
		w.setb(x,6,9,18)
	for z in [2,3,6]:
		w.setb(13,6,z,18)
		w.setb(22,6,z,18)
	# steep roof of grey stone tiles, ridge along X, dark-wood verges, log ridge
	var k := 0
	while true:
		var z0 := -2 + k
		var z1 := 10 - k
		if z0 > z1:
			break
		var y := 8 + k
		for x in range(12,24):
			var verge := x in [12,23]
			var tile := 34 if verge else (4 if (x*3 + k) % 5 == 0 else 5)
			w.setb(x,y,z0,tile)
			w.setb(x,y,z1,tile)
			if z1 - z0 <= 1:
				for zz in range(z0,z1+1):
					w.setb(x,y,zz,34 if verge else 7)
		for x in [13,22]:
			for zz in range(z0+1,z1):
				w.setb(x,y,zz,14 if (zz+y) % 3 else 27)
		k += 1
	# red brick chimney with a stone cap (smoke comes out at the top)
	w.fill(20,3,1,21,13,2,15)
	w.fill(20,14,1,21,14,2,4)
	for x in range(14,22):
		w.decal(x,9,4)
		w.decal(x,10,4)
	# barrels and crates by the door, like a tavern front
	w.setb(14,0,10,36)
	w.setb(15,0,10,36)
	w.setb(14,1,10,36)
	w.setb(21,0,10,6)
	# warm light over the doorway
	vb.lamp_points.append(Vector3(17.9,3.4,9.6))
	# Interior room: tiled floor, tall rear walls, cut-away front for the camera.
	for x in range(130,191):
		for z in range(63,113):
			w.decal(x,z,40)
	for x in range(148,172):
		for z in range(70,89):
			w.decal(x,z,41)
			if x in [148,171] or z in [70,88]:
				var height := 1 if z == 88 else 5
				for y in height:
					if z == 88 and x in [159,160,161]:
						continue
					w.setb(x,y,z,5 if y % 3 else 4)
	# Solid equipment footprints are shared by click pathfinding and physics.
	for rect in [Rect2i(150,71,3,3),Rect2i(154,71,3,3),Rect2i(163,71,6,3),Rect2i(152,78,3,1),Rect2i(158,78,3,1),Rect2i(168,80,2,2),Rect2i(149,81,3,2),Rect2i(155,83,2,2)]:
		for x in range(rect.position.x,rect.end.x):
			for z in range(rect.position.y,rect.end.y):
				w.setb(x,0,z,3)
				w.hidden_render[Vector3i(x,0,z)] = true

static func box(root: Node3D, p: Vector3, size: Vector3, color: Color, emission := 0.0) -> MeshInstance3D:
	return LP.part(root,LP.box(size),color,p,Vector3.ZERO,Vector3.ONE,0.85,0.0,emission)

static func props(vb) -> void:
	var root := Node3D.new()
	root.name = "BlacksmithWorkshop"
	vb.add_child(root)
	# A continuous tiled finish keeps the visual floor under solid equipment.
	var floor_mesher := BlockWorld.new()
	var floor_data := floor_mesher._new_chunk()
	for x in range(149,171):
		for z in range(71,88):
			floor_mesher._emit(floor_data,Vector3(x,-0.985,z),BlockWorld.FACES[4],PixelTex.STONE_TILE,false)
	root.add_child(floor_mesher._mesh_node(floor_data.v,floor_data.n,floor_data.uv,floor_data.uv2,floor_data.c,PixelTex.solid_material(),"WorkshopFloor"))
	# Exterior timber braces, shop sign and stacked firewood.
	for x in [15.5,19.5]:
		var brace := box(root,Vector3(x,4.8,8.55),Vector3(0.14,2.2,0.12),WOOD)
		brace.rotation.z = -0.55 if x < 18 else 0.55
	box(root,Vector3(19.8,3.0,9.0),Vector3(1.4,0.85,0.12),WOOD)
	var sign := Label3D.new()
	sign.text = "⚒ " + TranslationServer.translate("Blacksmith")
	sign.font = load("res://assets/fonts/ui_font_bold.tres")
	sign.font_size = 38
	sign.pixel_size = 0.006
	sign.position = Vector3(19.8,3.0,9.08)
	root.add_child(sign)
	for i in 8:
		LP.part(root,LP.cyl(0.12,0.12,0.7,8),WOOD,Vector3(21.5+(i%2)*0.3,0.15+(i/2)*0.25,9.7),Vector3(90,0,0))
	_smoke(root,Vector3(20.8,14,1.8),0.7)
	# Rough stone furnaces like the reference, with iron doors and bright mouths.
	for at in [Vector3(151.5,0,72.5),Vector3(155.5,0,72.5)]:
		for row in 7:
			var r := 1.15-float(row)*0.085
			for segment in 10:
				var angle := (segment+0.5*(row%2))*TAU/10
				if row < 3 and sin(angle) > 0.65:
					continue
				var stone := box(root,at+Vector3(cos(angle)*r,0.22+row*0.4,sin(angle)*r),Vector3(0.65,0.37,0.38),STONE.lightened(float((segment+row)%3)*0.04))
				stone.rotation.y = -angle + PI/2
		LP.part(root,LP.cyl(0.35,0.47,0.7,8),IRON,at+Vector3(0,3.1,0))
		box(root,at+Vector3(0,0.65,0.5),Vector3(0.7,0.65,0.15),HOT,3)
		_fire(root,at+Vector3(0,0.5,0.8))
		_smoke(root,at+Vector3(0,3.6,0),0.25)
	# Twin open coal hearths, stone hoods and incandescent coals.
	for x in [164.5,167.3]:
		box(root,Vector3(x,0.55,72.5),Vector3(2.5,1.1,2.3),STONE)
		box(root,Vector3(x,1.13,72.5),Vector3(2.05,0.12,1.9),Color(0.07,0.04,0.025))
		for i in 30:
			var ember := Vector3(x-0.9+(i%6)*0.34,1.24+sin(i*2.0)*0.045,71.8+(i/6)*0.32)
			box(root,ember,Vector3(0.2,0.13,0.2),HOT if i%3 else Color(0.2,0.07,0.03),2.5 if i%3 else 0.0)
		box(root,Vector3(x,3.5,72),Vector3(2.6,0.7,1.9),STONE)
		box(root,Vector3(x,4.3,71.7),Vector3(1.3,1.0,1.1),STONE)
		_fire(root,Vector3(x,1.25,72.5))
	# Two anvils with flared feet, horns and hot billets.
	for at in [Vector3(153.5,0,78.5),Vector3(159.5,0,78.5)]:
		_anvil(root,at)
		box(root,at+Vector3(0,1.04,0),Vector3(0.48,0.1,0.19),HOT,2)
	# Quench tub with water and iron hoops.
	LP.part(root,LP.cyl(0.95,0.7,0.85,14),WOOD,Vector3(156,0.43,84))
	LP.part(root,LP.cyl(0.84,0.84,0.035,24),Color(0.12,0.24,0.27),Vector3(156,0.86,84))
	for y in [0.15,0.7]:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.83 if y>0.5 else 0.72
		ring.outer_radius = ring.inner_radius+0.07
		LP.part(root,ring,IRON,Vector3(156,y,84))
	# Stock shelves and workbench.
	for y in [0.3,1.1,1.9]:
		box(root,Vector3(169,y,81),Vector3(2,0.12,1.0),WOOD)
		for i in 5:
			box(root,Vector3(168.3+i*0.32,y+0.15,81),Vector3(0.27,0.16,0.55),Color(0.26,0.29,0.32))
	for x in [168.1,169.9]:
		box(root,Vector3(x,1.0,81),Vector3(0.12,2.1,0.12),WOOD)
	box(root,Vector3(150.5,1.0,82),Vector3(2.7,0.16,1.1),WOOD)
	for x in [149.5,151.5]:
		box(root,Vector3(x,0.5,82),Vector3(0.15,1.0,0.8),WOOD)
	for i in 5:
		box(root,Vector3(149.7+i*0.35,1.13,82),Vector3(0.15,0.1,0.5),IRON)
	# Hand-cranked grinding wheel and a stool beside the tool bench.
	for x in [149.5,150.5]:
		box(root,Vector3(x,0.4,85.5),Vector3(0.15,0.8,0.7),WOOD)
	LP.part(root,LP.cyl(0.5,0.5,0.28,20),Color(0.44,0.43,0.39),Vector3(150,0.8,85.5),Vector3(0,0,90))
	box(root,Vector3(150.65,0.8,85.5),Vector3(0.25,0.07,0.07),IRON)
	box(root,Vector3(150.75,0.66,85.5),Vector3(0.07,0.3,0.07),IRON)
	LP.part(root,LP.cyl(0.28,0.28,0.1,12),WOOD,Vector3(151.5,0.55,85.5))
	for dx in [-0.17,0.17]:
		box(root,Vector3(151.5+dx,0.25,85.5),Vector3(0.07,0.5,0.25),WOOD)
	# Bellows: wood plates compress the leather body as the worker pumps.
	box(root,Vector3(162,0.7,74.5),Vector3(1.2,0.12,0.8),WOOD)
	var bellows := LP.pivot(root,"Bellows",Vector3(162,0.8,74.5))
	box(bellows,Vector3(0,0.2,0),Vector3(1.05,0.4,0.7),Color(0.33,0.14,0.07))
	box(bellows,Vector3(0,0.43,0),Vector3(1.2,0.08,0.8),WOOD)
	var tube := box(root,Vector3(162.7,0.9,73.8),Vector3(0.13,0.13,1.8),IRON)
	tube.rotation.y = -0.6
	# Working apprentices, independent cycles and clear unobstructed routes.
	# Pickup and receiving trays are at the ends of the carrier's route.
	for x in [168.0,161.0]:
		box(root,Vector3(x,0.85,83),Vector3(0.8,0.12,0.7),WOOD)
		box(root,Vector3(x,0.4,83),Vector3(0.18,0.8,0.5),WOOD)
		for i in 3:
			box(root,Vector3(x-0.25+i*0.25,0.98,83),Vector3(0.2,0.13,0.45),IRON.lightened(0.1))
	# The worker script is runtime-only; inside the editor the village builder
	# (a @tool script) would only get a placeholder that rejects `job`.
	for spec in [] if Engine.is_editor_hint() else [["hammer",Vector3(153.5,0,77.6),0.0],["bellows",Vector3(162,0,75.5),PI],["carry",Vector3(167,0,83),0.0]]:
		var worker := Node3D.new()
		worker.set_script(preload("res://scripts/world/smith_worker.gd"))
		worker.job = spec[0]
		worker.position = spec[1]
		worker.rotation.y = spec[2]
		worker.bellows = bellows
		root.add_child(worker)
	# Tools along the wall and weapon racks.
	GuildHall.weapon_rack(root,Vector3(169,0,76.5),PI/2)
	for i in 4:
		var handle := box(root,Vector3(158+i*0.55,2.1,70.55),Vector3(0.055,0.7,0.055),WOOD)
		handle.rotation.z = 0.2
		box(root,Vector3(158+i*0.55,2.4,70.55),Vector3(0.32,0.14,0.13),IRON)

static func _anvil(root: Node3D, at: Vector3) -> void:
	LP.part(root,LP.cyl(0.45,0.55,0.4,8),WOOD,at+Vector3(0,0.2,0))
	box(root,at+Vector3(0,0.48,0),Vector3(1.0,0.16,0.55),IRON)
	box(root,at+Vector3(0,0.68,0),Vector3(0.48,0.32,0.35),IRON)
	box(root,at+Vector3(0,0.91,0),Vector3(1.1,0.18,0.5),IRON.lightened(0.08))
	LP.part(root,LP.cone(0.22,0.7,6),IRON.lightened(0.08),at+Vector3(0.8,0.9,0),Vector3(0,0,-90))

static func _fire(root: Node3D, at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = at+Vector3(0,0.5,0)
	light.light_color = Color(1,0.38,0.09)
	light.light_energy = 2.1
	light.omni_range = 7
	root.add_child(light)
	var particles := CPUParticles3D.new()
	particles.mesh = LP.box(Vector3(0.04,0.08,0.04))
	particles.material_override = LP.mat(Color(1,0.45,0.03),0.9,0,3)
	particles.amount = 22
	particles.lifetime = 1.1
	particles.position = at
	particles.direction = Vector3.UP
	particles.gravity = Vector3(0,0.2,0)
	particles.spread = 20
	particles.initial_velocity_min = 0.35
	particles.initial_velocity_max = 1.1
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(0.4,0.02,0.3)
	root.add_child(particles)

static func _smoke(root: Node3D, at: Vector3, radius: float) -> void:
	var smoke := CPUParticles3D.new()
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2,0.18,0.16,0.15)
	mat.vertex_color_use_as_albedo = true
	smoke.mesh = LP.sphere(radius,8,4)
	smoke.material_override = mat
	smoke.position = at
	smoke.amount = 10
	smoke.lifetime = 3
	smoke.direction = Vector3(0.2,1,0)
	smoke.gravity = Vector3(0.07,0.08,0)
	smoke.initial_velocity_min = 0.3
	smoke.initial_velocity_max = 0.6
	smoke.scale_amount_min = 0.5
	smoke.scale_amount_max = 1.6
	root.add_child(smoke)
