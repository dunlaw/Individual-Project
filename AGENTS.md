# Repository Guidelines

## Environment & Scope

- This repository targets Godot 4.7-dev3; open `project.godot` from the root or use `godot4` CLI tools for editor and runtime tasks.
- Source contributions belong in `1.Codebase`; the numbered planning/report folders are archival and must remain unchanged.
- Autoload singletons such as `AudioManager`, `GameState`, and `AssetRegistry` are wired in `project.godot`; update that list whenever you add a new global service.

## Project Structure & Module Organization

- `1.Codebase/menu_main.tscn` is the configured entry point, with `main.tscn` and `main.gd` acting as the bootstrap scene.
- `1.Codebase/src/scripts/core` contains autoload logic (audio, AI, asset catalogues, state), while `src/scripts/ui` pairs with `src/scenes/ui` for screen-specific code.
- Reuse `src/assets/*` for art, audio, fonts, and UI textures; keep new resources grouped with the closest existing category.
- Runtime test scaffolding lives in `1.Codebase/Unit Test` and `src/scenes/tests`, letting you spawn test nodes without touching production scenes.

## Build, Test, and Development Commands

- Launch the game locally with `godot4 --path .`, which loads the default main menu.
- Open the Godot editor via `godot4 --path . --editor` when editing scenes or tuning autoload properties.
- Run the bundled audio regression check headlessly:
  `godot4 --headless --path . --run res://1.Codebase/src/scenes/tests/audio_test_runner.tscn`.
- Detect GDScript syntax issues early with the static checker:
  `godot4 --headless --path . --check-only`.

## Coding Style & Naming Conventions

- Write typed GDScript, indent with tabs, and follow snake_case for functions/variables plus UPPER_SNAKE_CASE for constants.
- Use `@onready` for node bindings, `preload` for static resources, and keep scene-script pairs aligned (`notification_popup.tscn` ↔ `notification_popup.gd`).
- Place helper utilities in `src/scripts/core` only if they must be autoloaded; otherwise keep them near their consuming scene.

### Key Rules

1. **Use ServiceLocator** for all global service access (NO hardcoded `/root/` paths)
   ```gdscript
   var game_state = ServiceLocator.get_game_state()  # ✅ GOOD
   var game_state = get_node("/root/GameState")      # ❌ BAD
   ```

2. **Use ErrorReporter** for all warnings and errors (NO `push_warning`)
   ```gdscript
   ErrorReporter.report_warning("Context", "Message")  # ✅ GOOD
   push_warning("Message")                             # ❌ BAD
   ```

3. **Use EventBus** for UI reacting to state changes
   ```gdscript
   EventBus.subscribe("reality_score_changed", self, "_on_score_changed")  # ✅ GOOD
   GameState.reality_score  # Direct access in UI                          # ❌ BAD
   ```

4. **Use GameConstants** for all magic numbers
   ```gdscript
   if score <= GameConstants.Stats.LOW_REALITY_THRESHOLD  # ✅ GOOD
   if score <= 20                                         # ❌ BAD
   ```

## Testing Guidelines

- Mirror the asynchronous harness in `Unit Test/test_audio_manager.gd`; await frames/timers to avoid race conditions with AudioServer or tweens.
- Name new test scenes under `src/scenes/tests` after the system under test and document any extra CLI commands alongside them.
- Validate boundary cases (volume limits, pooling thresholds, asset presence) before shipping features that touch autoload singletons.

## Commit & Pull Request Guidelines

- Follow the conventional commit prefixes used in history (`feat:`, `docs:`, `fix:`) and keep summaries under 72 characters.
- Keep each commit focused on one concern; describe scene or autoload touch-points in the body when necessary.
- PRs should include a problem statement, verification notes (commands run, scenes exercised), and screenshots or clips for UI-facing changes. Link issues or sprint tickets where applicable.

only edit code in folder /1.Codebase and please only Use Godot 4.7 format , dont Use Godot 3 format as it will have lot of bug! Use Godot executable at "C:\Users\dunc4\Downloads\Godot_v4.7-dev3_win64_console.exe"

## AI Collaboration Constraints

- The project is now in the polishing phase. Do not introduce new major features unless explicitly asked. Before starting any large or new feature, confirm with the requester whether it is still needed.
- Focus on refining existing systems, polishing gameplay details, and fixing bugs. Keep every substantial change tightly scoped to these goals.
- After completing any code modification, respond in Chinese describing what happened and how you changed the code, so the requester knows the exact adjustments made.
