extends Node
## Game State - Holds ALL current game data
## No game logic here, just data storage and access functions.

# =============================================================================
# TILE DATA STRUCTURE
# =============================================================================

class MapTile:
	var owner: int  # Config.TileOwner
	var resource_type: int  # Config.ResourceType
	var production: int
	var defense: int

	func _init(p_owner: int, p_resource: int, p_production: int, p_defense: int) -> void:
		owner = p_owner
		resource_type = p_resource
		production = p_production
		defense = p_defense

# =============================================================================
# STATE VARIABLES
# =============================================================================

# Map data: 2D array of MapTile
var tiles: Array = []

# Player resources
var resources: Dictionary = {
	"manpower": 0,
	"goods": 0,
	"supplies": 0
}

# Player army pool
var army: Dictionary = {
	"pikemen": 0,
	"cavalry": 0,
	"archers": 0
}

# Current turn assignments: tile_coord -> {pikemen, cavalry, archers}
var assignments: Dictionary = {}

# Game progress
var turn_number: int = 1
var tiles_owned: int = 1
var game_over: bool = false

# UI state
var selected_tile: Vector2i = Vector2i(-1, -1)

# =============================================================================
# INITIALIZATION
# =============================================================================

func reset_to_initial_state() -> void:
	_generate_map()
	_set_starting_resources()
	_set_starting_army()
	assignments.clear()
	turn_number = 1
	tiles_owned = 1
	game_over = false
	selected_tile = Vector2i(-1, -1)

func _generate_map() -> void:
	tiles.clear()

	for y in range(Config.GRID_SIZE):
		var row: Array = []
		for x in range(Config.GRID_SIZE):
			var tile: MapTile = _create_tile(x, y)
			row.append(tile)
		tiles.append(row)

func _create_tile(x: int, y: int) -> MapTile:
	var pos := Vector2i(x, y)

	# Capital tile
	if pos == Config.CAPITAL_POSITION:
		return MapTile.new(
			Config.TileOwner.PLAYER,
			Config.ResourceType.ALL,
			0,  # Special handling for capital production
			0   # No defense for player tiles
		)

	# Neutral tile
	var resource_type: int = randi_range(0, 2)  # MANPOWER, MATERIALS, or FOOD
	var production: int = _calculate_production()
	var defense: int = _calculate_defense(pos)

	return MapTile.new(
		Config.TileOwner.NEUTRAL,
		resource_type,
		production,
		defense
	)

func _calculate_production() -> int:
	var base: float = Config.TILE_PROD_BASE
	var variance: float = Config.TILE_PROD_VARIANCE
	var multiplier: float = randf_range(1.0 - variance, 1.0 + variance)
	return int(round(base * multiplier))

func _calculate_defense(pos: Vector2i) -> int:
	var capital: Vector2i = Config.CAPITAL_POSITION
	# Chebyshev distance (diagonal counts as 1)
	var distance: int = max(abs(pos.x - capital.x), abs(pos.y - capital.y))
	var defense_range: Vector2i = Config.get_defense_range(distance)
	return randi_range(defense_range.x, defense_range.y)

func _set_starting_resources() -> void:
	resources["manpower"] = Config.START_MANPOWER
	resources["goods"] = Config.START_GOODS
	resources["supplies"] = Config.START_SUPPLIES

func _set_starting_army() -> void:
	army["pikemen"] = Config.START_PIKEMEN
	army["cavalry"] = Config.START_CAVALRY
	army["archers"] = Config.START_ARCHERS

# =============================================================================
# TILE ACCESS
# =============================================================================

func get_tile(x: int, y: int) -> MapTile:
	if x < 0 or x >= Config.GRID_SIZE or y < 0 or y >= Config.GRID_SIZE:
		return null
	return tiles[y][x]

func set_tile_owner(x: int, y: int, new_owner: int) -> void:
	var tile := get_tile(x, y)
	if tile:
		tile.owner = new_owner
		if new_owner == Config.TileOwner.PLAYER:
			tiles_owned += 1

