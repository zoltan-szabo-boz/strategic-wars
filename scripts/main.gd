extends Control
## Main Game Controller - UI and Game Flow

# =============================================================================
# NODE REFERENCES (set in _ready via get_node)
# =============================================================================

var map_container: GridContainer
var tile_buttons: Array = []  # 2D array of Button references

# Info panel
var turn_label: Label
var tiles_label: Label
var manpower_label: Label
var goods_label: Label
var supplies_label: Label
var pikemen_label: Label
var cavalry_label: Label
var archers_label: Label

# Tile info
var tile_info_panel: PanelContainer
var tile_info_label: Label

# Train units button
var train_units_btn: Button

# Training panel
var training_panel: PanelContainer
var manpower_draft_label: Label
var goods_draft_label: Label
var supplies_draft_label: Label
var pike_count_label: Label
var pike_plus_btn: Button
var pike_minus_btn: Button
var cav_count_label: Label
var cav_plus_btn: Button
var cav_minus_btn: Button
var archer_count_label: Label
var archer_plus_btn: Button
var archer_minus_btn: Button
var cancel_training_btn: Button
var confirm_training_btn: Button

# Draft state for training
var draft_units: Dictionary = {"pikemen": 0, "cavalry": 0, "archers": 0}

# Turn report panel
var turn_report_panel: PanelContainer
var combat_report_label: Label
var income_report_label: Label
var close_report_btn: Button

# Turn report data
var turn_combat_results: Array = []  # Array of combat result dictionaries
var turn_income: Dictionary = {"manpower": 0, "goods": 0, "supplies": 0}

# Assignment panel
var assign_panel: VBoxContainer
var pike_slider: HSlider
var pike_label: Label
var cav_slider: HSlider
var cav_label: Label
var archer_slider: HSlider
var archer_label: Label

# End turn
var end_turn_btn: Button

# Victory
var victory_panel: PanelContainer
var victory_label: Label

# Help
var help_btn: Button
var help_panel: PanelContainer
var close_help_btn: Button
var new_game_btn: Button

# =============================================================================
# CONSTANTS
# =============================================================================

const TILE_SIZE := 64
const TILE_COLORS := {
	"player": Color(0.29, 0.56, 0.85),      # Blue
	"neutral": Color(0.5, 0.5, 0.5),         # Gray
	"border": Color(0.6, 0.55, 0.5),         # Brownish gray for attackable
	"selected": Color(1.0, 1.0, 1.0, 0.3),   # White overlay
}

const RESOURCE_ICONS := {
	Config.ResourceType.MANPOWER: "M",
	Config.ResourceType.GOODS: "G",
	Config.ResourceType.SUPPLIES: "S",
	Config.ResourceType.ALL: "*",
}

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_get_node_references()
	_connect_signals()
	_start_new_game()

