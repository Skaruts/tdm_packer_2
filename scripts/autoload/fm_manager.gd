extends Node
# autoloaded script



signal mission_added(mission:Mission)
signal mission_deleted(index:int)
signal mission_switched
signal missions_loaded

signal mission_saved
signal mission_reloaded
#signal pkignore_changed
#signal map_list_changed


signal mission_dirty_state_changed



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Mission stuff
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

var missions:Array = []
var curr_mission:Mission

var default_ignored_directories := Set.new(["/.git", "/savegames"])
var default_ignored_files   := Set.new([data.IGNORES_FILENAME, "bak", ".log", ".dat", ".py", ".pyc", ".pk4", ".zip", ".7z", ".rar", ".gitignore", ".gitattributes"])



func initialize() -> void:
	logs.task("Initializing FM Manager...")

	if not Path.file_exists(data.MISSIONS_FILE):
		save_missions_list()

	logs.info("FM Manager initialized")

	load_missions()

	if missions.size():
		select_mission(0)


func save_missions_list() -> void:
	var cf := ConfigFile.new()
	for m:Mission in missions:
		cf.set_value("missions", m.id, {}) # mission data is empty for now

	if cf.save(data.MISSIONS_FILE) != OK:
		logs.error("Couldn't save missions file at '%s'" % data.MISSIONS_FILE)


func load_missions() -> void:
	console.task("Loading missions.")

	var cf := ConfigFile.new()

	if cf.load(data.MISSIONS_FILE) == OK:
		logs.print(cf.get_sections())
		if not Path.file_exists(data.config.tdm_path):
			console.error("No TDM path set, or TDM path is invalid: '%s'" % data.config.tdm_path)
		elif cf.has_section("missions"):
			logs.print("lioading missions")
			for id:String in cf.get_section_keys("missions"):
				logs.print(id)
				var mission := load_mission(id)

	if missions.size():
		sort_missions()
		curr_mission = missions[0]

	console.info("Loaded %s missions." % missions.size())

	missions_loaded.emit()


func _mission_already_loaded(id:String) -> bool:
	for m:Mission in missions:
		if m.id == id:
			return true
	return false


func add_mission(id:String, no_sort:=false) -> Mission:
	if _mission_already_loaded(id):
		popups.warning_report.open({
			title= "Error",
			text = "Mission '%s' is already loaded." % [id],
		})
		popups.warning_report.close_requested
		return

	var last_mission = curr_mission

	var mission := load_mission(id)
	curr_mission = mission
	sort_missions()
	save_missions_list()

	mission_added.emit()
	mission_switched.emit()
	return mission


func get_mission_index() -> int:
	if missions.size():
		return missions.find(curr_mission)
	return 0


func remove_mission() -> void:
	var idx := get_mission_index()

	missions.erase(curr_mission)
	if missions.size():
		curr_mission = missions[ clamp(idx, 0, missions.size()-1) ]
	else:
		curr_mission = null

	sort_missions()
	save_missions_list()

	mission_deleted.emit(idx)
	mission_switched.emit()


func select_mission(index:int) -> void:
	assert(index >= 0 and index < missions.size())
	curr_mission = missions[index]
	mission_switched.emit()


func sort_missions() -> void:
	missions.sort_custom(func(a:Mission, b:Mission) -> bool:
		return a.id < b.id
	)



func validate_mission_path(fm_path:String) -> bool:
	if not Path.file_exists(Path.join(fm_path, data.MODFILE_FILENAME)):
		return false

	#if not Path.dir_exists(Path.join(fm_path, "maps")):
		#return false

	#if  not Path.file_exists(Path.join(fm_path, data.STARTINGMAP_FILENAME))    \
	#and not Path.file_exists(Path.join(fm_path, data.MAPSEQUENCE_FILENAME)):
		#return false

	return true

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Loading

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func load_mission(id:String) -> Mission:
	console.print("Loading '%s'" % [id])

	var mission := Mission.new(id)
	var fms_dir := Path.join(data.config.tdm_path.get_base_dir(), "fms")
	var fm_path := Path.join(fms_dir, id)

	missions.append(mission)

	if not Path.dir_exists(fm_path):
		console.error("couldn't load '%s': directory not found (%s)." % [id, fm_path])
		return mission

	if not Path.file_exists(Path.join(fm_path, data.MODFILE_FILENAME)):
		logs.error("couldn't find 'darkmod.txt' in '%s'" % fm_path)
		return mission

	mission.zipname = id + ".pk4"

	mission.path_root      = fm_path
	mission.path_root_test = Path.join(Path.join(data.config.tdm_copy_path.get_base_dir(), "fms"), id)
	mission.path_maps      = Path.join(fm_path, "maps")

	mission.path_defs      = Path.join(fm_path, "defs")
	mission.path_guis      = Path.join(fm_path, "guis")
	mission.path_materials = Path.join(fm_path, "materials")
	mission.path_particles = Path.join(fm_path, "particles")
	mission.path_skins     = Path.join(fm_path, "skins")
	mission.path_xdata     = Path.join(fm_path, "xdata")
	mission.path_scripts   = Path.join(fm_path, "script")

	_load_pkignore(mission, fm_path)
	_load_mission_files(mission, fm_path)
	FMUtils.build_file_tree(mission)

	return mission



