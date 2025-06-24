class_name GuiMenuBar
extends HBoxContainer

enum {
	MENU_SETTINGS,
	MENU_OPEN_PACKER_FOLDER,
	MENU_OPEN_MISSION_FOLDER,
	MENU_OPEN_MISSION_TEST_FOLDER,
	MENU_DEBUG_GET_WINDOW_SIZE,
	MENU_ABOUT,
	MENU_EXIT,
}

var main_menu:PopupMenu
var open_menu:PopupMenu



func _enter_tree() -> void:
	gui.menu_bar = self


func _ready() -> void:
	main_menu = %btn_menu.get_popup()

	# open folders menu
	#open_menu = PopupMenu.new()
	#open_menu.name = "open_menu"  # for the node tree, for debugging

	#main_menu.add_child(open_menu)
	#main_menu.add_submenu_item("Open Folder", "open_menu", 69)

	#open_menu.add_item("Mission folder", MENU_OPEN_MISSION_FOLDER)
	#open_menu.add_item("Mission test folder", MENU_OPEN_MISSION_TEST_FOLDER)
	#open_menu.add_separator()
	main_menu.add_item("TDM Packer folder", MENU_OPEN_PACKER_FOLDER)

	#open_menu.id_pressed.connect(_on_menu_id_pressed)

	# debug menu
	var debug_menu := PopupMenu.new()
	debug_menu.name = "debug_menu"  # for the node tree, for debugging
	main_menu.add_child(debug_menu)
	#main_menu.add_submenu_item("Debug", "debug_menu", 70)
	#debug_menu.add_item("Print Window Size", MENU_DEBUG_GET_WINDOW_SIZE)

	debug_menu.id_pressed.connect(_on_menu_id_pressed)

	# main menu stuff
	#main_menu.add_separator()
	main_menu.add_item("Settings", MENU_SETTINGS)
	main_menu.add_separator()
	main_menu.add_item("About", MENU_ABOUT)
	main_menu.add_separator()
	main_menu.add_item("Exit", MENU_EXIT)

	main_menu.id_pressed.connect(_on_menu_id_pressed)


func initialize() -> void:
	pass


func _on_menu_id_pressed(id:int) -> void:
	match id:
		MENU_OPEN_PACKER_FOLDER:       launcher.open_fm_packer_folder()
		MENU_OPEN_MISSION_FOLDER:      launcher.open_mission_folder()
		MENU_OPEN_MISSION_TEST_FOLDER: launcher.open_mission_test_folder()
		MENU_SETTINGS:                 open_dialog("settings")
		MENU_ABOUT:                    open_dialog("about")
		MENU_EXIT:                     get_tree().quit()
		MENU_DEBUG_GET_WINDOW_SIZE:
			var w := get_window()
			var ss := DisplayServer.screen_get_size()
			logs.print(w.position.x == (ss.x/2.0 - w.size.x/2.0))
			while w.position.x != (ss.x/2.0 - w.size.x/2.0):
				await get_tree().process_frame
				logs.error("%s | %s" % [ss, w.size])
				w.move_to_center()


func open_dialog(dialog_name: String) -> void:
	match dialog_name:
		"settings":
			popups.show_popup(popups.settings_dialog)
		"about":
			popups.show_message(
				"About",
				"TDM PAcker 2\nVersion %s\n\nBy Skaruts" % data.VERSION,
			)


func _on_main_tab_button_pressed(idx: int) -> void:
	gui.workspace_mgr.set_main_workspace_tab(idx)