func _get_node_references() -> void:
	# Use get_node_or_null to avoid crashes if nodes don't exist
	map_container = get_node_or_null("GameContainer/MapPanel/MapContainer")
	if not map_container:
		push_error("MapContainer not found!")
		return

	turn_label = get_node_or_null("GameContainer/RightPanel/TurnLabel")
	tiles_label = get_node_or_null("GameContainer/RightPanel/TilesLabel")
	manpower_label = get_node_or_null("GameContainer/RightPanel/ManpowerLabel")
	goods_label = get_node_or_null("GameContainer/RightPanel/GoodsLabel")
	supplies_label = get_node_or_null("GameContainer/RightPanel/SuppliesLabel")
	pikemen_label = get_node_or_null("GameContainer/RightPanel/PikemenLabel")
	cavalry_label = get_node_or_null("GameContainer/RightPanel/CavalryLabel")
	archers_label = get_node_or_null("GameContainer/RightPanel/ArchersLabel")

	tile_info_panel = get_node_or_null("GameContainer/RightPanel/TileInfoPanel")
	tile_info_label = get_node_or_null("GameContainer/RightPanel/TileInfoPanel/TileInfoLabel")

	train_units_btn = get_node_or_null("GameContainer/LeftPanel/TrainUnitsBtn")

	# Training panel
	training_panel = get_node_or_null("TrainingPanel")
	manpower_draft_label = get_node_or_null("TrainingPanel/VBox/ResourcesPanel/ResourcesHBox/ManpowerDraft")
	goods_draft_label = get_node_or_null("TrainingPanel/VBox/ResourcesPanel/ResourcesHBox/GoodsDraft")
	supplies_draft_label = get_node_or_null("TrainingPanel/VBox/ResourcesPanel/ResourcesHBox/SuppliesDraft")
	pike_count_label = get_node_or_null("TrainingPanel/VBox/UnitsContainer/PikeRow/PikeControls/PikeCount")
	pike_plus_btn = get_node_or_null("TrainingPanel/VBox/UnitsContainer/PikeRow/PikeControls/PikePlus")
	pike_minus_btn = get_node_or_null("TrainingPanel/VBox/UnitsContainer/PikeRow/PikeControls/PikeMinus")
	cav_count_label = get_node_or_null("TrainingPanel/VBox/UnitsContainer/CavRow/CavControls/CavCount")
	cav_plus_btn = get_node_or_null("TrainingPanel/VBox/UnitsContainer/CavRow/CavControls/CavPlus")
	cav_minus_btn = get_node_or_null("TrainingPanel/VBox/UnitsContainer/CavRow/CavControls/CavMinus")
	archer_count_label = get_node_or_null("TrainingPanel/VBox/UnitsContainer/ArcherRow/ArcherControls/ArcherCount")
	archer_plus_btn = get_node_or_null("TrainingPanel/VBox/UnitsContainer/ArcherRow/ArcherControls/ArcherPlus")
	archer_minus_btn = get_node_or_null("TrainingPanel/VBox/UnitsContainer/ArcherRow/ArcherControls/ArcherMinus")
	cancel_training_btn = get_node_or_null("TrainingPanel/VBox/ButtonsHBox/CancelTrainingBtn")
	confirm_training_btn = get_node_or_null("TrainingPanel/VBox/ButtonsHBox/ConfirmTrainingBtn")

	# Turn report panel
	turn_report_panel = get_node_or_null("TurnReportPanel")
	combat_report_label = get_node_or_null("TurnReportPanel/VBox/ScrollContainer/ReportContent/CombatReport")
	income_report_label = get_node_or_null("TurnReportPanel/VBox/ScrollContainer/ReportContent/IncomeReport")
	close_report_btn = get_node_or_null("TurnReportPanel/VBox/CloseReportBtn")

	assign_panel = get_node_or_null("GameContainer/LeftPanel/AssignPanel")
	pike_slider = get_node_or_null("GameContainer/LeftPanel/AssignPanel/PikeRow/PikeSlider")
	pike_label = get_node_or_null("GameContainer/LeftPanel/AssignPanel/PikeRow/PikeLabel")
	cav_slider = get_node_or_null("GameContainer/LeftPanel/AssignPanel/CavRow/CavSlider")
	cav_label = get_node_or_null("GameContainer/LeftPanel/AssignPanel/CavRow/CavLabel")
	archer_slider = get_node_or_null("GameContainer/LeftPanel/AssignPanel/ArcherRow/ArcherSlider")
	archer_label = get_node_or_null("GameContainer/LeftPanel/AssignPanel/ArcherRow/ArcherLabel")

	end_turn_btn = get_node_or_null("GameContainer/LeftPanel/EndTurnBtn")

	victory_panel = get_node_or_null("VictoryPanel")
	victory_label = get_node_or_null("VictoryPanel/VictoryLabel")

	help_btn = get_node_or_null("HelpBtn")
	help_panel = get_node_or_null("HelpPanel")
	close_help_btn = get_node_or_null("HelpPanel/VBox/CloseHelpBtn")
	new_game_btn = get_node_or_null("NewGameBtn")

