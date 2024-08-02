extends TabContainer

var _mission:Mission

@onready var packing: HSplitContainer = %packing


func init(mission:Mission) -> void:
	_mission = mission

	current_tab = data.curr_workspace
	for c:Node in get_children():
		#if c.has_method("init"):
		c.init(mission)

