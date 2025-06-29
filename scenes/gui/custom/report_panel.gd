class_name ReportPanel
extends MarginContainer


enum LabelPosition {
	TOP,
	BOTTOM,
}


@onready var _rtl: RichTextLabel = %RichTextLabel
@onready var _pb: ProgressBar = %ProgressBar

var _bb_code := ""

var aborted: bool


func set_progress_bar(enable:bool) -> void:
	_pb.visible = enable


func set_label_position(pos:LabelPosition) -> void:
	if   pos == LabelPosition.TOP:    _pb.move_to_front()
	elif pos == LabelPosition.BOTTOM: _rtl.move_to_front()


func clear() -> void:
	_rtl.clear()
	_bb_code = ""
	aborted = false
	# wait two frames to provide some visual feedback in case new text output
	# is the same after clearing
	await get_tree().process_frame
	await get_tree().process_frame


func get_selected_text() -> String:
	return _rtl.get_selected_text()


func select_all() -> void:
	_rtl.select_all()


func set_bb_text(text:String) -> void:
	_rtl.append_text(text)
	_bb_code = text


func get_bb_text() -> String:
	return _bb_code


func set_percentage(percent:float) -> void:
	_pb.value = percent * 100



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Text API

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=



func _push_text(string:String, color:Color, new_line:=true) -> void:
	if color != null:
		var bb_string := '[color=%s]%s[/color]' % [color.to_html(), string]
		_bb_code += bb_string
		if new_line:
			_bb_code += '\n'
		_rtl.append_text(bb_string)
	else:
		_rtl.append_text(string)

	if new_line:
		_rtl.newline()


func print_color(msg:String, color:Color, new_line:=true) -> void:
	_push_text("%s" % [msg], color, new_line)


func print(msg:String, new_line:=true) -> void:
	_push_text("%s" % [msg], data.TEXT_COLOR, new_line)


func task(msg:String, new_line:=true) -> void:
	_push_text("%s" % [msg], logs.COLOR_TASK, new_line)


func info(msg:String, new_line:=true) -> void:
	_push_text("%s" % [msg], logs.COLOR_INFO, new_line)


func error(msg:String, new_line:=true) -> void:
	_push_text("%s" % [msg], logs.COLOR_ERROR, new_line)


func warning(msg:String, new_line:=true) -> void:
	_push_text("%s" % [msg], logs.COLOR_WARNING, new_line)


func reminder(msg:String, new_line:=true) -> void:
	_push_text("%s" % [msg], logs.COLOR_REMINDER, new_line)
