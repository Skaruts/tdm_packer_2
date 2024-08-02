extends TabContainer


func _ready() -> void:
	fm_manager.missions_loaded.connect(_on_missions_loaded)
	fm_manager.mission_added.connect(_on_mission_added)
	fm_manager.mission_deleted.connect(_on_mission_deleted)
	fm_manager.mission_switched.connect(_on_mission_switched)

	# remove editor test workspaces
	for c:Node in get_children():
		c.free()

	if fm_manager.missions.size():
		load_mission_workspaces()


func load_mission_workspaces() -> void:
	if not fm_manager.missions.size():
		add_child(preloads.DummyWorkspace.instantiate())
	else:
		for i in fm_manager.missions.size():
			_add_workspace_node(fm_manager.missions[i])






#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Signals
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _on_missions_loaded() -> void:
	load_mission_workspaces()


func _on_mission_switched() -> void:
	current_tab = fm_manager.get_mission_index()
	#logs.print("switched - current_tab:", current_tab, fm_manager.curr_mission.id)


func _on_workspace_tab_changed(index: int) -> void:
	for ws:TabContainer in get_children():
		if ws.get("packing"):
			ws.packing.current_tab = index


func _sort_nodes_by_name() -> void:
	var children := get_children()
	children.sort_custom(func(a: Node, b: Node) -> bool:
		return a._mission.id.naturalnocasecmp_to(b._mission.id) < 0
	)

	for node in get_children():
		remove_child(node)

	for node in children:
		add_child(node)


func _on_mission_added() -> void:
	# if it's first mission added, remove dummy workspace
	if fm_manager.missions.size() == 1:
		# free this instantly, or it will break the next code
		get_child(0).free()

	var ws := _add_workspace_node(fm_manager.curr_mission)
	current_tab = ws.get_index()
	#if ws.get("packing"):
		#ws.packing.select_next_available()
	_sort_nodes_by_name()


func _add_workspace_node(mission:Mission) -> TabContainer:
	var ws:Control

	if mission.file_tree != null:
		ws = preloads.Workspace.instantiate() as TabContainer
		add_child(ws)
		ws.packing.tab_changed.connect(_on_workspace_tab_changed)
		ws.init(mission)
	else:
		ws = preloads.DummyWorkspace.instantiate() as TabContainer
		add_child(ws)
		ws.init(mission)

	return ws



func _on_mission_deleted(index:int) -> void:
	get_child(index).queue_free()
	if fm_manager.missions.size():
		current_tab = fm_manager.get_mission_index()
		#logs.print("deleted - current_tab:", current_tab, fm_manager.curr_mission.id)
	else:
		add_child(preloads.DummyWorkspace.instantiate())
		current_tab = 0


