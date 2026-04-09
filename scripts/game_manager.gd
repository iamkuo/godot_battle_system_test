extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

# Game Balance
const ELIXIR_COST: int = 3
const SPAWN_LANES: int = 3

# AI Configuration
const AI_COOLDOWN_MIN: float = 2.0
const AI_COOLDOWN_MAX: float = 5.0
const AI_SPAWN_CHANCE: float = 0.8  # 80% chance to spawn when cooldown is ready

# Teams
enum Team {PLAYER = 0, OPPONENT = 1}

# Available Cards
const AVAILABLE_CARDS: Array[PackedScene] = [preload("res://scenes/cards/archer.tscn")]
const ALLIES_AVAILABLE_CARDS: Array[PackedScene] = [preload("res://scenes/cards/archer.tscn")]

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var allies_container: Node2D = get_tree().current_scene.get_node("AlliesContainer")
@onready var opponents_container: Node2D = get_tree().current_scene.get_node("OpponentsContainer")
@onready var spawn_points: Node2D = get_tree().current_scene.get_node("SpawnPoints")
@onready var ui: CanvasLayer = get_tree().current_scene.get_node("UI")
@onready var elixir: Node = get_tree().current_scene.get_node("UI/ElixirBar")

# =============================================================================
# AI SETTINGS
# =============================================================================

var ai_enabled: bool = true
var ai_cooldown: float = 0.0
var local_team: Team = Team.PLAYER

# =============================================================================
# LIFECYCLE METHODS
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_update_elixir_label(elixir.get_current_int())

func _process(delta: float) -> void:
	if not ai_enabled:
		return

	_handle_ai_logic(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("po"):
		_handle_test_spawn()

# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _connect_signals() -> void:
	elixir.elixir_changed.connect(_update_elixir_label)

func _handle_ai_logic(delta: float) -> void:
	if ai_cooldown > 0:
		ai_cooldown -= delta
		return

	# Reset cooldown
	ai_cooldown = randf_range(AI_COOLDOWN_MIN, AI_COOLDOWN_MAX)
	
	# Check if AI should spawn this cycle
	if randf() > AI_SPAWN_CHANCE:
		return

	var card_index: int = randi() % AVAILABLE_CARDS.size()
	var lane: int = randi() % SPAWN_LANES
	var pos: Vector2 = get_spawn_point(Team.OPPONENT, lane)

	spawn_unit(AVAILABLE_CARDS[card_index], pos, Team.OPPONENT, lane)

func _handle_test_spawn() -> void:
	var pos: Vector2 = get_spawn_point(local_team, 0)
	spawn_unit(ALLIES_AVAILABLE_CARDS[0], pos, local_team, 0)

# =============================================================================
# UI METHODS
# =============================================================================

func _update_elixir_label(val: int) -> void:
	var label: Label = elixir.get_node("ElixirLabel")
	label.text = str(val)

func show_message(txt: String) -> void:
	var label: Label = ui.get_node("MsgLabel")
	label.text = txt

# =============================================================================
# GAME LOGIC METHODS
# =============================================================================

func can_spawn(team: Team, cost: int) -> bool:
	if team == local_team:
		return elixir.get_current_int() >= cost
	else:
		return true

func spawn_unit(packed_scene: PackedScene, pos: Vector2, team: Team, lane: int) -> void:
	if team == local_team:
		elixir.try_consume(ELIXIR_COST)

	var unit: Node = packed_scene.instantiate()
	unit.global_position = pos
	unit.team = team
	unit.lane = lane

	# Add to appropriate container based on team
	var container: Node2D = allies_container if team == local_team else opponents_container
	container.add_child(unit)

	unit.add_to_group("units")

	# Flip sprite for opposing team
	var sprite: Sprite2D = unit.get_node("Sprite2D")
	sprite.flip_h = (team == Team.OPPONENT)

# =============================================================================
# SPAWN SYSTEM
# =============================================================================

func get_spawn_point(team: Team, lane: int) -> Vector2:
	var spawn_node_name: String = _get_spawn_node_name(team, lane)
	var spawn_node: Node2D = spawn_points.get_node(spawn_node_name)
	return spawn_node.global_position

func _get_spawn_node_name(team: Team, lane: int) -> String:
	var team_prefix: String = "L" if team == Team.PLAYER else "R"
	var lane_suffix: String = ""
	
	match lane:
		0: lane_suffix = "Top"
		1: lane_suffix = "Middle"
		2: lane_suffix = "Bottom"
		_: lane_suffix = "Middle"
		
	return "%s_%s" % [team_prefix, lane_suffix]

# =============================================================================
# PUBLIC API
# =============================================================================

func toggle_ai() -> void:
	ai_enabled = not ai_enabled
	print("AI %s" % ("enabled" if ai_enabled else "disabled"))

func set_ai_enabled(enabled: bool) -> void:
	ai_enabled = enabled
	print("AI %s" % ("enabled" if ai_enabled else "disabled"))

func get_team_name(team: Team) -> String:
	match team:
		Team.PLAYER: return "Player"
		Team.OPPONENT: return "Opponent"
		_: return "Unknown"

func is_valid_lane(lane: int) -> bool:
	return lane >= 0 and lane < SPAWN_LANES

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func on_tower_destroyed(tower: Node) -> void:
	var winner: Team = Team.PLAYER if tower.team == Team.OPPONENT else Team.OPPONENT
	show_message("Team %d won!" % winner)
	get_tree().paused = true
