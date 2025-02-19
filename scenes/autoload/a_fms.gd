extends Node
# autoloaded script


# TODO: maybe 'fms_folder' shouldn't exist (multiple sources of truth)


var fms_folder : String  # TODO:

var missions : Array[Mission]
var curr_mission : Mission

var _save_timer := 0.0
var _save_delay := 1.0
var _mission_to_save : Mission



func initialize() -> void:
	logs.task("Initializing fms singleton...")

	if not Path.file_exists(data.MISSIONS_FILE):
		save_missions_list()

	update_folders()
	load_missions()

	if missions.size():
		#select_mission(0) # don't call this here, it's not needed, and it will 'check_mission_filesystem'
		curr_mission = missions[0]


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	_save_timer -= delta
	if _save_timer > 0: return
	stop_timer_and_save()


func start_save_timer() -> void:
	_save_timer = _save_delay
	_mission_to_save = curr_mission
	set_process(true)


func is_save_timer_counting() -> bool:
	return _save_timer > 0


func stop_timer_and_save() -> void:
	set_process(false)
	save_mission(_mission_to_save)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Loading
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func load_missions() -> void:
	console.task("Loading missions.")

	var cf := ConfigFile.new()
	if cf.load(data.MISSIONS_FILE) == OK:
		logs.print(cf.get_sections())
		if not Path.file_exists(data.config.tdm_path):
			console.warning("No TDM path set, or TDM path is invalid: '%s'" % data.config.tdm_path)
		elif cf.has_section("missions"):
			logs.print("loading missions")
			for id:String in cf.get_section_keys("missions"):
				load_mission(id)

	if missions.size():
		sort_missions()
		curr_mission = missions[0]

	console.info("Loaded %s missions." % missions.size())


func _mission_already_loaded(id:String) -> bool:
	for m:Mission in missions:
		if m.id == id:
			return true
	return false


func _reload_mission(mis:Mission) -> void:
	load_file(mis, "pkignore")
	FMUtils.build_file_tree(mis)
	_load_mission_files(mis)
	gui.workspace_mgr.on_mission_reloaded()
	gui.menu_bar.update_menu()


func _soft_reload_mission(mis:Mission) -> void:
	FMUtils.build_file_tree(mis)
	gui.workspace_mgr.on_mission_reloaded()
	gui.menu_bar.update_menu()


func load_mission(id: String, create_modfile := false) -> Mission:
	console.print("Loading '%s'" % [id])

	var mission := Mission.new()
	var fm_path := Path.join(fms_folder, id)
	mission.set_id(id)
	mission.set_paths(fm_path)

	missions.append(mission)

	if not Path.file_exists(mission.paths.modfile):
		if create_modfile:
			Path.write_file(mission.paths.modfile, data.DEFAULT_MODFILE)
		else:
			logs.error("couldn't find 'darkmod.txt' in '%s'" % fm_path)
			return mission

	mission.zipname = id + ".pk4"
	mission.full_filelist = Path.get_filepaths_recursive(mission.paths.root)

	load_file(mission, "pkignore")
	_load_mission_files(mission)
	FMUtils.build_file_tree(mission)

	return mission


func check_file_and_create(mis:Mission, filename:String, default_content:="") -> void:
	if not Path.file_exists(mis.paths.get(filename)):
		Path.write_file(mis.paths.get(filename), default_content)


func load_file(mis:Mission, filename:String, default_content:="") -> void:
	check_file_and_create(mis, filename, default_content)
	mis.files.set(filename, Path.read_file_string(mis.paths.get(filename)))
	mis.store_hash(mis.paths.get(filename))


func load_map_sequence(mis:Mission) -> void:
	mis.map_sequence = []

	if Path.file_exists(mis.paths.startingmap):
		mis.map_sequence = [Path.read_file_string(mis.paths.startingmap).strip_edges()]
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
				line = line.strip_edges(false, true)
				mis.map_sequence.append(line)

			mis.remove_hash(mis.paths.startingmap)
			mis.store_hash(mis.paths.mapsequence)

	else:
		Path.write_file(mis.paths.startingmap, "")
		mis.remove_hash(mis.paths.mapsequence)
		mis.store_hash(mis.paths.startingmap)


