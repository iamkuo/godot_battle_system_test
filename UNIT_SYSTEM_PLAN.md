# Unit System Implementation Plan

## Overview
This document outlines the complete unit system architecture for the battle game, including health/lifecycle, stats, behavior patterns, UI, spawn API, tower system, and integration with test_project.

---

## 1. Script Structure

### 1.1 Core Class Hierarchy

```
Node (Godot)
    extends
    - UnitBase (abstract base class) ✅ Created
        - AllyUnit (player controlled) - Use UnitBase with team=0
        - EnemyUnit (AI controlled) - Use UnitBase with team=1
    - TowerBase (abstract base class)
        - DefenseTower
        - SpawnTower
    - BehaviorPattern (resource-based patterns) ✅ Created
    - UnitStats (custom resource for stats) ✅ Created
    - UnitUI (CanvasLayer for unit selection)
    - SpawnAPI (static class for spawning)
    - GameManager (expanded)
    - TowerManager (new)
    - BattleWorldLink (for test_project integration)
```

### 1.2 File Structure

```
scripts/
    core/                              # ✅ All created
        unit_base.gd           # Abstract base for all units ✅
        unit_stats.gd          # Custom resource for unit stats ✅
        behavior_pattern.gd    # Resource for behavior patterns ✅
    units/
        ally_unit.gd           # Player-controlled unit (use UnitBase)
        enemy_unit.gd          # AI unit (use UnitBase)
    towers/
        tower_base.gd          # Abstract tower base
        defense_tower.gd       # Standard defense tower
    ui/
        unit_selection_circle.gd   # Circle UI when clicked
        unit_control_panel.gd      # Panel to change behavior
    systems/
        spawn_api.gd           # Spawning API
        tower_manager.gd       # Tower lifecycle management
        battle_world_link.gd   # Link to test_project
    game/
        game_manager.gd        # Expanded (existing)
        ending_screen.gd       # Existing
        archer.gd              # Archer unit specific
        player_in_battle.gd    # Player in battle
```

---

## 2. Unit System

### 2.1 UnitStats (Custom Resource)

```gdscript
# scripts/core/unit_stats.gd ✅ CREATED
class_name UnitStats
extends Resource

enum AttackType { DIRECT, PROJECTILE }

@export_group("Basic Stats")
@export var health: int = 100
@export var defense: int = 0
@export var cost: int = 3

@export_group("Combat Stats")
@export var attack_damage: int = 25
@export var attack_speed: float = 1.0
@export var attack_type: AttackType = AttackType.DIRECT
@export var projectile_scene: PackedScene = null

@export_group("Movement Stats")
@export var move_speed: float = 120.0

@export_group("Range Stats")
@export var view_distance: float = 300.0
@export var attack_distance: float = 200.0

@export_group("Visual")
@export var unit_texture: Texture2D = null
@export var idle_animation: String = "idle"
@export var attack_animation: String = "attack"
@export var walk_animation: String = "walk"
@export var die_animation: String = "die"

func create_runtime_data() -> Dictionary:
    return {
        "max_health": health,
        "current_health": health,
        "defense": defense,
        "attack_damage": attack_damage,
        "attack_speed": attack_speed,
        "attack_type": attack_type,
        "projectile_scene": projectile_scene,
        "move_speed": move_speed,
        "view_distance": view_distance,
        "attack_distance": attack_distance,
        "cost": cost,
        "unit_texture": unit_texture,
        "idle_animation": idle_animation,
        "attack_animation": attack_animation,
        "walk_animation": walk_animation,
        "die_animation": die_animation
    }
```

**Status:** ✅ Created at `scripts/core/unit_stats.gd`

### 2.2 UnitBase (Abstract Class)

