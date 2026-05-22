extends Node

signal coins_changed(total: int)
signal character_changed(character_id: String)
signal permanent_upgrade_changed(upgrade_id: String, level: int)
signal guild_changed
signal companion_roster_changed
signal squad_changed(summary: Dictionary)
signal recruitment_changed

const SAVE_PATH := "user://save_data.cfg"
const GameBalanceScript := preload("res://scripts/game/game_balance.gd")
const MAX_SQUAD_SIZE := 6
const RECRUITMENT_QUEUE_SIZE := 3
const REROLL_COSTS := [100, 150, 250, 400]

var coins := 0
var selected_character := "runner"
var unlocked_characters := {"runner": true}
var guild := {
	"name": "Guilda Falida",
	"level": 1,
	"reputation": 0,
	"companion_capacity": 12,
	"unlocked_structures": ["hall", "recruitment", "mission_board"],
	"unlocked_zones": ["initial_forest"]
}
var companion_roster := {}
var active_squad := []
var recruitment := {}
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
	_ensure_guild_defaults()

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

func get_companion_roster() -> Dictionary:
	_ensure_guild_defaults()
	return companion_roster

func get_active_squad() -> Array:
	_ensure_guild_defaults()
	return active_squad

func is_companion_in_squad(companion_id: String) -> bool:
	_ensure_guild_defaults()
	return active_squad.has(companion_id)

func toggle_companion_in_squad(companion_id: String) -> bool:
	_ensure_guild_defaults()
	if not companion_roster.has(companion_id):
		return false
	if active_squad.has(companion_id):
		active_squad.erase(companion_id)
	else:
		if active_squad.size() >= MAX_SQUAD_SIZE:
			return false
		var data: Dictionary = companion_roster[companion_id]
		if str(data.get("state", "disponivel")) in ["morto", "treinando"]:
			return false
		active_squad.append(companion_id)
	save_data()
	squad_changed.emit(get_squad_summary())
	return true

func get_active_companion_defs() -> Array:
	_ensure_guild_defaults()
	var result := []
	for companion_id in active_squad:
		if not companion_roster.has(companion_id):
			continue
		var data: Dictionary = companion_roster[companion_id]
		if str(data.get("state", "disponivel")) == "morto":
			continue
		result.append(_build_combat_companion_def(companion_id, data))
	return result

func apply_companion_run_results(results: Array) -> void:
	_ensure_guild_defaults()
	var changed := false
	for result_value in results:
		var result: Dictionary = result_value
		var companion_id := str(result.get("id", ""))
		if companion_id.is_empty() or not companion_roster.has(companion_id):
			continue
		var data: Dictionary = companion_roster[companion_id]
		data["level"] = max(int(data.get("level", 1)), int(result.get("level", data.get("level", 1))))
		data["xp"] = max(0, int(result.get("xp", data.get("xp", 0))))
		data["xp_required"] = max(1, int(result.get("xp_required", data.get("xp_required", 10))))
		data["max_health"] = maxf(1.0, float(result.get("max_health", data.get("max_health", 1.0))))
		data["current_health"] = _normalized_return_health(result, data)
		data["attack"] = maxf(0.0, float(result.get("attack", data.get("attack", 0.0))))
		data["defense"] = maxf(0.0, float(result.get("defense", data.get("defense", 0.0))))
		data["move_speed"] = maxf(1.0, float(result.get("move_speed", data.get("move_speed", 1.0))))
		data["speed_rating"] = maxf(0.0, float(result.get("speed_rating", data.get("speed_rating", 0.0))))
		data["range"] = maxf(0.0, float(result.get("range", data.get("range", 0.0))))
		data["cooldown"] = maxf(0.1, float(result.get("cooldown", data.get("cooldown", 1.0))))
		data["ability_power"] = maxf(0.0, float(result.get("ability_power", data.get("ability_power", 1.0))))
		data["state"] = _normalized_return_state(str(result.get("state", data.get("state", "disponivel"))))
		companion_roster[companion_id] = data
		changed = true
	if changed:
		save_data()
		companion_roster_changed.emit()
		squad_changed.emit(get_squad_summary())

