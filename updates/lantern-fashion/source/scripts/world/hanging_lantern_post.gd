extends RefCounted
const LIGHT_POSITION:=Vector3(.725,2.15,0)
static func make() -> StaticBody3D:
	var post:=StaticBody3D.new();post.name="StreetLantern";post.set_meta("street_lantern",true)
	var visual:=TownAssets.instance("hanging_lantern_post")
	if visual:post.add_child(visual)
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.48,.50,.48)
	collision.shape=shape;collision.position.y=.25;post.add_child(collision)
	return post
