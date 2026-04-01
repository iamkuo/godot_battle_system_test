extends Control
signal elixir_changed(current:int)

@export var max_elixir:int = 10
@export var regen_per_sec:float = 1.0
var current: float = 5.0

func _process(delta):
	current = min(max_elixir, current + regen_per_sec * delta)
	emit_signal("elixir_changed", int(floor(current)))

func try_consume(amount:int) -> bool:
	if int(floor(current)) >= amount:
		current -= amount
		emit_signal("elixir_changed", int(floor(current)))
		return true
	return false

func get_current_int() -> int:
	return int(floor(current))
