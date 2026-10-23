extends Node
# autoloaded script

enum MissionWarning {
	NO_MAP_SEQUENCE,
	MAP_IS_EXCLUDED,
	ALL_FILES_EXCLUDED,
}

var warning_strings: Array[String] = []

var mission_datas: ConfigFile

var missions : Array[Mission]
# var missing_missions: Array[String]
var curr_mission : Mission

var _save_timer := 0.0
var _save_delay := 1.0
var _mission_to_save : Mission

var missing_missions: Array[String]


func _ready() -> void:
	set_process(false)

	warning_strings.resize( MissionWarning.size() )
	warning_strings[MissionWarning.NO_MAP_SEQUENCE]    = "map sequence contains no maps"
	warning_strings[MissionWarning.MAP_IS_EXCLUDED]    = "map sequence contains maps excluded from the pk4"
	warning_strings[MissionWarning.ALL_FILES_EXCLUDED] = "all mission files are excluded from the pk4"

	mission_datas = ConfigFile.new()
	init_mission_datas()


func initialize() -> void:
	# logs.task("Initializing fms singleton...")
	if not Path.file_exists(data.config.tdm_path):
		console.warning("No TDM path set, or TDM path is invalid: '%s'" % data.config.tdm_path)
		return

	update_mission_datas()

	console.task("Loading missions.")

	if mission_datas.has_section("missions"):
		var ids := mission_datas.get_section_keys("missions")
		for id: String in ids:
			var mission := load_mission(id)
			missions.append(mission)

	curr_mission = null
	if missions.size():
		sort_missions()
		# Don't call 'select_mission(0)' here. It's not needed, and it will
		# call 'check_mission_filesystem()', which is undesirable at this point
		curr_mission = missions[0]

	console.info("Loaded %s missions." % (missions.size() - missing_missions.size()))

	save_mission_datas()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Save timer
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _process(delta: float) -> void:
	_save_timer -= delta
	if _save_timer > 0: return
	stop_timer_and_save()

var _should_reload := false
func start_save_timer(reload: bool) -> void:
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



func check_mission_warnings(mis: Mission) -> void:
	mis.warnings.clear()

	# check if all files are excluded
	if mis.inc_file_count == 0:
		mis.warnings[MissionWarning.ALL_FILES_EXCLUDED] = warning_strings[MissionWarning.ALL_FILES_EXCLUDED]

	# check if it has at least one map in the map sequence
	if mis.mdata.map_files.size() == 0:
		mis.warnings[MissionWarning.NO_MAP_SEQUENCE] = warning_strings[MissionWarning.NO_MAP_SEQUENCE]

	# check if any of the maps in the map sequence are excluded from the pk4
	for i: int in mis.mdata.map_files.size():
		var mf := mis.mdata.map_files[i]
		if mf.name == "": continue
		var is_excluded := mis.is_file_excluded(
			Path.join(mis.paths.maps, mf.name + ".map")
		)

		if is_excluded:
			mis.warnings[MissionWarning.MAP_IS_EXCLUDED] = warning_strings[MissionWarning.MAP_IS_EXCLUDED]


func get_mission_warnings_string(mis: Mission) -> String:
	var text := "Warnings:\n"
	for key in mis.warnings:
		var warn := mis.warnings[key]
		text += "\t- " + warn + "\n"

	return text





#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Loading
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
# const DEFAULT_MISSION_DATA := {
# 	opened   = false,
# 	readonly = true,
# 	edited_files = [],
# }

const DATA_VERSION := 2


func init_mission_datas() -> void:
	if not mission_datas.load(data.MISSIONS_FILE) == OK:
		mission_datas.set_value("info", "version", DATA_VERSION)
		# mission_datas.set_value("info", "editable", [])

		if not mission_datas.save(data.MISSIONS_FILE) == OK:
			logs.error("Couldn't save missions file at '%s'" % data.MISSIONS_FILE)

	if not mission_datas.has_section("info"):
		mission_datas.set_value("info", "version", DATA_VERSION)
		# mission_datas.set_value("info", "editable", [])

		# convert to new version
		if mission_datas.has_section("missions"):
			var opened_missions := mission_datas.get_section_keys("missions")
			for id in opened_missions:
				mission_datas.set_value("missions", id, [])

		# var mission_ids := FMUtils.get_mission_id_list()
		# mission_datas.clear()
		# for id in mission_ids:
		# 	var md := DEFAULT_MISSION_DATA.duplicate()
		# 	if id in opened_missions:
		# 		md.opened = true
		# 	mission_datas.set_value("missions", id, md)




