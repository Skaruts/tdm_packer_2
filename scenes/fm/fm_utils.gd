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
static func pack_mission(output:Object, mission:Mission) -> void:
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


static func _pack_files(output:Object, mission:Mission) -> ErrorReport:
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

		var fullpath:String = files[i]
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







#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#        Validate Paths

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
const INVALID_CHARS : Array[String] = [' ',
	'(', ')', '{', '}', '[', ']', '|', '!', '@', '#', '$', '%', '^', '&',
	'*', ',', '+', '-', '"', '\'', ':', ';', '?', '<', '>', '`', '~'#, '/'
]

const INVALID_CAHARS_NO_SPACE : Array[String] = [
	'(', ')', '{', '}', '[', ']', '|', '!', '@', '#', '$', '%', '^', '&',
	'*', ',', '+', '-', '"', '\'', ':', ';', '?', '<', '>', '`', '~'
]


static func validate_paths(output:Object, mission:Mission) -> bool:
	output.call_thread_safe("task", "Validating paths in '%s'..." % [mission.id])

	var steps: float = mission.filepaths.size() # account for the mission folder itself

	var invalid_paths: Array[String]
	var mission_folder_valid := true

	output.call_thread_safe("set_percentage", 1.0/steps)

	#output.call_thread_safe("task", "Checking mission folder...")
	for c:String in INVALID_CHARS:
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

	for i:int in mission.filepaths.size():
		output.call_thread_safe("set_percentage", (i+1)/steps)

		var path:String = mission.filepaths[i]
		var rel_path := path.replace(mission.paths.root + "/", '')

		for c:String in INVALID_CHARS:
			if c in rel_path:
				invalid_paths.append(rel_path)
				break

	if invalid_paths.size() > 0:
		output.call_thread_safe("error", "Some paths contain spaces or unsuported characters")
		for path:String in invalid_paths:
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


static func check_file_and_create(mis:Mission, filename:String, default_content:="") -> void:
	if not Path.file_exists(mis.paths.get(filename)):
		Path.write_file(mis.paths.get(filename), default_content)


static func load_file(mis:Mission, filename:String, default_content:="") -> void:
	check_file_and_create(mis, filename, default_content)
	mis.mdata.set(filename, Path.read_file_string(mis.paths.get(filename)))
	mis.store_hash(mis.paths.get(filename))


static func save_modfile(mis: Mission) -> void:
	#_save_mission_file(mis, mis.mdata.modfile, mis.paths.modfile, core.MODFILE_FILENAME, Mission.DirtyFlags.MODFILE)
	var modfile := "Title: %s\nDescription: %s\nAuthor: %s\nVersion: %s\nRequired TDM Version: %s\n"
	var md := mis.mdata
	modfile = modfile % [md.title, md.description, md.author, md.version, md.tdm_version]

	var map_count := mis.mdata.map_files.size()

	# TODO: add map titles
	if map_count > 0:
		for i:int in map_count:
			var title := mis.mdata.map_titles[i]
			if not title: continue
			modfile += "Mission %s Title: %s\n" % [i+1, title]

	Path.write_file(mis.paths.modfile, modfile)
	console.print("Saved modfile")
	mis.set_dirty_flag(false, Mission.DirtyFlags.MODFILE)

	mis.store_hash(mis.paths.modfile)


static func load_modfile(mis: Mission) -> void:
	check_file_and_create(mis, "modfile", data.DEFAULT_MODFILE)
	var file_string := Path.read_file_string(mis.paths.modfile)

	var map_index := -99
	var map_count := mis.mdata.map_files.size()
	mis.mdata.map_titles.clear()
	mis.mdata.map_titles.resize(map_count)

	var commit_section := \
		func(text:String, section: ModfileSection, _map_index:int) -> void:
			match section:
				ModfileSection.Title:       mis.mdata.title       = text
				ModfileSection.Author:      mis.mdata.author      = text
				ModfileSection.Version:     mis.mdata.version     = text
				ModfileSection.TDM_Version: mis.mdata.tdm_version = text
				ModfileSection.Description: mis.mdata.description = text
				ModfileSection.Map_Title:
					if _map_index >= mis.mdata.map_titles.size():
						mis.mdata.map_titles.resize(_map_index+1)
					logs.print(_map_index, _map_index >= mis.mdata.map_titles.size())
					mis.mdata.map_titles[_map_index] = text

	var tokens := file_string.replace('\n', ' ').replace('\t', ' ').split(' ')
	var curr_section := ModfileSection.None
	var section_text := ""
	#var final_text := ""

	var toks_lut := {
		"Title:"       = ModfileSection.Title,
		"Author:"      = ModfileSection.Author,
		"Version:"     = ModfileSection.Version,
		"Description:" = ModfileSection.Description,
		# no colons
		"Required"     = ModfileSection.TDM_Version,  # Required TDM Version:
		"Mission"      = ModfileSection.Map_Title,    # Mission 1 Title:
	}

	# use lower case tokens, in case it was manually edited by the user
	# and contains case mistakes
	var token_count := tokens.size()
	var i := 0
	while i < token_count:
		var tok := tokens[i]
		if tok in toks_lut.keys():
			commit_section.call(section_text.strip_edges(), curr_section, map_index)
			section_text = ""

			if tok.to_lower() == "mission":
				logs.print(tokens[i+2], tokens[i+2].to_lower() == "title:")
				if i+2 < token_count and tokens[i+2].to_lower() == "title:":
					curr_section = toks_lut[tok]
					map_index = tokens[i+1].to_int()-1
					i += 2
			elif tok.to_lower() == "required":
				if i+2 < token_count \
				and tokens[i+1].to_lower() == "tdm" \
				and tokens[i+2].to_lower() == "version:":
					curr_section = toks_lut[tok]
					i += 2
			else:
				curr_section = toks_lut[tok]

			#logs.print(">", i, curr_section, tok, " | ", section_text, " | ", map_index)
			i += 1
			continue

		#logs.print("-", i, curr_section, tok, " | ", section_text, " | ", map_index)
		section_text += tok + ' '
		i += 1
	commit_section.call(section_text.strip_edges(), curr_section, map_index)

	#logs.print(mis.mdata.map_titles)
	#if map_titles.size() >= map_count:
		#logs.warning("map titles exceed number of map files: %s/%s" % [map_titles.size(), map_count])

	mis.store_hash(mis.paths.modfile)



