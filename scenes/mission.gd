class_name Mission
extends RefCounted


var file_tree:FMTreeNode
var filepaths: Array[String]
var full_filelist: Array[String]  # used to check for external changes
var file_hashes:Dictionary

var inc_file_count:int
var inc_dir_count:int
var exc_file_count:int
var exc_dir_count:int

var ignored_directories:Set
var ignored_files:Set

class MissionPaths: # this allows auto-completion and strict typing, unlike dictionaries
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


class MissionData extends RefCounted:
	# modfile
	var title       : String
	var description : String
	var author      : String
	var version     : String
	var tdm_version : String
	var map_titles  : Array[String]
	# other
	var pkignore    : String
	var readme      : String
	var map_files   : Array[String]


var paths := MissionPaths.new()
var mdata := MissionData.new()


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



#func _init(_id:String) -> void:
	#id = _id
	#zipname = id + data.config.packname_suffix + ".pk4"
func update_zipname() -> bool:
	var old_zip_name := zipname
	var cfg_suffix:String = data.config.packname_suffix
	var suffix := ""
	if cfg_suffix.contains(data.TOK_VERSION):
		suffix = cfg_suffix.replace(data.TOK_VERSION, mdata.version).replace(' ', '_')
	zipname = id + suffix + ".pk4"
	return old_zip_name != zipname

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Maps

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

func _swap_array_items(array:Array, idx1:int, idx2:int) -> void:
	var item1 : Variant = array[idx1]
	var item2 : Variant = array[idx2]
	array[idx1] = item2
	array[idx2] = item1


func move_map(direction:String, idx:int, silent:=false) -> bool:
	var moved := false
	if direction == "move_up":
		if idx > 0:
			_swap_array_items(mdata.map_files, idx, idx-1)
			_swap_array_items(mdata.map_titles, idx, idx-1)
			moved = true
	elif direction == "move_down":
		if idx < mdata.map_files.size()-1:
			_swap_array_items(mdata.map_files,  idx, idx+1)
			_swap_array_items(mdata.map_titles, idx, idx+1)
			moved = true
	if moved:
		set_dirty_flag(true, DirtyFlags.MAPS, silent)
		set_dirty_flag(true, DirtyFlags.MODFILE, silent)
	return moved

func add_map_file(string:String, silent:=false) -> bool:
	if string in mdata.map_files: return false
	mdata.map_files.append(string)
	mdata.map_titles.append("")
	set_dirty_flag(true, DirtyFlags.MAPS, silent)
	logs.print(mdata.map_files)
	return true


func remove_map_file(string:String, silent:=false) -> bool:
	assert(string in mdata.map_files)
	var idx := mdata.map_files.find(string)
	mdata.map_files.erase(string)
	mdata.map_titles.remove_at(idx)
	set_dirty_flag(true, DirtyFlags.MAPS, silent)
	set_dirty_flag(true, DirtyFlags.MODFILE, silent)
	return true


func set_map_title(idx:int, string:String, silent:=false) -> bool:
	if mdata.map_titles[idx] == string: return false
	mdata.map_titles[idx] = string
	set_dirty_flag(true, DirtyFlags.MODFILE, silent)
	return true


#func remove_map_title(string:String) -> bool:
	#assert(string in mdata.map_titles)
	#mdata.map_titles.erase(string)
	#return true


#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Paths

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
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



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#		Files

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func store_hash(filepath:String) -> void:
	file_hashes[filepath] = FMUtils.get_file_hash(filepath)


func remove_hash(filepath:String) -> void:
	if filepath in file_hashes:
		file_hashes.erase(filepath)


func set_dirty_flag(file_dirty:bool, flag:DirtyFlags, _silent:=false) -> void:
	#var old_dirty := dirty
	if file_dirty: dirty |= flag
	else:          dirty &= ~flag

	#if old_dirty != dirty and not silent:
		#gui.missions_list.update_current_mission_id()


func get_dirty_flag(flag:DirtyFlags) -> bool:
	return dirty & flag != 0


func update_pkignore(text:String, file_dirty:=true, silent:=false) -> void:
	mdata.pkignore = text
	set_dirty_flag(file_dirty, DirtyFlags.PKIGNORE, silent)

func update_description(text:String, file_dirty:=true, silent:=false) -> void:
	mdata.description = text
	set_dirty_flag(file_dirty, DirtyFlags.MODFILE, silent)

func update_readme(text:String, file_dirty:=true, silent:=false) -> void:
	mdata.readme = text
	set_dirty_flag(file_dirty, DirtyFlags.README, silent)

func update_title(text:String, file_dirty:=true, silent:=false) -> void:
	mdata.title = text
	set_dirty_flag(file_dirty, DirtyFlags.MODFILE, silent)

func update_author(text:String, file_dirty:=true, silent:=false) -> void:
	mdata.author = text
	set_dirty_flag(file_dirty, DirtyFlags.MODFILE, silent)

func update_version(text:String, file_dirty:=true, silent:=false) -> void:
	mdata.version = text
	update_zipname()
	set_dirty_flag(file_dirty, DirtyFlags.MODFILE, silent)

func update_tdm_version(text:String, file_dirty:=true, silent:=false) -> void:
	mdata.tdm_version = text
	set_dirty_flag(file_dirty, DirtyFlags.MODFILE, silent)