func save_mission_datas() -> void:
	if data.config.tdm_path == "": return
	for m in missions:
		var files: Array
		for path: String in m.mdata.edited_files:
			var rel_path := _get_relative_file_path(path, m.id)
			files.append(rel_path)
		mission_datas.set_value("missions", m.id, files)

	if mission_datas.save(data.MISSIONS_FILE) != OK:
		logs.error("Couldn't save missions file at '%s'" % data.MISSIONS_FILE)


func update_mission_datas() -> void:
	missing_missions.clear()

	# check newly created missions
	# for id in mission_ids:
		# if not mission_datas.has_section_key("missions", id):
			# mission_datas.set_value("missions", id, DEFAULT_MISSION_DATA.duplicate())

	if data.config.tdm_path == "":
		return

	var mission_ids := FMUtils.get_mission_id_list()

	if mission_datas.has_section("editable"):
		for id in mission_datas.get_section_keys("editable"):
			if id in mission_ids: continue
			mission_datas.erase_section_key("editable", id)

	if mission_datas.has_section("missions"):
		# check deleted missions
		for id in mission_datas.get_section_keys("missions"):
			if id in mission_ids: continue
			missing_missions.append(id)
			mission_datas.erase_section_key("missions", id)


		# for id in mission_datas.get_section_keys("missions"):
		# 	var md: Dictionary = mission_datas.get_value("missions", id, null)
		# 	if not "edited_files" in md:
		# 		md.edited_files = []

		save_mission_datas()

		if missing_missions.size() > 0:
			var message := "Couldn't load the following missions:\n\n"
			for id: String in missing_missions:
				# var md: Dictionary = mission_datas.get_value("missions", id, null)
				# if not md.missing: continue
				message += id + '\n'
			popups.show_message("Warning", message)







func is_mission_already_loaded(id: String) -> bool:
	for m: Mission in missions:
		if m.id == id: return true
	return false


func _reload_mission(mis: Mission) -> void:
	FMUtils.load_or_create_file(mis, "pkignore")
	FMUtils.build_file_tree(mis)
	_load_mission_files(mis)
	gui.on_mission_reloaded( get_mission_index(mis) )


func soft_reload_mission(mis: Mission, force_update := false) -> void:
	FMUtils.build_file_tree(mis)
	gui.on_mission_reloaded( get_mission_index(mis), force_update )



func load_mission(id: String) -> Mission:
	assert(data.config.tdm_path != "")
	var fms_folder := Path.join(data.config.tdm_path.get_base_dir(), "fms")

	var mission := Mission.new()
	mission.id = id

	var fm_path := Path.join(fms_folder, id)
	if not Path.dir_exists(fm_path):
		return null
	mission.set_paths(fm_path)
	assert(Path.dir_exists(fm_path))

	mission.full_filelist = Path.get_filepaths_recursive(mission.paths.root)
	FMUtils.load_or_create_file(mission, "pkignore")
	_load_mission_files(mission)
	mission.update_zipname()
	FMUtils.build_file_tree(mission)
	console.print("Opened %s" % [id])

	check_mission_warnings(mission)

	return mission


func _load_mission_files(mis: Mission) -> void:
	FMUtils.load_map_sequence(mis)
	FMUtils.load_modfile(mis)
	FMUtils.load_or_create_file(mis, "readme")

	var files: Array = mission_datas.get_value("missions", mis.id, [])
	FMUtils.load_edited_files(files, mis)

	# for f in missing_files:
	# 	md.edited_files.erase(f)


func is_mission_opened(id: String) -> bool:
	if id == "": return false
	for m in missions:
		if m.id == id: return true
	return false


