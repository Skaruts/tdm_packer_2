class_name ValidationTab
extends HSplitContainer


@onready var btn_parse_maps: Button = %btn_parse_maps
@onready var btn_find_unused: Button = $VBoxContainer2/HFlowContainer/btn_find_unused
@onready var ob_map_choice: OptionButton = %ob_map_choice

@onready var maps_report: ReportPanel = %maps_report
@onready var assets_report: ReportPanel = %assets_report


@onready var parent: GuiTabPackage = get_parent()


enum AssetCategory {
	ALL,
	ENTITIES,
	MODELS,
	MATERIALS,
	SKINS,
	PARTICLES,
	XDATA,
}

# . check for unused entities in files that are being included
#
# . check for entities that don't match the given values, to make sure
#   #entities are configured correctly (eg, all keys are droppable)
@onready var ob_asset_category: OptionButton = %ob_asset_category


func _ready() -> void:
	ob_asset_category.add_item("All",        AssetCategory.ALL)
	ob_asset_category.add_item("Entities",   AssetCategory.ENTITIES)
	ob_asset_category.add_item("Models",     AssetCategory.MODELS)
	ob_asset_category.add_item("Materials",  AssetCategory.MATERIALS)
	ob_asset_category.add_item("Skins",      AssetCategory.SKINS)
	ob_asset_category.add_item("Particles",  AssetCategory.PARTICLES)
	ob_asset_category.add_item("Xdata",      AssetCategory.XDATA)

	#Utils.set_button_state(btn_find_unused,   false)
	Utils.set_button_state(ob_map_choice,     false)
	Utils.set_button_state(ob_asset_category, false)

	btn_find_unused.pressed.connect(_on_btn_find_unused_pressed)

	#assets_report.set_label_position(assets_report.LabelPosition.BOTTOM)
	assets_report.set_progress_bar(false)

	#maps_report.set_label_position(maps_report.LabelPosition.BOTTOM)
	maps_report.set_progress_bar(false)
	maps_report.set_bb_text('Press [color="cc8800"]Parse Maps[/color] to gather map information.')



func parse_maps() -> bool:
	const Map    := MapParser.Map
	const Entity := MapParser.Entity

	var mission := parent.mission
	if mission.mdata.map_files.size() == 0: return false
	#logs.print("parsing maps")

	var parser := MapParser.new()
	mission.map_parser = parser

	maps_report.set_progress_bar(true)
	await maps_report.clear()

	#maps_report.task("Parsing maps...\n")
	for map_filename in mission.mdata.map_files:
		var map_path := Path.join(mission.paths.maps, map_filename + ".map")
		await launcher.run_in_local_thread( parser.parse.bind(maps_report, map_path, map_filename) )

	# TODO: fill out the label with map info
	maps_report.print("")
	for map_name:String in parser.maps:
		var map := parser.maps[map_name]
		maps_report.info("%s.map" % map_name)
		maps_report.print("      %s entities" % map.entities.size())
		maps_report.print("      %s brushes" % map.brushes.size())
		maps_report.print("      %s patches" % map.patches.size())
		maps_report.print("      %s materials" % map.materials.size())

		var num_models := 0
		for model:String in map.models.items():
			if model.begins_with("func_static_"): continue
			num_models += 1
		maps_report.print("      %s models" % [num_models])

		maps_report.print("      %s particles" % map.particles.size())
		maps_report.print("      %s skins" % map.skins.size())
		maps_report.print("      %s xdata" % map.xdata.size())
		maps_report.print("")


	var maps_parsed := parser.maps.size()
	var total_maps := mission.mdata.map_files.size()
	maps_report.reminder("%d/%d maps parsed successfully" % [maps_parsed, total_maps])

	maps_report.set_progress_bar(false)
	return true


func _on_btn_parse_maps_pressed() -> void:
	if await parse_maps():
		Utils.set_button_state(btn_find_unused,   true)
		Utils.set_button_state(ob_map_choice,     true)
		Utils.set_button_state(ob_asset_category, true)


func _on_btn_find_unused_pressed() -> void:
	var id := ob_asset_category.get_selected_id()
	await assets_report.clear()

	# TODO: gather all the definitions in the files
	FMUtils.gather_definitions(assets_report, parent.mission)


	# TODO: find unused stuff
	#match id:
		#AssetCategory.ALL:       FMUtils.find_unused_models(assets_report)
		#AssetCategory.ENTITIES:  pass
		#AssetCategory.MODELS:    pass
		#AssetCategory.MATERIALS: pass
		#AssetCategory.SKINS:     pass
		#AssetCategory.PARTICLES: pass
		#AssetCategory.XDATA:     pass
