class_name ConfigData
extends RefCounted


var dirty := false
var __properties:Dictionary


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
		var err_msg := "Couldn't save config file at '%s'" % path
		logs.error(err_msg)
		push_error(err_msg)
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

	dirty = false
	return OK


func duplicate() -> ConfigData:
	var cd := ConfigData.new()

	cd.__properties = __properties.duplicate(true)
	cd.dirty = false # make sure this is reset

	return cd


func update(new_data:ConfigData, _dirty:=true) -> void:
	__properties = new_data.__properties.duplicate(true)
	dirty = _dirty


func update_from_dict(new_data:Dictionary, _dirty:=true) -> void:
	__properties = new_data.duplicate(true)
	dirty = _dirty


func is_equal_to(other:ConfigData) -> bool:
	return self.__properties == other.__properties