# func set_mission_opened(id: String, opened: bool) -> void:
# 	var md: Dictionary = mission_datas.get_value("missions", id, null)
# 	assert(md != null)
# 	md.opened = opened


func is_mission_readonly(id: String) -> bool:
	return not mission_datas.has_section_key("editable", id)


func set_mission_readonly(id: String, enable: bool) -> void:
	var editable := not enable # to make this less confusing

	if editable:
		if mission_datas.has_section("editable") \
		and mission_datas.has_section_key("editable", id): return
		mission_datas.set_value("editable", id, true)
	else:
		if not mission_datas.has_section("editable"): return
		if not mission_datas.has_section_key("editable", id): return
		mission_datas.erase_section_key("editable", id)

	save_mission_datas()

	var mis: Mission = get_mission_with_id(id)
	if mis == null: return

	# _reload_mission( get_mission_with_id(id) )
	gui.update_workspaces()
	gui.on_mission_reloaded( get_mission_index(mis) )
	gui.update_missions_list()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Saving
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

func _base_files_exist(mis: Mission) -> bool:
	if not Path.file_exists( mis.paths.get("modfile") ): return false
	if not Path.file_exists( mis.paths.get("readme") ):  return false

	if  not Path.file_exists( mis.paths.get("startingmap") ) \
	and not Path.file_exists( mis.paths.get("mapsequence") ):
		return false

	return true

func _create_base_files(mis: Mission) -> void:
	FMUtils.create_mission_file(mis, "modfile", data.DEFAULT_MODFILE)
	FMUtils.create_mission_file(mis, "readme", "")
	FMUtils.create_mission_file(mis, "startingmap", "")



func save_mission(mission: Mission, reload := false) -> void:
	if not mission.dirty or fms.is_mission_readonly(mission.id):
		return

	# if not _base_files_exist():
	# 	_create_base_files()

	if mission.get_dirty_flag(Mission.DirtyFlags.PKIGNORE):
		FMUtils.save_pkignore(mission)
		reload = true

	if mission.get_dirty_flag(Mission.DirtyFlags.MODFILE):
		FMUtils.save_modfile(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.README):
		FMUtils.save_readme(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.MAPS):
		FMUtils.save_maps_file(mission)

	if mission.get_dirty_flag(Mission.DirtyFlags.FILES):
		var files: Array = mission_datas.get_value("missions", mission.id, [])
		FMUtils.save_edited_files(files, mission)

	#logs.print("saving mission", reload)
	if reload:
		soft_reload_mission(mission)
		gui.update_missions_list()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Misc
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func sort_missions() -> void:
	missions.sort_custom(func(a: Mission, b: Mission) -> bool:
		return a.id < b.id
	)


func select_mission(idx: int) -> void:
	assert(idx >= 0 and idx < missions.size())
	curr_mission = missions[idx]
	logs.print("select_mission", idx, curr_mission.id)

	check_mission_filesystem(curr_mission)

	gui.missions_list_update_buttons()
	gui.select_workspace( get_current_mission_index() )


func add_missions(ids: Array[String]) -> void:
	if ids.size() == 0: return
	#console.task("opening mission" if ids.size() < 2 else "opening missions")

	popups.main_progress_bar.show_bar()
	popups.main_progress_bar.set_percentage(0)
	popups.main_progress_bar.set_cancel_enabled(true)

	await get_tree().process_frame
	var num_missions_processed := 0

	for i: float in ids.size():
		if popups.main_progress_bar.aborted:
			popups.main_progress_bar.hide_bar()
			break

		var id := ids[i]
		popups.main_progress_bar.set_percentage(i/ids.size())
		popups.main_progress_bar.set_text("Loading '%s'" % id)

		var mission := load_mission(id)
		missions.append(mission)
		# set_mission_opened(mission.id, true)

		curr_mission = mission
		gui.add_workspace(mission)

		num_missions_processed += 1
		logs.print("add mission: ", missions.find(curr_mission), curr_mission.id)
		await get_tree().process_frame

	if num_missions_processed > 0:
		popups.main_progress_bar.set_text("Updating UI")
		popups.main_progress_bar.set_percentage(0.95)
		sort_missions()
		save_mission_datas()
		gui.update_missions_list()

		popups.main_progress_bar.set_text("All missions loaded")
		popups.main_progress_bar.set_percentage(1)

	if popups.main_progress_bar.aborted:
		popups.main_progress_bar.set_text("Aborting")

	await get_tree().create_timer(0.25).timeout
	popups.main_progress_bar.hide_bar()


