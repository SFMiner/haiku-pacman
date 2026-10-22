# Haiku Pac — Implementation Plan

Derived from `GDD.md` (draft v0.1). Each milestone ends with the game booting and the new feature demoable. Check off
items as they're done.

**Engine:** Godot 4.5, GDScript (tabs, type hints). **Renderer:** GL Compatibility. **Target:** HTML5 export
(desktop runs during development). Browser rules are checked from Milestone 0 onward, not saved for the end.
**Conventions:** the shared Gamedev learning log (`..\..\CLAUDE.md`) applies. Subagents are Haiku only (see `CLAUDE.md`).

**Current state:** scaffold only. `project.godot` still has the template name, no scripts, no scenes, no tests.

---

## Guiding principles
1. **Pure logic first.** Maze parsing, movement, ghost targeting and scoring are plain GDScript with no node
   dependencies, so they can be unit-tested headless.
2. **Data-driven.** The maze is `data/maze.txt`; tuning is `data/tuning.json`. Nothing is hard-coded.
3. **Fixed logic tick.** Movement and timers step on a fixed tick, so behaviour doesn't change with frame rate.
4. **Runnable at every milestone.**

---

## Milestone 0 — Project skeleton
**Goal:** the project boots to an empty window at the right size, with folders and autoloads in place.

- [x] `project.godot`: `config/name="Haiku Pac"`. Window 224 × 288 logical, stretch `canvas_items`, integer scale,
      pixel-art defaults (nearest filter, no mipmaps).
- [x] HTML5 export preset: single-threaded (`thread_support=false`), output folder `build/web/` for now (Pages location
      to be confirmed), "Export With Debug" unticked. Preset points at the matching zip in `godot-2d-web-template\` (see Milestone 9).
- [x] Folders: `scripts/`, `scenes/` created. `data/` and `tests/` get created with their first files, since git doesn't track empty folders.
- [x] Input actions: `move_up`, `move_down`, `move_left`, `move_right` (arrows and WASD), `start` (Enter, Space),
      `pause` (Esc, P).
- [x] `scenes/main.tscn`: minimal root with `main.gd` attached. It builds everything else in code.
- [x] Autoload `scripts/game.gd` (`Game`): `ui_open: bool`, `score`, `high_score`, `lives`, `level`, and signals
      `score_changed`, `lives_changed`, `level_changed`.
- [x] Autoload `scripts/sfx.gd` (`Sfx`): empty stub with `play(name: String)`.

**Done when:** the window opens at the right size and closes cleanly.
**Check:** `--headless --editor --quit-after 250` reports no `SCRIPT ERROR`.

---

## Milestone 1 — Maze from data
**Goal:** the maze appears from `data/maze.txt`.

- [x] `data/maze_default.txt` (original) and `data/maze_classic.txt` (recreation): 28 × 31 ASCII each (`#` wall,
      `.` dot, `o` power pellet, `-` ghost door, space = empty, `P` Pac-Man start, `G` ghost start points, `F` fruit
      spot). Both files must have the same dimensions and start markers.
- [x] Classic layout: taken from bobeff/pacman (GPL-3.0), checked against the arcade counts (240 dots, 4 energizers).
      Credited in `CREDITS.md`. Default layout: original, see `CREDITS.md`.
- [x] `scripts/maze.gd` (`class_name Maze`, pure logic): loads a file by mode, exposes `is_wall(tile)`, `is_door(tile)`,
      `tile_kind(tile)`, `size`, `wrap(tile)` (tunnel row wrap), `dot_count()`.
- [x] `scripts/maze_view.gd`: draws walls and dots from `Maze` with `_draw`, batched into one draw pass (per the
      Gamedev batching lesson).
- [x] Dots and pellets are removed as eaten, via `Maze.eat()` and `MazeView.erase_tile()`, not by freeing nodes.

**Done when:** the maze draws correctly and the dot count matches a value written by hand in the test.
**Tests:** `tests/test_maze.gd`. Load the file, check dimensions, wall count, dot count and tunnel wrap.

