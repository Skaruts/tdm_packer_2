class_name FMUtils
extends Node


static var default_ignored_directories := Set.new([
	"/.git",
	"/savegames"
])

static var default_ignored_files := Set.new([
	data.IGNORES_FILENAME,
	".gitignore",
	".gitattributes",
	".pyc",
	".py",
	".pk4",
	".zip",
	".7z",
	".rar",
	".log",
	".dat",
	"bak",
])



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
static func pack_mission(rep_panel:ReportPanel, mission:Mission) -> void:
	rep_panel.call_thread_safe("task", "Packing '%s'..." % [mission.zipname])

	# delete any pk4's that may have been created by the packer
	# (any whose name begins with the mission id)
	var old_paks := Path.get_filepaths_filtered(mission.paths.root,
		func(path:String) -> bool:
			return path.get_extension() == "pk4" and path.get_file().begins_with(mission.id)
	)
	for old_pak:String in old_paks:
		var err := Path.delete_file(old_pak)
		if err != OK:
			rep_panel.call_thread_safe("error", "(%s) couldn't delete file '%s'" % [Path.get_error_text(err), old_pak])
			return

	var t1 := Time.get_ticks_msec()
	var report := _pack_files(rep_panel, mission)

	if report.ok:
		var t2 := Time.get_ticks_msec()
		var total_time := "%.2f" % [(t2-t1)/1000.0]
		rep_panel.call_thread_safe("task", "Finished packing '%s'..." % [mission.zipname])
		rep_panel.call_thread_safe("info", "%s dirs, %s files, %s seconds" % [mission.inc_dir_count, mission.inc_file_count, total_time])
	else:
		rep_panel.call_thread_safe("error", report.error)


static func _pack_files(rep_panel:ReportPanel, mission:Mission) -> ErrorReport:
	var zipper := ZIPPacker.new()
	var pakpath := Path.join(mission.paths.root, mission.zipname)

	var err := zipper.open(pakpath)
	if err != OK:
		return ErrorReport.new(false, "Couldn't create pk4 archive at '%s'" % [pakpath])

	var report := ErrorReport.new(true)
	var files  := mission.filepaths
	var subst_files : Array[String] = ["readme.txt"]
	var file_count  : float = files.size()

	for i:float in file_count:
		if rep_panel.aborted:
			report = ErrorReport.new(false, "aborted")
			break
		rep_panel.call_thread_safe("set_percentage", (i+1)/file_count)

		var fullpath:String = files[i]
		var rel_path := fullpath.trim_prefix(mission.paths.root + '/')
		rep_panel.call_thread_safe("print", "    %s" % [rel_path])
		zipper.start_file(rel_path)

		var filename := fullpath.get_file()
		if not filename in subst_files:
			zipper.write_file(Path.read_file_bytes(fullpath))
		else:
			var content := Path.read_file_string(fullpath)
			content = content.replace(data.TOK_VERSION,     mission.mdata.version)
			content = content.replace(data.TOK_AUTHOR,      mission.mdata.author)
			content = content.replace(data.TOK_TITLE,       mission.mdata.title)
			content = content.replace(data.TOK_MIN_VERSION, mission.mdata.tdm_version)
			if content.contains(data.TOK_DATETIME):
				content = content.replace(data.TOK_DATETIME, data.get_date_time_string())
			#logs.print(filename, filename in subst_files, content)
			zipper.write_file(content.to_utf8_buffer())

		zipper.close_file()

	zipper.close()
	return report



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		File Tree

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func build_file_tree(mission:Mission) -> void:
	logs.task("Building file tree...")

	mission.inc_dir_count       = 0
	mission.inc_file_count      = 0
	mission.exc_dir_count       = 0
	mission.exc_file_count      = 0
	mission.file_tree           = FMTreeNode.new(mission.paths.root)
	mission.ignored_files       = default_ignored_files.duplicate()
	mission.ignored_directories = default_ignored_directories.duplicate()
	mission.filepaths.clear()

	init_ignores(mission)
	_gather_files(mission, mission.file_tree)

	for i: int in range(mission.filepaths.size()-1, -1, -1):
		var filepath := mission.filepaths[i]
		if not filepath.contains(mission.paths.maps): continue
		var basename := filepath.get_file().get_basename()
		#logs.print(basename, basename in mission.mdata.map_files, filepath)
		if not basename in mission.mdata.map_files:
			mission.filepaths.remove_at(i)
			mission.inc_file_count -= 1
			mission.exc_file_count += 1

	logs.task("Finished building file tree")


static func init_ignores(mission:Mission) -> void:
	if mission.mdata.pkignore == "": return

	var list: PackedStringArray = mission.mdata.pkignore.split('\n', false)
	for line: String in list:
		if '#' in line: line = line.left(line.find('#'))
		line = line.strip_edges()
		if line == "":
			continue

		if '/' in line:
			if   line.begins_with('/'):  line = line.substr(1)
			elif line.ends_with('/'):    line = line.substr(0, line.length()-1)

			if line.length() <= 1:
				continue
			mission.ignored_directories.add(line)
		else:
			mission.ignored_files.add(line)


