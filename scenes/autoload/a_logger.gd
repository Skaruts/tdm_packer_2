extends Node
# autoloaded script


# version 10
# TODO:
#      - dump logs to a file on demand
#          . or periodically?
#          . or append on the fly?



const __NULL = "__non-null_null__"


const COLOR_TASK     := Color(0.67333334684372, 1, 0.60000002384186)
const COLOR_ERROR    := Color(1, 0.419607847929, 0.419607847929)
const COLOR_WARNING  := Color(1, 0.787, 0.29)
const COLOR_INFO     := Color(0.51999998092651, 0.85599994659424, 1)
const COLOR_REMINDER := Color(1, 0.53999996185303, 0.9080001115799)


var colors := {
	end_tag  = "[/color]",

	info     = "[color=%s]" % [COLOR_INFO.to_html(false)],    # 78e4ff
	warning  = "[color=%s]" % [COLOR_WARNING.to_html(false)],    # ffcc66
	reminder = "[color=%s]" % [COLOR_REMINDER.to_html(false)],
	error    = "[color=%s]" % [COLOR_ERROR.to_html(false)],    # ff6b6b
	caller   = "[color=%s]" % [Color(0.71, 0.47, 1).to_html(false)],    # b778ff
	success  = "[color=%s]" % [Color(0.47, 1, 0.47).to_html(false)],    # 7aff78
	task     = "[color=%s]" % [COLOR_TASK.to_html(false)],    # ffbb78
}


class LoggerError extends RefCounted:
	var ok:bool
	var error:String
	func _init(_ok:bool, err_msg:Variant=null) -> void:
		ok = _ok
		if err_msg:
			error = err_msg as String



var messages:Array[String]
var errors:Array[String]
var warnings:Array[String]
var reminders:Array[String]



func __store_message(message:String) -> void:
	messages.append(message)

@warning_ignore("shadowed_variable")
func __store_error(error:String) -> void:
	messages.append(error)
	errors.append(error)

@warning_ignore("shadowed_variable")
func __store_warning(warning:String) -> void:
	messages.append(warning)
	warnings.append(warning)

@warning_ignore("shadowed_variable")
func __store_reminder(reminder:String) -> void:
	messages.append(reminder)
	reminders.append(reminder)



func _format(message:String, format:String) -> String:
	return "%s%s%s" % [ colors[format], message, colors.end_tag ]


func _get_caller(error_level:int) -> String:
	var caller:String
	var stack := get_stack()
	if stack: # seems like there's no stack trace inside threads, or if project is exported
		var caller_info: Dictionary = stack[error_level+1]    # caller_info [source, function, line]
		caller = "%s(%s): " % [caller_info.source.get_file(), caller_info.line]
	return caller



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Public API

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func error(msg:Variant, __error_level:=0) -> void:
	var caller:String = _get_caller(1)
	var full_msg := caller + str(msg)
	__store_error(full_msg)

	# if project exported, don't use rich text formatting
	if OS.has_feature("template"):
		push_error( full_msg )
	else:
		print_rich( _format("● ERROR: " + full_msg, "error") )


func warning(msg:Variant, __error_level:=0) -> void:
	var caller:String = _get_caller(1)
	var full_msg := caller + str(msg)
	__store_warning(full_msg)

	if OS.has_feature("template"):
		push_warning( full_msg )
	else:
		print_rich( _format("● WARNING: " + full_msg, "warning") )


func reminder(msg:Variant, __error_level:=0) -> void:
	var caller:String = _get_caller(1)
	var full_msg := "● REMINDER: " + caller + str(msg)
	__store_reminder(full_msg)

	if OS.has_feature("template"):
		print( "> REMINDER: " + str(msg) )
	else:
		print_rich( _format(full_msg, "reminder") )


func info(msg:Variant) -> void:
	var full_msg := "INFO: " + str(msg)
	__store_message(full_msg)

	if OS.has_feature("template"):
		print( full_msg )
	else:
		print_rich( _format(full_msg, "info") )


func task(msg:Variant) -> void:
	var full_msg := "TASK: " + str(msg)
	__store_message(full_msg)

	if OS.has_feature("template"):
		print( full_msg )
	else:
		print_rich(_format(full_msg, "task"))



func varargs_to_str(array:Array) -> String:
	var args: Array[Variant] = array.filter(
		func(value:Variant) -> bool:
			return typeof(value) != TYPE_STRING or value != __NULL
	)
	return "%s ".repeat(args.size()).strip_edges() % args


# simulates varargs
func print( arg0:Variant=__NULL,  arg1:Variant=__NULL,  arg2:Variant=__NULL,  arg3:Variant=__NULL,
			arg4:Variant=__NULL,  arg5:Variant=__NULL,  arg6:Variant=__NULL,  arg7:Variant=__NULL,
			arg8:Variant=__NULL,  arg9:Variant=__NULL,  arg10:Variant=__NULL, arg11:Variant=__NULL,
			arg12:Variant=__NULL, arg13:Variant=__NULL, arg14:Variant=__NULL, arg15:Variant=__NULL,
			arg16:Variant=__NULL, arg17:Variant=__NULL, arg18:Variant=__NULL, arg19:Variant=__NULL
		) -> void:

	var msg:String = varargs_to_str([arg0,  arg1,  arg2,  arg3,  arg4, arg5,  arg6,  arg7,  arg8,  arg9,
		arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19])

	var caller:String = _get_caller(1)

	var full_msg := caller + msg
	__store_message(full_msg)

	if OS.has_feature("template"):
		print(full_msg)
	else:
		print_rich(_format(caller, "caller") + msg)


# print array of args
func printa( args:Array, __error_level := 1) -> void:
	var msg:String = varargs_to_str(args)
	var caller:String = _get_caller(__error_level)

	var full_msg := caller + msg
	__store_message(full_msg)

	if OS.has_feature("template"):
		print(full_msg)
	else:
		print_rich(_format(caller, "caller") + msg)


# run a function, benchmark it, and return its results
# if not 'silent', automatically print the 'task' or 'error' message
# provided in 'messages', and reports the benchmark time
@warning_ignore("shadowed_variable")
func run(f:Callable, messages:={}, silent:=false) -> Variant:
	if silent: return f.call()

	var t1 := Time.get_ticks_msec()
	var res:Variant = f.call()
	var t2 := Time.get_ticks_msec()

	var time_str := "%.3f s" % [(t2-t1)/1000.0]

	if not messages.is_empty():
		if not res is LoggerError or res.ok:
			task(messages.task + "  (%s)" % [time_str])
		else:
			error(messages.error + res.error, 1)

	return res
