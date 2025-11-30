extends Control
## Main Game Controller - UI and Game Flow

# =============================================================================
# NODE REFERENCES (set in _ready via get_node)
# =============================================================================

var map_container: GridContainer
var tile_buttons: Array = []  # 2D array of Button references

# Info panel
var turn_label: Label
var tiles_label: RichTextLabel
var manpower_label: RichTextLabel
var goods_label: RichTextLabel
var supplies_label: RichTextLabel
var pikemen_label: RichTextLabel
var cavalry_label: RichTextLabel
var archers_label: RichTextLabel

# Tile info
var tile_info_panel: PanelContainer
var tile_info_label: Label

# Train units button
var train_units_btn: Button

# Training panel
var training_panel: PanelContainer
var manpower_draft_label: RichTextLabel
var goods_draft_label: RichTextLabel
var supplies_draft_label: RichTextLabel
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
var combat_report_label: RichTextLabel
var income_report_label: RichTextLabel
var close_report_btn: Button

# Turn report data
var turn_combat_results: Array = []  # Array of combat result dictionaries
var turn_income: Dictionary = {"manpower": 0, "goods": 0, "supplies": 0}

# Assignment panel (floating tooltip)
var assign_panel: PanelContainer
var pike_slider: HSlider
var pike_label: RichTextLabel
var cav_slider: HSlider
var cav_label: RichTextLabel
var archer_slider: HSlider
var archer_label: RichTextLabel

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
	"ai": Color(0.85, 0.29, 0.29),           # Red
}

# Preloaded icon textures for tiles
var RESOURCE_ICON_TEXTURES := {}
var ICON_SHIELD: Texture2D
var ICON_SWORDS: Texture2D

func _load_icon_textures() -> void:
	RESOURCE_ICON_TEXTURES = {
		Config.ResourceType.MANPOWER: load("res://assets/icons/pickaxe.svg"),
		Config.ResourceType.GOODS: load("res://assets/icons/gear.svg"),
		Config.ResourceType.SUPPLIES: load("res://assets/icons/bread.svg"),
		Config.ResourceType.ALL: null,  # Capital uses no icon, just "*"
	}
	ICON_SHIELD = load("res://assets/icons/shield.svg")
	ICON_SWORDS = load("res://assets/icons/swords.svg")

# Icon BBCode helpers
const ICON_PICKAXE := "[img=30]res://assets/icons/pickaxe.svg[/img]"
const ICON_GEAR := "[img=30]res://assets/icons/gear.svg[/img]"
const ICON_BREAD := "[img=30]res://assets/icons/bread.svg[/img]"
const ICON_DAGGER := "[img=30]res://assets/icons/dagger.svg[/img]"
const ICON_HORSE := "[img=30]res://assets/icons/horse.svg[/img]"
const ICON_BOW := "[img=30]res://assets/icons/bow.svg[/img]"
const ICON_BLUE := "[img=30]res://assets/icons/blue_circle.svg[/img]"
const ICON_RED := "[img=14]res://assets/icons/red_circle.svg[/img]"

# Helper to set BBCode text on RichTextLabel
func _set_bbcode(label: RichTextLabel, bbcode: String) -> void:
	label.clear()
	label.append_text(bbcode)

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_load_icon_textures()
	_get_node_references()
	_init_static_bbcode_labels()
	_connect_signals()
	_start_new_game()

