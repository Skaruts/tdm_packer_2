class_name Mission
extends RefCounted


var file_tree:FMTreeNode
var filepaths: Array[String]
var full_filelist: Array[String]  # used to check for external changes
var file_hashes:Dictionary
var file_count:int
var dir_count:int

var ignored_directories:Set
var ignored_files:Set

class _MissionPaths: # this allows auto-completion and strict typing, unlike dictionaries
	var root        : String
	var test_root   : String  # root dir of TDM copy for testing pk4s
	var fm_test     : String

	var maps        : String
	var defs        : String
	var guis        : String
	var materials   : String
	var particles   : String
	var skins       : String
	var xdata       : String
	var scripts     : String

	var modfile     : String
	var readme      : String
	var pkignore    : String
	var startingmap : String
	var mapsequence : String

class _MissionFiles:
	var pkignore : String
	var modfile  : String
	var readme   : String

var paths : _MissionPaths
var files : _MissionFiles


var map_sequence: Array[String]

var id      : String
var zipname : String



enum DirtyFlags {
	PKIGNORE    = 1 << 0,
	MODFILE     = 1 << 1,
	MAPS        = 1 << 2,
	README      = 1 << 3,
	#FILES       = 1 << 4,
}
var dirty := 0



func _init() -> void:
	paths = _MissionPaths.new()
	files = _MissionFiles.new()


func set_id(_id:String) -> void:
	id = _id
	zipname = id + ".pk4"


func store_hash(filepath:String) -> void:
	file_hashes[filepath] = FMUtils.get_file_hash(filepath)


func remove_hash(filepath:String) -> void:
	if filepath in file_hashes:
		file_hashes.erase(filepath)


func set_dirty_flag(file_dirty:bool, flag:DirtyFlags, silent:=false) -> void:
	var old_dirty := dirty
	if file_dirty: dirty |= flag
	else:          dirty &= ~flag

	if old_dirty != dirty and not silent:
		gui.missions_list.update_current_mission_title()



func get_dirty_flag(flag:DirtyFlags) -> bool:
	return dirty & flag != 0


func update_pkignore(text:String, file_dirty:=true, silent:=false) -> void:
	files.pkignore = text
	set_dirty_flag(file_dirty, DirtyFlags.PKIGNORE, silent)

func update_modfile(text:String, file_dirty:=true, silent:=false) -> void:
	files.modfile = text
	set_dirty_flag(file_dirty, DirtyFlags.MODFILE, silent)

func update_readme(text:String, file_dirty:=true, silent:=false) -> void:
	files.readme = text
	set_dirty_flag(file_dirty, DirtyFlags.README, silent)



func add_map(name:String, silent:=false) -> bool:
	if name in map_sequence: return false
	map_sequence.append(name)
	return true

func remove_map(name:String, silent:=false) -> bool:
	assert(name in map_sequence)
	map_sequence.erase(name)
	return true





func set_paths(path:String) -> void:
	paths.root      = path
	if data.config.tdm_copy_path != "":
		paths.test_root = Path.join(Path.join(data.config.tdm_copy_path.get_base_dir(), "fms"), id)

	paths.maps      = Path.join(path, "maps")
	paths.defs      = Path.join(path, "defs")
	paths.guis      = Path.join(path, "guis")
	paths.materials = Path.join(path, "materials")
	paths.particles = Path.join(path, "particles")
	paths.skins     = Path.join(path, "skins")
	paths.xdata     = Path.join(path, "xdata")
	paths.scripts   = Path.join(path, "scripts")

	paths.modfile   = Path.join(path, data.MODFILE_FILENAME)
	paths.readme    = Path.join(path, data.README_FILENAME)
	paths.pkignore  = Path.join(path, data.IGNORES_FILENAME)
	paths.startingmap = Path.join(path, data.STARTINGMAP_FILENAME)
	paths.mapsequence = Path.join(path, data.MAPSEQUENCE_FILENAME)
