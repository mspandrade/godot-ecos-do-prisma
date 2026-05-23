extends Node

signal coins_changed(total: int)
signal character_changed(character_id: String)
signal permanent_upgrade_changed(upgrade_id: String, level: int)
signal guild_changed
signal companion_roster_changed
signal squad_changed(summary: Dictionary)
signal recruitment_changed
signal mission_changed(mission_id: String)

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
var selected_mission_id := "initial_forest_survival"
var missions := {
	"initial_forest_survival": {
		"id": "initial_forest_survival",
		"name": "Patrulha na Floresta Inicial",
		"zone": "initial_forest",
		"zone_name": "Floresta Inicial",
		"recommended_level": 1,
		"coin_reward": 80,
		"xp_reward": 30,
		"completion_unlock_zone": "wolf_cave",
		"completion_unlock_zone_name": "Caverna dos Lobos",
		"enemies": ["goblins", "slimes"],
		"objective": "Sobreviver ate decidir fugir ou cair.",
		"risk": "Baixo",
		"unlocked": true,
		"combat": {
			"duration_seconds": 180.0,
			"completion_coin_reward": 80,
			"wave_offset": 0,
			"spawn_amount_bonus": 0,
			"spawn_interval_multiplier": 1.0,
			"boss_interval": 150.0,
			"enemy_health_multiplier": 1.0,
			"enemy_speed_multiplier": 1.0,
			"enemy_damage_multiplier": 1.0,
			"xp_multiplier": 1.0,
			"coin_multiplier": 1.0
		}
	},
	"wolf_cave_scout": {
		"id": "wolf_cave_scout",
		"name": "Batedores na Caverna dos Lobos",
		"zone": "wolf_cave",
		"zone_name": "Caverna dos Lobos",
		"recommended_level": 3,
		"coin_reward": 150,
		"xp_reward": 70,
		"completion_unlock_zone": "ancient_ruins",
		"completion_unlock_zone_name": "Ruinas Antigas",
		"enemies": ["lobos", "goblins rapidos"],
		"objective": "Testar o esquadrao contra hordas rapidas.",
		"risk": "Medio",
		"unlocked": false,
		"combat": {
			"duration_seconds": 240.0,
			"completion_coin_reward": 150,
			"wave_offset": 2,
			"spawn_amount_bonus": 2,
			"spawn_interval_multiplier": 0.86,
			"boss_interval": 125.0,
			"enemy_health_multiplier": 1.18,
			"enemy_speed_multiplier": 1.16,
			"enemy_damage_multiplier": 1.12,
			"xp_multiplier": 1.25,
			"coin_multiplier": 1.25
		}
	},
	"ancient_ruins_contract": {
		"id": "ancient_ruins_contract",
		"name": "Contrato nas Ruinas Antigas",
		"zone": "ancient_ruins",
		"zone_name": "Ruinas Antigas",
		"recommended_level": 5,
		"coin_reward": 260,
		"xp_reward": 130,
		"enemies": ["cultistas", "mortos-vivos"],
		"objective": "Enfrentar inimigos resistentes e buscar reliquias.",
		"risk": "Alto",
		"unlocked": false,
		"combat": {
			"duration_seconds": 300.0,
			"completion_coin_reward": 260,
			"wave_offset": 4,
			"spawn_amount_bonus": 3,
			"spawn_interval_multiplier": 0.78,
			"boss_interval": 110.0,
			"enemy_health_multiplier": 1.45,
			"enemy_speed_multiplier": 1.06,
			"enemy_damage_multiplier": 1.28,
			"xp_multiplier": 1.55,
			"coin_multiplier": 1.55
		}
	}
}
var permanent_upgrades := {
	"guild_hall": 0,
	"dormitories": 0,
	"training_field": 0,
	"recruiter_network": 0,
	"supply_cache": 0
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
	"guild_hall": {
		"name": "Salao da Guilda",
		"category": "Base",
		"desc": "Organiza contratos, reputacao e estruturas da guilda.",
		"effect": "+1 nivel da guilda por melhoria.",
		"base_cost": 220,
		"step": 260,
		"max": 4
	},
	"dormitories": {
		"name": "Dormitorios",
		"category": "Companions",
		"desc": "Abre espaco para manter mais aventureiros contratados.",
		"effect": "+2 capacidade de companions por melhoria.",
		"base_cost": 180,
		"step": 180,
		"max": 5
	},
	"training_field": {
		"name": "Campo de Treino",
		"category": "Companions",
		"desc": "Melhora a rotina de treino e acelera aprendizado em missoes concluidas.",
		"effect": "+15% XP de missao por melhoria.",
		"base_cost": 260,
		"step": 240,
		"max": 5
	},
	"recruiter_network": {
		"name": "Rede de Recrutadores",
		"category": "Recrutamento",
		"desc": "Contatos melhores reduzem custo de reroll e aumentam candidatos raros.",
		"effect": "-10% custo de reroll e +chance de raridade por melhoria.",
		"base_cost": 240,
		"step": 230,
		"max": 5
	},
	"supply_cache": {
		"name": "Armazem de Suprimentos",
		"category": "Combate",
		"desc": "Mantem o lider equipado para sobreviver e recolher recursos.",
		"effect": "+10 vida e +8 alcance de coleta do lider por melhoria.",
		"base_cost": 160,
		"step": 150,
		"max": 6
	}
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
	if not upgrade_defs.has(upgrade_id):
		return 0
	var def: Dictionary = upgrade_defs[upgrade_id]
	return int(def["base_cost"] + def["step"] * permanent_upgrades.get(upgrade_id, 0))

func buy_permanent_upgrade(upgrade_id: String) -> bool:
	if not upgrade_defs.has(upgrade_id):
		return false
	var def: Dictionary = upgrade_defs[upgrade_id]
	var current := int(permanent_upgrades.get(upgrade_id, 0))
	if current >= int(def["max"]):
		return false
	var cost := get_upgrade_cost(upgrade_id)
	if not spend_coins(cost):
		return false
	permanent_upgrades[upgrade_id] = current + 1
	_refresh_guild_upgrade_effects()
	permanent_upgrade_changed.emit(upgrade_id, current + 1)
	guild_changed.emit()
	if upgrade_id == "dormitories":
		companion_roster_changed.emit()
	if upgrade_id == "recruiter_network":
		recruitment_changed.emit()
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
	var base_cost: int = REROLL_COSTS[min(reroll_count, REROLL_COSTS.size() - 1)]
	var discount: float = 1.0 - minf(0.5, int(permanent_upgrades.get("recruiter_network", 0)) * 0.1)
	return max(25, int(round(base_cost * discount)))

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

func get_missions() -> Array:
	_ensure_guild_defaults()
	var result := []
	for mission_id in missions.keys():
		var mission: Dictionary = missions[mission_id].duplicate(true)
		mission["unlocked"] = _is_mission_unlocked(mission)
		result.append(mission)
	result.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["recommended_level"]) < int(b["recommended_level"]))
	return result

