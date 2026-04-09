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
- **Unit Types**: Currently supports Archer units with ranged combat
- **AI Integration**: Opponent units spawn automatically with randomized timing
- **Tower Defense**: Each team has towers that must be protected

### Technical Features
- **Signal-Based Architecture**: Clean communication between game systems
- **Team System**: Player (Team 0) vs Opponent (Team 1)
- **Projectile System**: Ranged combat with projectile physics
- **Spawn Point Management**: Validated unit spawning locations

## Project Structure

```
project/
|-- scenes/                 # Scene files
|   |-- Main.tscn          # Main game scene
|   |-- unit.tscn          # Unit template
|   |-- Tower.tscn         # Tower structure
|   |-- Projectile.tscn    # Projectile template
|   |-- cards/             # Card-related scenes
|   |-- ending_screen.tscn # Game over screen
|   |-- player.tscn        # Player configuration
|   `-- spawn_ui.tscn      # Spawn interface
|
|-- scripts/               # Game logic
|   |-- game_manager.gd    # Core game controller
|   |-- unit.gd            # Unit behavior and AI
|   |-- tower.gd           # Tower health and damage
|   |-- projectile.gd      # Projectile physics
|   |-- spawn_ui.gd        # User interface
|   |-- card_button.gd     # Card interaction
|   `-- ending_screen.gd   # Game over logic
|
|-- assets/                # Art and audio resources
|
|-- IMPLEMENTATION_GUIDE.md  # Step-by-step fixes
|-- PROJECT_ANALYSIS.md      # Detailed project analysis
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
- **Number Keys (1-3)**: Spawn units in different lanes (when configured)
- **Space**: Default unit spawn action

## Current Status

### Working Features
- [x] Elixir regeneration system
- [x] Unit spawning mechanics
- [x] Lane-based movement
- [x] Basic combat system
- [x] AI opponent spawning
- [x] Tower health system
- [x] Projectile physics

### Known Issues
- [ ] Input action "po" not defined in InputMap
- [ ] No unit count limit (infinite spawning)
- [ ] Hardcoded spawn point names
- [ ] Missing health UI for towers
- [ ] No game end conditions
- [ ] Limited unit variety (only Archer)

### Quick Fixes Available
See `IMPLEMENTATION_GUIDE.md` for step-by-step solutions to critical issues:
1. Unit spawn limit implementation
2. Input action configuration
3. Spawn point validation
4. Debug HUD addition

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
1. Create new unit scene in `scenes/`
2. Configure unit properties (health, damage, speed)
3. Add to `AVAILABLE_CARDS` array in `game_manager.gd`
4. Update UI to display new card options

#### Implementing Card System
1. Create `CardData` resource class
2. Define card properties (cost, description, scene)
3. Replace hardcoded `AVAILABLE_CARDS` with resource-based system
4. Update UI to display card information

#### Adding Wave System
1. Create `wave_manager.gd` script
2. Implement wave progression and difficulty scaling
3. Add wave UI elements
4. Connect to game end conditions

## Testing

### Manual Testing Checklist
- [ ] Player can spawn units with configured input
- [ ] Elixir regenerates at correct rate
- [ ] Units move to designated lanes
- [ ] Units engage enemies in their lane
- [ ] Units attack towers as fallback targets
- [ ] AI spawns opponents at regular intervals
- [ ] Towers take damage and can be destroyed
- [ ] No Vector2.ZERO spawn point errors

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
- [ ] Multiple unit types (Tank, Speeder, Mage)
- [ ] Card collection system
- [ ] Wave-based progression
- [ ] Visual health bars
- [ ] Sound effects and music
- [ ] Particle effects
- [ ] Save/load system
- [ ] Multiplayer support

### Architecture Improvements
- [ ] Remove hardcoded team values
- [ ] Implement constants system
- [ ] Create unit management system
- [ ] Add event logging
- [ ] Improve error handling

---

**Note**: This is currently a test/prototype project. See `IMPLEMENTATION_GUIDE.md` for quick fixes to make the game fully functional, and `PROJECT_ANALYSIS.md` for detailed technical analysis and improvement recommendations.
