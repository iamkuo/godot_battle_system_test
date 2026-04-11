extends Node

signal game_state_changed(state: String)

enum Team { PLAYER = 0, OPPONENT = 1 }

const SPAWN_LANES: int = 3
const AI_COOLDOWN_MIN: float = 2.0
const AI_COOLDOWN_MAX: float = 5.0
const AI_SPAWN_CHANCE: float = 1.0

var curr: Node
var spawn_points: Node2D
var allies_container: Node2D
var opponents_container: Node2D
var elixir: Control

var local_team: Team = Team.PLAYER
var game_state: String = "idle"
var unit_stats_registry: Dictionary = {}

var ai_enabled: bool = true
var ai_cooldown: float = 0.0

const UnitStatsScript = preload("res://scripts/core/unit_stats.gd")

func _ready() -> void:
	curr = get_tree().current_scene
	if curr:
		spawn_points = curr.get_node("SpawnPoints")
		allies_container = curr.get_node_or_null("AlliesContainer")
		opponents_container = curr.get_node_or_null("EnemiesContainer")
		elixir = curr.get_node_or_null("UI/SpawnUI")
	else:
		print("DEBUG: FAIL - curr is null in _ready!")
		
	unit_stats_registry.clear()
	var dir = DirAccess.open("res://resources/unit_stats/")
	if dir:
		var files = dir.get_files()
		for file_name in files:
			file_name = file_name.trim_suffix(".remap")
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var resource = load("res://resources/unit_stats/" + file_name)
				if resource and "cost" in resource:
					unit_stats_registry[file_name.replace(".tres", "")] = resource
	
	game_state = "ready"
	game_state_changed.emit(game_state)

func _process(delta: float) -> void:
	if not ai_enabled:
		return
	ai_cooldown -= delta
	if ai_cooldown > 0:
		return
	ai_cooldown = randf_range(AI_COOLDOWN_MIN, AI_COOLDOWN_MAX)
	if randf() >= AI_SPAWN_CHANCE:
		return
		
	var stats_ids = unit_stats_registry.keys()
	if stats_ids.is_empty():
		return
		
	var random_stat = unit_stats_registry[stats_ids[randi() % stats_ids.size()]]
	var lane = randi() % SPAWN_LANES
	spawn_enemy(random_stat, lane)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("po"):
		var stats_ids = unit_stats_registry.keys()
		if not stats_ids.is_empty():
			spawn_ally(unit_stats_registry[stats_ids[0]], 0)

func get_spawn_point(team: int, lane: int) -> Vector2:
	var team_enum = Team.PLAYER if team == 0 else Team.OPPONENT
	var suffix = ["Top", "Middle", "Bottom"][lane] if lane >= 0 and lane < 3 else "Middle"
	var prefix = "L" if team_enum == Team.PLAYER else "R"
	if spawn_points and spawn_points.has_node(prefix + "_" + suffix):
		return spawn_points.get_node(prefix + "_" + suffix).global_position
	return Vector2.ZERO

func spawn_ally(stats: UnitStats, lane: int) -> void:
	if not stats or not allies_container:
		return
	if elixir and not elixir.try_consume(stats.cost):
		return
	var pos = get_spawn_point(Team.PLAYER, lane)
	allies_container.spawn_unit(stats, pos, lane)

func spawn_enemy(stats: UnitStats, lane: int) -> void:
	if not stats or not opponents_container:
		return
	var pos = get_spawn_point(Team.OPPONENT, lane)
	opponents_container.spawn_unit(stats, pos, lane)

func can_spawn(team: int, cost: int) -> bool:
	if team == 0 and elixir:
		return elixir.get_current_int() >= cost
	return true

func on_tower_destroyed(tower: Node) -> void:
	var win_team = Team.PLAYER if tower.team == Team.OPPONENT else Team.OPPONENT
	MessageManager.show_message("Team %d won!" % win_team, 5.0)
	game_state = "game_over"
	game_state_changed.emit(game_state)
	get_tree().paused = true
