class_name XDataCodeHighlighter
extends BaseCodeHighlighter


var comment_level := 0


func _on_init() -> void:
	keywords1 = [
		"precache",
	]

	keywords2 = [
		"import",
		"from",
	]




func _get_line_syntax_highlighting(line_num: int) -> Dictionary:
	var page_rgx := RegEx.create_from_string("page[0-9]*_[a-zA-Z]*|gui_page[0-9]*|snd_[a-zA-Z0-9_]*|num_pages")
	var header_rgx := RegEx.create_from_string("\\B[a-zA-Z]\\/[a-zA-Z0-9_\\/]*")

	var config      := data.config
	var color_map   : Dictionary = {}
	var text_editor := get_text_edit()

	var line     := text_editor.get_line(line_num)
	var stripped := line.strip_edges()

	if stripped.is_empty():
		return color_map

	# check single line comments
	var comment_idx := line.find("//")
	if comment_idx != -1:
		color_map[comment_idx] = { color = config.comment }
		if comment_idx == 0 or stripped.left(comment_idx).strip_edges().is_empty():
			return color_map

	# check multiline comments
	var ml_comment_start := line.find("/*")
	var ml_comment_end := line.find("*/")

	if ml_comment_start != -1:
		comment_level += 1
		color_map[ml_comment_start] = { color = config.comment }

	if ml_comment_end   != -1:
		comment_level = max(0, comment_level-1)
		color_map[ml_comment_end] = { color = config.comment }
		color_map[ml_comment_end+2] = { color = Color.LIGHT_GRAY }

	if comment_level > 0:
		color_map[0] = { color = config.comment }
		return color_map

	var line_parts := stripped.split(':', false)

	var key := line_parts[0].strip_edges()
	var idx: int = line.find(key)
	if   key in keywords1: color_map[idx] = { color = config.keyword3 }
	elif key in keywords2: color_map[idx] = { color = config.keyword3 }
	elif key in SYMBOLS:  color_map[idx] = { color = config.symbol }
	else:
		if page_rgx.search_all(key).size() > 0:
			color_map[idx] = { color = config.keyword1 }
		elif header_rgx.search_all(key).size() > 0:
			color_map[idx] = { color = config.header }
		else:
			color_map[idx] = { color = config.string }

	idx = line.find(':')
	if idx != -1: color_map[idx] = { color = config.symbol }

	if line_parts.size() > 1:
		var val := line_parts[1].strip_edges()

		# idx = line.find('{')
		# if idx != -1: color_map[idx] = { color = config.symbol }
		# idx = line.find('}')
		# if idx != -1: color_map[idx] = { color = config.symbol }
		# idx = line.find('\\')
		# if idx != -1: color_map[idx] = { color = config.symbol }

		# idx = line.find('\n')
		# if idx != -1: color_map[idx] = { color = config.symbol }
		# idx = line.find('\t')
		# if idx != -1: color_map[idx] = { color = config.symbol }


		idx = line.find(val)
		color_map[idx] = { color = config.string }

	return color_map
