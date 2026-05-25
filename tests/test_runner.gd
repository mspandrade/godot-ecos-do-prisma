extends SceneTree

const RunStateScript := preload("res://scripts/core/run_state.gd")
const UpgradeManagerScript := preload("res://scripts/game/upgrade_manager.gd")
const GameDataScript := preload("res://scripts/core/game_data.gd")
const CompanionScript := preload("res://scripts/game/companion.gd")
const CompanionManagerScript := preload("res://scripts/game/companion_manager.gd")
const EnemySpawnerScript := preload("res://scripts/game/enemy_spawner.gd")
const ScenePoolScript := preload("res://scripts/core/scene_pool.gd")
const PoolItemScript := preload("res://tests/pool_item.gd")

class FakeCompanion:
	extends Node
	signal leveled_up(companion: Node, choices: Array)
	var is_down := false
	var received_xp := 0

	func add_xp(amount: int) -> void:
		received_xp += amount

	func apply_upgrade(_upgrade_id: String) -> void:
		pass

var failures := 0
var total := 0

func _init() -> void:
	print("Running unit tests...")
	_test_run_state_leveling()
	_test_run_state_multiple_levelups_and_signals()
	_test_weapon_and_passive_limits()
	_test_survival_passives()
	_test_companion_level_and_upgrades()
	_test_companion_ignores_xp_and_upgrades_when_unavailable()
	_test_cleric_heals_recruited_companions()
	_test_companion_manager_distributes_xp_only_to_active_recruits()
	_test_upgrade_choices_respect_limits()
	_test_upgrade_request_emits_available_choices()
	_test_weapon_evolution()
	_test_weapon_evolution_requires_passive_and_level()
	_test_save_feedback_signal()
	_test_settings_persistence()
	_test_bestiary_kill_tracking()
	_test_achievement_unlocks()
	_test_achievement_persistence()
	_test_extended_achievement_hooks()
	_test_guild_upgrade_cost_formula()
	_test_guild_upgrade_effects()
	_test_guild_upgrade_requirements()
	_test_training_field_companion_training()
	_test_guild_morale_changes_with_results()
	_test_default_guild_squad_summary()
	_test_squad_can_be_emptied()
	_test_flee_coin_retention_uses_squad_speed()
	_test_mission_readiness_uses_squad_and_unlocks()
	_test_fast_travel_zone_unlocks()
	_test_selected_mission_combat_profile()
	_test_resource_collection_mission_profile()
	_test_mission_victory_rewards_progression()
	_test_optional_boss_mission_progression()
	_test_late_game_mission_progression()
	_test_demon_king_final_completion()
	_test_persistent_companion_upgrade_choice()
	_test_flee_does_not_complete_mission()
	_test_enemy_spawner_accepts_mission_profile()
	_test_companion_run_results_update_roster()
	_test_wounded_companion_starts_next_mission_injured()
	_test_infirmary_treats_wounded_companion()
	_test_dead_companion_resurrection_flow()
	_test_blacksmith_equipment_flow()
	_test_heavy_equipment_speed_penalty()
	_test_random_equipment_award()
	_test_recruitment_hire_adds_companion()
	_test_recruitment_reroll_spends_coins_and_scales_cost()
	_test_scene_pool_acquire_and_recycle_signal()
	if failures == 0:
		print("All %d tests passed." % total)
	else:
		push_error("%d of %d tests failed." % [failures, total])
	quit(failures)

