class_name GuiTabFiles
extends TabContainer

@onready var tr_files: Tree = $HSplitContainer/VBoxContainer/tr_files

#func _enter_tree() -> void:
	#gui.tab_files = self

var _mission: Mission

func on_mission_reloaded(_force_update:=false) -> void:
	# update the syntax highlighters if mission is readonly or not

	# if valid_mission
	# 	tag saved versions of all open text editors
	# 	update button states

	_reload_tree()
	pass

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

	if not valid_mission:
		tr_files.clear()
		# if not fms.is_mission_missing(_mission.id):
		# 	_update_buttons_states()

	_reload_tree()



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

	# "tga", "png", "jpg", "jpeg",    # TODO
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
					tree_item = _create_node(gui_parent, node.name, icon, disabled, data.VALID_COLOR)
				else:
					tree_item = _create_node(gui_parent, node.name, icon, disabled)
		elif _dir_has_valid_files(node):
			if node.has_edited_files(_mission):
				tree_item = _create_node(gui_parent, node.name, icon, disabled, data.VALID_COLOR)
			else:
				tree_item = _create_node(gui_parent, node.name, icon, disabled)


		_build_file_tree(node, tree_item, disabled)



func _create_node(parent: TreeItem, text: String, icon: Texture2D, disabled := false, color: Variant = null) -> TreeItem:
	var node := parent.create_child()
	node.set_text(0, text)

	if color:
		node.set_custom_color(0, color)
		#node.set_icon_modulate(0, color)

	node.set_icon(0, icon)
	node.set_icon_max_width(0, 16)

	if disabled:
		node.set_selectable(0, false)
		node.set_custom_color(0, data.FADED_TEXT_COLOR)

	node.collapsed = true
	return node
