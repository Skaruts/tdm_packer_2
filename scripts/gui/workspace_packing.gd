extends BaseWorkspace

signal tab_changed


@onready var file_dialog: FileDialog = $file_dialog


@onready var pk4_files_tree: Tree = %pk4_files_tree
@onready var excluded_files_tree: Tree = %excluded_files_tree

@onready var pkignore_editor: CodeEdit = %pkignore_editor
@onready var modfile_text_edit: CodeEdit = %modfile_text_edit
@onready var readme_text_edit: CodeEdit = %readme_text_edit

@onready var pk_4_label: Label = %pk4_label
@onready var pk_4_files_tree: Tree = %pk4_files_tree

@onready var pkignore_label: Label = %pkignore_label
@onready var modfile_text_label: Label = %modfile_text_label
@onready var readme_text_label: Label = %readme_text_label


@onready var map_list: ItemList = $tabs/Info/VSplitContainer/maps/map_list
@onready var remove_map_btn: Button = %remove_map_btn


var curr_editor:Variant = null



class ModfileHighlighter extends CodeHighlighter:
	const KWS = ["Title", "Description", "Author", "Authors", "Required TDM Version", "Version"]
	func _init() -> void:
		function_color = data.TEXT_COLOR
		member_variable_color = data.TEXT_COLOR
		number_color = Color(0.917, 0.55, 1) # TODO: this isn't working, the function below conflicts with these things
		symbol_color = data.TEXT_COLOR

		#for kw:String in ["Title", "Description", "Author", "Authors", "Mission", "Required", "TDM", "Version"]:
			#add_keyword_color(kw, Color("73ff63"))

	func _get_line_syntax_highlighting(idx: int) -> Dictionary:
		var color_map: Dictionary
		var text_editor:CodeEdit = get_text_edit()
		var line:String = text_editor.get_line(idx)

		var colon_idx := line.find(':')

		if colon_idx != -1:
			var str := line.left(colon_idx).strip_edges()
			if str in KWS:
				color_map[0] = { "color": Color("73ff63") }
				color_map[colon_idx+1] = { "color": data.TEXT_COLOR }
			elif str.begins_with("Mission") and str.ends_with("Title"):
				var parts := str.split(' ', false)
				if parts.size() == 3 and parts[1].is_valid_int():
					color_map[0] = { "color": Color("73ff63") }
					color_map[colon_idx+1] = { "color": data.TEXT_COLOR }


		return color_map



var current_tab :int:
	get: return %tabs.current_tab
	set(index): %tabs.current_tab = index





func init(mission:Mission) -> void:
	super(mission)

	pkignore_editor.syntax_highlighter = pkignore_editor.syntax_highlighter.duplicate()
	pkignore_editor.text = _mission.pkignore
	pkignore_editor.clear_undo_history() # remove the text change above from undo history
	pkignore_editor.tag_saved_version()

	modfile_text_edit.syntax_highlighter = ModfileHighlighter.new()
	modfile_text_edit.text = _mission.modfile
	modfile_text_edit.clear_undo_history()
	modfile_text_edit.tag_saved_version()

	readme_text_edit.text = _mission.readme
	readme_text_edit.clear_undo_history()
	readme_text_edit.tag_saved_version()

	remove_map_btn.disabled = true

	_build_trees()
	_build_map_list()


func _build_map_list() -> void:
	map_list.clear()
	for map in _mission.map_names:
		map_list.add_item(map)
	#map_list.deselect_all()
	#remove_map_btn.disabled = true


func _init_signals() -> void:
	fm_manager.mission_reloaded.connect(_on_mission_reloaded)
	fm_manager.mission_saved.connect(_on_mission_saved)

func _on_mission_saved() -> void:
	if _mission != fm_manager.curr_mission: return
	_update_label(pkignore_label, data.IGNORES_FILENAME, false)
	_update_label(modfile_text_label, data.MODFILE_FILENAME, false)
	_update_label(readme_text_label, data.README_FILENAME, false)
	pkignore_editor.tag_saved_version()
	modfile_text_edit.tag_saved_version()
	readme_text_edit.tag_saved_version()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_file"):
		save_current_file()


