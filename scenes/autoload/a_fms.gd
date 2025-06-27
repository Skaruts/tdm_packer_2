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



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Save timer
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _process(delta: float) -> void:
	_save_timer -= delta
	if _save_timer > 0: return
	stop_timer_and_save()

var _should_reload := false
func start_save_timer(reload:bool) -> void:
	_save_timer = _save_delay
	_mission_to_save = curr_mission
	_should_reload = reload
	set_process(true)


func is_save_timer_counting() -> bool:
	return _save_timer > 0


func stop_timer_and_save() -> void:
	set_process(false)
	save_mission(_mission_to_save, _should_reload)
	_should_reload = false



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Loading
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func load_missions() -> void:
	console.task("Loading missions.")

	var cf := ConfigFile.new()
	if cf.load(data.MISSIONS_FILE) == OK:
		#logs.print(cf.get_sections())
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


func is_mission_already_loaded(id:String) -> bool:
	for m:Mission in missions:
		if m.id == id:
			return true
	return false


func _reload_mission(mis:Mission) -> void:
	load_file(mis, "pkignore")
	FMUtils.build_file_tree(mis)
	_load_mission_files(mis)
	gui.workspace_mgr.on_mission_reloaded( get_mission_index(mis) )


func soft_reload_mission(mis:Mission, force_update:=false) -> void:
	FMUtils.build_file_tree(mis)
	gui.workspace_mgr.on_mission_reloaded( get_mission_index(mis), force_update )


func load_mission(id: String, create_modfile := false) -> Mission:
	var mission := Mission.new()
	mission.id = id
	#mission.zipname = id + data.config.packname_suffix + ".pk4"
	var fm_path := Path.join(fms_folder, id)

	mission.set_paths(fm_path)
	missions.append(mission)

	if not Path.file_exists(mission.paths.modfile):
		if create_modfile:
			Path.write_file(mission.paths.modfile, data.DEFAULT_MODFILE)
		else:
			logs.error("couldn't find 'darkmod.txt' in '%s'" % fm_path)
			return mission

	mission.full_filelist = Path.get_filepaths_recursive(mission.paths.root)

	load_file(mission, "pkignore")
	_load_mission_files(mission)
	mission.update_zipname()
	FMUtils.build_file_tree(mission)

	console.print("Opened %s" % [id])

	return mission


func check_file_and_create(mis:Mission, filename:String, default_content:="") -> void:
	if not Path.file_exists(mis.paths.get(filename)):
		Path.write_file(mis.paths.get(filename), default_content)


func load_file(mis:Mission, filename:String, default_content:="") -> void:
	check_file_and_create(mis, filename, default_content)
	mis.mdata.set(filename, Path.read_file_string(mis.paths.get(filename)))
	mis.store_hash(mis.paths.get(filename))


func load_map_sequence(mis:Mission) -> void:
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


func _load_mission_files(mis:Mission) -> void:
	load_map_sequence(mis)
	load_modfile(mis)
	load_file(mis, "readme")


enum ModfileSection {
	None,
	Title,
	Author,
	Version,
	TDM_Version,
	Description,
	Map_Title,
}

func load_modfile(mis:Mission) -> void:
	check_file_and_create(mis, "modfile", data.DEFAULT_MODFILE)
	var file_string := Path.read_file_string(mis.paths.modfile)

	var map_index := -99
	var map_count := mis.mdata.map_files.size()
	mis.mdata.map_titles.clear()
	mis.mdata.map_titles.resize(map_count)

	var commit_section := \
		func(text:String, section: ModfileSection, map_index:int) -> void:
			match section:
				ModfileSection.Title:       mis.mdata.title       = text
				ModfileSection.Author:      mis.mdata.author      = text
				ModfileSection.Version:     mis.mdata.version     = text
				ModfileSection.TDM_Version: mis.mdata.tdm_version = text
				ModfileSection.Description: mis.mdata.description = text
				ModfileSection.Map_Title:
					if map_index >= mis.mdata.map_titles.size():
						mis.mdata.map_titles.resize(map_index+1)
					logs.print(map_index, map_index >= mis.mdata.map_titles.size())
					mis.mdata.map_titles[map_index] = text

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

	#console.print("Saving mission", mission.id)

	if mission.get_dirty_flag(Mission.DirtyFlags.PKIGNORE):
		save_pkignore(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.MODFILE):
		save_modfile(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.README):
		save_readme(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.MAPS):
		save_maps_file(mission, false)

	#logs.print("saving mission", reload)
	if reload:
		soft_reload_mission(mission)


func save_modfile(mis:Mission) -> void:
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


func save_readme(mis:Mission) -> void:
	_save_mission_file(mis, mis.mdata.readme, mis.paths.readme, data.README_FILENAME, Mission.DirtyFlags.README)
	mis.store_hash(mis.paths.readme)


func save_pkignore(mis:Mission) -> void:
	_save_mission_file(mis, mis.mdata.pkignore, mis.paths.pkignore, data.IGNORES_FILENAME, Mission.DirtyFlags.PKIGNORE)
	soft_reload_mission(mis)
	mis.store_hash(mis.paths.pkignore)


func _save_mission_file(mis:Mission, content:String, filepath:String, filename:String, flag:Mission.DirtyFlags, force_it:=false) -> bool:
	if not mis.get_dirty_flag(flag) and not force_it: return false
	Path.write_file(filepath, content)
	console.print("Saved '%s'" % filename)
	mis.set_dirty_flag(false, flag)
	return true


