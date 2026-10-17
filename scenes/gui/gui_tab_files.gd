class_name GuiTabFiles
extends TabContainer


const NodeInfo := TreeUtils.NodeInfo

const TextFileEditorScene := preload("res://scenes/gui/text_file_editor.tscn")


@onready var tc_editors: TabContainer = %tc_editors
@onready var tr_files: Tree = $HSplitContainer/VBoxContainer/tr_files
@onready var tabs_menu: PopupMenu = $HSplitContainer/tabs_menu


var _mission : Mission
var editors  : Dictionary[String, TextFileEditor]

var syntax_highlighters: Array[SyntaxHighlighter]
var curr_tab_hovered_idx: int = 0

var tr_files_root: TreeItem

var tab_bar: TabBar


enum TabMenuOptions {
	CLOSE_TAB,
	UNDO_CLOSE_TAB,
	CLOSE_OTHER_TABS,
	CLOSE_ALL_TABS,
	WORD_WRAP,
	LOCATE_IN_TREE,
}


func _ready() -> void:
	for c in tc_editors.get_children():
		c.free()

	tr_files.item_activated.connect(_on_tr_files_item_activated)

	tab_bar = tc_editors.get_tab_bar()
	tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_NEVER
	tab_bar.max_tab_width = 150
	tab_bar.select_with_rmb = true

	tab_bar.tab_close_pressed.connect(_on_tab_bar_tab_close_pressed)
	tab_bar.gui_input.connect(_on_tab_bar_gui_input)
	tab_bar.tab_rmb_clicked.connect(_on_tab_bar_tab_rmb_clicked)

	tc_editors.sort_children.connect(_on_tc_editors_sort_children)

	tabs_menu.add_item("Close Tab", TabMenuOptions.CLOSE_TAB)
	# tabs_menu.add_item("Undo Close Tab", TabMenuOptions.UNDO_CLOSE_TAB)
	tabs_menu.add_item("Close Other Tabs", TabMenuOptions.CLOSE_OTHER_TABS)
	tabs_menu.add_item("Close All Tabs", TabMenuOptions.CLOSE_ALL_TABS)
	tabs_menu.add_separator()
	# tabs_menu.add_item("Toggle Word Wrap", TabMenuOptions.WORD_WRAP)
	tabs_menu.add_check_item("Word Wrap", TabMenuOptions.WORD_WRAP)

	tabs_menu.add_separator()
	tabs_menu.add_item("Locate File", TabMenuOptions.LOCATE_IN_TREE)


	tabs_menu.set_item_tooltip(
		tabs_menu.get_item_index(TabMenuOptions.WORD_WRAP),
		"Toggle word wrapping"
	)

	tabs_menu.set_item_tooltip(
		tabs_menu.get_item_index(TabMenuOptions.LOCATE_IN_TREE),
		"Locate and select this file in the file tree."
	)


	tabs_menu.id_pressed.connect(_on_tabs_menu_id_pressed)
	tabs_menu.window_input.connect(_on_tabs_menu_window_input)


func set_mission(mission: Mission) -> void:
	_mission = mission

	_build_tree()
	_reload_tabs(_mission.file_tree)


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

	tab_bar.tab_close_display_policy = data.config.tab_close_buttons_mode

	if not is_missing:
		_build_tree()
		_reload_tabs(_mission.file_tree)


func update_tree_node_file_opened(node: FMTreeNode, opened: bool) -> void:
	var ti := _get_tree_item_by_name(tr_files_root, node.name)
	_set_item_edited_files_button(ti, node.is_dir, opened)

	var ti_parent := ti.get_parent()
	var node_parent := node.parent
	while ti_parent != null and ti_parent != tr_files_root:
		if _dir_has_edited_files(node_parent):
			_set_item_edited_files_button(ti_parent, node_parent.is_dir, true)
			if not opened: break
		else:
			_set_item_edited_files_button(ti_parent, node_parent.is_dir, false)

		ti_parent = ti_parent.get_parent()
		node_parent = node_parent.parent