func get_recruitment_queue() -> Array:
	_ensure_guild_defaults()
	return recruitment.get("available", [])

func get_reroll_cost() -> int:
	_ensure_guild_defaults()
	var reroll_count := int(recruitment.get("reroll_count", 0))
	return REROLL_COSTS[min(reroll_count, REROLL_COSTS.size() - 1)]

func reroll_recruits() -> bool:
	_ensure_guild_defaults()
	var cost := get_reroll_cost()
	if not spend_coins(cost):
		return false
	recruitment["reroll_count"] = int(recruitment.get("reroll_count", 0)) + 1
	recruitment["available"] = _generate_recruitment_queue()
	save_data()
	recruitment_changed.emit()
	return true

func hire_recruit(index: int) -> bool:
	_ensure_guild_defaults()
	var available: Array = recruitment.get("available", [])
	if index < 0 or index >= available.size():
		return false
	if companion_roster.size() >= int(guild.get("companion_capacity", 12)):
		return false
	var candidate: Dictionary = available[index]
	var cost := int(candidate.get("cost", 0))
	if not spend_coins(cost):
		return false
	var traits: Array = candidate.get("traits", [])
	var companion_id := _next_companion_id()
	var data := _make_companion_data(
		companion_id,
		str(candidate.get("name", "Recruta")),
		str(candidate.get("class", "shield")),
		str(candidate.get("rarity", "comum")),
		traits
	)
	data["level"] = int(candidate.get("level", 1))
	data["xp_required"] = int(10 + (int(data["level"]) - 1) * 6)
	companion_roster[companion_id] = data
	available.remove_at(index)
	while available.size() < RECRUITMENT_QUEUE_SIZE:
		available.append(_generate_recruit_candidate())
	recruitment["available"] = available
	save_data()
	companion_roster_changed.emit()
	recruitment_changed.emit()
	return true

func get_squad_summary() -> Dictionary:
	_ensure_guild_defaults()
	var total_level := 0.0
	var total_speed := 0.0
	var count := 0
	for companion_id in active_squad:
		if not companion_roster.has(companion_id):
			continue
		var data: Dictionary = companion_roster[companion_id]
		total_level += float(data.get("level", 1))
		total_speed += float(data.get("speed_rating", 0.0))
		count += 1
	var average_level := total_level / count if count > 0 else 0.0
	var average_speed := total_speed / count if count > 0 else 0.0
	return {
		"size": count,
		"max_size": MAX_SQUAD_SIZE,
		"average_level": average_level,
		"average_speed": average_speed,
		"speed_label": classify_squad_speed(average_speed),
		"mobility_warning": get_mobility_warning(average_speed)
	}

func classify_squad_speed(average_speed: float) -> String:
	if average_speed < 4.0:
		return "Muito lento"
	if average_speed < 6.0:
		return "Lento"
	if average_speed < 7.5:
		return "Equilibrado"
	if average_speed < 9.0:
		return "Rapido"
	return "Muito rapido"

func get_mobility_warning(average_speed: float) -> String:
	if average_speed < 4.0:
		return "Fuga arriscada contra hordas rapidas."
	if average_speed < 6.0:
		return "Pode ter dificuldade para fugir."
	return "Mobilidade adequada para missoes iniciais."

func get_flee_coin_retention() -> float:
	var average_speed := float(get_squad_summary()["average_speed"])
	if average_speed < 4.0:
		return 0.45
	if average_speed < 6.0:
		return 0.6
	if average_speed < 7.5:
		return 0.75
	if average_speed < 9.0:
		return 0.9
	return 1.0

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
	cfg.set_value("guild", "data", guild)
	cfg.set_value("guild", "companion_roster", companion_roster)
	cfg.set_value("guild", "active_squad", active_squad)
	cfg.set_value("guild", "recruitment", recruitment)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	coins = int(cfg.get_value("save", "coins", coins))
	selected_character = str(cfg.get_value("save", "selected_character", selected_character))
	unlocked_characters = cfg.get_value("save", "unlocked_characters", unlocked_characters)
	permanent_upgrades = cfg.get_value("save", "permanent_upgrades", permanent_upgrades)
	guild = cfg.get_value("guild", "data", guild)
	companion_roster = cfg.get_value("guild", "companion_roster", companion_roster)
	active_squad = cfg.get_value("guild", "active_squad", active_squad)
	recruitment = cfg.get_value("guild", "recruitment", recruitment)
	_ensure_guild_defaults()

