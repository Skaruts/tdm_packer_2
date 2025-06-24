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

@onready var btn_add_map    : Button = %btn_add_map
@onready var btn_remove_map : Button = %btn_remove_map

@onready var tr_included   : Tree  = %tr_included
@onready var tr_excluded   : Tree  = %tr_excluded
@onready var lb_included   : Label = %lb_included
@onready var lb_excluded   : Label = %lb_excluded

#@onready var map_list: ItemList = %map_list
@onready var tr_map_list : Tree  = %tr_map_list

@onready var btn_move_up   : Button = %btn_move_up
@onready var btn_move_down : Button = %btn_move_down


var curr_editor: CodeEdit
var _mission: Mission
var _tree_root:TreeItem

var tree_alignment := HORIZONTAL_ALIGNMENT_LEFT




func _add_map_tree_item(filename:String, title:="") -> TreeItem:
	var item := _tree_root.create_child()
	item.set_editable(0, false)
	item.set_editable(1, true)

	item.set_text_alignment(0, tree_alignment)
	item.set_text_alignment(1, tree_alignment)

	item.set_text(0, filename)
	#item.set_icon(0, data.ICON_FILE)
	#item.set_icon_max_width(0, 16)

	item.set_custom_color(1, Color(0.82, 0.698, 0.361))# Color.GOLDENROD)
	item.set_text(1, title)

	return item


func _ready() -> void:
	tr_map_list.columns = 2
	tr_map_list.hide_root = true
	tr_map_list.set_column_title(0, "Map")
	tr_map_list.set_column_title(1, "Title")
	tr_map_list.set_column_expand(0, true)
	tr_map_list.set_column_expand(1, true)
	tr_map_list.set_column_expand_ratio(1, 2)
	#tr_map_list.set_column_custom_minimum_width(0, 150)
	tr_map_list.set_column_title_alignment(0, tree_alignment)
	tr_map_list.set_column_title_alignment(1, tree_alignment)

	tr_map_list.button_clicked.connect(
		func(item:TreeItem, col:int, id:int, mouse_btn_idx:int) -> void:
			logs.print(id)
			pass
	)

	tr_map_list.item_edited.connect(
		func() -> void:
			logs.print("item was edited")
			var item := tr_map_list.get_edited()
			if _mission.set_map_title(item.get_index(), item.get_text(1)):
				fms.start_save_timer(false)
	)
	tr_map_list.item_selected.connect( _set_button_states.bind(true) )
	tr_map_list.empty_clicked.connect(
		func(_click_position: Vector2, _mouse_button_index: int) -> void:
			tr_map_list.deselect_all()
			_set_button_states(false)
	)
	#tr_map_list.focus_exited.connect(
		#func() -> void:
			##await get_tree().create_timer(0.5).timeout
			#await get_tree().process_frame
			#tr_map_list.deselect_all()
	#)

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
	btn_move_up.pressed.connect(_on_move_arrow_pressed.bind("move_up"))
	btn_move_down.pressed.connect(_on_move_arrow_pressed.bind("move_down"))
	_set_button_states(false)




func _on_move_arrow_pressed(direction:String) -> void:
	var item     := tr_map_list.get_selected()
	assert(item != null)
	var idx      := item.get_index()

	if _mission.move_map(direction, idx):
		fms.start_save_timer(false)
		_build_map_list()
		var new_item := _tree_root.get_child(idx-1)
		if   direction == "move_up":   tr_map_list.set_selected(new_item, 0)
		elif direction == "move_down": tr_map_list.set_selected(new_item, 0)



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

	_set_button_states(false)

	_build_trees()
	_build_map_list()
	set_show_roots(data.config.show_tree_roots)




func _set_button_states(enabled:bool) -> void:
	btn_remove_map.disabled = not enabled
	btn_move_up.disabled    = not enabled
	btn_move_down.disabled  = not enabled

	btn_remove_map.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	btn_move_up.focus_mode    = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	btn_move_down.focus_mode  = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE





