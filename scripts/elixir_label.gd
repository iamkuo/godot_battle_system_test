extends Label

@export var max_elixir:int = 10

func update_elixir_display(current_amount: int):
	text = "Elixir: %d/%d" % [current_amount, max_elixir]
