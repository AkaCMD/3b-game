# Repository Guidelines

## Project Structure & Module Organization
`main.lua` is the game bootstrapping entry point: globals, assets, and scene registration live there. Runtime code lives in `src/`, with scene flow in `src/scenes/`, reusable entity behavior in `src/components/`, and one gameplay object or UI module per file, for example `src/player.lua`, `src/enemy.lua`, and `src/power_up_ui.lua`. Arena edge behavior is currently owned by `src/edge.lua`; there is no active `src/components/edge_enemy_spawners.lua` module. Static content is under `assets/` (`images/`, `sfx/`, `fonts/`). Third-party dependencies are vendored in `lib/`; treat that directory as external unless you are intentionally patching a library. Editor and debug helpers live in `.vscode/`. Local agent notes may live in `.agent/` and are not part of runtime code.

## Build, Test, and Development Commands
Run the game locally with `love .`. Use `love . debug` when launching through the local Lua debugger configured in `.vscode/launch.json`. Run automated tests with `lua tests/run.lua` or `luajit tests/run.lua`; keep new specs registered in `tests/run.lua` so the default suite covers them. Build distributable packages with `makelove --config make_all.toml` or the VS Code task `Build LÖVE`; outputs go to `bin/`. There is no separate project install step because dependencies are committed into `lib/`.

## Coding Style & Naming Conventions
Match the existing Lua style in the touched file: the codebase currently mixes tabs and spaces, so avoid reformatting unrelated lines. Use PascalCase for classes and major globals (`Player`, `World`, `Level`), and snake_case for methods and local helpers (`add_entity`, `check_collisions`). Prefer lowercase snake_case filenames for new modules; `src/Item.lua` is a legacy exception, so keep existing imports case-correct. Keep modules focused on one entity or subsystem, and use `require("src.<module>")` for runtime modules. Preserve the current LÖVE/LuaJIT setup from `.vscode/settings.json`.

## Testing Guidelines
This repository includes a lightweight Lua test suite under `tests/`. Add focused specs for pure logic, entity/component behavior, collision outcomes, wave progression, upgrade definitions, and UI text assembly. Run `lua tests/run.lua` and, when LuaJIT-specific behavior matters, `luajit tests/run.lua`. Also validate gameplay changes by running `love .` and manually testing the affected loop, collisions, audio, and UI states. For balance or rendering changes, include the exact scenario you tested in your PR, for example "player damage + power-up menu after wave clear."

## Commit & Pull Request Guidelines
Recent history uses Conventional Commit-style prefixes such as `feat:` and `refactor:`. Follow that pattern and keep subjects short, imperative, and specific, for example `feat: add boss intro timing`. Each completed feature or self-contained refactor step must be recorded with a git commit before moving on to the next feature. Pull requests should describe gameplay impact, list manual test steps, and include screenshots or short clips for visible UI or rendering changes. Link the related issue when one exists.

## Asset & Dependency Notes
Keep new art, sound, and font files inside the matching `assets/` subdirectory and load them through the Cargo asset loader. Do not rename or restructure vendored libraries in `lib/` unless the change is deliberate and documented in the PR.
