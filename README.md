# Haiku Pac

An original Pac-Man-style game in Godot 4.5. Two maze modes: **Default** (original layout) and **Classic** (a recreation, see `CREDITS.md`). Target: HTML5 export, with desktop runs during development.

Design: [`GDD.md`](GDD.md). Build order and tests: [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md).

## Features

- [x] Project skeleton, input map, autoloads (Milestone 0)
- [x] Maze from data, both layouts, rendering, headless tests (Milestone 1)
- [x] Pac-Man movement, queued turns, dots and energizers, score (Milestone 2)
- [x] Ghosts move and leave the house, collisions cost a life (Milestone 3)
- [x] Ghost AI targeting, scatter/chase cycle (Milestone 4)
- [x] Power pellets, frightened ghosts, eating ghosts (Milestone 5)
- [x] Levels, fruit, lives (Milestone 6)
- [x] Title screen, HUD, pause, high score (Milestone 7)
- [x] Procedural sound and polish (Milestone 8)
- [ ] HTML5 release build (Milestone 9)
- [ ] Music (later, after v1)

## Running

Open the project in Godot 4.5, or run it from the command line. See `CLAUDE.md` → Commands for the editor scan and the test command.

## License

GPL-3.0. See `LICENSE` and `CREDITS.md`.
