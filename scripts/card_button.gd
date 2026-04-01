extends Button
@export var unit_scene: PackedScene
@export var cost:int = 3
var gm:Node = null
var lane:int = 1
var team:int = 0

func _ready():
    gm = get_tree().root.get_node("Main/GameManager")
    connect("pressed", Callable(self,"_on_pressed"))

func _on_pressed():
    if not gm: return
    if not gm.can_spawn(team, cost):
        gm.show_message("Not enough elixir")
        return
    var spawn_pos = gm.get_spawn_point(team, lane)
    gm.spawn_unit(unit_scene, spawn_pos, team, lane)
