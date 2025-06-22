class_name MainProgressBar
extends Window


@onready var lb_status    : Label       = %lb_status
@onready var progress_bar : ProgressBar = %progress_bar

var aborted := false


func _enter_tree() -> void:
	visible = false

func show_bar() -> void:
	aborted = false
	visible = true

func hide_bar() -> void:
	aborted = false
	visible = false


func set_text(text:String) -> void:
	lb_status.text = text


func set_percentage(percent:float) -> void:
	progress_bar.value = percent * 100


func set_cancel_enabled(enable:bool) -> void:
	%btn_canel.visible = enable


func _on_btn_canel_pressed() -> void:
	aborted = true


func _on_window_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		aborted = true
