# ClashPrototype - Battle System Test

A Godot 4.x tower defense/card battle hybrid game where players spawn units using elixir resources to defeat enemy towers.

## Overview

This is a prototype battle system testing project that implements:
- **Resource Management**: Elixir-based economy with regeneration
- **Unit Spawning**: Lane-based unit deployment system
- **AI Opponents**: Automatic enemy unit spawning
- **Combat System**: Melee and ranged unit interactions
- **Tower Defense**: Protective towers with health systems

## Features

### Core Gameplay
- **Elixir System**: Resource management with regeneration and cost validation
- **Lane-Based Combat**: Three lanes (Top, Middle, Bottom) for strategic unit placement
- **Unit Types**: Archer, Mage, and Warrior units with ranged/melee combat
- **AI Integration**: Opponent units spawn automatically with randomized timing
- **Tower Defense**: Each team has towers that must be protected

### Technical Features
- **Signal-Based Architecture**: Clean communication between game systems
- **Team System**: Player (Team 0) vs Opponent (Team 1)
- **Projectile System**: Ranged combat with projectile physics
- **Spawn Point Management**: Validated unit spawning locations
- **UI System**: Unit control panel and selection circle
- **Resource System**: UnitStats resources for configurable unit attributes

## Current Strengths

1. **Clean Separation of Concerns** - GameManager handles spawning/game flow, Units handle movement/combat
2. **Signal-Based Communication** - Elixir system uses signals for UI updates (good pattern)
3. **Lane-Based Movement** - Units stay in their lanes, simplifying pathing
4. **Resource Management** - Elixir system with regeneration and cost validation
5. **Ranged/Melee Support** - Units can be configured as ranged or melee combatants
6. **AI Integration** - Automatic opponent unit spawning with randomized timing
7. **Unit System Foundation** - UnitBase, UnitStats, BehaviorPattern classes created
8. **Type Annotations** - All functions have proper type hints

## Project Structure

```
project/
|-- scenes/                 # Scene files
|   |-- Main.tscn          # Main game scene
|   |-- unit.tscn          # Unit template
|   |-- Tower.tscn         # Tower structure
|   |-- ending_screen.tscn # Game over screen
|   |-- player.tscn        # Player configuration
|   |-- spawn_ui.tscn      # Spawn interface
|   `-- units/             # Unit scenes
|       |-- cards/         # Unit card scenes
|       |   |-- ally_archer.tscn
|       |   `-- opponent_archer.tscn
|       `-- projectiles/   # Projectile scenes
|           |-- allies_projectile.tscn
|           `-- opponents_projectile.tscn
|
|-- scripts/               # Game logic
|   |-- game_manager.gd    # Core game controller
|   |-- unit.gd            # Unit behavior
|   |-- projectile.gd      # Projectile physics
|   |-- spawn_ui.gd        # User interface
|   |-- card_button.gd     # Card interaction
|   |-- ending_screen.gd   # Game over logic
|   |-- player_in_battle.gd
|   |-- archer.gd         # Archer unit specific
|   |-- core/              # Core unit system
|   |   |-- unit_base.gd   # Abstract base for all units
|   |   |-- unit_stats.gd  # Custom resource for unit stats
|   |   `-- behavior_pattern.gd  # Resource for behavior patterns
|   |-- systems/           # Game systems
|   |   |-- battle_world_link.gd
|   |   `-- tower_manager.gd
|   |-- towers/           # Tower scripts
|   |   `-- tower_base.gd
|   `-- ui/                # UI components
|       |-- unit_control_panel.gd
|       `-- unit_selection_circle.gd
|
|-- resources/             # Game resources
|   `-- unit_stats/        # Unit stat resources
|       |-- archer_player.tres
|       |-- archer_enemy.tres
|       |-- mage_player.tres
|       |-- mage_enemy.tres
|       |-- warrior_player.tres
|       `-- warrior_enemy.tres
|
|-- assets/                # Art and audio resources
|
|-- IMPLEMENTATION_GUIDE.md  # Step-by-step fixes
|-- PROJECT_ANALYSIS.md      # Detailed project analysis
|-- PROJECT_DIFF.md           # Comparison with reference project
|-- UNIT_SYSTEM_PLAN.md        # Complete unit system architecture
`-- problems&and_expect_moves.txt  # Known issues
```

## Getting Started

### Prerequisites
- Godot Engine 4.5 or later
- Vulkan rendering support

### Installation
1. Clone or download this project
2. Open `project.godot` in Godot Engine
3. Press F5 to run the main scene

### Controls
- **Arrow Keys**: Navigate UI
- **Key 1 (po)**: Spawn unit in Top lane
- **Key 2 (pu)**: Spawn unit in Middle lane
- **Key 3 (py)**: Spawn unit in Bottom lane
- **Space (spawn_ai_unit)**: Trigger AI unit spawn

## Current Status