func _init_static_bbcode_labels() -> void:
	# Training panel - unit info labels need BBCode re-parsed at runtime
	var pike_name := get_node_or_null("TrainingPanel/VBox/UnitsContainer/PikeRow/PikeInfo/PikeName") as RichTextLabel
	var pike_cost := get_node_or_null("TrainingPanel/VBox/UnitsContainer/PikeRow/PikeInfo/PikeCost") as RichTextLabel
	var pike_rps := get_node_or_null("TrainingPanel/VBox/UnitsContainer/PikeRow/PikeInfo/PikeRPS") as RichTextLabel
	var cav_name := get_node_or_null("TrainingPanel/VBox/UnitsContainer/CavRow/CavInfo/CavName") as RichTextLabel
	var cav_cost := get_node_or_null("TrainingPanel/VBox/UnitsContainer/CavRow/CavInfo/CavCost") as RichTextLabel
	var cav_rps := get_node_or_null("TrainingPanel/VBox/UnitsContainer/CavRow/CavInfo/CavRPS") as RichTextLabel
	var archer_name := get_node_or_null("TrainingPanel/VBox/UnitsContainer/ArcherRow/ArcherInfo/ArcherName") as RichTextLabel
	var archer_cost := get_node_or_null("TrainingPanel/VBox/UnitsContainer/ArcherRow/ArcherInfo/ArcherCost") as RichTextLabel
	var archer_rps := get_node_or_null("TrainingPanel/VBox/UnitsContainer/ArcherRow/ArcherInfo/ArcherRPS") as RichTextLabel

	# Help panel
	var help_label := get_node_or_null("HelpPanel/VBox/HelpLabel") as RichTextLabel

	# Set BBCode content for training panel
	if pike_name:
		_set_bbcode(pike_name, "%s PIKEMAN" % ICON_DAGGER)
	if pike_cost:
		_set_bbcode(pike_cost, "Cost: %s5 %s2 %s3  |  Power: 10" % [ICON_PICKAXE, ICON_GEAR, ICON_BREAD])
	if pike_rps:
		_set_bbcode(pike_rps, "Strong vs: %s  |  Weak vs: %s" % [ICON_HORSE, ICON_BOW])

	if cav_name:
		_set_bbcode(cav_name, "%s CAVALRY" % ICON_HORSE)
	if cav_cost:
		_set_bbcode(cav_cost, "Cost: %s8 %s5 %s5  |  Power: 15" % [ICON_PICKAXE, ICON_GEAR, ICON_BREAD])
	if cav_rps:
		_set_bbcode(cav_rps, "Strong vs: %s  |  Weak vs: %s" % [ICON_BOW, ICON_DAGGER])

	if archer_name:
		_set_bbcode(archer_name, "%s ARCHER" % ICON_BOW)
	if archer_cost:
		_set_bbcode(archer_cost, "Cost: %s4 %s4 %s2  |  Power: 8" % [ICON_PICKAXE, ICON_GEAR, ICON_BREAD])
	if archer_rps:
		_set_bbcode(archer_rps, "Strong vs: %s  |  Weak vs: %s" % [ICON_DAGGER, ICON_HORSE])

	# Help panel
	if help_label:
		_set_bbcode(help_label, "[center]GOAL: Eliminate the enemy (%s red)!\n\nClick a border tile to select it.\nUse sliders to assign units.\nPress END TURN to finish your turn and resolve combat.\n\nTiles give resources each turn.\nSpend resources to train new units.\nYou can attack multiple tiles per turn.\n\nCombat: stronger army wins.\nThe enemy AI also expands and attacks![/center]" % ICON_RED)

	# Initialize draft resource labels (they get updated in _update_training_display but need initial setup)
	if manpower_draft_label:
		_set_bbcode(manpower_draft_label, "%s %d" % [ICON_PICKAXE, GameState.get_resource("manpower")])
	if goods_draft_label:
		_set_bbcode(goods_draft_label, "%s %d" % [ICON_GEAR, GameState.get_resource("goods")])
	if supplies_draft_label:
		_set_bbcode(supplies_draft_label, "%s %d" % [ICON_BREAD, GameState.get_resource("supplies")])