func _get_tree_item_by_name(parent: TreeItem, target_name: String) -> TreeItem:
	if not parent:
		return null

	# Check the current item (column 0 is usually where the text/name is)
	if parent.get_text(0) == target_name:
		return parent

	# Search children recursively
	var child := parent.get_first_child()
	while child:
		var found := _get_tree_item_by_name(child, target_name)
		if found:
			return found
		child = child.get_next()

	return null



func _add_editor_if_needed(node: FMTreeNode) -> bool:
	if node.path in editors: return false

	var ed: TextFileEditor = TextFileEditorScene.instantiate()
	tc_editors.add_child(ed)
	editors[node.path] = ed

	ed.set_data(_mission, node.path)
	ed.name = node.name
	ed.set_meta("node", node)

	tab_bar.set_tab_title( tc_editors.get_child_count()-1, node.name )

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
		if node.is_dir:
			_reload_tabs(node)
			continue

		if not node.path in _mission.mdata.edited_files:
			continue

		var old_hash: String
		if _mission.has_edited_file(node.path):
			old_hash = _mission.get_file_hash(node.path)

		fms.add_edited_file_to_mission(_mission, node.path)

		var added_ed := _add_editor_if_needed(node)
		var hash_comp := old_hash == _mission.get_file_hash(node.path)
		if added_ed:
			editors[node.path].set_text(_mission.mdata.edited_files[node.path])
			editors[node.path].update_colors()
		elif not hash_comp:
			logs.print("RELAODING FILE")
			editors[node.path].update_text(_mission.mdata.edited_files[node.path])
			editors[node.path].update_colors()


func _build_tree() -> void:
	logs.print("RELOAD_TREE", _mission.id)

	var sel_path: String
	var sel_item := tr_files.get_selected()
	if sel_item:
		var info: NodeInfo = sel_item.get_metadata(0)
		sel_path = info.path

	var expanded_paths : Dictionary = {}
	var should_restore := tr_files_root != null

	if should_restore:
		TreeUtils.get_tree_state(tr_files_root, expanded_paths)

	tr_files.clear()
	tr_files_root = tr_files.create_item()
	tr_files_root.set_metadata(0, NodeInfo.new(_mission.file_tree.path, _mission.file_tree.name, _mission.file_tree))
	tr_files_root.set_text(0, _mission.id)
	tr_files_root.set_custom_color(0, data.TREE_ROOT_COLOR)
	var disabled := fms.is_mission_readonly(_mission.id)

	_build_file_tree(_mission.file_tree, tr_files_root, disabled)

	if should_restore:
		TreeUtils.restore_tree_state(tr_files, tr_files_root, expanded_paths, sel_path)

	# _prune_tree_of_missing_files(tr_files_root, disabled)
	# print("--------------------")
	# TreeUtils.print_tree(tr_files_root)
	# _add_new_files_to_tree(_mission.file_tree, tr_files_root, disabled)
	# print("--------------------")
	# TreeUtils.print_tree(tr_files_root)


# func _prune_tree_of_missing_files(parent: TreeItem, disabled := false) -> void:
# 	if parent == null: return

# 	var item := parent.get_first_child()
# 	if not item:
# 		if not parent == tr_files_root:
# 			parent.get_parent().remove_child(parent)
# 		return

# 	# check missing files and prune the tree
# 	while item != null:
# 		var info: NodeInfo = item.get_metadata(0)
# 		assert(info.node)

# 		if info.node.is_dir:
# 			if Path.dir_exists(info.path):
# 				_prune_tree_of_missing_files(item, disabled)
# 		elif not Path.file_exists(info.path):
# 			parent.remove_child(item)

# 		item = item.get_next()



