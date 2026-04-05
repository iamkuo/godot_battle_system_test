extends Node2D
@export var hp:int = 1000
@export var team:int = 0
@export var lane:int = 1

func _ready():
	add_to_group("towers")

func take_damage(amount:int):
	hp -= amount
	if hp <= 0:
		on_destroyed()

func on_destroyed():
	var gm = get_tree().root.get_node("Main")
	if gm:
		gm.on_tower_destroyed(self)
	queue_free()
