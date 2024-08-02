extends Node
# autoloaded script

"""
	A little hacky interface to the console node,
	so it can be used from anywhere
"""


# the console registers itself
#    > main.tscn > %console_label
var _console_node: TabContainer

const __NULL = "__non-null_null__"



func print( arg0:Variant=__NULL, arg1:Variant=__NULL, arg2:Variant=__NULL, arg3:Variant=__NULL, arg4:Variant=__NULL, arg5:Variant=__NULL, arg6:Variant=__NULL, arg7:Variant=__NULL, arg8:Variant=__NULL, arg9:Variant=__NULL, arg10:Variant=__NULL, arg11:Variant=__NULL, arg12:Variant=__NULL, arg13:Variant=__NULL, arg14:Variant=__NULL, arg15:Variant=__NULL, arg16:Variant=__NULL, arg17:Variant=__NULL, arg18:Variant=__NULL, arg19:Variant=__NULL) -> void:
	_console_node.print(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19)
	logs.print(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19)


func error(msg:String) -> void:
	_console_node.error(msg)
	logs.error(msg)


func warning(msg:String) -> void:
	_console_node.warning(msg)
	logs.warning(msg)


func info(msg:String) -> void:
	_console_node.info(msg)
	logs.info(msg)


func reminder(msg:String) -> void:
	_console_node.reminder(msg)
	logs.reminder(msg)


func task(msg:String) -> void:
	_console_node.task(msg)
	logs.task(msg)