```gdscript
# scripts/core/unit_base.gd ✅ CREATED
class_name UnitBase
extends CharacterBody2D

# Signals
signal health_changed(current: int, max: int)
signal died(unit: UnitBase)
signal target_acquired(target: Node)

# Lifecycle states
enum LifecycleState { ALIVE, DYING, DEAD }

# Exported stats resource
@export var stats: UnitStats

# Runtime data
var current_health: int
var lifecycle_state: LifecycleState = LifecycleState.ALIVE
var team: int = 0
var lane: int = 1
var behavior_pattern: BehaviorPattern = null
var selected: bool = false

# Target management
var current_target: Node = null
var attack_cooldown: float = 0.0

func _ready():
    _initialize_stats()
    _setup_collision()
    _connect_signals()

func _initialize_stats():
    if stats:
        current_health = stats.health
    else:
        current_health = 100

func _setup_collision():
    # Setup collision layer/mask for unit interactions
    pass

func _connect_signals():
    if died.connect(_on_died) != OK:
        push_warning("Failed to connect died signal")

func _physics_process(delta: float):
    if lifecycle_state != LifecycleState.ALIVE:
        return

    _process_attack_cooldown(delta)

    var was_moving = velocity.length() > 5.0

    if current_target and is_instance_valid(current_target):
        _handle_combat(delta)
    else:
        _handle_movement(delta)

    var now_moving = velocity.length() > 5.0
    if was_moving != now_moving:
        _update_animation_state(now_moving)

func _process_attack_cooldown(delta: float):
    attack_cooldown = max(0.0, attack_cooldown - delta)

func _handle_combat(delta: float):
    var dist = global_position.distance_to(current_target.global_position)

    if dist <= stats.attack_distance:
        velocity = Vector2.ZERO
        move_and_slide()
        if attack_cooldown <= 0.0:
            _perform_attack(current_target)
    else:
        _move_towards(current_target.global_position, delta)

func _handle_movement(delta: float):
    var dest: Vector2

    if behavior_pattern and behavior_pattern.pattern_type == BehaviorPattern.PatternType.FOLLOW_PLAYER:
        var player = _get_player_reference()
        if player:
            dest = player.global_position
        else:
            dest = _get_lane_goal_pos()
    else:
        dest = _get_lane_goal_pos()

    _move_towards(dest, delta)

func _move_towards(pos: Vector2, delta: float):
    var dir = pos - global_position
    if dir.length() < 5:
        velocity = Vector2.ZERO
    else:
        velocity = dir.normalized() * stats.move_speed
        if sprite:
            sprite.flip_h = dir.x < 0
    move_and_slide()

func _perform_attack(target: Node):
    if is_attacking or not target or not is_instance_valid(target):
        return

    is_attacking = true
    attack_cooldown = 1.0 / stats.attack_speed

    _play_animation(stats.attack_animation)
    await _execute_attack(target)

    is_attacking = false

func _execute_attack(target: Node):
    match stats.attack_type:
        UnitStats.AttackType.DIRECT:
            if target.has_method("take_damage"):
                target.take_damage(stats.attack_damage)
        UnitStats.AttackType.PROJECTILE:
            _spawn_projectile(target)
    await get_tree().create_timer(0.3).timeout

func _spawn_projectile(target: Node):
    if not stats.projectile_scene:
        return

    var projectile = stats.projectile_scene.instantiate()
    projectile.global_position = global_position
    projectile.target = target
    projectile.damage = stats.attack_damage
    projectile.team = team

    get_parent().add_child(projectile)

func _update_animation_state(is_moving: bool):
    if animation_player:
        var anim_name = stats.walk_animation if is_moving else stats.idle_animation
        if animation_player.has_animation(anim_name):
            animation_player.play(anim_name)

func _play_animation(anim_name: String):
    if animation_player and animation_player.has_animation(anim_name):
        animation_player.play(anim_name)

func take_damage(amount: int) -> void:
    var actual_damage = max(0, amount - stats.defense)
    current_health -= actual_damage
    health_changed.emit(current_health, stats.health)

    if current_health <= 0:
        _die()

func _die():
    lifecycle_state = LifecycleState.DYING
    _play_animation(stats.die_animation)
    await get_tree().create_timer(0.5).timeout
    died.emit(self)
    queue_free()

func find_target() -> Node:
    # Override for unit-specific targeting
    return null

func set_behavior_pattern(pattern: BehaviorPattern):
    behavior_pattern = pattern

func select_unit():
    selected = true
    _show_selection_circle()

func deselect_unit():
    selected = false
    _hide_selection_circle()

func _show_selection_circle():
    # Emit signal to UI system
    pass

func _hide_selection_circle():
    # Emit signal to UI system
    pass
```

**Status:** ✅ Created at `scripts/core/unit_base.gd`

### 2.3 Behavior Patterns (Resource-based)

