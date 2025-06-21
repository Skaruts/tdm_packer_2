extends BasePopup


@onready var category_tree       : Tree     = %category_tree

@onready var ledit_tdm           : LineEdit = %ledit_tdm
@onready var ledit_dr            : LineEdit = %ledit_dr
@onready var ledit_tdm_copy      : LineEdit = %ledit_tdm_copy
@onready var btn_browse_tdm      : Button   = %btn_browse_tdm
@onready var btn_browse_dr       : Button   = %btn_browse_dr
@onready var btn_browse_tdm_copy : Button   = %btn_browse_tdm_copy

@onready var tabs                : TabContainer = %tabs

@onready var sbox_gui_font_size: SpinBox = %sbox_gui_font_size
@onready var sbox_code_font_size: SpinBox = %sbox_code_font_size
@onready var ckbtn_show_roots: CheckButton = %ckbtn_show_roots

@onready var btn_apply: Button = %btn_apply
@onready var btn_ok: Button = %btn_ok
@onready var btn_cancel: Button = %btn_cancel


var temp_config: ConfigData

func _on_ready() -> void:
	#
	# 	init tree
	#
	category_tree.hide_root = true
	var root := category_tree.create_item()
	var general := root.create_child()
	general.set_text(0, "General")
	category_tree.set_selected(general, 0)
	root.create_child().set_text(0, "Paths")
	category_tree.item_selected.connect(
		func() -> void:
			tabs.current_tab = category_tree.get_selected().get_index()
	)

	#
	#	init signals
	#
	sbox_gui_font_size.value_changed.connect(_on_sbox_gui_font_size_value_changed)
	sbox_code_font_size.value_changed.connect(_on_sbox_code_font_size_value_changed)

	ledit_tdm.text_changed.connect(_on_ledit_tdm_text_changed)
	ledit_dr.text_changed.connect(_on_ledit_dr_text_changed)
	ledit_tdm_copy.text_changed.connect(_on_ledit_tdm_copy_text_changed)
	btn_browse_tdm.pressed.connect(_on_btn_browse_tdm_pressed)
	btn_browse_dr.pressed.connect(_on_btn_browse_dr_pressed)
	btn_browse_tdm_copy.pressed.connect(_on_btn_browse_tdm_copy_pressed)


func _on_close_requested() -> void:
	pass


func _on_popup() -> void:
	temp_config = data.config.duplicate()

	ledit_tdm.text      = temp_config.tdm_path
	ledit_dr.text       = temp_config.dr_path
	ledit_tdm_copy.text = temp_config.tdm_copy_path

	_validate_and_update_colors(ledit_tdm,      temp_config.tdm_path,      "tdm_path")
	_validate_and_update_colors(ledit_dr,       temp_config.dr_path,       "dr_path")
	_validate_and_update_colors(ledit_tdm_copy, temp_config.tdm_copy_path, "tdm_copy_path")

	sbox_gui_font_size.set_value_no_signal(temp_config.gui_font_size)
	sbox_code_font_size.set_value_no_signal(temp_config.code_font_size)
	ckbtn_show_roots.set_pressed_no_signal(temp_config.show_tree_roots)


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
	else:
		temp_config.set(key, "")
		line_edit.set_color(line_edit.COLOR_ERROR)
	_update_apply_button()


func _update_apply_button() -> void:
	btn_apply.disabled = temp_config.is_equal_to(data.config)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Paths Settings Buttons

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_ledit_tdm_text_changed(path:String) -> void:
	_validate_and_update_colors(ledit_tdm, path, "tdm_path")

func _on_ledit_dr_text_changed(path:String) -> void:
	_validate_and_update_colors(ledit_dr, path, "dr_path")

func _on_ledit_tdm_copy_text_changed(path:String) -> void:
	_validate_and_update_colors(ledit_tdm_copy, path, "tdm_copy_path")


func _get_curr_dir(ledit:LineEdit, config_key:String) -> String:
	var curr_path: String
	if ledit.text != "" and Path.exists(ledit.text):
		if Path.is_file(ledit.text):
			curr_path = ledit.text.get_base_dir()
		else:
			curr_path = ledit.text
	else:
		curr_path = data.config.get(config_key).get_base_dir()
		if not Path.exists(curr_path):
			curr_path = ""

	return curr_path


func _on_btn_browse_tdm_pressed() -> void:
	popups.open_single_file({
			title = "Locate TDM executable",
			current_dir = _get_curr_dir(ledit_tdm, "tdm_path"),
		},
		func(path:String) -> void:
			logs.print(path)
			ledit_tdm.text = path
			_validate_and_update_colors(ledit_tdm, path, "tdm_path")
	)


func _on_btn_browse_dr_pressed() -> void:
	popups.open_single_file({
			title = "Locate DarkRadiant executable",
			current_dir = _get_curr_dir(ledit_dr, "dr_path"),
		},
		func(path:String) -> void:
			logs.print(path)
			ledit_dr.text = path
			_validate_and_update_colors(ledit_dr, path, "dr_path")
	)


func _on_btn_browse_tdm_copy_pressed() -> void:
	popups.open_single_file({
			title = "Locate TDM copy executable",
			current_dir = _get_curr_dir(ledit_tdm_copy, "tdm_copy_path"),
		},
		func(path:String) -> void:
			logs.print(path)
			ledit_tdm_copy.text = path
			_validate_and_update_colors(ledit_tdm_copy, path, "tdm_copy_path")
	)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		General Settings Buttons

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_sbox_gui_font_size_value_changed(value: float) -> void:
	temp_config.gui_font_size = value
	_update_apply_button()


func _on_sbox_code_font_size_value_changed(value: float) -> void:
	temp_config.code_font_size = value
	_update_apply_button()


func _on_ckbtn_show_roots_toggled(toggled_on: bool) -> void:
	temp_config.show_tree_roots = toggled_on
	_update_apply_button()
