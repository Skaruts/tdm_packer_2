extends Node
# autoloaded script

enum {
	MENU_SETTINGS,
	MENU_OPEN_PACKER_FOLDER,
	MENU_ABOUT,
	MENU_EXIT,
}

var menu_bar      : Control
var missions_list : GuiMissionsList
var workspace_mgr : GuiWorkspaceManager




func initialize() -> void:
	var main: Control = get_tree().root.get_node("main")
	menu_bar = main.get_node("%menu_bar")
	missions_list = main.get_node("%missions_list")
	workspace_mgr = main.get_node("%workspace_mgr")

	missions_list.initialize()
	workspace_mgr.initialize()
	init_menu_bar()

	var btn_pack_tab: Button = menu_bar.get_node("%btn_pack_tab")
	var btn_files_tab: Button = menu_bar.get_node("%btn_files_tab")

	btn_pack_tab.pressed.connect(workspace_mgr.set_main_workspace_tab.bind(0))
	btn_files_tab.pressed.connect(workspace_mgr.set_main_workspace_tab.bind(1))


func init_menu_bar() -> void:
	var main_menu: PopupMenu = menu_bar.get_node("%btn_menu").get_popup()

	main_menu.add_item("TDM Packer folder", MENU_OPEN_PACKER_FOLDER)
	main_menu.add_item("Settings", MENU_SETTINGS)
	main_menu.add_separator()
	main_menu.add_item("About", MENU_ABOUT)
	main_menu.add_separator()
	main_menu.add_item("Exit", MENU_EXIT)

	main_menu.id_pressed.connect(_on_menu_id_pressed)


func _on_menu_id_pressed(id:int) -> void:
	match id:
		MENU_OPEN_PACKER_FOLDER:       launcher.open_fm_packer_folder()
		MENU_SETTINGS:                 open_dialog("settings")
		MENU_ABOUT:                    open_dialog("about")
		MENU_EXIT:                     get_tree().quit()


func open_dialog(dialog_name: String) -> void:
	match dialog_name:
		"settings":
			popups.show_popup(popups.settings_dialog)
		"about":
			popups.show_message(
				"About",
				"TDM PAcker 2\nVersion %s\n\nBy Skaruts" % data.VERSION,
			)