```gdscript
# scripts/core/behavior_pattern.gd ✅ CREATED
class_name BehaviorPattern
extends Resource

enum PatternType {
    STAY,              # Stay in place, attack anything in range
    FOLLOW_PLAYER,     # Follow the player character
    ATTACK_NEAREST_ENEMY,  # Chase and attack nearest enemy unit
    ATTACK_NEAREST_TOWER    # Chase and attack nearest enemy tower
}

@export var pattern_type: PatternType = PatternType.ATTACK_NEAREST_ENEMY
@export var name: String = "Attack Nearest Enemy"
@export var description: String = "Automatically targets and attacks the nearest enemy unit"

# For FOLLOW_PLAYER pattern
@export var follow_distance: float = 100.0
@export var player_reference: Node2D = null

func get_target_for(unit: Node2D) -> Node:
    match pattern_type:
        PatternType.STAY:
            return _get_target_in_range(unit)
        PatternType.FOLLOW_PLAYER:
            return _handle_follow_player(unit)
        PatternType.ATTACK_NEAREST_ENEMY:
            return _get_nearest_enemy(unit)
        PatternType.ATTACK_NEAREST_TOWER:
            return _get_nearest_tower(unit)
    return null

func _get_target_in_range(unit: Node2D) -> Node:
    # Return any enemy in attack range
    var enemies = _get_nearby_enemies(unit, unit.stats.attack_distance)
    return enemies[0] if enemies else null

func _handle_follow_player(unit: Node2D) -> Node:
    # Move towards player if too far, otherwise stay/attack
    if not player_reference:
        return _get_target_in_range(unit)

    var dist = unit.global_position.distance_to(player_reference.global_position)
    if dist > follow_distance:
        # Move towards player (handled by movement system)
        pass

    return _get_target_in_range(unit)

func _get_nearest_enemy(unit: Node2D) -> Node:
    var all_enemies = get_tree().get_nodes_in_group("units")
    var nearest: Node = null
    var nearest_dist: float = 1e9

    for enemy in all_enemies:
        if enemy.team == unit.team: continue
        var dist = unit.global_position.distance_to(enemy.global_position)
        if dist < nearest_dist and dist <= unit.stats.view_distance:
            nearest_dist = dist
            nearest = enemy

    # Fallback to tower if no enemy found
    if not nearest:
        return _get_nearest_tower(unit)

    return nearest

func _get_nearest_tower(unit: Node2D) -> Node:
    var towers = get_tree().get_nodes_in_group("towers")
    var nearest: Node = null
    var nearest_dist: float = 1e9

    for tower in towers:
        if tower.team == unit.team: continue
        var dist = unit.global_position.distance_to(tower.global_position)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest = tower

    return nearest

func _get_nearby_enemies(unit: Node2D, range: float) -> Array:
    var enemies = []
    var all_units = get_tree().get_nodes_in_group("units")

    for u in all_units:
        if u.team == unit.team: continue
        if unit.global_position.distance_to(u.global_position) <= range:
            enemies.append(u)

    return enemies
```

**Status:** ✅ Created at `scripts/core/behavior_pattern.gd`

---

## 3. UI System

### 3.1 Unit Selection Circle

```gdscript
# scripts/ui/unit_selection_circle.gd
class_name UnitSelectionCircle
extends Node2D

var target_unit: UnitBase = null
var radius: float = 50.0
var visible_state: bool = false

func _ready():
    visible = false
    z_index = 100  # Always on top

func show_for_unit(unit: UnitBase):
    target_unit = unit
    radius = unit.stats.attack_distance
    visible = true

func hide_circle():
    target_unit = null
    visible = false

func _draw():
    if not visible: return

    # Draw circle outline
    draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color.GREEN, 2.0)

    # Draw direction indicator
    if target_unit:
        var dir = Vector2(1, 0)  # Could use actual facing direction
        draw_line(Vector2.ZERO, dir * radius, Color.YELLOW, 2.0)

func _process(_delta):
    if visible:
        queue_redraw()
```

### 3.2 Unit Control Panel

