class_name FMUtils
extends Node


static var _default_ignored_directories := Set.new(["/.git", "/savegames"])
static var _default_ignored_files       := Set.new([data.IGNORES_FILENAME, "bak", ".log", ".dat", ".py", ".pyc", ".pk4", ".zip", ".7z", ".rar", ".gitignore", ".gitattributes"])


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Utils
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static var alpha_sort_paths := func(a:String, b:String) -> bool:
	var afile := a.get_file()
	var bfile := b.get_file()
	return afile < bfile


static func should_ignore(path:String, filters:Set) -> bool:
	for string:String in filters.items():
		if string in path:
			return true
	return false


static func get_file_hash(path:String) -> String:
	return Path.get_md5(path)

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Packing

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func pack_mission(mission:Mission, scene_tree:SceneTree) -> void:
	console.task("Packing '%s'..." % [mission.zipname])
	await scene_tree.process_frame

	var t1 := Time.get_ticks_msec()

	await _pack_files(mission, scene_tree)

	var t2 := Time.get_ticks_msec()
	var total_time := "%.2f" % [(t2-t1)/1000.0]

	console.task("Finished packing '%s'..." % [mission.zipname])
	console.info("%s dirs, %s files, %s seconds" % [mission.dir_count, mission.file_count, total_time])



static func _pack_files(mission:Mission, scene_tree:SceneTree) -> ErrorReport:
	var zipper := ZIPPacker.new()
	var pakpath := Path.join(mission.paths.root, mission.zipname)

	var err := zipper.open(pakpath)
	if err != OK:
		return ErrorReport.new(false, "Couldn't create pk4 archive at '%s'" % [pakpath])

	for fpath:String in mission.filepaths:
		var rel_path := fpath.trim_prefix(mission.paths.root + '/')

		console.print("packing '%s'" % [rel_path])
		await scene_tree.process_frame # wait for message to be printed

		zipper.start_file(rel_path)
		zipper.write_file(Path.read_file_bytes(fpath))
		zipper.close_file()

	zipper.close()
	return ErrorReport.new(true)





#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		File Tree

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func build_file_tree(mission:Mission) -> void:
	logs.task("Building file tree...")

	mission.dir_count = 0
	mission.file_count = 0
	var ign_dirs  := _default_ignored_directories.duplicate()
	var ign_files := _default_ignored_files.duplicate()

	init_ignores(mission.files.pkignore, ign_dirs, ign_files)

	_add_files_to_ignores(mission.paths.root, ign_dirs, ign_files)
	_add_maps_to_ignores(mission, ign_dirs, ign_files)

	var root := FMTreeNode.new(mission.paths.root)
	_build_mission_nodes(mission, root, ign_dirs, ign_files)

	mission.file_tree = root
	mission.filepaths = build_mission_filepaths(mission, root)
	mission.ignored_files = ign_files
	mission.ignored_directories = ign_dirs

	logs.task("Finished building file tree")


static func _build_mission_nodes(mission:Mission, parent:FMTreeNode, ign_dirs:Set, ign_files:Set) -> void:
	var dpaths:Array[String] = Path.get_dirpaths(parent.path)
	var fpaths:Array[String] = Path.get_filepaths(parent.path)


	for dir:String in dpaths:
		var dir_node := FMTreeNode.new(dir, parent)
		dir_node.ignored = parent.ignored \
						 or should_ignore(dir, ign_dirs) \
						 or parent.path.ends_with(Path.join(mission.paths.root, "maps"))
		dir_node.is_dir = true
		_build_mission_nodes(mission, dir_node, ign_dirs, ign_files)

	for file:String in fpaths:
		var file_node := FMTreeNode.new(file, parent)
		file_node.ignored = parent.ignored \
			or should_ignore(file, ign_files)


static func print_tree_node_recursive(root:FMTreeNode) -> void:
	for c:FMTreeNode in root.children:
		if not c.ignored:
			logs.print(c.rel_path)

		if c.children.size():
			print_tree_node_recursive(c)


static func build_mission_filepaths(mission:Mission, root:FMTreeNode) -> Array[String]:
	var filepaths:Array[String] = []

	for c:FMTreeNode in root.children:
		if not c.ignored:
			if not c.is_dir:
				mission.file_count += 1
				filepaths.append(c.path)
			else:
				mission.dir_count += 1

		if c.children.size():
			filepaths += build_mission_filepaths(mission, c)

	return filepaths


static func init_ignores(pkignore:String, ign_dirs:Set, ign_files:Set) -> void:
	if pkignore == "": return

	var list:PackedStringArray = pkignore.split('\n', false)
	for line in list:
		if '#' in line:
			line = line.left(line.find('#'))

		line = line.strip_edges()
		if line == "": continue

		if '/' in line:
			if line.begins_with('/'):
				line = line.substr(1)
			elif line.ends_with('/'):
				line = line.substr(0, line.length()-1)

			if line == "": continue
			ign_dirs.add(line)
		else:
			ign_files.add(line)



static func _get_used_map_names(file:String) -> Array[String]:
	var map_names:Array[String]
	if Path.file_exists(file):
		var string := Path.read_file_string(file)
		map_names = [ string.strip_edges().split('\n', false)[0] ]
	return map_names


static func _add_files_to_ignores(root:String, ign_dirs:Set, ign_files:Set, ignored:=false) -> void:
	var dpaths:Array[String] = Path.get_dirpaths(root)
	var fpaths:Array[String] = Path.get_filepaths(root)

	for dir:String in dpaths:
		var dir_ignored := should_ignore(dir, ign_dirs)
		_add_files_to_ignores(dir, ign_dirs, ign_files, dir_ignored)

	for filepath:String in fpaths:
		if ignored or should_ignore(filepath, ign_files):
			ign_files.add( filepath )



static func _add_maps_to_ignores(mission:Mission, ign_dirs:Set, ign_files:Set) -> void:
	if not Path.dir_exists(mission.paths.maps): return
	var dpaths:Array[String] = Path.get_dirpaths(mission.paths.maps)
	var fpaths:Array[String] = Path.get_filepaths(mission.paths.maps)

	# every dir inside '/maps' should be ignored
	for dir:String in dpaths:
		ign_dirs.add( Path.join(mission.paths.maps, dir) )

	var used_map_names := mission.map_sequence

	var fpaths_copy := fpaths.duplicate()
	for filepath:String in fpaths_copy:
		var filename := filepath.get_basename().get_file()
		if filename in used_map_names:
			fpaths.erase(filepath)

	for filepath:String in fpaths:
		ign_files.add(filepath)
