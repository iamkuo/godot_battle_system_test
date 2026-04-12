extends Control
signal elixir_changed(current:int)

@export var max_elixir:int = 10
@export var regen_per_sec:float = 1.0
var current: float = 5.0
var last_update_time: float = 0.0

@onready var elixir_bar: ProgressBar = $ElixirUI/ElixirBar
@onready var elixir_label: Label = $ElixirUI/ElixirLabel
@onready var cards_container: Control = $CardsUI/Panel/CardsContainer

var card_scene: PackedScene = preload("res://scenes/ui/card.tscn")

func _ready():
	# Initialize the progress bar
	if elixir_bar:
		elixir_bar.max_value = max_elixir
		elixir_bar.value = current
	# Connect to our own signal to update UI
	elixir_changed.connect(_update_ui)
	# Auto-generate cards from unit stats resources
	_generate_cards()

func _generate_cards():
	var stats_dir = "res://resources/unit_stats/"
	var dir = DirAccess.open(stats_dir)
	if not dir:
		push_warning("Cannot open unit stats directory: " + stats_dir)
		return
	
	var files = dir.get_files()
	for file in files:
		file = file.trim_suffix(".remap")
		if file.ends_with(".tres") or file.ends_with(".res"):
			var stats_path = stats_dir + file
			var stats = load(stats_path)
			if stats and stats is UnitStats and stats.team == 0:
				_create_card(stats)

func _create_card(stats: UnitStats):
	var card = card_scene.instantiate()
	card.unit_stats = stats
	card.name = stats.resource_name
	cards_container.add_child(card)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_TAB and event.pressed):
		visible = not visible

func _process(delta):
	current = min(max_elixir, current + regen_per_sec * delta)
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_update_time >= 1.0:
		last_update_time = now
		emit_signal("elixir_changed", int(floor(current)))

func _update_ui(current_amount: int):
	if elixir_bar:
		elixir_bar.value = current_amount
	if elixir_label:
		elixir_label.text = "%d/%d" % [current_amount, max_elixir]

func try_consume(amount:int) -> bool:
	if int(floor(current)) >= amount:
		current -= amount
		emit_signal("elixir_changed", int(floor(current)))
		if elixir_label:
			elixir_label.text = "%d/%d" % [int(floor(current)), max_elixir]
		return true
	return false



func get_current_int() -> int:
	return int(floor(current))
