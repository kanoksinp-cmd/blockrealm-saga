extends SceneTree
var failures:=0
func check(ok:bool,message:String) -> void:
 if not ok:failures+=1;push_error(message)
func frames(n:=6) -> void:
 for i in n:await process_frame
func _initialize() -> void:
 await process_frame
 root.min_size=Vector2i.ZERO;root.size=Vector2i(390,844) if OS.get_environment("BR_MOBILE")=="1" else Vector2i(1280,720)
 var game=root.get_node("Game")
 game.new_character("NovaMoon32",load("res://scripts/voxel/avatar.gd").default_appearance())
 game.base_level=64;game.job="Rune Knight";game.job_level=35
 game.stats={"STR":59.0,"AGI":53.0,"VIT":37.0,"INT":6.0,"DEX":5.0,"LUK":13.0};game.stat_points=20
 var scene=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
 await frames(15)
 var ui=game.ui
 check(ui._status_vp.render_target_update_mode==SubViewport.UPDATE_DISABLED,"closed card preview disabled")
 ui._status.panel.show();ui._refresh_status();await frames(8)
 if ui._mobile:ui._fit_windows();await frames(6)
 check(ui._status_rows.STR[0].text=="59","whole stats do not show .0")
 check(ui._status_info.get_child_count()==8,"eight combat metric groups")
 check(ui._status_info.columns==2,"combat values stay paired in two columns")
 var model=ui._status_vp.get_node("Holder")
 var angle=model.rotation.y
 ui._process(0.2)
 check(absf(model.rotation.y-angle)>0.01,"character rotates while card visible")
 check(ui._status_vp.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"visible spinning preview live")
 ui._status_rotate.pressed.emit();ui._process(0.2)
 angle=model.rotation.y;ui._process(0.2)
 check(is_equal_approx(angle,model.rotation.y),"pause stops rotation")
 ui._status_rotate.pressed.emit();ui._process(0.2)
 check(not is_equal_approx(angle,model.rotation.y),"resume starts rotation")
 var before=float(game.stats.STR);var points=game.stat_points;var cost=game.stat_cost("STR")
 ui._status_rows.STR[1].pressed.emit()
 check(float(game.stats.STR)==before+1 and game.stat_points==points-cost,"stat button preserves cost and increment")
 game.stat_points=0;ui._refresh_status()
 check(ui._status_rows.values().all(func(row):return row[1].disabled),"all plus buttons disabled without points")
 var rect=ui._status.panel.get_global_rect();var vp=root.get_visible_rect().size
 check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=vp.x+2 and rect.end.y<=vp.y+2,"card fits viewport")
 for row in ui._status_info.get_children():
  check(row.get_child_count()==3,"icon label value remain grouped")
 ui._status.panel.hide()
 check(ui._status_vp.render_target_update_mode==SubViewport.UPDATE_DISABLED,"closing stops preview rendering")
 print("CHARACTER CARD ","PASS" if failures==0 else "FAIL "+str(failures))
 scene.queue_free();await frames();quit(1 if failures else 0)
