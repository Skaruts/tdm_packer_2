extends BasePopup


var _first_item        : TreeItem
var _last_item         : TreeItem
var _selected_missions : Dictionary


@onready var lb_header     : Label = %lb_header
@onready var tr_missions   : Tree  = %tr_missions
@onready var lb_warnings   : Label = %lb_warnings
@onready var btn_unlock_fm : Button = %btn_unlock_fm
@onready var le_search     : CustomLineEdit = %le_search


const fm_tooltip_more := "Click to toggle editable/read-only. Making a mission editable means TDM Packer\n"          \
					   + "can create the necessary base base files for the mission. This is not recommended\n"       \
					   + "for missions made by other authors, as it may cause some issues.\n\n"                      \
					   + "(E.g., if a mission has no 'startmap.txt' or 'map_sequence.txt', TDM Packer will create\n" \
					   + "an empty one, which will then prevent TDM from running the mission, as this empty\n"       \
					   + "file will override the one in the pk4.)"

const lock_tooltip_ro := "This mission is read-only.\n\n" + fm_tooltip_more
const lock_tooltip_ed := "This mission is editable.\n\n" + fm_tooltip_more


var _filtered_names : Array[String] = []

func _on_ready() -> void:
	tr_missions.columns = 2
	 #tr_missions.select_mode = Tree.SELECT_MULTI
	tr_missions.select_mode = Tree.SELECT_SINGLE
	lb_warnings.set("theme_override_colors/font_color", data.ERROR_COLOR)

	btn_unlock_fm.pressed.connect(_on_btn_unlock_fm_pressed)

	tr_missions.button_clicked.connect(_on_tr_missions_button_clicked)
	tr_missions.gui_input.connect(_on_tr_missions_gui_input)
	le_search.text_changed.connect(_on_le_search_text_changed)



func _on_popup() -> void:
	lb_warnings.hide()
	btn_ok.disabled = true
	# tr_missions.grab_focus()
	le_search.grab_focus()
	# le_search.text = ""
	_build_missions_list()


func _build_missions_list() -> void:
	logs.print("_build_missions_list")
	# var num_invalid_missions := 0
	var mission_paths := FMUtils.get_mission_folder_list()

	tr_missions.clear()
	tr_missions.columns = 2
	_filtered_names.clear()
	var root := tr_missions.create_item()



	for i: int in mission_paths.size():
		var name := mission_paths[i].get_file()
		var filter: String = le_search.text
		if filter == "" or name.contains(filter):
			_filtered_names.append(name)

	var num_rows : int = round(_filtered_names.size() / float(tr_missions.columns))

	for j: int in num_rows:
		var item := root.create_child()

		var idx1 := j
		_add_tree_item(_filtered_names[idx1], 0, item)

		var idx2 := j+num_rows
		if idx2 < _filtered_names.size():
			_add_tree_item(_filtered_names[idx2], 1, item)

	var children := root.get_children()
	_first_item = children[0]
	_last_item = children[children.size()-1]


func _add_tree_item(id: String, col: int, item: TreeItem) -> void:
		var is_loaded := fms.is_mission_already_loaded(id)
		var is_readonly := fms.is_mission_readonly(id)

		item.set_text(col, id)
		item.set_icon(col, data.ICON_FOLDER)
		item.set_icon_max_width(col, 20)

		if is_readonly:
			item.add_button(col, data.ICON_DOT, 0, false, lock_tooltip_ro)
			item.set_button_color(col, 0, Color.DIM_GRAY)
		else:
			item.add_button(col, data.ICON_CHECKMARK, 0, false, lock_tooltip_ed)
			item.set_button_color(col, 0, data.VALID_COLOR)

		if is_loaded:
			item.set_custom_color(col, data.FADED_TEXT_COLOR)
			item.set_selectable(col, false)
		else:
			item.set_metadata(col, true)



func _on_le_search_text_changed(_new_text: String) -> void:
	_build_missions_list()


func _on_tr_missions_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home"):
		_select_first_item()
	elif event.is_action_pressed("ui_end"):
		_select_last_item()


func _on_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_bar_button_pressed(BarButton.CANCEL)


func _on_bar_button_pressed(idx:int) -> void:
	if idx != BarButton.CANCEL:
		#if not await _validate_selected_missions():
			#return
		_commit_data()

	if idx != BarButton.APPLY:
		close_requested.emit()


func _commit_data() -> void:
	var missions: Array[String]

	for mission_id: String in _selected_missions:
		if mission_id == "": continue
		missions.append(mission_id)

	await fms.add_missions(missions)


