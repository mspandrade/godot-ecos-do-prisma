extends SceneTree

const RunStateScript := preload("res://scripts/core/run_state.gd")
const UpgradeManagerScript := preload("res://scripts/game/upgrade_manager.gd")
const GameDataScript := preload("res://scripts/core/game_data.gd")
const CompanionScript := preload("res://scripts/game/companion.gd")

var failures := 0
var total := 0

func _init() -> void:
	print("Running unit tests...")
	_test_run_state_leveling()
	_test_weapon_and_passive_limits()
	_test_survival_passives()
	_test_companion_level_and_upgrades()
	_test_upgrade_choices_respect_limits()
	_test_weapon_evolution()
	_test_permanent_upgrade_cost_formula()
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

func _test_permanent_upgrade_cost_formula() -> void:
	var data: Node = GameDataScript.new()
	data.permanent_upgrades["damage"] = 0
	_assert_eq(data.get_upgrade_cost("damage"), 150, "Permanent upgrade base cost is used at level zero")
	data.permanent_upgrades["damage"] = 3
	_assert_eq(data.get_upgrade_cost("damage"), 480, "Permanent upgrade cost scales by step per level")
	data.free()