func _get_node_references() -> void:
	# Use get_node_or_null to avoid crashes if nodes don't exist
	map_container = get_node_or_null("GameContainer/MapPanel/MapContainer")
	if not map_container:
		push_error("MapContainer not found!")
		return

	turn_label = get_node_or_null("TurnLabel")
	tiles_label = get_node_or_null("GameContainer/RightPanel/TilesLabel")
	manpower_label = get_node_or_null("GameContainer/RightPanel/ManpowerLabel")
	goods_label = get_node_or_null("GameContainer/RightPanel/GoodsLabel")
	supplies_label = get_node_or_null("GameContainer/RightPanel/SuppliesLabel")
	pikemen_label = get_node_or_null("GameContainer/RightPanel/PikemenLabel")
	cavalry_label = get_node_or_null("GameContainer/RightPanel/CavalryLabel")
	archers_label = get_node_or_null("GameContainer/RightPanel/ArchersLabel")

	tile_info_panel = get_node_or_null("GameContainer/RightPanel/TileInfoPanel")
	tile_info_label = get_node_or_null("GameContainer/RightPanel/TileInfoPanel/TileInfoLabel")

	train_units_btn = get_node_or_null("BottomButtons/TrainUnitsBtn")

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

	assign_panel = get_node_or_null("AssignPanel")
	pike_slider = get_node_or_null("AssignPanel/VBox/PikeRow/PikeSlider")
	pike_label = get_node_or_null("AssignPanel/VBox/PikeRow/PikeLabel")
	cav_slider = get_node_or_null("AssignPanel/VBox/CavRow/CavSlider")
	cav_label = get_node_or_null("AssignPanel/VBox/CavRow/CavLabel")
	archer_slider = get_node_or_null("AssignPanel/VBox/ArcherRow/ArcherSlider")
	archer_label = get_node_or_null("AssignPanel/VBox/ArcherRow/ArcherLabel")

	end_turn_btn = get_node_or_null("BottomButtons/EndTurnBtn")

	victory_panel = get_node_or_null("VictoryPanel")
	victory_label = get_node_or_null("VictoryPanel/VictoryLabel")

	help_btn = get_node_or_null("TopLeftButtons/HelpBtn")
	help_panel = get_node_or_null("HelpPanel")
	close_help_btn = get_node_or_null("HelpPanel/VBox/CloseHelpBtn")
	new_game_btn = get_node_or_null("TopLeftButtons/NewGameBtn")

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
		help_panel.show()
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

	# Create grid of buttons with icon containers
	for y in range(Config.GRID_SIZE):
		var row: Array = []
		for x in range(Config.GRID_SIZE):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			btn.pressed.connect(_on_tile_clicked.bind(x, y))
			btn.clip_text = true

			# Create VBox container for icons/labels
			var vbox := VBoxContainer.new()
			vbox.name = "VBox"
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			btn.add_child(vbox)

			# Resource row (icon + production)
			var res_row := HBoxContainer.new()
			res_row.name = "ResRow"
			res_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			res_row.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.add_child(res_row)

			var res_icon := TextureRect.new()
			res_icon.name = "ResIcon"
			res_icon.custom_minimum_size = Vector2(30, 30)
			res_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			res_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			res_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			res_row.add_child(res_icon)

			var prod_label := Label.new()
			prod_label.name = "ProdLabel"
			prod_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			res_row.add_child(prod_label)

			# Defense row (icon + value) - for neutral tiles
			var def_row := HBoxContainer.new()
			def_row.name = "DefRow"
			def_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			def_row.alignment = BoxContainer.ALIGNMENT_CENTER
			def_row.visible = false
			vbox.add_child(def_row)

			var def_icon := TextureRect.new()
			def_icon.name = "DefIcon"
			def_icon.custom_minimum_size = Vector2(24, 24)
			def_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			def_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			def_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			def_row.add_child(def_icon)

			var def_label := Label.new()
			def_label.name = "DefLabel"
			def_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			def_row.add_child(def_label)

			# Assignment indicator (swords icon) - overlay on entire tile
			var assign_icon := TextureRect.new()
			assign_icon.name = "AssignIcon"
			assign_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
			assign_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			assign_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			assign_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			assign_icon.modulate = Color(1, 1, 1, 0.7)  # Semi-transparent
			assign_icon.visible = false
			btn.add_child(assign_icon)

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
	elif tile.owner == Config.TileOwner.AI:
		color = TILE_COLORS["ai"]
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

	# Clear button text (we use custom children now)
	btn.text = ""

	# Get child nodes
	var vbox := btn.get_node("VBox")
	var res_icon: TextureRect = vbox.get_node("ResRow/ResIcon")
	var prod_label: Label = vbox.get_node("ResRow/ProdLabel")
	var def_row: HBoxContainer = vbox.get_node("DefRow")
	var def_icon: TextureRect = vbox.get_node("DefRow/DefIcon")
	var def_label: Label = vbox.get_node("DefRow/DefLabel")
	var assign_icon: TextureRect = btn.get_node("AssignIcon")

	# Set resource icon and production
	var icon_texture: Texture2D = RESOURCE_ICON_TEXTURES.get(tile.resource_type)
	if icon_texture:
		res_icon.texture = icon_texture
		res_icon.visible = true
	else:
		res_icon.visible = false

	# Set production label
	if tile.resource_type == Config.ResourceType.ALL:
		prod_label.text = "*"  # Capital
	else:
		prod_label.text = str(tile.production)

	# Show defense row for neutral/border tiles
	if tile.owner == Config.TileOwner.NEUTRAL:
		def_row.visible = true
		def_icon.texture = ICON_SHIELD
		def_label.text = str(tile.defense)
	else:
		def_row.visible = false

	# Show assignment indicator if units assigned
	if GameState.has_assignment(Vector2i(x, y)):
		assign_icon.texture = ICON_SWORDS
		assign_icon.visible = true
	else:
		assign_icon.visible = false

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
	_set_bbcode(manpower_label, "%s Manpower: %d (+%d)" % [ICON_PICKAXE, GameState.get_resource("manpower"), income["manpower"]])
	_set_bbcode(goods_label, "%s Goods: %d (+%d)" % [ICON_GEAR, GameState.get_resource("goods"), income["goods"]])
	_set_bbcode(supplies_label, "%s Supplies: %d (+%d)" % [ICON_BREAD, GameState.get_resource("supplies"), income["supplies"]])

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
	_set_bbcode(pikemen_label, "%s Pikemen: %d (%d)" % [ICON_DAGGER, available["pikemen"], GameState.army["pikemen"]])
	_set_bbcode(cavalry_label, "%s Cavalry: %d (%d)" % [ICON_HORSE, available["cavalry"], GameState.army["cavalry"]])
	_set_bbcode(archers_label, "%s Archers: %d (%d)" % [ICON_BOW, available["archers"], GameState.army["archers"]])