func _ensure_guild_defaults() -> void:
	if guild.is_empty():
		guild = {
			"name": "Guilda Falida",
			"level": 1,
			"reputation": 0,
			"companion_capacity": 12,
			"unlocked_structures": ["hall", "recruitment", "mission_board"],
			"unlocked_zones": ["initial_forest"]
		}
	for key in ["name", "level", "reputation", "companion_capacity", "unlocked_structures", "unlocked_zones"]:
		if not guild.has(key):
			guild[key] = _default_guild_value(key)
	if companion_roster.is_empty():
		companion_roster = _default_companion_roster()
		if active_squad.is_empty():
			active_squad = ["c_warrior_001", "c_archer_001", "c_cleric_001"]
	active_squad = active_squad.filter(func(companion_id): return companion_roster.has(str(companion_id)))
	if recruitment.is_empty():
		recruitment = {"available": _generate_recruitment_queue(), "reroll_count": 0}
	if not recruitment.has("available") or recruitment.get("available", []).is_empty():
		recruitment["available"] = _generate_recruitment_queue()
	if not recruitment.has("reroll_count"):
		recruitment["reroll_count"] = 0

func _default_guild_value(key: String) -> Variant:
	match key:
		"name":
			return "Guilda Falida"
		"level":
			return 1
		"reputation":
			return 0
		"companion_capacity":
			return 12
		"unlocked_structures":
			return ["hall", "recruitment", "mission_board"]
		"unlocked_zones":
			return ["initial_forest"]
	return null

func _default_companion_roster() -> Dictionary:
	return {
		"c_warrior_001": _make_companion_data("c_warrior_001", "Bruna", "shield", "comum", ["leal"]),
		"c_archer_001": _make_companion_data("c_archer_001", "Theo", "archer", "comum", ["observador"]),
		"c_cleric_001": _make_companion_data("c_cleric_001", "Lina", "cleric", "incomum", ["cuidadosa"]),
		"c_tank_001": _make_companion_data("c_tank_001", "Otto", "tank", "comum", ["teimoso"]),
		"c_mage_001": _make_companion_data("c_mage_001", "Mira", "mage", "incomum", ["curiosa"]),
		"c_assassin_001": _make_companion_data("c_assassin_001", "Kael", "assassin", "raro", ["impulsivo"])
	}

func _make_companion_data(companion_id: String, companion_name: String, class_type: String, rarity: String, traits: Array) -> Dictionary:
	var base := GameBalanceScript.get_companion_def_by_class(class_type)
	return {
		"id": companion_id,
		"name": companion_name,
		"class": class_type,
		"class_name": base.get("name", class_type),
		"rarity": rarity,
		"level": 1,
		"xp": 0,
		"xp_required": 10,
		"max_health": float(base.get("health", 20.0)),
		"current_health": float(base.get("health", 20.0)),
		"attack": float(base.get("damage", 4.0)),
		"defense": float(base.get("defense", 0.0)),
		"speed_rating": float(base.get("speed_rating", 5.0)),
		"move_speed": float(base.get("speed", 210.0)),
		"range": float(base.get("range", 200.0)),
		"cooldown": float(base.get("cooldown", 1.0)),
		"ability_power": float(base.get("ability_power", 1.0)),
		"crit": float(base.get("crit", 0.05)),
		"luck": float(base.get("luck", 0.05)),
		"ability": str(base.get("ability", "")),
		"passive": str(base.get("passive", "")),
		"traits": traits,
		"equipment": [],
		"state": "disponivel"
	}

