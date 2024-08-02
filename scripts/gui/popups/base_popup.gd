class_name BasePopup extends Window


signal popup_closed(confirmed:bool)
signal popup_confirmed
signal popup_canceled
signal about_to_close

var pu_data:Variant



func _init() -> void:
	about_to_popup.connect(_on_about_to_popup)
	close_requested.connect(_on_close_requested)


func open(_pu_data:Variant=null) -> void:
	pu_data = _pu_data
	popup()


func _input(event: InputEvent) -> void:
	if not visible: return
	if   event.is_action_pressed("ui_cancel"): close(false)
#	elif event.is_action_pressed("ui_accept"): close(true)


func _on_about_to_popup() -> void:
	pass


func close(confirmed:=false) -> void:
	popup_closed.emit(confirmed)
	about_to_close.emit()
	hide()


func _on_close_requested() -> void:
	popup_closed.emit(false)
	about_to_close.emit()
	hide()
