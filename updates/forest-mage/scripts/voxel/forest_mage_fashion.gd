extends RefCounted
## Original Forest Mage Blender meshes, attached to the existing animated rig.
static var scenes: Dictionary = {}
static func model(part: String) -> Node3D:
	if not scenes.has(part):scenes[part]=load("res://assets/models/forest_mage/%s.glb" % part)
	var scene: PackedScene = scenes[part]
	return scene.instantiate() as Node3D if scene else null
static func apply(root: Node3D, rig: Dictionary, with_weapon: bool) -> void:
	# Keep all rig pivots and animations; replace visual meshes only.
	for mesh in root.find_children("*", "MeshInstance3D", true, false):mesh.visible=false
	for part in ["head","torso","arm_l","arm_r","leg_l","leg_r"]:
		var n := model(part)
		if n:rig[part].add_child(n)
	if with_weapon:
		if rig.has("weapon"):
			var old: Node3D=rig.weapon
			old.get_parent().remove_child(old);old.free()
		var holder:=Node3D.new();holder.name="ForestStaff"
		rig.arm_r.add_child(holder);holder.position=Vector3(0,-9.5,2.2)*Avatar.PX
		var staff:=model("staff")
		if staff:holder.add_child(staff)
		rig.weapon=holder;rig.fashion_weapon="staff"
	var pets:=model("pets")
	if pets:
		pets.name="ForestSpirits";root.add_child(pets)
		for ap in pets.find_children("*","AnimationPlayer",true,false):
			var player:=ap as AnimationPlayer
			for name in player.get_animation_list():
				if name=="RESET":continue
				player.get_animation(name).loop_mode=Animation.LOOP_LINEAR
				player.play(name);break
