class_name ColorButton
extends HBoxContainer

signal color_changed(color: Color)

@onready var _label: Label = $Label
@onready var _color_button: ColorPickerButton = $ColorPickerButton


var text: String:
	set(str): _label.text = str
	get:      return _label.text


var color: Color:
	set(col): _color_button.color = col
	get:      return _color_button.color


func _on_color_picker_button_color_changed(color: Color) -> void:
	color_changed.emit(color)
