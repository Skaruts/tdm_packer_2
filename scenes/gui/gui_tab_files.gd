class_name GuiTabFiles
extends TabContainer


const TextFileEditorScene := preload("res://scenes/gui/text_file_editor.tscn")


@onready var tc_editors: TabContainer = %tc_editors
@onready var tr_files: Tree = $HSplitContainer/VBoxContainer/tr_files


var _mission : Mission
var editors  : Dictionary[String, TextFileEditor]
# var dummy_editor: TextFileEditor

var syntax_highlighters: Array[SyntaxHighlighter]

var curr_tab_hovered_idx: int = 0

func _ready() -> void:
	# dummy_editor = tc_editors.get_child(0)
	tr_files.item_activated.connect(_on_tr_files_item_activated)

	var tab_bar := tc_editors.get_tab_bar()
	tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_NEVER
	tab_bar.max_tab_width = 150

	tab_bar.tab_close_pressed.connect(_on_tab_bar_tab_close_pressed)

	tab_bar.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton \
			and event.button_index == 3\
			and event.pressed:
				var lmp := tab_bar.get_local_mouse_position()
				var idx := tab_bar.get_tab_idx_at_point(lmp)
				if idx != -1:
					_on_tab_bar_tab_close_pressed(idx)
	)

	for c in tc_editors.get_children():
		c.queue_free()


func _on_tab_bar_tab_close_pressed(tab_idx: int) -> void:
	var tab := tc_editors.get_child(tab_idx)
	var node: FMTreeNode = tab.get_meta("node")
	_remove_editor(tab)

	# if editors.size() == 0:
	# 	tc_editors.add_child(dummy_editor)

	fms.remove_edited_file_from_mission(_mission, node.path)


func _on_tr_files_item_activated() -> void:
	var item := tr_files.get_selected()
	var node: FMTreeNode = item.get_metadata(0)
	if node.is_dir: return

	if node.path in editors:
		var idx := -1
		for i in tc_editors.get_child_count():
			var tab: Control = tc_editors.get_child(i)
			if tab.name == node.name.replace('.', '_'):
				idx = i
				break

		if idx >= 0:
			tc_editors.current_tab = idx

		return

	# if tc_editors.get_child(0) == dummy_editor:
	# 	tc_editors.remove_child(dummy_editor)

	fms.add_edited_file_to_mission(_mission, node.path)
	_add_editor_id_needed(node)
	_update_editor(node.path, _mission.mdata.edited_files[node.path])

	tc_editors.current_tab = tc_editors.get_child_count() - 1



func on_mission_reloaded(_force_update := false) -> void:
	logs.print("on_mission_reloaded")
	# TODO: update the syntax highlighters if mission is readonly or not

	var is_missing := fms.is_mission_missing(_mission.id)
	var is_readonly := fms.is_mission_readonly(_mission.id)
	var valid_mission := not is_missing and not is_readonly

	for ed: TextFileEditor in editors.values():
		if valid_mission:
			ed.tag_code_editor()
		ed.update_button_states()
		ed.update_colors()

	var tb: TabBar = tc_editors.get_tab_bar()
	tb.tab_close_display_policy = data.config.tab_close_buttons_mode

	if not is_missing:
		_reload_tree()
		_reload_tabs(_mission.file_tree)




# func update_pack_name() -> void:
# 	pass



func set_mission(mission: Mission) -> void:
	_mission = mission

	# pk_syntax_highlighter = ce_pkignore.syntax_highlighter.duplicate()
	# ce_pkignore.text = _mission.mdata.pkignore
	# ce_pkignore.clear_undo_history()
	# ce_pkignore.tag_saved_version()

	# ce_readme.text = _mission.mdata.readme
	# ce_readme.clear_undo_history()
	# ce_readme.tag_saved_version()

	# _update_buttons_states()


	var valid_mission := not fms.is_mission_missing(_mission.id) \
						 and not fms.is_mission_readonly(_mission.id)

	# ce_pkignore.syntax_highlighter = pk_syntax_highlighter if valid_mission else null

	# if not valid_mission:
	# 	tr_files.clear()
		# if not fms.is_mission_missing(_mission.id):
		# 	_update_buttons_states()
		# return

	_reload_tree()
	# _reload_tabs()

	_reload_tabs(_mission.file_tree)
	# for c: FMTreeNode in _mission.file_tree.children:


