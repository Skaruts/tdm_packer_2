extends BasePopup


@onready var lb_header: Label = %lb_header
@onready var rtl_listing: RichTextLabel = %rtl_listing
@onready var progress_bar: ProgressBar = %progress_bar

@onready var text_menu: PopupMenu = %text_menu


enum TextOptions {
	SELECT_ALL,
	COPY,
}

enum State {
	IDLE,
	ENDED,
	PACKING,
	VALIDATING,
}
var state := State.IDLE


var _output_bb_code := ""



func _on_ready() -> void:
	text_menu.size = Vector2(10, 10) #
	text_menu.add_item("Copy",       TextOptions.COPY)
	text_menu.add_item("Select all", TextOptions.SELECT_ALL)

	text_menu.id_pressed.connect(
		func(id:int) -> void:
			if id == TextOptions.COPY:
				DisplayServer.clipboard_set( rtl_listing.get_selected_text() )
			elif id == TextOptions.SELECT_ALL:
				rtl_listing.select_all()
	)
	rtl_listing.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton:
				if event.button_index == 2 and event.pressed:
					text_menu.position = get_mouse_position() + Vector2(position)
					text_menu.popup()
	)


func _on_popup() -> void:
	var mission := fms.curr_mission

	if mission.pack_report:
		rtl_listing.append_text(mission.pack_report)
		_output_bb_code = mission.pack_report

	title = "Packing '%s'  (%s)" % [mission.mdata.title, mission.id]
	state = State.IDLE
	progress_bar.value = 0
	update_buttons()


func _on_close() -> void:
	fms.curr_mission.pack_report = _output_bb_code
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
		update_buttons()


func update_buttons() -> void:
	if state == State.IDLE:
		Utils.set_button_state(btn_ok,     true)
		Utils.set_button_state(btn_cancel, true)
		Utils.set_button_state(btn_apply,  true)
		btn_cancel.text   = "Cancel"
	elif state == State.PACKING:
		progress_bar.value = 0
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
	rtl_listing.clear()
	_output_bb_code = ""
	# wait two frames to provide some visual feedback in case new text output
	# is the same after clearing
	await get_tree().process_frame
	await get_tree().process_frame


func _pack_files() -> void:
	if not await _validate_files():
		await get_tree().process_frame
		error("\nCan't pack mission: there are invalid paths.")
		return
	state = State.PACKING
	update_buttons()
	fms.force_save_mission()
	await launcher.run_in_local_thread(FMUtils.pack_mission.bind(self, fms.curr_mission))
	state = State.ENDED
	update_buttons()


func _validate_files() -> bool:
	state = State.VALIDATING
	update_buttons()
	var valid: bool = await launcher.run_in_local_thread(FMUtils.validate_paths.bind(self, fms.curr_mission))
	state = State.IDLE
	update_buttons()
	return valid


func is_packing() -> bool:
	return state == State.PACKING


func set_percentage(percent:float) -> void:
	progress_bar.value = percent * 100



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Text API

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func print(msg:String) -> void:
	_push_text("%s" % [msg], data.TEXT_COLOR, true)
	#console.print(msg)

func task(msg:String) -> void:
	_push_text("%s" % [msg], logs.COLOR_TASK, true)
	#console.task(msg)

func info(msg:String) -> void:
	_push_text("%s" % [msg], logs.COLOR_INFO, true)
	#console.info(msg)

func error(msg:String) -> void:
	_push_text("%s" % [msg], logs.COLOR_ERROR, true)
	#console.error(msg)

func warning(msg:String) -> void:
	_push_text("%s" % [msg], logs.COLOR_WARNING, true)

func reminder(msg:String) -> void:
	_push_text("%s" % [msg], logs.COLOR_REMINDER, true)


func _push_text(string:String, color:Color, new_line:bool) -> void:
	if color != null:
		var bb_string := '[color=%s]%s[/color]' % [color.to_html(), string]
		_output_bb_code += bb_string
		if new_line:
			_output_bb_code += '\n'
		rtl_listing.append_text(bb_string)
	else:
		rtl_listing.append_text(string)

	if new_line:
		rtl_listing.newline()
