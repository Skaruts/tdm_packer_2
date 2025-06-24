class_name FMTreeNode
extends RefCounted



var parent:FMTreeNode
var children:Array[FMTreeNode]

var path:String
var rel_path:String
var name:String
var ignored:bool
var is_dir:bool




func _init(_path:String, _parent:Variant=null) -> void:
	path = _path
	name = _path.get_file()

	if _parent:
		parent = _parent as FMTreeNode
		parent.add_child(self)
		rel_path = Path.join(parent.rel_path, name)
	else:
		rel_path = name


func add_child(node:FMTreeNode) -> void:
	if not node in children:
		children.append(node)


func has_included_files() -> bool:
	if not is_dir or ignored: return false
	for c:FMTreeNode in children:
		if not c.is_dir:
			if not c.ignored:
				return true
		elif c.has_included_files():
			return true
	return false


func has_ignored_files() -> bool:
	if not is_dir or ignored: return true
	for c:FMTreeNode in children:
		if not c.is_dir:
			if c.ignored:
				return true
		elif c.has_ignored_files():
			return true
	return false


@warning_ignore("shadowed_variable")
func get_child_named(name:String) -> Variant:
	for c:FMTreeNode in children:
		if c.name == name:
			return c
		var node:FMTreeNode = c.get_child_named(name)
		if node: return node as FMTreeNode

	return null
