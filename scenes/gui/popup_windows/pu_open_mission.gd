extends BasePopup


var _first_item        : TreeItem
var _last_item         : TreeItem
var _selected_missions : Dictionary

@onready var lb_header   : Label = %lb_header
@onready var tr_missions : Tree  = %tr_missions
@onready var lb_warnings: Label = %lb_warnings

@onready var btn_unlock_fm: Button = %btn_unlock_fm

const fm_tooltip_more := "Click to toggle editable/read-only. Making a mission editable means TDM Packer\n"          \
					   + "can create the necessary base base files for the mission. This is not recommended\n"       \
					   + "for missions made by other authors, as it may cause some issues.\n\n"                      \
					   + "(E.g., if a mission has no 'startmap.txt' or 'map_sequence.txt', TDM Packer will create\n" \
					   + "an empty one, which will then prevent TDM from running the mission, as this empty\n"       \
					   + "file will override the one in the pk4.)"

const lock_tooltip_ro := "This mission is read-only.\n\n" + fm_tooltip_more
const lock_tooltip_ed := "This mission is editable.\n\n" + fm_tooltip_more



func _on_ready() -> void:
	tr_missions.columns = 2
	# tr_missions.select_mode = Tree.SELECT_MULTI
	tr_missions.select_mode = Tree.SELECT_ROW
	lb_warnings.set("theme_override_colors/font_color", data.ERROR_COLOR)

	btn_unlock_fm.pressed.connect(_on_btn_unlock_fm_pressed)

	tr_missions.button_clicked.connect(_on_tr_missions_button_clicked)



func _on_popup() -> void:
	lb_warnings.hide()
	btn_ok.disabled = true
	tr_missions.grab_focus()

	# var num_invalid_missions := 0
	var mission_paths := FMUtils.get_mission_folder_list()

	tr_missions.clear()
	tr_missions.columns = 1
	var _root := tr_missions.create_item()

	for i: int in mission_paths.size():
		var path := mission_paths[i]
		var idx  := i % tr_missions.columns
		var mission_id := path.get_file()
		var item: TreeItem

		# var is_valid_mission := Path.file_exists(Path.join(path, data.MODFILE_FILENAME))
		var is_loaded := fms.is_mission_already_loaded(mission_id)
		var is_readonly := fms.is_mission_readonly(mission_id)

		if idx == 0:
			item = _root.create_child()
			for j:int in tr_missions.columns:
				item.set_selectable(j, false)

		if   i == 0:                      _first_item = item
		elif i == mission_paths.size()-1: _last_item = item

		item.set_text(idx, mission_id)
		item.set_icon(idx, data.ICON_FOLDER)
		item.set_icon_max_width(idx, 20)

		if is_readonly:
			item.add_button(idx, data.ICON_DOT, 0, false, lock_tooltip_ro)
			item.set_button_color(idx, 0, Color.DIM_GRAY)
		else:
			item.add_button(idx, data.ICON_CHECKMARK, 0, false, lock_tooltip_ed)
			item.set_button_color(idx, 0, data.VALID_COLOR)


		if is_loaded:
			# item.set_custom_color(idx, data.VALID_COLOR)
			item.set_custom_color(idx, data.FADED_TEXT_COLOR)
		else:
			item.set_selectable(idx, true)
			item.set_metadata(idx, true) #is_valid_mission)

			# if not is_valid_mission:
			# 	num_invalid_missions += 1
			# 	item.set_custom_color(idx, data.ERROR_COLOR)



	# if num_invalid_missions > 0:
	# 	lb_warnings.text = "%s folders are missing 'darkmod.txt'" % num_invalid_missions
	# 	lb_warnings.show()


func _on_input(event: InputEvent) -> void:
	if   event.is_action_pressed("ui_home"):
		_select_first_item()
	elif event.is_action_pressed("ui_end"):
		_select_last_item()
	elif event.is_action_pressed("ui_cancel"):
		_on_bar_button_pressed(BarButton.CANCEL)


func _on_bar_button_pressed(idx:int) -> void:
	if idx != BarButton.CANCEL:
		#if not await _validate_selected_missions():
			#return
		_commit_data()

	if idx != BarButton.APPLY:
		close_requested.emit()


func _commit_data() -> void:
	var missions:Array[String]
	for mission_id:String in _selected_missions:
		missions.append(mission_id)
	await fms.add_missions(missions)


func _on_close() -> void:
	_selected_missions.clear()


func _hack_to_force_tree_to_update_visuals() -> void:
	tr_missions.visible = false
	tr_missions.visible = true


func _select_first_item() -> void:
	tr_missions.set_selected(_first_item, 0)
	tr_missions.ensure_cursor_is_visible()
	_hack_to_force_tree_to_update_visuals()


func _select_last_item() -> void:
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
	#logs.print("_on_tr_missions_item_activated")
	_on_bar_button_pressed(BarButton.OK)


func _on_tr_missions_multi_selected(item: TreeItem, column: int, selected: bool) -> void:
	var item_text: String = item.get_text(column)
	if selected:
		if not item_text in _selected_missions:
			_selected_missions[item_text] = item.get_metadata(column)
	else:
		_selected_missions.erase(item_text)

func _on_tr_missions_cell_selected() -> void:
	logs.print("_on_tr_missions_cell_selected")
	btn_ok.disabled = false

func _on_tr_missions_item_selected() -> void:
	logs.print("_on_tr_missions_item_selected")
	btn_ok.disabled = false
	var item := tr_missions.get_selected()
	var item_text: String = item.get_text(0)

	if not item_text in _selected_missions:
		_selected_missions[item_text] = item.get_metadata(0)
	else:
		_selected_missions.erase(item_text)

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