static func _save_mission_file(mis:Mission, content:String, filepath:String, filename:String, flag:Mission.DirtyFlags, force_it:=false) -> bool:
	if not mis.get_dirty_flag(flag) and not force_it: return false
	Path.write_file(filepath, content)
	console.print("Saved '%s'" % filename)
	mis.set_dirty_flag(false, flag)
	return true

static func save_readme(mis:Mission) -> void:
	_save_mission_file(mis, mis.mdata.readme, mis.paths.readme, data.README_FILENAME, Mission.DirtyFlags.README)
	mis.store_hash(mis.paths.readme)


static func save_pkignore(mis:Mission) -> void:
	_save_mission_file(mis, mis.mdata.pkignore, mis.paths.pkignore, data.IGNORES_FILENAME, Mission.DirtyFlags.PKIGNORE)

	mis.store_hash(mis.paths.pkignore)


static func save_maps_file(mis: Mission) -> bool:
	#logs.print("maps:  ", mis.mdata.map_files)

	if mis.mdata.map_files.size() <= 1: # save startingmap.txt
		if Path.file_exists(mis.paths.mapsequence):
			DirAccess.remove_absolute(mis.paths.mapsequence)

		var map:String
		if mis.mdata.map_files.size():
			map = mis.mdata.map_files[0]

		_save_mission_file(mis, map, mis.paths.startingmap, data.STARTINGMAP_FILENAME, Mission.DirtyFlags.MAPS, true)
		mis.remove_hash(mis.paths.mapsequence)
		mis.store_hash(mis.paths.startingmap)
	else: # save tdm_mapsequence.txt
		if Path.file_exists(mis.paths.startingmap):
			DirAccess.remove_absolute(mis.paths.startingmap)

		var string := ""
		for i:int in mis.mdata.map_files.size():
			string += "Mission %d: %s\n" % [i+1, mis.mdata.map_files[i]]
		_save_mission_file(mis, string, mis.paths.mapsequence, data.MAPSEQUENCE_FILENAME, Mission.DirtyFlags.MAPS, true)
		mis.remove_hash(mis.paths.startingmap)
		mis.store_hash(mis.paths.mapsequence)

	return true



static func load_map_sequence(mis: Mission) -> void:
	mis.mdata.map_files.clear()

	if Path.file_exists(mis.paths.startingmap):
		# TODO: maybe I should read this file by lines too, to prevent problems
		# with invalid lines
		var map_filename := Path.read_file_string(mis.paths.startingmap).strip_edges()
		mis.mdata.map_files.append(map_filename)
		mis.remove_hash(mis.paths.mapsequence)
		mis.store_hash(mis.paths.startingmap)

	elif Path.file_exists(mis.paths.mapsequence):
		if Path.file_exists(mis.paths.mapsequence):
			var lines := Path.read_file_string(mis.paths.mapsequence).split('\n')

			for line:String in lines:
				# TODO: detect comments and ignore (may need a proper parser)
				if line == "" or line.find('Mission ') == -1 or line.find(':') == -1:
					continue

				line = line.substr( line.find(':')+1 )
				line = line.strip_edges(true, true)
				mis.mdata.map_files.append(line)

			mis.remove_hash(mis.paths.startingmap)
			mis.store_hash(mis.paths.mapsequence)

	else:
		Path.write_file(mis.paths.startingmap, "")
		mis.remove_hash(mis.paths.mapsequence)
		mis.store_hash(mis.paths.startingmap)

	#logs.print("on load", mis.mdata.map_files)
