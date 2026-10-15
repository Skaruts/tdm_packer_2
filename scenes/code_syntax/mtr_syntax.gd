class_name MaterialCodeHighlighter
extends BaseCodeHighlighter


func _on_init() -> void:
	builtins = [
		"qer_editorimage",
	]

	param_types = [
		"parm3",
		"add",
		"modulate",
	]

	keywords = [
		"glass",
		"noselfshadow",
		"diffusemap",
		"specularmap",
		"bumpmap",
		"blend",
		"map",
		"rgb",
		"colored",
		"zeroClamp",
		"alpha",
	]



# var comment_level := 0
# var block_level := 0

# func _get_line_syntax_highlighting(line_num: int) -> Dictionary:
# 	var _path_regex := RegEx.create_from_string("(?!.*({|}|(\\/\\/)|(\\/\\*)|(\\*\\/)))[a-zA-Z0-9_\\-/\\.{}]")
# 	#var _path_regex := RegEx.create_from_string("[a-zA-Z0-9_\\-/\\.]+")

# 	var config    := data.config
# 	var color_map : Dictionary = {}
# 	var text_editor := get_text_edit()

# 	var line    := text_editor.get_line(line_num)
# 	var stripped := line.strip_edges()
# 	if stripped.is_empty():
# 		return color_map


# 	var l_bracket := line.find("{")
# 	var r_bracket := line.find("}")

# 	if r_bracket != -1:
# 		block_level = max(0, block_level-1)

# 	# check single line comments
# 	var comment_idx := line.find("//")
# 	if comment_idx != -1:
# 		color_map[comment_idx] = { color = config.comment }
# 		if comment_idx == 0 or stripped.left(comment_idx).strip_edges().is_empty():
# 			return color_map

# 	# check multiline comments
# 	var ml_comment_start := line.find("/*")
# 	var ml_comment_end := line.find("*/")

# 	if ml_comment_start != -1:
# 		comment_level += 1
# 		color_map[ml_comment_start] = { color = config.comment }

# 	if ml_comment_end   != -1:
# 		comment_level = max(0, comment_level-1)
# 		color_map[ml_comment_end] = { color = config.comment }
# 		color_map[ml_comment_end+2] = { color = Color.LIGHT_GRAY }

# 	if comment_level > 0:
# 		color_map[0] = { color = config.comment }
# 		return color_map


# 	# var results := _path_regex.search_all(stripped)

# 	# for res in results:
# 	# 	var token := res.get_string(0)
# 	# 	var start := res.get_start(0)

# 	# 	if   token in keywords1: color_map[start] = { "color": config.keyword1 }
# 	# 	elif token in keywords2: color_map[start] = { "color": config.keyword2 }
# 	# 	elif token in params:    color_map[start] = { "color": config.param }
# 	# 	elif not "/*" in token and "/" in token or ("." in token and not token.is_valid_float()):
# 	# 		# Unquoted texture / file path
# 	# 		color_map[start] = { "color": config.string }

# 	# logs.print(block_level, line)
# 	var line_parts := stripped.replace('\t', ' ').split(' ', false)

# 	#if block_level == 0:
# 		#var results := _path_regex.search_all(line)
# 		#if l_bracket != -1:
# 			#block_level += 1
# 		#if results.size() > 0:
# 			#var str := results[0].get_string()
# 			#color_map[line.find(str)] = { color = config.header }

# 		##logs.print(line_num, line, results)
# 		##color_map[0] = { color = config.header }
# 			#return color_map

# 	var part := line_parts[0]
# 	var idx: int = line.find(part)

# 	if   part in keywords1: color_map[idx] = { color = config.keyword1 }
# 	elif part in keywords2: color_map[idx] = { color = config.keyword2 }
# 	elif part in keywords3: color_map[idx] = { color = config.keyword3 }


# 	if part in keywords1 or part in keywords2 or part in keywords3:
# 		if line_parts.size() > 1:
# 			part = line_parts[1]
# 			idx = line.find(part)

# 			if   part in params:	        color_map[idx] = { color = config.param }
# 			elif part.is_valid_float(): color_map[idx] = { color = config.number }
# 			else:                       color_map[idx] = { color = config.string }
# 		#elif block_level == 0:
# 			##var _path_regex := RegEx.create_from_string("[a-zA-Z0-9_\\-/\\.]+")
# 			#color_map[idx] = { color = Color.RED }



# 	if l_bracket != -1:
# 		block_level += 1



# 	return color_map
