# Implementation Status

Last updated: 2026-05-31, after gameplay HUD readability fix

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
- Result popup now hides `Tentar novamente` on mission victory/flee; retry remains only for defeat.
- Mission select displays mission duration.
- Added test coverage for mission duration and completion reward in the combat profile.

### Mission Completion Rewards

- Added `GameData.apply_mission_result()` to centralize end-of-mission progression.
- Victory now splits the mission XP reward across active companions.
- Victory reports companions that gained levels from the mission reward.
- Completing the initial forest unlocks `wolf_cave`; completing wolf cave unlocks `ancient_ruins`.
- Returning from a mission resets recruitment reroll cost, including flee/failed returns.
- GameOver now shows mission XP, level gains, newly unlocked zones and reroll reset feedback.
- Added regression coverage for victory rewards, zone unlocks and flee not completing missions.

### Dedicated Recruitment Screen

- Added `scenes/ui/RecruitmentScene.tscn` and `scripts/ui/recruitment_scene.gd`.
- Guild now has separate buttons for `Companions` and `Recrutamento`.
- Recruitment screen shows coins, roster capacity, reroll cost, candidate details and hire buttons.
- Character screen is now focused on leader selection and active squad management.

### Guild Upgrade Rework

- Replaced generic permanent stat upgrade definitions with guild-focused improvements.
- New guild upgrades: `Salao da Guilda`, `Dormitorios`, `Campo de Treino`, `Rede de Recrutadores` and `Armazem de Suprimentos`.
- `Salao da Guilda` increases guild level and unlocks structure flags for later systems.
- `Dormitorios` increases companion roster capacity by 2 per level.
- `Campo de Treino` increases mission completion XP by 15% per level.
- `Rede de Recrutadores` discounts rerolls and improves recruitment rarity rolls.
- `Armazem de Suprimentos` improves leader health and pickup range.
- Upgrade UI now shows category, description, effect and current guild capacity/level.
- Legacy stat upgrades remain compatible in `get_selected_stats()` for older saves, but are no longer shown in the guild upgrade UI.
- Added regression coverage for guild upgrade costs and effects.

### Graveyard And Death Flow

- Companions now enter `caido` when reduced to 0 health instead of disappearing as an immediate wounded return.
- Downed companions have a 30-second rescue window; if the timer expires they become `morto`.
- HUD companion rows show `Caido Ns` during the rescue window and `Morto` after death.
- `CompanionManager.get_run_results()` now persists `caido`, `morto` and normal return states.
- Dead companions are removed from the active squad and excluded from squad summaries/combat spawns.
- Added `GameData.get_dead_companions()`, `get_resurrection_cost()` and `resurrect_companion()`.
- Added `scenes/ui/GraveyardScene.tscn` and `scripts/ui/graveyard_scene.gd`.
- Guild now has a `Cemiterio` button, locked until the guild has the graveyard structure flag.
- Resurrected companions return as `ferido`, with partial health and a 25% XP penalty.
- Added regression coverage for downed timers, death persistence, graveyard listing and resurrection.

### End-of-Run Companion Feedback

- `GameData.apply_companion_run_results()` now returns a consequence summary.
- GameOver now shows companions that returned `Feridos` and companions that died as `Mortos`.
- Added regression coverage for wounded/dead companion result summaries.

### Persistent Companion Upgrade Choices

- Mission XP level-ups now add `pending_upgrades` to persistent companion roster data.
- `CharactersScreen` shows pending upgrade choices directly on each companion row.
- Persistent upgrade choices apply to attack, cooldown, health, range, speed and ability power.
- Rarity affects how many choices are shown: common 3, rare/epic 4, legendary 5.
- Runtime combat companion upgrades also support the new `speed` choice.
- Added regression coverage for pending upgrade creation and application.

### Guild Upgrade Locks

