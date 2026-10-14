extends Node
# autoloaded script



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Constants
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
const VERSION = "0.4.1.alpha"

const DEFAULT_CONFIG := {
	paths = {
		dr_path       = "",
		tdm_path      = "",
		tdm_copy_path = "",
	},
	gui = {
		gui_font_size   = 14,
		code_font_size  = 14,
		show_tree_roots = true,
		packname_suffix = "_v$version",
		popup_bg_opacity = 0.5,
		date_time_format = "d/m/y t",
	},
	editors = {
		background_color = Color(0.07, 0.064, 0.062),
		tab_close_buttons_mode = 0,
	},
	syntax = {
		text      = Color.LIGHT_GRAY,
		keyword1  = Color(0.384, 1.0, 0.0),
		keyword2  = Color(0.0, 0.831, 0.498),
		keyword3  = Color(0.902, 0.0, 1.0),
		type      = Color(0.415, 1.0, 0.22),
		function  = Color(0.22, 0.545, 1.0),
		builtin   = Color(0.376, 0.959, 0.99),
		member    = Color(1.0, 0.417, 0.0),
		number    = Color(0.788, 0.616, 0.988),
		constant  = Color(0.0, 1.0, 1.0),
		symbol    = Color(1.0, 1.0, 1.0),
		comment   = Color(0.345, 0.345, 0.345),
		string    = Color(1.0, 0.698, 0.212),
		directive = Color(1.0, 0.253, 0.24),
		boolean   = Color(0.788, 0.616, 0.988),
		header    = Color(0.341, 0.714, 1.0),
		param     = Color(0.0, 1.0, 1.0),
	},
}

#const DEFAULT_MODFILE =                          \
		  #"Title: Beautiful Title\n"              \
		#+ "Description: Lovely Description\n" \
		#+ "Author: Amazing Author\n"             \
		#+ "Version: 1\n"                         \
		#+ "Required TDM Version: 2.12"

const DEFAULT_MODFILE =                          \
		  "Title:\n"              \
		+ "Description:\n" \
		+ "Author:\n"             \
		+ "Version:\n"                         \
		+ "Required TDM Version:"

const ERROR_COLOR       = Color(1.0, 0.49, 0.49)
const WARNING_COLOR     = Color(1, 0.67500007152557, 0.22000002861023)
const VALID_COLOR       = Color(0.43, 1, 0.43)
const TEXT_COLOR        = Color.LIGHT_GRAY
const FADED_TEXT_COLOR  = Color(0.3, 0.3, 0.3)
const EDITED_FILE_COLOR = Color(1, 0.851, 0.53)


# Tecnically constants, as they'll never change
var CWD           := Path.to_global("res://")
var DATA_PATH     := Path.to_global("res://data")
var SETTINGS_PATH := Path.to_global("res://data/settings.cfg")
var MISSIONS_FILE := Path.to_global("res://data/missions.dat")

const IGNORES_FILENAME     = ".pkignore"
const MODFILE_FILENAME     = "darkmod.txt"
const STARTINGMAP_FILENAME = "startingmap.txt"
const MAPSEQUENCE_FILENAME = "tdm_mapsequence.txt"
const README_FILENAME      = "readme.txt"
const CURRENT_FM_FILE      = "currentfm.txt"

const ICON_FILE       : Texture2D = preload("res://assets/icons/file_icon.png")
const ICON_FOLDER     : Texture2D = preload("res://assets/icons/folder_icon.png")
const ICON_DOT        : Texture2D = preload("res://assets/icons/dot_icon.png")
const ICON_CHECKMARK  : Texture2D = preload("res://assets/icons/check_mark_icon.png")
const ICON_WARNING    : Texture2D = preload("res://assets/icons/NodeWarning.svg")
const ICON_LOCK       : Texture2D = preload("res://assets/icons/lock_icon.png")

#const WORKSPACE_PATH = "res://scenes/gui/gui_mission_workspace.tscn"
#const UP_ARROW_16   := preload("res://assets/icons/up_arrow_16.png")
#const DOWN_ARROW_16 := preload("res://assets/icons/down_arrow_16.png")

const TOK_VERSION     := "$version"
const TOK_AUTHOR      := "$author"
const TOK_TITLE       := "$title"
const TOK_MIN_VERSION := "$min_version"
const TOK_DATETIME    := "$date_time"





#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Data
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
var app_title := "TDM Packer 2 (%s)" % [VERSION]

var config: ConfigData

var base_color := Color(0.149, 0.141, 0.125)
var accent_color := Color(1.0, 0.467, 0.0)

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#        Internal API
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func _save_config() -> int:
	var err := config.save(SETTINGS_PATH)
	return err

func _load_config() -> bool:
	var err := config.load(SETTINGS_PATH)
	return err == OK

func _update_theme() -> void:
	var theme := ThemeDB.get_project_theme()
	theme.default_font_size = config.gui_font_size
	theme.set_font_size("font_size", "CodeEdit", config.code_font_size)
	popups.popup_background.color.a = config.popup_bg_opacity

	var stylebox: StyleBoxFlat = theme.get_stylebox("normal", "CodeEdit")
	stylebox.bg_color = config.background_color



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#        External API
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func initialize() -> void:
	logs.task("Initializing data...")

	config = ConfigData.new()
	config.update_from_dict(DEFAULT_CONFIG)
	if not Path.dir_exists(DATA_PATH):
		Path.make_dir(DATA_PATH)

	if not Path.file_exists(SETTINGS_PATH):
		_save_config()

	if not _load_config():
		logs.error("Failed to initialize data.")
		# FIXME: this popup's callback is only called when confirmed
		popups.show_message(
			"Error",
			"Data initialization failed: could not load config file. Aborting",
			func() -> void:
				get_tree().quit()
		)
		return

	_save_config() # save in case some settings are missing from the file
	_update_theme()


func update_config(new_config:ConfigData) -> void:
	if not new_config.dirty: return
	logs.print("SAVING OPTIONS")

	config.update(new_config)
	_save_config()
	_update_theme()

	# some stuff needs to know the config changed
	fms.update_mission_data()
	gui.update_missions_list()

	for i:int in fms.missions.size():
		var mis:Mission = fms.missions[i]
		if mis.update_zipname():
			#fms.soft_reload_mission(mis, true)
			#gui.workspace_update_pack_name( fms.get_mission_index(mis) )
			gui.workspace_update_pack_name(i)
		gui.on_mission_reloaded(i)


	gui.update_workspaces()
	gui.workspace_set_show_roots()
	gui.missions_list_update_buttons()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Helper Functions
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func is_tdm_path_set()      -> bool: return data.config.tdm_path      != ""
func is_dr_path_set()       -> bool: return data.config.dr_path       != ""
func is_tdm_copy_path_set() -> bool: return data.config.tdm_copy_path != ""



func get_date_time_string() -> String:
	var dic := Time.get_datetime_dict_from_system()
	#date_time_format = "d/m/y h:m"
	var date_time: String = config.date_time_format
	date_time = date_time.replace('t', "%d:%02d" % [dic.hour, dic.minute])
	date_time = date_time.replace('d', "%02d"    % dic.day)
	date_time = date_time.replace('m', "%02d"    % dic.month)
	date_time = date_time.replace('y', "%d"     % dic.year)
	return date_time
