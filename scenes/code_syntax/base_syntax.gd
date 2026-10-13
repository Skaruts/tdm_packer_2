class_name BaseCodeHighlighter
extends CodeHighlighter


var keywords1: Array[String]
var keywords2: Array[String]
var keywords3: Array[String]
var headers: Array[String]
var params: Array[String]
var directives: Array[String]

const SYMBOLS := ["(", ")", "{", "}", "\\", ":", "->", ",", "\n", "\t"]

func _init() -> void:
	_on_init()

	var config: ConfigData = data.config

	number_color = config.number
	symbol_color = config.symbol
	member_variable_color = Color.LIGHT_GRAY

	for kw: String in keywords1: add_keyword_color(kw, config.keyword1)
	for kw: String in keywords2: add_keyword_color(kw, config.keyword2)
	for kw: String in keywords3: add_keyword_color(kw, config.param)
	for kw: String in headers: add_keyword_color(kw, config.header)
	for kw: String in params: add_keyword_color(kw, config.param)
	for kw: String in directives: add_keyword_color(kw, config.directive)

	add_color_region('"', '"', config.string)
	add_color_region('/*', '*/', config.comment)
	add_color_region('//', "", config.comment)


func _on_init() -> void:
	assert(false, "to override")
