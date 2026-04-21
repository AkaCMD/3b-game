# Repository Guidelines

## Project Structure & Module Organization
`main.lua` is the game entry point and scene coordinator. Runtime code lives in `src/`, with one gameplay object or UI module per file, for example `src/player.lua`, `src/enemy.lua`, and `src/power_up_ui.lua`. Static content is under `assets/` (`images/`, `sfx/`, `fonts/`). Third-party dependencies are vendored in `lib/`; treat that directory as external unless you are intentionally patching a library. Editor and debug helpers live in `.vscode/`.

## Build, Test, and Development Commands
Run the game locally with `love .`. Use `love . debug` when launching through the local Lua debugger configured in `.vscode/launch.json`. Build distributable packages with `makelove --config make_all.toml` or the VS Code task `Build LÖVE`; outputs go to `bin/`. There is no separate install step because dependencies are committed into `lib/`.

## Coding Style & Naming Conventions
Match the existing Lua style in the touched file: the codebase currently mixes tabs and spaces, so avoid reformatting unrelated lines. Use PascalCase for classes and major globals (`Player`, `World`, `Level`), and snake_case for methods and local helpers (`add_entity`, `check_collisions`). Keep modules focused on one entity or subsystem, and continue using `require("src.<module>")` from `main.lua`. Preserve the current LÖVE/LuaJIT setup from `.vscode/settings.json`.

## Testing Guidelines
This repository does not currently include an automated test suite. Validate changes by running `love .` and manually testing the affected gameplay loop, collisions, audio, and UI states. For balance or rendering changes, include the exact scenario you tested in your PR, for example "player damage + power-up menu after wave clear."

## Commit & Pull Request Guidelines
Recent history uses Conventional Commit-style prefixes such as `feat:` and `refactor:`. Follow that pattern and keep subjects short, imperative, and specific, for example `feat: add boss intro timing`. Each completed feature or self-contained refactor step must be recorded with a git commit before moving on to the next feature. Pull requests should describe gameplay impact, list manual test steps, and include screenshots or short clips for visible UI or rendering changes. Link the related issue when one exists.

## Asset & Dependency Notes
Keep new art, sound, and font files inside the matching `assets/` subdirectory and load them through the Cargo asset loader. Do not rename or restructure vendored libraries in `lib/` unless the change is deliberate and documented in the PR.
