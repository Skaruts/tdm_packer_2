class_name BaseWorkspace
extends Control

# TODO: rethink the naming of the workspace classes, it's confusing


var _mission:Mission


func init(mission:Mission) -> void:
	_mission = mission
	assert(_mission != null)
	_init_signals()


func _init_signals() -> void:     assert(false, "to override")
func _on_mission_saved() -> void: assert(false, "to override if signal connected")
