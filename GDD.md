# Haiku Pac — Game Design Document (draft v0.1)

Draft 2026-10-22. Not approved. Godot 4.5, GDScript, GL Compatibility, desktop first (web export is a later milestone).
Working title only. See open question 1 before any public release.

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
- **Levels:** the mazes repeat after the first. Ghosts speed up and frightened time shrinks as levels rise, down to a
  floor.

## 4. Art and sound (original, no external assets)
- **Art:** all visuals are drawn in code (`_draw`) from primitives. No image files in v1, which avoids PNG import issues.
  Ghosts are distinct by colour and eye direction, not by shape alone. Colour is never the only cue (blue ghost also
  flashes near the end of its timer).
- **Sound:** procedurally generated `AudioStreamWAV` effects (chomp, power pellet, eat ghost, death, fruit, level
  clear, siren). No music in v1. Procedural audio keeps the web export simple.
- **Text:** a bundled pixel font if one is available, otherwise Godot's default font at integer size.

## 5. Scope
**In v1:** title, one maze layout repeating, four ghosts with the rules above, fruit, lives, extra life, high-score
save (local file), pause, procedural sound.
**Out of v1:** multiple maze layouts, music, controller remapping, online scores, a level editor.

## 6. Technical plan (summary)
- The game is code-driven, following the Gamedev template: a minimal `Main.tscn` builds the maze and entities in code.
- Maze layout lives in `data/maze.txt` as ASCII (`#` wall, `.` dot, `o` power pellet, `-` ghost door, space = empty).
  Speeds, timers and scores live in `data/tuning.json`. Nothing is hard-coded.
- Movement and AI are pure grid logic (no physics engine). That makes ghost targeting and maze parsing easy to unit-test
  headless.
- Soft pause via `Game.ui_open`, the template convention. Timed logic uses a fixed logic tick, not frame time, so
  behaviour doesn't depend on frame rate.
- High score saved to `user://`. Web builds will need a `JavaScriptBridge` localStorage branch later.

## 7. Open questions for Sean
1. **Name and trademark.** "Pac-Man" is a Bandai Namco trademark. Keep "Haiku Pac" (or another original name) for any
   public release? The draft assumes yes.
2. **Web target.** Should v1 also export to the browser (sims-site style iframe, or GitHub Pages)? If yes, the web
   milestone follows the sims-site rules (Pause control, Tab/Escape exit).
3. **Maze.** An original layout (the draft's assumption) or a recreation of the classic maze?
4. **Sound and music.** Procedural effects only (the draft), or should I add a music track later?
5. **Difficulty.** Should there be a difficulty option, or keep it as one arcade-style curve?
