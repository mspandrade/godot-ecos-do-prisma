extends Node
class_name UpgradeManager

signal choices_ready(choices: Array)
signal upgrade_applied(upgrade: Dictionary)

const GameBalanceScript := preload("res://scripts/game/game_balance.gd")

var run_state: RunState
var weapon_system: Node
var upgrades := GameBalanceScript.get_upgrade_defs()
var evolutions := GameBalanceScript.get_weapon_evolutions()

func setup(state: RunState, weapons: Node) -> void:
	run_state = state
	weapon_system = weapons

func request_choices() -> void:
	var pool := []
	for up in upgrades:
		if _can_offer(up):
			pool.append(up)
	pool.shuffle()
	choices_ready.emit(pool.slice(0, min(3, pool.size())))

func apply_upgrade(upgrade: Dictionary) -> void:
	match str(upgrade["kind"]):
		"weapon":
			run_state.add_weapon_level(str(upgrade["id"]))
		"passive":
			run_state.add_passive_level(str(upgrade["id"]))
	_check_evolutions()
	upgrade_applied.emit(upgrade)

func _can_offer(upgrade: Dictionary) -> bool:
	var id := str(upgrade["id"])
	if upgrade["kind"] == "weapon":
		return run_state.can_add_weapon(id) and int(run_state.weapon_levels.get(id, 0)) < 8
	return run_state.can_add_passive(id) and int(run_state.passive_levels.get(id, 0)) < 5

func _check_evolutions() -> void:
	for weapon_id in evolutions.keys():
		if not run_state.weapon_levels.has(weapon_id):
			continue
		var evo: Dictionary = evolutions[weapon_id]
		if int(run_state.weapon_levels[weapon_id]) < int(evo["level"]):
			continue
		if not run_state.passive_levels.has(str(evo["passive"])):
			continue
		run_state.weapon_levels[weapon_id] = 10
