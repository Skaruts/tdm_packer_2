extends Node
# autoloaded script


# TODO: maybe 'fms_folder' shouldn't exist (multiple sources of truth)


var fms_folder : String  # TODO:

var missions : Array[Mission]
var missing_missions: Array[String]
var curr_mission : Mission

var _save_timer := 0.0
var _save_delay := 1.0
var _mission_to_save : Mission



func initialize() -> void:
	logs.task("Initializing fms singleton...")

	if not Path.file_exists(data.MISSIONS_FILE):
		save_missions_list()

	update_folders()
	load_all_missions()

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
func load_all_missions() -> void:
	console.task("Loading missions.")

	var cf := ConfigFile.new()
	if cf.load(data.MISSIONS_FILE) == OK:
		#logs.print(cf.get_sections())
		if not Path.file_exists(data.config.tdm_path):
			console.warning("No TDM path set, or TDM path is invalid: '%s'" % data.config.tdm_path)
		elif cf.has_section("missions"):
			logs.print("loading missions")
			var keys := cf.get_section_keys("missions")
			for id: String in keys:
				var val: Dictionary = cf.get_value("missions", id, {locked=false})
				load_mission(id, false, val.locked)

	if missing_missions.size() > 0:
		save_missions_list()
		var message := "Couldn't load the following missions:\n\n"
		for id:String in missing_missions:
			message += id + '\n'
		popups.show_message("Warning", message)

	if missions.size():
		sort_missions()
		curr_mission = missions[0]

	console.info("Loaded %s missions." % (missions.size() - missing_missions.size()))


func is_mission_already_loaded(id:String) -> bool:
	for m:Mission in missions:
		if m.id == id:
			return true
	return false


func _reload_mission(mis:Mission) -> void:
	FMUtils.load_file(mis, "pkignore")
	FMUtils.build_file_tree(mis)
	_load_mission_files(mis)
	gui.workspace_mgr.on_mission_reloaded( get_mission_index(mis) )


func soft_reload_mission(mis:Mission, force_update:=false) -> void:
	FMUtils.build_file_tree(mis)
	gui.workspace_mgr.on_mission_reloaded( get_mission_index(mis), force_update )


func load_mission(id: String, create_modfile := false, locked := true) -> Mission:
	var mission := Mission.new()
	mission.id = id
	mission.locked = locked

	var fm_path := Path.join(fms_folder, id)

	mission.set_paths(fm_path)
	missions.append(mission)

	if not Path.dir_exists(fm_path):
		mission.missing = true
		missing_missions.append(id)
		console.warning("Couldn't open mission '%s' (not found)" % [id])
		return mission

	if not locked:
		if not Path.file_exists(mission.paths.modfile):
			if create_modfile:
				Path.write_file(mission.paths.modfile, data.DEFAULT_MODFILE)
			else:
				logs.error("couldn't find 'darkmod.txt' in '%s'" % fm_path)
				return mission

	mission.full_filelist = Path.get_filepaths_recursive(mission.paths.root)

	FMUtils.load_file(mission, "pkignore")
	_load_mission_files(mission)
	mission.update_zipname()
	FMUtils.build_file_tree(mission)

	console.print("Opened %s" % [id])

	return mission


func _load_mission_files(mis: Mission) -> void:
	FMUtils.load_map_sequence(mis)
	FMUtils.load_modfile(mis)
	FMUtils.load_file(mis, "readme")



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Saving
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func save_missions_list() -> void:
	var cf := ConfigFile.new()
	for m:Mission in missions:
		logs.print(m.locked)
		cf.set_value("missions", m.id, {locked=m.locked}) # mission data is empty for now

	if cf.save(data.MISSIONS_FILE) != OK:
		logs.error("Couldn't save missions file at '%s'" % data.MISSIONS_FILE)


func save_mission(mission:Mission, reload:=false) -> void:
	if not mission.dirty or mission.missing: return

	#console.print("Saving mission", mission.id)

	if mission.get_dirty_flag(Mission.DirtyFlags.PKIGNORE):
		FMUtils.save_pkignore(mission)
		reload = true

	if mission.get_dirty_flag(Mission.DirtyFlags.MODFILE):
		FMUtils.save_modfile(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.README):
		FMUtils.save_readme(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.MAPS):
		FMUtils.save_maps_file(mission)

	#logs.print("saving mission", reload)
	if reload:
		soft_reload_mission(mission)



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
	logs.print("select_mission", idx, curr_mission.id)
	if not curr_mission.missing:
		check_mission_filesystem(curr_mission)
	gui.missions_list.update_buttons()
	gui.workspace_mgr.select_workspace(get_current_mission_index())


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


