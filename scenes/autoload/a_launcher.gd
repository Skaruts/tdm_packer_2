extends Node
# autoloaded script


signal _execution_finished(res:Path.ExecutionResults)

signal tdm_process_started
signal tdm_process_ended


# TODO: this could just be an array
const tdm_log_file1 := "DarkMod.log"
const tdm_log_file2 := "DarkMod.temp.log"

# TODO: this could just be a single variable (only one TDM process is ever stored at a time)
var pids: Dictionary    # this keeps track of a running TDM process (Process IDs)

var timer: Timer



func _ready() -> void:
	timer = Timer.new()
	timer.autostart = true
	timer.wait_time = 3
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	if not pids.size(): return
	for pid: int in pids:
		if not OS.is_process_running(pid):
			var f: Callable = pids[pid]
			f.call()
			pids.erase(pid)



func is_game_running() -> bool:
	return pids.size() > 0


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#        Threads

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
var local_threads:Array[Thread]

func run_in_local_thread(f:Callable) -> Variant:
	var t := Thread.new()
	local_threads.append(t)
	t.start(f)
	while t.is_alive():
		await get_tree().process_frame
	local_threads.erase(t)
	return t.wait_to_finish()


func run_in_global_thread(f:Callable) -> Variant:
	var t := Thread.new()
	t.start(f)
	while t.is_alive():
		await get_tree().process_frame
	return t.wait_to_finish()






func _run_app_thread(path:String, args:Array[String]) -> void:
	var res := Path.execute(path, args)
	call_deferred_thread_group("emit_signal", _execution_finished, res)




func open_fm_packer_folder() -> void:
	OS.shell_open(ProjectSettings.globalize_path("res://"))


func open_mission_folder() -> void:
	OS.shell_open(fms.curr_mission.paths.root)


func run_darkradiant() -> void:
	# TODO: support other OSs
	var exec_filepath:String = data.config.dr_path
	var arg := "fs_game=fms/%s" % [fms.curr_mission.id]

	if not Path.file_exists(exec_filepath):
		popups.show_message(
			"Error launching DarkRadiant",
			"The path to the executable is invalid."
		)
		return

	console.task("Running DarkRadiant for '%s'" % fms.curr_mission.id)
	var _pid := OS.create_process(exec_filepath, [arg])


func run_tdm() -> void:
	_run_game("Running TDM", data.config.tdm_path, fms.curr_mission.id, false, tdm_process_started, tdm_process_ended)



func _delete_folder(root_path: String, delete_root: bool) -> void:
	var files := Path.get_filepaths(root_path)
	for fpath:String in files:
		DirAccess.remove_absolute(fpath)
	if delete_root:
		DirAccess.remove_absolute(root_path)



const TEST_FOLDER_NAME := "__dp_test_mission__"
func run_tdm_mission_test() -> void:
	var mission := fms.curr_mission

	# check if source pk4 file exists
	var src_pak_file :String = Path.join(mission.paths.root, mission.zipname)
	if not Path.file_exists(src_pak_file):
		popups.show_message(
			"Error",
			"'%s' doesn't exist. You must 'Pack' the mission first." \
			% [mission.zipname]
		)
		return

	var fms_folder := Path.join(data.config.tdm_path.get_base_dir(), "fms")
	var test_path := Path.join(fms_folder, TEST_FOLDER_NAME)

	# if 'test_path' already exists, delete all files/folders in it
	if Path.dir_exists(test_path):
		_delete_folder(test_path, false)

	var err := Path.make_dir(test_path)
	if err != OK:
		popups.show_message(
			"Error",
			"Can't create testing folder at path\n    '%s'.\nERROR: %s.\n" % [test_path, Path.get_error_text(err)]
		)
		return

	# copy a modified modfile (to make the mission name different
	# from the original in the Missions List)
	var modfile := FMUtils.generate_modfile_from_mission(mission, true)
	Path.write_file(Path.join(test_path, data.MODFILE_FILENAME), modfile)

	# if the mission has an 'install_splash.tga', copy it too, as the game doesn't extract it
	# from the pk4 when the modfile already exists in the folder
	var splash_path := Path.join(mission.paths.root, "install_splash.tga")
	if Path.file_exists(splash_path) \
	and not mission.is_file_excluded(splash_path):
		var splash_dest_path := Path.join(test_path, "install_splash.tga")
		err = DirAccess.copy_absolute(splash_path, splash_dest_path)
		if err != OK:
			popups.show_message(
				"Error Copying 'install_splash.tga'",
				"Couldn't copy '%s' to the test location '%s'. ERROR: %s.\n" \
				% [mission.zipname, splash_dest_path, Path.get_error_text(err)]
			)
			return

	# copy the pk4 over to the test folder
	var dest_pak_file: String = Path.join(test_path, mission.zipname)
	err = DirAccess.copy_absolute(src_pak_file, dest_pak_file)
	if err != OK:
		popups.show_message(
			"Error Copying pak file",
			"Couldn't copy '%s' to the test location '%s'. ERROR: %s.\n" \
			% [mission.zipname, dest_pak_file, Path.get_error_text(err)]
		)
		return

	_run_game("Running TDM (isolated pk4)", data.config.tdm_path, TEST_FOLDER_NAME, true, tdm_process_started, tdm_process_ended)



func _run_game(task_name: String, exec_filepath: String,
			   mission_id: String, is_mission_testing: bool,
			   start_signal: Signal, end_signal: Signal) -> void:

	var game_dir :String = exec_filepath.get_base_dir()
	var currfm_path := Path.join(game_dir, data.CURRENT_FM_FILE)

	if not Path.file_exists(exec_filepath):
		popups.show_message(
			"Error launching TDM",
			"The path to the executable is invalid: '%s'. \n" % exec_filepath
		)
		return

	# switch the 'currentfm.txt' file to point to this fm before launching TDM
	Path.write_file(currfm_path, mission_id)

	console.task(task_name)
	var pid := OS.create_process(exec_filepath, [])
	if pid >= 0:
		start_signal.emit()

		# Since Godot can't change the CWD, TDM will create logs inside the
		# Packer's directory, and they need to be moved to TDM dir after it
		# shuts down.
		pids[pid] = func() -> void:
			logs.task("Moving TDM logs to TDM directory")
			Path.move_file(
				Path.join(data.CWD, tdm_log_file1),
				Path.join(game_dir, tdm_log_file1)
			)
			Path.move_file(
				Path.join(data.CWD, tdm_log_file2),
				Path.join(game_dir, tdm_log_file2)
			)

			console.info("TDM process ended")

			if is_mission_testing:
				console.print("removing test folder")
				var fms_folder := Path.join(data.config.tdm_path.get_base_dir(), "fms")
				var test_path := Path.join(fms_folder, TEST_FOLDER_NAME)
				_delete_folder(test_path, true)

			end_signal.emit()
