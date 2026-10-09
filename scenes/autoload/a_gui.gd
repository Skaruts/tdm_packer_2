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
@onready var workspace_mgr : TabContainer = main.get_node("%workspace_mgr")

var _missions_list_root: TreeItem


func initialize() -> void:
	init_missions_list()
	init_workspaces()
	init_menu_bar()

	var btn_pack_tab: Button = menu_bar.get_node("%btn_pack_tab")
	var btn_files_tab: Button = menu_bar.get_node("%btn_files_tab")

	btn_pack_tab.pressed.connect(gui.workspace_set_main_tab.bind(0))
	btn_files_tab.pressed.connect(gui.workspace_set_main_tab.bind(1))




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

# @onready var il_missions       : ItemList  = main.get_node("%il_missions")
@onready var tr_missions       : Tree      = main.get_node("%tr_missions")
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
	# il_missions.item_clicked.connect(_on_il_missions_item_clicked)
	tr_missions.item_mouse_selected.connect(_on_tr_missions_item_mouse_selected)
	btn_open_mission.pressed.connect(_on_btn_open_mission_pressed)
	btn_close_mission.pressed.connect(_on_btn_close_mission_pressed)

	btn_play_mission.pressed.connect(_on_btn_play_mission_pressed)
	btn_run_dr.pressed.connect(_on_btn_run_dr_pressed)
	btn_pack_mission.pressed.connect(_on_btn_pack_mission_pressed)
	btn_test_pack.pressed.connect(_on_btn_test_pack_pressed)

	tr_missions.columns = 1
	tr_missions.hide_root = true
	#tr_missions.button_clicked.connect(
		#func(item: TreeItem, _column: int, id: int, _mouse_button_index: int) -> void:
			#match id:
				#ListButton.LOCK:
					#var mission := fms.get_mission_at_index(item.get_index())
					#mission_set_locked(mission, not mission.locked)
	#)
			#func _on_tr_missions_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	update_missions_list()


enum ListButton {
	LOCK,
}


#func mission_set_locked(mission: Mission, enabled: bool) -> void:
	#mission.locked = enabled
	#update_missions_list()
	#missions_list_update_buttons()
	#on_mission_reloaded(fms.get_mission_index(mission), true)


func update_missions_list() -> void:
	tr_missions.clear()
	_missions_list_root = tr_missions.create_item()

	for m: Mission in fms.missions:
		var item := _missions_list_root.create_child()
		item.set_text(0, m.id)
		item.set_custom_color(0, Color.DIM_GRAY if fms.is_mission_readonly(m.id) else Color.WHITE)

		if fms.is_mission_missing(m.id):
			item.set_custom_color(0, data.ERROR_COLOR)
			# # il_missions.set_item_icon(_idx, data.ICON_WARNING)
			# item.add_button(0, data.ICON_LOCK, 0, true, "")
		else:
			# var btn_idx := item.get_button_count(0)
			# item.add_button(0, data.ICON_LOCK, ListButton.LOCK, false,
			# 	"Click to lock/unlock mission."
			# )
			# item.set_button_color(0, btn_idx, Color.WHITE if fms.is_mission_readonly(m) else Color.DIM_GRAY)
			# #item.set_button_color(0, btn_idx, Color.DIM_GRAY)
			pass

	if fms.missions.size() > 0:
		var curr_idx := fms.get_current_mission_index()
		var selected_item := _missions_list_root.get_child(curr_idx)
		tr_missions.set_selected( selected_item, 0 )

	missions_list_update_buttons()


func missions_list_update_buttons() -> void:
	var no_missions: bool = fms.missions.size() == 0
	btn_open_mission.disabled  = not data.is_tdm_path_set()
	btn_close_mission.disabled = no_missions

	if not no_missions and not fms.is_mission_missing(fms.curr_mission.id) \
	and fms.curr_mission.file_tree != null:
		btn_play_mission.disabled     = not data.is_tdm_path_set()
		btn_run_dr.disabled           = not data.is_dr_path_set()

		btn_pack_mission.disabled     = not data.is_tdm_path_set() \
										 or fms.is_mission_readonly(fms.curr_mission.id)
		btn_test_pack.disabled        = not data.is_tdm_copy_path_set() \
										 or not fms.is_mission_packed(fms.curr_mission) \
										 or fms.is_mission_readonly(fms.curr_mission.id)
	else:
		btn_play_mission.disabled     = true
		btn_run_dr.disabled           = true
		btn_pack_mission.disabled     = true
		btn_test_pack.disabled        = true


