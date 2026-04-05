extends Area2D
@export var speed: float = 700.0
var damage: int = 20
var target: Node = null

func _physics_process(delta):
	if not is_instance_valid(target):
		queue_free()
		return
	var dir = (target.global_position - global_position)
	if dir.length() < 8:
		hit_target()
		return
	global_position += dir.normalized() * speed * delta

func hit_target():
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()
