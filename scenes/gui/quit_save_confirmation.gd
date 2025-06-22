extends ConfirmationDialog

signal popup_closed(canceled:bool)
#
#enum {
	#CANCEL,
	#QUIT_NO_SAVE,
	#SAVE_AND_QUIT,
#}

const ACTION = "dont_save"

func _on_about_to_popup() -> void:
	if not canceled.is_connected(_on_canceled): canceled.connect(_on_canceled)
	if not confirmed.is_connected(_on_confirmed): confirmed.connect(_on_confirmed)
	if not custom_action.is_connected(_on_custom_action): custom_action.connect(_on_custom_action)


func _ready() -> void:
	add_button("Don't Save", false, ACTION)


func _on_custom_action(_action: StringName) -> void:
	close_requested.emit()
	popup_closed.emit(false)
	hide()

func _on_canceled() -> void:
	popup_closed.emit(true)

func _on_confirmed() -> void:
	popup_closed.emit(false)
