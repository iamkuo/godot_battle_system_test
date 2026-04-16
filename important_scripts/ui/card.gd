extends Button
class_name Card

enum Team { PLAYER = 0, OPPONENT = 1 }

signal card_pressed(card: Card)

@export var unit_stats: UnitStats
@export var unit_scene: PackedScene

@onready var cost_label: Label
@onready var name_label: Label
@onready var icon_texture: TextureRect

var gm: Node = null
var lane: int = 1
var team: Team = Team.PLAYER

func _ready():
	gm = get_tree().root.get_node("Main")
	connect("pressed", _on_pressed)
	_setup_ui()

func _setup_ui():
	cost_label = $MarginContainer/VBoxContainer/CostLabel
	name_label = $MarginContainer/VBoxContainer/NameLabel
	icon_texture = $MarginContainer/VBoxContainer/IconTexture
	
	if unit_stats:
		if cost_label:
			cost_label.text = str(unit_stats.cost)
		if name_label:
			name_label.text = unit_stats.resource_name.replace("Stats", "")
		if icon_texture and unit_stats.button_icon:
			icon_texture.texture = unit_stats.button_icon

func _on_pressed():
	if not gm: return
	print("Card pressed: ", unit_stats.resource_name, ", cost=", unit_stats.cost)
	if gm.elixir.get_current_int() < unit_stats.cost:
		print("Not enough elixir")
		MessageManager.show_message("Not enough Elixir")
		return
	if not gm.can_spawn(team, unit_stats.cost):
		print("can_spawn returned false")
		MessageManager.show_message("Not enough Elixir")
		return
	print("Spawning unit via gm")
	gm.spawn_ally(unit_stats, lane)
	emit_signal("card_pressed", self)
	


func _on_mouse_entered() -> void:
	$".".scale = Vector2(1.1, 1.1)
	$".".position.x -= 5
	$".".position.y -= 5
func _on_mouse_exited() -> void:
	$".".scale = Vector2(1.0, 1.0)
	$".".position.x += 5
	$".".position.y += 5
