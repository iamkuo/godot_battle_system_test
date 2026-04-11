# Project Diff: battle_system_test vs godot-battle-system-test-main-(1)

## Overview
This document compares `battle_system_test` with `godot-battle-system-test-main-(1)` reference project.

---

## Scripts Comparison

### game_manager.gd

| Feature | battle_system_test | reference |
|---------|-------------------|-----------|
| Type annotations | Yes (`func _ready() -> void:`) | No |
| Node references | `@onready` with type hints | `var` without type hints |
| Team enum | `enum Team {PLAYER = 0, OPPONENT = 1}` | Uses raw `int` (0, 1) |
| AI spawn chance | Has `AI_SPAWN_CHANCE: float = 0.8` | No spawn chance check |
| Spawn point naming | `R_Top`, `R_Middle`, `L_Top` | `R_Top`, `R_Middle`, `L_Top` (same) |
| Elixir reference | `get_tree().current_scene.get_node("UI/SpawnUI")` | `main.get_node("UI/UIPanel/ElixirSystem")` |
| AI spawn logic | Spawns OPPONENT units | Spawns team 1 units |
| Player input | Spawns at fixed spawn point | Spawns at player position |

### archer.gd (Unit Movement)

| Feature | battle_system_test | reference |
|---------|-------------------|-----------|
| HP check in `_physics_process` | Added: `if hp <= 0: die(); return` | Missing |
| Attack timer | Added: `attack_timer = max(0.0, attack_timer - delta)` | Missing |
| No target behavior | Moves to lane goal (`get_lane_goal_pos()`) | **Returns early - units idle!** |
| `find_target()` lane filter | Commented out: `#if u.lane != lane: continue` | Same |
| Type annotations | Yes | No |

**Key Fix Applied:** Units now move towards lane goal when no target is found.

**Status:** ✅ Fixed - UnitBase class in scripts/core/ handles this properly.

### opponent_unit.gd (reference only)
- Exists in reference project but NOT in battle_system_test
- Contains proper movement logic (fallback to lane goal)
- Could be imported if needed

### projectile.gd
- **Identical** in both projects

### tower.gd
- Reference has `scripts/tower.gd`
- battle_system_test has `Tower.tscn` referencing `scripts/tower.gd` (same)

### Additional Scripts in Reference

| Script | battle_system_test | reference |
|--------|-------------------|-----------|
| `control.gd` | Missing | Exists (elixir system as Control) |
| `elixir.gd` | Missing (uses `spawn_ui.gd`) | Exists |
| `elixir_label.gd` | Missing | Exists |
| `card_button.gd` | ✅ Exists | Exists (button for spawning) |
| `character_body_2d.gd` | Exists (player movement) | Exists (same) |

---

## Scenes Comparison

### Scene Structure

| Path (reference) | Path (battle_system_test) | Status |
|------------------|--------------------------|--------|
| `scenes/cards/alley/archer.tscn` | `scenes/units/cards/alley_archer.tscn` | Renamed |
| `scenes/cards/alley/allies_projectile.tscn` | `scenes/units/projectiles/allies_projectile.tscn` | Renamed |
| `scenes/cards/opponent/opponent_archer.tscn` | `scenes/units/cards/opponent_archer.tscn` | Renamed |
| `scenes/cards/opponent/opponents_projectile.tscn` | `scenes/units/projectiles/opponents_projectile.tscn` | Renamed |

### Unit Scene Scripts

| Scene | Script (reference) | Script (battle_system_test) |
|-------|-------------------|----------------------------|
| opponent_archer.tscn | `opponent_unit.gd` | `unit.gd` (MISSING!) |

**Issue:** `opponent_archer.tscn` references `scripts/unit.gd` which doesn't exist in battle_system_test!

---

## Key Issues Found

1. **Missing `scripts/unit.gd`** - Referenced by `opponent_archer.tscn` but file doesn't exist
2. **Unit movement bug** - Fixed: units now move to lane goal when no target
3. **Scene path differences** - All scenes moved from `scenes/cards/` to `scenes/units/cards/`
4. **Script structure differences** - battle_system_test has more type annotations

---

## Files to Import (if needed)

