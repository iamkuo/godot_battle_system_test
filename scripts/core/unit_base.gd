class_name UnitBase
extends CharacterBody2D

const unit_selection_circle = preload("res://scripts/ui/unit_selection_circle.gd")

signal health_changed(current: int, max: int)
signal died(unit: UnitBase)

enum LifecycleState {ALIVE, DYING, DEAD}

@export var stats: UnitStats

var current_health: int
var lifecycle_state: LifecycleState = LifecycleState.ALIVE
var team: int = 0
var lane: int = 1
var behavior_pattern: BehaviorPattern = null
var selected: bool = false

var current_target: Node = null
var attack_cooldown: float = 0.0
var is_attacking: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var selection_circle: Node2D = $SelectionCircle if has_node("SelectionCircle") else null

func _ready():
	if stats:
		current_health = stats.health
	else:
		current_health = 100
		stats = UnitStats.new()
	if died.connect(_on_died) != OK:
		push_warning("Failed to connect died signal")
	if stats and stats.unit_texture and sprite:
		sprite.texture = stats.unit_texture

func _physics_process(delta: float):
	if lifecycle_state != LifecycleState.ALIVE:
		return

	attack_cooldown = max(0.0, attack_cooldown - delta)

	var was_moving = velocity.length() > 5.0

	if current_target and is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		if dist <= stats.attack_distance:
			velocity = Vector2.ZERO
			move_and_slide()
			if attack_cooldown <= 0.0:
				_perform_attack(current_target)
		else:
			var dir = current_target.global_position - global_position
			if dir.length() < 5:
				velocity = Vector2.ZERO
			else:
				velocity = dir.normalized() * stats.move_speed
				if sprite:
					sprite.flip_h = dir.x < 0
				move_and_slide()
	else:
		var dest: Vector2
		if behavior_pattern and behavior_pattern.pattern_type == BehaviorPattern.PatternType.FOLLOW_PLAYER:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				dest = players[0].global_position
			else:
				var x = 1400 if team == 0 else 200
				dest = Vector2(x, global_position.y)
		else:
			var x = 1400 if team == 0 else 200
			dest = Vector2(x, global_position.y)
		var dir = dest - global_position
		if dir.length() < 5:
			velocity = Vector2.ZERO
		else:
			velocity = dir.normalized() * stats.move_speed
			if sprite:
				sprite.flip_h = dir.x < 0
			move_and_slide()

	var now_moving = velocity.length() > 5.0
	if was_moving != now_moving:
		if animation_player:
			var anim_name = stats.walk_animation if now_moving else stats.idle_animation
			if animation_player.has_animation(anim_name):
				animation_player.play(anim_name)

func _perform_attack(target: Node):
	if is_attacking or not target or not is_instance_valid(target):
		return

	is_attacking = true
	attack_cooldown = 1.0 / stats.attack_speed

	if animation_player and animation_player.has_animation(stats.attack_animation):
			animation_player.play(stats.attack_animation)

	match stats.attack_type:
		UnitStats.AttackType.DIRECT:
			if target.has_method("take_damage"):
				target.take_damage(stats.attack_damage)
				emit_signal("dealt_damage", stats.attack_damage, target)
		UnitStats.AttackType.PROJECTILE:
			if not stats.projectile_scene:
				return
			var projectile = stats.projectile_scene.instantiate()
			projectile.global_position = global_position
			projectile.target = target
			projectile.damage = stats.attack_damage
			projectile.team = team
			get_parent().add_child(projectile)
	await get_tree().create_timer(0.3).timeout

	is_attacking = false

func take_damage(amount: int) -> void:
	var actual_damage = max(0, amount - stats.defense)
	current_health -= actual_damage
	health_changed.emit(current_health, stats.health)

	if current_health <= 0:
		lifecycle_state = LifecycleState.DYING
		if animation_player and animation_player.has_animation(stats.die_animation):
			animation_player.play(stats.die_animation)
		await get_tree().create_timer(0.5).timeout
		lifecycle_state = LifecycleState.DEAD
		died.emit(self )
		queue_free()

func find_target() -> Node:
	if behavior_pattern:
		return behavior_pattern.get_target_for(self )

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
		selection_circle.show_for_unit(self )

func deselect_unit():
	selected = false
	if selection_circle and selection_circle is unit_selection_circle:
		selection_circle.hide_circle()

func _on_died(unit: UnitBase):
	emit_signal("died", unit)

func _move_towards(target_pos: Vector2, delta: float):
	var dir = target_pos - global_position
	if dir.length() < 5:
		velocity = Vector2.ZERO
	else:
		velocity = dir.normalized() * stats.move_speed
		if sprite:
			sprite.flip_h = dir.x < 0
	move_and_slide()

func _get_lane_goal_pos() -> Vector2:
	var x = 1400 if team == 0 else 200
	return Vector2(x, global_position.y)
