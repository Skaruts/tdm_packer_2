extends Control

# boot plash size for release:
#	576 x 432


func _enter_tree() -> void:
	# make sure all the existing popup windows have a reference in 'popups'
	popups.popup_background       = %popup_background
	popups.message_dialog         = %AcceptDialog
	popups.confirmation_dialog    = %ConfirmationDialog
	popups.file_dialog            = %FileDialog
	popups.settings_dialog        = %settings_dialog
	popups.quit_save_confirmation = %quit_save_confirmation
	popups.open_mission           = %open_mission
	popups.main_progress_bar      = %main_progress_bar
	popups.pack_mission           = %pack_mission
	popups.add_map                = %add_map

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
	# (still looks bad often, though)
	await get_tree().process_frame
	w.move_to_center()


func _on_console_toggled() -> void:
	%console_split.collapsed = %console.collapsed


var num_subwindows: int
func _notification(what: int) -> void:
	if is_inside_tree():
		await get_tree().process_frame  # wait for popups to close, if any

	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			fms.force_save_mission(false)
			get_tree().quit()

		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			num_subwindows = get_all_subwindows(get_viewport()).size()
			# logs.print(num_subwindows, "NOTIFICATION_WM_WINDOW_FOCUS_OUT")

		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			# logs.print(num_subwindows, "NOTIFICATION_WM_WINDOW_FOCUS_IN")
			if num_subwindows == 0:
				fms.check_missions_on_focus_in()
			#num_subwindows = get_all_subwindows(get_viewport()).size()



func get_all_subwindows(window: Window) -> Array[Window]:
	var windows: Array[Window] = window.get_embedded_subwindows()
	for w in windows:
		windows += get_all_subwindows(w)
	return windows
