extends BasePopup


@onready var le_tdm              : LineEdit    = %le_tdm
@onready var le_dr               : LineEdit    = %le_dr
@onready var le_tdm_copy         : LineEdit    = %le_tdm_copy
@onready var btn_browse_tdm      : Button      = %btn_browse_tdm
@onready var btn_browse_dr       : Button      = %btn_browse_dr
@onready var btn_browse_tdm_copy : Button      = %btn_browse_tdm_copy

@onready var sb_gui_font_size    : SpinBox     = %sb_gui_font_size
@onready var sb_code_font_size   : SpinBox     = %sb_code_font_size
@onready var cbt_show_roots      : CheckButton = %cbt_show_roots
@onready var sb_bg_opacity       : SpinBox     = %sb_bg_opacity

@onready var le_pk4_suffix       : LineEdit    = %le_pk4_suffix
@onready var le_date_time_format : LineEdit    = %le_date_time_format


@onready var cpb_background : ColorPickerButton = %cpb_background
@onready var ob_close_btns  : OptionButton      = %ob_close_btns

@onready var cpb_text       : ColorPickerButton = %cpb_text
@onready var cpb_keywords1  : ColorPickerButton = %cpb_keywords1
@onready var cpb_comments   : ColorPickerButton = %cpb_comments
@onready var cpb_keywords2  : ColorPickerButton = %cpb_keyword2
@onready var cpb_strings    : ColorPickerButton = %cpb_strings
@onready var cpb_keywords3  : ColorPickerButton = %cpb_keyword3
@onready var cpb_numbers    : ColorPickerButton = %cpb_numbers
@onready var cpb_types      : ColorPickerButton = %cpb_types
@onready var cpb_booleans   : ColorPickerButton = %cpb_booleans
@onready var cpb_functions  : ColorPickerButton = %cpb_functions
@onready var cpb_constants  : ColorPickerButton = %cpb_constants
@onready var cpb_builtins   : ColorPickerButton = %cpb_builtins
@onready var cpb_symbols    : ColorPickerButton = %cpb_symbols
@onready var cpb_members    : ColorPickerButton = %cpb_members
@onready var cpb_directives : ColorPickerButton = %cpb_directives
@onready var cpb_headers    : ColorPickerButton = %cpb_headers
@onready var cpb_params     : ColorPickerButton = %cpb_params



var color_pickers: Array[ColorPickerButton]
var temp_config: ConfigData


func _on_ready() -> void:
	%tc_tabs.current_tab = 0

	sb_gui_font_size.value_changed.connect(_on_sb_gui_font_size_value_changed)
	sb_code_font_size.value_changed.connect(_on_sb_code_font_size_value_changed)

	le_tdm.text_changed.connect(_on_le_tdm_text_changed)
	le_dr.text_changed.connect(_on_le_dr_text_changed)
	le_tdm_copy.text_changed.connect(_on_le_tdm_copy_text_changed)
	le_date_time_format.text_changed.connect(_on_le_date_time_format_text_changed)

	btn_browse_tdm.pressed.connect(_on_btn_browse_tdm_pressed)
	btn_browse_dr.pressed.connect(_on_btn_browse_dr_pressed)
	btn_browse_tdm_copy.pressed.connect(_on_btn_browse_tdm_copy_pressed)

	color_pickers = [
		cpb_background,   cpb_text,        cpb_keywords1,
		cpb_comments,     cpb_keywords2,   cpb_strings,
		cpb_keywords3,    cpb_numbers,     cpb_types,
		cpb_booleans,     cpb_functions,   cpb_constants,
		cpb_builtins,     cpb_symbols,     cpb_members,
		cpb_directives,   cpb_headers,     cpb_params,
	]

	for cbp in color_pickers:
		cbp.color_changed.connect(_on_cpb_color_changed.bind(cbp))

	ob_close_btns.item_selected.connect(_in_ob_close_btns_item_selected)



func _on_close_requested() -> void:
	pass


func _on_popup() -> void:
	temp_config = data.config.duplicate()

	le_tdm.text        = temp_config.tdm_path
	le_dr.text         = temp_config.dr_path
	le_tdm_copy.text   = temp_config.tdm_copy_path

	_validate_and_update_colors(le_tdm,      temp_config.tdm_path,      "tdm_path")
	_validate_and_update_colors(le_dr,       temp_config.dr_path,       "dr_path")
	_validate_and_update_colors(le_tdm_copy, temp_config.tdm_copy_path, "tdm_copy_path")

	sb_gui_font_size.set_value_no_signal(temp_config.gui_font_size)
	sb_code_font_size.set_value_no_signal(temp_config.code_font_size)
	cbt_show_roots.set_pressed_no_signal(temp_config.show_tree_roots)
	sb_bg_opacity.set_value_no_signal(temp_config.popup_bg_opacity * 100)

	le_pk4_suffix.text = temp_config.packname_suffix
	le_date_time_format.text = temp_config.date_time_format


	cpb_background.color   = temp_config.background_color
	ob_close_btns.selected = temp_config.tab_close_buttons_mode

	cpb_text.color       = temp_config.text
	cpb_keywords1.color  = temp_config.keyword1
	cpb_comments.color   = temp_config.comment
	cpb_keywords2.color  = temp_config.keyword2
	cpb_strings.color    = temp_config.string
	cpb_keywords3.color  = temp_config.keyword3
	cpb_numbers.color    = temp_config.number
	cpb_types.color      = temp_config.type
	cpb_booleans.color   = temp_config.boolean
	cpb_functions.color  = temp_config.function
	cpb_constants.color  = temp_config.constant
	cpb_builtins.color   = temp_config.builtin
	cpb_symbols.color    = temp_config.symbol
	cpb_members.color    = temp_config.member
	cpb_directives.color = temp_config.directive
	cpb_headers.color    = temp_config.header
	cpb_params.color     = temp_config.param