- Guild upgrades now support guild-level requirements.
- `Campo de Treino` and `Rede de Recrutadores` require Guilda Nv 2.
- Upgrade purchases now fail if the guild-level requirement is not met.
- Upgrade UI now shows `Bloqueado` and the requirement text when a guild upgrade is locked.
- Added regression coverage for locked upgrades, unlock after `Salao da Guilda`, and buying unlocked upgrades.

### Recruitment UX Comparison

- Recruitment candidates now show rarity-colored names for quick scanning.
- Candidate rows compare level and mobility against the current active squad average.
- Candidate rows show how many companions of the same class already exist in the roster and active squad.
- Hire buttons now communicate blocked states directly: full dormitories or missing coins.

### Leader And Squad Screen Split

- `CharactersScreen` is now focused on active squad management and pending companion upgrades.
- Added a dedicated `LeaderScreen` for selecting or unlocking the playable leader.
- Guild menu now exposes separate `Esquadrao` and `Lider` buttons.
- Fixed `LeaderScreen` missing coin calculation to use explicit integer typing (`maxi`) so the leader button opens without the GDScript inference error.

### Initial Blacksmith And Equipment Screen

- Added persistent equipment inventory and equipment serial data to `GameData`.
- Added a first blacksmith catalog: `Lamina de Ferro`, `Colete Reforcado`, `Botas de Batedor` and `Amuleto de Foco`.
- Equipment can now be forged with coins, equipped on companions and unequipped.
- Equipped items modify persistent companion stats and are limited to two items per companion.
- Added `BlacksmithScreen` behind the existing guild `blacksmith` structure unlock.
- Guild menu now shows `Ferreiro bloqueado` until the structure is unlocked.
- Added regression coverage for forge, equip, stat bonus and unequip flow.

### Equipment Rarity And Upgrade Rules

- Forged equipment now rolls rarity: comum, incomum, raro, epico or lendario.
- Equipment now has persistent level data, defaulting old saved items to level 1/common.
- Added equipment upgrade costs and `upgrade_equipment()` to improve items up to level 5.
- Upgraded equipped items remove the old bonus, apply the higher scaled bonus and preserve clean unequip behavior.
- Blacksmith inventory rows now show rarity, level and a `Melhorar` action with coin gating.
- Added regression coverage for upgrading an equipped item and verifying scaled stat bonuses.

### Mission Equipment Rewards

- Missions now define an `equipment_reward_chance`.
- Victory can add a rolled equipment item directly to the persistent equipment inventory.
- Equipment reward rarity scales from mission recommended level.
- Fleeing/failed mission returns do not grant mission equipment.
- GameOver outcome text now reports equipment earned on mission victory.
- Added regression coverage for victory equipment rewards and flee not awarding mission equipment.

### Equipment Reforge Rules

- Added equipment reforge costs.
- Added `reforge_equipment()` to reroll equipment rarity without changing item type or level.
- Reforging equipped items removes the old rarity-scaled bonus and reapplies the new one cleanly.
- Blacksmith inventory rows now expose a `Reforjar` action with coin gating.
- Added regression coverage for reforging equipped equipment.

### Guild Layout Refresh

- Guild screen now separates summary text from facility actions.
- Facility actions now use a two-column grid to fit mission, squad, leader, recruitment, upgrades, graveyard, blacksmith and settings.
- Guild summary now shows equipment inventory count.

### Combat Equipment Drops

- Added `GameData.award_random_equipment()` for reusable direct equipment rewards.
- Enemy kills during combat now have a low chance to award random equipment directly to the guild inventory.
- Combat equipment drops scale rarity from selected mission recommended level.
- End-of-run results include combat equipment drops alongside mission completion equipment rewards.
- Added regression coverage for random equipment awards.

### Training Field Screen

- Added persistent `training_sessions` to companions.
- Added `GameData.get_training_options()`, `get_training_cost()` and `train_companion()`.
- Training is locked until the guild has the training field structure.
- Training spends coins and permanently improves companion attack, health, speed or defense.
- Added `TrainingScreen` and a guild `Treinamento` facility button.
- Added regression coverage for training lock, cost, stat effect and scaling cost.

### Late-Game Mission Chain

