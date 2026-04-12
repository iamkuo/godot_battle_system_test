class_name BehaviorPattern
extends Resource

enum PatternType {
	STAY,
	FOLLOW_PLAYER,
	ATTACK_NEAREST_ENEMY,
	ATTACK_NEAREST_TOWER
}

@export var pattern_type: PatternType = PatternType.ATTACK_NEAREST_ENEMY
@export var name: String = "Attack Nearest Enemy"
@export var description: String = "Automatically targets and attacks the nearest enemy unit"

@export_group("Follow Settings")
@export var follow_distance: float = 100.0

func _init():
	resource_name = "BehaviorPattern"

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
	var enemies = _get_nearby_enemies(unit, unit.stats.attack_distance)
	return enemies[0] if enemies else null

func _handle_follow_player(unit: Node2D) -> Node:
	var player = _get_player_reference(unit)
	if not player:
		return _get_target_in_range(unit)
	
	var dist = unit.global_position.distance_to(player.global_position)
	if dist > follow_distance:
		unit.set_meta("move_to_position", player.global_position)
	
	return _get_target_in_range(unit)

func _get_nearest_enemy(unit: Node2D) -> Node:
	var all_enemies = unit.get_tree().get_nodes_in_group("units")
	var nearest: Node = null
	var nearest_dist: float = 1e9
	
	for enemy in all_enemies:
		if enemy == unit or enemy.team == unit.team:
			continue
		var dist = unit.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist and dist <= unit.stats.view_distance:
			nearest_dist = dist
			nearest = enemy
	
	if nearest:
		return nearest
	
	return _get_nearest_tower(unit)

func _get_nearest_tower(unit: Node2D) -> Node:
	var towers = unit.get_tree().get_nodes_in_group("towers")
	var nearest: Node = null
	var nearest_dist: float = 1e9
	
	for tower in towers:
		if tower.team == unit.team:
			continue
		if tower is TowerBase and tower.is_destroyed:
			continue
		var dist = unit.global_position.distance_to(tower.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = tower
	
	return nearest

func _get_nearby_enemies(unit: Node2D, range: float) -> Array:
	var enemies = []
	var all_units = unit.get_tree().get_nodes_in_group("units")
	
	for u in all_units:
		if u.team == unit.team:
			continue
		if unit.global_position.distance_to(u.global_position) <= range:
			enemies.append(u)
	
	return enemies

func _get_player_reference(unit: Node2D) -> Node2D:
	var players = unit.get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	return null

static func get_pattern_name(type: PatternType) -> String:
	match type:
		PatternType.STAY:
			return "Stay"
		PatternType.FOLLOW_PLAYER:
			return "Follow Player"
		PatternType.ATTACK_NEAREST_ENEMY:
			return "Attack Nearest Enemy"
		PatternType.ATTACK_NEAREST_TOWER:
			return "Attack Nearest Tower"
	return "Unknown"
