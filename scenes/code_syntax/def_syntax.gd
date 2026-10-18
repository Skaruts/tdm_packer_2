class_name DefCodeHighlighter
extends BaseCodeHighlighter


func _on_init() -> void:
	member_variable_color = data.config.text
	function_color = data.config.text

	# NOTE: these are currently not being used, as there's no custom
	#       syntax highlighting for .def files

	builtins = [
		"entityDef",
		"model",
	]

	base_types = [
		"mesh",
		"channel",
		"anim",
		"anim",
		"frame",
	]

	user_types = [
		"inherit",
		"spawnclass",
		"editor_usage",
		"editor_color",
		"editor_displayFolder",
		"editor_mins",
		"editor_maxs",
		"editor_snd",
		"editor_var",
	]

	param_types = [
		"walk",
		"walk2",
		"run",
		"search",
		"melee_attack1",
		"sight",
		"torso",
		"legs",
		"af_pose",
		"ik_pose",
		"idle",
		"idle2",
		"walk_blind",
		"footstep",
		"sound_voice",
		"snd_sight",
		"snd_accel",
		"snd_move",
		"snd_decel",
		"snd_open",
		"snd_close",
		"snd_opened",
		"snd_explode",
		"snd_sight",
		"snd_moving",
		"snd_stationary",
		"snd_alert",
		"snd_end",
		"snd_death",
		"snd_death_nopower",
		"snd_sparks",
		"snd_bullethole",
		"snd_shatter",
		"snd_quake",
	]