Only import if specific features are required:

| File | Reason |
|------|--------|
| `opponent_unit.gd` | Contains proper unit AI logic (optional, fixed in archer.gd) |
| `card_button.gd` | For UI card button spawning (optional) |
| `elixir.gd` | Alternative elixir system (optional) |

---

## Already Fixed

- Unit movement when no target (archer.gd:26-50)
- Created scripts/unit.gd (was missing, now exists)
- Created scripts/core/unit_base.gd (abstract base class)
- Created scripts/core/unit_stats.gd (custom resource)
- Created scripts/core/behavior_pattern.gd (resource for behavior patterns)
- Type annotations added to all functions
- Scene structure organized (scenes/units/)

---

## Merge Strategy

### Recommended Approach: Selective Import

**Do NOT do a full merge.** The projects have diverged in structure. Instead, selectively import only what's needed.

### Phase 1: Keep battle_system_test as Base (Recommended)

battle_system_test has better code quality:
- Type annotations on all functions ✅
- Fixed unit movement (moves to lane goal when no target) ✅
- Better organized scene structure (`scenes/units/`) ✅
- Unit system foundation (UnitBase, UnitStats, BehaviorPattern) ✅

**Action:** Keep battle_system_test structure, only import missing features.

### Phase 2: Scripts to Import (Priority Order)

| Priority | Script | When to Import |
|----------|--------|----------------|
| High | `card_button.gd` | If you want UI card buttons for spawning |
| Medium | `elixir.gd` | If you want separate elixir system node |
| Low | `elixir_label.gd` | Only if using elixir.gd |

### Phase 3: Scenes to Align

If you want to use reference scenes, update paths:

| Reference Path | Target Path |
|----------------|-------------|
| `scenes/cards/alley/archer.tscn` | `scenes/units/cards/alley_archer.tscn` |
| `scenes/cards/opponent/opponent_archer.tscn` | `scenes/units/cards/opponent_archer.tscn` |

**Or** update `game_manager.gd` preload paths to reference scenes.

### Phase 4: game_manager.gd Differences

Key decisions:

1. **Team enum vs raw int:**
   - Keep `enum Team {PLAYER, OPPONENT}` (battle_system_test) - more readable

2. **AI spawn chance:**
   - Keep `AI_SPAWN_CHANCE: float = 0.8` (battle_system_test) - better control

3. **Player spawn position:**
   - Reference spawns at player position (more dynamic)
   - battle_system_test spawns at fixed point (simpler)
   - **Suggestion:** Keep fixed spawn for now, can change later

4. **Elixir reference path:**
   - battle_system_test: `UI/SpawnUI`
   - Reference: `UI/UIPanel/ElixirSystem`
   - **Suggestion:** Keep current path, update if changing UI structure

### Phase 5: Files to NOT Import (Duplicates/Redundant)

| File | Reason |
|------|--------|
| `opponent_unit.gd` | Logic merged into `unit.gd` |
| `control.gd` | Redundant with `spawn_ui.gd` |
| `archer.gd` (reference) | battle_system_test has better version |

### Quick Merge Checklist

```markdown
[ ] Keep battle_system_test as main project
[ ] Import card_button.gd if UI card buttons needed
[ ] Update scene preloads in game_manager.gd if using reference scenes
[ ] Keep type annotations in battle_system_test scripts ✅
[ ] Keep fixed unit movement (archer.gd:26-50) ✅
[ ] Keep scripts/unit.gd (already created) ✅
[ ] Keep scripts/core/unit_base.gd ✅
[ ] Keep scripts/core/unit_stats.gd ✅
[ ] Keep scripts/core/behavior_pattern.gd ✅
[ ] Update PROJECT_ANALYSIS.md with new structure ✅
```

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Scene path conflicts | Medium | Update preloads before importing scenes |
| Duplicate script names | Low | Reference has different script names |
| UI structure mismatch | Medium | Match elixir node paths first |

---

## Summary

**Recommended: Selective merge only.**

battle_system_test has better code quality (type annotations, fixed unit movement). Only import `card_button.gd` if you need UI card buttons. Don't import scenes - keep current structure.
