class_name UnitSelectionCircle
extends Node2D

var target_unit: UnitBase = null
var radius: float = 50.0
var visible_state: bool = false

func _ready():
	visible = false
	z_index = 100

func show_for_unit(unit: UnitBase):
	target_unit = unit
	radius = unit.stats.attack_distance
	visible = true

func hide_circle():
	target_unit = null
	visible = false

func _draw():
	if not visible:
		return

	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color.GREEN, 2.0)

	if target_unit:
		var dir = Vector2(1, 0)
		draw_line(Vector2.ZERO, dir * radius, Color.YELLOW, 2.0)

func _process(_delta):
	if visible:
		queue_redraw()