- Added `demon_gate_assault`, unlocked by completing `ancient_ruins_contract`.
- Added `demon_king_vanguard`, unlocked by completing `demon_gate_assault`.
- Ancient ruins now unlocks `Portao Demoniaco`; demon gate unlocks `Fortaleza do Rei Demonio`.
- Added late-game combat profiles with higher wave offset, stronger enemies, faster bosses and better rewards.
- Added regression coverage for the late-game unlock chain and selected combat profile.

### Mission Kill Objectives

- Mission combat profiles now support `objective_type` and `target_kills`.
- Wolf cave and later missions use kill-count objectives instead of only waiting out the timer.
- Combat HUD now shows current objective progress.
- `GameManager` tracks enemy kills and ends kill-count missions with victory when the target is reached.
- Added regression coverage for objective data in combat profiles.

### Demon King Final Mission

- Added `demon_king_final`, unlocked after the vanguard mission opens `Trono do Rei Demonio`.
- Added campaign completion state to guild data.
- Completing the final mission marks the campaign as completed.
- GameOver now reports the final campaign completion message.
- Added regression coverage for final unlock, final mission profile and campaign completion.

### Auto-Save Feedback

- `GameData.save_data()` now emits `save_feedback` after a successful save.
- Guild screen listens to save feedback and briefly shows `Progresso salvo.`.
- Added regression coverage for the save feedback signal.

### Bestiary Kill Tracking

- Added persistent `bestiary` data to `GameData`.
- Enemy spawner kill signal now includes enemy sprite/type.
- GameManager tracks enemy types defeated during a run and persists them at run end.
- Added `GameData.add_bestiary_kills()` and `get_bestiary()`.
- Added regression coverage for accumulated bestiary counts.

### Codex Screen

- Added `CodexScreen` to display persistent bestiary enemy counts.
- Guild menu now has a `Codex` facility button.
- Codex shows total defeated enemies and sorted per-enemy counts.
- Codex also shows achievement/milestone progress.

### Guild Morale

- Added persistent guild morale.
- Victory increases morale; fleeing and defeat reduce morale.
- Wounded and dead companion run consequences reduce morale.
- Guild screen now shows morale value and label.
- GameOver reports mission morale changes.
- Added regression coverage for morale deltas and morale labels.

### Achievements And Milestones

- Added persistent achievement state to `GameData`.
- Added milestone definitions for first mission victory, first recruit, first equipment, bestiary progress and Demon King defeat.
- Achievement unlocks emit `achievement_unlocked`.
- Achievement unlocks are saved in the same save cycle as the triggering action.
- Added regression coverage for achievement unlocks and save persistence.

### Heavy Equipment Penalties

- Added heavy equipment options to the blacksmith inventory.
- `Escudo Torre` and `Placas Pesadas` provide defensive value while reducing mobility and movement speed.
- Negative equipment bonuses are applied and reversed through the same equip/unequip flow as positive bonuses.
- Added regression coverage for speed penalties and restoration after unequip.

### Persistent Settings

- Added persistent settings data to `GameData`.
- Added `SettingsScreen` with sliders for master, music and SFX volume.
- Added a fullscreen toggle.
- Guild and main menu settings buttons now open the real settings screen instead of toggling placeholder text.
- Added regression coverage for settings change events and save/load persistence.

### Mission Fast Travel

- Added persistent selected travel zone to `GameData`.
- Added travel-zone discovery from mission data.
- Locked zones cannot be selected until mission progression unlocks them.
- Mission board now shows fast-travel region buttons and filters missions by selected region.
- Added regression coverage for locked and unlocked travel-zone selection.

### Expanded Achievement Hooks

- Added additional long-term achievement definitions for full squad, expanded roster, restored guild, first companion death and first resurrection.
- Squad, roster, guild upgrade, death and resurrection flows now unlock their matching milestones.
- Codex displays the expanded milestone list automatically.
- Added regression coverage for each new achievement hook.

### Mission Enemy Variety