func _build_combat_companion_def(companion_id: String, companion_data: Dictionary) -> Dictionary:
	var class_type := str(companion_data.get("class", "shield"))
	var base := GameBalanceScript.get_companion_def_by_class(class_type)
	var level := int(companion_data.get("level", 1))
	var rarity_multiplier := _rarity_multiplier(str(companion_data.get("rarity", "comum")))
	var result := base.duplicate(true)
	result["id"] = companion_id
	result["name"] = str(companion_data.get("name", base.get("name", companion_id)))
	result["rarity"] = str(companion_data.get("rarity", base.get("rarity", "comum")))
	result["level"] = level
	result["state"] = str(companion_data.get("state", "disponivel"))
	result["health"] = float(companion_data.get("max_health", base["health"])) * (1.0 + (level - 1) * 0.08) * rarity_multiplier
	result["speed"] = float(companion_data.get("move_speed", base["speed"]))
	result["speed_rating"] = float(companion_data.get("speed_rating", base.get("speed_rating", 5.0)))
	result["damage"] = float(companion_data.get("attack", base["damage"])) * (1.0 + (level - 1) * 0.07) * rarity_multiplier
	result["defense"] = float(companion_data.get("defense", base.get("defense", 0.0)))
	result["range"] = float(companion_data.get("range", base["range"]))
	result["cooldown"] = float(companion_data.get("cooldown", base["cooldown"]))
	result["ability_power"] = float(companion_data.get("ability_power", base.get("ability_power", 1.0)))
	return result

func _rarity_multiplier(rarity: String) -> float:
	match rarity:
		"incomum":
			return 1.08
		"raro":
			return 1.18
		"epico":
			return 1.32
		"lendario":
			return 1.5
	return 1.0

func _generate_recruitment_queue() -> Array:
	var result := []
	for i in range(RECRUITMENT_QUEUE_SIZE):
		result.append(_generate_recruit_candidate())
	return result

func _generate_recruit_candidate() -> Dictionary:
	var rarity := _roll_rarity()
	var base: Dictionary = GameBalanceScript.get_companion_defs().pick_random()
	var level := 1 + (1 if rarity in ["raro", "epico", "lendario"] and randf() < 0.45 else 0)
	var cost := _recruit_cost(str(rarity), level)
	return {
		"name": _roll_recruit_name(),
		"class": str(base["class"]),
		"class_name": str(base["name"]),
		"rarity": rarity,
		"level": level,
		"cost": cost,
		"traits": [_roll_trait()],
		"ability": str(base.get("ability", "")),
		"speed_rating": float(base.get("speed_rating", 5.0))
	}

func _roll_rarity() -> String:
	var roll := randf()
	if roll < 0.01:
		return "lendario"
	if roll < 0.05:
		return "epico"
	if roll < 0.15:
		return "raro"
	if roll < 0.4:
		return "incomum"
	return "comum"

func _recruit_cost(rarity: String, level: int) -> int:
	var base_cost := 140
	match rarity:
		"incomum":
			base_cost = 220
		"raro":
			base_cost = 360
		"epico":
			base_cost = 620
		"lendario":
			base_cost = 980
	return base_cost + max(0, level - 1) * 80

func _roll_recruit_name() -> String:
	return ["Ari", "Bela", "Caio", "Dara", "Eron", "Faye", "Galo", "Hana", "Ivo", "Juno", "Kira", "Lio"].pick_random()

func _roll_trait() -> String:
	return ["leal", "corajoso", "cuidadoso", "impulsivo", "observador", "teimoso", "sortudo", "disciplinado"].pick_random()

func _next_companion_id() -> String:
	var next_index := int(guild.get("next_companion_index", companion_roster.size() + 1))
	var companion_id := "c_recruit_%03d" % next_index
	while companion_roster.has(companion_id):
		next_index += 1
		companion_id = "c_recruit_%03d" % next_index
	guild["next_companion_index"] = next_index + 1
	return companion_id

func _normalized_return_state(run_state: String) -> String:
	if run_state in ["caido", "ferido"]:
		return "ferido"
	if run_state == "morto":
		return "morto"
	return "disponivel"

func _normalized_return_health(result: Dictionary, data: Dictionary) -> float:
	var max_health := maxf(1.0, float(result.get("max_health", data.get("max_health", 1.0))))
	var state := _normalized_return_state(str(result.get("state", data.get("state", "disponivel"))))
	if state == "ferido":
		return maxf(1.0, max_health * 0.35)
	if state == "morto":
		return 0.0
	return clampf(float(result.get("current_health", max_health)), 1.0, max_health)