func _erase_mission(mis:Mission) -> void:
	missions.erase(mis)
	if mis.id in missing_missions:
		missing_missions.erase(mis.id)


func remove_mission(mis:Mission) -> void:
	console.print("Closed %s" % mis.id)

	var last_idx := get_current_mission_index()

	logs.print("remove_current_mission: ", last_idx, mis.id)

	_erase_mission(mis)

	if missions.size() > 0:
		var idx: int = missions.find(curr_mission)
		if idx == -1:
			idx = clamp(last_idx, 0, missions.size()-1)
		curr_mission = missions[ idx ]
		#sort_missions()
	else:
		curr_mission = null

	save_missions_list()

	gui.missions_list.update_list()
	gui.workspace_mgr.remove_workspace(last_idx)


func _check_file_hash(mis:Mission, path:String) -> bool:
	if path not in mis.file_hashes: return false
	var file_hash := FMUtils.get_file_hash(path)
	return file_hash == mis.file_hashes[path]


func check_mission_filesystem(mis:Mission) -> bool:
	#logs.print("check_mission_filesystem")
	#var old_list:Array[String] = mis.full_filelist.duplicate()
	var new_list := Path.get_filepaths_recursive(mis.paths.root)
	var changed_files: Array[String]

	if mis.mdata.map_files.size() <= 1:
		if not Path.file_exists(mis.paths.startingmap) \
		or not _check_file_hash(mis, mis.paths.startingmap):
			changed_files.append("map_sequence")
	else:
		if not Path.file_exists(mis.paths.mapsequence)\
		or not _check_file_hash(mis, mis.paths.mapsequence):
			changed_files.append("map_sequence")

	if not _check_file_hash(mis, mis.paths.modfile):
		logs.print("modfile was changed externally")
		changed_files.append("modfile")

	if not _check_file_hash(mis, mis.paths.readme):
		changed_files.append("readme")

	if not _check_file_hash(mis, mis.paths.pkignore):
		changed_files.append("pkignore")


	if changed_files.size() == 0:
		return false

	mis.update_zipname()
	mis.full_filelist = new_list
	FMUtils.build_file_tree(mis)

	for file:String in changed_files:
		if file == "map_sequence":
			FMUtils.load_map_sequence(mis)
		elif file == "modfile":
			FMUtils.load_modfile(mis)
		else:
			FMUtils.load_file(mis, file)
		gui.workspace_mgr.get_current_workspace().tab_package.reload_file(file)

	return true


func _replace_mission(mis:Mission) -> void:
	var idx := missions.find(mis)
	_erase_mission(mis)
	gui.workspace_mgr.remove_workspace(idx)

	mis = load_mission(mis.id)
	sort_missions()
	gui.workspace_mgr.add_workspace(mis)


func check_missions_on_focus_in() -> void:
	var new_missing_missions: Array[String]
	var missions_changed := false

	var last_idx := missions.find(curr_mission)

	for mission:Mission in missions:
		if Path.dir_exists(mission.paths.root):
			if mission.id in missing_missions:
				missing_missions.erase(mission.id)
				_replace_mission(mission)
				missions_changed = true
			else:
				check_mission_filesystem(mission)
		else:
			mission.missing = true
			if not mission.id in missing_missions:
				console.warning("Couldn't find mission '%s' (may be renamed or deleted)" % [mission.id])
				new_missing_missions.append(mission.id)
			missions_changed = true
			missing_missions.append(mission.id)

	if new_missing_missions.size() > 0:
		var message := "The following missions seem to be missing\n(may have been renamed or deleted):\n\n"
		for id:String in new_missing_missions:
			message += id + '\n'

		popups.show_message( "Warning", message )

	if not missions_changed: return

	sort_missions()
	save_missions_list()
	curr_mission = missions[last_idx]
	gui.missions_list.update_list()
	gui.workspace_mgr.update_workspaces()



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
