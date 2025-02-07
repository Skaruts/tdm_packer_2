extends Node
# autoloaded script


var menu_bar      : GuiMenuBar
var missions_list : GuiMissionsList
var workspace_mgr : GuiWorkspaceManager



func initialize() -> void:
	missions_list.initialize()
	workspace_mgr.initialize()
	menu_bar.initialize()
