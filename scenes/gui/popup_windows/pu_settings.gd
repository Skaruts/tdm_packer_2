extends BasePopup


@onready var le_tdm              : LineEdit = %le_tdm
@onready var le_dr               : LineEdit = %le_dr
@onready var le_tdm_copy         : LineEdit = %le_tdm_copy
@onready var btn_browse_tdm      : Button   = %btn_browse_tdm
@onready var btn_browse_dr       : Button   = %btn_browse_dr
@onready var btn_browse_tdm_copy : Button   = %btn_browse_tdm_copy

@onready var sb_gui_font_size    : SpinBox     = %sb_gui_font_size
@onready var sb_code_font_size   : SpinBox     = %sb_code_font_size
@onready var cbt_show_roots      : CheckButton = %cbt_show_roots
@onready var sb_bg_opacity       : SpinBox     = %sb_bg_opacity


var temp_config: ConfigData


func _on_ready() -> void:
	%tabs.current_tab = 0

	sb_gui_font_size.value_changed.connect(_on_sb_gui_font_size_value_changed)
	sb_code_font_size.value_changed.connect(_on_sb_code_font_size_value_changed)

	le_tdm.text_changed.connect(_on_le_tdm_text_changed)
	le_dr.text_changed.connect(_on_le_dr_text_changed)
	le_tdm_copy.text_changed.connect(_on_le_tdm_copy_text_changed)
	btn_browse_tdm.pressed.connect(_on_btn_browse_tdm_pressed)
	btn_browse_dr.pressed.connect(_on_btn_browse_dr_pressed)
	btn_browse_tdm_copy.pressed.connect(_on_btn_browse_tdm_copy_pressed)


func _on_close_requested() -> void:
	pass


func _on_popup() -> void:
	temp_config = data.config.duplicate()

	le_tdm.text      = temp_config.tdm_path
	le_dr.text       = temp_config.dr_path
	le_tdm_copy.text = temp_config.tdm_copy_path

	_validate_and_update_colors(le_tdm,      temp_config.tdm_path,      "tdm_path")
	_validate_and_update_colors(le_dr,       temp_config.dr_path,       "dr_path")
	_validate_and_update_colors(le_tdm_copy, temp_config.tdm_copy_path, "tdm_copy_path")

	sb_gui_font_size.set_value_no_signal(temp_config.gui_font_size)
	sb_code_font_size.set_value_no_signal(temp_config.code_font_size)
	cbt_show_roots.set_pressed_no_signal(temp_config.show_tree_roots)
	sb_bg_opacity.set_value_no_signal(temp_config.popup_bg_opacity * 100)


func _on_input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_accept")\
	#and not btn_ok.disabled:
		#_on_bar_button_pressed(BarButtonIndex.BUTTON_OK)
	if event.is_action_pressed("ui_cancel"):
		_on_bar_button_pressed(BarButtonIndex.BUTTON_CANCEL)


func _on_bar_button_pressed(idx:int) -> void:
	if idx != BarButtonIndex.BUTTON_CANCEL:
		_commit_data()

	if idx != BarButtonIndex.BUTTON_APPLY:
		close_requested.emit()


func _commit_data() -> void:
	data.update_config(temp_config)
	gui.workspace_mgr.set_show_roots()
	gui.missions_list.update_buttons()
	gui.menu_bar.update_menu()


func _validate_and_update_colors(line_edit:CustomLineEdit, filepath:String, key:String) -> void:
	if Path.file_exists(filepath):
		temp_config.set(key, filepath)
		line_edit.set_color(line_edit.COLOR_NORMAL) # COLOR_NORMAL
		_update_apply_button()
	else:
		temp_config.set(key, "")
		line_edit.set_color(line_edit.COLOR_ERROR)



func _update_apply_button() -> void:
	%btn_apply.disabled = temp_config.is_equal_to(data.config)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Paths Settings Buttons

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_le_tdm_text_changed(path:String) -> void:
	_validate_and_update_colors(le_tdm, path, "tdm_path")


func _on_le_dr_text_changed(path:String) -> void:
	_validate_and_update_colors(le_dr, path, "dr_path")


func _on_le_tdm_copy_text_changed(path:String) -> void:
	_validate_and_update_colors(le_tdm_copy, path, "tdm_copy_path")


func _get_curr_dir(le:LineEdit, config_key:String) -> String:
	var curr_path: String
	if le.text != "" and Path.exists(le.text):
		if Path.is_file(le.text):
			curr_path = le.text.get_base_dir()
		else:
			curr_path = le.text
	else:
		curr_path = data.config.get(config_key).get_base_dir()
		if not Path.exists(curr_path):
			curr_path = ""

	return curr_path


func _on_btn_browse_tdm_pressed() -> void:
	popups.open_single_file({
			title = "Locate TDM executable",
			current_dir = _get_curr_dir(le_tdm, "tdm_path"),
		},
		func(path:String) -> void:
			logs.print(path)
			le_tdm.text = path
			_validate_and_update_colors(le_tdm, path, "tdm_path")
	)


func _on_btn_browse_dr_pressed() -> void:
	popups.open_single_file({
			title = "Locate DarkRadiant executable",
			current_dir = _get_curr_dir(le_dr, "dr_path"),
		},
		func(path:String) -> void:
			logs.print(path)
			le_dr.text = path
			_validate_and_update_colors(le_dr, path, "dr_path")
	)


func _on_btn_browse_tdm_copy_pressed() -> void:
	popups.open_single_file({
			title = "Locate TDM copy executable",
			current_dir = _get_curr_dir(le_tdm_copy, "tdm_copy_path"),
		},
		func(path:String) -> void:
			logs.print(path)
			le_tdm_copy.text = path
			_validate_and_update_colors(le_tdm_copy, path, "tdm_copy_path")
	)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		General Settings Buttons

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_sb_gui_font_size_value_changed(value: float) -> void:
	temp_config.gui_font_size = value
	_update_apply_button()


func _on_sb_code_font_size_value_changed(value: float) -> void:
	temp_config.code_font_size = value
	_update_apply_button()


func _on_cbt_show_roots_toggled(toggled_on: bool) -> void:
	temp_config.show_tree_roots = toggled_on
	_update_apply_button()


func _on_sb_bg_opacity_value_changed(value: float) -> void:
	temp_config.popup_bg_opacity = value/100.0
	_update_apply_button()
