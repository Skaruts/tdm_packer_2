extends Control



func _enter_tree() -> void:
	# make sure all the existing popup windows have a reference in 'popups'
	popups.popup_background       = %popup_background
	popups.message_dialog         = %AcceptDialog
	popups.confirmation_dialog    = %ConfirmationDialog
	popups.file_dialog            = %FileDialog
	popups.settings_dialog        = %settings_dialog
	popups.quit_save_confirmation = %quit_save_confirmation


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_window().title = data.app_title

	# need to reset window parameters after boot splash screen is gone
	# splash parameters are the ones used in 'project settings/display/window'
	var w := get_window()
	w.borderless = false
	#w.transparent = false
	w.unresizable = false
	w.size = Vector2i(1152, 738)
	w.move_to_center()

	data.initialize()
	fms.initialize()
	gui.initialize()

	# do this again in case the window got wrongly repositioned due to frame drops
	# (don't just do it here once, though, as it will be visually worse)
	await get_tree().process_frame
	w.move_to_center()


func _on_console_toggled() -> void:
	%console_split.collapsed = %console.collapsed


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if await _check_for_unsaved_missions():
				get_tree().quit()
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			fms.check_mission_filesystem()
			gui.menu_bar.update_menu()



func _check_for_unsaved_missions() -> bool:
	for mission in fms.missions:
		if not mission.dirty: continue

		popups.show_save_quit_confirmation(
			mission.id,
			"Save before quitting?",
			fms.save_mission.bind(mission)
		)

		if await popups.quit_save_confirmation.popup_closed:
			return false

		# add a delay between multiple save confirmation popups
		await get_tree().create_timer(0.1).timeout

	return true
