class_name SkinCodeHighlighter
extends BaseCodeHighlighter


var comment_level := 0


func _on_init() -> void:
	base_types = ["model"]
	functions = ["skin"]  # headers


# func _update_cache() -> void:
# 	logs.print("_update_cache")



# func _get_line_syntax_highlighting(line_num: int) -> Dictionary:
# 	if line_num == 0:
# 		comment_level = 0

# 	var path_rgx := RegEx.create_from_string("\\B[a-zA-Z]\\/[a-zA-Z0-9_\\/]*")

# 	var config      := data.config
# 	var color_map   : Dictionary = {}
# 	var text_editor := get_text_edit()

# 	var line     := text_editor.get_line(line_num)
# 	var stripped := line.strip_edges()

# 	if stripped.is_empty():
# 		# logs.print("<- ", line_num+1, line, color_map)
# 		return color_map

# 	line = check_comments(line, color_map)

# 	if line.find('/*') or line.find('*/') or line.find('//'):
# 		handle_comment_line(line, color_map)

# 	if line == "": return color_map

# 	var line_parts := stripped.replace('\t', ' ').split(' ', false)

# 	var key := line_parts[0].strip_edges()
# 	var val: String
# 	if line_parts.size() > 1:
# 		val = line_parts[1].strip_edges()

# 	var idx: int = line.find(key)
# 	# if   key in keywords1: color_map[idx] = { color = config.keyword1 }
# 	if key in headers:   color_map[idx] = { color = config.header }
# 	elif key in SYMBOLS: color_map[idx] = { color = config.symbol }
# 	else:                color_map[idx] = { color = config.keyword1 }

# 	if val != "":
# 		idx = line.find(val)
# 		if path_rgx.search_all(val).size() > 0:
# 			color_map[idx] = { color = config.string }
# 		elif key in headers:
# 			color_map[idx] = { color = Color.LIGHT_GRAY }
# 		else:
# 			color_map[idx] = { color = config.string }

# 	# logs.print(line_num+1, "'"+key+"'", "'"+val+"'", color_map)
# 	# if line.find("*/") != -1:
# 	# 	logs.print("<- ", line_num+1, line, color_map)
# 	# 	logs.print(ml_comment_end)

# 	return color_map

# func handle_comment_line(line: String, color_map: Dictionary) -> Array[String]:
# 	var config := data.config
# 	var new_line := line

# 	var line_parts: Array[String]

# 	var i := 0
# 	while i < line.length():
# 		var c := line[i]

# 		match c:
# 			'/':
# 				if i < line.length()-1:
# 					if line[i+1] == '*':
# 						comment_level += 1
# 						color_map[i] = { color = config.comment }
# 						return line.left(i)
# 					elif line[i+1] == '/' and comment_level == 0:
# 						color_map[i] = { color = config.comment }
# 						return line.left(i)
# 			'*':
# 				# sadnsadn */ sadasdasdadad   /* // comment
# 				if i < line.length()-1 and line[i+1] == '/':
# 					if comment_level == 0:
# 						color_map[i] = { color = Color.RED }
# 						color_map[i+2] = { color = Color.LIGHT_GRAY }
# 						return [line.substr(0, i), ]

# 					color_map[0] = { color = config.comment }
# 					comment_level = max(0, comment_level-1)
# 					if comment_level == 0:
# 						color_map[i+2] = { color = Color.LIGHT_GRAY }
# 						new_line = line.substr(i+2)
# 						return new_line
# 					i += 1
# 		i += 1

# 	return line_parts
