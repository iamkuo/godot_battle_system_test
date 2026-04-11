class_name BattleWorldLink
extends Node

var linked_world: Node = null
var sync_enabled: bool = false

var battle_stats: Dictionary = {}
var player_progression: Dictionary = {}

signal world_data_synced(data: Dictionary)
signal battle_result_submitted(result: Dictionary)

func _ready():
	_setup_link()

func _setup_link():
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
	return 0

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
	pass

func set_link_enabled(enabled: bool):
	sync_enabled = enabled