---

## Milestone 2 — Pac-Man movement and dots
**Goal:** Pac-Man moves through the maze, takes queued turns, eats dots and scores.

- [x] `scripts/grid_mover.gd` (`class_name GridMover`, pure logic): tile position, direction, progress toward the
      next tile, `queued_direction`, `can_move(dir)`, `step()` (one logic tick, returns true on reaching a tile centre).
- [x] `scripts/pacman.gd`: input → `queued_direction`. Turns are taken at the next tile centre where the new direction is open.
- [x] Eating a dot: `Game.score += 10`, `Sfx.play("chomp")`. Power pellet: 50 points.
- [x] Movement runs on the fixed logic tick (`_physics_process`, 60 Hz).
- [x] `data/tuning.json`: Pac-Man speed (80% of base), base speed in tiles/s.

**Done when:** Pac-Man turns into corridors before reaching the junction, eats dots, and the score goes up.
**Tests:** `tests/test_grid_mover.gd` (queued turn is taken only at a centre; blocked turn waits; tunnel wrap).

---

## Milestone 3 — Ghosts move
**Goal:** four ghosts leave the house and roam, without AI targeting yet.

- [ ] `scripts/ghost.gd` (`class_name Ghost`): a `GridMover` with a name, colour and a current mode.
- [ ] Ghost movement rules: no reversal except on mode change; at each junction pick the open direction by priority
      order up, left, down, right.
- [ ] `scripts/ghost_house.gd`: release timers, one ghost at a time, reading `tuning.json`.
- [ ] Ghosts kill Pac-Man on contact: `Game.lives -= 1`, emit a death signal.
- [ ] Death: pause, a short animation, reset all positions. Game over at zero lives.

**Done when:** ghosts leave the house in order, roam, and a collision costs a life and resets.
**Tests:** `tests/test_ghost_rules.gd` (no reversal; priority order at a 4-way junction; release order).

---

## Milestone 4 — Ghost AI targeting
**Goal:** each ghost's chase behaviour matches the GDD.

- [ ] `scripts/ghost_ai.gd` (pure logic, `class_name GhostAI`): `target_tile(ghost_name, pacman_tile, pacman_dir,
      blinky_tile, scatter_corner, distance)`.
  - Blinky → Pac-Man tile. Pinky → 4 tiles ahead of Pac-Man. Inky → vector from Blinky through the tile 2 ahead of
    Pac-Man, doubled. Clyde → Pac-Man when more than 8 tiles away, otherwise his corner.
- [ ] Scatter / chase cycle as a `Game`-owned timer, lengths from `tuning.json`, shortening per level.
- [ ] Known quirk, reproduced on purpose: when Pac-Man faces up, Pinky's target also shifts 4 tiles left (documented
      in `tests`).

**Done when:** each ghost chases the right target in each mode.
**Tests:** `tests/test_ghost_ai.gd`. Table-driven: one row per ghost per case, including the up-facing quirk.

---

## Milestone 5 — Power pellets, frightened ghosts, eating ghosts
**Goal:** the power-pellet loop works end to end.

- [ ] Power pellet: all ghosts enter frightened mode for a timer from `tuning.json`. Ghosts reverse direction once on
      entering it.
- [ ] Frightened movement: random choice at junctions, slower speed.
- [ ] Eating a frightened ghost: score 200, 400, 800, 1600 by chain count within one pellet. The ghost becomes eyes
      and returns to the house by a fixed path, then respawns.
- [ ] Blue ghosts flash near the end of their timer (colour is not the only cue).
- [ ] Sounds: `power`, `eat_ghost`.

**Done when:** a pellet can be used to eat ghosts for the right scores, and the timer ends correctly.
**Tests:** `tests/test_scoring.gd` (chain values 200/400/800/1600, reset after the pellet ends, extra life crossing
10,000 once only).

---

## Milestone 6 — Levels, fruit, lives
**Goal:** the full game loop, with levels and bonuses.

