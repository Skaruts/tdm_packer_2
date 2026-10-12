class_name TextFileEditor
extends VBoxContainer


@onready var code_edit: CodeEdit = %CodeEdit

func _ready() -> void:
	pass



func update_text(text: String) -> void:
	code_edit.text = text


func tag_code_editor() -> void:
	code_edit.tag_saved_version()


func update_button_states() -> void:
	# var mis: Mission = (owner as GuiTabFiles)._mission

	# var is_missing := fms.is_mission_missing(mis.id)
	# var is_readonly := fms.is_mission_readonly(mis.id)
	# var valid_mission := not is_missing and not is_readonly

	# if valid_mission:
	# 	# update toolbar buttons
	# 	# when they exist
	# 	pass
	pass