func _on_tr_missions_item_mouse_selected(_mouse_position: Vector2, mouse_button_index: int) -> void:
	if mouse_button_index > 2:
		return

	var index := tr_missions.get_selected().get_index()
	fms.select_mission(index)
	missions_list_update_buttons()

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




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Mission Workspace Management

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
const MissionWorkspaceScene: PackedScene = preload("res://scenes/gui/gui_mission_workspace.tscn")

var curr_pack_tab := 0
var curr_files_tab := 0


func _add_workspace_node(mission:Mission) -> MissionWorkspace:
	var ws: MissionWorkspace = MissionWorkspaceScene.instantiate()
	workspace_mgr.add_child(ws)

	ws.tab_package.current_tab = curr_pack_tab
	ws.tab_files.current_tab = curr_files_tab
	ws.tab_package.tab_changed.connect(_on_tab_package_tab_changed)
	ws.tab_files.tab_changed.connect(_on_tab_files_tab_changed)
	ws.set_mission(mission)
	return ws


func init_workspaces() -> void:
	for mission in fms.missions:
		_add_workspace_node(mission)


func update_workspaces() -> void:
	for ws: MissionWorkspace in workspace_mgr.get_children():
		ws.update_nodes()


func get_current_workspace() -> MissionWorkspace:
	return workspace_mgr.get_children()[fms.get_current_mission_index()]


func add_workspace(mission: Mission) -> void:
	var ws := _add_workspace_node(mission)
	#ws.tab_package.select_previous_available() # TODO: this doesn't seem needed??
	_sort_nodes_by_name()
	select_workspace(ws.get_index())


func remove_workspace(index: int) -> void:
	var ws := workspace_mgr.get_child(index)
	ws.queue_free()
	workspace_mgr.remove_child(ws)

	if fms.missions.size():
		var curr_idx := fms.get_current_mission_index()
		select_workspace( clamp(curr_idx, 0, fms.missions.size()-1) )
	#else:
		#select_workspace(0)


func select_workspace(index: int) -> void:
	workspace_mgr.current_tab = index


func workspace_set_main_tab(idx: int) -> void:
	for ws: MissionWorkspace in workspace_mgr.get_children():
		ws.switch_main_tab(idx)


func on_mission_reloaded(idx: int, force_update := false) -> void:
	var ws: MissionWorkspace = workspace_mgr.get_children()[idx]
	ws.on_mission_reloaded(force_update)


func workspace_update_pack_name(idx:int) -> void:
	var ws: MissionWorkspace = workspace_mgr.get_children()[idx]
	ws.update_pack_name()


#func package_reload_file(filename:String) -> void:
	#var ws:MissionWorkspace = workspace_mgr.get_children()[fms.get_current_mission_index()]
	#ws.tab_package.reload_file(filename)

func workspace_set_show_roots() -> void:
	for ws: MissionWorkspace in workspace_mgr.get_children():
		ws.tab_package.set_show_roots(data.config.show_tree_roots)



func _sort_nodes_by_name() -> void:
	var children := workspace_mgr.get_children()
	children.sort_custom(func(a: Node, b: Node) -> bool:
		return a._mission.id.naturalnocasecmp_to(b._mission.id) < 0
	)

	# TODO: try this loop instead of the other two
	#for i in children.size():
		#move_child(children[i], i)

	for node in workspace_mgr.get_children():
		workspace_mgr.remove_child(node)

	for node in children:
		workspace_mgr.add_child(node)


func _on_tab_package_tab_changed(index: int) -> void:
	curr_pack_tab = index
	for ws: MissionWorkspace in workspace_mgr.get_children():
		ws.tab_package.current_tab = index


func _on_tab_files_tab_changed(index: int) -> void:
	curr_files_tab = index
	for ws: MissionWorkspace in workspace_mgr.get_children():
		ws.tab_files.current_tab = index
