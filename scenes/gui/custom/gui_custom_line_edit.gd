class_name CustomLineEdit
extends LineEdit


enum {
	COLOR_NORMAL,
	COLOR_VALID,
	COLOR_WARNING,
	COLOR_ERROR,
}

func _ready() -> void:
	caret_blink = true
	drag_and_drop_selection_enabled = false


func set_color(index:int) -> void:
	match index:
		COLOR_NORMAL:  set("theme_override_colors/font_color", data.TEXT_COLOR)
		COLOR_VALID:   set("theme_override_colors/font_color", data.VALID_COLOR)
		COLOR_WARNING: set("theme_override_colors/font_color", data.WARNING_COLOR)
		COLOR_ERROR:   set("theme_override_colors/font_color", data.ERROR_COLOR)
