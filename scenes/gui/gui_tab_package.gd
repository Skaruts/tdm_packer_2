class_name GuiTabPackage
extends TabContainer



class ModfileHighlighter extends CodeHighlighter:
	const KWS = [
		"Title", "Description", "Author", "Authors",
		"Required TDM Version", "Version",
	]
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
			var string := line.left(colon_idx).strip_edges()
			if string in KWS:
				color_map[0] = { "color": Color("73ff63") }
				color_map[colon_idx+1] = { "color": data.TEXT_COLOR }
			elif string.begins_with("Mission") and string.ends_with("Title"):
				var parts := string.split(' ', false)
				if parts.size() == 3 and parts[1].is_valid_int():
					color_map[0] = { "color": Color("73ff63") }
					color_map[colon_idx+1] = { "color": data.TEXT_COLOR }


		return color_map



enum EditorIndex {
	Modfile,
	Readme,
	PkIgnore,
}




@onready var cedit_modfile: CodeEdit = %cedit_modfile
@onready var cedit_readme: CodeEdit = %cedit_readme
@onready var cedit_pkignore: CodeEdit = %cedit_pkignore

#@onready var label_modfile: Label = %label_modfile
#@onready var label_readme: Label = %label_readme
#@onready var label_pkignore: Label = %label_pkignore

@onready var btn_add_map: Button = %btn_add_map
@onready var btn_remove_map: Button = %btn_remove_map

@onready var tree_included_files: Tree = %tree_included_files
@onready var tree_excluded_files: Tree = %tree_excluded_files
@onready var label_included_files: Label = %label_included_files
@onready var label_excluded_files: Label = %label_excluded_files

@onready var map_list: ItemList = %map_list


var curr_editor: CodeEdit
var _mission: Mission



func _ready() -> void:
	btn_remove_map.disabled = map_list.item_count == 0

	# remove font color, it's only for viewing the syntax in the editor
	cedit_modfile.set("theme_override_colors/font_color", null)
	cedit_modfile.syntax_highlighter = ModfileHighlighter.new()

	cedit_modfile.text_changed.connect(_on_code_editor_text_changed.bind(EditorIndex.Modfile))
	cedit_readme.text_changed.connect(_on_code_editor_text_changed.bind(EditorIndex.Readme))
	cedit_pkignore.text_changed.connect(_on_code_editor_text_changed.bind(EditorIndex.PkIgnore))

	cedit_modfile.focus_entered.connect(_on_code_editor_focus_changed.bind(EditorIndex.Modfile, true))
	cedit_readme.focus_entered.connect(_on_code_editor_focus_changed.bind(EditorIndex.Readme, true))
	cedit_pkignore.focus_entered.connect(_on_code_editor_focus_changed.bind(EditorIndex.PkIgnore, true))

	cedit_modfile.focus_exited.connect(_on_code_editor_focus_changed.bind(EditorIndex.Modfile, false))
	cedit_readme.focus_exited.connect(_on_code_editor_focus_changed.bind(EditorIndex.Readme, false))
	cedit_pkignore.focus_exited.connect(_on_code_editor_focus_changed.bind(EditorIndex.PkIgnore, false))

	btn_add_map.pressed.connect(_on_btn_add_map_pressed)
	btn_remove_map.pressed.connect(_on_btn_remove_map_pressed)

	map_list.item_selected.connect(
		func(_index: int) -> void:
			btn_remove_map.disabled = false
	)

	map_list.empty_clicked.connect(
		func(_at_position: Vector2, _mouse_button_index: int) -> void:
			map_list.deselect_all()
			btn_remove_map.disabled = true
	)


#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("save"):
		#save_current_file()


func set_mission(mission: Mission) -> void:
	_mission = mission

	cedit_pkignore.syntax_highlighter = cedit_pkignore.syntax_highlighter.duplicate()
	cedit_pkignore.text = _mission.files.pkignore
	cedit_pkignore.clear_undo_history()
	cedit_pkignore.tag_saved_version()


	cedit_modfile.text = _mission.files.modfile
	cedit_modfile.clear_undo_history()
	cedit_modfile.tag_saved_version()

	cedit_readme.text = _mission.files.readme
	cedit_readme.clear_undo_history()
	cedit_readme.tag_saved_version()

	btn_remove_map.disabled = true

	_build_trees()
	_build_map_list()
	set_show_roots(data.config.show_tree_roots)



