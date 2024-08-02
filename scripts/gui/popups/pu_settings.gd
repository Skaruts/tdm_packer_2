extends BasePopup



@onready var dr_line_edit: LineEdit = %dr_line_edit
@onready var tdm_line_edit: LineEdit = %tdm_line_edit
@onready var tdm_copy_line_edit: LineEdit = %tdm_copy_line_edit

@onready var dr_browse_btn: Button = %dr_browse_btn
@onready var tdm_browse_btn: Button = %tdm_browse_btn
@onready var tdm_copy_browse_btn: Button = %tdm_copy_browse_btn

@onready var minimap_checkbox: CheckBox = %minimap_checkbox

@onready var cat_tree: Tree = $Control/VBoxContainer/HBoxContainer/category_tree
@onready var tabs: TabContainer = %tabs

@onready var text_edits_font_size_spinbox: SpinBox = %text_edits_font_size_spinbox
@onready var gui_font_size_spinbox: SpinBox = %gui_font_size_spinbox


@onready var file_dialog: FileDialog = $file_dialog



func _ready() -> void:
	cat_tree.hide_root = true
	var root := cat_tree.create_item()

	var general := root.create_child()
	var paths := root.create_child()
	general.set_text(0, "General")
	paths.set_text(0, "Paths")

	cat_tree.set_selected(general, 0)


func open(pu_data:Variant=null) -> void:
	super(pu_data)
	dr_line_edit.text = pu_data.dr_path
	tdm_line_edit.text = pu_data.tdm_path
	tdm_copy_line_edit.text = pu_data.tdm_copy_path
	validate_and_update_colors(dr_line_edit, pu_data.dr_path, "dr_path")
	validate_and_update_colors(tdm_line_edit, pu_data.tdm_path, "tdm_path")
	validate_and_update_colors(tdm_copy_line_edit, pu_data.tdm_copy_path, "tdm_copy_path")

	#minimap_checkbox.button_pressed = pu_data.draw_minimap
	#text_size_spinbox.data.config.

	var theme := ThemeDB.get_project_theme()
	gui_font_size_spinbox.set_value_no_signal(pu_data.gui_font_size)
	text_edits_font_size_spinbox.set_value_no_signal(pu_data.code_font_size)




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Menu / ok / cancel
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_category_tree_item_selected() -> void:
	tabs.current_tab = cat_tree.get_selected().get_index()

func _on_ok_btn_pressed() -> void:
	close(true)

func _on_cancel_btn_pressed() -> void:
	close(false)

func validate_and_update_colors(line_edit:LineEdit, filepath:String, key:String) -> void:
	if Path.file_exists(filepath):
		pu_data[key] = filepath
		line_edit.set_color(line_edit.COLOR_NORMAL) # COLOR_NORMAL
	else:
		pu_data[key] = ""
		line_edit.set_color(line_edit.COLOR_ERROR)




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		General

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_minimap_checkbox_toggled(toggled_on: bool) -> void:
	pu_data.draw_minimap = toggled_on




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Paths

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_dr_line_edit_text_changed(path: String) -> void:
	validate_and_update_colors(dr_line_edit, path, "dr_path")

func _on_tdm_line_edit_text_changed(path: String) -> void:
	validate_and_update_colors(tdm_line_edit, path, "tdm_path")

func _on_tdm_copy_line_edit_text_changed(path: String) -> void:
	validate_and_update_colors(tdm_copy_line_edit, path, "tdm_copy_path")



func _on_dr_browse_btn_pressed() -> void:
	var curr_dir :String
	if dr_line_edit.text: curr_dir = dr_line_edit.text.get_base_dir()
	else:                 data.config.dr_path.get_base_dir()

	file_dialog.open({
		title = "Locate DarkRadiant",
		dir = curr_dir,
		mode = FileDialog.FILE_MODE_OPEN_FILE,
	})

	var filepath:String = await file_dialog.file_selected
	dr_line_edit.text = filepath
	validate_and_update_colors(dr_line_edit, filepath, "dr_path")


func _on_tdm_browse_btn_pressed() -> void:
	var curr_dir :String
	if tdm_line_edit.text: curr_dir = tdm_line_edit.text.get_base_dir()
	else:                 data.config.tdm_path.get_base_dir()

	file_dialog.open({
		title = "Locate TDM",
		dir = curr_dir,
		mode = FileDialog.FILE_MODE_OPEN_FILE,
	})
	var filepath:String = await file_dialog.file_selected

	tdm_line_edit.text = filepath
	validate_and_update_colors(tdm_line_edit, filepath, "tdm_path")

func _on_tdm_copy_browse_btn_pressed() -> void:
	var curr_dir :String
	if tdm_copy_line_edit.text: curr_dir = tdm_copy_line_edit.text.get_base_dir()
	else:                 data.config.tdm_copy_path.get_base_dir()

	file_dialog.open({
		title = "Locate TDM (test version)",
		dir = curr_dir,
		mode = FileDialog.FILE_MODE_OPEN_FILE,
	})
	var filepath:String = await file_dialog.file_selected

	tdm_copy_line_edit.text = filepath
	validate_and_update_colors(tdm_copy_line_edit, filepath, "tdm_copy_path")



func _on_gui_font_size_spinbox_value_changed(value: float) -> void:
	pu_data["gui_font_size"] = value
	#var theme := ThemeDB.get_project_theme()

func _on_text_edits_font_size_spinbox_value_changed(value: float) -> void:
	pu_data["code_font_size"] = value



func _on_apply_btn_pressed() -> void:
	data.update_theme(pu_data)