func get_selected_mission() -> Dictionary:
	_ensure_guild_defaults()
	if not missions.has(selected_mission_id):
		selected_mission_id = "initial_forest_survival"
	var mission: Dictionary = missions[selected_mission_id].duplicate(true)
	mission["unlocked"] = _is_mission_unlocked(mission)
	return mission

func select_mission(mission_id: String) -> bool:
	_ensure_guild_defaults()
	if not missions.has(mission_id):
		return false
	var mission: Dictionary = missions[mission_id]
	if not _is_mission_unlocked(mission):
		return false
	selected_mission_id = mission_id
	save_data()
	mission_changed.emit(selected_mission_id)
	return true

func get_mission_readiness(mission_id: String = "") -> Dictionary:
	_ensure_guild_defaults()
	var resolved_id := selected_mission_id if mission_id.is_empty() else mission_id
	if not missions.has(resolved_id):
		resolved_id = "initial_forest_survival"
	var mission: Dictionary = missions[resolved_id]
	var squad := get_squad_summary()
	var average_level := float(squad["average_level"])
	var average_speed := float(squad["average_speed"])
	var recommended_level := int(mission["recommended_level"])
	var level_delta := average_level - float(recommended_level)
	var unlocked := _is_mission_unlocked(mission)
	var risk := _mission_risk_label(level_delta, average_speed, str(mission.get("risk", "Baixo")))
	var warnings := _mission_warnings(level_delta, average_speed, int(squad["size"]), unlocked)
	return {
		"mission_id": resolved_id,
		"unlocked": unlocked,
		"squad_size": int(squad["size"]),
		"average_level": average_level,
		"recommended_level": recommended_level,
		"average_speed": average_speed,
		"speed_label": str(squad["speed_label"]),
		"risk": risk,
		"warnings": warnings,
		"can_start": unlocked and int(squad["size"]) > 0
	}

