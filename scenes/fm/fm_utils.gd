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
	".bak",
])



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Utils
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static var alpha_sort_paths := func(a: String, b: String) -> bool:
	var afile := a.get_file()
	var bfile := b.get_file()
	return afile < bfile


static func should_ignore(path: String, filters: Set) -> bool:
	for string:String in filters.items():
		if string in path:
			return true
	return false


static func get_file_hash(path: String) -> String:
	return Path.get_md5(path)


static func check_file_hash(mis: Mission, path: String) -> bool:
	if path not in mis.file_hashes: return false
	return Path.get_md5(path) == mis.file_hashes[path]


static func load_edited_files(files: Array, mis: Mission) -> Array[String]:
	var missing_files: Array[String]
	for rel_path: String in files:
		var filepath := Path.join(mis.paths.root, rel_path)
		if not Path.file_exists(filepath):
			missing_files.append(filepath)
			continue
		mis.add_edited_file(filepath)
	return missing_files


static func save_edited_files(files: Array, mis: Mission) -> void:
	for rel_path: String in files:
		var filepath := Path.join(mis.paths.root, rel_path)
		assert(filepath in mis.mdata.edited_files)
		#if not check_file_hash(mis, filepath):
		var content: String = mis.mdata.edited_files[filepath]
		Path.write_file(filepath, content)


static func check_edited_files_changed(mis: Mission) -> bool:
	for filepath: String in mis.mdata.edited_files:
		if not check_file_hash(mis, filepath):
			return true
	return false

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Packing

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func pack_mission(output: Object, mission: Mission) -> void:
	output.call_thread_safe("task", "Packing '%s'..." % [mission.zipname])

	# delete any pk4's that may have been created by the packer
	# (any whose name begins with the mission id)
	var old_paks := Path.get_filepaths_filtered(mission.paths.root,
		func(path:String) -> bool:
			return path.get_extension() == "pk4" and path.get_file().begins_with(mission.id)
	)
	for old_pak:String in old_paks:
		var err := Path.delete_file(old_pak)
		if err != OK:
			output.call_thread_safe("error", "(%s) couldn't delete file '%s'" % [Path.get_error_text(err), old_pak])
			return

	var t1 := Time.get_ticks_msec()
	var report := _pack_files(output, mission)

	if report.ok:
		var t2 := Time.get_ticks_msec()
		var total_time := "%.2f" % [(t2-t1)/1000.0]
		output.call_thread_safe("task", "Finished packing '%s'..." % [mission.zipname])
		output.call_thread_safe("info", "%s dirs, %s files, %s seconds" % [mission.inc_dir_count, mission.inc_file_count, total_time])
	else:
		output.call_thread_safe("error", report.error)


static func _pack_files(output: Object, mission: Mission) -> ErrorReport:
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
		if not output.is_packing():
			report = ErrorReport.new(false, "aborted")
			break
		output.call_thread_safe("set_percentage", (i+1)/file_count)

		var fullpath: String = files[i]
		var rel_path := fullpath.trim_prefix(mission.paths.root + '/')
		output.call_thread_safe("print", "    %s" % [rel_path])
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
static func build_file_tree(mission: Mission) -> void:
	# logs.task("Building file tree...")

	mission.inc_dir_count       = 0
	mission.inc_file_count      = 0
	mission.exc_dir_count       = 0
	mission.exc_file_count      = 0
	mission.file_tree           = FMTreeNode.new(mission.paths.root, null, true)
	mission.ignored_files       = default_ignored_files.duplicate()
	mission.ignored_directories = default_ignored_directories.duplicate()
	mission.filepaths.clear()

	init_ignores(mission)
	_gather_files(mission, mission.file_tree)



	for i: int in range(mission.filepaths.size()-1, -1, -1):
		var filepath := mission.filepaths[i]
		if not filepath.contains(mission.paths.maps): continue
		var basename := filepath.get_file().get_basename()
		if not mission.is_map_in_sequence(basename):
			mission.filepaths.remove_at(i)
			mission.inc_file_count -= 1
			mission.exc_file_count += 1

	# logs.task("Finished building file tree")


static func init_ignores(mission: Mission) -> void:
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


