extends Node

var _popups:Array[Window]

# Note: only one 'Window' can be "exclusive". So if an "exclusive" popup must
# be invoked from another "exclusive" popup, then make it local to that
# popup's scene, instead of invoking a global one from here.



func _ready() -> void:
	popups.warning_report = $warning_report
	popups.confirmation   = $confirmation
	popups.settings       = $settings
	popups.add_mission    = $add_mission
	popups.progress_bar   = $progress_bar
	popups.quit_save_confirmation = $quit_save_confirmation

	_popups = [
		popups.warning_report,
		popups.confirmation,
		popups.progress_bar,
		popups.settings,
		popups.add_mission,
		popups.quit_save_confirmation,
	]

	for pu in _popups:
		pu.about_to_popup.connect(_on_popup_opened)
		pu.about_to_close.connect(_on_popup_closed)



func _set_overlay(enable:bool) -> void:
	$ColorRect.visible = enable

func _on_popup_closed() -> void:
	_set_overlay(false)

func _on_popup_opened() -> void:
	_set_overlay(true)