- [ ] Level clear when `Maze.dot_count() == 0`: flash, wait, next level.
- [ ] Level scaling from `tuning.json`: ghost and Pac-Man speed, frightened time, scatter/chase cycle lengths, with a
      floor.
- [ ] Fruit: appears after 70 and 170 dots, stays a few seconds, points by level.
- [ ] Extra life at 10,000 points, once per game.

**Done when:** you can clear level 1, reach level 2 with faster ghosts, and collect fruit.
**Tests:** `tests/test_levels.gd` (scaling values per level, fruit trigger counts, extra-life rule).

---

## Milestone 7 — Screens, HUD, pause, high score
**Goal:** the game can be started, paused, lost and restarted from the menus.

- [ ] Title screen with high score, controls, and a maze mode choice (Default / Classic). Start on Enter or Space.
      The choice is stored with the high score (separate high score per mode).
- [ ] HUD: score, high score, lives icons, level number. Drawn in code.
- [ ] Pause with Esc or P, plus an on-screen Pause/Resume button. Uses `Game.ui_open` (soft pause), so every gameplay
      script checks it and returns early.
- [ ] Game over screen, then back to title.
- [ ] High score saved through one `SaveManager` call: `user://highscore.json` on desktop, a `JavaScriptBridge`
      localStorage branch on web (`OS.has_feature("web")`). Every read and write wrapped in error handling.
- [ ] On-screen Pause/Resume button (touch and mouse as well as keyboard).

**Done when:** start → play → pause → resume → die → game over → title → start again works, and the high score
survives a restart, on desktop and in the browser.
**Check:** `Game.ui_open` is respected by every gameplay script. Pause freezes ghosts, Pac-Man and timers.

---

## Milestone 8 — Procedural sound and polish
**Goal:** the game sounds finished with no audio files.

- [ ] `scripts/sfx.gd`: generate `AudioStreamWAV` for chomp, power, eat_ghost, death, fruit, level_clear, siren.
- [ ] Siren pitch rises with the number of dots left.
- [ ] Screen shake is off by default. Check the game is readable with no effects.

**Done when:** every event in the GDD has a sound, and nothing plays twice on one event.

---

## Later — Music (after v1)
**Goal:** background music. Not part of v1.

- [ ] Choose a music source. Original or properly licensed tracks only. Record the license in `CREDITS.md`.
- [ ] Music on/off setting, persisted with the high score.
- [ ] Web: check the track plays after the first key press, the same as sound effects.

## Milestone 9 — HTML5 release build
**Goal:** a browser build that plays end to end. This is the release target, not an extra.

- [ ] Run `python ..\..\godot-2d-web-template\check_web_template.py <project>` and pick the matching template zip
      (2D or 2D + GUI, depending on what the game uses). Point the preset at that named zip.
- [ ] Export with "Export With Debug" unticked. Confirm the wasm size matches the chosen template.
- [ ] Scan the project for emoji and deprecated GDScript functions (the lean templates drop them).
- [ ] Browser smoke test with Playwright (`chromium.launch({channel: 'chrome'})`), checking the console for any
      `SCRIPT ERROR`: title → play → pause → game over → high score persists after reload.
- [ ] Audio starts after the first key press (browser autoplay rule).
- [ ] Publish to GitHub Pages only after Sean confirms where the build should go (default: `docs/`, ask first).

---

## Testing approach
- Pure-logic tests live in `tests/` and run headless: `tests/run_tests.gd`, a `SceneTree` script that loads each
  `test_*.gd` and prints a pass count.
- Run: `& "C:\Users\seanm\Nextcloud2\Gamedev\GodotGames\Godot_v4.5-stable_win64.exe" --headless --path "C:\Users\seanm\Nextcloud2\Gamedev\GodotGames\haiku-game" --script res://tests/run_tests.gd`
- Trust the pass count, not just zero failures: the total must equal the expected number, since a test that aborts can
  hide tests that never ran.
- Visual checks use a windowed run with a screenshot gate, not headless.

## Commit points
Commit and push at the end of each milestone (see `CLAUDE.md` → Version control).