```gdscript
# scripts/ui/unit_control_panel.gd
class_name UnitControlPanel
extends Control

var selected_unit: UnitBase = null
var current_pattern: BehaviorPattern = null

@onready var pattern_buttons: Array[Button] = []

func _ready():
    visible = false
    _create_pattern_buttons()

func _create_pattern_buttons():
    # Create buttons for each pattern type
    var patterns = [
        BehaviorPattern.PatternType.STAY,
        BehaviorPattern.PatternType.FOLLOW_PLAYER,
        BehaviorPattern.PatternType.ATTACK_NEAREST_ENEMY,
        BehaviorPattern.PatternType.ATTACK_NEAREST_TOWER
    ]

    for i in patterns.size():
        var btn = Button.new()
        btn.text = BehaviorPattern.PatternType.keys()[patterns[i]]
        btn.pressed.connect(_on_pattern_selected.bind(patterns[i]))
        pattern_buttons.append(btn)

func show_for_unit(unit: UnitBase):
    selected_unit = unit
    visible = true
    global_position = unit.get_global_transform_with_canvas().origin + Vector2(60, -60)

func _on_pattern_selected(pattern_type: int):
    if not selected_unit: return

    var new_pattern = BehaviorPattern.new()
    new_pattern.pattern_type = pattern_type
    selected_unit.set_behavior_pattern(new_pattern)
    hide_panel()

func hide_panel():
    visible = false
    selected_unit = null
```

---

## 4. Spawn API

```gdscript
# scripts/systems/spawn_api.gd
class_name SpawnAPI
extends Node

# Preloaded unit scenes (to be populated)
var available_units: Dictionary = {}

signal unit_spawned(unit: UnitBase, spawn_info: Dictionary)
signal spawn_failed(reason: String)

enum SpawnResult { SUCCESS, FAILED_INVALID_COST, FAILED_MAX_UNITS, FAILED_INVALID_LANE }

func _ready():
    _register_available_units()

func _register_available_units():
    # Register all unit scenes from the units directory
    # This will be expanded as more units are added
    pass

func spawn_unit(
    unit_scene: PackedScene,
    spawn_position: Vector2,
    team: int,
    lane: int,
    behavior_pattern: BehaviorPattern = null
) -> SpawnResult:
    # Validate spawn conditions
    var validation = _validate_spawn(unit_scene, team, lane)
    if validation != SpawnResult.SUCCESS:
        spawn_failed.emit(_get_error_message(validation))
        return validation

    # Create unit instance
    var unit = unit_scene.instantiate()
    unit.global_position = spawn_position
    unit.team = team
    unit.lane = lane

    if behavior_pattern:
        unit.set_behavior_pattern(behavior_pattern)

    # Add to appropriate container
    _place_unit_in_container(unit, team)

    # Emit success signal
    var spawn_info = {
        "unit": unit,
        "position": spawn_position,
        "team": team,
        "lane": lane,
        "pattern": behavior_pattern
    }
    unit_spawned.emit(unit, spawn_info)

    return SpawnResult.SUCCESS

func _validate_spawn(unit_scene: PackedScene, team: int, lane: int) -> SpawnResult:
    # Check if unit scene is valid
    if not unit_scene:
        return SpawnResult.FAILED_INVALID_COST

    # Check lane validity
    if lane < 0 or lane > 2:
        return SpawnResult.FAILED_INVALID_LANE

    # Check unit limits per team
    var current_count = _get_team_unit_count(team)
    var max_count = _get_max_units_for_team(team)

    if current_count >= max_count:
        return SpawnResult.FAILED_MAX_UNITS

    return SpawnResult.SUCCESS

func _get_team_unit_count(team: int) -> int:
    var group_name = "ally_units" if team == 0 else "enemy_units"
    return get_tree().get_nodes_in_group(group_name).size()

func _get_max_units_for_team(team: int) -> int:
    return 10  # Configurable per team

func _place_unit_in_container(unit: UnitBase, team: int):
    var container_name = "AlliesContainer" if team == 0 else "OpponentsContainer"
    var container = get_tree().current_scene.get_node_or_null(container_name)

    if container:
        container.add_child(unit)
        unit.add_to_group("units")
        unit.add_to_group("ally_units" if team == 0 else "enemy_units")

func _get_error_message(result: SpawnResult) -> String:
    match result:
        SpawnResult.FAILED_INVALID_COST:
            return "Invalid unit scene"
        SpawnResult.FAILED_MAX_UNITS:
            return "Maximum unit limit reached"
        SpawnResult.FAILED_INVALID_LANE:
            return "Invalid lane specified"
    return "Unknown error"

# Static API for external spawning
static func create_spawn_request(
    unit_scene: PackedScene,
    position: Vector2,
    team: int,
    lane: int,
    pattern: BehaviorPattern = null
) -> Dictionary:
    return {
        "scene": unit_scene,
        "position": position,
        "team": team,
        "lane": lane,
        "pattern": pattern
    }
```

---

## 5. Tower System

### 5.1 TowerBase

