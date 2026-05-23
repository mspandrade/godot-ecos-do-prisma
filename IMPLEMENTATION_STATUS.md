# Implementation Status

Last updated: 2026-05-23, after flee preparation cooldown

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

### Flee Mechanic

- Added `Fugir` button directly to the combat HUD.
- Added `GameManager.flee_run()` to end the run as a flee result.
- Flee is no longer instant: pressing `Fugir` starts a 5-second preparation window before the run ends.
- During flee preparation the HUD disables the flee button and shows the remaining flee countdown.
- Flee keeps a percentage of run coins based on squad average speed: very slow 45%, slow 60%, balanced 75%, fast 90%, very fast 100%.
- Game over/result popup now shows `Fuga concluida` and displays kept coins versus collected coins.
- Added test coverage for flee coin retention by squad speed.

### Mission Select

- Added mission data and selected mission persistence to `GameData`.
- Added mission readiness summary: squad level, recommended level, squad speed, risk, warnings and can-start state.
- Added `scenes/ui/MissionSelect.tscn` and `scripts/ui/mission_select.gd`.
- Guild mission button now opens the mission board instead of starting combat directly.
- Guild scene shows the currently selected mission and calculated risk.
- Added test coverage for locked/unlocked missions and underleveled warnings.

### Mission Combat Profiles

- Selected mission now generates a combat profile through `GameData.get_selected_mission_combat_profile()`.
- `GameManager` applies that profile to `EnemySpawner` before initial enemies are spawned.
- `EnemySpawner` uses mission profile values for wave offset, spawn amount, spawn interval and boss interval.
- `Enemy` uses mission profile values for health, speed, damage, XP drops and coin drops.
- Added test coverage for selected mission combat profile and spawner profile storage.

### Mission Timer

- Each mission combat profile now defines `duration_seconds`.
- Combat HUD timer now shows countdown to mission end.
- `GameManager` finishes the run as `vitoria` when the mission timer reaches zero.
- Victory adds the mission completion coin reward to collected run coins.
- Result popup shows `Missao concluida` for timer victories.
- Result popup title node is now marked as unique so victory/flee result titles resolve safely.
- Mission select displays mission duration.
- Added test coverage for mission duration and completion reward in the combat profile.

## Current State

- Default roster has six companions.
- Default active squad has three companions: `c_warrior_001`, `c_archer_001`, `c_cleric_001`.
- The squad screen is still a pragmatic bridge inside `CharactersScreen`, not the final guild UI.
- Runtime companion XP/level and selected companion upgrades are now written back to the persistent roster when the run ends.
- Recruitment queue is functional, but still lives inside `CharactersScreen` as a temporary bridge.
- The application start scene is now the guild scene.
- Party editing now allows removing companions, including clearing the party completely.
- Combat HUD now has a flee action. Flee takes 5 seconds to prepare, preserves companion run progress and applies a coin penalty based on squad mobility.
- Mission board is functional for selecting an unlocked mission before starting combat. The selected mission is saved.
- Selected mission now affects combat pressure and enemy rewards.
- Missions now end automatically when their timer reaches zero.

## Pending After This Slice

- Build a dedicated recruitment scene instead of keeping recruitment inside the character screen.
- Add a dedicated recruitment/guild scene once the loop stabilizes.
- Add fallen/death/graveyard flow.
- Add feedback on GameOver for companion XP, level gains and wounded companions.

## Validation Checklist

- Done: `godot --headless --path . --script res://tests/test_runner.gd` -> 112 tests passed after flee cooldown.
- Done: `godot --headless --path . --scene res://scenes/Game.tscn --quit-after 8` -> scene booted cleanly after flee cooldown.
- Note: Direct headless runs of UI-only scenes crash Godot 4.6.2 on this machine, including the existing `MainMenu`, `CharactersScreen` and `UpgradesScreen`; use editor/GUI verification for UI scene rendering.

## Files Changed By This Slice

- `IMPLEMENTATION_STATUS.md`
- `project.godot`
- `scenes/ui/GuildScene.tscn`
- `scenes/ui/MissionSelect.tscn`
- `scenes/ui/CharactersScreen.tscn`
- `scenes/ui/HUD.tscn`
- `scripts/core/game_data.gd`
- `scripts/game/companion.gd`
- `scripts/game/companion_manager.gd`
- `scripts/game/enemy.gd`
- `scripts/game/enemy_spawner.gd`
- `scripts/game/game_manager.gd`
- `scripts/game/game_balance.gd`
- `scripts/ui/guild_scene.gd`
- `scripts/ui/mission_select.gd`
- `scripts/ui/characters_screen.gd`
- `scripts/ui/game_over.gd`
- `scripts/ui/hud.gd`
- `scripts/ui/mission_select.gd`
- `scripts/ui/upgrades_screen.gd`
- `tests/test_runner.gd`