func _load_pkignore(mission:Mission, fm_path:String) -> void:
	var pkignore_path := Path.join(fm_path, data.IGNORES_FILENAME)

	if not Path.file_exists(pkignore_path):
		Path.write_file(pkignore_path, "")

	mission.pkignore = Path.read_file_string(pkignore_path)


func _load_mission_files(mission:Mission, fm_path:String) -> void:
	var modfile_path := Path.join(fm_path, data.MODFILE_FILENAME)
	mission.modfile = Path.read_file_string(modfile_path)

	var readme_path := Path.join(fm_path, data.README_FILENAME)
	if not Path.file_exists(readme_path):
		Path.write_file(readme_path, "")
	mission.readme = Path.read_file_string(readme_path)

	var startingmap_path := Path.join(fm_path, data.STARTINGMAP_FILENAME)
	if Path.file_exists(startingmap_path):
		var str := Path.read_file_string(startingmap_path)
		mission.map_names = [str.strip_edges()]
	else:
		var tdm_mapsequence_path := Path.join(fm_path, data.MAPSEQUENCE_FILENAME)
		if Path.file_exists(tdm_mapsequence_path):
			var str := Path.read_file_string(tdm_mapsequence_path)
			var lines := str.strip_edges().split('\n', false)

			for line:String in lines:
				line = line.substr( line.find(':')+1 )
				line = line.strip_edges()
				mission.map_names.append(line)


func _reload_mission(mis:Mission) -> void:
	_load_pkignore(mis, mis.path_root)
	FMUtils.build_file_tree(mis)
	_load_mission_files(mis, mis.path_root)
	mission_reloaded.emit()


func _soft_reload_mission(mis:Mission) -> void:
	FMUtils.build_file_tree(mis)
	mission_reloaded.emit()





#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Saving

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
# TODO: this function shouldn't be here
func pack_mission() -> void:
	FMUtils.pack_mission(curr_mission, get_tree())


func save_mission(mission:Mission) -> void:
	if not mission.dirty: return

	if mission.get_dirty_flag(Mission.DirtyFlags.PKIGNORE):
		save_pkignore(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.MODFILE):
		save_modfile(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.README):
		save_readme(mission)

	mission_saved.emit()


func save_pkignore(mission:Mission) -> void:
	_save_essential_mission_file(mission, mission.pkignore, data.IGNORES_FILENAME, Mission.DirtyFlags.PKIGNORE)
	_soft_reload_mission(mission)

func save_modfile(mission:Mission) -> void:
	_save_essential_mission_file(mission, mission.modfile, data.MODFILE_FILENAME, Mission.DirtyFlags.MODFILE)

func save_readme(mission:Mission) -> void:
	_save_essential_mission_file(mission, mission.readme, data.README_FILENAME, Mission.DirtyFlags.README)



func _save_essential_mission_file(mis:Mission, content:String, filename:String, flag:Mission.DirtyFlags, force_it:=false) -> bool:
	if not mis.get_dirty_flag(flag) and not force_it: return false
	var path := Path.join(mis.path_root, filename)
	Path.write_file(path, content)
	console.print("Saved '%s'" % filename)
	mis.set_dirty_flag(false, flag)
	return true


func save_maps_file(mis:Mission) -> bool:
	# TODO: there's no save state in the map files

	var map_names := mis.map_names
	var startingmap := Path.join(mis.path_root, data.STARTINGMAP_FILENAME)
	var mapsequence := Path.join(mis.path_root, data.MAPSEQUENCE_FILENAME)

	if map_names.size() <= 1:
		if Path.file_exists(mapsequence):
			DirAccess.remove_absolute(mapsequence)

		var map:String
		if map_names.size(): map = map_names[0]
		_save_essential_mission_file(mis, map, data.STARTINGMAP_FILENAME, Mission.DirtyFlags.MAPS, true)
	else:
		if Path.file_exists(startingmap):
			DirAccess.remove_absolute(startingmap)

		var str:String
		for i in map_names.size():
			str += "Mission %s: %s\n" % [i+1, map_names[i]]
		_save_essential_mission_file(mis, str, data.MAPSEQUENCE_FILENAME, Mission.DirtyFlags.MAPS, true)

	_soft_reload_mission(mis)
	return true
