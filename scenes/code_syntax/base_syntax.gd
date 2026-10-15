class_name BaseCodeHighlighter
extends CodeHighlighter


var keywords:    Array[String]
var flows:       Array[String]
var base_types:  Array[String]
var user_types:  Array[String]
var param_types: Array[String]
var comments:    Array[String]
var strings:     Array[String]
var builtins:    Array[String]
var entrefs:     Array[String]
var constants:   Array[String]
var directives:  Array[String]
var headers:     Array[String]


const SYMBOLS := ["(", ")", "{", "}", "\\", ":", "->", ",", "\n", "\t", "$", "&"]


func _init() -> void:
	var config: ConfigData = data.config

	number_color = config.number
	symbol_color = config.symbol
	member_variable_color = config.member
	function_color = config.function

	_on_init()

	for kw: String in keywords:    add_keyword_color(kw, config.keyword)
	for kw: String in flows:       add_keyword_color(kw, config.flow)
	for kw: String in base_types:  add_keyword_color(kw, config.base_type)
	for kw: String in user_types:  add_keyword_color(kw, config.user_type)
	for kw: String in param_types: add_keyword_color(kw, config.param_type)
	for kw: String in comments:    add_keyword_color(kw, config.comment)
	for kw: String in strings:     add_keyword_color(kw, config.string)
	for kw: String in builtins:    add_keyword_color(kw, config.builtin)
	for kw: String in entrefs:     add_keyword_color(kw, config.entref)
	for kw: String in constants:   add_keyword_color(kw, config.constant)
	for kw: String in directives:  add_keyword_color(kw, config.directive)
	for kw: String in headers:     add_keyword_color(kw, config.header)

	var booleans := ["true", "false", "null"]
	for kw: String in booleans:    add_keyword_color(kw, config.number)

	add_color_region('"', '"', config.string)
	add_color_region("'", "'", config.string)
	add_color_region('/*', '*/', config.comment)
	add_color_region('//', "", config.comment)


func _on_init() -> void:
	assert(false, "to override")
