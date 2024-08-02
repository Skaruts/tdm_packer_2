extends TabContainer


@onready var btn_add_mission: Button = %btn_add_mission
@onready var btn_delete_mission: Button = %btn_delete_mission
@onready var item_list: ItemList = %ItemList



func _ready() -> void:
	fm_manager.mission_switched.connect(_on_mission_switched)
	fm_manager.mission_saved.connect(_on_mission_switched) # this is not a mistake
	fm_manager.mission_dirty_state_changed.connect(_on_mission_dirty_state_changed)

	refresh_missions()



func update_buttons() -> void:
	#btn_add_mission.disabled = data.config.tdm_path == ""

	if fm_manager.missions.size():
		btn_delete_mission.disabled   = false
	else:
		btn_delete_mission.disabled   = true


func _on_mission_dirty_state_changed() -> void:
	var idx := fm_manager.get_mission_index()
	var id := fm_manager.curr_mission.id
	if fm_manager.curr_mission.dirty:
		id += " (*)"
	item_list.set_item_text(idx, id)


func refresh_missions() -> void:
	item_list.clear()
	for m:Mission in fm_manager.missions:
		var id := m.id
		if m.dirty:
			id += " (*)"
		var idx := item_list.add_item(id)
		if m.file_tree == null:
			item_list.set_item_custom_fg_color(idx, data.ERROR_COLOR)
			item_list.set_item_metadata(idx, "invalid mission")
	update_buttons()


func _on_mission_switched() -> void:
	refresh_missions()
	if fm_manager.missions.size():
		var idx := fm_manager.missions.find(fm_manager.curr_mission)
		item_list.select(idx)


func _on_btn_add_mission_pressed() -> void:
	if not data.config.tdm_path:
		popups.warning_report.open({
			title = "Warning",
			text = "No Dark Mod path set.\n(Menu > Settings > Paths)",
		})
		return

	var dic:Dictionary = {}

	popups.add_mission.open(dic)

	var confirmed:bool = await popups.add_mission.popup_closed
	if confirmed:
		await fm_manager.add_mission(dic.id)


func _on_btn_delete_mission_pressed() -> void:
	popups.confirmation.open({
		title= "Please confirm...",
		text = "Are you sure you want to remove mission '%s'?" % [fm_manager.curr_mission.id],
	})
	var confirmed:bool = await popups.confirmation.popup_closed
	if confirmed:
		fm_manager.remove_mission()


func _on_item_list_item_selected(index: int) -> void:
	fm_manager.select_mission(index)
