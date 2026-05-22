# Implementation Status

Last updated: 2026-05-22, after party removal fix

## Current Goal

Start implementing `plano_desenvolvimento_jogo_godot_isometrico.md` while keeping the current autoshooter prototype playable.

## Read Context

- Development plan: `plano_desenvolvimento_jogo_godot_isometrico.md`
- Current prototype summary: `README.md`
- Core state/save: `scripts/core/game_data.gd`
- Combat/run flow: `scripts/game/game_manager.gd`
- Companion runtime: `scripts/game/companion_manager.gd`, `scripts/game/companion.gd`
- Companion/player UI entry point: `scripts/ui/characters_screen.gd`

## Baseline Notes

- The project is a Godot 4.x 2D isometric autoshooter prototype.
- Fase 1 and much of Fase 2 already exist: isometric movement, camera follow, auto combat, enemy spawning, XP, coins, level-up choices and recruitable run companions.
- The plan's next useful bridge is persistent guild/companion squad data, because it supports later guild, recruitment, speed average, mission risk and death systems.
- Existing dirty files before this work: `scenes/Game.tscn`, `scripts/game/enemy.gd`, and untracked art/plan assets. Do not revert them.

## Completed In This Slice

### Slice 1

- Added persistent guild companion roster and active squad to `scripts/core/game_data.gd`.
- Added squad summary helpers: average level, average speed, speed label and mobility warning.
- Added six MVP companion classes in `scripts/game/game_balance.gd`: warrior, tank, archer, mage, cleric and assassin.
- Added tank and assassin runtime behavior in `scripts/game/companion.gd`.
- Updated `scripts/game/companion_manager.gd` to spawn the active squad from `GameData` when the autoload is available, with fallback to balance defaults.
- Updated `scripts/ui/characters_screen.gd` and `scenes/ui/CharactersScreen.tscn` so the existing character screen can manage the active squad and show speed/risk summary.
- Added test coverage for default guild squad data in `tests/test_runner.gd`.

### Slice 2

- Persistent squad companions now start combat already recruited/in formation instead of appearing as lost pickups.
- `scripts/game/companion_manager.gd` can report run results for each companion.
- `scripts/game/game_manager.gd` writes companion level, XP, selected stat upgrades, health and return state back into `GameData` at run end.
- Fallen companions return to the guild as `ferido` with partial health; full death/graveyard is still pending.
- Added recruitment state to `GameData`: 3-candidate queue, reroll costs, rarity rolls and hiring into the roster.
- Added recruitment controls to the existing `CharactersScreen` bridge UI.
- Added tests for run-result persistence, hiring and reroll behavior.

### Guild Start Change

- Added `scenes/ui/GuildScene.tscn` and `scripts/ui/guild_scene.gd`.
- Updated `project.godot` so the game starts at `res://scenes/ui/GuildScene.tscn`.
- Updated return navigation from combat, character management and upgrades back to the guild scene.

### Party Removal Fix

- Fixed `GameData.toggle_companion_in_squad()` so removing a companion does not immediately append the same id back.
- Removed automatic repopulation of an intentionally empty active squad.
- Empty party is allowed while editing, but `GuildScene` disables mission start when the squad has zero companions.
- Added regression coverage for emptying the squad.

## Current State

- Default roster has six companions.
- Default active squad has three companions: `c_warrior_001`, `c_archer_001`, `c_cleric_001`.
- The squad screen is still a pragmatic bridge inside `CharactersScreen`, not the final guild UI.
- Runtime companion XP/level and selected companion upgrades are now written back to the persistent roster when the run ends.
- Recruitment queue is functional, but still lives inside `CharactersScreen` as a temporary bridge.
- The application start scene is now the guild scene.
- Party editing now allows removing companions, including clearing the party completely.

## Pending After This Slice

- Build a dedicated guild scene instead of overloading the character screen.
- Add mission select with recommended level, squad average level, speed warning and risk text.
- Add a dedicated recruitment/guild scene once the loop stabilizes.
- Add fallen/death/graveyard flow.
- Add explicit flee action and rewards penalty.
- Add feedback on GameOver for companion XP, level gains and wounded companions.

## Validation Checklist

- Done: `godot --headless --path . --script res://tests/test_runner.gd` -> 92 tests passed.
- Done: `godot --headless --path . --scene res://scenes/Game.tscn --quit-after 8` -> scene booted cleanly.
- Note: Direct headless runs of UI-only scenes crash Godot 4.6.2 on this machine, including the existing `MainMenu`, `CharactersScreen` and `UpgradesScreen`; use editor/GUI verification for UI scene rendering.

## Files Changed By This Slice

- `IMPLEMENTATION_STATUS.md`
- `project.godot`
- `scenes/ui/GuildScene.tscn`
- `scenes/ui/CharactersScreen.tscn`
- `scripts/core/game_data.gd`
- `scripts/game/companion.gd`
- `scripts/game/companion_manager.gd`
- `scripts/game/game_manager.gd`
- `scripts/game/game_balance.gd`
- `scripts/ui/guild_scene.gd`
- `scripts/ui/characters_screen.gd`
- `scripts/ui/upgrades_screen.gd`
- `tests/test_runner.gd`