func _load_mission_files(mis:Mission) -> void:
	load_file(mis, "modfile")
	load_file(mis, "readme")
	load_map_sequence(mis)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Saving
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func save_missions_list() -> void:
	var cf := ConfigFile.new()
	for m:Mission in missions:
		cf.set_value("missions", m.id, {}) # mission data is empty for now

	if cf.save(data.MISSIONS_FILE) != OK:
		logs.error("Couldn't save missions file at '%s'" % data.MISSIONS_FILE)


func save_mission(mission:Mission, reload:=false) -> void:
	if not mission.dirty: return

	if mission.get_dirty_flag(Mission.DirtyFlags.PKIGNORE):
		save_pkignore(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.MODFILE):
		save_modfile(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.README):
		save_readme(mission)

	if reload:
		_soft_reload_mission(mission)


func save_modfile(mis:Mission) -> void:
	_save_mission_file(mis, mis.files.modfile, mis.paths.modfile, data.MODFILE_FILENAME, Mission.DirtyFlags.MODFILE)
	mis.store_hash(mis.paths.modfile)


func save_readme(mis:Mission) -> void:
	_save_mission_file(mis, mis.files.readme, mis.paths.readme, data.README_FILENAME, Mission.DirtyFlags.README)
	mis.store_hash(mis.paths.readme)


func save_pkignore(mis:Mission) -> void:
	_save_mission_file(mis, mis.files.pkignore, mis.paths.pkignore, data.IGNORES_FILENAME, Mission.DirtyFlags.PKIGNORE)
	_soft_reload_mission(mis)
	mis.store_hash(mis.paths.pkignore)


func _save_mission_file(mis:Mission, content:String, filepath:String, filename:String, flag:Mission.DirtyFlags, force_it:=false) -> bool:
	if not mis.get_dirty_flag(flag) and not force_it: return false
	Path.write_file(filepath, content)
	console.print("Saved '%s'" % filename)
	mis.set_dirty_flag(false, flag)
	return true


func save_maps_file(mis:Mission) -> bool:
	logs.print("map_sequence:  ", mis.map_sequence)

	if mis.map_sequence.size() <= 1: # save startingmap.txt
		if Path.file_exists(mis.paths.mapsequence):
			DirAccess.remove_absolute(mis.paths.mapsequence)

		var map:String
		if mis.map_sequence.size():
			map = mis.map_sequence[0]

		_save_mission_file(mis, map, mis.paths.startingmap, data.STARTINGMAP_FILENAME, Mission.DirtyFlags.MAPS, true)
		mis.remove_hash(mis.paths.mapsequence)
		mis.store_hash(mis.paths.startingmap)
	else: # save tdm_mapsequence.txt
		if Path.file_exists(mis.paths.startingmap):
			DirAccess.remove_absolute(mis.paths.startingmap)

		var str:String
		for i:int in mis.map_sequence.size():
			str += "Mission %d: %s\n" % [i+1, mis.map_sequence[i]]
		_save_mission_file(mis, str, mis.paths.mapsequence, data.MAPSEQUENCE_FILENAME, Mission.DirtyFlags.MAPS, true)
		mis.remove_hash(mis.paths.startingmap)
		mis.store_hash(mis.paths.mapsequence)

	_soft_reload_mission(mis)
	return true



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Misc
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func sort_missions() -> void:
	missions.sort_custom(func(a:Mission, b:Mission) -> bool:
		return a.id < b.id
	)


func update_folders() -> void:
	if data.config.tdm_path:
		fms_folder = Path.join(data.config.tdm_path.get_base_dir(), "fms")


