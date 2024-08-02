extends Control


enum {
	MENU_SETTINGS,
	MENU_OPEN_PACKER_FOLDER,
	MENU_OPEN_MISSION_FOLDER,
	MENU_OPEN_TEST_MISSION_FOLDER,
	MENU_EXIT,
}

@onready var btn_menu: MenuButton = %btn_menu
@onready var settings_btn: Button = %settings_btn # for quick tests


var main_menu:PopupMenu
var open_menu:PopupMenu



func _ready() -> void:
	main_menu = btn_menu.get_popup()

	open_menu = PopupMenu.new()
	open_menu.name = "open_menu"
	main_menu.add_child(open_menu)

	main_menu.add_submenu_item("Open Folder", "open_menu", 69)

	open_menu.add_item("TDM Packer folder", MENU_OPEN_PACKER_FOLDER)
	open_menu.add_separator()
	open_menu.add_item("Mission folder", MENU_OPEN_MISSION_FOLDER)
	open_menu.add_item("Mission test folder", MENU_OPEN_TEST_MISSION_FOLDER)

	main_menu.add_separator()
	main_menu.add_item("Settings", MENU_SETTINGS)
	main_menu.add_separator()
	main_menu.add_item("Exit", MENU_EXIT)
	main_menu.id_pressed.connect(_on_menu_id_pressed)
	open_menu.id_pressed.connect(_on_menu_id_pressed)

	settings_btn.pressed.connect(func():
		data.open_settings()
	)

	fm_manager.mission_switched.connect(_on_mission_switched)

	_update_buttons()


func _on_mission_switched() -> void:
	_update_buttons()


func _on_menu_id_pressed(id:int) -> void:
	match id:
		MENU_OPEN_PACKER_FOLDER:       launcher.open_fm_packer_folder()
		MENU_OPEN_MISSION_FOLDER:      launcher.open_mission_folder()
		MENU_OPEN_TEST_MISSION_FOLDER: launcher.open_mission_test_folder()
		MENU_SETTINGS:                 data.open_settings()
		MENU_EXIT:                     get_tree().quit()



func _update_buttons() -> void:
	if fm_manager.curr_mission and fm_manager.curr_mission.file_tree != null:
		open_menu.set_item_disabled(open_menu.get_item_index(MENU_OPEN_MISSION_FOLDER), false)
		open_menu.set_item_disabled(open_menu.get_item_index(MENU_OPEN_TEST_MISSION_FOLDER), false)
	else:
		open_menu.set_item_disabled(open_menu.get_item_index(MENU_OPEN_MISSION_FOLDER), true)
		open_menu.set_item_disabled(open_menu.get_item_index(MENU_OPEN_TEST_MISSION_FOLDER), true)
