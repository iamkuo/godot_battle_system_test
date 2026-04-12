class_name UnitControlPanel
extends Control

var selected_unit: UnitBase = null
var current_pattern: BehaviorPattern = null

@onready var pattern_buttons: Array[Button] = []

func _ready():
	visible = false
	_create_pattern_buttons()

func _create_pattern_buttons():
	var patterns = [
		BehaviorPattern.PatternType.STAY,
		BehaviorPattern.PatternType.FOLLOW_PLAYER,
		BehaviorPattern.PatternType.ATTACK_NEAREST_ENEMY,
		BehaviorPattern.PatternType.ATTACK_NEAREST_TOWER
	]

	for i in patterns.size():
		var btn = Button.new()
		btn.text = BehaviorPattern.get_pattern_name(patterns[i])
		btn.pressed.connect(_on_pattern_selected.bind(patterns[i]))
		pattern_buttons.append(btn)

func show_for_unit(unit: UnitBase):
	selected_unit = unit
	visible = true
	global_position = unit.get_global_transform_with_canvas().origin + Vector2(60, -60)

func _on_pattern_selected(pattern_type: int):
	if not selected_unit:
		return

	var new_pattern = BehaviorPattern.new()
	new_pattern.pattern_type = pattern_type
	selected_unit.set_behavior_pattern(new_pattern)
	hide_panel()

func hide_panel():
	visible = false
	selected_unit = null
