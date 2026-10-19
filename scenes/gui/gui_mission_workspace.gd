class_name MissionWorkspace
extends MarginContainer

@onready var tab_package: GuiTabPackage = %tab_package
@onready var tab_files: GuiTabFiles = %tab_files
@onready var node_mission_workspace: TabContainer = %node_mission_workspace


var _mission: Mission


#func _enter_tree() -> void:
	#gui.workspace_panel = self


# func update_nodes() -> void:
	# node_mission_workspace.visible = true
	# node_missing_mission.visible = fms.is_mission_missing(_mission.id)


func set_mission(m:Mission) -> void:
	_mission = m
	# update_nodes()
	tab_package.set_mission(m)
	tab_files.set_mission(m)


func on_mission_reloaded(force_update:=false) -> void:
	# update_nodes()
	tab_package.on_mission_reloaded(force_update)
	tab_files.on_mission_reloaded(force_update)



func update_pack_name() -> void:
	# tab_package.update_pack_name()
	# tab_files.update_pack_name()
	pass


func switch_main_tab(tab_idx: int) -> void:
	node_mission_workspace.current_tab = tab_idx
