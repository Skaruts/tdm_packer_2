extends ConfirmationDialog

signal about_to_close
signal popup_closed(state:int)


const ACTION = "save&quit"

enum {
	CANCEL,
	QUIT_NO_SAVE,
	SAVE_AND_QUIT,
}

func _ready() -> void:
	#	about_to_popup.connect(_on_about_to_popup)
	close_requested.connect(_on_close_requested)
	visibility_changed.connect(_on_visibility_changed)

	add_button("Save & Quit", false, ACTION)



func open(info:Dictionary) -> void:
	if info.is_empty():
		info = {
			title="No title",
			text = "no text",
			state = CANCEL,
		}

	title = info.title
	dialog_text = info.text
	popup()





func _on_custom_action(action: StringName) -> void:
	popup_closed.emit(SAVE_AND_QUIT)
	hide()

func _on_confirmed() -> void:
	popup_closed.emit(QUIT_NO_SAVE)
	hide()

func _on_canceled() -> void:
	popup_closed.emit(CANCEL)
	hide()





func _on_close_requested() -> void:
	hide()


func _on_visibility_changed() -> void:
	if not visible:
		about_to_close.emit()
