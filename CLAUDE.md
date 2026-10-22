# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## License

GPL-3.0 (`LICENSE`), because the Classic maze layout is copied from a GPL-3.0 project. Credits in `CREDITS.md`.
Don't add code or data from other sources without checking their license and recording it there.

## Goal

Build a Pac-Man clone in Godot 4.5. Design: `GDD.md` (draft, not yet approved). Build order and tests: `IMPLEMENTATION_PLAN.md`.

## Subagents

Subagents are allowed for this project, with one rule: every subagent must use the Haiku model (`model: "haiku"`, i.e. `claude-haiku-5-5`). Do not spawn Sonnet or Opus subagents here, even though the global CLAUDE.md prefers Sonnet. This project rule takes precedence for this repo.

## Project state

This is a bare Godot 4.5 project (GL Compatibility renderer, `project.godot`). It has no scripts, scenes, tests, lint config or README yet, and `config/name` is still the template default `"New Game Project"`.

## Version control

Git repo with remote `origin` at GitHub `SFMiner/haiku-pacman` (public). Keep it updated: commit and push after each meaningful change. Repo-local git identity is set to Sean's personal account, not the global school identity. `.gitignore` excludes `.godot/`.

## Commands

Godot 4.5 stable is one level up, at `C:\Users\seanm\Nextcloud2\Gamedev\GodotGames\Godot_v4.5-stable_win64.exe` (PowerShell):

```powershell
& "C:\Users\seanm\Nextcloud2\Gamedev\GodotGames\Godot_v4.5-stable_win64.exe" --headless --path "C:\Users\seanm\Nextcloud2\Gamedev\GodotGames\haiku-game" --editor --quit-after 250
```

- This is the primary check. Expect no `SCRIPT ERROR`, `Parse Error` or `not found`. It also registers `class_name`s and imports assets.
- No test runner or linter exists yet. When tests are added, record the single-test command here.

## Conventions

GDScript and Godot conventions come from the shared Gamedev learning log (`..\..\CLAUDE.md`, auto-loaded for this tree). Do not copy its lessons here. Add only rules specific to this game.

## Architecture

None to document yet. When scripts and scenes appear, add the big-picture structure here: autoloads, scene flow, and how the main loop is wired.