func _assert_true(condition: bool, message: String) -> void:
	total += 1
	if condition:
		print("PASS: %s" % message)
	else:
		failures += 1
		push_error("FAIL: %s" % message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	_assert_true(actual == expected, "%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func _assert_float_eq(actual: float, expected: float, message: String) -> void:
	_assert_true(is_equal_approx(actual, expected), "%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func _test_run_state_leveling() -> void:
	var state: RunState = RunStateScript.new()
	var leveled := state.add_xp(8)
	_assert_true(leveled, "XP crossing threshold reports level up")
	_assert_eq(state.level, 2, "Run level increments")
	_assert_eq(state.xp, 0, "XP remainder is preserved after exact level up")
	_assert_true(state.xp_required > 8, "Next XP requirement scales upward")
	state.free()

func _test_run_state_multiple_levelups_and_signals() -> void:
	var state: RunState = RunStateScript.new()
	var levels := []
	var xp_events := []
	var coin_events := []
	state.level_changed.connect(func(level: int): levels.append(level))
	state.xp_changed.connect(func(current: int, required: int): xp_events.append([current, required]))
	state.coins_changed.connect(func(coins: int): coin_events.append(coins))
	var leveled := state.add_xp(30)
	state.add_coins(7)
	_assert_true(leveled, "Large XP gain reports at least one level up")
	_assert_eq(state.level, 3, "Large XP gain can cross multiple levels")
	_assert_eq(state.xp, 8, "Large XP gain preserves remainder after multiple level ups")
	_assert_eq(levels, [2, 3], "Level signal emits once per gained level")
	_assert_eq(xp_events, [[8, 22]], "XP signal emits final XP state")
	_assert_eq(coin_events, [7], "Coin signal emits updated coin total")
	state.free()

func _test_weapon_and_passive_limits() -> void:
	var state: RunState = RunStateScript.new()
	for id in ["bolt", "aura", "orbit", "burst", "wisp", "nova"]:
		_assert_true(state.can_add_weapon(id), "Weapon slot accepts %s" % id)
		state.add_weapon_level(id)
	_assert_true(not state.can_add_weapon("seventh"), "Seventh new weapon is rejected")
	_assert_true(state.can_add_weapon("bolt"), "Existing weapon can still level when slots are full")
	for id in ["might", "haste", "magnet", "guard", "luck", "focus"]:
		_assert_true(state.can_add_passive(id), "Passive slot accepts %s" % id)
		state.add_passive_level(id)
	_assert_true(not state.can_add_passive("seventh_passive"), "Seventh new passive is rejected")
	_assert_true(state.can_add_passive("might"), "Existing passive can still level when slots are full")
	state.free()

func _test_survival_passives() -> void:
	var state: RunState = RunStateScript.new()
	state.add_passive_level("vitality")
	state.add_passive_level("guard")
	state.add_passive_level("renewal")
	_assert_eq(state.max_health_bonus, 18.0, "Vitality passive increases run max health")
	_assert_eq(state.damage_reduction, 0.08, "Guard passive increases damage reduction")
	_assert_eq(state.regen_per_second, 0.7, "Renewal passive increases health regeneration")
	for i in range(10):
		state.add_passive_level("guard")
	_assert_true(state.damage_reduction <= 0.55, "Guard damage reduction is capped")
	state.free()

func _test_companion_level_and_upgrades() -> void:
	var companion: Node = CompanionScript.new()
	companion.is_recruited = true
	companion.attack_damage = 10.0
	companion.attack_cooldown = 2.0
	companion.max_health = 20.0
	companion.attack_range = 100.0
	companion.ability_power = 1.0
	companion.move_speed = 200.0
	companion.speed_rating = 5.0
	companion.xp_required = 5
	companion.add_xp(5)
	_assert_eq(companion.level, 2, "Companion levels up after receiving enough XP")
	companion.apply_upgrade("damage")
	companion.apply_upgrade("cooldown")
	companion.apply_upgrade("health")
	companion.apply_upgrade("range")
	companion.apply_upgrade("speed")
	companion.apply_upgrade("ability")
	_assert_float_eq(companion.attack_damage, 11.2, "Companion damage upgrade applies")
	_assert_float_eq(companion.attack_cooldown, 1.86, "Companion cooldown upgrade applies")
	_assert_float_eq(companion.max_health, 28.0, "Companion health upgrade applies")
	_assert_float_eq(companion.attack_range, 118.0, "Companion range upgrade applies")
	_assert_float_eq(companion.move_speed, 210.0, "Companion speed upgrade applies to movement")
	_assert_float_eq(companion.speed_rating, 5.35, "Companion speed upgrade applies to squad rating")
	_assert_float_eq(companion.ability_power, 1.15, "Companion ability upgrade applies")
	companion.take_damage(40.0)
	_assert_eq(companion.health, 0.0, "Companion can fall after taking lethal damage")
	_assert_true(companion.is_down, "Companion enters downed state after falling")
	_assert_eq(companion.state, "caido", "Fallen companion waits in caido state")
	_assert_true(not companion.is_damage_target(), "Downed companion is no longer a damage target")
	companion._process_downed(companion.downed_duration)
	_assert_eq(companion.state, "morto", "Downed companion dies when the rescue timer expires")
	companion.free()

func _test_companion_ignores_xp_and_upgrades_when_unavailable() -> void:
	var companion: Node = CompanionScript.new()
	companion.attack_damage = 10.0
	companion.max_health = 20.0
	companion.health = 20.0
	companion.xp_required = 5
	companion.add_xp(5)
	_assert_eq(companion.level, 1, "Unrecruited companion ignores XP")
	companion.apply_upgrade("damage")
	_assert_float_eq(companion.attack_damage, 10.0, "Unrecruited companion ignores upgrades")
	companion.is_recruited = true
	companion.take_damage(30.0)
	companion.add_xp(5)
	companion.apply_upgrade("health")
	_assert_eq(companion.level, 1, "Downed companion ignores XP")
	_assert_float_eq(companion.max_health, 20.0, "Downed companion ignores upgrades")
	companion.free()

func _test_cleric_heals_recruited_companions() -> void:
	var player := Node2D.new()
	player.global_position = Vector2.ZERO

	var cleric: Node = CompanionScript.new()
	cleric.player = player
	cleric.class_type = "cleric"
	cleric.is_recruited = true
	cleric.attack_damage = 5.0
	cleric.attack_range = 210.0
	cleric.ability_power = 1.0
	cleric.global_position = Vector2.ZERO

	var wounded: Node = CompanionScript.new()
	wounded.is_recruited = true
	wounded.max_health = 22.0
	wounded.health = 10.0
	wounded.global_position = Vector2(40, 0)

	var healed: bool = cleric._heal_companion_targets([wounded])
	_assert_true(healed, "Cleric reports healing when companion is wounded in area")
	_assert_float_eq(wounded.health, 15.0, "Cleric heals recruited companion in area")

	wounded.free()
	cleric.free()
	player.free()

func _test_companion_manager_distributes_xp_only_to_active_recruits() -> void:
	var manager: Node = CompanionManagerScript.new()
	var active := FakeCompanion.new()
	var downed := FakeCompanion.new()
	downed.is_down = true
	manager.recruited_companions.append(active)
	manager.recruited_companions.append(downed)
	manager.distribute_xp(5)
	_assert_eq(active.received_xp, 3, "Companion manager shares rounded XP with active recruits")
	_assert_eq(downed.received_xp, 0, "Companion manager skips downed recruits")
	active.free()
	downed.free()
	manager.free()

func _test_upgrade_choices_respect_limits() -> void:
	var state: RunState = RunStateScript.new()
	var manager: UpgradeManager = UpgradeManagerScript.new()
	manager.setup(state, null)
	for id in ["bolt", "aura", "orbit", "burst", "wisp", "nova"]:
		state.add_weapon_level(id)
	for i in range(8):
		state.add_weapon_level("bolt")
	for id in ["might", "haste", "magnet", "guard", "luck", "focus"]:
		state.add_passive_level(id)
	for i in range(5):
		state.add_passive_level("might")
	for upgrade in manager.upgrades:
		if upgrade["kind"] == "weapon" and not state.weapon_levels.has(upgrade["id"]):
			_assert_true(not manager._can_offer(upgrade), "Manager rejects new weapon when slots are full")
		if upgrade["kind"] == "passive" and not state.passive_levels.has(upgrade["id"]):
			_assert_true(not manager._can_offer(upgrade), "Manager rejects new passive when slots are full")
	_assert_true(not manager._can_offer({"id": "bolt", "kind": "weapon"}), "Manager rejects max-level weapon")
	_assert_true(not manager._can_offer({"id": "might", "kind": "passive"}), "Manager rejects max-level passive")
	manager.free()
	state.free()

func _test_upgrade_request_emits_available_choices() -> void:
	var state: RunState = RunStateScript.new()
	var manager: UpgradeManager = UpgradeManagerScript.new()
	var emitted_choices := []
	manager.setup(state, null)
	manager.choices_ready.connect(func(choices: Array):
		emitted_choices.clear()
		emitted_choices.append_array(choices)
	)
	manager.request_choices()
	_assert_true(emitted_choices.size() > 0, "Upgrade request emits choices")
	_assert_true(emitted_choices.size() <= 3, "Upgrade request limits choices to three")
	for choice in emitted_choices:
		_assert_true(manager._can_offer(choice), "Emitted upgrade choice is currently offerable")
	for upgrade in manager.upgrades:
		var max_level := 8 if upgrade["kind"] == "weapon" else 5
		for i in range(max_level):
			if upgrade["kind"] == "weapon":
				state.add_weapon_level(str(upgrade["id"]))
			else:
				state.add_passive_level(str(upgrade["id"]))
	emitted_choices.clear()
	manager.request_choices()
	_assert_eq(emitted_choices.size(), 0, "Upgrade request emits no choices when everything is capped")
	manager.free()
	state.free()

func _test_weapon_evolution() -> void:
	var state: RunState = RunStateScript.new()
	var manager: UpgradeManager = UpgradeManagerScript.new()
	manager.setup(state, null)
	for i in range(8):
		state.add_weapon_level("bolt")
	state.add_passive_level("might")
	manager._check_evolutions()
	_assert_eq(state.weapon_levels["bolt"], 10, "Weapon evolves when level and passive requirement are met")
	manager.free()
	state.free()

func _test_weapon_evolution_requires_passive_and_level() -> void:
	var state: RunState = RunStateScript.new()
	var manager: UpgradeManager = UpgradeManagerScript.new()
	manager.setup(state, null)
	for i in range(7):
		state.add_weapon_level("aura")
	state.add_passive_level("magnet")
	manager._check_evolutions()
	_assert_eq(state.weapon_levels["aura"], 7, "Weapon does not evolve below required level")
	state.add_weapon_level("aura")
	state.passive_levels.clear()
	manager._check_evolutions()
	_assert_eq(state.weapon_levels["aura"], 8, "Weapon does not evolve without required passive")
	manager.free()
	state.free()

func _test_save_feedback_signal() -> void:
	var data: Node = GameDataScript.new()
	var messages := []
	data.save_feedback.connect(func(message: String): messages.append(message))
	data.add_coins(1)
	_assert_true(messages.has("Progresso salvo."), "Save feedback emits after save")
	data.free()

func _test_settings_persistence() -> void:
	var data: Node = GameDataScript.new()
	var events := []
	data.settings_changed.connect(func(_settings: Dictionary): events.append("changed"))
	_assert_true(data.set_game_setting("master_volume", 0.45), "Master volume setting can be changed")
	_assert_true(data.set_game_setting("fullscreen", false), "Fullscreen setting can be changed")
	_assert_true(events.size() >= 2, "Settings emit change events")
	var loaded: Node = GameDataScript.new()
	loaded.load_data()
	var current: Dictionary = loaded.get_settings()
	_assert_float_eq(float(current.get("master_volume", 0.0)), 0.45, "Master volume setting persists")
	_assert_eq(bool(current.get("fullscreen", true)), false, "Fullscreen setting persists")
	data.free()
	loaded.free()

func _test_bestiary_kill_tracking() -> void:
	var data: Node = GameDataScript.new()
	var events := []
	data.bestiary_changed.connect(func(): events.append("changed"))
	data.add_bestiary_kills({"goblin_green_sword": 3, "slime_orange": 2})
	data.add_bestiary_kills({"goblin_green_sword": 1})
	var bestiary: Dictionary = data.get_bestiary()
	_assert_true(events.size() > 0, "Bestiary emits when kills are tracked")
	_assert_eq(bestiary["goblin_green_sword"], 4, "Bestiary accumulates repeated enemy kills")
	_assert_eq(bestiary["slime_orange"], 2, "Bestiary tracks multiple enemy types")
	data.free()

func _test_achievement_unlocks() -> void:
	var data: Node = GameDataScript.new()
	var unlocked := []
	data.achievement_unlocked.connect(func(achievement_id: String): unlocked.append(achievement_id))
	data.add_bestiary_kills({"goblin_green_sword": 25})
	_assert_true(bool(data.get_achievements().get("bestiary_25", false)), "Bestiary milestone unlocks achievement")
	_assert_true(unlocked.has("bestiary_25"), "Achievement unlock emits signal")
	data.apply_mission_result("initial_forest_survival", "vitoria")
	_assert_true(bool(data.get_achievements().get("first_contract", false)), "First victory unlocks contract achievement")
	data.free()

func _test_achievement_persistence() -> void:
	var data: Node = GameDataScript.new()
	data.add_bestiary_kills({"goblin_green_sword": 25})
	var loaded: Node = GameDataScript.new()
	loaded.load_data()
	_assert_true(bool(loaded.get_achievements().get("bestiary_25", false)), "Achievement unlock persists in the same save cycle")
	data.free()
	loaded.free()

func _test_extended_achievement_hooks() -> void:
	var data: Node = GameDataScript.new()
	data.coins = 20000
	data.toggle_companion_in_squad("c_tank_001")
	data.toggle_companion_in_squad("c_mage_001")
	data.toggle_companion_in_squad("c_assassin_001")
	_assert_true(bool(data.get_achievements().get("full_squad", false)), "Full squad unlocks achievement")
	data.recruitment = {
		"available": [{
			"name": "Rafa",
			"class": "archer",
			"class_name": "Arqueiro",
			"rarity": "comum",
			"level": 1,
			"cost": 100,
			"traits": [],
			"ability": "Tiro Certeiro",
			"speed_rating": 6.0
		}],
		"reroll_count": 0
	}
	_assert_true(data.hire_recruit(0), "Hiring seventh companion succeeds")
	_assert_true(bool(data.get_achievements().get("expanded_roster", false)), "Expanded roster unlocks achievement")
	for i in range(4):
		_assert_true(data.buy_permanent_upgrade("guild_hall"), "Guild hall can be upgraded toward level five")
	_assert_true(bool(data.get_achievements().get("guild_level_5", false)), "Guild level five unlocks achievement")
	data.apply_companion_run_results([{
		"id": "c_warrior_001",
		"level": 1,
		"xp": 0,
		"xp_required": 10,
		"max_health": 24.0,
		"current_health": 0.0,
		"state": "morto"
	}])
	_assert_true(bool(data.get_achievements().get("first_death", false)), "First companion death unlocks achievement")
	_assert_true(data.resurrect_companion("c_warrior_001"), "Resurrection succeeds for achievement test")
	_assert_true(bool(data.get_achievements().get("first_resurrection", false)), "First resurrection unlocks achievement")
	data.free()

func _test_guild_upgrade_cost_formula() -> void:
	var data: Node = GameDataScript.new()
	data.permanent_upgrades["guild_hall"] = 0
	_assert_eq(data.get_upgrade_cost("guild_hall"), 220, "Guild upgrade base cost is used at level zero")
	data.permanent_upgrades["guild_hall"] = 3
	_assert_eq(data.get_upgrade_cost("guild_hall"), 1000, "Guild upgrade cost scales by step per level")
	data.free()

func _test_guild_upgrade_effects() -> void:
	var data: Node = GameDataScript.new()
	data.coins = 1200
	_assert_true(data.buy_permanent_upgrade("dormitories"), "Dormitory guild upgrade can be bought")
	_assert_eq(data.guild["companion_capacity"], 14, "Dormitory upgrade increases companion capacity")
	data.permanent_upgrades["recruiter_network"] = 2
	_assert_eq(data.get_reroll_cost(), 80, "Recruiter network discounts reroll cost")
	data.permanent_upgrades["training_field"] = 2
	_assert_float_eq(data.get_mission_xp_multiplier(), 1.3, "Training field increases mission XP multiplier")
	data.permanent_upgrades["supply_cache"] = 1
	var stats: Dictionary = data.get_selected_stats()
	_assert_float_eq(float(stats["max_health"]), 110.0, "Supply cache increases leader health")
	_assert_float_eq(float(stats["pickup_range"]), 128.0, "Supply cache increases leader pickup range")
	data.free()

func _test_guild_upgrade_requirements() -> void:
	var data: Node = GameDataScript.new()
	data.coins = 1200
	_assert_true(not data.can_buy_permanent_upgrade("training_field"), "Training field is locked before guild level requirement")
	_assert_eq(data.get_upgrade_lock_reason("training_field"), "Requer Guilda Nv 2.", "Locked guild upgrade reports requirement")
	_assert_true(not data.buy_permanent_upgrade("training_field"), "Locked guild upgrade cannot be bought")
	_assert_true(data.buy_permanent_upgrade("guild_hall"), "Guild hall can be upgraded first")
	_assert_eq(data.guild["level"], 2, "Guild hall upgrade raises guild level")
	_assert_true(data.can_buy_permanent_upgrade("training_field"), "Training field unlocks after guild reaches level two")
	_assert_true(data.buy_permanent_upgrade("training_field"), "Unlocked guild upgrade can be bought")
	data.free()

func _test_training_field_companion_training() -> void:
	var data: Node = GameDataScript.new()
	data.add_coins(500)
	var before_attack := float(data.get_companion_roster()["c_warrior_001"]["attack"])
	_assert_true(not data.train_companion("c_warrior_001", "attack"), "Training is locked before training field structure")
	data.permanent_upgrades["guild_hall"] = 1
	data.get_companion_roster()
	var cost: int = data.get_training_cost("c_warrior_001")
	_assert_true(data.train_companion("c_warrior_001", "attack"), "Training field can train companion")
	_assert_eq(data.coins, 500 - cost, "Training spends coins")
	_assert_float_eq(float(data.companion_roster["c_warrior_001"]["attack"]), before_attack * 1.06, "Training improves companion attack")
	_assert_eq(data.companion_roster["c_warrior_001"]["training_sessions"], 1, "Training session count increases")
	_assert_true(data.get_training_cost("c_warrior_001") > cost, "Training cost scales after sessions")
	data.free()

func _test_guild_morale_changes_with_results() -> void:
	var data: Node = GameDataScript.new()
	_assert_eq(data.get_morale_label(), "Estavel", "Default morale label is stable")
	var victory: Dictionary = data.apply_mission_result("initial_forest_survival", "vitoria")
	_assert_eq(data.guild["morale"], 55, "Victory improves guild morale")
	_assert_eq(victory["morale_delta"], 5, "Mission result reports morale gain")
	var flee: Dictionary = data.apply_mission_result("initial_forest_survival", "fuga")
	_assert_eq(data.guild["morale"], 52, "Fleeing reduces guild morale")
	_assert_eq(flee["morale_delta"], -3, "Mission result reports morale loss")
	data.apply_companion_run_results([{"id": "c_warrior_001", "state": "morto"}])
	_assert_eq(data.guild["morale"], 44, "Companion death reduces guild morale")
	_assert_eq(data.get_morale_label(), "Tensa", "Morale label changes when morale drops")
	data.free()

func _test_default_guild_squad_summary() -> void:
	var data: Node = GameDataScript.new()
	var summary: Dictionary = data.get_squad_summary()
	var combat_defs: Array = data.get_active_companion_defs()
	_assert_eq(summary["size"], 3, "Default guild starts with three active companions")
	_assert_float_eq(summary["average_speed"], 6.0, "Default squad speed average uses companion ratings")
	_assert_eq(summary["speed_label"], "Equilibrado", "Default squad speed gets a readable label")
	_assert_eq(combat_defs.size(), 3, "Combat companion defs come from active squad")
	_assert_eq(combat_defs[0]["id"], "c_warrior_001", "Combat companion keeps persistent roster id")
	data.free()

func _test_squad_can_be_emptied() -> void:
	var data: Node = GameDataScript.new()
	var starting_squad: Array = data.get_active_squad().duplicate()
	for companion_id in starting_squad:
		_assert_true(data.toggle_companion_in_squad(str(companion_id)), "Squad member can be removed")
	_assert_eq(data.get_active_squad().size(), 0, "Squad can be empty while editing party")
	_assert_eq(data.get_squad_summary()["size"], 0, "Empty squad is not repopulated by summary")
	_assert_eq(data.get_active_companion_defs().size(), 0, "Empty squad does not spawn fallback companions")
	data.free()

func _test_flee_coin_retention_uses_squad_speed() -> void:
	var data: Node = GameDataScript.new()
	_assert_float_eq(data.get_flee_coin_retention(), 0.75, "Balanced default squad keeps most coins when fleeing")
	data.active_squad = ["c_tank_001"]
	_assert_float_eq(data.get_flee_coin_retention(), 0.45, "Very slow squad keeps fewer coins when fleeing")
	data.active_squad = ["c_assassin_001"]
	_assert_float_eq(data.get_flee_coin_retention(), 1.0, "Very fast squad keeps all coins when fleeing")
	data.free()

func _test_mission_readiness_uses_squad_and_unlocks() -> void:
	var data: Node = GameDataScript.new()
	var initial: Dictionary = data.get_mission_readiness("initial_forest_survival")
	_assert_true(initial["can_start"], "Initial mission can start with default squad")
	_assert_eq(initial["risk"], "Baixo", "Initial mission starts with low risk")
	var locked: Dictionary = data.get_mission_readiness("wolf_cave_scout")
	_assert_true(not locked["unlocked"], "Locked mission reports locked state")
	_assert_true(not data.select_mission("wolf_cave_scout"), "Cannot select locked mission")
	data.guild["unlocked_zones"] = ["initial_forest", "wolf_cave"]
	_assert_true(data.select_mission("wolf_cave_scout"), "Can select mission after unlocking zone")
	var cave: Dictionary = data.get_mission_readiness("wolf_cave_scout")
	_assert_true(cave["unlocked"], "Unlocked mission reports available")
	_assert_true(cave["warnings"].has("Esquadrao abaixo do level recomendado."), "Underleveled squad warns before mission")
	data.free()

func _test_fast_travel_zone_unlocks() -> void:
	var data: Node = GameDataScript.new()
	var zones: Array = data.get_travel_zones()
	_assert_true(zones.size() >= 2, "Travel board exposes known zones")
	_assert_eq(data.get_selected_travel_zone(), "initial_forest", "Initial travel zone is selected")
	_assert_true(not data.select_travel_zone("wolf_cave"), "Locked travel zone cannot be selected")
	data.apply_mission_result("initial_forest_survival", "vitoria")
	_assert_true(not data.select_travel_zone("wolf_cave"), "Unlocked zone still requires the guild portal for travel")
	data.permanent_upgrades["guild_hall"] = 2
	data.get_companion_roster()
	_assert_true(data.is_fast_travel_unlocked(), "Guild level three unlocks the portal")
	_assert_true(data.select_travel_zone("wolf_cave"), "Unlocked travel zone can be selected")
	_assert_eq(data.get_selected_travel_zone(), "wolf_cave", "Travel zone selection is stored")
	data.free()

func _test_selected_mission_combat_profile() -> void:
	var data: Node = GameDataScript.new()
	var initial: Dictionary = data.get_selected_mission_combat_profile()
	_assert_eq(initial["mission_id"], "initial_forest_survival", "Combat profile includes selected mission id")
	_assert_float_eq(initial["enemy_health_multiplier"], 1.0, "Initial mission keeps base enemy health")
	_assert_float_eq(initial["duration_seconds"], 180.0, "Initial mission has a phase timer")
	_assert_eq(initial["completion_coin_reward"], 80, "Initial mission has a completion coin reward")
	data.guild["unlocked_zones"] = ["initial_forest", "wolf_cave"]
	data.select_mission("wolf_cave_scout")
	var cave: Dictionary = data.get_selected_mission_combat_profile()
	_assert_eq(cave["mission_id"], "wolf_cave_scout", "Combat profile follows selected mission")
	_assert_float_eq(cave["duration_seconds"], 240.0, "Selected harder mission has its own timer")
	_assert_eq(cave["objective_type"], "kill_count", "Selected harder mission can use kill objective")
	_assert_eq(cave["target_kills"], 140, "Kill objective exposes target count")
	_assert_true(float(cave["enemy_speed_multiplier"]) > 1.0, "Wolf cave combat profile makes enemies faster")
	_assert_true(float(cave["coin_multiplier"]) > 1.0, "Harder mission improves coin drops")
	_assert_true((cave["enemy_sprites"] as Array).has("bat_purple"), "Mission combat profile carries zone enemy sprites")
	data.free()

func _test_resource_collection_mission_profile() -> void:
	var data: Node = GameDataScript.new()
	_assert_true(data.select_mission("initial_forest_gathering"), "Resource contract is available in the initial zone")
	var profile: Dictionary = data.get_selected_mission_combat_profile()
	_assert_eq(profile["objective_type"], "collect_resources", "Resource contract uses collection objective")
	_assert_eq(profile["target_resources"], 45, "Resource contract exposes required pickup count")
	var result: Dictionary = data.apply_mission_result("initial_forest_gathering", "vitoria")
	_assert_true((result["material_rewards"] as Array).has("Ervas da Floresta x4"), "Resource contract grants extra regional materials")
	data.free()

func _test_mission_victory_rewards_progression() -> void:
	var data: Node = GameDataScript.new()
	data.recruitment["reroll_count"] = 2
	data.missions["initial_forest_survival"]["equipment_reward_chance"] = 1.0
	var summary: Dictionary = data.apply_mission_result("initial_forest_survival", "vitoria")
	_assert_eq(summary["xp_per_companion"], 10, "Mission XP reward is split across active companions")
	_assert_eq(summary["reputation_reward"], 3, "Mission victory reports reputation reward")
	_assert_eq(data.guild["reputation"], 3, "Mission victory increases guild reputation")
	_assert_eq(data.companion_roster["c_warrior_001"]["level"], 2, "Mission XP can level active companions")
	_assert_eq(data.companion_roster["c_warrior_001"]["pending_upgrades"], 1, "Mission level up creates pending companion upgrade")
	_assert_true(summary["leveled_companions"].has("Bruna"), "Mission result reports companions that leveled")
	_assert_true((summary["unlocked_achievements"] as Array).has("Primeiro Contrato"), "Mission result reports newly unlocked achievement")
	_assert_true((summary["material_rewards"] as Array).has("Ervas da Floresta x2"), "Mission result reports zone material reward")
	_assert_eq(data.get_materials()["forest_herbs"], 2, "Mission victory stores zone materials")
	_assert_true(data.guild["unlocked_zones"].has("wolf_cave"), "Completing initial mission unlocks wolf cave")
	_assert_true(summary["unlocked_zone_names"].has("Caverna dos Lobos"), "Mission result reports unlocked zone name")
	_assert_eq(data.get_equipment_inventory().size(), 1, "Mission victory can award equipment")
	_assert_eq((summary["equipment_rewards"] as Array).size(), 1, "Mission result reports equipment reward")
	_assert_eq(data.recruitment["reroll_count"], 0, "Mission return resets recruitment reroll cost")
	data.free()

func _test_optional_boss_mission_progression() -> void:
	var data: Node = GameDataScript.new()
	data.guild["unlocked_zones"] = ["initial_forest", "wolf_cave"]
	_assert_true(data.select_mission("wolf_cave_alpha_hunt"), "Optional boss mission is available in unlocked zone")
	var profile: Dictionary = data.get_selected_mission_combat_profile()
	_assert_eq(profile["objective_type"], "boss_kill", "Optional boss mission uses boss objective")
	_assert_eq(profile["target_bosses"], 1, "Optional boss mission targets one boss")
	var summary: Dictionary = data.apply_mission_result("wolf_cave_alpha_hunt", "vitoria")
	_assert_true(bool(data.get_achievements().get("first_boss", false)), "Completing a boss mission unlocks boss achievement")
	_assert_true((summary["unlocked_achievements"] as Array).has("Cacador de Alfas"), "Boss mission result reports boss achievement")
	data.free()

func _test_late_game_mission_progression() -> void:
	var data: Node = GameDataScript.new()
	data.guild["unlocked_zones"] = ["initial_forest", "wolf_cave", "ancient_ruins"]
	var locked_readiness: Dictionary = data.get_mission_readiness("demon_gate_assault")
	_assert_true(not bool(locked_readiness["unlocked"]), "Demon gate starts locked")
	var ancient_summary: Dictionary = data.apply_mission_result("ancient_ruins_contract", "vitoria")
	_assert_true(data.guild["unlocked_zones"].has("poison_swamp"), "Completing ancient ruins unlocks poison swamp")
	_assert_true((ancient_summary["unlocked_zone_names"] as Array).has("Pantano Venenoso"), "Ancient ruins reports poison swamp unlock")
	_assert_true(data.select_mission("poison_swamp_purge"), "Unlocked poison swamp mission can be selected")
	var swamp_summary: Dictionary = data.apply_mission_result("poison_swamp_purge", "vitoria")
	_assert_true(data.guild["unlocked_zones"].has("cursed_graveyard"), "Completing poison swamp unlocks cursed graveyard")
	_assert_true((swamp_summary["unlocked_zone_names"] as Array).has("Cemiterio Maldito"), "Poison swamp reports cursed graveyard unlock")
	_assert_true(data.select_mission("cursed_graveyard_hunt"), "Unlocked cursed graveyard mission can be selected")
	var graveyard_summary: Dictionary = data.apply_mission_result("cursed_graveyard_hunt", "vitoria")
	_assert_true(data.guild["unlocked_zones"].has("demon_gate"), "Completing cursed graveyard unlocks demon gate")
	_assert_true((graveyard_summary["unlocked_zone_names"] as Array).has("Portao Demoniaco"), "Cursed graveyard reports demon gate unlock")
	_assert_true(data.select_mission("demon_gate_assault"), "Unlocked demon gate mission can be selected")
	var gate_profile: Dictionary = data.get_selected_mission_combat_profile()
	_assert_eq(gate_profile["mission_id"], "demon_gate_assault", "Demon gate combat profile is selectable")
	_assert_true(float(gate_profile["enemy_damage_multiplier"]) > 1.5, "Demon gate is a late-game damage spike")
	var gate_summary: Dictionary = data.apply_mission_result("demon_gate_assault", "vitoria")
	_assert_true(data.guild["unlocked_zones"].has("demon_keep"), "Completing demon gate unlocks demon keep")
	_assert_true((gate_summary["unlocked_zone_names"] as Array).has("Fortaleza do Rei Demonio"), "Demon gate reports final fortress unlock")
	data.free()

func _test_demon_king_final_completion() -> void:
	var data: Node = GameDataScript.new()
	data.guild["unlocked_zones"] = ["initial_forest", "wolf_cave", "ancient_ruins", "poison_swamp", "cursed_graveyard", "demon_gate", "demon_keep"]
	var vanguard_summary: Dictionary = data.apply_mission_result("demon_king_vanguard", "vitoria")
	_assert_true(data.guild["unlocked_zones"].has("demon_throne"), "Vanguard unlocks demon throne")
	_assert_true((vanguard_summary["unlocked_zone_names"] as Array).has("Trono do Rei Demonio"), "Vanguard reports demon throne unlock")
	_assert_true(data.select_mission("demon_king_final"), "Final Demon King mission can be selected after unlock")
	var final_profile: Dictionary = data.get_selected_mission_combat_profile()
	_assert_eq(final_profile["objective_type"], "boss_kill", "Final mission uses boss-kill objective")
	_assert_eq(final_profile["target_bosses"], 1, "Final mission exposes Demon King boss target")
	var final_summary: Dictionary = data.apply_mission_result("demon_king_final", "vitoria")
	_assert_true(bool(data.guild["campaign_completed"]), "Completing final mission marks campaign complete")
	_assert_true(bool(final_summary["campaign_completed"]), "Final mission result reports campaign completion")
	_assert_true((final_summary["unlocked_achievements"] as Array).has("Juramento Cumprido"), "Final result reports campaign achievement")
	data.free()

func _test_persistent_companion_upgrade_choice() -> void:
	var data: Node = GameDataScript.new()
	data.get_companion_roster()
	var companion: Dictionary = data.companion_roster["c_warrior_001"]
	companion["pending_upgrades"] = 1
	data.companion_roster["c_warrior_001"] = companion
	var before_attack := float(data.companion_roster["c_warrior_001"]["attack"])
	var choices: Array = data.get_companion_upgrade_choices("c_warrior_001")
	_assert_true(choices.size() > 0, "Pending companion upgrade exposes choices")
	_assert_true(data.apply_companion_pending_upgrade("c_warrior_001", "damage"), "Pending companion upgrade can be applied")
	_assert_float_eq(float(data.companion_roster["c_warrior_001"]["attack"]), before_attack * 1.12, "Persistent companion damage upgrade changes roster stat")
	_assert_eq(data.companion_roster["c_warrior_001"]["pending_upgrades"], 0, "Applying persistent companion upgrade spends pending point")
	data.free()

func _test_flee_does_not_complete_mission() -> void:
	var data: Node = GameDataScript.new()
	data.recruitment["reroll_count"] = 1
	data.missions["initial_forest_survival"]["equipment_reward_chance"] = 1.0
	var summary: Dictionary = data.apply_mission_result("initial_forest_survival", "fuga")
	_assert_eq(summary["xp_per_companion"], 0, "Fleeing does not award completion XP")
	_assert_eq(data.companion_roster["c_warrior_001"]["level"], 1, "Fleeing does not level companions through mission reward")
	_assert_true(not data.guild["unlocked_zones"].has("wolf_cave"), "Fleeing does not unlock the next zone")
	_assert_eq(data.get_equipment_inventory().size(), 0, "Fleeing does not award mission equipment")
	_assert_eq(data.recruitment["reroll_count"], 0, "Mission return through flee resets reroll cost")
	data.free()

func _test_enemy_spawner_accepts_mission_profile() -> void:
	var spawner: Node = EnemySpawnerScript.new()
	spawner.configure_mission({"wave_offset": 3, "spawn_amount_bonus": 2})
	_assert_eq(spawner.mission_profile["wave_offset"], 3, "Enemy spawner stores mission wave offset")
	_assert_eq(spawner.mission_profile["spawn_amount_bonus"], 2, "Enemy spawner stores mission spawn bonus")
	spawner.free()

func _test_companion_run_results_update_roster() -> void:
	var data: Node = GameDataScript.new()
	var summary: Dictionary = data.apply_companion_run_results([
		{
			"id": "c_warrior_001",
			"level": 3,
			"xp": 4,
			"xp_required": 18,
			"max_health": 48.0,
			"current_health": 0.0,
			"attack": 7.5,
			"defense": 5.0,
			"move_speed": 220.0,
			"speed_rating": 6.5,
			"range": 170.0,
			"cooldown": 1.1,
			"ability_power": 1.25,
			"state": "ferido"
		}
	])
	var companion: Dictionary = data.companion_roster["c_warrior_001"]
	_assert_eq(companion["level"], 3, "Run result persists companion level")
	_assert_eq(companion["xp"], 4, "Run result persists companion XP remainder")
	_assert_float_eq(companion["attack"], 7.5, "Run result persists chosen attribute upgrades")
	_assert_eq(companion["state"], "ferido", "Fallen companion returns as wounded")
	_assert_float_eq(companion["current_health"], 16.8, "Wounded companion returns with partial health")
	_assert_true(summary["wounded_companions"].has("Bruna"), "Run result reports wounded companions")
	data.free()

func _test_wounded_companion_starts_next_mission_injured() -> void:
	var data: Node = GameDataScript.new()
	var roster: Dictionary = data.get_companion_roster()
	roster["c_warrior_001"]["state"] = "ferido"
	roster["c_warrior_001"]["max_health"] = 40.0
	roster["c_warrior_001"]["current_health"] = 14.0
	var definitions: Array = data.get_active_companion_defs()
	var warrior: Dictionary = definitions[0]
	_assert_float_eq(float(warrior["health"]), float(warrior["max_health"]) * 0.35, "Wounded companion begins combat at persistent health ratio")
	var companion: Node = CompanionScript.new()
	companion.setup(warrior, null, Vector2.ZERO)
	_assert_true(companion.health < companion.max_health, "Runtime companion keeps wounded starting health")
	companion.free()
	data.free()

func _test_infirmary_treats_wounded_companion() -> void:
	var data: Node = GameDataScript.new()
	data.coins = 1000
	data.apply_companion_run_results([{"id": "c_warrior_001", "max_health": 40.0, "state": "ferido"}])
	_assert_true(not data.treat_companion("c_warrior_001"), "Treatment is locked before infirmary unlock")
	_assert_true(data.buy_permanent_upgrade("guild_hall"), "Guild hall upgrade unlocks infirmary")
	_assert_true((data.guild["unlocked_structures"] as Array).has("warehouse"), "Guild hall upgrade unlocks warehouse")
	var cost: int = data.get_treatment_cost("c_warrior_001")
	_assert_true(data.treat_companion("c_warrior_001"), "Infirmary treats wounded companion")
	var companion: Dictionary = data.get_companion_roster()["c_warrior_001"]
	_assert_eq(data.coins, 1000 - 220 - cost, "Treatment spends coins")
	_assert_eq(companion["state"], "disponivel", "Treatment restores available state")
	_assert_float_eq(float(companion["current_health"]), float(companion["max_health"]), "Treatment restores full persistent health")
	data.free()

func _test_dead_companion_resurrection_flow() -> void:
	var data: Node = GameDataScript.new()
	data.coins = 1000
	var summary: Dictionary = data.apply_companion_run_results([
		{
			"id": "c_warrior_001",
			"level": 3,
			"xp": 8,
			"xp_required": 18,
			"max_health": 48.0,
			"current_health": 0.0,
			"attack": 7.5,
			"defense": 5.0,
			"move_speed": 220.0,
			"speed_rating": 6.5,
			"range": 170.0,
			"cooldown": 1.1,
			"ability_power": 1.25,
			"state": "morto"
		}
	])
	_assert_eq(data.companion_roster["c_warrior_001"]["state"], "morto", "Dead run result persists in roster")
	_assert_true(summary["dead_companions"].has("Bruna"), "Run result reports dead companions")
	_assert_true(not data.get_active_squad().has("c_warrior_001"), "Dead companion is removed from active squad")
	_assert_eq(data.get_dead_companions().size(), 1, "Dead companion appears in graveyard list")
	var cost: int = data.get_resurrection_cost("c_warrior_001")
	_assert_true(data.resurrect_companion("c_warrior_001"), "Dead companion can be resurrected when coins are available")
	_assert_eq(data.coins, 1000 - cost, "Resurrection spends coins")
	_assert_eq(data.companion_roster["c_warrior_001"]["state"], "ferido", "Resurrected companion returns wounded")
	_assert_eq(data.companion_roster["c_warrior_001"]["xp"], 6, "Resurrection applies XP penalty")
	data.free()

func _test_blacksmith_equipment_flow() -> void:
	var data: Node = GameDataScript.new()
	data.add_coins(500)
	var roster: Dictionary = data.get_companion_roster()
	var base_attack := float(roster["c_warrior_001"]["attack"])
	var crafted: bool = data.craft_equipment("iron_blade")
	_assert_true(crafted, "Blacksmith can craft equipment when coins are available")
	_assert_eq(data.coins, 360, "Crafting equipment spends coins")
	var inventory: Array = data.get_equipment_inventory()
	_assert_eq(inventory.size(), 1, "Crafting adds one inventory item")
	data.equipment_inventory[0]["rarity"] = "comum"
	data.equipment_inventory[0]["level"] = 1
	var item_uid := str(inventory[0]["uid"])
	var equipped: bool = data.equip_companion_item("c_warrior_001", item_uid)
	_assert_true(equipped, "Equipment can be equipped on a companion")
	roster = data.get_companion_roster()
	_assert_true((roster["c_warrior_001"]["equipment"] as Array).has(item_uid), "Equipped item is tracked on companion")
	_assert_float_eq(float(roster["c_warrior_001"]["attack"]), base_attack + 1.3, "Equipment bonus changes companion stats")
	var upgrade_cost: int = data.get_equipment_upgrade_cost(item_uid)
	var upgraded: bool = data.upgrade_equipment(item_uid)
	_assert_true(upgraded, "Equipped equipment can be upgraded")
	_assert_eq(data.coins, 360 - upgrade_cost, "Upgrading equipment spends coins")
	_assert_eq(data.equipment_inventory[0]["level"], 2, "Equipment level increases")
	roster = data.get_companion_roster()
	_assert_float_eq(float(roster["c_warrior_001"]["attack"]), base_attack + 1.625, "Upgraded equipment reapplies scaled bonus")
	data.equipment_inventory[0]["rarity"] = "comum"
	var reforge_cost: int = data.get_equipment_reforge_cost(item_uid)
	data.coins = reforge_cost
	seed(1)
	var reforged: bool = data.reforge_equipment(item_uid)
	_assert_true(reforged, "Equipped equipment can be reforged")
	_assert_eq(data.coins, 0, "Reforging equipment spends coins")
	_assert_eq(data.equipment_inventory[0]["level"], 2, "Reforging preserves equipment level")
	roster = data.get_companion_roster()
	_assert_true(float(roster["c_warrior_001"]["attack"]) >= base_attack + 1.625, "Reforging reapplies equipment bonus cleanly")
	var unequipped: bool = data.unequip_companion_item(item_uid)
	_assert_true(unequipped, "Equipment can be unequipped")
	roster = data.get_companion_roster()
	_assert_true(not (roster["c_warrior_001"]["equipment"] as Array).has(item_uid), "Unequipped item is removed from companion")
	_assert_float_eq(float(roster["c_warrior_001"]["attack"]), base_attack, "Unequipping removes equipment bonus")
	data.free()

func _test_heavy_equipment_speed_penalty() -> void:
	var data: Node = GameDataScript.new()
	data.add_coins(500)
	_assert_true(not data.craft_equipment("tower_shield"), "Heavy equipment requires regional material")
	data.materials = {"cursed_bone": 1}
	var crafted: bool = data.craft_equipment("tower_shield")
	_assert_true(crafted, "Heavy equipment can be crafted")
	_assert_eq(data.get_materials()["cursed_bone"], 0, "Crafting heavy equipment consumes required material")
	var item_uid: String = str(data.get_equipment_inventory()[0]["uid"])
	var roster: Dictionary = data.get_companion_roster()
	var base_speed := float(roster["c_warrior_001"]["speed_rating"])
	var base_move_speed := float(roster["c_warrior_001"]["move_speed"])
	_assert_true(data.equip_companion_item("c_warrior_001", item_uid), "Heavy equipment can be equipped")
	roster = data.get_companion_roster()
	_assert_true(float(roster["c_warrior_001"]["speed_rating"]) < base_speed, "Heavy equipment lowers companion speed rating")
	_assert_true(float(roster["c_warrior_001"]["move_speed"]) < base_move_speed, "Heavy equipment lowers companion movement speed")
	_assert_true(data.unequip_companion_item(item_uid), "Heavy equipment can be unequipped")
	roster = data.get_companion_roster()
	_assert_float_eq(float(roster["c_warrior_001"]["speed_rating"]), base_speed, "Unequipping heavy equipment restores speed rating")
	_assert_float_eq(float(roster["c_warrior_001"]["move_speed"]), base_move_speed, "Unequipping heavy equipment restores movement speed")
	data.free()

func _test_random_equipment_award() -> void:
	var data: Node = GameDataScript.new()
	var item_name: String = data.award_random_equipment(4)
	_assert_true(not item_name.is_empty(), "Random equipment award returns display name")
	_assert_eq(data.get_equipment_inventory().size(), 1, "Random equipment award adds inventory item")
	var item: Dictionary = data.get_equipment_inventory()[0]
	_assert_true(item.has("rarity"), "Random equipment award stores rarity")
	_assert_true(item.has("level"), "Random equipment award stores level")
	data.free()

func _test_recruitment_hire_adds_companion() -> void:
	var data: Node = GameDataScript.new()
	data.coins = 1000
	data.recruitment = {
		"available": [{
			"name": "Nia",
			"class": "mage",
			"class_name": "Mago",
			"rarity": "raro",
			"level": 2,
			"cost": 360,
			"traits": ["focada"],
			"ability": "Bola de Fogo",
			"speed_rating": 5.0
		}],
		"reroll_count": 0
	}
	var before_count: int = data.get_companion_roster().size()
	var hired: bool = data.hire_recruit(0)
	_assert_true(hired, "Recruitment hire succeeds when coins and capacity allow")
	_assert_eq(data.get_companion_roster().size(), before_count + 1, "Hiring adds companion to roster")
	_assert_eq(data.coins, 640, "Hiring spends candidate cost")
	var hired_companion := {}
	for companion in data.get_companion_roster().values():
		if str(companion.get("name", "")) == "Nia":
			hired_companion = companion
			break
	_assert_float_eq(float(hired_companion["ability_power"]), 0.95, "Recruit trait applies a persistent attribute bonus")
	_assert_true(data.get_trait_effect_text("focada").contains("+20%"), "Recruit trait exposes its effect for UI comparison")
	_assert_eq(data.get_recruitment_queue().size(), 3, "Hiring refills recruitment queue")
	data.free()

func _test_recruitment_reroll_spends_coins_and_scales_cost() -> void:
	var data: Node = GameDataScript.new()
	data.coins = 500
	var first_cost: int = data.get_reroll_cost()
	var rerolled: bool = data.reroll_recruits()
	_assert_true(rerolled, "Recruitment reroll succeeds when coins are available")
	_assert_eq(data.coins, 400, "Recruitment reroll spends first cost")
	_assert_true(data.get_reroll_cost() > first_cost, "Recruitment reroll cost increases")
	_assert_eq(data.get_recruitment_queue().size(), 3, "Recruitment reroll creates three candidates")
	data.free()

func _test_scene_pool_acquire_and_recycle_signal() -> void:
	var parent := Node.new()
	var scene := PackedScene.new()
	var source := PoolItemScript.new()
	var recycled_count := [0]
	var pack_result := scene.pack(source)
	var pool := ScenePoolScript.new()
	_assert_eq(pack_result, OK, "Pool test scene packs successfully")
	pool.build(parent, scene, 2, func(_item: Node): recycled_count[0] += 1)
	_assert_eq(pool.items.size(), 2, "Scene pool builds requested number of items")
	var first: Node = pool.acquire()
	_assert_true(first != null, "Scene pool acquires inactive item")
	first.set("active", true)
	var second: Node = pool.acquire()
	_assert_true(second != null and second != first, "Scene pool skips active items")
	second.set("active", true)
	_assert_eq(pool.acquire(), null, "Scene pool returns null when all items are active")
	first.emit_signal("recycled", first)
	_assert_eq(recycled_count[0], 1, "Scene pool wires recycled callback")
	parent.free()
	source.free()
