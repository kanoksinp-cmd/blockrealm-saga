extends SkeletonModifier3D
## Runs after the wing AnimationPlayer: swings both wing roots back from the body
## into a natural V, lifts them a little, and adds a slow breathing sway, so the
## wings no longer lie flat against the character's back.

@export var sweep_deg := 28.0   # wing tips swept back, away from the back
@export var lift_deg := 10.0    # wing roots raised a little
@export var sway_deg := 4.0     # idle breathing
var _l := -1
var _r := -1
var _t := 0.0


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if _l < 0:
		_l = sk.find_bone("Shoulder.L")
		_r = sk.find_bone("Shoulder.R")
		_t = randf() * TAU
	_t += get_process_delta_time() if is_inside_tree() else 0.016
	var sway := sin(_t * 1.6) * sway_deg
	for side in [[_l, 1.0], [_r, -1.0]]:
		var idx: int = side[0]
		if idx < 0:
			continue
		var s: float = side[1]
		var pose := sk.get_bone_pose(idx)
		var extra := Basis(Vector3.UP, deg_to_rad((sweep_deg + sway) * s)) * Basis(Vector3.FORWARD, deg_to_rad(lift_deg * s))
		pose.basis = extra * pose.basis
		sk.set_bone_pose(idx, pose)
