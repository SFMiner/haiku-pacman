# Haiku Pac — Game Design Document (draft v0.1)

Draft 2026-10-22. Godot 4.5, GDScript, GL Compatibility. **Target: HTML5 export** (desktop runs are for development only).
Title: "Haiku Pac" (original name, not the trademarked one).

**Goal:** a faithful-feeling maze-chase game in the spirit of the 1980 arcade classic. Same core loop, same ghost
personalities, original layout, art and sound.

## 1. Core loop
Eat every dot in the maze while four ghosts chase you. A power pellet turns the ghosts blue for a few seconds so you
can eat them for points. Clear the maze to advance. Lose all lives and the game ends. Each level runs faster and the
power pellets last less time.

## 2. Player experience
1. **Title screen:** title, "Press Enter / Space to start", high score, the controls.
2. **Level start:** "Ready!" for about 2 s. Ghosts leave the ghost house one at a time.
3. **Play:** move with arrow keys or WASD. The turn you press is queued and taken at the next open junction, so you
   can pre-turn into corridors.
4. **Death:** a short animation, then a reset of positions. Lives count down.
5. **Level clear:** the maze flashes, then the next level starts.
6. **Game over:** show the score, save it if it's a high score, return to the title.
7. **Pause:** Esc or P. A Pause/Resume button is also shown on screen.

## 3. Rules and tuning
- **Grid:** the maze is 28 × 31 tiles. A tile is 8 logical pixels. The window is 224 × 288 logical pixels, scaled by an
  integer factor.
- **Movement:** everything moves on the tile grid at fixed speeds. Starting values: Pac-Man 80% of a base speed, ghosts
  75%, both in tiles per second. Speeds are set in `data/tuning.json` and tuned in playtests.
- **Dots:** 10 points. **Power pellets:** 50 points and a frightened timer.
- **Ghosts:** Blinky, Pinky, Inky and Clyde.
  - Ghosts can't reverse direction, except when the mode changes.
  - At each junction they choose the direction that gets closest to their target tile. Ties go in the order up, left, down, right.
  - **Scatter / chase cycle:** scatter to a home corner for a few seconds, then chase, repeating. Cycle lengths shorten
    as levels rise.
  - **Chase targets:** Blinky targets Pac-Man's tile. Pinky targets 4 tiles ahead of Pac-Man. Inky uses Blinky's
    position to pick a target. Clyde chases Pac-Man when far away, and retreats to his corner when close.
  - **Frightened:** ghosts turn blue, move slower and randomly, and can be eaten. Eaten ghosts score 200, 400, 800,
    then 1600 for each chained ghost in one pellet. Eaten ghosts return to the ghost house as eyes, then respawn.
  - Ghosts that touch Pac-Man while not frightened kill him.
- **Tunnel:** the middle row wraps left and right. Ghosts slow down inside the tunnel.
- **Fruit:** one bonus item appears after 70 and 170 dots are eaten. It stays for a few seconds. Points rise with level.
- **Lives:** 3 at start. Extra life at 10,000 points, once.
- **Maze mode:** chosen on the title screen. **Default** is the original layout. **Classic** recreates the classic
  arcade maze. Each mode uses one layout, repeated every level.
- **Difficulty:** one arcade-style curve, with no options.
- **Levels:** the maze repeats each level. Ghosts speed up and frightened time shrinks as levels rise, down to a
  floor.

## 4. Art and sound (original, no external assets)
- **Art:** all visuals are drawn in code (`_draw`) from primitives. No image files in v1, which avoids PNG import issues.
  Ghosts are distinct by colour and eye direction, not by shape alone. Colour is never the only cue (blue ghost also
  flashes near the end of its timer).
- **Sound:** procedurally generated `AudioStreamWAV` effects (chomp, power pellet, eat ghost, death, fruit, level
  clear, siren). No music in v1. Procedural audio keeps the web export simple.
- **Text:** a bundled pixel font if one is available, otherwise Godot's default font at integer size.

## 5. Scope
**In v1:** title with maze mode choice (Default or Classic), four ghosts with the rules above, fruit, lives, extra life, high-score
save (local file on desktop, localStorage in the browser), pause, procedural sound, HTML5 export.
**Out of v1:** music (planned for later), more than the two maze modes, controller remapping, online scores, a level
editor.

## 6. Technical plan (summary)
- The game is code-driven, following the Gamedev template: a minimal `Main.tscn` builds the maze and entities in code.
- Maze layouts live in `data/maze_default.txt` and `data/maze_classic.txt` as ASCII (`#` wall, `.` dot, `o` power pellet, `-` ghost door, space = empty).
  Speeds, timers and scores live in `data/tuning.json`. Nothing is hard-coded.
- Movement and AI are pure grid logic (no physics engine). That makes ghost targeting and maze parsing easy to unit-test
  headless.
- Soft pause via `Game.ui_open`, the template convention. Timed logic uses a fixed logic tick, not frame time, so
  behaviour doesn't depend on frame rate.
- **HTML5 is the release target.** Single-threaded export (no COOP/COEP headers needed), GL Compatibility, and the
  browser-safe rules from the Gamedev log (no emoji, no deprecated APIs, check the export with
  `check_web_template.py`).
- High score is saved to `user://` on desktop and to browser localStorage in web builds. Both sit behind one
  `SaveManager` call, with try/catch around every read and write.
- Browsers block audio until a key press, so the first key press unlocks sound.
- A Pause control is on screen, so the game is playable with the mouse or touch as well as the keyboard.

## 7. Decisions and open questions
**Decided (Sean, 2026-10-22):**
1. **Name:** "Haiku Pac", original art and sound. No Pac-Man trademark.
2. **Target:** HTML5 export.
3. **Maze:** two modes, Default (original) and Classic (recreation), chosen on the title screen.
4. **Sound:** procedural effects in v1. Music added later.
5. **Difficulty:** one arcade-style curve.

**Caveat on Classic:** the layout is a recreation of a Bandai Namco arcade maze. Keep it for personal and
development use, or drop it, before any public release. Sean should decide that separately.
