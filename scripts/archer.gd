extends CharacterBody2D
signal died(unit)
signal dealt_damage(amount, target)

@export var max_hp: int = 250
@export var atk: int = 100
@export var atk_speed: float = 1.0
@export var move_speed: float = 120.0
@export var attack_range: float = 200.0
@export var detection_range: float = 300.0  # 索敵範圍        
@export var is_ranged: bool = false
@export var projectile_scene: PackedScene
var can_attack: bool = true
var hp:int
var attack_timer: float = 0.0
var team:int = 0
var lane:int = 1
var target:Node = null#current object

func _ready():
	hp = max_hp
	set_physics_process(true)



func _physics_process(delta):
	if hp <= 0:
		die()
		return
	attack_timer = max(0.0, attack_timer - delta)
	
	# 1. If target disappears or dies, clear target
	if not is_instance_valid(target):
		target = find_target()
	
	# 2. Behavior decision
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_range:
			# Close enough, stop and attack
			velocity = Vector2.ZERO
			move_and_slide()
			do_attack(target) 
		else:
			# Within detection range but can't reach, move towards target
			move_towards(target.global_position, delta)
	else:
		# No target, move towards lane goal
		var dest = get_lane_goal_pos()
		move_towards(dest, delta)
		
func move_towards(pos: Vector2, _delta):
	var dir = (pos - global_position)
	
	# 使用 distance_to 判斷更直觀
	if dir.length() < 5: # 緩衝區，避免微小抖動
		velocity = Vector2.ZERO
	else:
		velocity = dir.normalized() * move_speed  
	move_and_slide()

func do_attack(t:Node):
	if not can_attack: return
	if not is_instance_valid(t): return
	if is_ranged and projectile_scene:
		var p = projectile_scene.instantiate()
		p.global_position = global_position
		p.target = t
		p.damage = atk
		get_parent().add_child(p)
		
	else:
		if t.has_method("take_damage"):
			t.take_damage(atk)
			emit_signal("dealt_damage", atk, t)
	can_attack = false
	await get_tree().create_timer(0.7 / atk_speed).timeout
	can_attack = true
func take_damage(amount:int):
	hp -= amount
	if hp <= 0:
		die()

func die():
	emit_signal("died", self)
	queue_free()

func find_target() -> Node:
	var best:Node = null
	var best_dist = 1e9
	for u in get_tree().get_nodes_in_group("units"):
		if u == self: continue
		if u.team == team: continue
		#if u.lane != lane: continue
		var d = global_position.distance_to(u.global_position)
		if d < best_dist:
			best_dist = d
			best = u
	if best:
		return best
	for t in get_tree().get_nodes_in_group("towers"):
		if t.team == team: continue
		if t.lane == lane:
			return t
	return null

func get_lane_goal_pos() -> Vector2:
	var x = 1400 if team == 0 else 200
	return Vector2(x, global_position.y)