func _build_map_list() -> void:
	map_list.clear()
	for map_name in _mission.map_sequence:
		map_list.add_item(map_name)


func on_mission_reloaded() -> void:
	if _mission != fms.curr_mission: return

	cedit_modfile.text = _mission.files.modfile
	cedit_readme.text = _mission.files.readme
	cedit_pkignore.text = _mission.files.pkignore

	cedit_modfile.tag_saved_version()
	cedit_readme.tag_saved_version()
	cedit_pkignore.tag_saved_version()

	#_update_label(label_modfile,  data.MODFILE_FILENAME, false)
	#_update_label(label_readme,   data.README_FILENAME,  false)
	#_update_label(label_pkignore, data.IGNORES_FILENAME, false)

	_build_trees()
	_build_map_list()


# TODO: this function may not be needed
#func update_on_mission_saved() -> void:
	#if _mission != fms.curr_mission: return
#
	#_update_label(label_modfile, data.MODFILE_FILENAME, false)
	#_update_label(label_readme, data.README_FILENAME, false)
	#_update_label(label_pkignore, data.IGNORES_FILENAME, false)
	#cedit_modfile.tag_saved_version()
	#cedit_readme.tag_saved_version()
	#cedit_pkignore.tag_saved_version()


func save_current_file() -> void:
	if curr_editor == null: return

	var dirty:bool = curr_editor.get_version() != curr_editor.get_saved_version()
	if not dirty: return

	if curr_editor == cedit_modfile:
		fms.save_modfile(_mission)
		#_update_label(label_modfile, data.MODFILE_FILENAME, false)
	elif curr_editor == cedit_readme:
		fms.save_readme(_mission)
		#_update_label(label_readme, data.README_FILENAME, false)
	elif curr_editor == cedit_pkignore:
		fms.save_pkignore(_mission)
		#_update_label(label_pkignore, data.IGNORES_FILENAME, false)

	curr_editor.tag_saved_version()


func reload_file(filename:String) -> void:
	logs.print("reloading file ", filename)
	match filename:
		"modfile":
			cedit_modfile.text = _mission.files.modfile
			cedit_modfile.tag_saved_version()
			#_update_label(label_modfile, data.MODFILE_FILENAME, false)
		"readme":
			logs.print("updating readme")
			cedit_readme.text = _mission.files.readme
			cedit_readme.tag_saved_version()
			#_update_label(label_readme, data.README_FILENAME, false)
		"pkignore":
			cedit_pkignore.text = _mission.files.pkignore
			cedit_pkignore.tag_saved_version()
			#_update_label(label_pkignore, data.IGNORES_FILENAME, false)
		"map_sequence":
			logs.print(_mission.map_sequence)
			_build_map_list()






func _on_code_editor_focus_changed(idx:int, focused:bool) -> void:
	#logs.print("code_editor_focus_changed: ", idx, focused)
	if focused:
		match idx:
			EditorIndex.Modfile:
				cedit_modfile.highlight_current_line = true
				curr_editor = cedit_modfile
			EditorIndex.Readme:
				cedit_readme.highlight_current_line = true
				curr_editor = cedit_readme
			EditorIndex.PkIgnore:
				cedit_pkignore.highlight_current_line = true
				curr_editor = cedit_pkignore
	else:
		curr_editor = null
		match idx:
			EditorIndex.Modfile:  cedit_modfile.highlight_current_line = false
			EditorIndex.Readme:   cedit_readme.highlight_current_line = false
			EditorIndex.PkIgnore: cedit_pkignore.highlight_current_line = false






func _on_code_editor_text_changed(idx:int) -> void:
	match idx:
		EditorIndex.Modfile:
			var dirty:bool = cedit_modfile.get_version() != cedit_modfile.get_saved_version()
			#_update_label(label_modfile, data.MODFILE_FILENAME, dirty)
			_mission.update_modfile(cedit_modfile.text, dirty)
		EditorIndex.Readme:
			var dirty:bool = cedit_readme.get_version() != cedit_readme.get_saved_version()
			#_update_label(label_readme, data.README_FILENAME, dirty)
			_mission.update_readme(cedit_readme.text, dirty)
		EditorIndex.PkIgnore:
			var dirty:bool = cedit_pkignore.get_version() != cedit_pkignore.get_saved_version()
			#_update_label(label_pkignore, data.IGNORES_FILENAME, dirty)
			_mission.update_pkignore(cedit_pkignore.text, dirty)

	fms.start_save_timer()