func _connect_signals() -> void:
	if not map_container:
		return  # Nodes not found, skip signal connections

	if train_units_btn:
		train_units_btn.pressed.connect(_on_train_units_pressed)

	# Training panel buttons
	if pike_plus_btn:
		pike_plus_btn.pressed.connect(_on_pike_plus)
	if pike_minus_btn:
		pike_minus_btn.pressed.connect(_on_pike_minus)
	if cav_plus_btn:
		cav_plus_btn.pressed.connect(_on_cav_plus)
	if cav_minus_btn:
		cav_minus_btn.pressed.connect(_on_cav_minus)
	if archer_plus_btn:
		archer_plus_btn.pressed.connect(_on_archer_plus)
	if archer_minus_btn:
		archer_minus_btn.pressed.connect(_on_archer_minus)
	if cancel_training_btn:
		cancel_training_btn.pressed.connect(_on_cancel_training)
	if confirm_training_btn:
		confirm_training_btn.pressed.connect(_on_confirm_training)

	if close_report_btn:
		close_report_btn.pressed.connect(_on_close_report)

	if pike_slider:
		pike_slider.value_changed.connect(_on_pike_slider_changed)
	if cav_slider:
		cav_slider.value_changed.connect(_on_cav_slider_changed)
	if archer_slider:
		archer_slider.value_changed.connect(_on_archer_slider_changed)

	if end_turn_btn:
		end_turn_btn.pressed.connect(_on_end_turn)

	if help_btn:
		help_btn.pressed.connect(_on_help_pressed)
	if close_help_btn:
		close_help_btn.pressed.connect(_on_close_help_pressed)
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game_pressed)

func _on_new_game_pressed() -> void:
	_start_new_game()

func _start_new_game() -> void:
	if not map_container:
		push_error("Cannot start game - UI not initialized")
		return
	GameState.reset_to_initial_state()
	_create_map_buttons()
	_refresh_all()
	if victory_panel:
		victory_panel.hide()
	if help_panel:
		help_panel.hide()
	if training_panel:
		training_panel.hide()
	if turn_report_panel:
		turn_report_panel.hide()
	# Reset draft state
	draft_units = {"pikemen": 0, "cavalry": 0, "archers": 0}
	turn_combat_results = []
	turn_income = {"manpower": 0, "goods": 0, "supplies": 0}

# =============================================================================
# MAP DISPLAY
# =============================================================================

func _create_map_buttons() -> void:
	# Clear existing
	for child in map_container.get_children():
		child.queue_free()
	tile_buttons.clear()

	# Create grid of buttons
	for y in range(Config.GRID_SIZE):
		var row: Array = []
		for x in range(Config.GRID_SIZE):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			btn.pressed.connect(_on_tile_clicked.bind(x, y))
			map_container.add_child(btn)
			row.append(btn)
		tile_buttons.append(row)

	_refresh_map()

func _refresh_map() -> void:
	for y in range(Config.GRID_SIZE):
		for x in range(Config.GRID_SIZE):
			_update_tile_button(x, y)

func _update_tile_button(x: int, y: int) -> void:
	var btn: Button = tile_buttons[y][x]
	var tile: GameState.MapTile = GameState.get_tile(x, y)

	# Set color based on owner and border status
	var color: Color
	if tile.owner == Config.TileOwner.PLAYER:
		color = TILE_COLORS["player"]
	elif GameState.is_border_tile(x, y):
		color = TILE_COLORS["border"]
	else:
		color = TILE_COLORS["neutral"]

	# Highlight selected tile
	if GameState.selected_tile == Vector2i(x, y):
		color = color.lightened(0.3)

	# Apply color via StyleBoxFlat
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.2, 0.2, 0.2)
	btn.add_theme_stylebox_override("normal", style)

	# Pressed/hover styles
	var hover_style := style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# Set text: resource icon + production (or defense for neutrals)
	var icon: String = RESOURCE_ICONS.get(tile.resource_type, "?")
	if tile.owner == Config.TileOwner.PLAYER:
		if tile.resource_type == Config.ResourceType.ALL:
			btn.text = icon  # Just star for capital
		else:
			btn.text = "%s%d" % [icon, tile.production]
	else:
		btn.text = "%s%d\nD:%d" % [icon, tile.production, tile.defense]

	# Show assignment indicator if units assigned
	if GameState.has_assignment(Vector2i(x, y)):
		btn.text += "\n!"

