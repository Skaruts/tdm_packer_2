class_name MapParser
extends Node



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#    Classes

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
# enum as dict because gdscript is too stupid to have string enums
const Scope : Dictionary[String, String] = {
	File     = "Scope.File",
	Entity   = "Scope.Entity",
	Property = "Scope.Property",
	Def      = "Scope.Def",
	BrushDef = "Scope.BrushDef",
	PatchDef = "Scope.PatchDef",
}


class Entity:
	var id         : int
	var classname  : String
	var name       : String
	var properties : Dictionary
	var brushes    : Array[Brush]
	var patches    : Array[Patch]
	var materials  : Set
	func _init(_id:int) -> void:
		id = _id
		materials = Set.new()


class Property:
	var name  : String
	var value : String
	func _init(_name:String, _value:String) -> void:
		name = _name
		value = _value


class Brush:
	var id        : int
	var materials : Set
	func _init(_id:int) -> void:
		id = _id
		materials = Set.new()


class Patch:
	var id       : int
	var material : String
	func _init(_id:int) -> void:
		id = _id


class Map:
	var entities : Array[Entity]



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#    Map Parser

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
var scope        := Scope.File

var maps         : Array[Map]
var entities     : Array[Entity]

var curr_map     : Map
var curr_ent     : Entity
var curr_brush   : Brush
var curr_patch   : Patch
var curr_prop    : String

var curr_primitive_id  := -1
var curr_entity_id     := -1

const _DEBUG_SHOW_SCOPES := false
const _DEBUG_PRINT_PROPS := false



func set_scope(new_scope:String) -> void:
	if _DEBUG_SHOW_SCOPES: print(">", new_scope)
	scope = new_scope


func is_scope(scp:String) -> bool:
	return scope == scp


# debug
func print_scope(prop_name:String, token:String) -> void:
	if not _DEBUG_SHOW_SCOPES: return
	print("    ", prop_name, token)


# debug
func print_prop(prop_name:String, value:String) -> void:
	if not _DEBUG_PRINT_PROPS: return
	print("       ", prop_name, value)


var level := 0
const _DEBUG_PRINT_TOKS := 0
func print_token(tok:String) -> void:
	if _DEBUG_PRINT_TOKS == 2:
		print(str(level) + "   ".repeat(level) + tok)
	elif _DEBUG_PRINT_TOKS == 1:
		print("   ".repeat(level) + tok)


