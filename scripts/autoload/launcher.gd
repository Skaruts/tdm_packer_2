extends Node
# autoloaded script


signal _execution_finished(res:Path.ExecutionResults)

signal tdm_copy_process_started
signal tdm_copy_process_ended

# to keep track of a running TDM copy process
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
	OS.shell_open(fm_manager.curr_mission.path_root)

func open_mission_test_folder() -> void:
	OS.shell_open(fm_manager.curr_mission.path_root_test)




func run_darkradiant() -> void:
	# TODO: support other OSs
	var exec_filepath:String = data.config.dr_path
	var arg := "fs_game=fms/%s" % [fm_manager.curr_mission.id]

	if not Path.file_exists(exec_filepath):
		popups.warning_report.open({
			title = "Error launching DarkRadiant",
			text = "The path to the executable is invalid.",
		})
		return

	console.task("Running DarkRadiant for '%s'" % fm_manager.curr_mission.id)
	var pid := OS.create_process(exec_filepath, [arg])



const tdm_log_file1 := "DarkMod.log"
const tdm_log_file2 := "DarkMod.temp.log"

func run_tdm_copy() -> void:
	var mission = fm_manager.curr_mission

	# check if source pk4 file exists
	var src_pak_file :String = Path.join(mission.path_root, mission.zipname)
	if not Path.file_exists(src_pak_file):
		popups.warning_report.open({
			title = "Error",
			text = "'%s' doesn't exist. You must 'Pack' the mission first." % [mission.zipname]
		})
		return

	# if destination path doesn't exist, create it
	var dest_pak_file :String = Path.join(mission.path_root_test, mission.zipname)
	if not Path.dir_exists(mission.path_root_test):
		var err := Path.make_dir(mission.path_root_test)
		if err != OK:
			popups.warning_report.open({
				title = "Error",
				text = "Can't create destination path\n    '%s'.\nERROR: %s.\n" % [mission.path_root_test, Path.get_error_text(err)]
			})
			return
	else:
		# if it exists, delete all files/folders in it
		var files := Path.get_filepaths(mission.path_root_test)
		for fpath:String in files:
			DirAccess.remove_absolute(fpath)

	# copy the pk4 over to the test TDM version folder
	var copy_err := DirAccess.copy_absolute(src_pak_file, dest_pak_file)
	if copy_err != OK:
		popups.warning_report.open({
			title = "Error Copying pak file",
			text = "Couldn't copy '%s' to the test location '%s'. ERROR: %s.\n" % [mission.zipname, dest_pak_file, Path.get_error_text(copy_err)]
		})
		return

	# launch TDM test version
	var exec_filepath:String = data.config.tdm_copy_path
	var test_game_dir :String = exec_filepath.get_base_dir()
	var currfm_path := Path.join(test_game_dir, data.CURRENT_FM_FILE)

	if not Path.file_exists(exec_filepath):
		popups.warning_report.open({
			title = "Error launching TDM",
			text = "The path to TDM executable is invalid: '%s'. \n" % exec_filepath,
		})
		return

	# switch the 'currentfm.txt' file to point to this fm before launching TDM
	Path.write_file(currfm_path, fm_manager.curr_mission.id)

	#logs.task("Starting TDM process")
	console.task("Running TDM")
	var pid := OS.create_process(exec_filepath, [])
	if pid >= 0:
		tdm_copy_process_started.emit()

		# This is required, since Godot can't change the CWD, so TDM will create
		# logs inside the Packer's directory, and they need to be moved to TDM
		# directory after it shuts down.
		pids[pid] = func() -> void:
			logs.task("Copying TDM logs to TDM directory")
			Path.move_file(
				Path.join(data.CWD, tdm_log_file1),
				Path.join(data.config.tdm_copy_path.get_base_dir(), tdm_log_file1)
			)
			Path.move_file(
				Path.join(data.CWD, tdm_log_file2),
				Path.join(data.config.tdm_copy_path.get_base_dir(), tdm_log_file2)
			)
			#logs.info("TDM process ended")
			console.info("TDM process ended")
			tdm_copy_process_ended.emit()


