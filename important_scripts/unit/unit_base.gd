class_name UnitBase
extends CharacterBody2D

enum Team { PLAYER = 0, OPPONENT = 1 }

const unit_selection_circle = preload("res://important_scripts/ui/unit_selection_circle.gd")

const ARRIVAL_DISTANCE: float = 5.0
const MOVING_SPEED_THRESHOLD: float = 5.0

signal health_changed(current: int, max: int)
signal died(unit: UnitBase)
signal dealt_damage(amount: int, target: Node)

enum LifecycleState {ALIVE, DYING, DEAD}

@export var stats: UnitStats

var current_health: int
var lifecycle_state: LifecycleState = LifecycleState.ALIVE
var team: Team = Team.PLAYER
var lane: int = 1
var behavior_pattern: BehaviorPattern = null
var selected: bool = false

var current_target: Node = null
var attack_cooldown: float = 0.0
var is_attacking: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var selection_circle: Node2D = $SelectionCircle if has_node("SelectionCircle") else null

func _ready():
	if stats:
		current_health = stats.health
	else:
		current_health = 100
		stats = UnitStats.new()

func _physics_process(delta: float):
	if lifecycle_state != LifecycleState.ALIVE:
		return

	var was_moving = velocity.length() > MOVING_SPEED_THRESHOLD
	attack_cooldown = max(0.0, attack_cooldown - delta)
	current_target = find_target()
	_step_combat_or_march()
	_sync_walk_idle_animation(was_moving)

func _refresh_target():
	current_target = find_target()

func _step_combat_or_march():
	if current_target and is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		if dist <= stats.attack_distance:
			velocity = Vector2.ZERO
			move_and_slide()
			look_at(current_target.global_position)
			if attack_cooldown <= 0.0:
				_perform_attack(current_target)
		else:
			_move_towards(current_target.global_position)
	else:
		_move_towards(_get_march_destination())

func _sync_walk_idle_animation(was_moving: bool):
	var now_moving = velocity.length() > MOVING_SPEED_THRESHOLD
	if was_moving != now_moving:
		var action = "walk" if now_moving else "idle"
		_play_action(action)

func _animation_base_name() -> String:
	return stats.unit_id if stats else ""

func _play_action(action: String):
	if not sprite or not sprite.sprite_frames:
		return
	var anim_name = _animation_base_name() + "_" + action
	if anim_name in sprite.sprite_frames.get_animation_names():
		sprite.play(anim_name)
	else:
		if action in sprite.sprite_frames.get_animation_names():
			sprite.play(action)

func _get_march_destination() -> Vector2:
	if has_meta("move_to_position"):
		return get_meta("move_to_position") as Vector2
	if behavior_pattern and behavior_pattern.pattern_type == BehaviorPattern.PatternType.FOLLOW_PLAYER:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			return players[0].global_position
		return _get_lane_goal_pos()
	return _get_lane_goal_pos()

func _perform_attack(target: Node):
	if is_attacking or not target or not is_instance_valid(target):
		return

	if stats.attack_type == UnitStats.AttackType.PROJECTILE and not stats.projectile_scene:
		push_warning("PROJECTILE attack missing projectile_scene on stats")
		return

	is_attacking = true
	attack_cooldown = 1.0 / stats.attack_speed

	_play_action("attack")

	match stats.attack_type:
		UnitStats.AttackType.DIRECT:
			if target.has_method("take_damage"):
				target.take_damage(stats.attack_damage)
				dealt_damage.emit(stats.attack_damage, target)
		UnitStats.AttackType.PROJECTILE:
			var projectile = stats.projectile_scene.instantiate()
			projectile.global_position = global_position
			projectile.target = target
			projectile.damage = stats.attack_damage
			projectile.team = team
			if projectile.has_method("set_shooter"):
				projectile.set_shooter(self)
			get_parent().add_child(projectile)

	await get_tree().create_timer(0.3).timeout

	is_attacking = false

func take_damage(amount: int) -> void:
	var actual_damage = max(0, amount - stats.defense)
	current_health -= actual_damage
	health_changed.emit(current_health, stats.health)

	if current_health <= 0:
		lifecycle_state = LifecycleState.DYING
		_play_action("die")
		await get_tree().create_timer(0.5).timeout
		lifecycle_state = LifecycleState.DEAD
		died.emit(self)
		queue_free()

func find_target() -> Node:
	if behavior_pattern:
		return behavior_pattern.get_target_for(self)

	var all_enemies = get_tree().get_nodes_in_group("units")
	var nearest: Node = null
	var nearest_dist: float = 1e9
	for enemy in all_enemies:
		if enemy == self or enemy.team == team:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist and dist <= stats.view_distance:
			nearest_dist = dist
			nearest = enemy
	if nearest:
		return nearest

	var towers = get_tree().get_nodes_in_group("towers")
	var tower_nearest: Node = null
	var tower_nearest_dist: float = 1e9
	for tower in towers:
		if tower.team == team:
			continue
		if tower is TowerBase and tower.is_destroyed:
			continue
		var t_dist = global_position.distance_to(tower.global_position)
		if t_dist < tower_nearest_dist:
			tower_nearest_dist = t_dist
			tower_nearest = tower
	return tower_nearest

func set_behavior_pattern(pattern: BehaviorPattern):
	behavior_pattern = pattern

func select_unit():
	if team != 0:
		return
	selected = true
	if selection_circle and selection_circle is unit_selection_circle:
		selection_circle.show_for_unit(self)

func deselect_unit():
	selected = false
	if selection_circle and selection_circle is unit_selection_circle:
		selection_circle.hide_circle()

func _move_towards(target_pos: Vector2):
	var dir = target_pos - global_position
	if dir.length() < ARRIVAL_DISTANCE:
		velocity = Vector2.ZERO
	else:
		velocity = dir.normalized() * stats.move_speed
		if sprite:
			sprite.flip_h = dir.x < 0
	move_and_slide()

func _get_lane_goal_pos() -> Vector2:
	var x = 1400 if team == 0 else 200
	return Vector2(x, global_position.y)