func _on_input(event: InputEvent) -> void:
	#if event.is_action_pressed("ui_accept")\
	#and not btn_ok.disabled:
		#_on_bar_button_pressed(BarButton.OK)
	if event.is_action_pressed("ui_cancel"):
		_on_bar_button_pressed(BarButton.CANCEL)


func _on_bar_button_pressed(idx:int) -> void:
	if idx != BarButton.CANCEL:
		_commit_data()

	if idx != BarButton.APPLY:
		close_requested.emit()


func _commit_data() -> void:
	data.update_config(temp_config)



func _validate_and_update_colors(line_edit:CustomLineEdit, filepath:String, key:String) -> void:
	if Path.file_exists(filepath):
		temp_config.set(key, filepath)
		line_edit.set_color(line_edit.COLOR_NORMAL) # COLOR_NORMAL
		_update_apply_button()
	else:
		temp_config.set(key, "")
		line_edit.set_color(line_edit.COLOR_ERROR)



func _update_apply_button() -> void:
	btn_apply.disabled = temp_config.is_equal_to(data.config)



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
		if Path.file_exists(le.text):
			curr_path = le.text.get_base_dir()
		else:
			curr_path = le.text
	else:
		curr_path = data.config.get(config_key).get_base_dir()
		if not Path.dir_exists(curr_path):
			curr_path = ""

	return curr_path


func _on_btn_browse_tdm_pressed() -> void:
	var filters := _get_executable_filters()

	popups.open_single_file({
			title = "Locate TDM executable",
			current_dir = _get_curr_dir(le_tdm, "tdm_path"),
			filters = filters,
		},
		func(path:String) -> void:
			logs.print(path)
			le_tdm.text = path
			_validate_and_update_colors(le_tdm, path, "tdm_path")
	)


func _on_btn_browse_dr_pressed() -> void:
	var filters := _get_executable_filters()

	popups.open_single_file({
			title = "Locate DarkRadiant executable",
			current_dir = _get_curr_dir(le_dr, "dr_path"),
			filters = filters,
		},
		func(path:String) -> void:
			logs.print(path)
			le_dr.text = path
			_validate_and_update_colors(le_dr, path, "dr_path")
	)


func _get_executable_filters() -> Array:
	match OS.get_name():
		"Windows": return ["*.exe; Executable Files"]
		"macOS": return ["*.dmg, *.app; Executable Files"]
		"Linux": return []
	return []

func _on_btn_browse_tdm_copy_pressed() -> void:
	var filters := _get_executable_filters()

	popups.open_single_file({
			title = "Locate TDM copy executable",
			current_dir = _get_curr_dir(le_tdm_copy, "tdm_copy_path"),
			filters = filters,
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


func _on_le_pk_4_suffix_text_changed(new_text: String) -> void:
	temp_config.packname_suffix = new_text
	_update_apply_button()

func _on_le_date_time_format_text_changed(new_text:String) -> void:
	temp_config.date_time_format = new_text
	_update_apply_button()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Color Settings Buttons

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_cpb_color_changed(color: Color, cpb: ColorPickerButton) -> void:
	match cpb:
		cpb_background : temp_config.background_color = color
		cpb_text       : temp_config.text      = color
		cpb_keywords1  : temp_config.keyword1  = color
		cpb_comments   : temp_config.comment   = color
		cpb_keywords2  : temp_config.keyword2  = color
		cpb_strings    : temp_config.string    = color
		cpb_keywords3  : temp_config.keyword3  = color
		cpb_numbers    : temp_config.number    = color
		cpb_types      : temp_config.type      = color
		cpb_booleans   : temp_config.boolean   = color
		cpb_functions  : temp_config.function  = color
		cpb_constants  : temp_config.constant  = color
		cpb_builtins   : temp_config.builtin   = color
		cpb_symbols    : temp_config.symbol    = color
		cpb_members    : temp_config.member    = color
		cpb_directives : temp_config.directive = color
		cpb_headers    : temp_config.header    = color
		cpb_params     : temp_config.param     = color
	_update_apply_button()


func _in_ob_close_btns_item_selected(idx: int) -> void:
	temp_config.tab_close_buttons_mode = idx
	_update_apply_button()
