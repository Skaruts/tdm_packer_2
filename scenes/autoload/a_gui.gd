extends Node
# autoloaded script

enum MenuOption {
	Menu_Settings,
	Menu_Open_Packer_Folder,
	Menu_About,
	Menu_Exit,
}

@onready var main          : Control = get_tree().root.get_node("main")
@onready var menu_bar      : Control = main.get_node("%menu_bar")
@onready var missions_list : Control = main.get_node("%missions_list")
@onready var workspace_mgr : Control = main.get_node("%workspace_mgr")



func initialize() -> void:
	init_missions_list()
	workspace_mgr.initialize()
	init_menu_bar()

	var btn_pack_tab: Button = menu_bar.get_node("%btn_pack_tab")
	var btn_files_tab: Button = menu_bar.get_node("%btn_files_tab")

	btn_pack_tab.pressed.connect(workspace_mgr.set_main_workspace_tab.bind(0))
	btn_files_tab.pressed.connect(workspace_mgr.set_main_workspace_tab.bind(1))



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Menu Bar

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func init_menu_bar() -> void:
	var main_menu: PopupMenu = menu_bar.get_node("%btn_menu").get_popup()

	main_menu.add_item("TDM Packer folder", MenuOption.Menu_Open_Packer_Folder)
	main_menu.add_item("Settings", MenuOption.Menu_Settings)
	main_menu.add_separator()
	main_menu.add_item("About", MenuOption.Menu_About)
	main_menu.add_separator()
	main_menu.add_item("Exit", MenuOption.Menu_Exit)

	main_menu.id_pressed.connect(_on_menu_id_pressed)


func _on_menu_id_pressed(id:int) -> void:
	match id:
		MenuOption.Menu_Open_Packer_Folder: launcher.open_fm_packer_folder()
		MenuOption.Menu_Settings:           open_dialog("settings")
		MenuOption.Menu_About:              open_dialog("about")
		MenuOption.Menu_Exit:               get_tree().quit()


func open_dialog(dialog_name: String) -> void:
	match dialog_name:
		"settings":
			popups.show_popup(popups.settings_dialog)
		"about":
			popups.show_message(
				"About",
				"TDM PAcker 2\nVersion %s\n\nBy Skaruts" % data.VERSION,
			)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Missions List

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
enum ListMenuPopup {
	OPEN_FOLDER,
	OPEN_TEST_FOLDER,
	CLOSE,
}

@onready var btn_open_mission  : Button = main.get_node("%btn_open_mission")
@onready var btn_close_mission : Button = main.get_node("%btn_close_mission")

@onready var btn_play_mission  : Button = main.get_node("%btn_play_mission")
@onready var btn_run_dr        : Button = main.get_node("%btn_run_dr")
@onready var btn_pack_mission  : Button = main.get_node("%btn_pack_mission")
@onready var btn_test_pack     : Button = main.get_node("%btn_test_pack")

@onready var il_missions       : ItemList = main.get_node("%il_missions")
@onready var pu_missions_menu  : PopupMenu = main.get_node("%missions_popup_menu")


func init_missions_list() -> void:
	launcher.tdm_process_started.connect(func() -> void: btn_play_mission.disabled = true)
	launcher.tdm_process_ended.connect(func() -> void: btn_play_mission.disabled = false)
	launcher.tdm_copy_process_started.connect(func() -> void: btn_test_pack.disabled = true)
	launcher.tdm_copy_process_ended.connect(func() -> void: btn_test_pack.disabled = false)

	var menu: PopupMenu = pu_missions_menu
	menu.add_item("Open Folder",      ListMenuPopup.OPEN_FOLDER)
	menu.add_item("Open Test Folder", ListMenuPopup.OPEN_TEST_FOLDER)
	menu.add_separator()
	menu.add_item("Close",            ListMenuPopup.CLOSE)

	pu_missions_menu.id_pressed.connect(_on_pu_missions_menu_id_pressed)
	il_missions.item_clicked.connect(_on_il_missions_item_clicked)
	btn_open_mission.pressed.connect(_on_btn_open_mission_pressed)
	btn_close_mission.pressed.connect(_on_btn_close_mission_pressed)


	update_missions_list()


func update_missions_list() -> void:
	il_missions.clear()
	for m:Mission in fms.missions:
		var id := m.id
		var _idx := il_missions.add_item(id)

		if m.missing:
			il_missions.set_item_custom_fg_color(_idx, data.ERROR_COLOR)
			il_missions.set_item_icon(_idx, data.ICON_WARNING)

		#if m.file_tree == null:
			#il_missions.set_item_custom_fg_color(idx, data.ERROR_COLOR)
			#il_missions.set_item_metadata(idx, "invalid mission")

	if fms.missions.size() > 0:
		logs.print("curr_idx: ", fms.get_current_mission_index(), fms.curr_mission.id)
		il_missions.select(fms.get_current_mission_index())

	update_missions_list_buttons()


func update_missions_list_buttons() -> void:
	var no_missions: bool = fms.missions.size() == 0
	btn_open_mission.disabled  = not data.is_tdm_path_set()
	btn_close_mission.disabled = no_missions

	if not no_missions and not fms.curr_mission.missing and fms.curr_mission.file_tree != null:
		btn_play_mission.disabled     = not data.is_tdm_path_set()
		btn_run_dr.disabled           = not data.is_dr_path_set()
		btn_pack_mission.disabled     = not data.is_tdm_path_set()
		btn_test_pack.disabled        = not data.is_tdm_copy_path_set() or not fms.is_mission_packed(fms.curr_mission)
	else:
		btn_play_mission.disabled     = true
		btn_run_dr.disabled           = true
		btn_pack_mission.disabled     = true
		btn_test_pack.disabled        = true



func _on_il_missions_item_clicked(index: int, _at_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index > 2:
		return

	fms.select_mission(index)
	update_missions_list_buttons()

	if mouse_button_index == 2:
		pu_missions_menu.position = missions_list.get_global_mouse_position()
		pu_missions_menu.popup()


func _on_pu_missions_menu_id_pressed(id:int) -> void:
	match id:
		ListMenuPopup.OPEN_FOLDER:      launcher.open_mission_folder()
		ListMenuPopup.OPEN_TEST_FOLDER: launcher.open_mission_test_folder()
		ListMenuPopup.CLOSE:            _on_btn_close_mission_pressed()


func _on_btn_open_mission_pressed() -> void:
	popups.show_popup( popups.open_mission )


func _on_btn_close_mission_pressed() -> void:
	popups.show_confirmation({
		text        = "Close '%s'?" % fms.curr_mission.id,
		ok_text     = "Yes",
		cancel_text = "No",
	})

	if not await popups.confirmation_dialog.answer:
		return

	# TODO: maybe ask confirmation?
	if fms.is_save_timer_counting():
		fms.stop_timer_and_save()
	fms.remove_mission(fms.curr_mission)


func _on_btn_play_mission_pressed() -> void:
	fms.play_mission()

func _on_btn_run_dr_pressed() -> void:
	fms.edit_mission()

func _on_btn_pack_mission_pressed() -> void:
	#fms.pack_mission()
	popups.show_popup(popups.pack_mission)

func _on_btn_test_pack_pressed() -> void:
	fms.test_pack()
