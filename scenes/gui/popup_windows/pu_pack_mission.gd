extends BasePopup


@onready var lb_header: Label = %lb_header
@onready var rtl_listing: RichTextLabel = %rtl_listing
@onready var progress_bar: ProgressBar = %progress_bar

enum State {
	IDLE,
	ENDED,
	PACKING,
}

var state := State.IDLE


func _on_ready() -> void:
	pass


func _on_popup() -> void:
	title = "Packing '%s'  (%s)" % [fms.curr_mission.mdata.title, fms.curr_mission.id]
	rtl_listing.clear()
	state = State.IDLE
	progress_bar.value = 0
	update_buttons()


func _on_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_bar_button_pressed(BarButton.CANCEL)
	elif event.is_action_pressed("ui_accept")\
	and state == State.IDLE:
		_start_packing()


func update_buttons() -> void:
	if state == State.IDLE:
		btn_ok.disabled   = false
		btn_ok.focus_mode = Control.FOCUS_ALL
		btn_cancel.text   = "Cancel"
	elif state == State.PACKING:
		progress_bar.value = 0
		btn_ok.disabled    = true
		btn_ok.focus_mode  = Control.FOCUS_NONE
		btn_cancel.text    = "Abort"
	elif state == State.ENDED:
		btn_ok.disabled   = false
		btn_ok.focus_mode = Control.FOCUS_ALL
		btn_cancel.text   = "Done"


func _on_bar_button_pressed(idx:int) -> void:
	if state <= State.ENDED:
		if idx == BarButton.OK:
			_start_packing()
		elif idx == BarButton.CANCEL:
			close_requested.emit()
	elif idx == BarButton.CANCEL:
		_abort_packing()


func _start_packing() -> void:
	state = State.PACKING
	rtl_listing.clear()
	update_buttons()
	await fms.pack_mission()
	_end_packing()


func _abort_packing() -> void:
	state = State.IDLE
	update_buttons()


func _end_packing() -> void:
	state = State.ENDED
	update_buttons()


func is_packing() -> bool:
	return state == State.PACKING


func _on_close() -> void:
	pass




func set_percentage(percent:float) -> void:
	progress_bar.value = percent * 100



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Text API

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

func print(msg:String) -> void:
	_push_text("%s" % [msg], data.TEXT_COLOR, true)
	console.print(msg)

func task(msg:String) -> void:
	_push_text("%s" % [msg], logs.COLOR_TASK, true)
	console.task(msg)

func info(msg:String) -> void:
	_push_text("%s" % [msg], logs.COLOR_INFO, true)
	console.info(msg)

func error(msg:String) -> void:
	_push_text("%s" % [msg], logs.COLOR_ERROR, true)
	console.error(msg)

func _push_text(string:String, color:Color, new_line:bool) -> void:
	if color != null:
		rtl_listing.push_color(color)
		rtl_listing.add_text(string)
		rtl_listing.pop()
	else:
		rtl_listing.add_text(string)

	if new_line:
		rtl_listing.newline()


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#	signals

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
