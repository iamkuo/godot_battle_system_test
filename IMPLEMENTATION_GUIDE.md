# Implementation Guide: Quick Fixes

This guide will walk you through implementing the most critical improvements.

---

## 🚀 Quick Fix #1: Unit Spawn Limit (15 min)

### Problem
Units can spawn infinitely; elixir regenerates without cap.

### Steps

**Step 1**: Add unit counting to game_manager.gd

Find the `_ready()` function and add after line 28:
```gdscript
var unit_count: int = 0
var max_units: int = 10
```

**Step 2**: Update `spawn_unit()` function (replace entire function)
```gdscript
func spawn_unit(packed_scene: PackedScene, pos: Vector2, team: int, lane: int):
	# Check unit limit FIRST (all teams)
	if team == local_team and unit_count >= max_units:
		show_message("Max units reached!")
		return
	
	# Then check elixir
	if team == local_team:
		if not elixir.try_consume(ELIXIR_COST):
			show_message("Not enough Elixir")
			return
	
	# Spawn the unit
	var unit = packed_scene.instantiate()
	unit.global_position = pos
	unit.team = team
	unit.lane = lane
	
	if team == local_team:
		allies_container.add_child(unit)
		unit_count += 1
	else:
		opponents_container.add_child(unit)
	
	unit.add_to_group("units")
	
	# Flip sprite for opposing team
	var sprite = unit.get_node_or_null("Sprite2D")
	if sprite:
		sprite.flip_h = (team == 1)
	
	# Track when unit dies to decrement count
	if unit.has_signal("died"):
		unit.died.connect(func(_u): unit_count -= 1)
```

**Step 3**: Test
- Run the game
- Try spawning more than 10 units
- Should see "Max units reached!" message

---

## 🚀 Quick Fix #2: Input Action (5 min)

### Problem
`_input(event)` checks for action "po" which doesn't exist.

### Steps

**Step 1**: Open your InputMap
- Project → Project Settings → Input Map tab

**Step 2**: Create new action
- Type "spawn_unit" in the action field
- Click "Add"

**Step 3**: Add keyboard binding
- Click "spawn_unit" action
- Click "+ Add Event"
- Press keyboard key (e.g., "P" for your test, or Space)
- Confirm

**Step 4**: Update game_manager.gd line 51
```gdscript
func _input(event):
	if event.is_action_pressed("spawn_unit"):  # Changed from "po"
		var pos = get_spawn_point(local_team, 0)
		if pos == Vector2.ZERO:
			push_error("Invalid spawn point for team %d" % local_team)
			return
		spawn_unit(AVAILABLE_CARDS[0], pos, local_team, 0)
```

**Step 5**: Test
- Run game
- Press your new key
- Should spawn Archer unit

---

## 🚀 Quick Fix #3: Spawn Point Validation (10 min)

### Problem
Hardcoded spawn point names are error-prone; no validation.

### Steps

**Step 1**: Create new file `scripts/spawn_point_manager.gd`
```gdscript
extends Node2D
class_name SpawnPointManager

var spawn_points: Dictionary = {}

func _ready() -> void:
	# Load all spawn points from children
	for child in get_children():
		spawn_points[child.name] = child
		print("Registered spawn point: " + child.name)
	
	# Validate required points
	var required_points = ["L_Top", "L_Middle", "L_Bottom", "R_Top", "R_Middle", "R_Bottom"]
	for point_name in required_points:
		if not point_name in spawn_points:
			push_error("Missing spawn point: " + point_name)

func get_spawn_point(team: int, lane: int) -> Vector2:
	var point_name = ""
	
	if team == 0:  # Left team
		match lane:
			0: point_name = "L_Top"
			1: point_name = "L_Middle"
			2: point_name = "L_Bottom"
	else:  # Right team
		match lane:
			0: point_name = "R_Top"
			1: point_name = "R_Middle"
			2: point_name = "R_Bottom"
	
	if point_name in spawn_points:
		return spawn_points[point_name].global_position
	
	push_error("Spawn point not found: " + point_name)
	return Vector2.ZERO
```

