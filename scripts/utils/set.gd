extends RefCounted
class_name Set

# version 3

"""
	An array type that doesn't allow duplicates
"""


var _size:int
var _items:Array
var _indices:Dictionary


func _init(array_or_set:Variant=null) -> void:
	if not array_or_set: return

	var array:Array
	if   array_or_set is Set:   array = array_or_set.items()
	elif array_or_set is Array: array = array_or_set

	for item:Variant in array:
		add(item)


func _to_string() -> String:
	return str(_items)


func contains(item:Variant) -> bool:
	return item in _indices

func is_empty() -> bool:
	return _size == 0


func size() -> int:
	return _size


func clear() -> void:
	_indices.clear()
	_items.clear()
	_size = 0


func items() -> Array:
	return _items

func duplicate() -> Set:
	return Set.new(self)


func add(item:Variant) -> void:
	if item in _indices: return
	_size += 1
	_items.append(item)
	_indices[item] = _size


func remove(item:Variant) -> void:
	if not item in _indices: return

	var idx:int = _indices[item]
	_indices.erase(item)

	# pop the top element off the set
	var top_item:Variant = _items.pop_back()

	if top_item != item:
		# if 'top_item' is not 'item', replace 'item' with 'top_item'
		_indices[top_item] = idx
		_items[idx] = top_item

	_size -= 1




