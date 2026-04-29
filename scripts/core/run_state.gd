extends Node
class_name RunState

signal xp_changed(current: int, required: int)
signal level_changed(level: int)
signal coins_changed(coins: int)
signal weapon_changed(summary: Array)
signal player_died

const MAX_WEAPONS := 6
const MAX_PASSIVES := 6

var level := 1
var xp := 0
var xp_required := 8
var coins := 0
var damage_multiplier := 1.0
var speed_bonus := 0.0
var pickup_bonus := 0.0
var max_health_bonus := 0.0
var damage_reduction := 0.0
var regen_per_second := 0.0
var weapon_levels := {}
var passive_levels := {}

func add_xp(amount: int) -> bool:
	xp += amount
	var leveled := false
	while xp >= xp_required:
		xp -= xp_required
		level += 1
		xp_required = int(xp_required * 1.24 + 5)
		level_changed.emit(level)
		leveled = true
	xp_changed.emit(xp, xp_required)
	return leveled

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func can_add_weapon(id: String) -> bool:
	return weapon_levels.has(id) or weapon_levels.size() < MAX_WEAPONS

func can_add_passive(id: String) -> bool:
	return passive_levels.has(id) or passive_levels.size() < MAX_PASSIVES

func add_weapon_level(id: String) -> void:
	weapon_levels[id] = int(weapon_levels.get(id, 0)) + 1
	weapon_changed.emit(get_weapon_summary())

func add_passive_level(id: String) -> void:
	passive_levels[id] = int(passive_levels.get(id, 0)) + 1
	match id:
		"might":
			damage_multiplier += 0.08
		"haste":
			speed_bonus += 14.0
		"magnet":
			pickup_bonus += 18.0
		"vitality":
			max_health_bonus += 18.0
		"guard":
			damage_reduction = min(0.55, damage_reduction + 0.08)
		"renewal":
			regen_per_second += 0.7

func get_weapon_summary() -> Array:
	var result := []
	for id in weapon_levels.keys():
		result.append({"id": id, "level": weapon_levels[id]})
	return result
