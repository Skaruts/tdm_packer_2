extends Node
# autoloaded script



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Constants
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
const VERSION = "a0.3.2"

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
		popup_bg_opacity = 0.5,
	}
}

const DEFAULT_MODFILE =                          \
		  "Title: Beautiful Title\n"              \
		+ "Description: Lovely Description\n" \
		+ "Author: Amazing Author\n"             \
		+ "Version: 1\n"                         \
		+ "Required TDM Version: 2.12"

const ERROR_COLOR       = Color(1.0, 0.49, 0.49)
const WARNING_COLOR     = Color(1, 0.67500007152557, 0.22000002861023)
const VALID_COLOR       = Color(0.43, 1, 0.43)
const TEXT_COLOR        = Color(0.80000001192093, 0.80000001192093, 0.79607844352722)
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

const FILE_ICON   = preload(nodepaths.FILE_ICON_PATH)
const FOLDER_ICON = preload(nodepaths.FOLDER_ICON_PATH)

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Data
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
var app_title := "TDM Packer 2 (%s)" % [VERSION]

var config:ConfigData



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
	fms.update_folders()
	gui.menu_bar.update_menu()
	gui.missions_list.update_buttons()



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Helper Functions
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func is_tdm_path_set()      -> bool: return data.config.tdm_path      != ""
func is_dr_path_set()       -> bool: return data.config.dr_path       != ""
func is_tdm_copy_path_set() -> bool: return data.config.tdm_copy_path != ""
