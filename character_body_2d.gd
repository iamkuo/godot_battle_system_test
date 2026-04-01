extends CharacterBody2D

@export var speed: float = 200.0
var coin_counter = 0

func _physics_process(_delta: float) -> void:
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("ui_left","ui_right")
	input_vector.y = Input.get_axis("ui_up","ui_down")
	input_vector = input_vector.normalized()
	velocity = input_vector * speed
	move_and_slide()
	
	
	
	#   $"../archer".position = $".".global_position ssssss
	


	
