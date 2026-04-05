extends Node

# Constants
const ELIXIR_COST: int = 3
const AI_COOLDOWN_MIN: float = 2.0
const AI_COOLDOWN_MAX: float = 5.0
const SPAWN_LANES: int = 3
const AVAILABLE_CARDS: Array = [preload("res://scenes/cards/archer.tscn")]

# Node references
var allies_container: Node2D
var opponents_container: Node2D
var spawn_points: Node2D
var ui: CanvasLayer
var elixir: Node

# AI settings
var ai_enabled: bool = true
var ai_cooldown: float = 0.0
var local_team: int = 0

func _ready():
	var main = get_tree().current_scene
	allies_container = main.get_node("UnitsContainer/AlliesContainer")
	opponents_container = main.get_node("UnitsContainer/OpponentsContainer")
	spawn_points = main.get_node("SpawnPoints")
	ui = main.get_node("UI")
	elixir = main.get_node("UI/UIPanel/ElixirSystem")
	
	elixir.connect("elixir_changed", _update_elixir_label)
	_update_elixir_label(elixir.get_current_int())
	
	set_process(true)

func _process(delta):
	if not ai_enabled:
		return
	
	if ai_cooldown > 0:
		ai_cooldown -= delta
	else:
		ai_cooldown = randf_range(AI_COOLDOWN_MIN, AI_COOLDOWN_MAX)
		var card_index = randi() % AVAILABLE_CARDS.size()
		var lane = randi() % SPAWN_LANES
		var pos = get_spawn_point(1, lane)
		
		if pos == Vector2.ZERO:
			push_warning("AI: Could not find spawn point for team 1, lane %d" % lane)
			return
		
		spawn_unit(AVAILABLE_CARDS[card_index], pos, 1, lane)

func _input(event):
	if event.is_action_pressed("po"):
		var pos = get_spawn_point(local_team, 0)
		spawn_unit(AVAILABLE_CARDS[0], pos, local_team, 0)

func _update_elixir_label(val: int):
	if not ui:
		return
	var label = ui.get_node_or_null("UIPanel/ElixirLabel")
	if label:
		label.text = str(val)

func show_message(txt: String):
	if ui:
		var l = ui.get_node("MsgLabel")
		if l:
			l.text = txt

func can_spawn(team: int, cost: int) -> bool:
	if team == local_team:
		return elixir.get_current_int() >= cost
	else:
		return true

func spawn_unit(packed_scene: PackedScene, pos: Vector2, team: int, lane: int):
	if team == local_team:
		if not elixir.try_consume(ELIXIR_COST):
			show_message("Not enough Elixir")
			return
	
	var unit = packed_scene.instantiate()
	unit.global_position = pos
	unit.team = team
	unit.lane = lane
	
	# Add to appropriate container based on team
	if team == local_team:
		allies_container.add_child(unit)
	else:
		opponents_container.add_child(unit)
	
	unit.add_to_group("units")
	
	# Flip sprite for opposing team
	var sprite = unit.get_node_or_null("Sprite2D")
	if sprite:
		sprite.flip_h = (team == 1)

func get_spawn_point(team: int, lane: int) -> Vector2:
	var spawn_node_name = ""
	
	if team == 0: # 左側隊伍
		match lane:
			0: spawn_node_name = "L_Top"
			1: spawn_node_name = "L_Middle"
			2: spawn_node_name = "L_Bottom"
	else: # 右側隊伍
		match lane:
			0: spawn_node_name = "R_Top"
			1: spawn_node_name = "R_Middle"
			2: spawn_node_name = "R_Bottom"
	
	if spawn_points.has_node(spawn_node_name):
		var p = spawn_points.get_node(spawn_node_name)
		return p.global_position
	
	push_error("找不到生成點節點: " + spawn_node_name)
	return Vector2.ZERO

func on_tower_destroyed(tower: Node):
	var winner = 1 - tower.team
	show_message("Team %d won!" % winner)
	get_tree().paused = true


