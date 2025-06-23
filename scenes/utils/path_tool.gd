class_name Path extends Object

# version 12

# just trying to unify the default API because it's a bit confusing
# and inconsistent, imo.
# All paths are expected to be absolute.
# Use 'Path.to_global()' to convert "res://..." paths into global paths




const _ERROR_STRINGS = [
		"OK", "Generic error.", "Unavailable", "Unconfigured", "Unauthorized",
		"Parameter range", "Out of memory (OOM)", "File: Not found", "File: Bad drive",
		"File: Bad path", "File: No permission error.", "File: Already in use error.",
		"File: Can't open error.", "File: Can't write error.", "File: Can't read error.",
		"File: Unrecognized error.", "File: Corrupt error.", "File: Missing dependencies error.",
		"File: End of file (EOF) error.", "Can't open error.", "Can't create error.",
		"Query failed error.", "Already in use error.", "Locked error.", "Timeout error.",
		"Can't connect error.", "Can't resolve error.", "Connection error.",
		"Can't acquire resource error.", "Can't fork process error.",
		"Invalid core error.", "Invalid parameter error.", "Already exists error.",
		"Does not exist error.", "Database: Read error.", "Database: Write error.",
		"Compilation failed error.", "Method not found error.", "Linking failed error.",
		"Script failed error.", "Cycling link (import cycle) error.", "Invalid declaration error.",
		"Duplicate symbol error.", "Parse error.", "Busy error.", "Skip error.",
		"Help error. Used internally when passing --version or --help as executable options.",
		"Bug error, caused by an implementation issue in the method.",
		"Printer on fire error (This is an easter egg, no built-in methods return this error code).",
]



static func get_error_text(err:int) -> String:
	# see @GlobalScope.Error enum
	return _ERROR_STRINGS[err]

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Execution

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
class ExecutionResults:
	var output:Array
	var error:int

# https://www.youtube.com/watch?v=765bzFrqIgM
static func execute(app_path:String, args:Array) -> ExecutionResults:
	logs.print("executing: ", app_path, ", ", args)
	var res := ExecutionResults.new()
	res.output = []
	res.error = OS.execute(app_path, args, res.output, false, true)

#	logs.print("executing: ", app_path, ", ", args)
#	logs.print("error: ", error, " | ", output)

	return res





static func to_global(local_path:String) -> String:
	return ProjectSettings.globalize_path(local_path)


static func get_cwd() -> String:
	return ProjectSettings.globalize_path("res://")


static func join(s1:String, s2:String) -> String:
	return s1.path_join(s2)




static func dir_exists(path:String) -> bool:
	return DirAccess.dir_exists_absolute(path)


static func file_exists(path:String) -> bool:
	return FileAccess.file_exists(path)


static func exists(path:String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path)




static func make_dir(path:String) -> int: # returns Error enum
	return DirAccess.make_dir_absolute(path)


static func make_dir_recursive(path:String) -> int: # returns Error enum
	return DirAccess.make_dir_recursive_absolute(path)


static func rename(from:String, to:String) -> void:
	DirAccess.rename_absolute(from, to)


static func get_modified_time(filepath:String) -> int:
	return FileAccess.get_modified_time(filepath)




static func read_file_bytes(path:String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path)


static func read_file_string(path:String) -> String:
	return FileAccess.get_file_as_string(path)


static func get_lines(path:String) -> Array[String]:
	var file := FileAccess.open(path, FileAccess.READ)
	var lines: Array[String]
	var length := file.get_length()
	while file.get_position() < length:
		lines.append(file.get_line())

	return lines