### Working Features
- [x] Elixir regeneration system
- [x] Unit spawning mechanics
- [x] Lane-based movement
- [x] Basic combat system
- [x] AI opponent spawning
- [x] Tower health system
- [x] Projectile physics
- [x] Unit system foundation (UnitBase, UnitStats, BehaviorPattern)
- [x] Type annotations on all functions
- [x] Better organized scene structure (`scenes/units/`)

### Critical Issues

1. **Elixir System Decoupling**
   - **Problem**: Elixir continues regenerating even when unit cap is reached
   - **File**: `game_manager.gd`
   - **Impact**: Players can hoard resources indefinitely but can't spend them

2. **Hardcoded Team Values**
   - **Problem**: Team IDs (0/1) hardcoded throughout; difficult to extend
   - **Files**: game_manager.gd, unit.gd, tower_base.gd
   - **Impact**: Adding 3+ teams requires refactoring multiple files

3. **Spawn Point Node Names are Hardcoded**
   - **File**: game_manager.gd
   - **Problem**: `L_Top`, `L_Middle`, `L_Bottom` spawn points are hardcoded strings
   - **Impact**: Typo or missing spawn point = silent Vector2.ZERO failure with warning

4. **No Unit Count Limit**
   - **Problem**: Can spawn infinite units
   - **Impact**: Performance degradation, unpredictable gameplay

5. **Input Actions Defined**
   - **Status**: InputMap now has `po`, `pu`, `py` for lane spawning and `spawn_ai_unit` for AI trigger

### Design Issues

1. **Missing Health UI**
   - No visual feedback for tower/unit health
   - Players don't know when towers are in danger

2. **Limited Unit Variety**
   - Only Archer units currently available in card system
   - Mage and Warrior stat resources exist but not fully integrated

3. **No Wave/Round System**
   - No clear progression or difficulty scaling
   - Game could run indefinitely

4. **Placeholder Text UI**
   - Shows development stage; needs localization

## Recommended Improvements

### Priority 1: Critical Gameplay Fixes

#### Fix Elixir & Spawn Limits
```gdscript
# In game_manager.gd
const MAX_UNITS_PER_TEAM: int = 10
var unit_counts: Dictionary = {0: 0, 1: 0}

func try_spawn_unit(packed_scene: PackedScene, pos: Vector2, team: int, lane: int) -> bool:
	# Check spawn limit
	if unit_counts[team] >= MAX_UNITS_PER_TEAM:
		show_message("Unit limit reached!")
		return false
	
	# Check elixir (only for player)
	if team == local_team and not elixir.try_consume(ELIXIR_COST):
		show_message("Not enough Elixir")
		return false
	
	# Spawn unit
	_create_unit_instance(packed_scene, pos, team, lane)
	unit_counts[team] += 1
	return true

# Connect unit death signal
signal unit_died(unit)
# In unit.gd die():
	GameManager.on_unit_died(self)
```

#### Fix Input Handling
```gdscript
# In game_manager.gd _input()
if event.is_action_pressed("ui_select"):  # Use standard action
	var pos = get_spawn_point(local_team, 0)
	if pos != Vector2.ZERO:
		try_spawn_unit(AVAILABLE_CARDS[0], pos, local_team, 0)
	else:
		push_error("Cannot spawn: invalid spawn point")
```

#### Fix Spawn Point System
```gdscript
# Create a SpawnPointManager class
class_name SpawnPointManager
extends Node2D

var spawn_points: Dictionary = {}

func _ready():
	# Cache spawn points
	for child in get_children():
		spawn_points[child.name] = child.global_position

func get_spawn_point(team: int, lane: int) -> Vector2:
	var key = "Team%d_Lane%d" % [team, lane]
	if key not in spawn_points:
		push_error("Missing spawn point: " + key)
		return Vector2.ZERO
	return spawn_points[key]
```

### Priority 2: Code Quality & Architecture

#### Remove Hardcoded Team Values
```gdscript
# Create constants.gd
class_name GameConstants
const TEAM_PLAYER: int = 0
const TEAM_OPPONENT: int = 1
const TEAMS: Array = [TEAM_PLAYER, TEAM_OPPONENT]

const LANES = {
	"TOP": 0,
	"MIDDLE": 1,
	"BOTTOM": 2
}
```

Use throughout:
```gdscript
if team == GameConstants.TEAM_PLAYER:
	allies_container.add_child(unit)
```

#### Create CardData System
```gdscript
# card_data.gd
class_name CardData
extends Resource

@export var name: String
@export var cost: int = 3
@export var scene: PackedScene
@export var description: String

# In game_manager.gd
const CARDS: Array[CardData] = [
	preload("res://data/archer.tres"),
	preload("res://data/tank.tres"),
]
```

#### Add Unit Management System
```gdscript
# unit_manager.gd
class_name UnitManager extends Node

var units_by_team: Dictionary = {0: [], 1: []}

func register_unit(unit: Node, team: int):
	units_by_team[team].append(unit)
	unit.died.connect(func(): unregister_unit(unit, team))

func unregister_unit(unit: Node, team: int):
	units_by_team[team].erase(unit)

func get_team_units(team: int) -> Array:
	return units_by_team[team]

func get_unit_count(team: int) -> int:
	return units_by_team[team].size()
```

