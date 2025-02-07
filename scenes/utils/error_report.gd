class_name ErrorReport
extends RefCounted


var ok:bool
var error:String


func _init(_ok:bool, err_msg:Variant=null) -> void:
	ok = _ok
	if err_msg:
		error = err_msg as String