func _build_map_list() -> void:
	var item := tr_map_list.get_selected()
	var idx:int = item.get_index() if item else -1

	#logs.print("_build_map_list")
	tr_map_list.clear()
	_tree_root = tr_map_list.create_item()
	for i:int in _mission.mdata.map_files.size():
		var filename := _mission.mdata.map_files[i]
		var title    := "" if _mission.mdata.map_titles.size() <= i else _mission.mdata.map_titles[i]
		_add_map_tree_item(filename, title)

	if idx > -1:
		tr_map_list.set_selected( _tree_root.get_child(idx), 0)

func on_mission_reloaded(force_update:=false) -> void:
	if _mission != fms.curr_mission and not force_update:
		return

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
	#le_title.tag_saved_version()
	#le_author.tag_saved_version()
	#le_version.tag_saved_version()
	#le_tdm_version.tag_saved_version()

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
			logs.print(_mission.mdata.map_files)
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
			fms.start_save_timer(false)
		ce_readme:
			var dirty:bool = ce_readme.get_version() != ce_readme.get_saved_version()
			_mission.update_readme(ce_readme.text, dirty)
			fms.start_save_timer(false)
		ce_pkignore:
			var dirty:bool = ce_pkignore.get_version() != ce_pkignore.get_saved_version()
			_mission.update_pkignore(ce_pkignore.text, dirty)
			fms.start_save_timer(true)



func _on_line_edit_text_changed(new_text:String, ledit:LineEdit) -> void:
	match ledit:
		le_title:
			_mission.update_title(new_text, true)
			fms.start_save_timer(false)
		le_author:
			_mission.update_author(new_text, true)
			fms.start_save_timer(false)
		le_version:
			_mission.update_version(new_text, true)
			update_tree_root_pack_name()
			fms.start_save_timer(false)
		le_tdm_version:
			_mission.update_tdm_version(new_text, true)
			fms.start_save_timer(false)


func add_map(map_name:String) -> void:
	_add_map_tree_item(map_name)
	tr_map_list.set_selected( _tree_root.get_child(-1), 0 )

func _on_btn_add_map_pressed() -> void:
	popups.add_map.pack_tab = self
	popups.show_popup(popups.add_map)

	#popups.open_single_file({
			#title = "Choose Map",
			#root_subfolder = _mission.paths.maps,
			#filters = ["*.map;Map Files"],
		#},
		#func(path:String) -> void:
			#logs.info(path)
			#var map_filename := path.get_basename().get_file()
			#if _mission.add_map_file(map_filename):
				#_add_map_tree_item(map_filename)
				#fms.start_save_timer(true)
				#tr_map_list.set_selected( _tree_root.get_child(-1), 0 )
	#)


func _on_btn_remove_map_pressed() -> void:
	# NOTE: the map list shouldn't allow selecting multiple files
	var item := tr_map_list.get_selected()
	assert(item != null)
	var idx := item.get_index()

	var filename := item.get_text(0)
	var title    := item.get_text(1)

	if _mission.remove_map_file(filename):
		_tree_root.remove_child(item)
		fms.start_save_timer(true)

	if _tree_root.get_child_count() == 0:
		_set_button_states(false)
	else:
		idx = clamp(idx, 0, _tree_root.get_child_count()-1)
		tr_map_list.set_selected( _tree_root.get_child(idx), 0 )


func set_show_roots(enabled:bool) -> void:
	tr_included.hide_root = not enabled
	tr_excluded.hide_root = not enabled
	if enabled:
		lb_included.text = "Files"
		lb_excluded.text = ""
	else:
		lb_included.text = _mission.zipname
		lb_excluded.text = "Excluded Files"



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Build Trees

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func update_tree_root_pack_name() -> void:
	var root := tr_included.get_root()
	root.set_text(0, _mission.zipname)