func _add_editor_id_needed(node: FMTreeNode) -> bool:
	if node.path in editors: return false
	var ed: TextFileEditor = TextFileEditorScene.instantiate()
	tc_editors.add_child(ed)
	ed.set_data(_mission, node.path)
	editors[node.path] = ed
	ed.name = node.name
	ed.set_meta("node", node)
	return true


func _update_editor(path: String, text: String) -> void:
	logs.print("_update_editor")
	editors[path].update_text(text)
	editors[path].update_colors()


func _remove_editor(tab: Control) -> void:
	var node: FMTreeNode = tab.get_meta("node")
	editors.erase(node.path)
	tab.queue_free()
	tc_editors.remove_child(tab)
	assert(editors.size() == tc_editors.get_child_count())


func _reload_tabs(parent: FMTreeNode) -> void:
	for node: FMTreeNode in parent.children:
		if not node.is_dir:
			if node.path in _mission.mdata.edited_files:
				var old_hash: String
				if _mission.has_edited_file(node.path):
					old_hash = _mission.get_file_hash(node.path)

				fms.add_edited_file_to_mission(_mission, node.path)

				var added_ed := _add_editor_id_needed(node)
				var hash_comp := old_hash == _mission.get_file_hash(node.path)
				if added_ed \
				or not hash_comp:
					_update_editor(node.path, _mission.mdata.edited_files[node.path])
		else:
			_reload_tabs(node)



func _reload_tree() -> void:
	tr_files.clear()
	var tr_files_root := tr_files.create_item()
	tr_files_root.set_text(0, _mission.id)

	var disabled := fms.is_mission_readonly(_mission.id)
	_build_file_tree(_mission.file_tree, tr_files_root, disabled)

	pass



const ALLOWED_FILES := [
	"txt", "md", "bat", "py", "gitignore", "log",
	"xd", "gui", "script", "def", "mtr", "prt", "skin", "xd",

	# "tga", "png", "jpg", "jpeg",    # TODO maybe
]

const RESTRICTED_FILES := [
	"readme.txt",
	"darkmod.txt",
	"map_sequence.txt",
	"startingmap.txt",
]

func _is_valid_file(node: FMTreeNode) -> bool:
	var ext := node.path.get_extension()
	if ext == "": return false
	return ext in ALLOWED_FILES and not node.name in RESTRICTED_FILES


func _dir_has_valid_files(node: FMTreeNode) -> bool:
	assert(node.is_dir)

	for c: FMTreeNode in node.children:
		if not c.is_dir:
			if _is_valid_file(c):
				return true
		elif _dir_has_valid_files(c):
			return true

	return false


func _build_file_tree(parent: FMTreeNode, gui_parent: TreeItem, disabled := false) -> void:
	for node: FMTreeNode in parent.children:
		if node.ignored: continue

		var icon := data.ICON_FOLDER if node.is_dir else data.ICON_FILE
		var tree_item: TreeItem

		if not node.is_dir:
			if _is_valid_file(node):
				if node.path in _mission.mdata.edited_files:
					tree_item = _create_node(gui_parent, node, icon, disabled, data.VALID_COLOR)
				else:
					tree_item = _create_node(gui_parent, node, icon, disabled)
		elif _dir_has_valid_files(node):
			if node.has_edited_files(_mission):
				tree_item = _create_node(gui_parent, node, icon, disabled, data.VALID_COLOR)
			else:
				tree_item = _create_node(gui_parent, node, icon, disabled)


		_build_file_tree(node, tree_item, disabled)



func _create_node(parent: TreeItem, node: FMTreeNode, icon: Texture2D, disabled := false, color: Variant = null) -> TreeItem:
	var tree_item := parent.create_child()
	tree_item.set_text(0, node.name)
	tree_item.set_metadata(0, node)

	if color:
		tree_item.set_custom_color(0, color)
		#tree_item.set_icon_modulate(0, color)

	tree_item.set_icon(0, icon)
	tree_item.set_icon_max_width(0, 16)

	if disabled:
		tree_item.set_selectable(0, false)
		tree_item.set_custom_color(0, data.FADED_TEXT_COLOR)

	tree_item.collapsed = true
	return tree_item