func save_current_file() -> void:
	if curr_editor == null: return

	var dirty:bool = curr_editor.get_version() != curr_editor.get_saved_version()
	if not dirty: return

	if curr_editor == pkignore_editor:
		fm_manager.save_pkignore(_mission)
		_update_label(pkignore_label, data.IGNORES_FILENAME, false)
	elif curr_editor == modfile_text_edit:
		fm_manager.save_modfile(_mission)
		_update_label(modfile_text_label, data.MODFILE_FILENAME, false)
	elif curr_editor == readme_text_edit:
		fm_manager.save_readme(_mission)
		_update_label(readme_text_label, data.README_FILENAME, false)

	curr_editor.tag_saved_version()


func select_previous_available() -> void:
	%tabs.select_previous_available()

func select_next_available() -> void:
	%tabs.select_next_available()


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Trees

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _build_trees() -> void:
	logs.task("Building GUI trees for '%s'..." % _mission.id)

	pk4_files_tree.clear()
	excluded_files_tree.clear()

	var inc_tree_root := pk4_files_tree.create_item()
	#inc_tree_root.set_text(0, _mission.zipname)
	pk_4_label.text = _mission.zipname

	var exc_tree_root := excluded_files_tree.create_item()
	#exc_tree_root.set_text(0, "... /" + _mission.id)

	#var t1 := Time.get_ticks_msec()

	_build_inc_tree(_mission.file_tree, inc_tree_root)
	_build_exc_tree(_mission.file_tree, exc_tree_root)

	if not Path.dir_exists(_mission.path_maps) \
	or not _mission.file_tree.get_child_named("maps").has_included_files():
		console.warning("mission '%s' has no valid maps" % _mission.id)

	#var t2 := Time.get_ticks_msec()
	#var total_time := "%.5f" % [(t2-t1)/1000]

	#logs.task("... finished building trees (%s)" % [total_time])


func _build_inc_tree(mroot:FMTreeNode, gui_root:TreeItem) -> void:
	for tn:FMTreeNode in mroot.children:
		if tn.ignored: continue

		var icon := preloads.FOLDER_ICON if tn.is_dir else preloads.FILE_ICON
		var gui_tree_item:TreeItem

		if tn.is_dir and tn.name == "maps" and not tn.has_included_files():
			#console.warning("mission '%s' has no valid maps" % _mission.id)
			gui_tree_item = _create_node(pk4_files_tree, tn.name, gui_root, icon, data.ERROR_COLOR)
		else:
			gui_tree_item = _create_node(pk4_files_tree, tn.name, gui_root, icon)

		_build_inc_tree(tn, gui_tree_item)


func _build_exc_tree(mroot:FMTreeNode, gui_root:TreeItem) -> void:
	for c:FMTreeNode in mroot.children:
		if c.is_dir:
			if not c.has_ignored_files():
				continue
		elif not c.ignored:
			continue

		var icon := preloads.FOLDER_ICON if c.is_dir else preloads.FILE_ICON
		var gui_tree_item := _create_node(excluded_files_tree, c.name, gui_root, icon)
		_build_exc_tree(c, gui_tree_item)


func _create_node(tree:Tree, text:String, root:TreeItem, icon:Texture2D, color:Variant=null) -> TreeItem:
	var node := tree.create_item(root)
	node.set_text(0, text)
	if color:
		node.set_custom_color(0, color as Color)
		#node.set_icon_modulate(0, color)
	node.set_icon(0, icon)
	node.set_icon_max_width(0, 16)

	node.collapsed = true
	return node





#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Signals

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_mission_reloaded() -> void:
	if _mission != fm_manager.curr_mission:return

	pkignore_editor.text = _mission.pkignore
	modfile_text_edit.text = _mission.modfile
	readme_text_edit.text = _mission.readme

	pkignore_editor.tag_saved_version()
	modfile_text_edit.tag_saved_version()
	readme_text_edit.tag_saved_version()

	_build_trees()
	_build_map_list()


