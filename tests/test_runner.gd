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
	_test_guild_upgrade_cost_formula()
	_test_guild_upgrade_effects()
	_test_default_guild_squad_summary()
	_test_squad_can_be_emptied()
	_test_flee_coin_retention_uses_squad_speed()
	_test_mission_readiness_uses_squad_and_unlocks()
	_test_selected_mission_combat_profile()
	_test_mission_victory_rewards_progression()
	_test_flee_does_not_complete_mission()
	_test_enemy_spawner_accepts_mission_profile()
	_test_companion_run_results_update_roster()
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
	companion.xp_required = 5
	companion.add_xp(5)
	_assert_eq(companion.level, 2, "Companion levels up after receiving enough XP")
	companion.apply_upgrade("damage")
	companion.apply_upgrade("cooldown")
	companion.apply_upgrade("health")
	companion.apply_upgrade("range")
	companion.apply_upgrade("ability")
	_assert_float_eq(companion.attack_damage, 11.2, "Companion damage upgrade applies")
	_assert_float_eq(companion.attack_cooldown, 1.86, "Companion cooldown upgrade applies")
	_assert_float_eq(companion.max_health, 28.0, "Companion health upgrade applies")
	_assert_float_eq(companion.attack_range, 118.0, "Companion range upgrade applies")
	_assert_float_eq(companion.ability_power, 1.15, "Companion ability upgrade applies")
	companion.take_damage(40.0)
	_assert_eq(companion.health, 0.0, "Companion can fall after taking lethal damage")
	_assert_true(companion.is_down, "Companion dies permanently after falling")
	_assert_true(not companion.is_damage_target(), "Dead companion is no longer a damage target")
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
	_assert_true(float(cave["enemy_speed_multiplier"]) > 1.0, "Wolf cave combat profile makes enemies faster")
	_assert_true(float(cave["coin_multiplier"]) > 1.0, "Harder mission improves coin drops")
	data.free()

func _test_mission_victory_rewards_progression() -> void:
	var data: Node = GameDataScript.new()
	data.recruitment["reroll_count"] = 2
	var summary: Dictionary = data.apply_mission_result("initial_forest_survival", "vitoria")
	_assert_eq(summary["xp_per_companion"], 10, "Mission XP reward is split across active companions")
	_assert_eq(data.companion_roster["c_warrior_001"]["level"], 2, "Mission XP can level active companions")
	_assert_true(summary["leveled_companions"].has("Bruna"), "Mission result reports companions that leveled")
	_assert_true(data.guild["unlocked_zones"].has("wolf_cave"), "Completing initial mission unlocks wolf cave")
	_assert_true(summary["unlocked_zone_names"].has("Caverna dos Lobos"), "Mission result reports unlocked zone name")
	_assert_eq(data.recruitment["reroll_count"], 0, "Mission return resets recruitment reroll cost")
	data.free()

func _test_flee_does_not_complete_mission() -> void:
	var data: Node = GameDataScript.new()
	data.recruitment["reroll_count"] = 1
	var summary: Dictionary = data.apply_mission_result("initial_forest_survival", "fuga")
	_assert_eq(summary["xp_per_companion"], 0, "Fleeing does not award completion XP")
	_assert_eq(data.companion_roster["c_warrior_001"]["level"], 1, "Fleeing does not level companions through mission reward")
	_assert_true(not data.guild["unlocked_zones"].has("wolf_cave"), "Fleeing does not unlock the next zone")
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
	data.apply_companion_run_results([
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