#func _update_label(label:Label, text:String, dirty:bool) -> void:
	#if dirty:
		#label.text = text + " (*)"
		#label.set("theme_override_colors/font_color", data.EDITED_FILE_COLOR)
	#else:
		#label.text = text
		#label.set("theme_override_colors/font_color", data.TEXT_COLOR)



func _on_btn_add_map_pressed() -> void:
	popups.open_single_file({
			title = "Choose Map",
			root_subfolder = _mission.paths.maps,
			filters = ["*.map;Map Files"],
		},
		func(path:String) -> void:
			logs.info(path)
			var map_name := path.get_basename().get_file()
			if _mission.add_map(map_name):
				map_list.add_item(map_name)
				fms.save_maps_file(_mission)
	)


func _on_btn_remove_map_pressed() -> void:
	var items := map_list.get_selected_items()
	if not items.size(): return
	var idx := items[0]    # NOTE: the map list shouldn't allow selecting multiple files
	var map_name := map_list.get_item_text(idx)

	if _mission.remove_map(map_name):
		map_list.remove_item(idx)
		fms.save_maps_file(_mission)

	btn_remove_map.disabled = map_list.item_count == 0


func set_show_roots(enabled:bool) -> void:
	tree_included_files.hide_root = not enabled
	tree_excluded_files.hide_root = not enabled
	if enabled:
		label_included_files.text = "Files"
		label_excluded_files.text = ""
	else:
		label_included_files.text = _mission.zipname
		label_excluded_files.text = "Excluded Files"



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Build Trees

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _build_trees() -> void:
	logs.task("Building GUI trees for '%s'..." % _mission.id)

	tree_included_files.clear()
	tree_excluded_files.clear()

	var inc_tree_root := tree_included_files.create_item()
	inc_tree_root.set_text(0, _mission.zipname)
	inc_tree_root.set_custom_color(0, data.EDITED_FILE_COLOR)
	#label_included_files.text = _mission.zipname

	var exc_tree_root := tree_excluded_files.create_item()
	#exc_tree_root.set_text(0, "... /" + _mission.id)
	exc_tree_root.set_text(0, "Excluded Files")
	exc_tree_root.set_custom_color(0, data.EDITED_FILE_COLOR)

	#var t1 := Time.get_ticks_msec()

	_build_inc_tree(_mission.file_tree, inc_tree_root)
	_build_exc_tree(_mission.file_tree, exc_tree_root)

	if not Path.dir_exists(_mission.paths.maps) \
	or not _mission.file_tree.get_child_named("maps").has_included_files():
		console.warning("mission '%s' has no valid maps" % _mission.id)

	#var t2 := Time.get_ticks_msec()
	#var total_time := "%.5f" % [(t2-t1)/1000]

	#logs.task("... finished building trees (%s)" % [total_time])


func _build_inc_tree(mroot:FMTreeNode, gui_root:TreeItem) -> void:
	for tn:FMTreeNode in mroot.children:
		if tn.ignored: continue

		var icon := data.FOLDER_ICON if tn.is_dir else data.FILE_ICON
		var gui_tree_item:TreeItem

		if tn.is_dir and tn.name == "maps" and not tn.has_included_files():
			#console.warning("mission '%s' has no valid maps" % _mission.id)
			gui_tree_item = _create_node(tree_included_files, tn.name, gui_root, icon, data.ERROR_COLOR)
		else:
			gui_tree_item = _create_node(tree_included_files, tn.name, gui_root, icon)

		_build_inc_tree(tn, gui_tree_item)


func _build_exc_tree(mroot:FMTreeNode, gui_root:TreeItem) -> void:
	for c:FMTreeNode in mroot.children:
		if c.is_dir:
			if not c.has_ignored_files():
				continue
		elif not c.ignored:
			continue

		var icon := data.FOLDER_ICON if c.is_dir else data.FILE_ICON
		var gui_tree_item := _create_node(tree_excluded_files, c.name, gui_root, icon)
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
