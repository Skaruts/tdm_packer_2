class_name GuiWorkspaceManager
extends TabContainer


@export var MissionWorkspaceScene:PackedScene  # preload(nodepaths.WORKSPACE_PATH)


var curr_pack_tab := 0
var curr_files_tab := 0



func _enter_tree() -> void:
	gui.workspace_mgr = self


func initialize() -> void:
	for mission in fms.missions:
		_add_workspace_node(mission)


func _add_workspace_node(mission:Mission) -> MissionWorkspace:
	var ws: MissionWorkspace = MissionWorkspaceScene.instantiate()
	add_child(ws)
	ws.tab_package.current_tab = curr_pack_tab
	ws.tab_files.current_tab = curr_files_tab
	ws.tab_package.tab_changed.connect(_on_tab_package_tab_changed)
	ws.tab_files.tab_changed.connect(_on_tab_files_tab_changed)
	ws.set_mission(mission)
	return ws


func select_workspace(index: int) -> void:
	current_tab = index


func set_main_workspace_tab(idx:int) -> void:
	for ws:MissionWorkspace in get_children():
		ws.current_tab = idx


func on_mission_reloaded(idx:int, force_update:=false) -> void:
	var ws:MissionWorkspace = get_children()[idx]
	ws.on_mission_reloaded(force_update)


func update_pack_name(idx:int) -> void:
	var ws:MissionWorkspace = get_children()[idx]
	ws.update_pack_name()


#func package_reload_file(filename:String) -> void:
	#var ws:MissionWorkspace = get_children()[fms.get_current_mission_index()]
	#ws.tab_package.reload_file(filename)

func get_current_workspace() -> MissionWorkspace:
	return get_children()[fms.get_current_mission_index()]

func set_show_roots() -> void:
	for ws:MissionWorkspace in get_children():
		ws.tab_package.set_show_roots(data.config.show_tree_roots)


func add_workspace(mission: Mission) -> void:
	var ws := _add_workspace_node(mission)
	#ws.tab_package.select_previous_available() # TODO: this doesn't seem needed??
	_sort_nodes_by_name()
	select_workspace(ws.get_index())


func remove_workspace(index: int) -> void:
	var ws := get_child(index)
	ws.queue_free()
	remove_child(ws)

	if fms.missions.size():
		logs.print("curr_idx mgr: ", fms.get_current_mission_index())
		select_workspace(fms.get_current_mission_index())
	else:
		select_workspace(0)


func _sort_nodes_by_name() -> void:
	var children := get_children()
	children.sort_custom(func(a: Node, b: Node) -> bool:
		return a._mission.id.naturalnocasecmp_to(b._mission.id) < 0
	)

	# TODO: try this loop instead of the other two
	#for i in children.size():
		#move_child(children[i], i)

	for node in get_children():
		remove_child(node)

	for node in children:
		add_child(node)


func _on_tab_package_tab_changed(index: int) -> void:
	curr_pack_tab = index
	for ws:MissionWorkspace in get_children():
		ws.tab_package.current_tab = index


func _on_tab_files_tab_changed(index: int) -> void:
	curr_files_tab = index
	for ws:MissionWorkspace in get_children():
		ws.tab_files.current_tab = index