# =============================================================================
# UI REFRESH
# =============================================================================

func _refresh_all() -> void:
	_refresh_map()
	_refresh_resources()
	_refresh_army()
	_refresh_turn_info()
	_refresh_tile_info()
	_refresh_assign_panel()

func _refresh_resources() -> void:
	var income := _calculate_income()
	manpower_label.text = "Manpower: %d (+%d)" % [GameState.get_resource("manpower"), income["manpower"]]
	goods_label.text = "Goods: %d (+%d)" % [GameState.get_resource("goods"), income["goods"]]
	supplies_label.text = "Supplies: %d (+%d)" % [GameState.get_resource("supplies"), income["supplies"]]

func _calculate_income() -> Dictionary:
	var income := {"manpower": 0, "goods": 0, "supplies": 0}

	# Capital income
	income["manpower"] += Config.CAPITAL_PROD_MANPOWER
	income["goods"] += Config.CAPITAL_PROD_GOODS
	income["supplies"] += Config.CAPITAL_PROD_SUPPLIES

	# Income from owned tiles
	for y in range(Config.GRID_SIZE):
		for x in range(Config.GRID_SIZE):
			var tile: GameState.MapTile = GameState.get_tile(x, y)
			if tile.owner == Config.TileOwner.PLAYER and tile.resource_type != Config.ResourceType.ALL:
				var res_key := _resource_type_to_key(tile.resource_type)
				if res_key != "":
					income[res_key] += tile.production

	return income

func _refresh_army() -> void:
	var available := GameState.get_available_army()
	pikemen_label.text = "Pikemen: %d (%d)" % [available["pikemen"], GameState.army["pikemen"]]
	cavalry_label.text = "Cavalry: %d (%d)" % [available["cavalry"], GameState.army["cavalry"]]
	archers_label.text = "Archers: %d (%d)" % [available["archers"], GameState.army["archers"]]

func _refresh_turn_info() -> void:
	turn_label.text = "Turn: %d" % GameState.turn_number
	tiles_label.text = "Tiles: %d/%d" % [GameState.tiles_owned, Config.TARGET_TILES]

func _refresh_tile_info() -> void:
	var coord := GameState.selected_tile
	if coord == Vector2i(-1, -1):
		tile_info_label.text = "Click a tile to select"
		assign_panel.hide()
		return

	var tile: GameState.MapTile = GameState.get_tile(coord.x, coord.y)
	var info := ""

	if tile.owner == Config.TileOwner.PLAYER:
		info = "YOUR TERRITORY\n"
		info += "Position: (%d, %d)\n" % [coord.x, coord.y]
		if tile.resource_type == Config.ResourceType.ALL:
			info += "Capital\n"
			info += "Produces: M+%d G+%d S+%d" % [
				Config.CAPITAL_PROD_MANPOWER,
				Config.CAPITAL_PROD_GOODS,
				Config.CAPITAL_PROD_SUPPLIES
			]
		else:
			var res_name := _get_resource_name(tile.resource_type)
			info += "Resource: %s +%d/turn" % [res_name, tile.production]
		assign_panel.hide()
	else:
		var is_border := GameState.is_border_tile(coord.x, coord.y)
		if is_border:
			info = "NEUTRAL - BORDER\n"
		else:
			info = "NEUTRAL\n"
		info += "Position: (%d, %d)\n" % [coord.x, coord.y]
		var res_name := _get_resource_name(tile.resource_type)
		info += "Resource: %s +%d/turn\n" % [res_name, tile.production]
		info += "Defense: %d" % tile.defense

		if is_border:
			assign_panel.show()
			_refresh_assign_panel()
		else:
			info += "\n\n(Not adjacent - cannot attack)"
			assign_panel.hide()

	tile_info_label.text = info

