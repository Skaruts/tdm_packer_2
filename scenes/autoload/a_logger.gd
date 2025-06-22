extends Node
# autoloaded script

#
#        Logger     (version 17)
#


const _LOGS_FILE = "res://logs.txt"
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


#var ansi_colors := { # TODO: this doesn't seem to work on windows 7
	#end_tag  = "[/fgcolor]",
#
	#info     = "[fgcolor=blue]",
	#warning  = "[fgcolor=yellow]",
	#reminder = "[fgcolor=pink]",
	#error    = "[fgcolor=red]",
	#caller   = "[fgcolor=purple]",
	#success  = "[fgcolor=green]",
	#task     = "[fgcolor=lime]",
#}


class LoggerError extends RefCounted:
	var ok:bool
	var error:String
	func _init(_ok:bool, err_msg:Variant=null) -> void:
		ok = _ok
		if err_msg:
			error = err_msg



var dump_logs     := true

var log_prints    := true
var log_infos     := true
var log_reminders := true
var log_tasks     := true
var log_warnings  := true
var log_errors    := true


var all_messages:Array[String]
@warning_ignore("shadowed_global_identifier")
var prints:Array[String]
var infos:Array[String]
var tasks:Array[String]
var reminders:Array[String]
var warnings:Array[String]
var errors:Array[String]



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Internal API

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _init() -> void:
	if dump_logs: _write_file("")


func _read_file() -> String:
	return FileAccess.get_file_as_string(_LOGS_FILE)

func _write_file(msg:String) -> void:
	var file := FileAccess.open(_LOGS_FILE, FileAccess.WRITE)
	if not file:
		error("Logger: can't write file '%s'" % [_LOGS_FILE])
		return
	file.store_string(msg)
	file.close()



func _dump_message(msg:String) -> void:
	var logs := _read_file()
	if logs == "":
		_write_file("%s" % msg)
	else:
		_write_file("%s\n%s" % [logs, msg])


func _cache_and_dump_message(array:Array[String], msg:String) -> void:
	all_messages.append(msg)
	array.append(msg)
	if dump_logs:
		_dump_message(msg)


func _format(message:String, format:String) -> String:
	#if OS.has_feature("template"):
		#return "%s%s%s" % [ ansi_colors[format], message, ansi_colors.end_tag ]
	#else:
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
func error(msg:Variant, print_path:=true, push:=true, __error_level:=0) -> void:
	if not log_errors: return
	var caller:String = _get_caller(__error_level+1) if print_path else ""
	var full_msg := caller + str(msg)
	_cache_and_dump_message(errors, "● ERROR: " + full_msg)
	if push:
		push_error( full_msg )
	if not OS.has_feature("template") or not push:
		print_rich( _format("● ERROR: " + full_msg, "error") )


func warning(msg:Variant, print_path:=true, push:=true, __error_level:=0) -> void:
	if not log_warnings: return
	var caller:String = _get_caller(__error_level+1) if print_path else ""
	var full_msg := caller + str(msg)
	_cache_and_dump_message(warnings, "● WARNING: " + full_msg)
	if push:
		push_warning( full_msg )
	if not OS.has_feature("template") or not push:
		print_rich( _format("● WARNING: " + full_msg, "warning") )


func print_subwarning(msg:String) -> void:
	if not log_warnings: return
	msg = "\t" + msg
	_cache_and_dump_message(warnings, msg)
	print(msg)


func print_suberror(msg:String) -> void:
	if not log_errors: return
	msg = "\t" + msg
	_cache_and_dump_message(errors, msg)
	print(msg)


func reminder(msg:Variant, print_path:=true, __error_level:=0) -> void:
	if not log_reminders: return
	var caller:String = _get_caller(__error_level+1) if print_path else ""
	var full_msg := "● REMINDER: " + caller + str(msg)
	_cache_and_dump_message(reminders, full_msg)
	print_rich( _format(full_msg, "reminder") )


func info(msg:Variant, print_path:=false, __error_level:=0) -> void:
	if not log_infos: return
	var caller:String = _get_caller(__error_level+1) if print_path else ""
	var full_msg := "INFO: " + caller + str(msg)
	_cache_and_dump_message(infos, full_msg)
	print_rich( _format(full_msg, "info") )


func task(msg:Variant, print_path:=false, __error_level:=0) -> void:
	if not log_tasks: return
	var caller:String = _get_caller(__error_level+1) if print_path else ""
	var full_msg := "TASK: " + caller + str(msg)
	_cache_and_dump_message(tasks, full_msg)
	print_rich(_format(full_msg, "task"))


func varargs_to_str(array:Array) -> String:
	var args: Array[Variant] = array.filter(
		func(value:Variant) -> bool:
			return typeof(value) != TYPE_STRING or value != __NULL
	)
	return "%s ".repeat(args.size()).strip_edges() % args


# simulates varargs, and supports up to 20 arguments
func print( arg0:Variant=__NULL,  arg1:Variant=__NULL,  arg2:Variant=__NULL,  arg3:Variant=__NULL,
			arg4:Variant=__NULL,  arg5:Variant=__NULL,  arg6:Variant=__NULL,  arg7:Variant=__NULL,
			arg8:Variant=__NULL,  arg9:Variant=__NULL,  arg10:Variant=__NULL, arg11:Variant=__NULL,
			arg12:Variant=__NULL, arg13:Variant=__NULL, arg14:Variant=__NULL, arg15:Variant=__NULL,
			arg16:Variant=__NULL, arg17:Variant=__NULL, arg18:Variant=__NULL, arg19:Variant=__NULL
		) -> void:
	if not log_prints: return

	var msg:String = varargs_to_str([arg0,  arg1,  arg2,  arg3,  arg4, arg5,  arg6,  arg7,  arg8,  arg9,
		arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19])

	var __error_level := 1
	var caller:String = _get_caller(__error_level)

	var full_msg := caller + msg
	_cache_and_dump_message(prints, full_msg)
	print_rich(_format(caller, "caller") + msg)


# print array of args
func printa( args:Array, print_path:=false, __error_level:=0) -> void:
	if not log_prints: return
	var msg:String = varargs_to_str(args)
	var caller:String = _get_caller(__error_level+1) if print_path else ""
	var full_msg := caller + msg
	_cache_and_dump_message(prints, full_msg)
	print_rich(_format(caller, "caller") + msg)


# run a function, benchmark it, and return its results
# if not 'suppress', then it prints out the 'task' or 'error' messages
# provided in the 'msgs' Dictionary, and reports the benchmark time
func run_task(msgs:Dictionary[String, String], suppress:bool, f:Callable) -> Variant:
	if suppress: return f.call()

	var has_messages := not msgs.is_empty()
	if has_messages and msgs.start != "":
		task(msgs.start)

	var t1 := Time.get_ticks_msec()
	var res:Variant = f.call()
	var t2 := Time.get_ticks_msec()

	var time_str := "%.3f s" % [(t2-t1)/1000.0]

	if not msgs.is_empty():
		if not res is LoggerError or res.ok:
			task(msgs.end + "  (%s)" % [time_str])
		else:
			error(msgs.error + res.error, 1)

	return res