func _on_pk4_files_tree_item_activated() -> void:
	#if pk4_files_tree.
	#logs.print("tree item activated", pk4_files_tree.get_selected().get_text(0))
	# TODO: open files in the editing workspace
	pass

func _on_tabs_tab_changed(index: int) -> void:
	tab_changed.emit(index)




func _update_label(label:Label, text:String, dirty:bool) -> void:
	label.text = text
	if dirty:
		label.text += " (*)"
		label.set("theme_override_colors/font_color", data.EDITED_FILE_COLOR)
	else:
		label.set("theme_override_colors/font_color", data.TEXT_COLOR)




func _on_pkignore_editor_text_changed() -> void:
	var dirty:bool = pkignore_editor.get_version() != pkignore_editor.get_saved_version()
	_update_label(pkignore_label, data.IGNORES_FILENAME, dirty)
	_mission.update_pkignore(pkignore_editor.text, dirty)

func _on_modfile_text_edit_text_changed() -> void:
	#logs.print(modfile_text_edit.has_undo())
	var dirty:bool = modfile_text_edit.get_version() != modfile_text_edit.get_saved_version()
	_update_label(modfile_text_label, data.MODFILE_FILENAME, dirty)
	_mission.update_modfile(modfile_text_edit.text, dirty)

func _on_readme_text_edit_text_changed() -> void:
	var dirty:bool = readme_text_edit.get_version() != readme_text_edit.get_saved_version()
	_update_label(readme_text_label, data.README_FILENAME, dirty)
	_mission.update_readme(readme_text_edit.text, dirty)


func _on_modfile_text_edit_focus_entered() -> void:
	modfile_text_edit.highlight_current_line = true
	curr_editor = modfile_text_edit
func _on_modfile_text_edit_focus_exited() -> void:
	modfile_text_edit.highlight_current_line = false
	curr_editor = null

func _on_readme_text_edit_focus_entered() -> void:
	readme_text_edit.highlight_current_line = true
	curr_editor = readme_text_edit
func _on_readme_text_edit_focus_exited() -> void:
	readme_text_edit.highlight_current_line = false
	curr_editor = null

func _on_pkignore_editor_focus_entered() -> void:
	pkignore_editor.highlight_current_line = true
	curr_editor = pkignore_editor
func _on_pkignore_editor_focus_exited() -> void:
	pkignore_editor.highlight_current_line = false
	curr_editor = null



func _on_add_map_btn_pressed() -> void:
	var maps_dir := fm_manager.curr_mission.path_maps
	file_dialog.open({
		title = "Choose Map",
		dir = maps_dir,
		root = maps_dir,
		mode = FileDialog.FILE_MODE_OPEN_FILE,
		filters = ["*.map;Map Files"],
	})

	var filepath:String = await file_dialog.file_selected
	logs.info(filepath)

	if filepath:
		var map_name := filepath.get_basename().get_file()
		if _mission.add_map(map_name):
			map_list.add_item(map_name)
			fm_manager.save_maps_file(_mission)

	#remove_map_btn.disabled = false


func _on_remove_map_btn_pressed() -> void:
	var items := map_list.get_selected_items()
	if not items.size(): return
	var idx := items[0]
	var map_name := map_list.get_item_text(idx)

	if _mission.remove_map(map_name):
		map_list.remove_item(idx)
		fm_manager.save_maps_file(_mission)
	remove_map_btn.disabled = not map_list.item_count




#func _update_mission_maps() -> void:
	#if not map_list.item_count: return
	#var str:String = map_list.get_item_text(0)
	#for i in range(1, map_list.item_count):
		#str += ',' + map_list.get_item_text(i)
	#_mission.update_map_names(str, true)


func _on_map_list_item_selected(index: int) -> void:
	remove_map_btn.disabled = false


func _on_map_list_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	map_list.deselect_all()
	remove_map_btn.disabled = true


#func _on_map_list_focus_exited() -> void:
	#logs.print("_on_map_list_focus_exited")
	#map_list.deselect_all()
	#remove_map_btn.disabled = true