static func _gather_files(mission: Mission, parent: FMTreeNode) -> void:
	var dirpaths  : Array[String] = Path.get_dirpaths(parent.path)
	var filepaths : Array[String] = Path.get_filepaths(parent.path)

	if not dirpaths.size() and not filepaths.size():
		if parent.path == mission.paths.maps: return
		if not parent.ignored:
			mission.ignored_files.add(parent.path)
			parent.ignored = true
		return

	var ign_files := mission.ignored_files
	var ign_dirs  := mission.ignored_directories

	for fullpath: String in dirpaths:
		var rel_path := fullpath.replace(mission.paths.root, '')
		var dir_node := FMTreeNode.new(fullpath, parent, true)
		dir_node.ignored = parent.ignored or should_ignore(rel_path, ign_dirs) \
						or (fullpath != mission.paths.maps
							and fullpath.contains(mission.paths.maps))
		if dir_node.ignored:
			ign_dirs.add(fullpath)
			mission.exc_dir_count += 1
		else:
			mission.inc_dir_count += 1
		_gather_files(mission, dir_node)

	for fullpath: String in filepaths:
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
static func print_tree_node_recursive(root: FMTreeNode) -> void:
	for c:FMTreeNode in root.children:
		if not c.ignored:
			logs.print(c.rel_path)

		if c.children.size():
			print_tree_node_recursive(c)







#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#        Paths

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
const INVALID_CHARS : Array[String] = [' ',
	'(', ')', '{', '}', '[', ']', '|', '!', '@', '#', '$', '%', '^', '&',
	'*', ',', '+', '-', '"', '\'', ':', ';', '?', '<', '>', '`', '~'#, '/'
]

const INVALID_CAHARS_NO_SPACE : Array[String] = [
	'(', ')', '{', '}', '[', ']', '|', '!', '@', '#', '$', '%', '^', '&',
	'*', ',', '+', '-', '"', '\'', ':', ';', '?', '<', '>', '`', '~'
]

static func get_mission_folder_list() -> Array[String]:
	assert(data.config.tdm_path != "")
	var fms_folder := Path.join(data.config.tdm_path.get_base_dir(), "fms")

	var mission_paths := Path.get_dirpaths(fms_folder)

	var exceptions: Array[String] = ["_missionshots"]
	for i: int in range(mission_paths.size()-1, -1, -1):
		for exc in exceptions:
			if mission_paths[i].ends_with(exc):
				mission_paths.remove_at(i)
				break

	return mission_paths


static func get_mission_id_list() -> Array[String]:
	var mission_paths := FMUtils.get_mission_folder_list()
	var mission_ids: Array[String]

	for path in mission_paths:
		mission_ids.append(path.get_file())

	return mission_ids


static func validate_paths(output: Object, mission: Mission) -> bool:
	output.call_thread_safe("task", "Validating paths in '%s'..." % [mission.id])

	var steps: float = mission.filepaths.size() # account for the mission folder itself

	var invalid_paths: Array[String]
	var mission_folder_valid := true

	output.call_thread_safe("set_percentage", 1.0/steps)

	#output.call_thread_safe("task", "Checking mission folder...")
	for c: String in INVALID_CHARS:
		if c in mission.id:
			mission_folder_valid = false
			output.call_thread_safe("warning", "Mission folder '%s' contains spaces or unsuported characters" % [mission.id])
			break

	output.call_thread_safe("set_percentage", 2.0/steps)
	if mission.id != mission.id.to_lower():
		mission_folder_valid = false
		output.call_thread_safe("warning", "Mission folder '%s' contains uppercase characters" % [mission.id])

	if mission_folder_valid:
		output.call_thread_safe("info", "Mission folder is valid")

	for i: int in mission.filepaths.size():
		output.call_thread_safe("set_percentage", (i+1)/steps)

		var path: String = mission.filepaths[i]
		var rel_path := path.replace(mission.paths.root + "/", '')

		for c: String in INVALID_CHARS:
			if c in rel_path:
				invalid_paths.append(rel_path)
				break

	if invalid_paths.size() > 0:
		output.call_thread_safe("error", "Some paths contain spaces or unsuported characters")
		for path: String in invalid_paths:
			output.call_thread_safe("print", "      %s" % path)

	var num_invalid_paths := invalid_paths.size() + (0 if mission_folder_valid else 1)
	#output.call_thread_safe("task", "Finished validating paths")
	output.call_thread_safe("info", "%s invalid paths\n" % [num_invalid_paths])
	if num_invalid_paths > 0:
		output.call_thread_safe("reminder", "Avoid paths with spaces or any of the unsuported characters:\n    %s" % [" ".join(INVALID_CAHARS_NO_SPACE)])

	return num_invalid_paths == 0






#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#        Mission Files

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
enum ModfileSection {
	None,
	Title,
	Author,
	Version,
	TDM_Version,
	Description,
	Map_Title,
}


static func check_file_and_create(mis: Mission, filename: String, default_content := "") -> bool:
	if Path.file_exists(mis.paths.get(filename)): return true
	if not fms.is_mission_readonly(mis.id):
		Path.write_file(mis.paths.get(filename), default_content)
		return true
	return false


static func load_file_strictly(mis: Mission, filename: String) -> void:
	var file_path: String = mis.paths.get(filename)
	if Path.file_exists(file_path):
		var file_content := Path.read_file_string(file_path)
		mis.mdata.set(filename, file_content)
		mis.store_hash(file_path)


