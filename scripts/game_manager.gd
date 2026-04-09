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
const ALLIES_AVAILABLE_CARDS: Array[PackedScene] = [preload("res://scenes/units/cards/alley_archer.tscn")]

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var allies_container: Node2D = get_tree().current_scene.get_node("AlliesContainer")
@onready var opponents_container: Node2D = get_tree().current_scene.get_node("OpponentsContainer")
@onready var spawn_points: Node2D = get_tree().current_scene.get_node("SpawnPoints")
@onready var ui: CanvasLayer = get_tree().current_scene.get_node("UI")
@onready var elixir: Node = get_tree().current_scene.get_node("UI/SpawnUI")
@onready var msg_label: Label = get_tree().current_scene.get_node("UI/SpawnUI/MsgLabel")

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
	pass

func _process(delta: float) -> void:
	if not ai_enabled:
		return

	if ai_cooldown > 0:
		ai_cooldown -= delta
		return

	ai_cooldown = randf_range(AI_COOLDOWN_MIN, AI_COOLDOWN_MAX)
	
	if randf() > AI_SPAWN_CHANCE:
		return

	var card_index: int = randi() % ALLIES_AVAILABLE_CARDS.size()
	var lane: int = randi() % SPAWN_LANES
	var team_prefix: String = "R"
	var lane_suffix: String = ""
	
	match lane:
		0: lane_suffix = "Top"
		1: lane_suffix = "Middle"
		2: lane_suffix = "Bottom"
		_: lane_suffix = "Middle"
		
	var spawn_node_name: String = "%s_%s" % [team_prefix, lane_suffix]
	var spawn_node: Node2D = spawn_points.get_node(spawn_node_name)
	var pos: Vector2 = spawn_node.global_position

	spawn_unit(ALLIES_AVAILABLE_CARDS[card_index], pos, Team.OPPONENT, lane, 0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("po"):
		var team_prefix: String = "L"
		var lane_suffix: String = "Top"
		var spawn_node_name: String = "%s_%s" % [team_prefix, lane_suffix]
		var spawn_node: Node2D = spawn_points.get_node(spawn_node_name)
		spawn_unit(ALLIES_AVAILABLE_CARDS[0], spawn_node.global_position, local_team, 0, ELIXIR_COST)

# =============================================================================
# GAME LOGIC METHODS
# =============================================================================

func can_spawn(team: Team, cost: int) -> bool:
	if team == local_team:
		return elixir.get_current_int() >= cost
	else:
		return true

func spawn_unit(packed_scene: PackedScene, pos: Vector2, team: Team, lane: int, cost: int) -> void:
	if team == local_team and not elixir.try_consume(cost):
		return

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

func get_spawn_point(team: Team, lane: int) -> Vector2:
	var team_prefix = "L" if team == Team.PLAYER else "R"
	var lane_suffix = ""
	match lane:
		0: lane_suffix = "Top"
		1: lane_suffix = "Middle"
		2: lane_suffix = "Bottom"
		_: lane_suffix = "Middle"
	var spawn_node_name = "%s_%s" % [team_prefix, lane_suffix]
	var spawn_node = spawn_points.get_node(spawn_node_name)
	return spawn_node.global_position

# =============================================================================
# EVENT HANDLERS
# =============================================================================

func on_tower_destroyed(tower: Node) -> void:
	var winner: Team = Team.PLAYER if tower.team == Team.OPPONENT else Team.OPPONENT
	msg_label.text = "Team %d won!" % winner
	get_tree().paused = true
