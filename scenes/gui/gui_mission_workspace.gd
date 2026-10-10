class_name MissionWorkspace
extends MarginContainer

@onready var tab_package: GuiTabPackage = %tab_package
@onready var tab_files: GuiTabFiles = %tab_files
@onready var node_mission_workspace: TabContainer = %node_mission_workspace
@onready var node_missing_mission: TabContainer = %node_missing_mission


var _mission: Mission


#func _enter_tree() -> void:
	#gui.workspace_panel = self


func update_nodes() -> void:
	node_mission_workspace.visible = not fms.is_mission_missing(_mission)
	node_missing_mission.visible = fms.is_mission_missing(_mission)


func set_mission(m:Mission) -> void:
	_mission = m
	update_nodes()
	tab_package.set_mission(m)
	#tab_files.set_mission(m) # TODO


func on_mission_reloaded(force_update:=false) -> void:
	update_nodes()
	if fms.is_mission_missing(_mission): return
	tab_package.on_mission_reloaded(force_update)
	tab_files.on_mission_reloaded(force_update)



func update_pack_name() -> void:
	if fms.is_mission_missing(_mission): return
	tab_package.update_pack_name()
	tab_files.update_pack_name()


func switch_main_tab(tab_idx: int) -> void:
	node_mission_workspace.current_tab = tab_idx
