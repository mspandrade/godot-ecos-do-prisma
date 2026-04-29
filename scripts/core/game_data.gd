extends Node

signal coins_changed(total: int)
signal character_changed(character_id: String)
signal permanent_upgrade_changed(upgrade_id: String, level: int)

const SAVE_PATH := "user://save_data.cfg"

var coins := 0
var selected_character := "runner"
var unlocked_characters := {"runner": true}
var permanent_upgrades := {
	"max_health": 0,
	"damage": 0,
	"move_speed": 0,
	"pickup_range": 0
}

var characters := {
	"runner": {
		"name": "Andarilha",
		"cost": 0,
		"max_health": 100.0,
		"speed": 240.0,
		"damage": 0.78,
		"pickup_range": 120.0
	},
	"warden": {
		"name": "Sentinela",
		"cost": 600,
		"max_health": 135.0,
		"speed": 210.0,
		"damage": 0.86,
		"pickup_range": 120.0
	},
	"spark": {
		"name": "Faisca",
		"cost": 900,
		"max_health": 85.0,
		"speed": 285.0,
		"damage": 0.92,
		"pickup_range": 150.0
	}
}

var upgrade_defs := {
	"max_health": {"name": "Vitalidade", "base_cost": 120, "step": 80, "max": 10, "value": 8.0},
	"damage": {"name": "Forca", "base_cost": 150, "step": 110, "max": 10, "value": 0.035},
	"move_speed": {"name": "Passos Leves", "base_cost": 130, "step": 95, "max": 8, "value": 8.0},
	"pickup_range": {"name": "Magnetismo", "base_cost": 100, "step": 75, "max": 8, "value": 12.0}
}

func _ready() -> void:
	load_data()

func add_coins(amount: int) -> void:
	coins = max(0, coins + amount)
	coins_changed.emit(coins)
	save_data()

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	save_data()
	return true

func get_upgrade_cost(upgrade_id: String) -> int:
	var def: Dictionary = upgrade_defs[upgrade_id]
	return int(def["base_cost"] + def["step"] * permanent_upgrades.get(upgrade_id, 0))

func buy_permanent_upgrade(upgrade_id: String) -> bool:
	var def: Dictionary = upgrade_defs[upgrade_id]
	var current := int(permanent_upgrades.get(upgrade_id, 0))
	if current >= int(def["max"]):
		return false
	var cost := get_upgrade_cost(upgrade_id)
	if not spend_coins(cost):
		return false
	permanent_upgrades[upgrade_id] = current + 1
	permanent_upgrade_changed.emit(upgrade_id, current + 1)
	save_data()
	return true

func unlock_character(character_id: String) -> bool:
	if unlocked_characters.get(character_id, false):
		selected_character = character_id
		character_changed.emit(selected_character)
		save_data()
		return true
	var cost := int(characters[character_id]["cost"])
	if not spend_coins(cost):
		return false
	unlocked_characters[character_id] = true
	selected_character = character_id
	character_changed.emit(selected_character)
	save_data()
	return true

func get_selected_stats() -> Dictionary:
	var stats: Dictionary = characters[selected_character].duplicate(true)
	stats["max_health"] += permanent_upgrades["max_health"] * upgrade_defs["max_health"]["value"]
	stats["damage"] += permanent_upgrades["damage"] * upgrade_defs["damage"]["value"]
	stats["speed"] += permanent_upgrades["move_speed"] * upgrade_defs["move_speed"]["value"]
	stats["pickup_range"] += permanent_upgrades["pickup_range"] * upgrade_defs["pickup_range"]["value"]
	return stats

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "coins", coins)
	cfg.set_value("save", "selected_character", selected_character)
	cfg.set_value("save", "unlocked_characters", unlocked_characters)
	cfg.set_value("save", "permanent_upgrades", permanent_upgrades)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	coins = int(cfg.get_value("save", "coins", coins))
	selected_character = str(cfg.get_value("save", "selected_character", selected_character))
	unlocked_characters = cfg.get_value("save", "unlocked_characters", unlocked_characters)
	permanent_upgrades = cfg.get_value("save", "permanent_upgrades", permanent_upgrades)