func get_selected_mission_combat_profile() -> Dictionary:
	_ensure_guild_defaults()
	var mission := get_selected_mission()
	var profile: Dictionary = mission.get("combat", {}).duplicate(true)
	var defaults := {
		"mission_id": str(mission.get("id", selected_mission_id)),
		"mission_name": str(mission.get("name", "")),
		"duration_seconds": 180.0,
		"completion_coin_reward": int(mission.get("coin_reward", 0)),
		"wave_offset": 0,
		"spawn_amount_bonus": 0,
		"spawn_interval_multiplier": 1.0,
		"boss_interval": 150.0,
		"enemy_health_multiplier": 1.0,
		"enemy_speed_multiplier": 1.0,
		"enemy_damage_multiplier": 1.0,
		"xp_multiplier": 1.0,
		"coin_multiplier": 1.0
	}
	for key in defaults.keys():
		if not profile.has(key):
			profile[key] = defaults[key]
	return profile

func apply_mission_result(mission_id: String, result_reason: String) -> Dictionary:
	_ensure_guild_defaults()
	var resolved_id := mission_id
	if resolved_id.is_empty() or not missions.has(resolved_id):
		resolved_id = selected_mission_id
	if not missions.has(resolved_id):
		return {}
	var mission: Dictionary = missions[resolved_id]
	var summary := {
		"mission_id": resolved_id,
		"result_reason": result_reason,
		"xp_reward": 0,
		"xp_per_companion": 0,
		"leveled_companions": [],
		"unlocked_zones": [],
		"unlocked_zone_names": [],
		"reroll_reset": false
	}
	if int(recruitment.get("reroll_count", 0)) != 0:
		recruitment["reroll_count"] = 0
		summary["reroll_reset"] = true
	if result_reason == "vitoria":
		_apply_mission_victory_rewards(mission, summary)
	save_data()
	if result_reason == "vitoria":
		companion_roster_changed.emit()
		squad_changed.emit(get_squad_summary())
		guild_changed.emit()
		mission_changed.emit(selected_mission_id)
	if bool(summary["reroll_reset"]):
		recruitment_changed.emit()
	return summary

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

func _apply_mission_victory_rewards(mission: Dictionary, summary: Dictionary) -> void:
	var active_ids := _rewardable_active_companion_ids()
	var xp_reward := int(round(int(mission.get("xp_reward", 0)) * get_mission_xp_multiplier()))
	var xp_per_companion := int(ceil(float(xp_reward) / max(1, active_ids.size()))) if active_ids.size() > 0 else 0
	summary["xp_reward"] = xp_reward
	summary["xp_per_companion"] = xp_per_companion
	if xp_per_companion > 0:
		for companion_id in active_ids:
			var level_result := _add_companion_xp(companion_id, xp_per_companion)
			if int(level_result["levels_gained"]) > 0:
				summary["leveled_companions"].append(level_result["name"])
	var unlock_zone := str(mission.get("completion_unlock_zone", ""))
	if not unlock_zone.is_empty():
		var unlocked_zones: Array = guild.get("unlocked_zones", [])
		if not unlocked_zones.has(unlock_zone):
			unlocked_zones.append(unlock_zone)
			guild["unlocked_zones"] = unlocked_zones
			summary["unlocked_zones"].append(unlock_zone)
			summary["unlocked_zone_names"].append(str(mission.get("completion_unlock_zone_name", unlock_zone)))

func get_mission_xp_multiplier() -> float:
	return 1.0 + int(permanent_upgrades.get("training_field", 0)) * 0.15

func _rewardable_active_companion_ids() -> Array:
	var result := []
	for companion_id in active_squad:
		if not companion_roster.has(companion_id):
			continue
		var data: Dictionary = companion_roster[companion_id]
		if str(data.get("state", "disponivel")) == "morto":
			continue
		result.append(str(companion_id))
	return result

func _add_companion_xp(companion_id: String, amount: int) -> Dictionary:
	var data: Dictionary = companion_roster[companion_id]
	var levels_gained := 0
	data["xp"] = max(0, int(data.get("xp", 0))) + max(0, amount)
	data["xp_required"] = max(1, int(data.get("xp_required", 10)))
	while int(data["xp"]) >= int(data["xp_required"]):
		data["xp"] = int(data["xp"]) - int(data["xp_required"])
		data["level"] = int(data.get("level", 1)) + 1
		data["xp_required"] = int(int(data["xp_required"]) * 1.28 + 6)
		data["current_health"] = maxf(1.0, float(data.get("max_health", 1.0)))
		levels_gained += 1
	companion_roster[companion_id] = data
	return {
		"name": str(data.get("name", companion_id)),
		"levels_gained": levels_gained
	}

