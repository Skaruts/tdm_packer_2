class_name GuiTabFiles
extends TabContainer


#func _enter_tree() -> void:
	#gui.tab_files = self


func on_mission_reloaded(force_update:=false) -> void:
	pass

func update_pack_name() -> void:
	pass