func parse_token(token:String) -> void:

	match scope:
		Scope.Entity:
			#print_scope("Scope.Entity", token)
			if token.begins_with('"'):
				if _DEBUG_PRINT_TOKS: print_token(token)
				curr_prop = token.substr(1, -2)
				set_scope(Scope.Property)
			elif token == '{':
				if _DEBUG_PRINT_TOKS: print_token(token)
				level += 1
				set_scope(Scope.Def)
			elif token == '}':
				level -= 1
				# commit entity
				if _DEBUG_PRINT_TOKS: print_token(token)
				curr_map.entities.append(curr_ent)
				curr_ent = null
				#print_prop("----------------------", "")
				set_scope(Scope.File)

		Scope.Def:
			#print_scope("Scope.Def", token)
			if token.begins_with("brushDef"):
				if _DEBUG_PRINT_TOKS: print_token(token)
				level += 1
				curr_brush = Brush.new(curr_primitive_id)
				set_scope(Scope.BrushDef)
			elif token.begins_with("patchDef"):
				if _DEBUG_PRINT_TOKS: print_token(token)
				level += 1
				curr_patch = Patch.new(curr_primitive_id)
				set_scope(Scope.PatchDef)
			elif token == '}':
				level -= 1
				if _DEBUG_PRINT_TOKS: print_token(token)
				set_scope(Scope.Entity)

		Scope.Property:
			#print_scope("Scope.Property", token)
			if token.begins_with('"'):
				if _DEBUG_PRINT_TOKS: print_token(token)
				var val := token.substr(1, -2)
				if   curr_prop == "classname": curr_ent.classname = val
				elif curr_prop == "name":      curr_ent.name = val
				print_prop(curr_prop, val)
				curr_ent.properties[curr_prop] = val
				curr_prop = ""
				set_scope(Scope.Entity)

		Scope.BrushDef:
			if token.begins_with('"'):
				if _DEBUG_PRINT_TOKS: print_token(token)
				print_prop("brush texture: ", token)
				var mat := token.substr(1, -2)
				curr_brush.materials.add(mat)
				curr_ent.materials.add(mat)
			elif token == '}':
				level -= 1
				# commit brush
				#if _DEBUG_PRINT_TOKS: print_token(token)
				curr_ent.brushes.append(curr_brush)
				curr_brush = null
				set_scope(Scope.Def)

		Scope.PatchDef:
			if token.begins_with('"'):
				if _DEBUG_PRINT_TOKS: print_token(token)
				print_prop("patch texture: ", token)
				var mat := token.substr(1, -2)
				curr_patch.material = mat
				curr_ent.materials.add(mat)
			elif token == '}':
				# commit patch
				#if _DEBUG_PRINT_TOKS: print_token(token)
				curr_ent.patches.append(curr_patch)
				curr_patch = null
				level -= 1
				set_scope(Scope.Def)

		Scope.File:   # this branch is the most infrequent, keep it last
			#print_scope("Scope.File", token)
			assert(level == 0)
			if token == '{':
				if _DEBUG_PRINT_TOKS: print_token(token)
				curr_ent = Entity.new(curr_entity_id)
				entities.append(curr_ent)
				level += 1
				set_scope(Scope.Entity)

	assert(level >= 0)



#const _DEBUG_TOKENS := true

func parse(map_file:String) -> Map:
	curr_map = Map.new()
	maps.append(curr_map)

	logs.task("    '%s'..." % [ map_file.get_file() ])

	var t1 := Time.get_ticks_msec()
	var lines := Path.get_lines(map_file)
	#var lines := Path.read_file_string(map_file).split('\n', false)


	for line:String in lines:
		# line = line.replace('\t', '')
		var line_start := line[0]
		var tokens : Array[String]

		if line_start == '(':
			assert(scope in [Scope.PatchDef, Scope.BrushDef], line)
			# when it's brush or patch, skip the faces
			if "textures" in line:  # brush
				var qt1 := line.find('"')
				var qt2 := line.find('"', qt1+1)
				#tokens = [ line.substr(qt1, qt2-qt1+1) ]
				parse_token( line.substr(qt1, qt2-qt1+1) )
			else:                   # patch
				continue

		elif line_start == '"':
			assert(scope in [Scope.Entity, Scope.PatchDef], line)
			var qt2 := line.find('"', 1) +1
			#tokens = [ line.substr(0, qt2), line.substr(qt2+1) ]
			parse_token(line.substr(0, qt2))
			parse_token(line.substr(qt2+1))
		elif line_start != '/':
			#tokens = [ line ]
			parse_token(line)
		else:  # comments
			var parts : Array[String] = Array(Array(line.split(' ', false)), TYPE_STRING, "", null)
			if parts.size() > 2:
				var curr_id := parts[2].to_int()
				if parts[1] == "entity":
					assert(scope == Scope.File, line)
					curr_entity_id = curr_id
				elif parts[1] == "primitive":
					assert(scope == Scope.Entity, line)
					curr_primitive_id = curr_id
			continue

		#for t:String in tokens:
			#parse_token(t)

	var t2 := Time.get_ticks_msec()
	logs.info("Map parsed in %.1f secs" % [(t2-t1)/1000.0])

	assert(scope      == Scope.File)
	assert(curr_prop  == "")
	assert(curr_ent   == null)
	assert(curr_brush == null)
	assert(curr_patch == null)

	# add the materials under the "texture" properties
	# that weren't detected during parsing
	for e:Entity in curr_map.entities:
		if "texture" in e.properties:
			e.materials.add(e.properties.texture)

	return curr_map
