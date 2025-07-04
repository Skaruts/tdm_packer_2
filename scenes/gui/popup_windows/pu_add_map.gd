extends BasePopup


const _LOADED_COLOR := Color(0.42, 0.807, 1.0)
const _ICON_COLOR   := Color(0.0, 1.0, 0.0)


var _first_item    : TreeItem
var _last_item     : TreeItem
var _selected_maps : Dictionary

# hacky way of communicating directly with the gui_tab_package that invokes this
var pack_tab : Control


@onready var lb_header         : Label       = %lb_header
@onready var tr_maps           : Tree        = %tr_maps
@onready var lb_warnings       : Label       = %lb_warnings
@onready var cbt_hide_excluded : CheckButton = %cbt_hide_excluded


func _on_ready() -> void:
	tr_maps.columns = 1
	tr_maps.select_mode = Tree.SELECT_MULTI
	lb_warnings.set("theme_override_colors/font_color", data.ERROR_COLOR)
	cbt_hide_excluded.set_pressed_no_signal(true)


func _on_popup() -> void:
	lb_warnings.hide()
	_update_button(btn_ok, false)
	tr_maps.grab_focus()
	_build_list()


func _build_list() -> void:
	var mission := fms.curr_mission

	var map_files := Path.get_filepaths_filtered(mission.paths.maps,
		func(filename:String) -> bool:
			return filename.get_extension() == "map"
	)

	tr_maps.clear()
	#tr_maps.columns = 1

	var _root := tr_maps.create_item()
	var item:TreeItem

	for i:int in map_files.size():
		var path := map_files[i]

		var is_included := not mission.ignored_files.contains(path)
		if cbt_hide_excluded.button_pressed and not is_included:
			continue

		var map_filename := path.get_file()
		var is_loaded   := map_filename.get_basename() in mission.mdata.map_files
		var idx  := i % tr_maps.columns

		if idx == 0:
			item = _root.create_child()
			for j:int in tr_maps.columns:
				item.set_selectable(j, false)

		if   i == 0:                  _first_item = item
		elif i == map_files.size()-1: _last_item  = item

		item.set_text(idx, map_filename)
		item.set_icon_max_width(idx, 20)

		var icon       : Texture2D
		var color      : Color
		var icon_color : Color

		if not is_included:
			color      = data.FADED_TEXT_COLOR
			icon       = data.ICON_MAP
			icon_color = data.FADED_TEXT_COLOR
		elif is_loaded:
			color      = _LOADED_COLOR
			icon       = data.ICON_MAP_LOADED
			icon_color = _LOADED_COLOR
		else:
			color      = data.TEXT_COLOR
			item.set_selectable(idx, true)
			icon       = data.ICON_MAP
			icon_color = _ICON_COLOR

		item.set_icon(idx, icon)
		item.set_custom_color(idx, color)
		item.set_icon_modulate(idx, icon_color)
		item.set_metadata(idx, is_included)


func _on_input(event: InputEvent) -> void:
	if   event.is_action_pressed("ui_home"):
		_select_first_item()
	elif event.is_action_pressed("ui_end"):
		_select_last_item()
	elif event.is_action_pressed("ui_cancel"):
		_on_bar_button_pressed(BarButton.CANCEL)


func _on_bar_button_pressed(idx:int) -> void:
	if idx != BarButton.CANCEL:
		if not await _validate_selected_maps():
			return
		_commit_data()

	if idx != BarButton.APPLY:
		close_requested.emit()


func _commit_data() -> void:
	logs.print(_selected_maps)
	var maps:Array[String]

	for map_filename:String in _selected_maps:
		maps.append(map_filename.get_basename())

	for map_name:String in maps:
		if fms.curr_mission.add_map_file(map_name):
			pack_tab.add_map(map_name)

	fms.start_save_timer(true)


func _on_close() -> void:
	_selected_maps.clear()


func _hack_to_force_tree_to_update_visuals() -> void:
	tr_maps.visible = false
	tr_maps.visible = true


func _select_first_item() -> void:
	tr_maps.set_selected(_first_item, 0)
	tr_maps.ensure_cursor_is_visible()
	_hack_to_force_tree_to_update_visuals()


func _select_last_item() -> void:
	for i:int in range(tr_maps.columns-1, -1, -1):
		if _last_item.is_selectable(i):
			tr_maps.set_selected(_last_item, i)
			break
	tr_maps.ensure_cursor_is_visible()
	_hack_to_force_tree_to_update_visuals()




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#	signals

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_tr_maps_cell_selected() -> void:
	_update_button(btn_ok, true)


func _validate_selected_maps() -> bool:
	var to_load := 0

	for map_name:String in _selected_maps:
		var is_valid: bool = _selected_maps[map_name]
		logs.print("is_valid", is_valid)
		if not is_valid:
			popups.show_confirmation({
				text = "Folder '%s' has no 'darkmod.txt'.\nCreate a new one?" % map_name,
			})
			if not await popups.confirmation_dialog.answer:
				continue
		to_load += 1

	return to_load == _selected_maps.size()


func _on_tr_maps_item_activated() -> void:
	_on_bar_button_pressed(BarButton.OK)


func _on_tr_maps_multi_selected(item: TreeItem, column: int, selected: bool) -> void:
	var item_text: String = item.get_text(column)
	if selected:
		if not item_text in _selected_maps:
			_selected_maps[item_text] = item.get_metadata(column)
	else:
		_selected_maps.erase(item_text)


func _on_cbt_hide_excluded_pressed() -> void:
	_build_list()