func _get_resource_name(res_type: int) -> String:
	match res_type:
		Config.ResourceType.MANPOWER: return "Manpower"
		Config.ResourceType.GOODS: return "Goods"
		Config.ResourceType.SUPPLIES: return "Supplies"
		Config.ResourceType.ALL: return "All"
	return "Unknown"


func _refresh_assign_panel() -> void:
	var coord := GameState.selected_tile
	if coord == Vector2i(-1, -1) or not GameState.is_border_tile(coord.x, coord.y):
		if assign_panel:
			assign_panel.hide()
		return

	if assign_panel:
		assign_panel.show()

	var assigned := GameState.get_assignment(coord)
	var total_army := GameState.army  # Total army (not available)

	# Calculate max for each slider: currently assigned + available
	var available := GameState.get_available_army()

	# Set slider ranges and values (block signals to prevent feedback loop)
	if pike_slider:
		pike_slider.set_block_signals(true)
		pike_slider.max_value = assigned["pikemen"] + available["pikemen"]
		pike_slider.value = assigned["pikemen"]
		pike_slider.set_block_signals(false)
	if pike_label:
		pike_label.text = "Pike: %d" % int(assigned["pikemen"])

	if cav_slider:
		cav_slider.set_block_signals(true)
		cav_slider.max_value = assigned["cavalry"] + available["cavalry"]
		cav_slider.value = assigned["cavalry"]
		cav_slider.set_block_signals(false)
	if cav_label:
		cav_label.text = "Cav: %d" % int(assigned["cavalry"])

	if archer_slider:
		archer_slider.set_block_signals(true)
		archer_slider.max_value = assigned["archers"] + available["archers"]
		archer_slider.value = assigned["archers"]
		archer_slider.set_block_signals(false)
	if archer_label:
		archer_label.text = "Arch: %d" % int(assigned["archers"])

# =============================================================================
# INPUT HANDLERS
# =============================================================================

func _on_tile_clicked(x: int, y: int) -> void:
	GameState.selected_tile = Vector2i(x, y)
	_refresh_all()

# =============================================================================
# TRAINING PANEL
# =============================================================================

func _on_train_units_pressed() -> void:
	# Reset draft and open panel
	draft_units = {"pikemen": 0, "cavalry": 0, "archers": 0}
	_refresh_training_panel()
	if training_panel:
		training_panel.show()

func _refresh_training_panel() -> void:
	# Calculate draft costs
	var draft_cost := _calculate_draft_cost()

	# Show resources with draft changes
	var current_manpower := GameState.get_resource("manpower")
	var current_goods := GameState.get_resource("goods")
	var current_supplies := GameState.get_resource("supplies")

	var remaining_manpower: int = current_manpower - int(draft_cost["manpower"])
	var remaining_goods: int = current_goods - int(draft_cost["goods"])
	var remaining_supplies: int = current_supplies - int(draft_cost["supplies"])

	if manpower_draft_label:
		manpower_draft_label.text = "Manpower: %d" % remaining_manpower
	if goods_draft_label:
		goods_draft_label.text = "Goods: %d" % remaining_goods
	if supplies_draft_label:
		supplies_draft_label.text = "Supplies: %d" % remaining_supplies

	# Update unit counts
	if pike_count_label:
		pike_count_label.text = str(draft_units["pikemen"])
	if cav_count_label:
		cav_count_label.text = str(draft_units["cavalry"])
	if archer_count_label:
		archer_count_label.text = str(draft_units["archers"])

	# Enable/disable +/- buttons based on affordability
	_update_training_buttons()

