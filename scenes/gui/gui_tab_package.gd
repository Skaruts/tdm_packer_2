class_name GuiTabPackage
extends TabContainer


enum EditorIndex {
	# modfile
	Title,
	Author,
	Version,
	TDM_Version,
	Description,
	# other
	Readme,
	PkIgnore,
}


@onready var le_title       : LineEdit = %le_title
@onready var le_author      : LineEdit = %le_author
@onready var le_version     : LineEdit = %le_version
@onready var le_tdm_version : LineEdit = %le_tdm_version

@onready var ce_description : CodeEdit = %ce_description
@onready var ce_readme      : CodeEdit = %ce_readme
@onready var ce_pkignore    : CodeEdit = %ce_pkignore

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

	#cedit_modfile.syntax_highlighter = ModfileHighlighter.new()


	var cedits := [ ce_description, ce_readme, ce_pkignore ]
	for i in cedits.size():
		var ed:Variant = cedits[i]
		ed.text_changed.connect(_on_code_editor_text_changed.bind(ed))
		ed.focus_entered.connect(_on_code_editor_focus_changed.bind(ed, true))
		ed.focus_exited.connect(_on_code_editor_focus_changed.bind(ed, false))

	var ledits := [ le_title, le_author, le_version, le_tdm_version ]
	for i in ledits.size():
		var ed:LineEdit = ledits[i]
		#ed.gui_input.connect(_on_ledit_gui_input.bind(i + EditorIndex.Title))
		ed.text_changed.connect(_on_line_edit_text_changed.bind(ed))


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




func set_mission(mission: Mission) -> void:
	_mission = mission

	#le_title.clear_undo_history()
	#le_author.clear_undo_history()
	#le_version.clear_undo_history()
	#le_tdm_version.clear_undo_history()

	#le_title.tag_saved_version()
	#le_author.tag_saved_version()
	#le_version.tag_saved_version()
	#le_tdm_version.tag_saved_version()

	le_title.text       = _mission.mdata.title
	le_author.text      = _mission.mdata.author
	le_version.text     = _mission.mdata.version
	le_tdm_version.text = _mission.mdata.tdm_version

	ce_description.text = _mission.mdata.description
	ce_description.clear_undo_history()
	ce_description.tag_saved_version()

	ce_pkignore.syntax_highlighter = ce_pkignore.syntax_highlighter.duplicate()
	ce_pkignore.text = _mission.mdata.pkignore
	ce_pkignore.clear_undo_history()
	ce_pkignore.tag_saved_version()

	ce_readme.text = _mission.mdata.readme
	ce_readme.clear_undo_history()
	ce_readme.tag_saved_version()

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

	le_title.text       = _mission.mdata.title
	le_author.text      = _mission.mdata.author
	le_version.text     = _mission.mdata.version
	le_tdm_version.text = _mission.mdata.tdm_version

	ce_description.text = _mission.mdata.description
	ce_readme.text      = _mission.mdata.readme
	ce_pkignore.text    = _mission.mdata.pkignore

	ce_description.tag_saved_version()
	ce_readme.tag_saved_version()
	ce_pkignore.tag_saved_version()
	le_title.tag_saved_version()
	le_author.tag_saved_version()
	le_version.tag_saved_version()
	le_tdm_version.tag_saved_version()

	_build_trees()
	_build_map_list()


func reload_file(filename:String) -> void:
	logs.print("reloading file ", filename)
	match filename:
		"modfile":
			le_title.text       = _mission.mdata.title
			le_author.text      = _mission.mdata.author
			le_version.text     = _mission.mdata.version
			le_tdm_version.text = _mission.mdata.tdm_version
			ce_description.text = _mission.mdata.description

			ce_description.tag_saved_version()
			#le_title.tag_saved_version()
			#le_author.tag_saved_version()
			#le_version.tag_saved_version()
			#le_tdm_version.tag_saved_version()

		"readme":
			logs.print("updating readme")
			ce_readme.text = _mission.mdata.readme
			ce_readme.tag_saved_version()

		"pkignore":
			ce_pkignore.text = _mission.mdata.pkignore
			ce_pkignore.tag_saved_version()

		"map_sequence":
			logs.print(_mission.map_sequence)
			_build_map_list()


func _on_code_editor_focus_changed(editor:CodeEdit, focused:bool) -> void:
	curr_editor = null
	ce_description.highlight_current_line = false
	ce_readme.highlight_current_line = false
	ce_pkignore.highlight_current_line = false

	if not focused: return

	editor.highlight_current_line = true
	curr_editor = editor


func _on_code_editor_text_changed(editor:CodeEdit) -> void:
	match editor:
		ce_description:
			var dirty:bool = ce_description.get_version() != ce_description.get_saved_version()
			_mission.update_description(ce_description.text, dirty)
		ce_readme:
			var dirty:bool = ce_readme.get_version() != ce_readme.get_saved_version()
			_mission.update_readme(ce_readme.text, dirty)
		ce_pkignore:
			var dirty:bool = ce_pkignore.get_version() != ce_pkignore.get_saved_version()
			_mission.update_pkignore(ce_pkignore.text, dirty)

	fms.start_save_timer()



#func _on_ledit_gui_input(event:InputEvent, idx:int) -> void:
	#if not event is InputEventKey: return
	#match idx:
		#EditorIndex.Title:
			#_mission.update_title(le_title.text, true)
			#fms.start_save_timer()
		#EditorIndex.Author:
			#_mission.update_author(le_author.text, true)
			#fms.start_save_timer()
		#EditorIndex.Version:
			#_mission.update_version(le_version.text, true)
			#fms.start_save_timer()
		#EditorIndex.TDM_Version:
			#_mission.update_tdm_version(le_tdm_version.text, true)
			#fms.start_save_timer()


func _on_line_edit_text_changed(new_text:String, ledit:LineEdit) -> void:
	match ledit:
		le_title:
			_mission.update_title(new_text, true)
			fms.start_save_timer()
		le_author:
			_mission.update_author(new_text, true)
			fms.start_save_timer()
		le_version:
			_mission.update_version(new_text, true)
			fms.start_save_timer()
		le_tdm_version:
			_mission.update_tdm_version(new_text, true)
			fms.start_save_timer()


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
