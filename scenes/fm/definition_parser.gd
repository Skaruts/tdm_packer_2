class_name DefinitionParser
extends RefCounted


enum Scope {
	FILE,
	DEF_PREFIX,

	DEF_NAME,
	ENTITY_DEF_NAME,
	ENTITY_DEF,

	# MODEL_DEF_NAME,
	# MODEL_DEF,
	# MODEL_DEF_INNER,
	DICT_SKIP_DEF_NAME,
	BOOL_SKIP_DEF_NAME,


	SKIP_DEF_NAME,
	SKIP_DEF,
	SKIP_DEF_INNER,
	PROP_VAL,
	MAX_ITEMS,
}


const _DEBUG_PRINT_SCOPES := false
const _PRINT_SYMBOLS := false
var scope_level : int

var idx            : int
var file_str       : String
var scope          : Scope
var token          : String
var curr_char      : String
var in_comment     : bool
var defs           : Dictionary
var curr_def       : Dictionary
var curr_def_type  : String
var curr_def_name  : String
var curr_prop_name : String


var scope_stack: Array[Scope]

func _push_scope(new_scope:Scope) -> void:
	assert(not in_comment)
	scope = new_scope
	scope_stack.push_back(new_scope)
	if _DEBUG_PRINT_SCOPES: print("Scope.", Scope.keys()[new_scope])

func _pop_scope() -> void:
	assert(not in_comment)
	scope_stack.pop_back()
	scope = scope_stack[-1]
	if _DEBUG_PRINT_SCOPES: print("Scope.", Scope.keys()[scope])


# func _set_scope(new_scope:Scope, level_inc:int) -> void:
# 	if in_comment: return
# 	scope = new_scope
# 	scope_level += level_inc
# 	if _DEBUG_PRINT_SCOPES: print("Scope.", Scope.keys()[scope])

enum AssetType {
	ENTITIES,
	# MODELS,
	MATERIALS,
	SKINS,
	PARTICLES,
	XDATA,
}
var _asset_type : AssetType

func parse(files:PackedStringArray, asset_type:AssetType) -> Dictionary:
	var defs_by_file: Dictionary
	_asset_type = asset_type

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
		scope_stack.clear()
		_push_scope(Scope.FILE)

		while idx < file_str.length():
			var next_char := file_str[idx+1] if idx+1 < file_str.length() else ''
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
				if identifier == "":
					logs.error("error parsing definition type")
					return false

				curr_def_type = identifier

				match _asset_type:
					AssetType.ENTITIES:
						if   identifier == "entityDef": _push_scope(Scope.ENTITY_DEF_NAME)
						elif identifier == "model":     _push_scope(Scope.SKIP_DEF_NAME)
						else:                           _push_scope(Scope.DICT_SKIP_DEF_NAME)
					# AssetType.MODELS:
						# _push_scope(Scope.UNKNOWN_DEF_NAME)
					AssetType.MATERIALS: _push_scope(Scope.BOOL_SKIP_DEF_NAME)
					AssetType.SKINS:     _push_scope(Scope.BOOL_SKIP_DEF_NAME)
					AssetType.PARTICLES: _push_scope(Scope.BOOL_SKIP_DEF_NAME)
					AssetType.XDATA:     _push_scope(Scope.BOOL_SKIP_DEF_NAME)

		Scope.DICT_SKIP_DEF_NAME:
			if not curr_char in [' ', '{' ,'\n', '\t']:
				curr_def_name = _parse_identifier()
				if curr_def_name != "":
					if _PRINT_SYMBOLS: print("%s %s" % [curr_def_type, curr_def_name])
					curr_def = {}
					defs[curr_def_name] = curr_def

			if curr_char == '{':
				if curr_def_name == "":
					if _PRINT_SYMBOLS: print("%s" % [curr_def_type])
					curr_def = {}
					defs[curr_def_name] = curr_def
				_pop_scope()
				if _PRINT_SYMBOLS: print("{")
				_push_scope(Scope.SKIP_DEF)
				curr_def_name = ""
				curr_def_type = ""

		Scope.BOOL_SKIP_DEF_NAME:
			if not curr_char in [' ', '{' ,'\n', '\t']:
				curr_def_name = ""
				curr_def_name = _parse_identifier()
				if curr_def_name != "":
					if _PRINT_SYMBOLS: print("%s %s" % [curr_def_type, curr_def_name])
					defs[curr_def_type] = true

			if curr_char == '{':
				if curr_def_name == "":
					if _PRINT_SYMBOLS: print("%s" % [curr_def_type])
					defs[curr_def_type] = true
				_pop_scope()
				if _PRINT_SYMBOLS:
					print("{")
				_push_scope(Scope.SKIP_DEF)
				curr_def_name = ""
				curr_def_type = ""

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
				_pop_scope()
				if _PRINT_SYMBOLS: print("{")
				_push_scope(Scope.ENTITY_DEF)
				curr_def_name = ""
				curr_def_type = ""

		Scope.ENTITY_DEF:
			if curr_char == '"':
				curr_prop_name = _parse_string()
				if curr_prop_name == "":
					logs.error("error parsing property name")
					return false
				if curr_prop_name == "model":
					_push_scope(Scope.PROP_VAL)
				else:
					idx = file_str.find('\n', idx)+1
			elif curr_char == '}':
				if _PRINT_SYMBOLS: print('}')
				_pop_scope()

		Scope.PROP_VAL:
			if curr_char == '"':
				var prop_val := _parse_string()
				if prop_val == "":
					logs.error("error parsing property value")
					return false

				if _PRINT_SYMBOLS: print('    "%s" "%s"' % [curr_prop_name, prop_val])
				curr_def[curr_prop_name] = prop_val
				_pop_scope()

		# unknown definitions are set here so they're skipped as much as possible
		Scope.SKIP_DEF_NAME:
			if not _PRINT_SYMBOLS:
				if curr_char == '{':
					_pop_scope()
					_push_scope(Scope.SKIP_DEF)
			else:
				if not curr_char in [' ', '{' ,'\n', '\t']:
					curr_def_name = _parse_identifier()
					if curr_def_name != "":
						if _PRINT_SYMBOLS: print("%s %s (skipped)" % [curr_def_type, curr_def_name])

				if curr_char == '{':
					if curr_def_name == "":
						if _PRINT_SYMBOLS: print("%s" % [curr_def_type])
					_pop_scope()
					if _PRINT_SYMBOLS: print("{")
					_push_scope(Scope.SKIP_DEF)
					curr_def_name = ""
					curr_def_type = ""

		Scope.SKIP_DEF:
			if curr_char == '{':
				_push_scope(Scope.SKIP_DEF_INNER)
			elif curr_char == '}':
				if _PRINT_SYMBOLS: print('}')
				_pop_scope()

		Scope.SKIP_DEF_INNER:
			if curr_char == '}':
				_pop_scope()

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