func _build_trees() -> void:
	logs.task("Building GUI trees for %s..." % _mission.id)

	tr_included.set_column_title(0, "%d dirs, %d files" % [_mission.inc_dir_count, _mission.inc_file_count])
	tr_excluded.set_column_title(0, "%d dirs, %d files" % [_mission.exc_dir_count, _mission.exc_file_count])

	tr_included.clear()
	tr_excluded.clear()

	var inc_tree_root := tr_included.create_item()
	inc_tree_root.set_text(0, _mission.zipname)
	inc_tree_root.set_custom_color(0, data.EDITED_FILE_COLOR)
	#lb_included.text = _mission.zipname

	var exc_tree_root := tr_excluded.create_item()
	exc_tree_root.set_text(0, "Excluded Files")
	exc_tree_root.set_custom_color(0, data.EDITED_FILE_COLOR)

	var t1 := Time.get_ticks_msec()

	_build_inc_tree(_mission.file_tree, inc_tree_root)
	_build_exc_tree(_mission.file_tree, exc_tree_root)

	if not Path.dir_exists(_mission.paths.maps) \
	or not _mission.file_tree.get_child_named("maps").has_included_files():
		console.warning("%s has no valid maps" % _mission.id)

	var t2 := Time.get_ticks_msec()
	var total_time := "%.5f" % [(t2-t1)/1000.0]
	logs.task("... finished building trees (%s)" % [total_time])


func _build_inc_tree(parent: FMTreeNode, gui_parent: TreeItem) -> void:
	for node: FMTreeNode in parent.children:
		if node.ignored: continue

		var icon := data.ICON_FOLDER if node.is_dir else data.ICON_FILE
		var tree_item: TreeItem

		var maps_path := _mission.paths.maps

		if not node.is_dir:
			if parent.path != maps_path:
				tree_item = _create_node(gui_parent, node.name, icon)
			else:
				var map_name := node.name.get_basename()
				if map_name in _mission.mdata.map_files:
					tree_item = _create_node(gui_parent, node.name, icon)
		else:
			if node.path != maps_path:
				tree_item = _create_node(gui_parent, node.name, icon)
			elif node.has_included_files():
				tree_item = _create_node(gui_parent, node.name, icon)
			else:
				tree_item = _create_node(gui_parent, node.name, icon, data.ERROR_COLOR)


		# if not (node.is_dir and node.path != maps_path):
		# 	tree_item = _create_node(tr_included, node.name, gui_parent, icon)
		# else:
		# 	if node.has_included_files():
		# 		tree_item = _create_node(tr_included, node.name, gui_parent, icon)
		# 	else:
		# 		tree_item = _create_node(tr_included, node.name, gui_parent, icon, data.ERROR_COLOR)

		_build_inc_tree(node, tree_item)


func _build_exc_tree(parent:FMTreeNode, gui_parent:TreeItem) -> void:
	for node: FMTreeNode in parent.children:
		var maps_path := _mission.paths.maps

		if node.is_dir:
			if not node.has_ignored_files():
				continue
		elif not node.ignored and parent.path != maps_path:
			continue

		var map_sequence := _mission.mdata.map_files
		var icon := data.ICON_FOLDER if node.is_dir else data.ICON_FILE
		var tree_item : TreeItem
		if not (not node.is_dir and parent.path == maps_path):
			tree_item = _create_node(gui_parent, node.name, icon)
		else:
			if node.ignored or not node.name.get_basename() in map_sequence:
				tree_item = _create_node(gui_parent, node.name, icon)

		_build_exc_tree(node, tree_item)


func _create_node(parent:TreeItem, text:String, icon:Texture2D, color:Variant=null) -> TreeItem:
	var node := parent.create_child()
	node.set_text(0, text)
	if color:
		node.set_custom_color(0, color)
		#node.set_icon_modulate(0, color)
	node.set_icon(0, icon)
	node.set_icon_max_width(0, 16)

	node.collapsed = true
	return node