static func _gather_files(mission:Mission, parent:FMTreeNode) -> void:
	var dirpaths:Array[String]  = Path.get_dirpaths(parent.path)
	var filepaths:Array[String] = Path.get_filepaths(parent.path)

	if not dirpaths.size() and not filepaths.size():
		if parent.path == mission.paths.maps: return
		if not parent.ignored:
			mission.ignored_files.add(parent.path)
			parent.ignored = true
		return

	var ign_files := mission.ignored_files
	var ign_dirs  := mission.ignored_directories

	for fullpath:String in dirpaths:
		var rel_path := fullpath.replace(mission.paths.root, '')
		var dir_node := FMTreeNode.new(fullpath, parent)
		dir_node.is_dir = true
		dir_node.ignored = parent.ignored or should_ignore(rel_path, ign_dirs) \
						or (fullpath != mission.paths.maps and fullpath.contains(mission.paths.maps))
		if dir_node.ignored:
			ign_dirs.add(fullpath)
			mission.exc_dir_count += 1
		else:
			mission.inc_dir_count += 1
		_gather_files(mission, dir_node)

	for fullpath:String in filepaths:
		var rel_path  := fullpath.replace(mission.paths.root, '')
		var file_node := FMTreeNode.new(fullpath, parent)
		file_node.ignored = parent.ignored or should_ignore(rel_path, ign_files)
		if file_node.ignored:
			ign_files.add(fullpath)
			mission.exc_file_count += 1
		else:
			mission.filepaths.append(fullpath)
			mission.inc_file_count += 1


# TODO: this should be in the tree class, maybe
static func print_tree_node_recursive(root:FMTreeNode) -> void:
	for c:FMTreeNode in root.children:
		if not c.ignored:
			logs.print(c.rel_path)

		if c.children.size():
			print_tree_node_recursive(c)





const INVALID_CHARS : Array[String] = [' ',
	'(', ')', '{', '}', '[', ']', '|', '!', '@', '#', '$', '%', '^', '&',
	'*', ',', '+', '-', '"', '\'', ':', ';', '?', '<', '>', '`', '~'#, '/'
]

const INVALID_CAHARS_NO_SPACE : Array[String] = [
	'(', ')', '{', '}', '[', ']', '|', '!', '@', '#', '$', '%', '^', '&',
	'*', ',', '+', '-', '"', '\'', ':', ';', '?', '<', '>', '`', '~'
]
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#        Validate Paths

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func validate_paths(rep_panel:ReportPanel, mission:Mission) -> bool:
	rep_panel.call_thread_safe("task", "Validating paths in '%s'..." % [mission.id])

	var steps: float = mission.filepaths.size() # account for the mission folder itself

	var invalid_paths: Array[String]
	var mission_folder_valid := true

	rep_panel.call_thread_safe("set_percentage", 1.0/steps)

	#rep_panel.call_thread_safe("task", "Checking mission folder...")
	for c:String in INVALID_CHARS:
		if c in mission.id:
			mission_folder_valid = false
			rep_panel.call_thread_safe("warning", "Mission folder '%s' contains spaces or unsuported characters" % [mission.id])
			break

	rep_panel.call_thread_safe("set_percentage", 2.0/steps)
	if mission.id != mission.id.to_lower():
		mission_folder_valid = false
		rep_panel.call_thread_safe("warning", "Mission folder '%s' contains uppercase characters" % [mission.id])

	if mission_folder_valid:
		rep_panel.call_thread_safe("info", "Mission folder is valid")

	for i:int in mission.filepaths.size():
		rep_panel.call_thread_safe("set_percentage", (i+1)/steps)

		var path:String = mission.filepaths[i]
		var rel_path := path.replace(mission.paths.root + "/", '')

		for c:String in INVALID_CHARS:
			if c in rel_path:
				invalid_paths.append(rel_path)
				break

	if invalid_paths.size() > 0:
		rep_panel.call_thread_safe("error", "Some paths contain spaces or unsuported characters")
		for path:String in invalid_paths:
			rep_panel.call_thread_safe("print", "      %s" % path)

	var num_invalid_paths := invalid_paths.size() + (0 if mission_folder_valid else 1)
	#rep_panel.call_thread_safe("task", "Finished validating paths")
	rep_panel.call_thread_safe("info", "%s invalid paths\n" % [num_invalid_paths])
	if num_invalid_paths > 0:
		rep_panel.call_thread_safe("reminder", "Avoid paths with spaces or any of the unsuported characters:\n    %s" % [" ".join(INVALID_CAHARS_NO_SPACE)])

	return num_invalid_paths == 0



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#        Valdate Map Assets

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func gather_definitions(rep_panel:ReportPanel, mission:Mission) -> void:
	#  [x]  entities
	#  [-]  models		 (not sure model defs are needed)
	#  [x]  materials
	#  [x]  skins
	#  [x]  particles
	#  [x]  xdata

	var t1 := Time.get_ticks_msec()

	var files: PackedStringArray

	var ent_parser := DefinitionParser.new()
	files = get_included_files_in_dir(mission, Path.join(mission.paths.root, "def"), ["*.def"])
	mission.defs.entity = ent_parser.parse(files)
	# for k:String in mission.defs.entity:
	# 	logs.print(mission.defs.entity[k])

	files = get_included_files_in_dir(mission, Path.join(mission.paths.root, "materials"), ["*.mtr"])
	var mtr_parser := DefinitionParser.new()
	mission.defs.material = mtr_parser.parse(files)
	# for path:String in mission.defs.material:
	# 	logs.print(path)
	# 	for k:String in mission.defs.material[path]:
	# 		logs.print("   ", k)

	files = get_included_files_in_dir(mission, Path.join(mission.paths.root, "skins"), ["*.skin"])
	var skin_parser := DefinitionParser.new()
	mission.defs.skin = skin_parser.parse(files)
	# for path:String in mission.defs.skin:
	# 	logs.print(path)
	# 	for k:String in mission.defs.skin[path]:
	# 		logs.print("   ", k)

	files = get_included_files_in_dir(mission, Path.join(mission.paths.root, "particles"), ["*.prt"])
	var particle_parser := DefinitionParser.new()
	mission.defs.particle = particle_parser.parse(files)
	# for path:String in mission.defs.particle:
	# 	logs.print(path)
	# 	for k:String in mission.defs.particle[path]:
	# 		logs.print("   ", k)

	files = get_included_files_in_dir(mission, Path.join(mission.paths.root, "xdata"), ["*.xd"])
	var xdata_parser := DefinitionParser.new()
	mission.defs.xdata = xdata_parser.parse(files)
	#for path:String in mission.defs.xdata:
		#logs.print(path)
		#for k:String in mission.defs.xdata[path]:
			#logs.print("   ", k)

	var t2 := Time.get_ticks_msec()
	logs.print("%.3f s" % [(t2-t1)/1000.0])



