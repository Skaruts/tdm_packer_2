extends BasePopup


@onready var ok_btn: Button = %ok_btn
@onready var path_line_edit: LineEdit = %path_line_edit
@onready var info_label: Label = %info_label

@onready var file_dialog: FileDialog = $file_dialog


func open(_pu_data:Variant=null) -> void:
	super(_pu_data)
	await get_tree().process_frame
	_on_browse_btn_pressed()


func _on_ok_btn_pressed() -> void:
	close(true)
	path_line_edit.text = ""


func _on_cancel_btn_pressed() -> void:
	close(false)
	path_line_edit.text = ""


func update_line_edit(path:String) -> void:
	if fm_manager.validate_mission_path(path):
		pu_data.id = path.get_file()
		#path_line_edit.set_color(path_line_edit.COLOR_VALID)
		#ok_btn.disabled = false
		info_label.text = "Path is valid."
		info_label.set("theme_override_colors/font_color", data.VALID_COLOR)
	else:
		pu_data.id = ""
		#path_line_edit.set_color(path_line_edit.COLOR_ERROR)
		#ok_btn.disabled = true
		info_label.text = "Invalid path. No 'darkmod.txt' found."
		info_label.set("theme_override_colors/font_color", data.ERROR_COLOR)


func _on_path_line_edit_text_changed(new_text: String) -> void:
	logs.print(new_text)
	update_line_edit(new_text)
	ok_btn.disabled = pu_data.id == ""
	if new_text == "":
		info_label.text = ""


func _on_browse_btn_pressed() -> void:
	var fms_dir := Path.join(data.config.tdm_path.get_base_dir(), "fms")

	file_dialog.open({
		title = "Locate Mission",
		dir = fms_dir,
		root = fms_dir,
		mode = FileDialog.FILE_MODE_OPEN_DIR
	})

	var dir:String = await file_dialog.dir_selected
	logs.print("_on_browse_btn_pressed: ", dir)
	path_line_edit.text = dir

	update_line_edit(dir)
	ok_btn.disabled = pu_data.id == ""



