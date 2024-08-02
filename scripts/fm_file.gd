class_name FMFile
extends RefCounted


var text:String
var filepath:String
var filename:String


func _to_string() -> String:
	return "FMFile(%s)" % filename