static func get_included_files_in_dir(mission:Mission, path:String, filters:Array[String]=[]) -> PackedStringArray:
	var files :PackedStringArray = []
	for fullpath:String in mission.filepaths:
		if not path in fullpath: continue
		var rel_path := fullpath.replace(mission.paths.root + '/', '')
		if not filters:
			files.append(fullpath)
		else:
			for filter:String in filters:
				if rel_path.match(filter):
					files.append(fullpath)
					break
	return files

























#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func find_unused_models(rep_panel:ReportPanel) -> Array[String]:
	#task("Checking models...")
	var mission := fms.curr_mission
	var files := get_included_files_in_dir(mission, Path.join(mission.paths.root, "models"), ["*.ase", "*.lwo"])
	var unused : Array[String]

	if files.size() > 0:
		var used := get_property_values(mission, "model")
		unused = check_unused_files_in_array(files, used)

	if unused.size() > 0:
		rep_panel.error("Some models are not found in the maps")
		for file in unused:
			rep_panel.print("    %s" % file)
		rep_panel.info( "%d unused models" % unused.size())
	else:
		rep_panel.info("No unused models")

	rep_panel.print("")

	return unused




static func get_property_values(mission:Mission, prop_name:String, patterns:Array[String]=[]) -> Array[String]:
	var props : Array[String] = []

	var all_entities := mission.map_parser.get_all_entities()

	for e:MapParser.Entity in all_entities:
		if not prop_name in e.properties:
			continue
		if not patterns:
			props.append(e.properties[prop_name])
		else:
			var prop_val: String = e.properties[prop_name]
			for p:String in patterns:
				if prop_val.match(p):
					props.append(prop_val)
					break
	return props


static func check_unused_files_in_dict(files:Dictionary, used:Array[String], valid_unused_defs:Array[String]=[], valid_unused_files:Array[String]=[]) -> Dictionary:
	var unused: Dictionary
	for filepath:String in files:
		if filepath in valid_unused_files: continue
		var defs:Array[String] = files[filepath]
		var num_unused := 0
		for d:String in defs:
			if d in valid_unused_defs: continue
			if not d in used:
				num_unused += 1
		if num_unused == defs.size():
			unused[filepath] = defs
	return unused


static func check_unused_files_in_array(files:Array[String], used:Array[String], valid_unused_defs:Array[String]=[], valid_unused_files:Array[String]=[]) -> Array[String]:
	var unused:Array[String] = []
	for d:String in files:
		if d in valid_unused_defs: continue
		if not d in used:
			unused.append(d)
	return unused