# func _add_new_files_to_tree(parent_node: FMTreeNode, parent: TreeItem, disabled := false) -> void:
# 	if parent == null: return
# 	assert(parent_node.is_dir)

# 	var node := parent_node.get_first_child()
# 	var item := parent.get_first_child()
# 	var idx := 0

# 	while node != null:
# 		var icon := data.ICON_FOLDER if node.is_dir else data.ICON_FILE

# 		if item:
# 			idx = item.get_index()

# 		if node.is_dir:
# 			var has_valid_files := _dir_has_valid_files(node)
# 			var has_edited_files := _dir_has_edited_files(node)
# 			if not item:
# 				# - folder was newly created or moved and item needs to be created
# 				# - item is a folder that doesn't contain edited files
# 				if has_valid_files:
# 					item = _create_tree_item(parent, node, icon, disabled, has_edited_files, null, idx)
# 			else:
# 				if item.get_text(0) != node.name:
# 					item = _create_tree_item(parent, node, icon, disabled, has_edited_files, null, item.get_index())
# 				else:
# 					item.set_metadata(0, NodeInfo.new(node.path, node.name, node))
# 			if has_valid_files:
# 				_add_new_files_to_tree(node, item, disabled)
# 		else:
# 			var is_edited_file := node.path in _mission.mdata.edited_files

# 			if not item:
# 				# - file was newly created or moved and item needs to be created
# 				if _is_valid_file(node):
# 					item = _create_tree_item(parent, node, icon, disabled, is_edited_file, null, idx)
# 			else:
# 				if item.get_text(0) != node.name:
# 					item = _create_tree_item(parent, node, icon, disabled, is_edited_file, null, item.get_index())
# 				else:
# 					item.set_metadata(0, NodeInfo.new(node.path, node.name, node))

# 		node = node.get_next()
# 		if item:
# 			item = item.get_next()












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


func _dir_has_edited_files(node: FMTreeNode) -> bool:
	assert(node.is_dir)

	for c: FMTreeNode in node.children:
		if not c.is_dir:
			if c.path in _mission.mdata.edited_files:
				return true
		elif _dir_has_edited_files(c):
			return true
	return false


func _build_file_tree(parent: FMTreeNode, gui_parent: TreeItem, disabled := false) -> void:
	for node: FMTreeNode in parent.children:
		var icon := data.ICON_FOLDER if node.is_dir else data.ICON_FILE
		var tree_item: TreeItem

		if not node.is_dir:
			if _is_valid_file(node):
				var is_edited_file := node.path in _mission.mdata.edited_files
				tree_item = _create_tree_item(gui_parent, node, icon, disabled, is_edited_file)
		elif _dir_has_valid_files(node):
			var has_edited_files := _dir_has_edited_files(node)
			tree_item = _create_tree_item(gui_parent, node, icon, disabled, has_edited_files)

		_build_file_tree(node, tree_item, disabled)




func _create_tree_item(parent: TreeItem, node: FMTreeNode, icon: Texture2D,
					   disabled := false, opened_files := false,
					   color: Variant = null, at_index := -1) -> TreeItem:
	var item := parent.create_child(at_index)
	item.set_text(0, node.name)
	item.set_metadata(0, NodeInfo.new(node.path, node.name, node))

	if color:
		item.set_custom_color(0, color)
		#item.set_icon_modulate(0, color)

	item.set_icon(0, icon)
	item.set_icon_max_width(0, 16)

	if disabled:
		item.set_selectable(0, false)
		item.set_custom_color(0, data.FADED_TEXT_COLOR)

	if opened_files:
		_set_item_edited_files_button(item, node.is_dir, true)

	item.collapsed = true
	return item


const TOOLTIP_FILE := "This file is being edited"
const TOOLTIP_DIR := "This folder has edited files"
func _set_item_edited_files_button(item: TreeItem, is_dir: bool, opened: bool) -> void:
	var tooltip := TOOLTIP_DIR if is_dir else TOOLTIP_FILE
	if opened:
		if item.get_button_count(0) == 0:
			item.add_button(0, data.ICON_DOT, 0, true, tooltip)
	else:
		if item.get_button_count(0) > 0:
			item.erase_button(0, 0)












