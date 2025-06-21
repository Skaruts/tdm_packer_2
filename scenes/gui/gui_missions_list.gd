class_name GuiMissionsList
extends TabContainer


enum ListMenu {
	OPEN_FOLDER,
	OPEN_TEST_FOLDER,
	CLOSE,
}


@onready var btn_open_mission  : Button = %btn_open_mission
@onready var btn_close_mission : Button = %btn_close_mission

@onready var btn_play_mission  : Button = %btn_play_mission
@onready var btn_run_dr        : Button = %btn_run_dr
@onready var btn_pack_mission  : Button = %btn_pack_mission
@onready var btn_test_pack     : Button = %btn_test_pack

@onready var il_missions       : ItemList  = %il_missions
@onready var pu_missions_menu  : PopupMenu = %missions_popup_menu



func _enter_tree() -> void:
	gui.missions_list = self


func _ready() -> void:
	launcher.tdm_process_started.connect(func() -> void: btn_play_mission.disabled = true)
	launcher.tdm_process_ended.connect(func() -> void: btn_play_mission.disabled = false)
	launcher.tdm_copy_process_started.connect(func() -> void: btn_test_pack.disabled = true)
	launcher.tdm_copy_process_ended.connect(func() -> void: btn_test_pack.disabled = false)

	var menu:PopupMenu = pu_missions_menu
	menu.add_item("Open Folder",      ListMenu.OPEN_FOLDER)
	menu.add_item("Open Test Folder", ListMenu.OPEN_TEST_FOLDER)
	menu.add_separator()
	menu.add_item("Close",            ListMenu.CLOSE)

	pu_missions_menu.id_pressed.connect(_on_pu_missions_menu_id_pressed)
	il_missions.item_clicked.connect(_on_il_missions_item_clicked)
	btn_open_mission.pressed.connect(_on_btn_open_mission_pressed)
	btn_close_mission.pressed.connect(_on_btn_close_mission_pressed)


func initialize() -> void:
	update_list()


func update_list() -> void:
	il_missions.clear()
	for m:Mission in fms.missions:
		var id := m.id
		var idx := il_missions.add_item(id)

		#if m.file_tree == null:
			#il_missions.set_item_custom_fg_color(idx, data.ERROR_COLOR)
			#il_missions.set_item_metadata(idx, "invalid mission")

	if fms.missions.size() > 0:
		#logs.print("curr_idx: ", fms.get_current_mission_index())
		il_missions.select(fms.get_current_mission_index())

	update_buttons()


func update_buttons() -> void:
	var no_missions: bool = fms.missions.size() == 0
	btn_open_mission.disabled  = not data.is_tdm_path_set()
	btn_close_mission.disabled = no_missions

	if not no_missions and fms.curr_mission.file_tree != null:
		btn_play_mission.disabled     = not data.is_tdm_path_set()
		btn_run_dr.disabled           = not data.is_dr_path_set()
		btn_pack_mission.disabled     = not data.is_tdm_path_set()
		btn_test_pack.disabled        = not data.is_tdm_copy_path_set() or not fms.is_mission_packed(fms.curr_mission)
	else:
		btn_play_mission.disabled     = true
		btn_run_dr.disabled           = true
		btn_pack_mission.disabled     = true
		btn_test_pack.disabled        = true



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#        signals

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_il_missions_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index > 2:
		return

	fms.select_mission(index)

	if mouse_button_index == 2:
		pu_missions_menu.position = get_global_mouse_position()
		pu_missions_menu.popup()


func _on_pu_missions_menu_id_pressed(id:int) -> void:
	match id:
		ListMenu.OPEN_FOLDER:      launcher.open_mission_folder()
		ListMenu.OPEN_TEST_FOLDER: launcher.open_mission_test_folder()
		ListMenu.CLOSE:            _on_btn_close_mission_pressed()


func _on_btn_open_mission_pressed() -> void:
	popups.open_folder({
			title = "Open Mission",
			root_subfolder = fms.fms_folder,
		},
		func(path:String) -> void:
			if Path.file_exists(Path.join(path, data.MODFILE_FILENAME)):
				fms.add_mission(path.get_file())
			else:
				popups.show_confirmation({
						text        = "File 'darkmod.txt' not found in '%s'.\n\nDo you want to create it?\n" % [path.get_file()],
						ok_text     = "Create",
						cancel_text = "Abort",
					},
					func() -> void:
						fms.add_mission(path.get_file())
				)
	)


func _on_btn_close_mission_pressed() -> void:
	# TODO: maybe ask confirmation?
	if fms.is_save_timer_counting():
		fms.stop_timer_and_save()
	fms.remove_current_mission()


func _on_btn_play_mission_pressed() -> void:
	fms.play_mission()

func _on_btn_run_dr_pressed() -> void:
	fms.edit_mission()

func _on_btn_pack_mission_pressed() -> void:
	fms.pack_mission()

func _on_btn_test_pack_pressed() -> void:
	fms.test_pack()