- Mission combat profiles now include enemy and boss sprite pools.
- Enemy spawns store the mission profile and prefer mission-specific sprites when available.
- Different zones now visually bias toward goblins/slimes, cave creatures, cultists, undead and demons.
- Added regression coverage that selected mission combat profiles carry zone enemy sprites.

### Mission Reputation Rewards

- Missions now define reputation rewards.
- Victory applies reputation to the persistent guild data.
- Guild header shows reputation beside guild level.
- GameOver victory results show reputation gained.
- Added regression coverage for reputation reward summary and guild reputation gain.

### Settings Placeholder Cleanup

- Removed dead `SettingsLabel` placeholder nodes from guild and main menu scenes.
- Confirmed settings buttons now only route to the real persisted settings screen.

### Mission Objective Card Clarity

- Mission board cards now show the actual objective type.
- Survival missions show the timer objective.
- Kill-count missions show the target number of enemy defeats.

### Real Wounded Companion Penalty

- Persistent companion health now influences the next combat spawn.
- Companions returning `ferido` start their next mission with reduced health instead of being silently restored to full health.
- Runtime companions receive both maximum and current starting health from the persistent squad definition.
- Added regression coverage for wounded starting-health carryover.

### Expanded Mid/Late-Game Zone Chain

- Added `Pantano Venenoso` mission between ancient ruins and the demonic front.
- Added `Cemiterio Maldito` mission before access to `Portao Demoniaco`.
- Both new missions define their own kill targets, durations, combat difficulty, rewards, reputation and visual enemy pools.
- Progression now follows the planned route from ruins through swamp and graveyard before the Demon King fortress.
- Added regression coverage for the expanded unlock chain.

### Boss-Kill Final Mission Objective

- The final Demon King mission now uses a boss-kill objective instead of a generic kill count.
- Enemy kill events now identify boss kills for objective tracking.
- HUD and mission cards display boss objective progress.
- Timer completion only wins survival contracts; unfinished kill-count or boss contracts now fail on timeout.
- Added regression coverage for the final mission boss target.

### Infirmary Recovery Facility

- Added `Enfermaria` as a guild facility unlocked after the first guild hall improvement.
- Added a dedicated infirmary screen listing wounded companions and paid treatments.
- Treatment restores a wounded companion to `disponivel` with full persistent health.
- This creates a strategic alternative to entering another mission while carrying the wound penalty.
- Added regression coverage for locked treatment, unlock, cost and restored health.

### Optional Alpha Boss Mission

- Added `Cacada ao Alfa da Caverna` as an optional boss contract in the Wolf Cave region.
- The new contract gives its own rewards and does not block the main progression path.
- Added `Cacador de Alfas` achievement for completing a boss contract.
- Added regression coverage for selecting the optional mission, its boss target and achievement unlock.

### Mission Achievement Result Feedback

- Mission result summaries now include achievements unlocked by that victory.
- The result popup shows newly earned milestones immediately after combat.
- First contract, first boss and campaign completion achievements are surfaced through this flow.
- Added regression coverage for normal, boss and final-campaign result feedback.

### Zone Materials And Warehouse

- Added persistent material inventory to `GameData`.
- Missions now reward region-specific materials such as herbs, fangs, relics, venom, cursed bones and demonic components.
- Mission result popup reports acquired materials.
- Added `Armazem` as a guild facility unlocked with the first hall improvement.
- Added a warehouse screen that lists stored materials and equipment totals.
- Added regression coverage for material rewards and warehouse unlock.

### Material-Based Forging

- Advanced heavy equipment recipes now require region materials in addition to coins.
- `Escudo Torre` consumes cursed bone and `Placas Pesadas` consumes demonic embers.
- Blacksmith crafting rows display material requirements and disable crafting when ingredients are missing.
- Added regression coverage for blocked crafting and material consumption.

### Guild Facility Layout Fit

- Expanded the guild content area and tightened spacing so the added Enfermaria and Armazem facility buttons fit the entrance screen layout.

### Mission Reward Preview Clarity

