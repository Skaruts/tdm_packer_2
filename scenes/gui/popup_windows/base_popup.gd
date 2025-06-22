class_name BasePopup extends Window


enum BarButton {
	OK,
	CANCEL,
	APPLY,
}

var temp_data:Dictionary


@onready var btn_apply: Button = %btn_apply
@onready var btn_ok: Button = %btn_ok
@onready var btn_cancel: Button = %btn_cancel


func _on_ready()                      -> void: pass  # to override
func _on_popup()                      -> void: assert(false, "must override")
func _on_input(_event: InputEvent)    -> void: pass  # to override
func _on_bar_button_pressed(_idx:int) -> void: assert(false, "must override")
func _on_close()                      -> void: pass  # to override


func _ready() -> void:
	if visible:
		visible = false

	about_to_popup.connect(
		func() -> void:
			_on_popup()
	)
	close_requested.connect(
		func() -> void:
			_on_close()
			hide()
	)

	%btn_ok.pressed.connect(_on_bar_button_pressed.bind(BarButton.OK))
	%btn_cancel.pressed.connect(_on_bar_button_pressed.bind(BarButton.CANCEL))
	%btn_apply.pressed.connect(_on_bar_button_pressed.bind(BarButton.APPLY))

	_on_ready()


func _input(event: InputEvent) -> void:
	_on_input(event)
	#if   event.is_action_pressed("ui_cancel"): close(false)
#	elif event.is_action_pressed("ui_accept"): close(true)
