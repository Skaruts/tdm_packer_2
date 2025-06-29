extends BasePopup


@onready var lb_header: Label = %lb_header
@onready var report_panel: ReportPanel = %report_panel



enum State {
	IDLE,
	ENDED,
	PACKING,
	VALIDATING,
}
var state := State.IDLE





func _on_ready() -> void:
	pass


func _on_popup() -> void:
	var mission := fms.curr_mission

	report_panel.clear()
	if mission.pack_report != "":
		report_panel.set_bb_text(mission.pack_report)

	title = "Packing '%s'  (%s)" % [mission.mdata.title, mission.id]
	state = State.IDLE
	report_panel.set_percentage(0)
	update_buttons()


func _on_close() -> void:
	fms.curr_mission.pack_report = report_panel.get_bb_text()
	_clear_text()


func _on_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_bar_button_pressed(BarButton.CANCEL)
	elif event.is_action_pressed("ui_accept")\
	and state == State.IDLE:
		_pack_files()


func _on_bar_button_pressed(idx:int) -> void:
	if state <= State.ENDED:
		if idx == BarButton.APPLY:
			await _clear_text()
			_validate_files()
		elif idx == BarButton.OK:
			await _clear_text()
			_pack_files()
		elif idx == BarButton.CANCEL:
			logs.print("canceling")
			close_requested.emit()
	elif idx == BarButton.CANCEL:
		state = State.IDLE
		report_panel.aborted = true
		update_buttons()


func update_buttons() -> void:
	if state == State.IDLE:
		Utils.set_button_state(btn_ok,     true)
		Utils.set_button_state(btn_cancel, true)
		Utils.set_button_state(btn_apply,  true)
		btn_cancel.text   = "Cancel"
	elif state == State.PACKING:
		report_panel.set_percentage(0)
		Utils.set_button_state(btn_ok, false)
		btn_cancel.text    = "Abort"
	elif state == State.ENDED:
		Utils.set_button_state(btn_ok, true)
		btn_cancel.text   = "Done"
	elif state == State.VALIDATING:
		Utils.set_button_state(btn_ok,     false)
		Utils.set_button_state(btn_cancel, false)
		Utils.set_button_state(btn_apply,  false)


func _clear_text() -> void:
	await report_panel.clear()


func _pack_files() -> void:
	if not await _validate_files():
		await get_tree().process_frame
		report_panel.error("\nCan't pack mission: there are invalid paths.")
		return
	state = State.PACKING
	update_buttons()
	fms.force_save_mission()
	await launcher.run_in_local_thread(FMUtils.pack_mission.bind(report_panel, fms.curr_mission))
	state = State.ENDED
	update_buttons()


func _validate_files() -> bool:
	state = State.VALIDATING
	update_buttons()
	var valid: bool = await launcher.run_in_local_thread(FMUtils.validate_paths.bind(report_panel, fms.curr_mission))
	state = State.IDLE
	update_buttons()
	return valid


#func is_packing() -> bool:
	#return state == State.PACKING
