class_name TreeUtils
extends Object


class NodeInfo:
	var path: String
	var name: String
	var node: FMTreeNode
	func _init(p: String, n: String, tn: FMTreeNode) -> void:
		path = p
		name = n
		node = tn


static func print_branch(parent: TreeItem, indent := 0) -> void:
	print("\t".repeat(indent) + parent.get_text(0))
	var item := parent.get_first_child()
	while item:
		print_branch(item, indent+1)
		item = item.get_next()


static func get_tree_state(parent: TreeItem, expanded_paths: Dictionary) -> void:
	if not parent.is_collapsed():
		var info: NodeInfo = parent.get_metadata(0)
		expanded_paths[info.path] = true

	var item := parent.get_first_child()
	while item:
		get_tree_state(item, expanded_paths)
		item = item.get_next()


static func restore_tree_state(tree: Tree, parent: TreeItem,
				expanded_paths: Dictionary, selected_path: String) -> void:
	var info: NodeInfo = parent.get_metadata(0)

	logs.print(info.path in expanded_paths, info.path)
	parent.set_collapsed(not info.path in expanded_paths)

	if info.path == selected_path:
		# tree.set_selected(parent, 0)
		parent.uncollapse_tree()
		parent.select(0)
		tree.scroll_to_item(parent, true)

	var item := parent.get_first_child()
	while item:
		restore_tree_state(tree, item, expanded_paths, selected_path)
		item = item.get_next()
