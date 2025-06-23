class_name MissionWorkspace
extends TabContainer

@onready var tab_package: GuiTabPackage = %tab_package
@onready var tab_files: GuiTabFiles = %tab_files


var _mission: Mission


#func _enter_tree() -> void:
	#gui.workspace_panel = self


func set_mission(m:Mission) -> void:
	_mission = m
	tab_package.set_mission(m)
	#tab_files.set_mission(m) # TODO


func on_mission_reloaded(force_update:=false) -> void:
	tab_package.on_mission_reloaded(force_update)
	tab_files.on_mission_reloaded(force_update)

func update_pack_name() -> void:
	tab_package.update_pack_name()
	tab_files.update_pack_name()
