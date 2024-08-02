extends Control



func _enter_tree() -> void:
	data.initialize()


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_window().title = data.app_title

	# don't init this in 'enter_tree', it must be after everything else is ready
	fm_manager.initialize()


func _on_console_btn_pressed() -> void:
	%con_split.collapsed = not %console.console_label.visible


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if await _check_for_unsaved_missions():
			get_tree().quit()


func _check_for_unsaved_missions() -> bool:
	var conf := popups.quit_save_confirmation

	for mission in fm_manager.missions:
		if mission.dirty:
			conf.open({
				title = "Please Confirm...",
				text = "There are unsaved changes to '%s'." % mission.id,
			})

			var answer:int = await conf.popup_closed
			match answer:
				conf.CANCEL:        return false
				conf.SAVE_AND_QUIT: fm_manager.save_mission(mission)

		# wait a bit, so that if there are multiple unsaved missions
		# the conf window closing and reopening is more perceptible to
		# the users (better visual feedback)
		await get_tree().create_timer(0.1).timeout

	return true
