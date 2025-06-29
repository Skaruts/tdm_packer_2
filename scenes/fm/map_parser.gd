class_name MapParser
extends RefCounted



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#    Classes

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
# enum as dict, so it's a string enum
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

	var materials  := Set.new()
	var models     := Set.new()
	var particles  := Set.new()
	var skins      := Set.new()
	var xdata      := Set.new()

	func _init(_id:int) -> void:
		id = _id


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

	var brushes    : Array[Brush]
	var patches    : Array[Patch]

	var materials  := Set.new()
	var models     := Set.new()
	var particles  := Set.new()
	var skins      := Set.new()
	var xdata      := Set.new()


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#    Map Parser

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
var maps         : Dictionary[String, Map]

var scope        := Scope.File
var curr_map     : Map
var curr_ent     : Entity
var curr_brush   : Brush
var curr_patch   : Patch
var curr_prop    : String

var curr_primitive_id  := -1
var curr_entity_id     := -1

const _DEBUG_SHOW_SCOPES := false
const _DEBUG_PRINT_PROPS := false
const _DEBUG_PRINT_TOKS := 0
var level := 0


func get_all_entities() -> Array[Entity]:
	var all_entities :Array[Entity]
	for map:Map in maps.values():
		all_entities.append_array(map.entities)
	return all_entities





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



func print_token(tok:String) -> void:
	if _DEBUG_PRINT_TOKS == 2:
		print(str(level) + "   ".repeat(level) + tok)
	elif _DEBUG_PRINT_TOKS == 1:
		print("   ".repeat(level) + tok)

func add_asset(type:String, asset:Variant) -> void:
	match  type:
		"brush":
			curr_ent.brushes.append(asset)
			curr_map.brushes.append(asset)
		"patch":
			curr_ent.patches.append(asset)
			curr_map.patches.append(asset)
		"material":
			curr_ent.materials.add(asset)
			curr_map.materials.add(asset)
		"model":
			curr_ent.models.add(asset)
			curr_map.models.add(asset)
		"particle":
			curr_ent.particles.add(asset)
			curr_map.particles.add(asset)
		"skin":
			curr_ent.skins.add(asset)
			curr_map.skins.add(asset)
		"xdata":
			curr_ent.xdata.add(asset)
			curr_map.xdata.add(asset)



func parse_token(token:String) -> void:
	match scope:
		Scope.Entity:
			#print_scope("Scope.Entity", token)
			if token.begins_with('"'):
				if _DEBUG_PRINT_TOKS: print_token(token)
				curr_prop = token.get_slice('"', 1)
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
				set_scope(Scope.File)

		Scope.Property:
			#print_scope("Scope.Property", token)
			if token.begins_with('"'):
				if _DEBUG_PRINT_TOKS: print_token(token)
				var val := token.get_slice('"', 1)
				if   curr_prop == "classname":      curr_ent.classname = val
				elif curr_prop == "name":           curr_ent.name = val
				elif curr_prop == "skin":           add_asset("skin", val)
				elif curr_prop == "xdata_contents": add_asset("xdata", val)
				elif curr_prop == "model":
					if not val.ends_with(".prt"):
						if not curr_ent.classname == "func_static" \
						or curr_ent.name != val:
							add_asset("model", val)
					else:
						add_asset("particle", val)

				print_prop(curr_prop, val)
				curr_ent.properties[curr_prop] = val
				curr_prop = ""
				set_scope(Scope.Entity)

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

		Scope.BrushDef:
			if token.begins_with('"'):
				if _DEBUG_PRINT_TOKS: print_token(token)
				print_prop("brush texture: ", token)
				var mat := token.get_slice('"', 1)
				curr_brush.materials.add(mat)
				add_asset("material", mat)
			elif token == '}':
				level -= 1
				# commit brush
				#if _DEBUG_PRINT_TOKS: print_token(token)
				add_asset("brush", curr_brush)
				curr_brush = null
				set_scope(Scope.Def)

		Scope.PatchDef:
			if token.begins_with('"'):
				if _DEBUG_PRINT_TOKS: print_token(token)
				print_prop("patch texture: ", token)
				var mat := token.get_slice('"', 1)
				assert(mat != "")
				#if curr_entity_id < 50:
					#logs.print("mat - ", mat)
				curr_patch.material = mat
				add_asset("material", mat)
			elif token == '}':
				# commit patch
				#if _DEBUG_PRINT_TOKS: print_token(token)
				curr_ent.patches.append(curr_patch)
				add_asset("patch", curr_patch)
				curr_patch = null
				level -= 1
				set_scope(Scope.Def)

		Scope.File:   # this branch is the most infrequent, keep it last
			#print_scope("Scope.File", token)
			#assert(level == 0)
			if token == '{':
				if _DEBUG_PRINT_TOKS: print_token(token)
				curr_ent = Entity.new(curr_entity_id)
				level += 1
				set_scope(Scope.Entity)

	#assert(level >= 0)



