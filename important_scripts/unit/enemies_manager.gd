extends Node2D

enum Team { PLAYER = 0, OPPONENT = 1 }

const SPAWN_LANES: int = 3
const UNIT_SCENES_PATH: String = "res://scenes/unit.tscn"
const OPPONENT_PROJECTILE_SCENE = preload("res://scenes/units/projectiles/opponents_projectile.tscn")

var opponent_team: Team = Team.OPPONENT

func spawn_unit(stats: UnitStats, pos: Vector2, lane: int) -> void:
	if not stats or lane < 0 or lane >= SPAWN_LANES:
		return
		
	var packed_scene = load(UNIT_SCENES_PATH)
	if not packed_scene:
		return
		
	var unit: Node = packed_scene.instantiate()
	unit.global_position = pos
	unit.team = opponent_team
	unit.lane = lane
	var runtime_stats = stats.duplicate()
	if runtime_stats.attack_type == UnitStats.AttackType.PROJECTILE:
		runtime_stats.projectile_scene = OPPONENT_PROJECTILE_SCENE
	unit.stats = runtime_stats
	
	add_child(unit)
	
	unit.add_to_group("units")
	unit.add_to_group("enemy_units")
	
	var sprite = unit.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.flip_h = true