static func load_or_create_file(mis: Mission, filename: String, default_content := "") -> void:
	if not Path.file_exists(mis.paths.get(filename)):
		if fms.is_mission_readonly(mis.id):
			return
		Path.write_file(mis.paths.get(filename), default_content)

	mis.mdata.set(filename, Path.read_file_string(mis.paths.get(filename)))
	mis.store_hash(mis.paths.get(filename))


static func create_mission_file(mis: Mission, filename: String, default_content := "") -> void:
	var file_path: String = mis.paths.get(filename)
	if Path.file_exists(file_path): return
	Path.write_file(mis.paths.get(filename), default_content)


static func save_modfile(mis: Mission) -> void:
	#_save_mission_file(mis, mis.mdata.modfile, mis.paths.modfile, core.MODFILE_FILENAME, Mission.DirtyFlags.MODFILE)

	var md := mis.mdata

	var title       := "Title: %s\n" % md.title
	var description := "Description: %s\n" % md.description
	var author      := "Author: %s\n" % md.author
	var version     := "Version: %s\n" % md.version
	var tdm_version := "Required TDM Version: %s\n" % md.tdm_version

	var map_titles := ""
	if mis.mdata.map_files.size() > 0:
		for i: int in mis.mdata.map_files.size():
			var mf := mis.mdata.map_files[i]
			if mf.title == "": continue
			map_titles += "Mission %s Title: %s\n" % [i+1, mf.title]

	var modfile := title       \
				 + map_titles  \
				 + description \
				 + author      \
				 + version     \
				 + tdm_version

	Path.write_file(mis.paths.modfile, modfile)
	console.print("Saved modfile")
	mis.set_dirty_flag(false, Mission.DirtyFlags.MODFILE)

	mis.store_hash(mis.paths.modfile)



class ModfileInfo:
	var title       : String
	var map_titles  : Array[String]
	var description : String
	var author      : String
	var version     : String
	var tdm_version : String
	var extra       : String


static func load_modfile(mis: Mission) -> void:
	if not Path.file_exists(mis.paths.get("modfile")):
		if fms.is_mission_readonly(mis.id):
			return
		Path.write_file(mis.paths.get("modfile"), data.DEFAULT_MODFILE)

	var file_string := Path.read_file_string(mis.paths.modfile)
	var section_rgx := RegEx.create_from_string(r"(Title:)|(Author:)|(Description:)|(Version:)|(Required TDM Version:)|(Mission \d+ Title:)")
	var rgx_matches := section_rgx.search_all(file_string)
	var map_count := mis.mdata.map_files.size()

	var headers: Dictionary = {}
	for m: RegExMatch in rgx_matches:
		var string := m.get_string()
		var start := m.get_start()
		var end := m.get_end()
		headers[string] = {name=string, start=start, end=end}

		# if string.begins_with("Mission "):
		# 	map_count += 1

	var mfi := ModfileInfo.new()

	if map_count > 0:
		mfi.map_titles.resize(map_count)

	for key: String in headers:
		var d: Dictionary = headers[key]
		var idx: int      = d.end

		if key.begins_with("Mission "):
			var map_idx := key.to_int()-1
			var end := _get_content_len(d, file_string, headers)
			var map_title: String = file_string.substr(idx, end-idx)\
										.strip_edges().replace('\n', '')
			# check the size, in case there are not as many maps as titles,
			# due to external human error
			if map_idx < mfi.map_titles.size():
				mfi.map_titles[map_idx] = map_title
		elif key.begins_with("Required"):
			var end := _get_content_len(d, file_string, headers)
			var content := file_string.substr(idx, end-idx)\
						   .strip_edges().replace('\n', '')
			mfi.tdm_version = content
		else:
			var end := _get_content_len(d, file_string, headers, key == "Description:")
			var content := file_string.substr(idx, end-idx).strip_edges()
			var prop := key.replace(':', '').to_lower()
			mfi.set(prop, content)

	# logs.print("---------------------------")
	# logs.print(mfi.title)
	# logs.print(mfi.map_titles)
	# logs.print(mfi.description)
	# logs.print(mfi.author)
	# logs.print(mfi.version)
	# logs.print(mfi.tdm_version)
	# logs.print("---------------------------")

	mis.mdata.title = mfi.title
	for i: int in map_count:
		var mf: Mission.MapFile = mis.mdata.map_files[i]
		mf.title = mfi.map_titles[i]

	# mis.mdata.map_titles = mfi.map_titles
	mis.mdata.author = mfi.author
	mis.mdata.version = mfi.version
	mis.mdata.tdm_version = mfi.tdm_version
	mis.mdata.description = mfi.description