### Priority 3: Feature Additions

#### Wave System
```gdscript
# wave_manager.gd
class_name WaveManager extends Node

var current_wave: int = 1
var wave_timer: float = 0.0
var wave_duration: float = 60.0

signal wave_started(wave: int)
signal wave_ended

func _process(delta):
	wave_timer += delta
	if wave_timer >= wave_duration:
		start_next_wave()

func start_next_wave():
	current_wave += 1
	wave_timer = 0.0
	# Increase difficulty
	emit_signal("wave_started", current_wave)
	GameManager.ai_cooldown_min = max(0.5, GameConstants.AI_COOLDOWN_MIN - current_wave * 0.1)
```

#### Health UI for Towers
```gdscript
# tower_hud.gd
@onready var tower = get_parent()
@onready var health_bar = $HealthBar

func _ready():
	tower.hp_changed.connect(on_hp_changed)

func on_hp_changed(new_hp: int):
	health_bar.value = (new_hp / float(tower.hp)) * 100
	
	if new_hp <= tower.max_hp * 0.25:
		health_bar.self_modulate = Color.RED
	elif new_hp <= tower.max_hp * 0.5:
		health_bar.self_modulate = Color.YELLOW
```

#### Event Logging System
```gdscript
# Add to game_manager.gd
func log_event(event_type: String, details: String):
	print("[%s] %s: %s" % [Time.get_ticks_msec(), event_type, details])
	# Later: save to file or send to analytics
```

### Quick Wins (Easy Fixes)

1. **Rename spawn points**: Use English names (L_Top -> PlayerTopLane)
2. **Add spawn feedback**: Show message when spawning successfully
3. **Fix input action**: Use `ui_select` or define "spawn_unit" action
4. **Add debug panel**: Show current unit counts, elixir, wave info
5. **Consistent naming**: Use snake_case for all variables

### Already Completed
- UnitBase, UnitStats, BehaviorPattern classes created in scripts/core/
- Type annotations added to all functions
- Scene structure organized with units/ directory

## Development

### Key Scripts

#### `game_manager.gd`
Central game controller handling:
- Unit spawning and validation
- Elixir management
- AI opponent logic
- Game flow coordination

#### `unit.gd`
Unit behavior implementation:
- Lane-based movement
- Target acquisition
- Combat mechanics
- Death handling

#### `tower.gd`
Tower defense system:
- Health management
- Damage reception
- Destruction events

### Extending the Project

#### Adding New Units
1. Create new unit scene in `scenes/units/cards/`
2. Configure UnitStats resource (health, damage, speed, attack type)
3. Attach UnitBase script to scene
4. Add to `AVAILABLE_CARDS` array in `game_manager.gd`
5. Update UI to display new card options

#### Implementing Card System
1. Create `CardData` resource class (optional, current uses UnitStats)
2. Define card properties (cost, description, scene)
3. Replace hardcoded `AVAILABLE_CARDS` with resource-based system
4. Update UI to display card information

#### Adding Wave System
1. Create `wave_manager.gd` script
2. Implement wave progression and difficulty scaling
3. Add wave UI elements
4. Connect to game end conditions

## Testing Checklist

- [ ] Player can spawn units with "spawn_unit" action (not "po")
- [ ] Elixir regenerates correctly
- [ ] Units stop spawning after reaching limit
- [ ] Units move to correct lanes
- [ ] Units chase enemies in their lane
- [ ] Units attack towers as fallback
- [ ] AI spawns opponents at intervals
- [ ] Towers take damage and report destroyed event
- [ ] No Vector2.ZERO errors in spawn point system

### Debug Features
The project includes debug capabilities:
- Console logging for spawn points
- Error reporting for missing actions
- Unit tracking and validation

## Contributing

When contributing to this project:
1. Follow existing code style (snake_case for variables)
2. Use signals for inter-system communication
3. Add error handling for edge cases
4. Update documentation for new features
5. Test with both player and AI scenarios

## License

This project is a prototype for educational and testing purposes.

## Future Development

### Planned Features
- [ ] Tank unit type
- [ ] Card collection system
- [ ] Wave-based progression
- [ ] Visual health bars
- [ ] Sound effects and music
- [ ] Particle effects
- [ ] Save/load system
- [ ] Multiplayer support
- [ ] Mage unit integration
- [ ] Warrior unit integration

### Architecture Improvements
- [ ] Remove hardcoded team values
- [ ] Implement constants system
- [ ] Create unit management system
- [ ] Add event logging
- [ ] Improve error handling

---

**Note**: This is currently a test/prototype project. See `IMPLEMENTATION_GUIDE.md` for quick fixes to make the game fully functional. This README now includes content merged from `PROJECT_ANALYSIS.md`.