- Mission cards now preview reputation and regional material rewards before a contract begins.
- This makes material-based forging decisions visible before committing the squad to combat.

### Progressive Portal Travel

- Fast travel is now unlocked by the `Portal` structure when the guild reaches level 3, matching the development plan.
- Discovering a new zone no longer grants immediate travel before the Portal is available.
- The mission board marks discovered-but-unreachable regions with their Portal requirement.
- Added regression coverage for Portal gating and guild-level unlock.

### Resource Collection Contract

- Added `Coleta de Ervas na Floresta` as an optional early-game contract.
- Added the `collect_resources` objective type: picked-up combat orbs advance a live `Suprimentos` HUD counter, and the mission wins when the target is collected.
- The collection contract grants a larger herb reward for the warehouse and crafting loop.
- Added regression coverage for mission availability, objective target and material reward.

### Mechanical Recruit Traits

- Recruitment traits now apply persistent stat effects when a companion is hired, instead of being decorative text.
- Traits cover health, attack, defense, range, luck, cooldown and ability-power specializations.
- Recruitment and squad screens now state each trait effect so the player can compare candidates with intent.
- Added regression coverage for a trait-driven recruited companion stat bonus and its UI description source.

### Expanded Mission Briefing

- Mission cards now list their predicted enemy groups alongside risk, mobility, rewards and objective.
- This completes the plan's pre-deployment visibility requirement for principal enemies.

### Luck-Driven Rewards

- Squad `luck` now modestly increases equipment chances from mission completion and collected combat orbs.
- `Sortudo` increases luck as described in the plan, while class critical chance remains functional during attacks.
- Guild, squad and mission preparation views now display the squad's average luck.

### Rarity Evolution And Level Milestones

- Persistent and in-run companion choices now vary in quality by rarity, not only in quantity.
- High-rarity companions can improve critical chance and luck through level-up choices.
- Levels 5, 10, 15 and 20 expose class power, specialization, advanced power and ultimate options.
- The combat companion choice popup supports up to five legendary options.
- Critical and luck choices selected in combat persist on return to the guild.

### Dedicated Zone Map Scenes

- Combat environments are now selected from the mission zone instead of always using the initial village floor.
- Added separate editable scenes for Floresta Inicial, Caverna dos Lobos, Ruinas Antigas, Pantano Venenoso, Cemiterio Maldito, Portao Demoniaco, Fortaleza Demoniaca and Trono Demoniaco.
- Missions in the same region intentionally share that region's map scene.
- `Game.tscn` keeps the original embedded floor hidden as a fallback if a zone scene cannot be loaded.
- Added regression coverage that routes every campaign zone to a loadable and instantiable map scene.

### Defense Contract

- Added `Defesa do Marco da Floresta` as an early specialized defense contract in the initial zone.
- Defense missions spawn a protected ward objective in combat; enemies can target and damage it like a hero.
- The mission succeeds if the timer ends while the ward survives, and fails immediately if the ward is destroyed.
- HUD and mission board now display defense objective progress.
- Added regression coverage for defense mission profile data and protected-objective damage/destruction behavior.

### Medieval UI Component Pass

