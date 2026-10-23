class_name FMTreeNode
extends RefCounted




var _parent : WeakRef
var parent : FMTreeNode:
		set(new_parent): _parent = weakref(new_parent)
		get():           return _parent.get_ref() if _parent else null

var children : Array[FMTreeNode]

var path     : String
var rel_path : String
var name     : String
var ignored  : bool
var is_dir   : bool


func print_branch(indent := 0) -> void:
	print("\t".repeat(indent) + name)

	var node := get_first_child()

	while node:
		#var text := node.get_text(0)
		node.print_branch(indent+1)
		node = node.get_next()
		#var next := node.get_text(0)

func _init(_path: String, _parent: Variant = null, _is_dir := false) -> void:
	path = _path
	name = _path.get_file()
	is_dir = _is_dir

	if _parent:
		parent = _parent as FMTreeNode
		parent.add_child(self)
		rel_path = Path.join(parent.rel_path, name)
	else:
		rel_path = name


func add_child(node: FMTreeNode) -> void:
	if not node in children:
		children.append(node)


func has_included_files() -> bool:
	if not is_dir or ignored: return false
	for c: FMTreeNode in children:
		if not c.is_dir:
			if not c.ignored:
				return true
		elif c.has_included_files():
			return true
	return false


func is_ignored_file() -> bool:
	if is_dir: return false
	return has_ignored_files()


func has_ignored_files() -> bool:
	if not is_dir and ignored: return true
	for c: FMTreeNode in children:
		if not c.is_dir:
			if c.ignored:
				return true
		elif c.has_ignored_files():
			return true
	return false


func get_child_named(name_: String) -> Variant:
	if name == name_: return self
	for c: FMTreeNode in children:
		if c.name == name_:
			return c
		var node: FMTreeNode = c.get_child_named(name_)
		if node:
			return node as FMTreeNode

	return null


func get_child_at_path(path_: String) -> Variant:
	if path == path_: return self
	for c: FMTreeNode in children:
		if c.path == path_:
			return c
		var node: FMTreeNode = c.get_child_at_path(path_)
		if node:
			return node as FMTreeNode

	return null

func get_first_child() -> FMTreeNode:
	if children.size() == 0: return null
	return children[0]


# TODO: makes this a linked list kind of tree
func get_next() -> FMTreeNode:
	var idx := parent.children.find(self)
	if idx >= parent.children.size()-1:
		return null
	return parent.children[idx+1]
