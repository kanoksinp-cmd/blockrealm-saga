extends "res://scripts/ui/ro_ui_base.gd"
## Desktop keeps the classic HUD; phones retain the compact touch interface.
func _ready() -> void:
	if _detect_mobile():
		set_script(load("res://scripts/ui/ro_ui_mobile.gd"))
		call("_ready")
	else:
		super._ready()
