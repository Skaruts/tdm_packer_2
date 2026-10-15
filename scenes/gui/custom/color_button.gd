class_name ColorButton
extends HBoxContainer

signal color_changed(color: Color)

@onready var label: Label = $Label
@onready var color_button: ColorPickerButton = $ColorPickerButton


var text: String:
	set(str): label.text = str
	get:      return label.text


var color: Color:
	set(col): color_button.color = col
	get:      return color_button.color


func _on_color_picker_button_color_changed(color: Color) -> void:
	color_changed.emit(color)