#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#	Signals

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=


func _on_tr_files_item_activated() -> void:
	var item := tr_files.get_selected()
	var info: NodeInfo = item.get_metadata(0)
	var node := info.node
	assert(node)

	if node.is_dir: return

	if node.path in editors:
		var idx := -1
		for i in tc_editors.get_child_count():
			var title: String = tab_bar.get_tab_title(i)
			if title == node.name:
				idx = i
				break

		if idx >= 0:
			tc_editors.current_tab = idx

		return

	# if tc_editors.get_child(0) == dummy_editor:
	# 	tc_editors.remove_child(dummy_editor)

	fms.add_edited_file_to_mission(_mission, node.path)
	_add_editor_if_needed(node)
	_update_editor(node.path, _mission.mdata.edited_files[node.path])
	update_tree_node_file_opened(node, true)

	tc_editors.current_tab = tc_editors.get_child_count() - 1


func _on_tabs_menu_window_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	var r := Rect2(tabs_menu.position, tabs_menu.size)
	if not r.has_point( get_global_mouse_position() ):
		tabs_menu.hide()


func _on_tabs_menu_id_pressed(id: int) -> void:
	var idx := tab_right_clicked
	var tab: TextFileEditor = tc_editors.get_child(idx)

	match id:
		TabMenuOptions.CLOSE_TAB:
			_on_tab_bar_tab_close_pressed(idx)
		# TabMenuOptions.UNDO_CLOSE_TAB:

		TabMenuOptions.CLOSE_OTHER_TABS:
			for i in range(tc_editors.get_child_count()-1, -1, -1):
				if i == idx: continue
				_on_tab_bar_tab_close_pressed(i)

		TabMenuOptions.CLOSE_ALL_TABS:
			for i in range(tc_editors.get_child_count()-1, -1, -1):
				_on_tab_bar_tab_close_pressed(i)

		TabMenuOptions.WORD_WRAP:
			tab.toggle_word_wrap()
			tabs_menu.set_item_checked(4, tab.get_word_wrap())

		TabMenuOptions.LOCATE_IN_TREE:
			var ti := _get_tree_item_by_name(tr_files_root, tab_bar.get_tab_title(idx))
			logs.print(ti != null)
			ti.uncollapse_tree()
			ti.select(0)
			tr_files.scroll_to_item(ti, true)





var tab_right_clicked: int
func _on_tab_bar_tab_rmb_clicked(idx: int) -> void:
	tab_right_clicked = idx
	var tab: TextFileEditor = tc_editors.get_child(idx)
	tabs_menu.set_item_checked(4, tab.get_word_wrap())
	tabs_menu.popup()
	tabs_menu.position = tab_bar.get_global_mouse_position()


func _on_tab_bar_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	# if event.button_index == 2:


	if event.button_index == 3:
		var lmp := tab_bar.get_local_mouse_position()
		var idx := tab_bar.get_tab_idx_at_point(lmp)
		if idx != -1:
			_on_tab_bar_tab_close_pressed(idx)



func _on_tc_editors_sort_children() -> void:
	logs.print("sort_children")

	for i in tc_editors.get_child_count():
		var tab: TextFileEditor = tc_editors.get_child(i)
		var node: FMTreeNode = tab.get_meta("node")
		tab_bar.set_tab_title(i, node.name)


func _on_tab_bar_tab_close_pressed(tab_idx: int) -> void:
	var tab := tc_editors.get_child(tab_idx)
	var node: FMTreeNode = tab.get_meta("node")
	_remove_editor(tab)

	fms.remove_edited_file_from_mission(_mission, node.path)
	update_tree_node_file_opened(node, false)