static func _get_content_len(curr_d: Dictionary, file_string: String,
							 headers: Dictionary, ignore_nls := false) -> int:
	var next_header := _get_next_header(curr_d, headers)

	if ignore_nls:
		if next_header.size() > 0: return next_header.start
		else:                      return file_string.length()

	var next_nl: int  = file_string.find("\n", curr_d.end)

	if next_header.size() > 0:
		if next_nl != -1: return min(next_nl, next_header.start)
		else:             return next_header.start

	return next_nl if next_nl != -1 else file_string.length()


static func _get_next_header(curr_d: Dictionary, headers: Dictionary) -> Dictionary:
	var dist := 9999999
	var h: Dictionary
	for key: String in headers:
		if key == curr_d.name: continue
		var d: Dictionary = headers[key]
		if d.start < curr_d.end: continue
		var new_dist: int = d.start-curr_d.end
		if new_dist < dist:
			dist = new_dist
			h = d
	return h



static func _save_mission_file(mis: Mission, content: String, filepath: String,
							   filename: String, flag: Mission.DirtyFlags,
							   force_it := false) -> bool:
	if not mis.get_dirty_flag(flag) and not force_it: return false
	Path.write_file(filepath, content)
	console.print("Saved '%s'" % filename)
	mis.set_dirty_flag(false, flag)
	return true


static func save_readme(mis: Mission) -> void:
	_save_mission_file(mis, mis.mdata.readme, mis.paths.readme,
					   data.README_FILENAME, Mission.DirtyFlags.README)
	mis.store_hash(mis.paths.readme)


static func save_pkignore(mis: Mission) -> void:
	_save_mission_file(mis, mis.mdata.pkignore, mis.paths.pkignore,
					   data.IGNORES_FILENAME, Mission.DirtyFlags.PKIGNORE)
	mis.store_hash(mis.paths.pkignore)


static func save_maps_file(mis: Mission) -> bool:
	#logs.print("maps:  ", mis.mdata.map_files)

	if mis.mdata.map_files.size() <= 1: # save startingmap.txt
		if Path.file_exists(mis.paths.mapsequence):
			DirAccess.remove_absolute(mis.paths.mapsequence)

		var mf: Mission.MapFile
		if mis.mdata.map_files.size():
			mf = mis.mdata.map_files[0]

		_save_mission_file(mis, mf.name, mis.paths.startingmap,
						   data.STARTINGMAP_FILENAME, Mission.DirtyFlags.MAPS,
						   true)
		mis.remove_hash(mis.paths.mapsequence)
		mis.store_hash(mis.paths.startingmap)
	else: # save tdm_mapsequence.txt
		if Path.file_exists(mis.paths.startingmap):
			DirAccess.remove_absolute(mis.paths.startingmap)

		var string := ""
		for i: int in mis.mdata.map_files.size():
			string += "Mission %d: %s\n" % [i+1, mis.mdata.map_files[i]]
		_save_mission_file(mis, string, mis.paths.mapsequence,
						   data.MAPSEQUENCE_FILENAME, Mission.DirtyFlags.MAPS,
						   true)
		mis.remove_hash(mis.paths.startingmap)
		mis.store_hash(mis.paths.mapsequence)

	return true



static func load_map_sequence(mis: Mission) -> void:
	mis.mdata.map_files.clear()

	if Path.file_exists(mis.paths.startingmap):
		# TODO: maybe I should read this file by lines too, to prevent problems
		# with invalid lines
		var map_filename := Path.read_file_string(mis.paths.startingmap) \
							.strip_edges()
		if map_filename != "":
			var mf := Mission.MapFile.new(map_filename)
			mis.mdata.map_files.append(mf)
			mis.remove_hash(mis.paths.mapsequence)
			mis.store_hash(mis.paths.startingmap)

	elif Path.file_exists(mis.paths.mapsequence):
		if Path.file_exists(mis.paths.mapsequence):
			var lines := Path.read_file_string(mis.paths.mapsequence)\
						 .split('\n')

			for line: String in lines:
				# TODO: detect comments and ignore (may need a proper parser)
				if line == "" or line.find('Mission ') == -1 \
				or line.find(':') == -1:
					continue

				line = line.substr( line.find(':')+1 )
				line = line.strip_edges(true, true)
				var mf := Mission.MapFile.new(line)
				mis.mdata.map_files.append(mf)

			mis.remove_hash(mis.paths.startingmap)
			mis.store_hash(mis.paths.mapsequence)

	elif not fms.is_mission_readonly(mis.id):
		Path.write_file(mis.paths.startingmap, "")
		mis.remove_hash(mis.paths.mapsequence)
		mis.store_hash(mis.paths.startingmap)

	# logs.print("on load", mis.id, mis.mdata.map_files)