func _on_close() -> void:
	_selected_missions.clear()


func _hack_to_force_tree_to_update_visuals() -> void:
	tr_missions.visible = false
	tr_missions.visible = true


func _select_first_item() -> void:
	if _filtered_names.size() <= 1: return
	tr_missions.set_selected(_first_item, 0)
	tr_missions.ensure_cursor_is_visible()
	_hack_to_force_tree_to_update_visuals()


func _select_last_item() -> void:
	if _filtered_names.size() <= 1: return
	for i:int in range(tr_missions.columns-1, -1, -1):
		if _last_item.is_selectable(i):
			tr_missions.set_selected(_last_item, i)
			break
	tr_missions.ensure_cursor_is_visible()
	_hack_to_force_tree_to_update_visuals()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#	signals

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=



func _validate_selected_missions() -> bool:
	var to_load := 0

	for mission_id: String in _selected_missions:
		var is_valid: bool = _selected_missions[mission_id]
		if not is_valid:
			popups.show_confirmation({
				text = "Folder '%s' has no 'darkmod.txt'.\nCreate a new one?" % mission_id,
			})
			if not await popups.confirmation_dialog.answer:
				continue
		to_load += 1

	return to_load == _selected_missions.size()


func _on_tr_missions_item_activated() -> void:
	logs.print("_on_tr_missions_item_activated")
	var item := tr_missions.get_selected()
	if not item: return
	var col := tr_missions.get_selected_column()
	var item_text: String = item.get_text(col)
	if item_text == "": return
	logs.print(item_text)
	_on_bar_button_pressed(BarButton.OK)


func _on_tr_missions_multi_selected(item: TreeItem, column: int, selected: bool) -> void:
	logs.print("_on_tr_missions_multi_selected")
	var item_text: String = item.get_text(column)
	if selected:
		if not item_text in _selected_missions:
			_selected_missions[item_text] = item.get_metadata(column)
	else:
		_selected_missions.erase(item_text)

# func _on_tr_missions_cell_selected() -> void:
# 	logs.print("_on_tr_missions_cell_selected")
# 	btn_ok.disabled = false

func _on_tr_missions_item_selected() -> void:
	logs.print("_on_tr_missions_item_selected")
	btn_ok.disabled = false


	var item := tr_missions.get_selected()
	var col := tr_missions.get_selected_column()
	var item_text: String = item.get_text(col)

	if not item_text in _selected_missions:
		_selected_missions.clear()
		_selected_missions[item_text] = item.get_metadata(col)
	# else:
	# 	_selected_missions.erase(item_text)
	# 	tr_missions.deselect_all()

	if item_text == "":
		btn_ok.disabled = true

	logs.print(_selected_missions)


# func _update_btn_unlock_fm() -> void:
# 	var is_readonly := fms


func _on_btn_unlock_fm_pressed() -> void:
	var readonly: bool
	for mission_id: String in _selected_missions:
		readonly = fms.is_mission_readonly(mission_id)
		fms.set_mission_readonly(mission_id, not readonly)

	var item := tr_missions.get_selected()
	var id := item.get_text(0)
	readonly = fms.is_mission_readonly(id)
	logs.print("_on_btn_unlock_fm_pressed", id, readonly, _selected_missions.size())
	btn_unlock_fm.text = "Make Readonly" if not readonly else "Make Editable"

	if readonly:
		# item.add_button(0, data.ICON_CHECKMARK, 0, true, "This mission is read-only")
		item.set_button_color(0, 0, Color.DIM_GRAY)
	else:
		# item.add_button(0, data.ICON_CHECKMARK, 0, true, "This mission is editable")
		item.set_button_color(0, 0, data.VALID_COLOR)


func _on_tr_missions_button_clicked(item: TreeItem, column: int, _btn_id: int, _mouse_button_index: int) -> void:
	var id := item.get_text(column)

	fms.set_mission_readonly(id, not fms.is_mission_readonly(id))

	if fms.is_mission_readonly(id):
		item.set_button_tooltip_text(column, 0, lock_tooltip_ro)
		item.set_button_color(column, 0, Color.DIM_GRAY)
		item.set_button(column, 0, data.ICON_DOT)
	else:
		item.set_button_tooltip_text(column, 0, lock_tooltip_ed)
		item.set_button_color(column, 0, data.VALID_COLOR)
		item.set_button(column, 0, data.ICON_CHECKMARK)