- Added a reusable medieval UI kit under `scenes/ui/components` and `scripts/ui/components`.
- New components include `MedievalButton`, `MenuPanel`, `ResourceBar`, `CompanionCard` and `UpgradeOptionCard`.
- Main menu, guild, mission select, companion roster, recruitment, guild upgrades, settings, pause and HUD now share the same medieval palette and button feedback.
- Roster and upgrade screens now render reusable card scenes instead of rebuilding all row structure inline.
- Main menu, guild and the major panel screens now use full-screen responsive margins instead of fixed centered boxes.
- Gameplay HUD now shows squad average level, average speed and live companion count alongside health, XP, timer, objective, coins and pause/flee actions.
- Follow-up text-fit pass now applies automatic label wrapping, compact ellipsis behavior for command labels/buttons, shorter locked facility labels and grid-based companion upgrade buttons to reduce menu misalignment from long Portuguese text.
- Fixed component setup order in the companion roster and guild upgrade screens so reusable card nodes are added to the scene tree before their `%Node` references are populated.
- Companion management cards now use dark medieval panels, visible light body text, compact card height and unclipped stats/trait labels so roster details do not disappear on parchment-colored cards.
- Recruitment candidate cards now use dark medieval panels, header/action layout and a visible multi-line details block for level, speed, ability, squad comparison and trait effects.
- Gameplay HUD top row now has tighter fixed widths for health/XP blocks, shorter companion bars, clearer squad text and coins reparented into the top HUD so core run information no longer truncates off-screen.
- Gameplay HUD now stacks XP under the player health block and uses compact labels (`M`, `Eq`, `Vel`, `C`) so timer, objective, pause and flee remain visible at 1228px-wide windows.
- Gameplay HUD action buttons now live in a dedicated top-right `ActionBar` outside the information row, with reserved right margin and wider buttons so `Pausar`/`Fugir` do not force label truncation.

### Mission Board Detail Expansion

- Mission readiness now exposes `risk_percent` alongside the readable risk label.
- Locked missions and empty squads report 100% risk, while available missions calculate risk from base danger, squad level delta, average speed and squad size.
- Mission cards now show description, numeric risk percentage, squad comparison, expected enemies, horde pressure, enemy stat/drop multipliers, victory condition, timer, reputation, material rewards, equipment chance and unlock rewards.
- Mission card details now render through a single wrapped multi-line label with explicit minimum height and no text trimming, avoiding the blank-card layout seen when many separate labels collapsed inside the card.
- Added regression coverage for numeric mission risk on available, locked and underleveled missions.

## Current State

