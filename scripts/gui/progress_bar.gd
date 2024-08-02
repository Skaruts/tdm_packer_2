extends Window

signal about_to_close

@onready var label: Label = %Label
@onready var progress_bar: ProgressBar = %ProgressBar



func _on_progress_bar_value_changed(value: float) -> void:
	if progress_bar.value == progress_bar.max_value:
		close_requested.emit()


func open(info:Dictionary) -> void:
	title = info.title
	label.text = info.text
	popup()


func set_text(text:String) -> void:
	label.text = text


func _on_close_requested() -> void:
	logs.print("_ON_CLOSE_REQUESTED")
	hide()


func _on_visibility_changed() -> void:
	if not visible:
		about_to_close.emit()
