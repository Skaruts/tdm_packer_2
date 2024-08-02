class_name Mission
extends RefCounted


var file_tree:FMTreeNode
var filepaths: Array[String]
var file_count:int
var dir_count:int

var ignored_directories:Set
var ignored_files:Set


var path_root:String
var path_root_test:String
var path_maps:String

var path_defs:String
var path_guis:String
var path_materials:String
var path_particles:String
var path_skins:String
var path_xdata:String
var path_scripts:String


var pkignore:String
var modfile:String
var readme:String
var map_names:Array[String]


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

#var open_files: Dictionary # [FMFile]



func _init(_id:="") -> void:
	id = _id


func set_dirty_flag(file_dirty:bool, flag:DirtyFlags, silent:=false) -> void:
	var old_dirty := dirty
	if file_dirty: dirty |= flag
	else:          dirty &= ~flag

	if old_dirty != dirty and not silent:
		fm_manager.mission_dirty_state_changed.emit()


func get_dirty_flag(flag:DirtyFlags) -> bool:
	return dirty & flag != 0


func update_pkignore(text:String, file_dirty:=true, silent:=false) -> void:
	pkignore = text
	set_dirty_flag(file_dirty, DirtyFlags.PKIGNORE, silent)

func update_modfile(text:String, file_dirty:=true, silent:=false) -> void:
	modfile = text
	set_dirty_flag(file_dirty, DirtyFlags.MODFILE, silent)

func update_readme(text:String, file_dirty:=true, silent:=false) -> void:
	readme = text
	set_dirty_flag(file_dirty, DirtyFlags.README, silent)



#func update_file(key_path:String, text:String, dirty:=true, silent:=false) -> void:
	#open_files[key_path].text = text
	#set_dirty_flag(dirty, DirtyFlags.FILES, silent)
#
#func close_file(key_path:String, silent:=false) -> void:
	#open_files.erase(key_path)
	#if open_files.size() == 0:
		#set_dirty_flag(false, DirtyFlags.FILES, silent)




func add_map(name:String, silent:=false) -> bool:
	if name in map_names: return false
	map_names.append(name)
	#set_dirty_flag(true, DirtyFlags.MAPS, silent)
	#fm_manager.reload_mission(self)
	return true

func remove_map(name:String, silent:=false) -> bool:
	logs.print("removing map")
	assert(name in map_names)
	#if not name in map_names: return false
	map_names.erase(name)
	#set_dirty_flag(true, DirtyFlags.MAPS, silent)
	#fm_manager.reload_mission(self)
	return true