func get_current_mission_index() -> int:
	assert(missions.size() > 0)
	return missions.find(curr_mission)


func get_mission_index(mission: Mission) -> int:
	assert(missions.size() > 0)
	assert(mission != null)
	return missions.find(mission)


func get_mission_at_index(index: int) -> Mission:
	assert(missions.size() > 0)
	return missions[index]


func _erase_mission(mis: Mission) -> void:
	assert(mis != null)
	missions.erase(mis)

	if mission_datas.has_section("missions")\
	and mission_datas.has_section_key("missions", mis.id):
		mission_datas.erase_section_key("missions", mis.id)

	# if mission_datas.has_section("editable")\
	# and mission_datas.has_section_key("editable", mis.id):
	# 	mission_datas.erase_section_key("editable", mis.id)

	# if mis.id in missing_missions:
	# 	missing_missions.erase(mis.id)


func remove_mission(mis: Mission) -> void:
	console.print("Closed %s" % mis.id)

	var last_idx := get_current_mission_index()

	# set_mission_opened(mis.id, false)
	_erase_mission(mis)

	# determine current mission
	if missions.size() > 0:
		var idx: int = missions.find(curr_mission)
		if idx == -1:
			idx = clamp(last_idx, 0, missions.size()-1)
		curr_mission = missions[ idx ]
		#sort_missions()
	else:
		curr_mission = null

	save_mission_datas()

	gui.update_missions_list()
	gui.remove_workspace(last_idx)





func check_mission_filesystem(mis: Mission) -> bool:
	#logs.print("check_mission_filesystem")
	#var old_list:Array[String] = mis.full_filelist.duplicate()

	var changed_files: Array[String]

	if mis.mdata.map_files.size() <= 1:
		if not Path.file_exists(mis.paths.startingmap) \
		or not FMUtils.check_file_hash(mis, mis.paths.startingmap):
			changed_files.append("map_sequence")
	else:
		if not Path.file_exists(mis.paths.mapsequence)\
		or not FMUtils.check_file_hash(mis, mis.paths.mapsequence):
			changed_files.append("map_sequence")

	if not FMUtils.check_file_hash(mis, mis.paths.modfile):
		# logs.print("modfile was changed externally")
		changed_files.append("modfile")

	if not FMUtils.check_file_hash(mis, mis.paths.readme):
		changed_files.append("readme")

	if not FMUtils.check_file_hash(mis, mis.paths.pkignore):
		changed_files.append("pkignore")

	if not FMUtils.check_edited_files_changed(mis):
		changed_files.append("edited_files")


	if changed_files.size() == 0:
		return false

	mis.update_zipname()
	mis.full_filelist = Path.get_filepaths_recursive(mis.paths.root)
	FMUtils.build_file_tree(mis)

	for file: String in changed_files:
		if file == "map_sequence":
			FMUtils.load_map_sequence(mis)
			gui.get_current_workspace().tab_package.reload_file(file)
		elif file == "modfile":
			FMUtils.load_modfile(mis)
			gui.get_current_workspace().tab_package.reload_file(file)
		elif file == "edited_files":
			var files: Array = mission_datas.get_value("missions", mis.id, [])
			FMUtils.load_edited_files(files, mis)
		else:
			FMUtils.load_or_create_file(mis, file)
			gui.get_current_workspace().tab_package.reload_file(file)

	return true


func _replace_mission(old_mis: Mission) -> void:
	var idx := missions.find(old_mis)
	_erase_mission(old_mis)
	gui.remove_workspace(idx)

	var new_mis := load_mission(old_mis.id)
	# var md: Dictionary = mission_datas.get_value("missions", new_mis.id, null)
	#new_mis.readonly = md.readonly
	missions.append(new_mis)

	sort_missions()
	gui.add_workspace(new_mis)