static func write_file(path:String, content:String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		logs.error("Path.write_file: %s at '%s'" % [get_error_text(FileAccess.get_open_error()), path])
		return
	file.store_string(content)
	file.close()


static func write_bytes_encrypted_with_pass(bytes:PackedByteArray, filename:String, password:String) -> void:
	var file := FileAccess.open_encrypted_with_pass(filename, FileAccess.WRITE, password)
	if not file:
		logs.error( FileAccess.get_open_error() )
		return
	file.store_buffer(bytes)
	file.close()


#static func open_path(path:String) -> DirAccess:
	#var da := DirAccess.open(path)
	#if not da: logs.error("Invalid path: '%s'" % [path])
	#return da

#static func close_path(da:DirAccess) -> void:
	## TODO



static func copy_file(src:String, dest:String) -> void:
	DirAccess.copy_absolute(src, dest)

static func move_file(src:String, dest:String) -> void:
	DirAccess.copy_absolute(src, dest)
	DirAccess.remove_absolute(src)



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Directories

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func get_dirnames(path:String) -> Array[String]:
	return Array( DirAccess.get_directories_at(path) as Array, TYPE_STRING, "", null)
	#return DirAccess.get_directories_at(path) as Array[String]


static func get_dirnames_filtered(path:String, filter:Callable) -> Array[String]:
	var dirs := get_dirnames(path)
	return dirs.filter(filter)


#static func get_dirnames_recursive(path:String) -> Array[String]:
	#assert(false, "NIY")  # TODO
	#return []
#
#
#static func get_dirnames_recursive_filtered(path:String, filter:Callable) -> Array[String]:
	#assert(false, "NIY")  # TODO
	#return []




static func get_dirpaths(path:String) -> Array[String]:
	var dirs := get_dirnames(path)

	for i in dirs.size():
		dirs[i] = Path.join(path, dirs[i])

	return dirs


static func get_dirpaths_filtered(path:String, filter:Callable) -> Array[String]:
	var dirs := get_dirpaths(path)
	return dirs.filter(filter)


static func get_dirpaths_recursive(root:String) -> Array[String]:
	var dirs := get_dirpaths(root)

	for dir:String in dirs:
		dirs += get_dirpaths_recursive(dir)

	return dirs


#static func get_dirpaths_recursive_filtered(path:String, filter:Callable) -> Array[String]:
	#assert(false, "NIY")  # TODO
	#return []


static func delete_dir(path:String) -> int:
	var error := DirAccess.remove_absolute(path)
	return error

static func delete_file(path:String) -> int:
	var error := DirAccess.remove_absolute(path)
	return error



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Files

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func get_filenames(path:String, _valid_extensions:Array = []) -> Array[String]:
	return Array( DirAccess.get_files_at(path) as Array, TYPE_STRING, "", null)


static func get_filenames_filtered(path:String, filter:Callable) -> Array[String]:
	var files:Array[String] = Array( DirAccess.get_files_at(path) as Array, TYPE_STRING, "", null)
	return files.filter(filter)


static func get_filenames_recursive(path:String) -> Array[String]:
	var dirs:Array[String] = get_dirnames(path)
	var files:Array[String] = get_filenames(path)

	for dir in dirs:
		files += get_filenames_recursive(Path.join(path, dir))

	return files


static func get_filenames_recursive_filtered(path:String, filter:Callable) -> Array[String]:
	var dirs:Array[String] = get_dirnames(path)
	var files:Array[String] = get_filenames_filtered(path, filter)

	for dir in dirs:
		files += get_filenames_recursive_filtered(Path.join(path, dir), filter)

	return files




static func get_filepaths(root:String) -> Array[String]:
	var files:Array[String] = Array( DirAccess.get_files_at(root) as Array, TYPE_STRING, "", null)
	for i in files.size():
		files[i] = Path.join(root, files[i])

	return files


static func get_filepaths_filtered(root:String, filter:Callable) -> Array[String]:
	var files := get_filepaths(root)
	files = files.filter(filter)
	return files


static func get_filepaths_recursive(path:String) -> Array[String]:
	var dirs:Array[String] = get_dirpaths(path)
	var files:Array[String] = get_filepaths(path)

	for dir in dirs:
		files += get_filepaths_recursive(dir)

	return files


static func get_filepaths_recursive_filtered(path:String, filter:Callable) -> Array[String]:
	var dirs:Array[String] = get_dirpaths(path)
	var files:Array[String] = get_filepaths_filtered(path, filter)

	for dir in dirs:
		files += get_filepaths_recursive_filtered(dir, filter)

	return files





#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Serialization

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func json_parse(path:String) -> Variant: # don't specify return type
	var json := JSON.new()
	var json_string := read_file_string(path)

	if json.parse(json_string) == OK:
		return json.data

	logs.error("JSON Parse Error at line %s: %s\nIn file: %s" % [json.get_error_line(), json.get_error_message(), path])

	return null


static func parse_json_string(string:String) -> Variant: # String
	var json := JSON.new()

	if json.parse(string) == OK:
		return json.data

	logs.error("JSON Parse Error at line %s: %s" % [json.get_error_line(), json.get_error_message()])

	return null


static func load_json_lines(path:String) -> Array[String]:
	var file := FileAccess.open(path, FileAccess.READ)
	var lines := []
	var length := file.get_length()
	while file.get_position() < length:
		var line := file.get_line()
		lines.append(parse_json_string(line))
#		lines.append(JSON.parse_string(line))

#	for l in lines:
#		logs.printt("line", l)
	return lines


static func load_csv_file(path:String) -> Array[String]:
	var file := FileAccess.open(path, FileAccess.READ)
	var lines := []
	var length := file.get_length()
	while file.get_position() < length:
		lines.append(file.get_csv_line())

#	for l in lines:
#		logs.print(l)
	return lines




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Hashing

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
static func get_md5(filepath:String) -> String:
	if not FileAccess.file_exists(filepath): return ""
	return FileAccess.get_md5(filepath)


static func get_sha256(filepath:String) -> String:
	if not FileAccess.file_exists(filepath): return ""
	return FileAccess.get_sha256(filepath)
