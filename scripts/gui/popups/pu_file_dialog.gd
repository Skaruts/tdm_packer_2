extends FileDialog

signal about_to_close


func _ready() -> void:
	close_requested.connect(_on_close_requested)
	visibility_changed.connect(_on_visibility_changed)


func _validate_field(dic:Dictionary, field:String, default:Variant) -> Variant:
	if field in dic: return dic[field]
	return default


func open(info:Dictionary) -> void:
	title          = _validate_field(info, "title", "NO TITLE")
	current_dir    = _validate_field(info, "dir", "")
	filters        = _validate_field(info, "filters", [])
	file_mode      = _validate_field(info, "mode", FileDialog.FILE_MODE_OPEN_FILE)
	root_subfolder = _validate_field(info, "root", "")

	# 'dir_selected' doesn't work with double-clicks, for some reason

	match file_mode:
		FileDialog.FILE_MODE_OPEN_FILE, \
		FileDialog.FILE_MODE_OPEN_FILES,\
		FileDialog.FILE_MODE_SAVE_FILE:
			file_selected.connect(_on_selected)
		#FileDialog.FILE_MODE_OPEN_DIR:
			#dir_selected.connect(_on_selected)
		FileDialog.FILE_MODE_OPEN_ANY:
			file_selected.connect(_on_selected)
			#dir_selected.connect(_on_selected)

	popup()


func _on_close_requested() -> void:
	hide()


func _on_selected(__:String) -> void:
	hide()


func _on_visibility_changed() -> void:
	if not visible:
		if file_selected.is_connected(_on_selected): file_selected.disconnect(_on_selected)
		#if dir_selected.is_connected(_on_selected): dir_selected.disconnect(_on_selected)
		about_to_close.emit()

