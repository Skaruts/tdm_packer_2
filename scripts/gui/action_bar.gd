extends TabContainer


@onready var btn_run_dr: Button = %btn_run_dr
@onready var btn_pack_mission: Button = %btn_pack_mission
@onready var btn_test_pack: Button = %btn_test_pack


func _ready() -> void:
	fm_manager.mission_switched.connect(_on_mission_switched)
	data.settings_changed.connect(_on_settings_changed)
	launcher.tdm_copy_process_started.connect(func() -> void: btn_test_pack.disabled = true)
	launcher.tdm_copy_process_ended.connect(func() -> void: btn_test_pack.disabled = false)
	update_buttons()


func update_buttons() -> void:
	if fm_manager.missions.size()  \
	and fm_manager.curr_mission.file_tree != null:
		btn_run_dr.disabled           = data.config.dr_path == ""
		btn_pack_mission.disabled     = data.config.tdm_path == ""
		btn_test_pack.disabled        = data.config.tdm_copy_path == ""
	else:
		btn_run_dr.disabled           = true
		btn_pack_mission.disabled     = true
		btn_test_pack.disabled        = true


func _on_mission_switched() -> void:
	update_buttons()


func _on_btn_run_dr_pressed() -> void:
	launcher.run_darkradiant()

func _on_btn_pack_mission_pressed() -> void:
	fm_manager.pack_mission()

func _on_btn_test_pack_pressed() -> void:
	launcher.run_tdm_copy()


func _on_settings_changed() -> void:
	update_buttons()