func _calculate_draft_cost() -> Dictionary:
	var pike_cost := Config.get_unit_cost(Config.UnitType.PIKEMAN)
	var cav_cost := Config.get_unit_cost(Config.UnitType.CAVALRY)
	var archer_cost := Config.get_unit_cost(Config.UnitType.ARCHER)

	return {
		"manpower": draft_units["pikemen"] * pike_cost["manpower"] + draft_units["cavalry"] * cav_cost["manpower"] + draft_units["archers"] * archer_cost["manpower"],
		"goods": draft_units["pikemen"] * pike_cost["goods"] + draft_units["cavalry"] * cav_cost["goods"] + draft_units["archers"] * archer_cost["goods"],
		"supplies": draft_units["pikemen"] * pike_cost["supplies"] + draft_units["cavalry"] * cav_cost["supplies"] + draft_units["archers"] * archer_cost["supplies"],
	}

func _can_afford_one_more(unit_type: int) -> bool:
	var cost := Config.get_unit_cost(unit_type)
	var draft_cost := _calculate_draft_cost()

	var remaining := {
		"manpower": GameState.get_resource("manpower") - draft_cost["manpower"],
		"goods": GameState.get_resource("goods") - draft_cost["goods"],
		"supplies": GameState.get_resource("supplies") - draft_cost["supplies"],
	}

	return remaining["manpower"] >= cost["manpower"] and remaining["goods"] >= cost["goods"] and remaining["supplies"] >= cost["supplies"]

func _update_training_buttons() -> void:
	# + buttons: enabled if can afford one more
	if pike_plus_btn:
		pike_plus_btn.disabled = not _can_afford_one_more(Config.UnitType.PIKEMAN)
	if cav_plus_btn:
		cav_plus_btn.disabled = not _can_afford_one_more(Config.UnitType.CAVALRY)
	if archer_plus_btn:
		archer_plus_btn.disabled = not _can_afford_one_more(Config.UnitType.ARCHER)

	# - buttons: enabled if draft count > 0
	if pike_minus_btn:
		pike_minus_btn.disabled = draft_units["pikemen"] <= 0
	if cav_minus_btn:
		cav_minus_btn.disabled = draft_units["cavalry"] <= 0
	if archer_minus_btn:
		archer_minus_btn.disabled = draft_units["archers"] <= 0

func _on_pike_plus() -> void:
	if _can_afford_one_more(Config.UnitType.PIKEMAN):
		draft_units["pikemen"] += 1
		_refresh_training_panel()

func _on_pike_minus() -> void:
	if draft_units["pikemen"] > 0:
		draft_units["pikemen"] -= 1
		_refresh_training_panel()

func _on_cav_plus() -> void:
	if _can_afford_one_more(Config.UnitType.CAVALRY):
		draft_units["cavalry"] += 1
		_refresh_training_panel()

func _on_cav_minus() -> void:
	if draft_units["cavalry"] > 0:
		draft_units["cavalry"] -= 1
		_refresh_training_panel()

func _on_archer_plus() -> void:
	if _can_afford_one_more(Config.UnitType.ARCHER):
		draft_units["archers"] += 1
		_refresh_training_panel()

func _on_archer_minus() -> void:
	if draft_units["archers"] > 0:
		draft_units["archers"] -= 1
		_refresh_training_panel()

func _on_cancel_training() -> void:
	# Just close - draft state will be reset on next open
	if training_panel:
		training_panel.hide()

func _on_confirm_training() -> void:
	# Apply the draft: spend resources and add units
	var draft_cost := _calculate_draft_cost()

	# Final check: can we still afford this?
	if GameState.can_afford(draft_cost):
		GameState.spend_resources(draft_cost)
		GameState.add_army("pikemen", draft_units["pikemen"])
		GameState.add_army("cavalry", draft_units["cavalry"])
		GameState.add_army("archers", draft_units["archers"])

	# Close panel and refresh
	if training_panel:
		training_panel.hide()
	_refresh_all()

func _on_pike_slider_changed(value: float) -> void:
	_set_assignment("pikemen", int(value))

func _on_cav_slider_changed(value: float) -> void:
	_set_assignment("cavalry", int(value))