func _refresh_turn_info() -> void:
	turn_label.text = "Turn: %d" % GameState.turn_number
	_set_bbcode(tiles_label, "Tiles: %s%d vs %s%d" % [ICON_BLUE, GameState.tiles_owned, ICON_RED, GameState.ai_tiles_owned])

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


func _position_assign_panel(coord: Vector2i) -> void:
	if not assign_panel or not map_container:
		return

	# Get the tile button position
	var btn: Button = tile_buttons[coord.y][coord.x]
	var btn_global_pos := btn.global_position
	var btn_size := btn.size

	# Position panel to the right of the tile, or left if not enough space
	var panel_size := assign_panel.size
	var screen_size := get_viewport_rect().size

	var target_pos := Vector2.ZERO

	# Try to position to the right of the tile
	target_pos.x = btn_global_pos.x + btn_size.x + 10

	# If it would go off screen, position to the left
	if target_pos.x + panel_size.x > screen_size.x:
		target_pos.x = btn_global_pos.x - panel_size.x - 10

	# Vertically center on the tile
	target_pos.y = btn_global_pos.y + (btn_size.y / 2) - (panel_size.y / 2)

	# Clamp to screen bounds
	target_pos.y = clamp(target_pos.y, 10, screen_size.y - panel_size.y - 10)
	target_pos.x = clamp(target_pos.x, 10, screen_size.x - panel_size.x - 10)

	assign_panel.global_position = target_pos