func is_valid_coord(x: int, y: int) -> bool:
	return x >= 0 and x < Config.GRID_SIZE and y >= 0 and y < Config.GRID_SIZE

# =============================================================================
# RESOURCE ACCESS
# =============================================================================

func get_resource(type: String) -> int:
	return resources.get(type, 0)

func set_resource(type: String, amount: int) -> void:
	resources[type] = amount

func add_resource(type: String, amount: int) -> void:
	resources[type] = resources.get(type, 0) + amount

func can_afford(cost: Dictionary) -> bool:
	return (resources["manpower"] >= cost.get("manpower", 0) and
			resources["goods"] >= cost.get("goods", 0) and
			resources["supplies"] >= cost.get("supplies", 0))

func spend_resources(cost: Dictionary) -> void:
	resources["manpower"] -= cost.get("manpower", 0)
	resources["goods"] -= cost.get("goods", 0)
	resources["supplies"] -= cost.get("supplies", 0)

# =============================================================================
# ARMY ACCESS
# =============================================================================

func get_army_count(unit_type: String) -> int:
	return army.get(unit_type, 0)

func set_army_count(unit_type: String, amount: int) -> void:
	army[unit_type] = amount

func add_army(unit_type: String, amount: int) -> void:
	army[unit_type] = army.get(unit_type, 0) + amount

func get_available_army() -> Dictionary:
	# Returns army minus what's already assigned
	var available := army.duplicate()
	for coord in assignments:
		var assigned: Dictionary = assignments[coord]
		available["pikemen"] -= assigned.get("pikemen", 0)
		available["cavalry"] -= assigned.get("cavalry", 0)
		available["archers"] -= assigned.get("archers", 0)
	return available

func get_total_army_size() -> int:
	return army["pikemen"] + army["cavalry"] + army["archers"]

# =============================================================================
# ASSIGNMENT ACCESS
# =============================================================================

func get_assignment(coord: Vector2i) -> Dictionary:
	return assignments.get(coord, {"pikemen": 0, "cavalry": 0, "archers": 0})

func set_assignment(coord: Vector2i, units: Dictionary) -> void:
	assignments[coord] = units

func clear_assignment(coord: Vector2i) -> void:
	assignments.erase(coord)

func clear_all_assignments() -> void:
	assignments.clear()

func has_assignment(coord: Vector2i) -> bool:
	var assigned := get_assignment(coord)
	return assigned["pikemen"] > 0 or assigned["cavalry"] > 0 or assigned["archers"] > 0

# =============================================================================
# BORDER DETECTION
# =============================================================================

func get_adjacent_coords(x: int, y: int) -> Array[Vector2i]:
	var adjacent: Array[Vector2i] = []
	var directions: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	for dir in directions:
		var nx: int = x + dir.x
		var ny: int = y + dir.y
		if is_valid_coord(nx, ny):
			adjacent.append(Vector2i(nx, ny))

	return adjacent

func is_border_tile(x: int, y: int) -> bool:
	var tile := get_tile(x, y)
	if not tile or tile.owner != Config.TileOwner.NEUTRAL:
		return false

	# Check if any adjacent tile is owned by player
	for adj in get_adjacent_coords(x, y):
		var adj_tile := get_tile(adj.x, adj.y)
		if adj_tile and adj_tile.owner == Config.TileOwner.PLAYER:
			return true

	return false

func get_all_borders() -> Array[Vector2i]:
	var borders: Array[Vector2i] = []
	for y in range(Config.GRID_SIZE):
		for x in range(Config.GRID_SIZE):
			if is_border_tile(x, y):
				borders.append(Vector2i(x, y))
	return borders

# =============================================================================
# GAME STATUS
# =============================================================================

func check_victory() -> bool:
	return tiles_owned >= Config.TARGET_TILES

func get_star_rating() -> int:
	if turn_number <= Config.RATING_PERFECT_TURNS:
		return 3
	elif turn_number <= Config.RATING_GREAT_TURNS:
		return 2
	elif turn_number <= Config.RATING_GOOD_TURNS:
		return 1
	else:
		return 0