func _on_archer_slider_changed(value: float) -> void:
	_set_assignment("archers", int(value))

func _set_assignment(unit_key: String, new_count: int) -> void:
	var coord := GameState.selected_tile
	if coord == Vector2i(-1, -1):
		return

	var assigned := GameState.get_assignment(coord)
	assigned[unit_key] = new_count
	GameState.set_assignment(coord, assigned)

	# Update label and army display without full refresh (to avoid slider feedback)
	_refresh_army()
	_refresh_assign_panel()

func _on_help_pressed() -> void:
	if help_panel:
		help_panel.show()

func _on_close_help_pressed() -> void:
	if help_panel:
		help_panel.hide()

# =============================================================================
# TURN REPORT
# =============================================================================

func _show_turn_report() -> void:
	# Format combat report
	var combat_text := ""
	if turn_combat_results.is_empty():
		combat_text = "No combat this turn."
	else:
		for result in turn_combat_results:
			var tile_pos: Vector2i = result["tile"]
			var victory: bool = result["victory"]
			var casualties: Dictionary = result["casualties"]

			combat_text += "Tile (%d, %d): " % [tile_pos.x, tile_pos.y]
			combat_text += "VICTORY!\n" if victory else "DEFEAT\n"
			combat_text += "  Role: %s\n" % result["role"]
			combat_text += "  Enemy Defense: %d\n" % result["defender_power"]

			var total_casualties: int = casualties["pikemen"] + casualties["cavalry"] + casualties["archers"]
			if total_casualties > 0:
				combat_text += "  Casualties: "
				var parts: Array = []
				if casualties["pikemen"] > 0:
					parts.append("%d Pike" % casualties["pikemen"])
				if casualties["cavalry"] > 0:
					parts.append("%d Cav" % casualties["cavalry"])
				if casualties["archers"] > 0:
					parts.append("%d Arch" % casualties["archers"])
				combat_text += ", ".join(parts) + "\n"
			else:
				combat_text += "  Casualties: None\n"
			combat_text += "\n"

	# Format income report
	var income_text := "Manpower: +%d\nGoods: +%d\nSupplies: +%d" % [
		turn_income["manpower"],
		turn_income["goods"],
		turn_income["supplies"]
	]

	# Update labels
	if combat_report_label:
		combat_report_label.text = combat_text.strip_edges()
	if income_report_label:
		income_report_label.text = income_text

	# Show panel
	if turn_report_panel:
		turn_report_panel.show()

func _on_close_report() -> void:
	if turn_report_panel:
		turn_report_panel.hide()

# =============================================================================
# TURN PROCESSING
# =============================================================================

func _on_end_turn() -> void:
	# Reset report data for this turn
	turn_combat_results = []
	turn_income = {"manpower": 0, "goods": 0, "supplies": 0}

	_process_combat()   # Combat first - capture tiles
	_process_income()   # Then collect income (including from newly captured)
	_check_victory()

	if not GameState.game_over:
		GameState.turn_number += 1
		GameState.clear_all_assignments()
		_refresh_all()
		_show_turn_report()

func _process_income() -> void:
	# Capital income
	GameState.add_resource("manpower", Config.CAPITAL_PROD_MANPOWER)
	GameState.add_resource("goods", Config.CAPITAL_PROD_GOODS)
	GameState.add_resource("supplies", Config.CAPITAL_PROD_SUPPLIES)

	# Track capital income for report
	turn_income["manpower"] += Config.CAPITAL_PROD_MANPOWER
	turn_income["goods"] += Config.CAPITAL_PROD_GOODS
	turn_income["supplies"] += Config.CAPITAL_PROD_SUPPLIES

	# Income from owned tiles
	for y in range(Config.GRID_SIZE):
		for x in range(Config.GRID_SIZE):
			var tile: GameState.MapTile = GameState.get_tile(x, y)
			if tile.owner == Config.TileOwner.PLAYER and tile.resource_type != Config.ResourceType.ALL:
				var res_key := _resource_type_to_key(tile.resource_type)
				GameState.add_resource(res_key, tile.production)
				# Track tile income for report
				turn_income[res_key] += tile.production