```gdscript
# scripts/towers/tower_base.gd
class_name TowerBase
extends Node2D

signal tower_destroyed(tower: TowerBase)
signal health_changed(current: int, max: int)

@export var max_health: int = 1000
@export var defense: int = 10
@export var team: int = 0
@export var lane: int = 1
@export var tower_name: String = "Tower"

var current_health: int = 0
var is_destroyed: bool = false

func _ready():
    current_health = max_health
    add_to_group("towers")
    _initialize()

func _initialize():
    # Override for tower-specific initialization
    pass

func take_damage(amount: int) -> void:
    if is_destroyed: return

    var actual_damage = max(0, amount - defense)
    current_health -= actual_damage
    health_changed.emit(current_health, max_health)

    if current_health <= 0:
        _destroy()

func _destroy():
    is_destroyed = true
    tower_destroyed.emit(self)

    # Notify TowerManager
    var tm = get_tree().current_scene.get_node_or_null("TowerManager")
    if tm:
        tm.on_tower_destroyed(self)

    # Death effect
    _play_destruction_effect()
    queue_free()

func _play_destruction_effect():
    # Override for tower-specific effects
    pass

func get_team() -> int:
    return team

func get_lane() -> int:
    return lane
```

### 5.2 TowerManager

```gdscript
# scripts/systems/tower_manager.gd
class_name TowerManager
extends Node

signal all_towers_destroyed(winning_team: int)
signal tower_destroyed_notify(tower: TowerBase)

var towers: Array[TowerBase] = []
var player_towers: int = 0
var enemy_towers: int = 0

func _ready():
    _register_all_towers()

func _register_all_towers():
    towers.clear()
    player_towers = 0
    enemy_towers = 0

    for node in get_tree().get_nodes_in_group("towers"):
        if node is TowerBase:
            towers.append(node)
            if node.team == 0:
                player_towers += 1
            else:
                enemy_towers += 1
            node.tower_destroyed.connect(_on_tower_destroyed.bind())

func _on_tower_destroyed(tower: TowerBase):
    towers.erase(tower)

    if tower.team == 0:
        player_towers -= 1
    else:
        enemy_towers -= 1

    tower_destroyed_notify.emit(tower)
    _check_game_end()

func _check_game_end():
    if player_towers <= 0:
        _end_game(1)  # Enemy wins
    elif enemy_towers <= 0:
        _end_game(0)  # Player wins

func _end_game(winning_team: int):
    all_towers_destroyed.emit(winning_team)

    # Notify GameManager to show end screen
    var gm = get_tree().current_scene.get_node_or_null("GameManager")
    if gm:
        gm.show_ending_screen(winning_team)
```

---

## 6. Ending Screen System

```gdscript
# scripts/game/ending_screen.gd
class_name EndingScreen
extends Control

@export var win_color: Color = Color.GREEN
@export var lose_color: Color = Color.RED

func show_result(winning_team: int, player_team: int = 0):
    visible = true

    var result_label = $ResultLabel
    if winning_team == player_team:
        result_label.text = "VICTORY!"
        result_label.modulate = win_color
    else:
        result_label.text = "DEFEAT"
        result_label.modulate = lose_color

func _on_restart_pressed():
    get_tree().reload_current_scene()

func _on_main_menu_pressed():
    # Load main menu scene
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

---

## 7. BattleWorldLink (test_project Integration)

```gdscript
# scripts/systems/battle_world_link.gd
class_name BattleWorldLink
extends Node

# Reference to test_project's world system
var linked_world: Node = null
var sync_enabled: bool = false

# Data to sync
var battle_stats: Dictionary = {}
var player_progression: Dictionary = {}

signal world_data_synced(data: Dictionary)
signal battle_result_submitted(result: Dictionary)

func _ready():
    _setup_link()

func _setup_link():
    # Attempt to find test_project's world system
    # This will be implemented when linking projects
    pass

func sync_battle_to_world():
    if not sync_enabled: return

    var data = {
        "timestamp": Time.get_ticks_msec(),
        "units_spawned": _count_units_spawned(),
        "towers_destroyed": _count_towers_destroyed(),
        "elixir_used": _get_elixir_used(),
        "result": _get_battle_result()
    }

    battle_stats = data
    world_data_synced.emit(data)

func _count_units_spawned() -> int:
    return get_tree().get_nodes_in_group("units").size()

func _count_towers_destroyed() -> int:
    return 0  # Track destroyed towers

