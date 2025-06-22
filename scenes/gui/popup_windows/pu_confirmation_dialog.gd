extends ConfirmationDialog

signal answer(accepted:bool)

func _ready() -> void:
	about_to_popup.connect(func() -> void:
		size = Vector2(10, 10) # shrink to reset to minimum_size
		confirmed.connect(_on_answer_given.bind(true))
		canceled.connect(_on_answer_given.bind(false))
	)

func _on_answer_given(accepted:bool) -> void:
	answer.emit(accepted)
