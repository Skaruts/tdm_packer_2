extends TabContainer


class ConsoleLine:
	var text:String
	var color:Color
	var new_line:bool
	func _init(t:String, c:Variant=null, nl:=true) -> void:
		text = t
		if c: color = c as Color
		new_line = nl


const __NULL = "__non-null_null__"
const MAX_LINES := 512

var lines:Array[ConsoleLine]
var timer:Timer

@onready var console_label: RichTextLabel = %console_label



func _enter_tree() -> void:
	console._console_node = self


func _ready() -> void:
	timer = Timer.new()
	timer.autostart = true
	#timer.one_shot = true
	timer.wait_time = 15
	timer.timeout.connect(_truncate_history)
	add_child(timer)


func _on_console_btn_pressed() -> void:
	console_label.visible = not console_label.visible


func _truncate_history() -> void:
	if lines.size() <= MAX_LINES: return
	console_label.clear()
	console_label.text = ""

	var i := 0
	while lines.size() > MAX_LINES and i < 10:
		lines.pop_front()
		i += 1

	for line in lines:
		_push_text(line.text, line.color, line.new_line)


func _add_line(string:String, color:Variant=null, new_line:=true) -> void:
	var line := ConsoleLine.new(string, color, new_line)
	lines.append(line)
	_push_text(string, color, new_line)


func _push_text(string:String, color:Variant=null, new_line:=true) -> void:
	if color != null:
		console_label.push_color(color as Color)
		console_label.add_text(string)
		console_label.pop()
	else:
		console_label.add_text(string)

	if new_line:
		console_label.newline()




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		API

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func print( arg0:Variant=__NULL,  arg1:Variant=__NULL,  arg2:Variant=__NULL,  arg3:Variant=__NULL,
			arg4:Variant=__NULL,  arg5:Variant=__NULL,  arg6:Variant=__NULL,  arg7:Variant=__NULL,
			arg8:Variant=__NULL,  arg9:Variant=__NULL,  arg10:Variant=__NULL, arg11:Variant=__NULL,
			arg12:Variant=__NULL, arg13:Variant=__NULL, arg14:Variant=__NULL, arg15:Variant=__NULL,
			arg16:Variant=__NULL, arg17:Variant=__NULL, arg18:Variant=__NULL, arg19:Variant=__NULL
		) -> void:

	var msg:String = logs.varargs_to_str([arg0,  arg1,  arg2,  arg3,  arg4, arg5,  arg6,  arg7,  arg8,  arg9,
		arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19])

	_add_line(msg, data.TEXT_COLOR)


func error(msg:String) -> void:
	_add_line("ERROR: %s" % [msg], logs.COLOR_ERROR, true)


func warning(msg:String) -> void:
	_add_line("WARNING: %s" % [msg], logs.COLOR_WARNING, true)


func info(msg:String) -> void:
	_add_line("%s" % [msg], logs.COLOR_INFO, true)


func reminder(msg:String) -> void:
	_add_line("REMINDER: %s" % [msg], logs.COLOR_REMINDER, true)


func task(msg:String) -> void:
	_add_line("%s" % [msg], logs.COLOR_TASK, true)

