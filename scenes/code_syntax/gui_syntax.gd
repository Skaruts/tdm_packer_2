class_name GuiCodeHighlighter
extends BaseCodeHighlighter


func _on_init() -> void:
	headers = [
		"windowDef",

		# TODO: Not 100% sure about these
		# (https://wiki.thedarkmod.com/index.php?title=GUI_Scripting:_TDM_vs_Doom_3,_Quake_4)
		"bindDef",
		"choiceDef",
		"editDef",
		"listDef",
		"renderDef",
		"sliderDef",
		"windowDef",
	]

	constants = [
		# "BRIEFING_TEXT_SCALE",            # defined
		# "BRIEFING_TEXT_FONT",             # defined
		# "SUBTITLES_NAMEPREFIX",           # defined
		# "POS_BRIEFING_OBJECTIVES_BUTTON", # defined
		# "POS_BRIEFING_MAIN_MENU_BUTTON",  # defined
		# "OBJ_OFFSET_X",                   # defined
		# "OBJ_FULL_WIDTH",                 # defined
		# "OBJ_FULL_HEIGHT",                # defined
		"MM_POS_OBJ_BACK_ACTION",
		"MM_POS_OBJ_FORWARD_BUTTON_GLOW",
		"MM_FONT_RIGHT_GLOW",
		"MM_BUTTON_HUGE",
		"MM_POS_OBJ_FORWARD_BUTTON",
		"MM_FONT_RIGHT",
		"GLOW_WHITE_COLOR",
		"MM_POS_OBJ_FORWARD_ACTION",
		"SGLOW_WHITE_COLOR",
		"SBOLDGLOW_WHITE_COLOR",
		"SINVISIBLE",
		"SGLOW_BRIGHTRED_COLOR",
		"MM_POS_OBJ_BACK_BUTTON_GLOW",
		"MM_FONT_LEFT_GLOW",
		"MM_POS_OBJ_BACK_BUTTON",
		"MM_FONT_LEFT",
		"MM_STATE_MAINMENU",
		"MM_MUSIC_BRIEFING",
		"MM_POS_OBJ_FORWARD_BUTTON_GLOW",
		"MM_STATE_FORWARD",
		"MM_STATE_BACKWARD",
		"BRIEFING_BACKGROUND_SIZE",
		"BRIEFING_BACKGROUND_IMAGE",
	]

	keywords1 = [
		"rect",
		"nocursor",
		"background",
		"visible",
		"matcolor",
		"noTime",
		"onTime",
		"forecolor",
		"text",
		"textscale",
		"textalign",
		"font",
		"resetTime",
		"set",
		"transition",
		"textalignx",
		"bordercolor",
		"backcolor",
		"resetCinematics",
		"setFocus",
		"runScript",
		"showCursor",
		"onActivate",

	]

	keywords2 = [
		"onAction",
		"onMouseEnter",
		"onMouseExit",
		"onNamedEvent",
	]

	keywords3 = [
		"if"
	]


	# params = [

	# ]

	directives = [
		"include",
		"define",
	]
