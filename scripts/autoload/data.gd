extends Node
# autoloaded script



#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Program stuff
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
const VERSION  = "0.1"
var app_title := "TDM Packer 2 (v%s)" % [VERSION]




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Constants
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
const ERROR_COLOR       = Color(1, 0.37, 0.37)
const WARNING_COLOR     = Color(1, 0.67500007152557, 0.22000002861023)
const VALID_COLOR       = Color(0.43, 1, 0.43)
const TEXT_COLOR        = Color(0.80000001192093, 0.80000001192093, 0.79607844352722)
const FADED_TEXT_COLOR  = Color(0.3, 0.3, 0.3)
const EDITED_FILE_COLOR = Color(1, 0.851, 0.53)

# Tecnically constants, won't ever change
var CWD           := ProjectSettings.globalize_path("res://")
var DATA_PATH     := ProjectSettings.globalize_path("res://data")
var SETTINGS_PATH := ProjectSettings.globalize_path("res://data/settings.cfg")
var MISSIONS_FILE := ProjectSettings.globalize_path("res://data/missions.dat")


const IGNORES_FILENAME     = ".pkignore"
const MODFILE_FILENAME     = "darkmod.txt"
const STARTINGMAP_FILENAME = "startingmap.txt"
const MAPSEQUENCE_FILENAME = "tdm_mapsequence.txt"
const README_FILENAME      = "readme.txt"
const CURRENT_FM_FILE      = "currentfm.txt"


const DEFAULT_MODFILE =                          \
		  "Title: Gorgeous Title\n"              \
		+ "Description: Beautiful Description\n" \
		+ "Author: Amazing Author\n"             \
		+ "Version: 1\n"                         \
		+ "Required TDM Version: 2.12"




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		Data
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
signal settings_changed

var config:ConfigData


# TODO: this shouldn't be here
var curr_workspace:int




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#        API

#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=

#func _init() -> void:
	#CWD = Path.get_cwd()


func save_config() -> int:
	var err := config.save(SETTINGS_PATH)
	return err


func load_config() -> bool:
	var err := config.load(SETTINGS_PATH)
	return err == OK


func initialize() -> void:
	logs.task("Initializing data...")

	config = ConfigData.new()

	if not Path.dir_exists(DATA_PATH):
		Path.make_dir(DATA_PATH)

	if not Path.file_exists(SETTINGS_PATH):
		save_config()

	if not load_config():
		popups.warning_report.open({
			title= "Error",
			text = "Data initialization failed: could not load config file.",
		})
		# should this await?
		await popups.warning_report.close_requested
		get_tree().quit()
		return

	update_theme(config)

	logs.task("Data initialized.")





func open_settings() -> void:
	var options:ConfigData = config.duplicate()
	#logs.print("options: ", options)
	popups.settings.open(options)

	var confirmed:bool = await popups.settings.popup_closed

	if confirmed:
		update_settings(options)


func update_settings(options:ConfigData) -> void:
	if not options.dirty: return
	logs.print("SAVING OPTIONS")

	config.update(options)

	update_theme(config)
	save_config()
	settings_changed.emit()


func update_theme(config:ConfigData) -> void:
	var theme := ThemeDB.get_project_theme()
	theme.default_font_size = config.gui_font_size
	theme.set_font_size("font_size", "CodeEdit", config.code_font_size)
