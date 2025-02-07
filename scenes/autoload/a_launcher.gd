extends Node
# autoloaded script


signal _execution_finished(res:Path.ExecutionResults)

signal tdm_process_started
signal tdm_process_ended
signal tdm_copy_process_started
signal tdm_copy_process_ended


const tdm_log_file1 := "DarkMod.log"
const tdm_log_file2 := "DarkMod.temp.log"

# to keep track of a running TDM process
var pids:Dictionary# Array[int]
var timer:Timer




func _ready() -> void:
	timer = Timer.new()
	timer.autostart = true
	timer.wait_time = 3
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)


func _on_timer_timeout() -> void:
	#logs.print("checking pids: ", pids.size())
	if not pids.size(): return
	for pid in pids:
		if not OS.is_process_running(pid):
			var f:Callable = pids[pid]
			f.call()
			pids.erase(pid)


func _run_app_thread(path:String, args:Array[String]) -> void:
	var res := Path.execute(path, args)
	call_deferred_thread_group("emit_signal", "_execution_finished", res)




func open_fm_packer_folder() -> void:
	OS.shell_open(ProjectSettings.globalize_path("res://"))

func open_mission_folder() -> void:
	OS.shell_open(fms.curr_mission.paths.root)

func open_mission_test_folder() -> void:
	OS.shell_open(fms.curr_mission.paths.test_root)




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
	var pid := OS.create_process(exec_filepath, [arg])







func run_tdm() -> void:
	_run_game("Running TDM", fms.curr_mission, data.config.tdm_path, "tdm_process_started", "tdm_process_ended")


func run_tdm_copy() -> void:
	var mission := fms.curr_mission
	# check if source pk4 file exists
	var src_pak_file :String = Path.join(mission.paths.root, mission.zipname)
	if not Path.file_exists(src_pak_file):
		popups.show_message(
			"Error",
			"'%s' doesn't exist. You must 'Pack' the mission first." % [mission.zipname]
		)
		return

	# if destination path doesn't exist, create it
	var dest_pak_file :String = Path.join(mission.paths.test_root, mission.zipname)
	if not Path.dir_exists(mission.paths.test_root):
		var err := Path.make_dir(mission.paths.test_root)
		if err != OK:
			popups.show_message(
				"Error",
				"Can't create destination path\n    '%s'.\nERROR: %s.\n" % [mission.paths.test_root, Path.get_error_text(err)]
			)
			return
	else:
		# if it exists, delete all files/folders in it
		var files := Path.get_filepaths(mission.paths.test_root)
		for fpath:String in files:
			DirAccess.remove_absolute(fpath)

	# copy the pk4 over to the test TDM version folder
	console.print("Copying pk4 to test location at '%s'" % dest_pak_file.get_base_dir())
	var copy_err := DirAccess.copy_absolute(src_pak_file, dest_pak_file)
	if copy_err != OK:
		popups.show_message(
			"Error Copying pak file",
			"Couldn't copy '%s' to the test location '%s'. ERROR: %s.\n" % [mission.zipname, dest_pak_file, Path.get_error_text(copy_err)]
		)
		return

	_run_game("Running TDM test version", mission, data.config.tdm_copy_path, "tdm_copy_process_started", "tdm_copy_process_ended")


func _run_game(task_name:String, mission:Mission, exec_filepath:String, start_signal:StringName, end_signal:StringName) -> void:
	# launch TDM test version

	var game_dir :String = exec_filepath.get_base_dir()
	var currfm_path := Path.join(game_dir, data.CURRENT_FM_FILE)

	if not Path.file_exists(exec_filepath):
		popups.show_message(
			"Error launching TDM",
			"The path to TDM executable is invalid: '%s'. \n" % exec_filepath
		)
		return

	# switch the 'currentfm.txt' file to point to this fm before launching TDM
	Path.write_file(currfm_path, fms.curr_mission.id)

	#logs.task("Starting TDM process")
	console.task(task_name)
	var pid := OS.create_process(exec_filepath, [])
	if pid >= 0:
		emit_signal(start_signal)

		# Since Godot can't change the CWD, TDM will create logs inside the
		# Packer's directory, and they need to be moved to TDM dir after it
		# shuts down.
		pids[pid] = func() -> void:
			logs.task("Copying TDM logs to TDM directory")
			Path.move_file(
				Path.join(data.CWD, tdm_log_file1),
				Path.join(game_dir, tdm_log_file1)
			)
			Path.move_file(
				Path.join(data.CWD, tdm_log_file2),
				Path.join(game_dir, tdm_log_file2)
			)

			console.info("TDM process ended")
			emit_signal(end_signal)
