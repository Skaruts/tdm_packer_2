extends ConfirmationDialog

signal about_to_close
signal popup_closed(confirmed:bool)


func _ready() -> void:
#	about_to_popup.connect(_on_about_to_popup)
	close_requested.connect(_on_close_requested)
	visibility_changed.connect(_on_visibility_changed)


func open(info:Dictionary) -> void:
	if info.is_empty():
		info = {
			title="No title",
			text = "no text",
			ok = "OK",
			cancel = "Cancel",
		}

	title = info.title
	dialog_text = info.text
	popup()


func _on_close_requested() -> void:
	hide()


func _on_visibility_changed() -> void:
	if not visible:
		about_to_close.emit()


func _on_confirmed() -> void:
	popup_closed.emit(true)
	hide()


func _on_canceled() -> void:
	popup_closed.emit(false)
	hide()
