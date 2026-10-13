class_name SkinCodeHighlighter_BAK1
extends BaseCodeHighlighter


var comment_level := 0


func _init() -> void:
	keywords1 = ["model"]
	headers = ["skin"]

# func _update_cache() -> void:
# 	logs.print("_update_cache")



func _get_line_syntax_highlighting(line_num: int) -> Dictionary:
	if line_num == 0:
		comment_level = 0

	var path_rgx := RegEx.create_from_string("\\B[a-zA-Z]\\/[a-zA-Z0-9_\\/]*")

	var config      := data.config
	var color_map   : Dictionary = {}
	var text_editor := get_text_edit()

	var line     := text_editor.get_line(line_num)
	var stripped := line.strip_edges()

	if stripped.is_empty():
		# logs.print("<- ", line_num+1, line, color_map)
		return color_map

	line = check_comments(line, color_map)

	# # check single line comments
	# var comment_idx := line.find("//")
	# if comment_idx != -1:
	# 	color_map[comment_idx] = { color = config.comment }
	# 	if comment_idx == 0 or line.left(comment_idx).strip_edges().is_empty():
	# 		# logs.print("<- ", line_num+1, line, color_map)
	# 		return color_map

	# # check multiline comments
	# var ml_comment_start := line.find("/*")
	# var ml_comment_end := line.find("*/")

	# if ml_comment_start != -1:
	# 	comment_level += 1
	# 	color_map[ml_comment_start] = { color = config.comment }

	# if ml_comment_end != -1:
	# 	logs.print("HEEERERRERERER!!!!")
	# 	comment_level = max(0, comment_level-1)
	# 	color_map[ml_comment_end] = { color = config.comment }
	# 	color_map[ml_comment_end+2] = { color = Color.LIGHT_GRAY }
	# 	line = line.left(ml_comment_end)
	# 	stripped = line.strip_edges()

	# if comment_level > 0:
	# 	color_map[0] = { color = config.comment }
	# 	if line.find("*/") != -1:
	# 		logs.print("<- ", line_num+1, line, color_map)
	# 	return color_map

	if line == "": return color_map

	var line_parts := stripped.replace('\t', ' ').split(' ', false)

	var key := line_parts[0].strip_edges()
	var val: String
	if line_parts.size() > 1:
		val = line_parts[1].strip_edges()

	var idx: int = line.find(key)
	# if   key in keywords1: color_map[idx] = { color = config.keyword1 }
	if key in headers:   color_map[idx] = { color = config.header }
	elif key in SYMBOLS: color_map[idx] = { color = config.symbol }
	else:                color_map[idx] = { color = config.keyword1 }

	if val != "":
		idx = line.find(val)
		if path_rgx.search_all(val).size() > 0:
			color_map[idx] = { color = config.string }
		elif key in headers:
			color_map[idx] = { color = Color.LIGHT_GRAY }
		else:
			color_map[idx] = { color = config.string }

	# logs.print(line_num+1, "'"+key+"'", "'"+val+"'", color_map)
	# if line.find("*/") != -1:
	# 	logs.print("<- ", line_num+1, line, color_map)
	# 	logs.print(ml_comment_end)

	return color_map


func check_comments(line: String, color_map: Dictionary) -> String:
	var config := data.config

	# check single line comments
	var comment_idx := line.find("//")
	if comment_idx != -1:
		color_map[comment_idx] = { color = config.comment }
		if comment_idx == 0 or line.left(comment_idx).strip_edges().is_empty():
			# logs.print("<- ", line_num+1, line, color_map)
			return ""

	# check multiline comments
	var ml_comment_start := line.find("/*")
	var ml_comment_end   := line.find("*/")


	if ml_comment_start != -1:
		comment_level += 1
		color_map[ml_comment_start] = { color = config.comment }

	if ml_comment_end != -1:
		comment_level = max(0, comment_level-1)
		color_map[0] = { color = config.comment }
		color_map[ml_comment_end+2] = { color = Color.LIGHT_GRAY }
		line = line.right(ml_comment_end-2)
		#logs.print(line, comment_level)
		return line

	if comment_level > 0:
		color_map[0] = { color = config.comment }
	 	# if line.find("*/") != -1:
	 		# logs.print("<- ", line_num+1, line, color_map)
		return ""

	return line
