extends BasePopup


var _first_item        : TreeItem
var _last_item         : TreeItem
var _selected_missions : Dictionary

@onready var lb_header   : Label = %lb_header
@onready var tr_missions : Tree  = %tr_missions
@onready var lb_warnings: Label = %lb_warnings



func _on_ready() -> void:
	tr_missions.columns = 2
	tr_missions.select_mode = Tree.SELECT_MULTI
	lb_warnings.set("theme_override_colors/font_color", data.ERROR_COLOR)


func _on_popup() -> void:
	lb_warnings.hide()
	btn_ok.disabled = true
	tr_missions.grab_focus()

	var num_invalid_missions := 0
	var mission_paths := Path.get_dirpaths(fms.fms_folder)

	var exceptions:Array[String] = ["_missionshots"]
	for i:int in range(mission_paths.size()-1, -1, -1):
		for exc:String in exceptions:
			if mission_paths[i].ends_with(exc):
				mission_paths.remove_at(i)
				break

	tr_missions.clear()
	tr_missions.columns = 1

	var _root := tr_missions.create_item()
	var item:TreeItem

	for i:int in mission_paths.size():
		var path := mission_paths[i]
		var idx  := i % tr_missions.columns
		var mission_name := path.get_file()

		var is_valid_mission := Path.file_exists(Path.join(path, data.MODFILE_FILENAME))
		var is_loaded := fms.is_mission_already_loaded(mission_name)

		if mission_name == "sk_nupcials":
			logs.print(is_valid_mission, Path.join(path, data.MODFILE_FILENAME))

		if idx == 0:
			item = _root.create_child()
			for j:int in tr_missions.columns:
				item.set_selectable(j, false)

		if   i == 0:                      _first_item = item
		elif i == mission_paths.size()-1: _last_item = item

		item.set_text(idx, mission_name)
		item.set_icon(idx, data.FOLDER_ICON)
		item.set_icon_max_width(idx, 20)

		if is_loaded:
			item.set_custom_color(idx, data.FADED_TEXT_COLOR)
		else:
			item.set_selectable(idx, true)
			item.set_metadata(idx, is_valid_mission)

			if not is_valid_mission:
				num_invalid_missions += 1
				item.set_custom_color(idx, data.ERROR_COLOR)


	if num_invalid_missions > 0:
		lb_warnings.text = "%s folders are missing 'darkmod.txt'" % num_invalid_missions
		lb_warnings.show()


func _on_input(event: InputEvent) -> void:
	if   event.is_action_pressed("ui_home"):
		_select_first_item()
	elif event.is_action_pressed("ui_end"):
		_select_last_item()
	elif event.is_action_pressed("ui_cancel"):
		_on_bar_button_pressed(BarButton.CANCEL)


func _on_bar_button_pressed(idx:int) -> void:
	if idx != BarButton.CANCEL:
		if not await _validate_selected_missions():
			return
		_commit_data()

	if idx != BarButton.APPLY:
		close_requested.emit()


func _commit_data() -> void:
	var missions:Array[String]
	for mission_name:String in _selected_missions:
		missions.append(mission_name)
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
func _on_tr_missions_cell_selected() -> void:
	#logs.print("_on_tr_missions_cell_selected")
	btn_ok.disabled = false


func _validate_selected_missions() -> bool:
	var to_load := 0

	for mission_name:String in _selected_missions:
		var is_valid: bool = _selected_missions[mission_name]
		if not is_valid:
			popups.show_confirmation({
				text = "Folder '%s' has no 'darkmod.txt'.\nCreate a new one?" % mission_name,
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