func _refresh_assign_panel() -> void:
	var coord := GameState.selected_tile
	if coord == Vector2i(-1, -1) or not GameState.is_border_tile(coord.x, coord.y):
		if assign_panel:
			assign_panel.hide()
		return

	if assign_panel:
		assign_panel.show()
		# Position the panel near the clicked tile
		_position_assign_panel(coord)

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
		_set_bbcode(pike_label, "%s %d" % [ICON_DAGGER, int(assigned["pikemen"])])

	if cav_slider:
		cav_slider.set_block_signals(true)
		cav_slider.max_value = assigned["cavalry"] + available["cavalry"]
		cav_slider.value = assigned["cavalry"]
		cav_slider.set_block_signals(false)
	if cav_label:
		_set_bbcode(cav_label, "%s %d" % [ICON_HORSE, int(assigned["cavalry"])])

	if archer_slider:
		archer_slider.set_block_signals(true)
		archer_slider.max_value = assigned["archers"] + available["archers"]
		archer_slider.value = assigned["archers"]
		archer_slider.set_block_signals(false)
	if archer_label:
		_set_bbcode(archer_label, "%s %d" % [ICON_BOW, int(assigned["archers"])])

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
		_set_bbcode(manpower_draft_label, "%s %d" % [ICON_PICKAXE, remaining_manpower])
	if goods_draft_label:
		_set_bbcode(goods_draft_label, "%s %d" % [ICON_GEAR, remaining_goods])
	if supplies_draft_label:
		_set_bbcode(supplies_draft_label, "%s %d" % [ICON_BREAD, remaining_supplies])

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
	# Update the tile to show/hide assignment icon immediately
	_update_tile_button(coord.x, coord.y)

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
					parts.append("%s%d" % [ICON_DAGGER, casualties["pikemen"]])
				if casualties["cavalry"] > 0:
					parts.append("%s%d" % [ICON_HORSE, casualties["cavalry"]])
				if casualties["archers"] > 0:
					parts.append("%s%d" % [ICON_BOW, casualties["archers"]])
				combat_text += ", ".join(parts) + "\n"
			else:
				combat_text += "  Casualties: None\n"
			combat_text += "\n"

	# Format income report
	var income_text := "%s Manpower: +%d\n%s Goods: +%d\n%s Supplies: +%d" % [
		ICON_PICKAXE, turn_income["manpower"],
		ICON_GEAR, turn_income["goods"],
		ICON_BREAD, turn_income["supplies"]
	]

	# Update labels
	if combat_report_label:
		_set_bbcode(combat_report_label, combat_text.strip_edges())
	if income_report_label:
		_set_bbcode(income_report_label, income_text)

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

	_process_combat()   # Player combat first - capture tiles
	_process_income()   # Then collect player income
	_check_game_over()

	if not GameState.game_over:
		# AI turn
		_process_ai_turn()
		_check_game_over()

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
		if tile.owner == Config.TileOwner.PLAYER:
			continue  # Already owned

		_resolve_combat(coord, assigned, tile)

func _resolve_combat(coord: Vector2i, attackers: Dictionary, tile: GameState.MapTile) -> void:
	# Calculate attacker power
	var attacker_power: float = (
		attackers["pikemen"] * Config.PIKE_POWER +
		attackers["cavalry"] * Config.CAV_POWER +
		attackers["archers"] * Config.ARCHER_POWER
	)

	# Defender power depends on tile type
	var defender_power: float
	var is_ai_tile: bool = tile.owner == Config.TileOwner.AI

	if is_ai_tile:
		# AI defends with its army (simplified: uses total army for any tile defense)
		defender_power = (
			GameState.ai_army["pikemen"] * Config.PIKE_POWER +
			GameState.ai_army["cavalry"] * Config.CAV_POWER +
			GameState.ai_army["archers"] * Config.ARCHER_POWER
		)
	else:
		defender_power = tile.defense

	if attacker_power <= 0:
		return  # No attack

	# Determine outcome
	var attacker_wins := attacker_power > defender_power

	# Calculate casualties
	var power_ratio: float
	var attacker_casualties_pct: float
	var defender_casualties_pct: float

	if attacker_wins:
		defender_casualties_pct = Config.RETREAT_THRESHOLD
		power_ratio = defender_power / max(attacker_power, 1.0)
		attacker_casualties_pct = power_ratio * Config.RETREAT_THRESHOLD
	else:
		attacker_casualties_pct = Config.RETREAT_THRESHOLD
		power_ratio = attacker_power / max(defender_power, 1.0)
		defender_casualties_pct = power_ratio * Config.RETREAT_THRESHOLD

	# Apply attacker casualties
	var surviving_pike: int = int(ceil(attackers["pikemen"] * (1.0 - attacker_casualties_pct)))
	var surviving_cav: int = int(ceil(attackers["cavalry"] * (1.0 - attacker_casualties_pct)))
	var surviving_archer: int = int(ceil(attackers["archers"] * (1.0 - attacker_casualties_pct)))

	var lost_pike: int = attackers["pikemen"] - surviving_pike
	var lost_cav: int = attackers["cavalry"] - surviving_cav
	var lost_archer: int = attackers["archers"] - surviving_archer

	# Deduct losses from player army
	GameState.army["pikemen"] -= lost_pike
	GameState.army["cavalry"] -= lost_cav
	GameState.army["archers"] -= lost_archer

	# Apply defender casualties if AI tile
	if is_ai_tile and attacker_wins:
		var ai_lost_pike: int = int(GameState.ai_army["pikemen"] * defender_casualties_pct)
		var ai_lost_cav: int = int(GameState.ai_army["cavalry"] * defender_casualties_pct)
		var ai_lost_archer: int = int(GameState.ai_army["archers"] * defender_casualties_pct)
		GameState.ai_army["pikemen"] -= ai_lost_pike
		GameState.ai_army["cavalry"] -= ai_lost_cav
		GameState.ai_army["archers"] -= ai_lost_archer

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

