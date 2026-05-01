extends SceneTree

const RunStateScript := preload("res://scripts/core/run_state.gd")
const UpgradeManagerScript := preload("res://scripts/game/upgrade_manager.gd")
const GameDataScript := preload("res://scripts/core/game_data.gd")
const CompanionScript := preload("res://scripts/game/companion.gd")
const CompanionManagerScript := preload("res://scripts/game/companion_manager.gd")
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
	_test_permanent_upgrade_cost_formula()
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

func _test_permanent_upgrade_cost_formula() -> void:
	var data: Node = GameDataScript.new()
	data.permanent_upgrades["damage"] = 0
	_assert_eq(data.get_upgrade_cost("damage"), 150, "Permanent upgrade base cost is used at level zero")
	data.permanent_upgrades["damage"] = 3
	_assert_eq(data.get_upgrade_cost("damage"), 480, "Permanent upgrade cost scales by step per level")
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