func get_mission_with_id(id: String) -> Mission:
	for m: Mission in missions:
		if m.id == id:
			return m
	return null


func check_missions_on_focus_in() -> void:
	if data.config.tdm_path == "": return
	update_mission_datas()

	for id: String in missing_missions:
		var mission := get_mission_with_id(id)

		# if mission isn't open, skip it
		if mission == null: continue

		var mis_idx := get_mission_index(mission)
		_erase_mission(mission)

		if missions.size() > 0:
			var idx: int = missions.find(curr_mission)
			if idx == -1:
				idx = clamp(mis_idx, 0, missions.size()-1)
			curr_mission = missions[ idx ]
		else:
			curr_mission = null
		gui.update_missions_list()
		gui.remove_workspace(mis_idx)


	# # check for missions that are no longer missing
	# var non_missing_count := 0
	# var new_missing_missions: Array[String]

	# for id in mission_datas.get_section_keys("missions"):
	# 	var md: Dictionary = mission_datas.get_value("missions", id, null)
	# 	assert(md != null)
	# 	if not md.opened: continue

	# 	var mis: Mission = get_mission_with_id(id)
	# 	if md.missing and not id in missing_missions:  # just went missing
	# 		new_missing_missions.append(mis)
	# 	elif not md.missing and id in missing_missions:  # no longer missing
	# 		_replace_mission(mis)
	# 		non_missing_count += 1

	# # report on missing missions
	# var last_idx := missions.find(curr_mission)

	# if new_missing_missions.size() > 0:
	# 	var message := "The following missions seem to be missing\n(may have been renamed or deleted):\n\n"
	# 	for id: String in new_missing_missions:
	# 		message += id + '\n'

	# 	popups.show_message( "Warning", message )


	# # if missions were added or removed, sort the list
	# if new_missing_missions.size() > 0 or non_missing_count > 0:
	# 	sort_missions()
	# 	# save_mission_datas()
	# 	curr_mission = missions[last_idx]

	# update the missions and the UI
	for m in missions:
		FMUtils.build_file_tree(m)
		# _load_mission_files(m)
		check_mission_filesystem(m)
		gui.on_mission_reloaded( get_mission_index(m), true )

	gui.update_missions_list()
	gui.update_workspaces()



func _get_relative_file_path(path: String, id: String) -> String:
	var idx := path.find(id)
	assert(idx != -1)
	var rel_path := path.left(idx+id.length()+1)
	return rel_path









func add_edited_file_to_mission(mis: Mission, path: String) -> void:
	mis.add_edited_file(path)
	var files: Array = mission_datas.get_value("missions", mis.id, [])
	var rel_path := _get_relative_file_path(path, mis.id)
	if not rel_path in files:
		files.append(rel_path)
		# TODO: check if this is necessary
		# mission_datas.set_value("missions", mis.id, files)
		save_mission_datas()


func remove_edited_file_from_mission(mis: Mission, path: String) -> void:
	fms.force_save_mission()
	mis.remove_edited_file(path)
	var files: Array = mission_datas.get_value("missions", mis.id, [])
	var rel_path := _get_relative_file_path(path, mis.id)
	files.erase(rel_path)
	# TODO: check if this is necessary
	# mission_datas.set_value("missions", mis.id, files)
	save_mission_datas()

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Playing / Packing / Editing
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func is_mission_packed(mis: Mission) -> bool:
	var pak_filepath: String = Path.join(mis.paths.root, mis.zipname)
	return Path.file_exists(pak_filepath)


func force_save_mission(reload := true) -> void:
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
		text        = "Launch TDM with isolated pk4 for\n    '%s'?" % curr_mission.mdata.title,
		ok_text     = "Yes",
		cancel_text = "No",
	})

	if not await popups.confirmation_dialog.answer:
		return

	if is_save_timer_counting():
		save_mission(curr_mission, true)

	launcher.run_pk4_isolated()
