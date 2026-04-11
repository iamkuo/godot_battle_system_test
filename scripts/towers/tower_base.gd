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

	var tm = get_tree().current_scene.get_node_or_null("TowerManager")
	if tm:
		tm.on_tower_destroyed(self)

	_play_destruction_effect()
	queue_free()

func _play_destruction_effect():
	pass

func get_team() -> int:
	return team

func get_lane() -> int:
	return lane
