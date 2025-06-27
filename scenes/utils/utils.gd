class_name Utils
extends Node


# TODO: this ought to be somewhere else
static func set_button_state(btn:Button, enabled:bool) -> void:
	btn.disabled   = not enabled
	btn.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
