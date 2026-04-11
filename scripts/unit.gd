extends UnitBase

func _ready():
	super._ready()

func _physics_process(delta: float):
	if lifecycle_state != LifecycleState.ALIVE:
		return

	if current_target and is_instance_valid(current_target):
		_handle_combat(delta)
	else:
		_handle_movement(delta)

	current_target = find_target()

func _handle_combat(delta: float):
	var dist = global_position.distance_to(current_target.global_position)

	if dist <= stats.attack_distance:
		look_at(current_target.global_position)
		if attack_cooldown <= 0.0:
			_perform_attack(current_target)
	else:
		_move_towards(current_target.global_position, delta)

func _handle_movement(delta: float):
	var dest = _get_lane_goal_pos()
	_move_towards(dest, delta)

func _on_died(unit: UnitBase):
	emit_signal("died", unit)