func _resource_type_to_key(res_type: int) -> String:
	match res_type:
		Config.ResourceType.MANPOWER: return "manpower"
		Config.ResourceType.GOODS: return "goods"
		Config.ResourceType.SUPPLIES: return "supplies"
	return ""

func _process_combat() -> void:
	# Process each border with assigned units
	for coord in GameState.assignments.duplicate():  # Duplicate to avoid modification during iteration
		var assigned := GameState.get_assignment(coord)
		if not GameState.has_assignment(coord):
			continue

		var tile: GameState.MapTile = GameState.get_tile(coord.x, coord.y)
		if tile.owner != Config.TileOwner.NEUTRAL:
			continue  # Already captured somehow

		_resolve_combat(coord, assigned, tile)

func _resolve_combat(coord: Vector2i, attackers: Dictionary, tile: GameState.MapTile) -> void:
	# Calculate attacker power (vs neutral, no RPS)
	var attacker_power: float = (
		attackers["pikemen"] * Config.PIKE_POWER +
		attackers["cavalry"] * Config.CAV_POWER +
		attackers["archers"] * Config.ARCHER_POWER
	)

	var defender_power: float = tile.defense

	if attacker_power <= 0:
		return  # No attack

	# Determine outcome
	var attacker_wins := attacker_power > defender_power

	# Calculate casualties
	var power_ratio: float
	var attacker_casualties_pct: float
	var defender_casualties_pct: float

	if attacker_wins:
		# Attacker wins - defender retreats at 50%
		defender_casualties_pct = Config.RETREAT_THRESHOLD
		# Attacker takes damage proportional to defender's strength
		power_ratio = defender_power / attacker_power
		attacker_casualties_pct = power_ratio * Config.RETREAT_THRESHOLD
	else:
		# Defender wins - attacker retreats at 50%
		attacker_casualties_pct = Config.RETREAT_THRESHOLD
		power_ratio = attacker_power / defender_power
		defender_casualties_pct = power_ratio * Config.RETREAT_THRESHOLD

	# Apply attacker casualties (return survivors to pool)
	var surviving_pike: int = int(ceil(attackers["pikemen"] * (1.0 - attacker_casualties_pct)))
	var surviving_cav: int = int(ceil(attackers["cavalry"] * (1.0 - attacker_casualties_pct)))
	var surviving_archer: int = int(ceil(attackers["archers"] * (1.0 - attacker_casualties_pct)))

	var lost_pike: int = attackers["pikemen"] - surviving_pike
	var lost_cav: int = attackers["cavalry"] - surviving_cav
	var lost_archer: int = attackers["archers"] - surviving_archer

	# Deduct losses from army
	GameState.army["pikemen"] -= lost_pike
	GameState.army["cavalry"] -= lost_cav
	GameState.army["archers"] -= lost_archer

	# If attacker wins, capture tile
	if attacker_wins:
		GameState.set_tile_owner(coord.x, coord.y, Config.TileOwner.PLAYER)

	# Track combat result for report
	var combat_result := {
		"tile": coord,
		"role": "Attacker",
		"victory": attacker_wins,
		"attackers": attackers.duplicate(),
		"defender_power": int(defender_power),
		"casualties": {
			"pikemen": lost_pike,
			"cavalry": lost_cav,
			"archers": lost_archer,
		}
	}
	turn_combat_results.append(combat_result)

func _check_victory() -> void:
	if GameState.check_victory():
		GameState.game_over = true
		var stars := GameState.get_star_rating()
		var star_text := ""
		for i in range(stars):
			star_text += "*"
		if stars == 0:
			star_text = "Complete"

		victory_label.text = "VICTORY!\n\nYou conquered %d tiles\nin %d turns\n\nRating: %s" % [
			GameState.tiles_owned,
			GameState.turn_number,
			star_text
		]
		victory_panel.show()
