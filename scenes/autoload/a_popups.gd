extends Node
# autoloaded script

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#
#   This is a bit of wrapper around the popup windows, just so I can darken
#   the screen behind them using a 'ColorRect'.
#
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

# these variables are set in 'main' on '_enter_tree'
var popup_background       : ColorRect
var confirmation_dialog    : ConfirmationDialog
var message_dialog         : AcceptDialog
var file_dialog            : FileDialog

var quit_save_confirmation : ConfirmationDialog
var settings_dialog        : Window

var popup_stack    : Array[Window]


func _ready() -> void:
	confirmation_dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	confirmation_dialog.get_label().max_lines_visible = 10

	message_dialog.visibility_changed.connect(_on_popup_visibility_changed.bind(message_dialog))
	confirmation_dialog.visibility_changed.connect(_on_popup_visibility_changed.bind(confirmation_dialog))
	file_dialog.visibility_changed.connect(_on_popup_visibility_changed.bind(file_dialog))
	quit_save_confirmation.visibility_changed.connect(_on_popup_visibility_changed.bind(quit_save_confirmation))
	settings_dialog.visibility_changed.connect(_on_popup_visibility_changed.bind(settings_dialog))


func _on_popup_visibility_changed(pu:Window) -> void:
	if pu.visible:
		popup_stack.push_back(pu)
		popup_background.visible = true
	else:
		var last_pu: Window = popup_stack.pop_back()
		if last_pu != pu: logs.error("popup stack mismatch")
		if popup_stack.size() == 0:
			popup_background.visible = false


func _connect_callback(pu:Window, _signal:StringName, callback:Variant=null) -> void:
	var connections := pu.get_signal_connection_list(_signal)
	for c:Dictionary in connections:
		pu.disconnect(_signal, c.callable)

	if callback:
		pu.connect(_signal, callback)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Regular Popups
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func show_message(title:String, text:String, callback:Variant=null) -> void:
	_connect_callback(message_dialog, "confirmed", callback)
	message_dialog.title = title
	message_dialog.dialog_text = text
	message_dialog.popup()


func show_confirmation(options: Dictionary, callback:Callable) -> void:
	_connect_callback(confirmation_dialog, "confirmed", callback)
	confirmation_dialog.title              = "Please Confirm" if not "title" in options else options.title
	confirmation_dialog.dialog_text        = "Are you sure?" if not "text" in options else options.text
	confirmation_dialog.cancel_button_text = "Cancel" if not "cancel_text" in options else options.cancel_text
	confirmation_dialog.ok_button_text     = "Ok" if not "ok_text" in options else options.ok_text
	confirmation_dialog.popup()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Misc Popups
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func show_popup(pu:Window, confirm_cb:Variant=null, cancel_cb:Variant=null) -> void:
	_connect_callback(pu, "confirmed", confirm_cb)
	_connect_callback(pu, "canceled", cancel_cb)
	pu.popup()


func show_save_quit_confirmation(mission_id:String, question:String, save_cb:Callable, nosave_cb:Variant=null) -> void:
	_connect_callback(quit_save_confirmation, "confirmed", save_cb)
	_connect_callback(quit_save_confirmation, "custom_action", nosave_cb)
	quit_save_confirmation.dialog_text = "There are unsaved changes to '%s'.\n%s" % [mission_id, question]
	quit_save_confirmation.popup()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		File Dialogs
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _check_file_diagog_options(options:Dictionary, default_title: String) -> void:
	file_dialog.root_subfolder     = ""            if not "root_subfolder" in options else options.root_subfolder
	file_dialog.current_dir        = ""            if not "current_dir"    in options else options.current_dir
	file_dialog.filters            = []            if not "filters"        in options else options.filters
	file_dialog.cancel_button_text = "Cancel"      if not "cancel_text"    in options else options.cancel_text
	file_dialog.ok_button_text     = "OK"          if not "ok_text"        in options else options.ok_text
	file_dialog.title              = default_title if not "title" in options else options.title


func open_folder(options:Dictionary, callback:Callable) -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_check_file_diagog_options(options, "Open Directory")
	_connect_callback(file_dialog, "dir_selected", callback)
	file_dialog.popup()


func open_single_file(options:Dictionary, callback:Callable) -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_check_file_diagog_options(options, "Open File")
	_connect_callback(file_dialog, "file_selected", callback)
	file_dialog.popup()


func open_multi_file(options:Dictionary, callback:Callable) -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	_check_file_diagog_options(options, "Open Files")
	_connect_callback(file_dialog, "files_selected", callback)
	file_dialog.popup()
