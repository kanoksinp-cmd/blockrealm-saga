extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  failures += 1
  push_error(message)
func _initialize() -> void:
 await process_frame
 var world := Node3D.new()
 root.add_child(world)
 current_scene = world
 var camera := Camera3D.new()
 world.add_child(camera)
 camera.position = Vector3(0, 0, 7)
 var popup = load("res://scripts/combat/damage_popup.gd")
 for critical in [false, true]:
  var p = popup.new()
  p.setup("1234", Color.WHITE, critical, false)
  world.add_child(p)
  check(p._font_size >= (46 if critical else 38), "damage font enlarged relative to character")
  p.set_process(false)
  var positions: Array[float] = []
  var scales: Array[float] = []
  for time in [0.02, 0.38, 0.65, 0.9, 1.1]:
   p._age = time
   p._process(0.0)
   positions.append(p.position.y)
   scales.append(p.scale.x)
  check(positions[1] < positions[0], "number rises first")
  check(positions[2] > positions[1] and positions[3] > positions[2] and positions[4] > positions[3], "number falls after apex")
  check(scales[1] > scales[2] and scales[2] > scales[3] and scales[3] > scales[4], "number keeps shrinking")
  check(p.modulate.a < 0.2, "number fades before expiry")
  p._age = 0.0
  for i in 30: p._process(1.0 / 30.0)
  var at30: Vector2 = p.position
  p._age = 0.0
  for i in 60: p._process(1.0 / 60.0)
  check(p.position.distance_to(at30) < 0.01, "animation consistent at 30 and 60 FPS")
  p.queue_free()
 var target := Node3D.new()
 world.add_child(target)
 root.get_node("Settings").set_value("damage_numbers", true)
 var fx = load("res://scripts/combat/fx.gd")
 for i in 24: fx.popup(target, Vector3.ZERO, "128", Color.WHITE)
 await process_frame
 var layer = world.get_node("CombatDamagePopups")
 check(layer.get_child_count() <= 8, "rapid hits stay bounded per target")
 await create_timer(popup.DURATION + 0.2).timeout
 check(layer.get_child_count() == 0, "all numbers free after expiry")
 print("DAMAGE ARC ", "PASS" if failures == 0 else "FAIL")
 world.queue_free()
 await process_frame
 quit(0 if failures == 0 else 1)