func save_maps_file(mis:Mission, reload:bool) -> bool:
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

	if reload:
		soft_reload_mission(mis)

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
	logs.print("select_mission", idx, curr_mission.id)


func add_missions(ids:Array[String]) -> void:
	if ids.size() == 0: return
	#console.task("opening mission" if ids.size() < 2 else "opening missions")

	popups.main_progress_bar.show_bar()
	popups.main_progress_bar.set_percentage(0)
	popups.main_progress_bar.set_cancel_enabled(true)

	await get_tree().process_frame
	var num_missions_processed := 0

	for i:float in ids.size():
		if popups.main_progress_bar.aborted:
			popups.main_progress_bar.hide_bar()
			break

		var id := ids[i]
		popups.main_progress_bar.set_percentage(i/ids.size())
		popups.main_progress_bar.set_text("Loading '%s'" % id)

		var mission := load_mission(id, true)
		curr_mission = mission
		gui.workspace_mgr.add_workspace(mission)

		num_missions_processed += 1
		logs.print("add mission: ", missions.find(curr_mission), curr_mission.id)
		await get_tree().process_frame

	if num_missions_processed > 0:
		popups.main_progress_bar.set_text("Updating UI")
		popups.main_progress_bar.set_percentage(0.95)
		sort_missions()
		save_missions_list()
		gui.missions_list.update_list()

		popups.main_progress_bar.set_text("All missions loaded")
		popups.main_progress_bar.set_percentage(1)

	if popups.main_progress_bar.aborted:
		popups.main_progress_bar.set_text("Aborting")

	await get_tree().create_timer(0.25).timeout
	popups.main_progress_bar.hide_bar()


func get_current_mission_index() -> int:
	assert(missions.size() > 0)
	return missions.find(curr_mission)

func get_mission_index(mission:Mission) -> int:
	assert(missions.size() > 0)
	return missions.find(mission)


func remove_current_mission() -> void:
	console.print("Closed %s" % curr_mission.id)

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


func _check_file_hash(mis:Mission, path:String) -> bool:
	if path not in mis.file_hashes: return false
	var file_hash := FMUtils.get_file_hash(path)
	return file_hash == mis.file_hashes[path]


func check_mission_filesystem() -> bool:
	if missions.size() == 0: return false
	#logs.print("check_mission_filesystem")
	#var old_list:Array[String] = curr_mission.full_filelist.duplicate()
	var new_list := Path.get_filepaths_recursive(curr_mission.paths.root)
	var changed_files: Array[String]

	if curr_mission.mdata.map_files.size() <= 1:
		if not Path.file_exists(curr_mission.paths.startingmap) \
		or not _check_file_hash(curr_mission, curr_mission.paths.startingmap):
			changed_files.append("map_sequence")
	else:
		if not Path.file_exists(curr_mission.paths.mapsequence)\
		or not _check_file_hash(curr_mission, curr_mission.paths.mapsequence):
			changed_files.append("map_sequence")

	if not _check_file_hash(curr_mission, curr_mission.paths.modfile):
		logs.print("modfile was changed externally")
		changed_files.append("modfile")

	if not _check_file_hash(curr_mission, curr_mission.paths.readme):
		changed_files.append("readme")

	if not _check_file_hash(curr_mission, curr_mission.paths.pkignore):
		changed_files.append("pkignore")


	if changed_files.size() == 0:
		return false

	curr_mission.full_filelist = new_list
	FMUtils.build_file_tree(curr_mission)

	for file:String in changed_files:
		if file == "map_sequence":
			load_map_sequence(curr_mission)
		elif file == "modfile":
			load_modfile(curr_mission)
		else:
			load_file(curr_mission, file)
		gui.workspace_mgr.get_current_workspace().tab_package.reload_file(file)

	return true



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Playing / Packing / Editing
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func is_mission_packed(mis:Mission) -> bool:
	var pak_filepath :String = Path.join(mis.paths.root, mis.zipname)
	return Path.file_exists(pak_filepath)


func force_save_mission(reload:=true) -> void:
	if is_save_timer_counting():
		_should_reload = reload
		stop_timer_and_save()


func play_mission() -> void:
	popups.show_confirmation({
		text        = "Launch TDM for\n    '%s'?" % curr_mission.mdata.title,
		ok_text     = "Yes",
		cancel_text = "No",
	})
	if not await popups.confirmation_dialog.answer:
		return

	if is_save_timer_counting():
		save_mission(curr_mission, true)
	launcher.run_tdm()


func edit_mission() -> void:
	popups.show_confirmation({
		text        = "Launch DarkRadiant for\n    '%s'?" % curr_mission.mdata.title,
		ok_text     = "Yes",
		cancel_text = "No",
	})
	if not await popups.confirmation_dialog.answer:
		return

	if is_save_timer_counting():
		save_mission(curr_mission, true)
	launcher.run_darkradiant()


func test_pack() -> void:
	popups.show_confirmation({
		text        = "Launch TDM test-version for\n    '%s'?" % curr_mission.mdata.title,
		ok_text     = "Yes",
		cancel_text = "No",
	})
	if not await popups.confirmation_dialog.answer:
		return

	if is_save_timer_counting():
		save_mission(curr_mission, true)
	launcher.run_tdm_copy()