func _check_game_over() -> void:
	if GameState.check_victory():
		GameState.game_over = true
		var stars := GameState.get_star_rating()
		var star_text := ""
		for i in range(stars):
			star_text += "⭐"
		if stars == 0:
			star_text = "Complete"

		victory_label.text = "VICTORY!\n\nYou eliminated the enemy\nin %d turns\n\nRating: %s" % [
			GameState.turn_number,
			star_text
		]
		victory_panel.show()
	elif GameState.check_defeat():
		GameState.game_over = true
		victory_label.text = "DEFEAT!\n\nThe enemy conquered\nyour territory\n\nTry again!"
		victory_panel.show()

# =============================================================================
# AI TURN PROCESSING
# =============================================================================

func _process_ai_turn() -> void:
	_ai_collect_income()
	_ai_train_units()
	_ai_attack()

func _ai_collect_income() -> void:
	# Capital income
	GameState.ai_resources["manpower"] += Config.CAPITAL_PROD_MANPOWER
	GameState.ai_resources["goods"] += Config.CAPITAL_PROD_GOODS
	GameState.ai_resources["supplies"] += Config.CAPITAL_PROD_SUPPLIES

	# Income from owned tiles
	for y in range(Config.GRID_SIZE):
		for x in range(Config.GRID_SIZE):
			var tile: GameState.MapTile = GameState.get_tile(x, y)
			if tile.owner == Config.TileOwner.AI and tile.resource_type != Config.ResourceType.ALL:
				var res_key := _resource_type_to_key(tile.resource_type)
				GameState.ai_resources[res_key] += tile.production

func _ai_train_units() -> void:
	# AI spends resources greedily - train as many units as possible
	# Prioritize: pikemen (balanced), then cavalry (power), then archers
	var trained := true
	while trained:
		trained = false

		# Try to train pikeman
		var pike_cost := Config.get_unit_cost(Config.UnitType.PIKEMAN)
		if _ai_can_afford(pike_cost):
			_ai_spend_resources(pike_cost)
			GameState.ai_army["pikemen"] += 1
			trained = true
			continue

		# Try to train archer (cheaper)
		var archer_cost := Config.get_unit_cost(Config.UnitType.ARCHER)
		if _ai_can_afford(archer_cost):
			_ai_spend_resources(archer_cost)
			GameState.ai_army["archers"] += 1
			trained = true
			continue

		# Try to train cavalry
		var cav_cost := Config.get_unit_cost(Config.UnitType.CAVALRY)
		if _ai_can_afford(cav_cost):
			_ai_spend_resources(cav_cost)
			GameState.ai_army["cavalry"] += 1
			trained = true
			continue