**Step 2**: Update game_manager.gd
```gdscript
@onready var spawn_point_manager = get_tree().current_scene.get_node_or_null("SpawnPoints")

func _ready():
	# ... existing code ...
	
	# Add this validation
	if not spawn_point_manager or not spawn_point_manager.has_method("get_spawn_point"):
		push_error("SpawnPointManager not found or misconfigured!")
	else:
		print("SpawnPointManager loaded successfully")

func get_spawn_point(team: int, lane: int) -> Vector2:
	if spawn_point_manager:
		return spawn_point_manager.get_spawn_point(team, lane)
	return Vector2.ZERO
```

**Step 3**: Update scene
- In Main.tscn, attach the spawn point manager script to the SpawnPoints node
- Run game in editor
- Check console for "Registered spawn point" messages

---

## 🚀 Quick Fix #4: Add Debug HUD (20 min)

Creates overlay showing game state.

### Steps

**Step 1**: Create new file `scripts/debug_hud.gd`
```gdscript
extends CanvasLayer

var font: Font
var debug_text: String = ""

func _ready():
	layer = 100  # Always on top
	font = ThemeDB.fallback_font

func _process(_delta):
	var gm = get_tree().root.get_node_or_null("Main")
	if not gm:
		return
	
	var elixir_val = gm.elixir.get_current_int() if gm.elixir else 0
	var max_elixir = gm.elixir.max_elixir if gm.elixir else 0
	
	debug_text = """
	=== DEBUG HUD ===
	Player Units: %d / %d
	Opponent Units: [Active]
	Elixir: %d / %d
	FPS: %d
	""" % [
		gm.unit_count,
		gm.max_units,
		elixir_val,
		max_elixir,
		Engine.get_frames_per_second()
	]
	
	queue_redraw()

func _draw():
	if not font:
		return
	
	draw_string_outline(
		font,
		Vector2(10, 20),
		debug_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color.BLACK,
		Color.WHITE
	)
```

**Step 2**: Add to Main.tscn
- Add new CanvasLayer as child of Main
- Attach debug_hud.gd script
- Check game - should see stats in top-left

---

## 🎯 Implementation Order

1. **Day 1**: Fix #1 (spawn limit) + Fix #2 (input) - Takes 20 min
2. **Day 2**: Fix #3 (spawn points) - Takes 10 min
3. **Day 3**: Fix #4 (debug HUD) - Takes 20 min

---

## ✅ Validation Checklist

After each fix, verify:

### Fix #1
- [ ] Spawn 10 archers → 11th spawn shows message
- [ ] AI can still spawn infinite units (that's okay for now)
- [ ] Elixir continues to regenerate

### Fix #2
- [ ] Assigned input action shows in project settings
- [ ] Pressing key spawns unit
- [ ] Console shows no "Action 'po' not found" errors

### Fix #3
- [ ] Console shows "Registered spawn point: L_Top" etc.
- [ ] No "Spawn point not found" errors
- [ ] Units spawn at correct positions

### Fix #4
- [ ] Debug HUD visible in top-left
- [ ] Shows correct unit count
- [ ] Updates every frame

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Action 'po' not found" error | Create "spawn_unit" in InputMap |
| Units spawn at (0, 0) | Check SpawnPoints node exists and is visible in editor |
| spawn_unit() function not working | Verify `unit_count` variable added to `_ready()` |
| Debug HUD not showing | Verify CanvasLayer is child of Main and script attached |
| Spawning 11+ units still works | Make sure `unit_count -= 1` doesn't have typo |

---

## Pro Tips

1. **Test in Editor**: Press F5 to run main scene, F6 to reload script
2. **Use Breakpoints**: Click line number to set breakpoint, step through code
3. **Check Console**: F8 opens debug console showing all errors/warnings
4. **Save Often**: Ctrl+S after each change

---

## Next Steps After Quick Fixes

Once the 4 quick fixes are done, you're ready for:
1. Add more card types (Tank, Speeder)
2. Create wave system
3. Add health bars to towers
4. Implement game end conditions
5. Polish UI

Good luck! 🚀
