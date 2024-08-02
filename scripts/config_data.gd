class_name ConfigData
extends RefCounted


var dirty := false

var __properties:Dictionary = {
	paths = {
		dr_path        = "",
		tdm_path       = "",
		tdm_copy_path  = "",
	},
	gui = {
		gui_font_size = 14,
		code_font_size = 14,
		#draw_minimap = true,
	}
}



func _get(prop: StringName) -> Variant:
	for key in __properties:
		if prop in __properties[key]:
			return __properties[key][prop]

	logs.error("config.get failed:   %s" % prop)
	return null


func _set(prop: StringName, val: Variant) -> bool:
	for key in __properties:
		if prop in __properties[key]:
			__properties[key][prop] = val
			dirty = true
			return true

	return false




#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
#		API
#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=
func save(path:String) -> int:
	var cf := ConfigFile.new()

	for key in __properties:
		for prop in __properties[key]:
			cf.set_value(key, prop, __properties[key][prop])

	var err := cf.save(path)
	if err != OK:
		logs.error("Couldn't save config file at '%s'" % path)
		return err

	dirty = false
	return OK


func load(path:String) -> int:
	var cf := ConfigFile.new()
	var err := cf.load(path)
	if err != OK: return err

	for key in __properties:
		for prop in __properties[key]:
			__properties[key][prop] = cf.get_value(key, prop, __properties[key][prop])

	return OK


func duplicate() -> ConfigData:
	var cd := ConfigData.new()

	cd.__properties = __properties.duplicate(true)
	cd.dirty = false # make sure this is reset

	return cd


func update(new_data:ConfigData) -> void:
	__properties = new_data.__properties.duplicate(true)
	dirty = true