func _ai_can_afford(cost: Dictionary) -> bool:
	return (GameState.ai_resources["manpower"] >= cost.get("manpower", 0) and
			GameState.ai_resources["goods"] >= cost.get("goods", 0) and
			GameState.ai_resources["supplies"] >= cost.get("supplies", 0))

func _ai_spend_resources(cost: Dictionary) -> void:
	GameState.ai_resources["manpower"] -= cost.get("manpower", 0)
	GameState.ai_resources["goods"] -= cost.get("goods", 0)
	GameState.ai_resources["supplies"] -= cost.get("supplies", 0)

func _ai_attack() -> void:
	# Get all tiles AI can attack
	var borders := GameState.get_all_ai_borders()
	if borders.is_empty():
		return

	# Simple AI: attack one random border tile with full army
	var target: Vector2i = borders[randi() % borders.size()]
	var tile: GameState.MapTile = GameState.get_tile(target.x, target.y)

	# Calculate AI army power
	var ai_power: float = (
		GameState.ai_army["pikemen"] * Config.PIKE_POWER +
		GameState.ai_army["cavalry"] * Config.CAV_POWER +
		GameState.ai_army["archers"] * Config.ARCHER_POWER
	)

	if ai_power <= 0:
		return  # No army to attack with

	# Determine defender power
	var defender_power: float
	var is_player_tile: bool = tile.owner == Config.TileOwner.PLAYER

	if is_player_tile:
		# Player defends with army
		defender_power = (
			GameState.army["pikemen"] * Config.PIKE_POWER +
			GameState.army["cavalry"] * Config.CAV_POWER +
			GameState.army["archers"] * Config.ARCHER_POWER
		)
	else:
		defender_power = tile.defense

	# Determine outcome
	var ai_wins := ai_power > defender_power

	# Calculate casualties
	var power_ratio: float
	var ai_casualties_pct: float
	var defender_casualties_pct: float

	if ai_wins:
		defender_casualties_pct = Config.RETREAT_THRESHOLD
		power_ratio = defender_power / max(ai_power, 1.0)
		ai_casualties_pct = power_ratio * Config.RETREAT_THRESHOLD
	else:
		ai_casualties_pct = Config.RETREAT_THRESHOLD
		power_ratio = ai_power / max(defender_power, 1.0)
		defender_casualties_pct = power_ratio * Config.RETREAT_THRESHOLD

	# Apply AI casualties
	var ai_lost_pike: int = int(GameState.ai_army["pikemen"] * ai_casualties_pct)
	var ai_lost_cav: int = int(GameState.ai_army["cavalry"] * ai_casualties_pct)
	var ai_lost_archer: int = int(GameState.ai_army["archers"] * ai_casualties_pct)

	GameState.ai_army["pikemen"] -= ai_lost_pike
	GameState.ai_army["cavalry"] -= ai_lost_cav
	GameState.ai_army["archers"] -= ai_lost_archer

	# Apply player casualties if defending player tile
	var player_lost_pike: int = 0
	var player_lost_cav: int = 0
	var player_lost_archer: int = 0
	if is_player_tile and ai_wins:
		player_lost_pike = int(GameState.army["pikemen"] * defender_casualties_pct)
		player_lost_cav = int(GameState.army["cavalry"] * defender_casualties_pct)
		player_lost_archer = int(GameState.army["archers"] * defender_casualties_pct)
		GameState.army["pikemen"] -= player_lost_pike
		GameState.army["cavalry"] -= player_lost_cav
		GameState.army["archers"] -= player_lost_archer

	# If AI wins, capture tile
	if ai_wins:
		GameState.set_tile_owner(target.x, target.y, Config.TileOwner.AI)

	# Only add to combat report if player was involved (defending their tile)
	if is_player_tile:
		var combat_result := {
			"tile": target,
			"role": "Defender",
			"victory": not ai_wins,
			"attackers": {"pikemen": 0, "cavalry": 0, "archers": 0},
			"defender_power": int(ai_power),
			"casualties": {
				"pikemen": player_lost_pike,
				"cavalry": player_lost_cav,
				"archers": player_lost_archer,
			},
		}
		turn_combat_results.append(combat_result)
