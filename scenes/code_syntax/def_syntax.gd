class_name DefCodeHighlighter
extends BaseCodeHighlighter


func _on_init() -> void:
	member_variable_color = data.config.text
	function_color = data.config.text

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
	]