func parse(rep_panel:ReportPanel, map_file:String, map_filename:String) -> Map:
	rep_panel.call_thread_safe("task", "Parsing '%s'..." % [ map_file.get_file() ])
	rep_panel.call_thread_safe("set_percentage", 0)

	scope             = Scope.File
	curr_map          = null
	curr_ent          = null
	curr_brush        = null
	curr_patch        = null
	curr_prop         = ""
	curr_entity_id    = -1
	curr_primitive_id = -1
	level             = 0
	# var max_level := 0

	# if 'level' ever goes over this, then probably something went wrong
	const _MAX_LEVEL := 3

	var map := Map.new()
	curr_map = map

	var t1 := Time.get_ticks_msec()

	var lines := Path.get_lines_safe(map_file)

	if lines.size() == 0:
		rep_panel.call_thread_safe("error", "Coudln't load map %s" % map_file.get_file())
		return null

	var num_lines: float = lines.size()
	for i:float in num_lines:
		var line:String = lines[i]

		if line == "": continue
		if level < 0 or level > _MAX_LEVEL: break

		rep_panel.call_thread_safe("set_percentage", i/num_lines)

		var line_start := line[0]
		#logs.print(line)
		if line_start == '(':
			assert(scope in [Scope.PatchDef, Scope.BrushDef], line)
			# when it's brush or patch, skip the faces
			if "textures" in line:  # brush
				parse_token( '"%s"' % line.get_slice('"', 1) )
			else:                       # patch
				continue

		elif line_start == '"':
			assert(scope in [Scope.Entity, Scope.PatchDef], line)
			if scope == Scope.Entity:
				var parts := line.split('"', false)
				parse_token('"%s"' % parts[0])
				parse_token('"%s"' % parts[2])
			else:
				parse_token('"%s"' % line.get_slice('"', 1))

		elif line_start != '/':
			parse_token(line)

		else:  # comments
			var parts := line.split(' ', false)
			if parts.size() < 3: continue

			var curr_id := parts[2].to_int()
			if parts[1] == "entity":
				assert(scope == Scope.File, line)
				curr_entity_id = curr_id
			elif parts[1] == "primitive":
				assert(scope == Scope.Entity, line)
				curr_primitive_id = curr_id

		# if level > max_level:
		# 	max_level = level

		if level > _MAX_LEVEL:
			break



	curr_map = null
	var t2 := Time.get_ticks_msec()

	if scope != Scope.File or level != 0:
		rep_panel.call_thread_safe("error", "Failed to load map %s" % map_file.get_file())
		return null

	maps[map_filename] = map

	logs.info("Map parsed in %.1f secs" % [(t2-t1)/1000.0])

	## add the materials under the "texture" properties
	## that weren't detected during parsing
	#for e:Entity in map.entities:
		#if "texture" in e.properties:
			#e.materials.add(e.properties.texture)

	# logs.print("max_level", max_level)

	return map