- Default roster has six companions.
- Default active squad has three companions: `c_warrior_001`, `c_archer_001`, `c_cleric_001`.
- The squad screen is still a pragmatic bridge inside `CharactersScreen`, not the final guild UI.
- Runtime companion XP/level and selected companion upgrades are now written back to the persistent roster when the run ends.
- Recruitment queue now has a dedicated guild screen.
- Guild upgrades now affect roster capacity, mission XP, reroll costs, recruitment rarity and leader supplies.
- Companion death and resurrection are now represented in data and in a dedicated graveyard screen.
- End-of-run popup now communicates companion consequences before returning to the guild.
- Companions that level from mission rewards now wait for player-selected persistent upgrades in the guild roster screen.
- Guild upgrade progression now gates later structures through guild level.
- Recruitment now gives clearer candidate comparison and blocked-hire feedback.
- Leader selection and squad editing now live on separate guild screens.
- The blacksmith/equipment loop now exists as a first playable guild system.
- Equipment now has rarity, levels and paid upgrade scaling.
- Mission victories can now feed the equipment inventory.
- Equipment can now be reforged for rarity rerolls.
- Guild screen is more readable as facilities accumulate.
- Combat kills can now feed equipment progression, not only mission completion.
- Training field is now a playable companion-growth facility.
- Progression now extends toward the Demon King fortress.
- Missions can now have kill-count objectives beyond survival timers.
- The campaign now has a final Demon King completion state.
- Auto-save now has user-facing feedback in the guild.
- Enemy kills now feed persistent bestiary progress.
- Codex screen exposes bestiary progress from the guild.
- Guild morale now reflects victories, retreats and losses.
- Achievement milestones now track long-term guild progress and appear in the Codex.
- Heavy equipment now creates real speed tradeoffs for mission risk and fleeing.
- Settings are now a real persisted screen reachable from guild and main menu.
- Mission board now supports fast travel between unlocked regions once the level-3 Portal is available.
- More campaign and guild milestones now unlock through normal play.
- Enemy visuals now vary by mission/zone instead of only by wave number.
- Reputation is now a real mission reward and visible guild progress metric.
- Old settings placeholder UI has been removed from guild/main menu scenes.
- Mission cards clearly show whether a contract is survival or kill-count.
- Wounded companion state now has a real next-mission health penalty.
- Campaign progression now includes the planned swamp and cursed graveyard regions.
- The final mission now culminates in defeating a boss rather than filling an ordinary kill quota.
- The guild now has a recovery loop for companions returning wounded.
- Unlocked regions can now offer optional boss content outside the main campaign chain.
- Mission victory screens now visibly celebrate newly unlocked milestones.
- Zone-specific materials now persist and can be reviewed in the guild warehouse.
- Regional materials now feed equipment crafting choices in the blacksmith.
- The expanded facility grid is accommodated on the guild entry screen.
- Mission cards show reputation and regional materials before deployment.
- The first zone now offers a resource-collection contract in addition to survival.
- Newly recruited companions now carry meaningful trait bonuses shown in management screens.
- Mission selection now previews expected opposition before deployment.
- Each campaign region now loads its own editable combat map scene.
- The first specialized defense contract is playable in the initial zone.
- Primary menu screens now share reusable medieval UI components and mobile-friendlier full-screen panel layouts.
- HUD now includes squad level, average speed and live companion count.
- HUD now keeps coins, squad stats, timer, objective, pause and flee visible in the top row with less truncation.
- Long labels/buttons now have safer wrapping or ellipsis rules through the shared medieval UI helper.
- Roster and guild-upgrade menus no longer call reusable card `setup()` before card `_ready()`, avoiding crashes when navigating into those screens.
- Roster cards now show companion metadata, stats and traits with readable contrast in the squad management screen.
- Recruitment cards now show candidate details with readable contrast instead of pale text on parchment.
- Wounded persistent companions now enter combat with their saved partial health instead of being silently healed when placed in formation.
- Dropped combat equipment is now rolled on orb collection and only committed after victory or successful flee extraction; defeat loses pending loot.
- Material-gated heavy equipment is excluded from early mission and combat drop pools until the intended mission tier.
- The initial `cuidadosa` and `curiosa` traits now grant real bonuses; `sortudo` raises squad luck and old rosters migrate once.
- Squad luck now improves equipment reward/drop chances and is displayed during guild and mission preparation.
- Companion rarity and level milestones now unlock real critical, luck and ultimate evolution choices.
- The Ferreiro now unlocks at guild level 3, matching the Portal milestone described in the plan.
- The application start scene is now the guild scene.
- Party editing now allows removing companions, including clearing the party completely.
- Combat HUD now has a flee action. Flee takes 5 seconds to prepare, preserves companion run progress and applies a coin penalty based on squad mobility.
- Mission board is functional for selecting an unlocked mission before starting combat. The selected mission is saved.
- Mission board cards now include mission description, risk percentage and richer combat/reward details before deployment.
- Mission board detail text is consolidated into a visible multi-line block so the cards no longer show only title/buttons.
- Selected mission now affects combat pressure and enemy rewards.
- Missions now end automatically when their timer reaches zero.
- Timer victories now grant mission XP, unlock the next zone when configured and show the results in the popup.

## Pending After This Slice

- Add richer facility pages as systems mature.
- Add remaining specialized contract types, such as escort, only if their combat interactions can be made readable.
- Add final balance checks and remaining presentation polish.

## Validation Checklist

- Done: `godot --headless --path . --script res://tests/test_runner.gd` -> 357 tests passed after mission board risk/detail update.
- Done: `godot --headless --path . --scene res://scenes/Game.tscn --quit-after 8` -> combat scene booted cleanly after mission board risk/detail update.
- Done: `godot --headless --path . --quit-after 2` -> configured entry scene (`GuildScene`) booted cleanly after mission board risk/detail update.
- Done: `git diff --check` -> no whitespace errors reported.
- Known issue reproduced: direct headless launch of `MissionSelect.tscn` still crashes with the existing Godot 4.6.2 UI-only scene signal-11 pattern after the script loads; use full project boot or GUI/editor verification for that view.
- Note: concurrent Godot headless validations can reproduce the existing Godot 4.6.2 signal-11 crash on this machine; the isolated validations above complete cleanly.
- Known issue reproduced: `--check-only --script` on the edited Control UI scripts also triggers the existing Godot 4.6.2 headless signal-11 crash on this machine; validation therefore relies on the stable unit-test and scene-boot paths above.
- Known issue reproduced: direct headless launch of `BlacksmithScreen.tscn` crashes with the same Godot 4.6.2 UI-only scene crash pattern.
- Known issue: direct headless launch of UI-only scenes still crashes Godot 4.6.2 on this machine; `GraveyardScene.tscn` hit the same engine crash pattern as the older UI scenes.
- Note: Direct headless runs of UI-only scenes crash Godot 4.6.2 on this machine, including the existing `MainMenu`, `CharactersScreen` and `UpgradesScreen`; use editor/GUI verification for UI scene rendering.

