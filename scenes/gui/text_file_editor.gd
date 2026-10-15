class_name TextFileEditor
extends VBoxContainer


@onready var code_edit: CodeEdit = %CodeEdit

var path: String
var mission: Mission


func _ready() -> void:
	code_edit.text_changed.connect(_on_code_edit_text_changed.bind())
	code_edit.focus_entered.connect(code_edit.set_highlight_current_line.bind(true))
	code_edit.focus_exited.connect(code_edit.set_highlight_current_line.bind(false))



func _on_code_edit_text_changed() -> void:
	var dirty: bool = code_edit.get_version() != code_edit.get_saved_version()
	mission.update_file(path, code_edit.text, dirty)
	fms.start_save_timer(false)
	# code_edit.syntax_highlighter.clear_highlighting_cache()



func set_data(mis: Mission, _path: String) -> void:
	mission = mis
	path = _path


func update_text(text: String) -> void:
	code_edit.text = text


func tag_code_editor() -> void:
	code_edit.tag_saved_version()


func update_button_states() -> void:
	pass


func update_colors() -> void:
	logs.print("update_colors")
	var ext := path.get_extension()
	match ext:
		"mtr"    : code_edit.syntax_highlighter = MaterialCodeHighlighter.new()
		"skin"   : code_edit.syntax_highlighter = SkinCodeHighlighter.new()
		"xd"     : code_edit.syntax_highlighter = XDataCodeHighlighter.new()
		"prt"    : code_edit.syntax_highlighter = ParticleCodeHighlighter.new()
		"def"    : code_edit.syntax_highlighter = DefCodeHighlighter.new()
		"gui"    : code_edit.syntax_highlighter = GuiCodeHighlighter.new()
		"script" : code_edit.syntax_highlighter = ScriptCodeHighlighter.new()
		_: code_edit.syntax_highlighter = null