func select_mission(idx:int) -> void:
	assert(idx >= 0 and idx < missions.size())
	curr_mission = missions[idx]
	check_mission_filesystem()
	gui.missions_list.update_buttons()
	gui.workspace_mgr.select_workspace(get_current_mission_index())
	gui.menu_bar.update_menu()
	logs.print("select_mission", idx, curr_mission.id)


func add_mission(id:String) -> Mission:
	if _mission_already_loaded(id):
		popups.show_message("", "Mission '%s' is already loaded." % [id])
		return

	var last_mission = curr_mission

	var mission := load_mission(id, true)
	curr_mission = mission
	sort_missions()
	save_missions_list()

	gui.missions_list.update_list()
	gui.workspace_mgr.add_workspace(mission)
	gui.menu_bar.update_menu()

	logs.print("add mission: ", missions.find(curr_mission), curr_mission.id)
	return mission


func get_current_mission_index() -> int:
	assert(missions.size() > 0)
	return missions.find(curr_mission)


func remove_current_mission() -> void:
	var last_idx := get_current_mission_index()
	var curr_idx: int
	logs.print("remove_current_mission: ", last_idx, curr_mission.id)

	missions.erase(curr_mission)
	if missions.size() > 0:
		curr_idx = clamp(last_idx, 0, missions.size()-1)
		curr_mission = missions[ curr_idx ]
		sort_missions()
		save_missions_list()
	else:
		curr_mission = null
		save_missions_list()
	gui.missions_list.update_list()
	gui.workspace_mgr.remove_workspace(last_idx)
	gui.menu_bar.update_menu()


func _check_file_hash(mis:Mission, path:String) -> bool:
	if path not in mis.file_hashes: return false
	var hash := FMUtils.get_file_hash(path)
	return hash == mis.file_hashes[path]


func check_mission_filesystem() -> bool:
	if missions.size() == 0: return false

	var old_list:Array[String] = curr_mission.full_filelist.duplicate()
	var new_list := Path.get_filepaths_recursive(curr_mission.paths.root)

	var changed_files: Array[String]

	if not _check_file_hash(curr_mission, curr_mission.paths.modfile):
		changed_files.append("modfile")

	if not _check_file_hash(curr_mission, curr_mission.paths.readme):
		changed_files.append("readme")

	if not _check_file_hash(curr_mission, curr_mission.paths.pkignore):
		changed_files.append("pkignore")

	if curr_mission.map_sequence.size() <= 1:
		if not Path.file_exists(curr_mission.paths.startingmap) \
		or not _check_file_hash(curr_mission, curr_mission.paths.startingmap):
			changed_files.append("map_sequence")
	else:
		if not Path.file_exists(curr_mission.paths.mapsequence)\
		or not _check_file_hash(curr_mission, curr_mission.paths.mapsequence):
			changed_files.append("map_sequence")

	if changed_files.size() == 0:
		return false

	curr_mission.full_filelist = new_list
	FMUtils.build_file_tree(curr_mission)

	for file:String in changed_files:
		if file != "map_sequence":
			load_file(curr_mission, file)
		else:
			load_map_sequence(curr_mission)
		gui.workspace_mgr.get_current_workspace().tab_package.reload_file(file)

	return true



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Playing / Packing / Editing
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func is_mission_packed(mis:Mission) -> bool:
	var pak_filepath :String = Path.join(mis.paths.root, mis.zipname)
	return Path.file_exists(pak_filepath)


func pack_mission() -> void:
	if is_save_timer_counting():
		save_mission(curr_mission, true)
	FMUtils.pack_mission(curr_mission, get_tree())
	check_mission_filesystem()


func play_mission() -> void:
	if is_save_timer_counting():
		save_mission(curr_mission, true)
	launcher.run_tdm()


func edit_mission() -> void:
	if is_save_timer_counting():
		save_mission(curr_mission, true)
	launcher.run_darkradiant()


func test_pack()    -> void:
	if is_save_timer_counting():
		save_mission(curr_mission, true)
	launcher.run_tdm_copy()