## Files Changed By This Slice

- `IMPLEMENTATION_STATUS.md`
- `project.godot`
- `scenes/Game.tscn`
- `scenes/maps/InitialForestMap.tscn`
- `scenes/maps/WolfCaveMap.tscn`
- `scenes/maps/AncientRuinsMap.tscn`
- `scenes/maps/PoisonSwampMap.tscn`
- `scenes/maps/CursedGraveyardMap.tscn`
- `scenes/maps/DemonGateMap.tscn`
- `scenes/maps/DemonKeepMap.tscn`
- `scenes/maps/DemonThroneMap.tscn`
- `scenes/ui/GuildScene.tscn`
- `scenes/ui/GraveyardScene.tscn`
- `scenes/ui/BlacksmithScreen.tscn`
- `scenes/ui/LeaderScreen.tscn`
- `scenes/ui/TrainingScreen.tscn`
- `scenes/ui/CodexScreen.tscn`
- `scenes/ui/SettingsScreen.tscn`
- `scenes/ui/InfirmaryScreen.tscn`
- `scenes/ui/WarehouseScreen.tscn`
- `scenes/ui/MissionSelect.tscn`
- `scenes/ui/CharactersScreen.tscn`
- `scenes/ui/HUD.tscn`
- `scenes/ui/CompanionChoices.tscn`
- `scenes/ui/components/MedievalButton.tscn`
- `scenes/ui/components/MenuPanel.tscn`
- `scenes/ui/components/ResourceBar.tscn`
- `scenes/ui/components/CompanionCard.tscn`
- `scenes/ui/components/UpgradeOptionCard.tscn`
- `scripts/core/game_data.gd`
- `scripts/game/companion.gd`
- `scripts/game/companion_manager.gd`
- `scripts/game/xp_orb.gd`
- `scripts/game/enemy.gd`
- `scripts/game/enemy_spawner.gd`
- `scripts/game/game_manager.gd`
- `scripts/game/game_balance.gd`
- `scripts/game/zone_map.gd`
- `scripts/game/defense_objective.gd`
- `scripts/ui/guild_scene.gd`
- `scripts/ui/mission_select.gd`
- `scripts/ui/companion_choices.gd`
- `scripts/ui/characters_screen.gd`
- `scripts/ui/game_over.gd`
- `scripts/ui/graveyard_scene.gd`
- `scripts/ui/blacksmith_screen.gd`
- `scripts/ui/leader_screen.gd`
- `scripts/ui/training_screen.gd`
- `scripts/ui/codex_screen.gd`
- `scripts/ui/settings_screen.gd`
- `scripts/ui/infirmary_screen.gd`
- `scripts/ui/warehouse_screen.gd`
- `scripts/ui/hud.gd`
- `scripts/ui/mission_select.gd`
- `scripts/ui/recruitment_scene.gd`
- `scripts/ui/upgrades_screen.gd`
- `scripts/ui/components/medieval_ui.gd`
- `scripts/ui/components/medieval_button.gd`
- `scripts/ui/components/menu_panel.gd`
- `scripts/ui/components/resource_bar.gd`
- `scripts/ui/components/companion_card.gd`
- `scripts/ui/components/upgrade_option_card.gd`
- `tests/test_runner.gd`