func get_selected_stats() -> Dictionary:
	var stats: Dictionary = characters[selected_character].duplicate(true)
	var supply_level := int(permanent_upgrades.get("supply_cache", 0))
	stats["max_health"] += supply_level * 10.0
	stats["pickup_range"] += supply_level * 8.0
	stats["max_health"] += int(permanent_upgrades.get("max_health", 0)) * 8.0
	stats["damage"] += int(permanent_upgrades.get("damage", 0)) * 0.035
	stats["speed"] += int(permanent_upgrades.get("move_speed", 0)) * 8.0
	stats["pickup_range"] += int(permanent_upgrades.get("pickup_range", 0)) * 12.0
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
	cfg.set_value("guild", "selected_mission_id", selected_mission_id)
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
	selected_mission_id = str(cfg.get_value("guild", "selected_mission_id", selected_mission_id))
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
	for upgrade_id in upgrade_defs.keys():
		if not permanent_upgrades.has(upgrade_id):
			permanent_upgrades[upgrade_id] = 0
	_refresh_guild_upgrade_effects()
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
	if not missions.has(selected_mission_id) or not _is_mission_unlocked(missions[selected_mission_id]):
		selected_mission_id = "initial_forest_survival"

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

func _refresh_guild_upgrade_effects() -> void:
	var hall_level := int(permanent_upgrades.get("guild_hall", 0))
	var dormitory_level := int(permanent_upgrades.get("dormitories", 0))
	guild["level"] = 1 + hall_level
	guild["companion_capacity"] = 12 + dormitory_level * 2
	var structures := ["hall", "recruitment", "mission_board"]
	if int(permanent_upgrades.get("training_field", 0)) > 0 or hall_level >= 1:
		structures.append("training_field")
	if int(permanent_upgrades.get("recruiter_network", 0)) > 0 or hall_level >= 2:
		structures.append("recruiter_network")
	if int(permanent_upgrades.get("supply_cache", 0)) > 0 or hall_level >= 1:
		structures.append("supply_cache")
	if hall_level >= 2:
		structures.append("graveyard")
	if hall_level >= 3:
		structures.append("blacksmith")
	guild["unlocked_structures"] = structures

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
	var recruiter_level := int(permanent_upgrades.get("recruiter_network", 0))
	var legendary_threshold := 0.01 + recruiter_level * 0.002
	var epic_threshold := 0.05 + recruiter_level * 0.008
	var rare_threshold := 0.15 + recruiter_level * 0.02
	var uncommon_threshold := 0.4 + recruiter_level * 0.03
	if roll < legendary_threshold:
		return "lendario"
	if roll < epic_threshold:
		return "epico"
	if roll < rare_threshold:
		return "raro"
	if roll < uncommon_threshold:
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

func _is_mission_unlocked(mission: Dictionary) -> bool:
	if bool(mission.get("unlocked", false)):
		return true
	var zone := str(mission.get("zone", ""))
	var unlocked_zones: Array = guild.get("unlocked_zones", [])
	return unlocked_zones.has(zone)

func _mission_risk_label(level_delta: float, average_speed: float, base_risk: String) -> String:
	var score := 0
	match base_risk:
		"Medio":
			score += 1
		"Alto":
			score += 2
	if level_delta < -2.0:
		score += 2
	elif level_delta < 0.0:
		score += 1
	if average_speed < 4.0:
		score += 1
	return ["Baixo", "Medio", "Alto", "Critico"][min(score, 3)]

func _mission_warnings(level_delta: float, average_speed: float, squad_size: int, unlocked: bool) -> Array:
	var warnings := []
	if not unlocked:
		warnings.append("Zona bloqueada. Evolua a guilda ou conclua missoes anteriores.")
	if squad_size <= 0:
		warnings.append("Monte um esquadrao antes de iniciar.")
	if level_delta < 0.0:
		warnings.append("Esquadrao abaixo do level recomendado.")
	if average_speed < 6.0:
		warnings.append("Baixa mobilidade pode dificultar a fuga.")
	if warnings.is_empty():
		warnings.append("Esquadrao pronto para esta missao.")
	return warnings

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
