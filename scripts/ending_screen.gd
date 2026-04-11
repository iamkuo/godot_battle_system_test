extends Control

@export var win_color: Color = Color.GREEN
@export var lose_color: Color = Color.RED
@export var player_team: int = 0

@onready var result_label: Label = $BackgroundPanel/VBoxContainer/ResultLabel
@onready var background: Panel = $BackgroundPanel

func _ready():
	visible = false

func show_result(winning_team: int):
	visible = true

	if winning_team == player_team:
		result_label.text = "VICTORY!"
		result_label.modulate = win_color
	else:
		result_label.text = "DEFEAT"
		result_label.modulate = lose_color

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
