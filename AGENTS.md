# Repository Guidelines

parabola is a 2D action platformer built with Godot 4.7 (GL Compatibility renderer) using GDScript. These guidelines keep the project organized and consistent.

## Project Structure & Module Organization

- `project.godot` — project configuration, input actions, and autoloads.
- `scenes/` — Godot scenes grouped by category: `characters/`, `general/`, `items/throwable/`, `levels/demo/`.
- `scripts/` — GDScript files that mirror scene categories (`scripts/characters/player.gd` pairs with `scenes/characters/player.tscn`).
- `global/` — autoload scripts. `world_event_bus.gd` is registered as `WorldEventBus` and acts as the signal hub for decoupled communication (for example, camera limits).
- `assets/` — imported assets such as tiles.
- `docs/` — documentation, written in Chinese: `design.md` is the game design spec, `precautions.md` collects gotchas (read both before designing new systems).
- `gdext/` — local native-extension work; it is gitignored and must not be committed.
- `.agents/` — local GodotPrompter skill library, gitignored; do not commit changes to it.
- `WorldEventBus` signals must be emitted with `call_deferred` (or via `await`): emitting synchronously in `_ready` runs before other nodes' `_ready` connections, so receivers miss the event (see `scripts/levels/world.gd`).

## Build, Test, and Development Commands

- Open `project.godot` in Godot 4.7.1 (the editor path is configured in `.vscode/settings.json`).
- Run the game: press F5 in the editor, or run `godot --path .` from the command line.
- Open the editor from the CLI: `godot --path . --editor`.
- There is no build step; GDScript runs directly and Godot imports assets on first open. Never commit generated `.godot/` files.

## Coding Style & Naming Conventions

- Use tabs for indentation; UTF-8 encoding and LF line endings are enforced by `.editorconfig` and `.gitattributes`.
- Follow GDScript conventions: `snake_case` for variables, functions, and signals; `PascalCase` for classes; `_` prefix for private members (`_gravity`, `_on_world_limit_data_changed`).
- Use type hints and explicit return types (`func move(delta: float) -> void`), `@export` for configurable values, and `:=` for inferred locals.
- Document public members with `##` doc comments; existing comments are written in Chinese.
- Input actions use a `player_` prefix (`player_move_left`, `player_jump`), and physics layer names are meaningful (`world`, `player`, `item`).
- No linter is configured; follow the official GDScript style guide.

## Testing Guidelines

- No automated test framework is configured yet.
- Verify changes manually by running the game from `scenes/levels/demo/world.tscn`.
- If you introduce a test framework, update this section with the run commands and naming conventions.

## Commit & Pull Request Guidelines

- Match the existing history: one concise Chinese sentence describing the change, for example `实现玩家基础移动逻辑`.
- Keep each commit focused on a single behavior; add a body explaining rationale when it is not obvious.
- Pull requests need a description covering motivation, what changed, and how it was verified. Include screenshots or recordings for visual or gameplay changes, and link any related issue.