func _get_elixir_used() -> int:
    var gm = get_tree().current_scene.get_node_or_null("GameManager")
    if gm and gm.has_method("get_elixir_used"):
        return gm.get_elixir_used()
    return 0

func _get_battle_result() -> String:
    var tm = get_tree().current_scene.get_node_or_null("TowerManager")
    if tm:
        if tm.player_towers <= 0:
            return "defeat"
        elif tm.enemy_towers <= 0:
            return "victory"
    return "ongoing"

func load_world_data_to_battle():
    # Load progression data from test_project into battle
    pass

func set_link_enabled(enabled: bool):
    sync_enabled = enabled
```

---

## 8. Implementation Order

### Phase 1: Core Foundation (Days 1-2) 
1. Create `unit_base.gd` - Abstract base class 
2. Create `unit_stats.gd` - Custom resource for unit stats 
3. Create `behavior_pattern.gd` - Resource for behavior patterns 
4. Update `unit.tscn` to use new system (pending)

### Phase 2: Behavior System (Days 3-4) 
1. Implement behavior pattern logic in unit_base 
2. Create pattern selection UI (pending)
3. Implement all 4 pattern types 

### Phase 3: UI System (Days 5-6)
1. Create `unit_selection_circle.gd` (pending)
2. Create `unit_control_panel.gd` (pending)
3. Integrate click detection for unit selection (pending)

### Phase 4: Spawn API (Days 7-8)
1. Create `spawn_api.gd` (pending)
2. Add spawn validation (pending)
3. Connect to existing GameManager (pending)

### Phase 5: Tower System (Days 9-10)
1. Create `tower_base.gd` (pending)
2. Create `tower_manager.gd` (pending)
3. Update existing Tower.tscn (pending)

### Phase 6: End Game (Days 11-12)
1. Enhance `ending_screen.gd` (pending)
2. Connect TowerManager to ending screen (pending)
3. Test game end conditions (pending)

### Phase 7: Integration (Days 13-14)
1. Create `battle_world_link.gd` (pending)
2. Define sync protocol with test_project (pending)
3. Test cross-project data flow (pending)

---

## 9. Key Files to Create/Modify

### New Files COMPLETED (Phase 1)
```
scripts/core/unit_base.gd ✅ Created
scripts/core/unit_stats.gd ✅ Created
scripts/core/behavior_pattern.gd ✅ Created
scripts/ui/unit_selection_circle.gd (pending)
scripts/ui/unit_control_panel.gd (pending)
scripts/systems/spawn_api.gd (pending)
scripts/systems/tower_manager.gd (pending)
scripts/systems/battle_world_link.gd (pending)
```

### Modified Files
```
scripts/unit.gd - Extend from UnitBase (pending)
scripts/archer.gd - Extend from UnitBase (pending)
scripts/game_manager.gd - Integrate SpawnAPI (pending)
scripts/ending_screen.gd - Add team parameters (pending)
```

### Scene Updates
```
scenes/unit.tscn - Add selection circle, update script (pending)
scenes/Tower.tscn - Add TowerBase script, health bar (pending)
scenes/Main.tscn - Add TowerManager, update UI (pending)
scenes/units/cards/ - Unit card scenes (existing)
scenes/units/projectiles/ - Projectile scenes (existing)
```

---

## 10. Data Flow Diagram

```
Input System (Click)
        |
        v
Unit Selection Manager
        |
        +-- UnitSelectionCircle (visual feedback)
        |
        +-- UnitControlPanel (pattern selection)
        |
        v
UnitBase._physics_process()
        |
        +-- BehaviorPattern.get_target()
        |       |
        |       +-- STAY -> Return enemy in range
        |       +-- FOLLOW_PLAYER -> Move to player
        |       +-- ATTACK_NEAREST_ENEMY -> Find nearest enemy
        |       +-- ATTACK_NEAREST_TOWER -> Find nearest tower
        |
        +-- Combat (attack if in range)
        +-- Movement (move to target if out of range)

TowerManager
        |
        +-- Tracks all towers
        +-- Detects game end
        +-- Triggers ending screen

SpawnAPI
        |
        +-- Validates spawn
        +-- Creates unit
        +-- Places in container
        +-- Emits unit_spawned signal
```

---

## 11. Next Steps

1. **Review this plan** and provide feedback
2. **Start Phase 1**: Create core foundation classes
3. **Iterate** based on testing and requirements

---

*Document Version: 1.0*
*Created: Apr 10, 2026*
