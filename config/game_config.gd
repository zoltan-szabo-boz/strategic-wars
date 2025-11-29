extends Node
## Game Configuration - ALL BALANCE VALUES IN ONE PLACE
## Change values here to tweak game balance without touching game logic.

# =============================================================================
# MAP SETTINGS
# =============================================================================

const GRID_SIZE: int = 7
const CAPITAL_POSITION: Vector2i = Vector2i(1, 1)

# =============================================================================
# DEFENSE SETTINGS (by ring/distance from capital)
# =============================================================================

# Ring 1: tiles adjacent to capital (distance 1)
const DEFENSE_RING_1_MIN: int = 20
const DEFENSE_RING_1_MAX: int = 30

# Ring 2: 2 tiles away
const DEFENSE_RING_2_MIN: int = 30
const DEFENSE_RING_2_MAX: int = 40

# Ring 3: 3 tiles away
const DEFENSE_RING_3_MIN: int = 40
const DEFENSE_RING_3_MAX: int = 50

# Ring 4+: 4 or more tiles away
const DEFENSE_RING_4_MIN: int = 50
const DEFENSE_RING_4_MAX: int = 60

# =============================================================================
# RESOURCE PRODUCTION
# =============================================================================

# Capital produces all 3 resources at these rates
const CAPITAL_PROD_MANPOWER: int = 3
const CAPITAL_PROD_GOODS: int = 2
const CAPITAL_PROD_SUPPLIES: int = 2

# Normal tiles produce one resource type
const TILE_PROD_BASE: int = 5
const TILE_PROD_VARIANCE: float = 0.2  # +/- 20%

# =============================================================================
# UNIT COSTS
# =============================================================================

# Pikeman: Cheap, balanced, defensive
const PIKE_COST_MANPOWER: int = 5
const PIKE_COST_GOODS: int = 2
const PIKE_COST_SUPPLIES: int = 3

# Cavalry: Expensive, powerful
const CAV_COST_MANPOWER: int = 8
const CAV_COST_GOODS: int = 5
const CAV_COST_SUPPLIES: int = 5

# Archer: Cheapest supplies cost, lowest power
const ARCHER_COST_MANPOWER: int = 4
const ARCHER_COST_GOODS: int = 4
const ARCHER_COST_SUPPLIES: int = 2

# =============================================================================
# UNIT POWER
# =============================================================================

const PIKE_POWER: int = 10
const CAV_POWER: int = 15
const ARCHER_POWER: int = 8

# =============================================================================
# COMBAT MODIFIERS
# =============================================================================

# Rock-Paper-Scissors: Pike > Cav > Archer > Pike
const RPS_STRONG_MULTIPLIER: float = 1.5  # 150% damage vs weak type
const RPS_WEAK_MULTIPLIER: float = 0.5    # 50% damage vs strong type
const RETREAT_THRESHOLD: float = 0.5       # Retreat at 50% casualties

# =============================================================================
# STARTING CONDITIONS
# =============================================================================

const START_MANPOWER: int = 30
const START_GOODS: int = 20
const START_SUPPLIES: int = 25

const START_PIKEMEN: int = 2
const START_CAVALRY: int = 1
const START_ARCHERS: int = 2

# =============================================================================
# VICTORY CONDITIONS
# =============================================================================

const TARGET_TILES: int = 25

# Star ratings based on turn count (lower is better)
const RATING_PERFECT_TURNS: int = 15  # 3 stars
const RATING_GREAT_TURNS: int = 20    # 2 stars
const RATING_GOOD_TURNS: int = 30     # 1 star

# =============================================================================
# ENUMS (used by game_state and game_logic)
# =============================================================================

enum TileOwner { NEUTRAL, PLAYER }
enum ResourceType { MANPOWER, GOODS, SUPPLIES, ALL }
enum UnitType { PIKEMAN, CAVALRY, ARCHER }

# =============================================================================
# RPS RELATIONSHIPS
# =============================================================================

# Returns what unit type this type is STRONG against
func get_strong_against(unit: UnitType) -> UnitType:
	match unit:
		UnitType.PIKEMAN: return UnitType.CAVALRY
		UnitType.CAVALRY: return UnitType.ARCHER
		UnitType.ARCHER: return UnitType.PIKEMAN
	return unit

# Returns what unit type this type is WEAK against
func get_weak_against(unit: UnitType) -> UnitType:
	match unit:
		UnitType.PIKEMAN: return UnitType.ARCHER
		UnitType.CAVALRY: return UnitType.PIKEMAN
		UnitType.ARCHER: return UnitType.CAVALRY
	return unit

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Get defense range for a given distance from capital
func get_defense_range(distance: int) -> Vector2i:
	match distance:
		1: return Vector2i(DEFENSE_RING_1_MIN, DEFENSE_RING_1_MAX)
		2: return Vector2i(DEFENSE_RING_2_MIN, DEFENSE_RING_2_MAX)
		3: return Vector2i(DEFENSE_RING_3_MIN, DEFENSE_RING_3_MAX)
		_: return Vector2i(DEFENSE_RING_4_MIN, DEFENSE_RING_4_MAX)

# Get unit cost as dictionary
func get_unit_cost(unit: UnitType) -> Dictionary:
	match unit:
		UnitType.PIKEMAN:
			return {"manpower": PIKE_COST_MANPOWER, "goods": PIKE_COST_GOODS, "supplies": PIKE_COST_SUPPLIES}
		UnitType.CAVALRY:
			return {"manpower": CAV_COST_MANPOWER, "goods": CAV_COST_GOODS, "supplies": CAV_COST_SUPPLIES}
		UnitType.ARCHER:
			return {"manpower": ARCHER_COST_MANPOWER, "goods": ARCHER_COST_GOODS, "supplies": ARCHER_COST_SUPPLIES}
	return {}

# Get unit power
func get_unit_power(unit: UnitType) -> int:
	match unit:
		UnitType.PIKEMAN: return PIKE_POWER
		UnitType.CAVALRY: return CAV_POWER
		UnitType.ARCHER: return ARCHER_POWER
	return 0
