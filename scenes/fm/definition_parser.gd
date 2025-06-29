class_name DefinitionParser
extends RefCounted

# enum as dict, so it's a string enum
const Scope : Dictionary[String, String] = {
	FILE              = "Scope.FILE",
	DEF_PREFIX        = "Scope.DEF_PREFIX",
	DEF_NAME          = "Scope.DEF_NAME",
	ENTITY_DEF_NAME   = "Scope.ENTITY_DEF_NAME",
	ENTITY_DEF        = "Scope.ENTITY_DEF",
	MODEL_DEF_NAME    = "Scope.MODEL_DEF_NAME",
	MODEL_DEF         = "Scope.MODEL_DEF",
	MODEL_DEF_INNER   = "Scope.MODEL_DEF_INNER",
	UNKNOWN_DEF_NAME  = "Scope.UNKNOWN_DEF_NAME",
	UNKNOWN_DEF       = "Scope.UNKNOWN_DEF",
	UNKNOWN_DEF_INNER = "Scope.UNKNOWN_DEF_INNER",
	PROP_VAL          = "Scope.PROP_VAL",
}

const _DEBUG_PRINT_SCOPES := false
const _PRINT_SYMBOLS := false
var scope_level : int

var idx            : int
var file_str       : String
var scope          : String
var token          : String
var curr_char      : String
var in_comment     : bool
var defs           : Dictionary
var curr_def       : Dictionary
var curr_def_type  : String
var curr_def_name  : String
var curr_prop_name : String



func _set_scope(new_scope:String, level_inc:int) -> void:
	if in_comment: return
	scope = new_scope
	scope_level += level_inc
	if _DEBUG_PRINT_SCOPES: print(scope)


func parse(files:PackedStringArray) -> Dictionary:
	var defs_by_file: Dictionary

	for path:String in files:
		file_str = Path.read_file_string_nl(path)
		if file_str == "":
			logs.error("couldn't read file '%s'" % path)
			continue

		idx            = 0
		curr_char      = ""
		in_comment     = false
		curr_def       = {}
		curr_prop_name = ""

		defs = {}
		defs_by_file[path] = defs

		idx = 0
		_set_scope(Scope.FILE, 0)

		while idx < file_str.length()-1:
			var next_char := file_str[idx+1]
			curr_char = file_str[idx]
			idx   += 1

			if curr_char == '/' and next_char == '/':
				if not in_comment:
					idx = file_str.find('\n', idx)+1

			elif curr_char == '/' and next_char == '*':
				in_comment = true
				idx = file_str.find('*/', idx)
				if idx == -1:
					logs.error("error parsing file '%s'" % path)
					continue

			elif curr_char == '*' and next_char == '/':
				in_comment = false
				idx += 1

			else:
				assert(not in_comment, "%s | %s" % [curr_char, next_char])
				if not _parse_entity_def_token():
					continue

	return defs_by_file


func _parse_entity_def_token() -> bool:
	match scope:
		Scope.FILE:
			if not curr_char in [' ', '\t', '\n', '{', '}']:
				var identifier := _parse_identifier()

				# if _PRINT_SYMBOLS: print(curr_def_type)
				if identifier == "":
					logs.error("error parsing definition type")
					return false

				if identifier == "entityDef":
					curr_def_type = identifier
					_set_scope(Scope.ENTITY_DEF_NAME, 0)
				else:
					curr_def_type = identifier
					if _PRINT_SYMBOLS: print("%s (unknown)" % [identifier])
					_set_scope(Scope.UNKNOWN_DEF_NAME, 0)

		Scope.ENTITY_DEF_NAME:
			if not curr_char in [' ', '{' ,'\n', '\t']:
				curr_def_name = _parse_identifier()
				if curr_def_name != "":
					if _PRINT_SYMBOLS: print("%s %s" % [curr_def_type, curr_def_name])
					curr_def = {}
					defs[curr_def_name] = curr_def
				else:
					logs.error("error parsing definition name")
					return false

			if curr_char == '{':
				if _PRINT_SYMBOLS: print("{")
				_set_scope(Scope.ENTITY_DEF, 1)

		Scope.ENTITY_DEF:
			if curr_char == '"':
				curr_prop_name = _parse_string()
				if curr_prop_name == "":
					logs.error("error parsing property name")
					return false
				if curr_prop_name == "model":
					#if _PRINT_SYMBOLS: print(curr_prop_name)
					_set_scope(Scope.PROP_VAL, 0)
				else:
					idx = file_str.find('\n', idx)+1
			elif curr_char == '}':
				if _PRINT_SYMBOLS: print('}')
				_set_scope(Scope.FILE, -1)

		Scope.PROP_VAL:
			if curr_char == '"':
				var prop_val := _parse_string()
				if prop_val == "":
					logs.error("error parsing property value")
					return false

				if _PRINT_SYMBOLS: print('    "%s" "%s"' % [curr_prop_name, prop_val])
				curr_def[curr_prop_name] = prop_val
				_set_scope(Scope.ENTITY_DEF, -1)

		# unknown definitions are skipped, as much as possible
		Scope.UNKNOWN_DEF_NAME:
			if not _PRINT_SYMBOLS:
				if curr_char == '{':
					_set_scope(Scope.UNKNOWN_DEF, 1)
			else:
				if not curr_char in [' ', '{' ,'\n', '\t']:
					curr_def_name = _parse_identifier()
					if curr_def_name != "":
						if _PRINT_SYMBOLS: print("%s %s" % [curr_def_type, curr_def_name])
						curr_def = {}
						defs[curr_def_name] = curr_def
					else:
						logs.error("error parsing definition name")
						return false

				if curr_char == '{':
					if _PRINT_SYMBOLS: print("{")
					_set_scope(Scope.UNKNOWN_DEF, 1)

		Scope.UNKNOWN_DEF:
			if curr_char == '{':
				_set_scope(Scope.UNKNOWN_DEF_INNER, 1)
			elif curr_char == '}':
				if _PRINT_SYMBOLS: print('}')
				_set_scope(Scope.FILE, -1)

		Scope.UNKNOWN_DEF_INNER:
			if curr_char == '}':
				_set_scope(Scope.UNKNOWN_DEF, -1)

	return true


func _parse_string() -> String:
	var result := ""
	idx -= 1
	while true:
		idx += 1
		if idx >= file_str.length(): break
		var chr := file_str[idx]
		if chr == '\n': return ""
		if chr == '"':
			idx += 1
			break
		result += chr
	# logs.print("string:  '%s'" % result)
	return result


func _parse_identifier() -> String:
	var result := ""
	idx -= 1
	while true:
		if idx >= file_str.length(): break
		var chr := file_str[idx]
		if chr in [' ', '\t', '\n', '{']:
			if chr != '{':
				idx += 1
			break
		result += chr
		idx += 1
	# logs.print("identifier:  '%s'" % result)
	return result
