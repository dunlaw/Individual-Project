## Testing Overview

The current project no longer uses GUT. Automated verification is now organised around custom headless Godot runners and standalone GDScript suites.

- `1.Codebase/Unit Test/all_tests_runner.gd` is the main aggregation runner.
- `1.Codebase/Unit Test/prompt_tests_runner.gd` groups prompt and parsing related suites.
- `1.Codebase/Unit Test/ui_tests_runner.gd` groups selected UI-facing suites.
- `1.Codebase/src/scenes/tests/` contains lightweight scene wrappers for headless execution where scene context is useful.

At the time of writing, `1.Codebase/Unit Test` contains 59 `.gd` files in total:

- 55 dedicated `test_*.gd` suites
- 4 runner/helper scripts (`all_tests_runner.gd`, `prompt_tests_runner.gd`, `ui_tests_runner.gd`, `quick_verify.gd`)

Additional targeted tests also exist outside that folder:

- `1.Codebase/src/scripts/tests/`
- `1.Codebase/src/scripts/ui/test_markdown_parser.gd`

## What The Main Runner Does

`all_tests_runner.gd` currently scans three roots:

1. `res://1.Codebase/Unit Test`
2. `res://1.Codebase/src/scripts/tests`
3. `res://1.Codebase/src/scripts/ui`

It then:

1. runs an inline sanity suite first
2. discovers `test_*.gd` scripts recursively
3. skips helper/mock-only files via an explicit skip list
4. instantiates each suite as a node
5. reads per-suite counters such as `tests_passed` and `tests_failed`
6. applies a 60-second watchdog timeout per suite
7. exits with non-zero status if tracked failures remain

## Current Coverage Highlights

- Core state and persistence: `test_game_state.gd`, `test_save_load_system.gd`, `test_gamestate_integration.gd`, `test_journal_save_load.gd`
- AI prompt and parsing stack: `test_ai_prompt_builder.gd`, `test_ai_context_compression.gd`, `test_scene_directives_parser.gd`, `test_narrative_response_parser.gd`
- Provider layer: `test_ai_system.gd`, `test_ai_providers.gd`, `test_live_api_client.gd`, `test_ollama_client.gd`
- Story/UI refactor coverage: `test_story_scene_modules.gd`, `test_story_ui_controller.gd`, `test_ui_overlap_checker.gd`, `test_markdown_parser.gd`
- Regression-focused suites: `test_polish_regressions.gd`, `test_prayer_context_fix.gd`, `test_prayer_dissonance_bug.gd`, `test_trolley_problem_relationship_bug.gd`

## Headless Commands

Use the Godot 4.7-dev3 console executable required by this repository:

```powershell
& 'C:\Users\dunc4\Downloads\Godot_v4.7-dev3_win64_console.exe' --headless --path 'C:\Users\dunc4\Documents\GitHub\Individual-Project' --script 'res://1.Codebase/Unit Test/all_tests_runner.gd'
```

```powershell
& 'C:\Users\dunc4\Downloads\Godot_v4.7-dev3_win64_console.exe' --headless --path 'C:\Users\dunc4\Documents\GitHub\Individual-Project' --script 'res://1.Codebase/Unit Test/prompt_tests_runner.gd'
```

```powershell
& 'C:\Users\dunc4\Downloads\Godot_v4.7-dev3_win64_console.exe' --headless --path 'C:\Users\dunc4\Documents\GitHub\Individual-Project' --script 'res://1.Codebase/Unit Test/ui_tests_runner.gd'
```

## Report Alignment Notes

When writing the dissertation/report, the testing section should now describe:

- custom headless runners rather than GUT
- standalone GDScript suites rather than only scene-based tests
- the split between deterministic automated suites and developer-led functional testing
- the late-stage regression suites added after refactors
- telemetry exports as functional-testing evidence, not as a substitute for unit assertions
