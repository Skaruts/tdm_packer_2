class_name ParticleCodeHighlighter
extends BaseCodeHighlighter


func _on_init() -> void:
	builtins = [   # headers
		"particle",
	]

	param_types = [
		"sphere",
		"cone",
		"view",
	]

	flows = [
		"to",
	]

	keywords = [
		"count",
		"material",
		"time",
		"cycles",
		"timeOffset",
		"bunching",
		"distribution",
		"direction",
		"orientation",
		"speed",
		"size",
		"aspect",
		"rotation",
		"randomDistribution",
		"boundsExpansion",
		"fadeIn",
		"fadeOut",
		"fadeIndex",
		"color",
		"fadeColor",
		"offset",
		"gravity",
		"entityColor",
	]


