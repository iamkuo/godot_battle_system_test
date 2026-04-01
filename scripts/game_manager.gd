extends Node
@onready var units_container = $unitcontainer/archer
@onready var spawn_points = $SpawnPoints
@onready var ui = $UI
@onready var elixir = $UI/Control/Elixir

var local_team:int = 0
var ai_enabled: bool = true
var ai_timer: float = 0.0

func _ready():
	if elixir:
		elixir.connect("elixir_changed", Callable(self,"_on_elixir_changed"))
	if ui:
		var label = ui.get_node("Control/ElixirLabel") # Point to the actual Label node
		if label:
			label.text = str(elixir.get_current_int())
		#var label = ui.get_node("Control/Elixir")
		if label:
			label.text = str(elixir.get_current_int())
	set_process(true)

func _process(delta):
	if ai_enabled:
		ai_timer -= delta
		if ai_timer <= 0.0:
			ai_timer = randf_range(1.0, 3.5)
			#ai_play_card()

func _on_elixir_changed(val:int):
	if ui:
		var label = ui.get_node("Control/ElixirLabel")
		if label:
			label.text = str(val)

func show_message(txt:String):
	if ui:
		var l = ui.get_node("MsgLabel")
		if l:
			l.text = txt

func can_spawn(team:int, cost:int) -> bool:
	if team == local_team:
		return elixir.get_current_int() >= cost
	else:
		return true

func spawn_unit(packed_scene:PackedScene, pos:Vector2, team:int, lane:int):
	if team == local_team:
		if not elixir.try_consume(3):
			show_message("Not enough Elixir")
			return
	var u = packed_scene.instantiate()
	u.global_position = pos
	u.team = team
	u.lane = lane
	units_container.add_child(u)
	u.add_to_group("units")
	if u.has_node("Sprite2D"):
		var s = u.get_node("Sprite2D")
		s.flip_h = (team == 1)

func get_spawn_point(team: int, lane: int) -> Vector2:
	var spawn_node_name = ""
	
	if team == 0: # 左側隊伍
		match lane:
			0: spawn_node_name = "Spawn_L_Top"
			1: spawn_node_name = "Spawn_L_Mid"
			2: spawn_node_name = "Spawn_L_Bot"
	else: # 右側隊伍
		match lane:
			0: spawn_node_name = "Spawn_R_Top"
			1: spawn_node_name = "Spawn_R_Mid"
			2: spawn_node_name = "Spawn_R_Bot"

	# 檢查節點是否存在，避免當機
	if spawn_points.has_node(spawn_node_name):
		var p = spawn_points.get_node(spawn_node_name)
		return p.global_position
	
	push_error("找不到生成點節點: " + spawn_node_name)
	return Vector2.ZERO

func on_tower_destroyed(tower:Node):
	var winner = 1 - tower.team
	show_message("Team %d won!" % winner)
	get_tree().paused = true

func _on_ai_card_timer_timeout():
	ai_play_card()
func ai_play_card():
	var cards = [ preload("res://scenes/cards/archer.tscn") ]
	var pick = randi() % cards.size()
	var lane = randi() % 3
	var pos = get_spawn_point(1, lane)
	spawn_unit(cards[pick], pos, 1, lane)
#func _input(event):
	# 當按下你設定的 "spawn_ai_unit" 動作時
	#if event.is_action_pressed("spawn_ai_unit"):
		# 呼叫原本的 AI 出牌函數
		#ai_play_card()
		# 如果你想在畫面上顯示提示
		#show_message("手動生成單位！")

# 如果你沒有去設定 Input Map，也可以直接用這個簡單版本（偵測 Enter 鍵）
# func _input(event):
# 	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
# 		ai_play_card()


#func _input(event):
	#if event.is_action_pressed("po"): # 需在 Input Map 設定
		#manual_spawn_at_lane(0)
	#elif event.is_action_pressed("pu"):
		#manual_spawn_at_lane(1)
	#elif event.is_action_pressed("py"):
		#manual_spawn_at_lane(2)

#func manual_spawn_at_lane(lane_index: int):
	#var cards = [ preload("res://scenes/cards/archer.tscn") ]
	#var pos = get_spawn_point(local_team, lane_index)
	#spawn_unit(cards[0], pos, local_team, lane_index)
func _input(event):
	if event.is_action_pressed("po"): # 需在 Input Map 設定
		manual_spawn_at_lane(0)

func manual_spawn_at_lane(lane_index: int):
	var cards = [ preload("res://scenes/cards/archer.tscn") ]
	var pos = get_spawn_point(local_team, lane_index)
	spawn_unit(cards[0], pos, local_team, lane_index)
