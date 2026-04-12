extends Area2D

enum Team { PLAYER = 0, OPPONENT = 1 }

@export var speed: float = 700.0
@export var max_travel_distance: float = 3200.0
@export var max_lifetime: float = 12.0
@export var face_target: bool = true

var damage: int = 20
var target: Node = null
var team: Team = Team.PLAYER

var _traveled: float = 0.0
var _age: float = 0.0
var _shooter: WeakRef = null

func set_shooter(unit: Node) -> void:
	if unit:
		_shooter = weakref(unit)

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= max_lifetime:
		queue_free()
		return

	if not is_instance_valid(target):
		queue_free()
		return

	var dir = target.global_position - global_position
	if dir.length() < 8:
		hit_target()
		return

	var step = dir.normalized() * speed * delta
	_traveled += step.length()
	if _traveled >= max_travel_distance:
		queue_free()
		return

	global_position += step

	if face_target:
		var spr = get_node_or_null("Sprite2D") as Sprite2D
		if spr:
			spr.flip_h = dir.x < 0

func hit_target() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
		var shooter = _shooter.get_ref() if _shooter else null
		if shooter and shooter.has_signal("dealt_damage"):
			shooter.emit_signal("dealt_damage", damage, target)
	queue_free()
