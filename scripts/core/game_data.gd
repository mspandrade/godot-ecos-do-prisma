extends Node

signal coins_changed(total: int)
signal character_changed(character_id: String)
signal permanent_upgrade_changed(upgrade_id: String, level: int)
signal guild_changed
signal companion_roster_changed
signal squad_changed(summary: Dictionary)
signal recruitment_changed
signal mission_changed(mission_id: String)
signal travel_zone_changed(zone_id: String)
signal equipment_changed
signal materials_changed
signal training_changed(companion_id: String)
signal bestiary_changed
signal achievement_unlocked(achievement_id: String)
signal settings_changed(settings: Dictionary)
signal save_feedback(message: String)

const SAVE_PATH := "user://save_data.cfg"
const GameBalanceScript := preload("res://scripts/game/game_balance.gd")
const MAX_SQUAD_SIZE := 6
const MAX_COMPANION_EQUIPMENT := 2
const MAX_EQUIPMENT_LEVEL := 5
const RECRUITMENT_QUEUE_SIZE := 3
const REROLL_COSTS := [100, 150, 250, 400]

var coins := 0
var selected_character := "runner"
var unlocked_characters := {"runner": true}
var guild := {
	"name": "Guilda Falida",
	"level": 1,
	"reputation": 0,
	"morale": 50,
	"companion_capacity": 12,
	"campaign_completed": false,
	"unlocked_structures": ["hall", "recruitment", "mission_board"],
	"unlocked_zones": ["initial_forest"]
}
var companion_roster := {}
var active_squad := []
var recruitment := {}
var equipment_inventory := []
var equipment_serial := 0
var materials := {}
var bestiary := {}
var achievements := {}
var settings := {
	"master_volume": 0.8,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"fullscreen": false
}
var selected_travel_zone := "initial_forest"
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
		"reputation_reward": 3,
		"material_rewards": {"forest_herbs": 2},
		"equipment_reward_chance": 0.35,
		"completion_unlock_zone": "wolf_cave",
		"completion_unlock_zone_name": "Caverna dos Lobos",
		"enemies": ["goblins", "slimes"],
		"objective": "Sobreviver ate decidir fugir ou cair.",
		"risk": "Baixo",
		"unlocked": true,
		"combat": {
			"objective_type": "survive",
			"target_kills": 0,
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
	"initial_forest_gathering": {
		"id": "initial_forest_gathering",
		"name": "Coleta de Ervas na Floresta",
		"zone": "initial_forest",
		"zone_name": "Floresta Inicial",
		"recommended_level": 2,
		"coin_reward": 105,
		"xp_reward": 42,
		"reputation_reward": 4,
		"material_rewards": {"forest_herbs": 4},
		"equipment_reward_chance": 0.4,
		"enemies": ["goblins", "slimes"],
		"objective": "Recolher suprimentos antes que a expedicao termine.",
		"risk": "Baixo",
		"unlocked": true,
		"combat": {
			"objective_type": "collect_resources",
			"target_resources": 45,
			"duration_seconds": 165.0,
			"completion_coin_reward": 105,
			"wave_offset": 1,
			"spawn_amount_bonus": 1,
			"spawn_interval_multiplier": 0.94,
			"boss_interval": 145.0,
			"enemy_health_multiplier": 1.06,
			"enemy_speed_multiplier": 1.05,
			"enemy_damage_multiplier": 1.02,
			"xp_multiplier": 1.08,
			"coin_multiplier": 1.1
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
		"reputation_reward": 6,
		"material_rewards": {"wolf_fang": 2},
		"equipment_reward_chance": 0.5,
		"completion_unlock_zone": "ancient_ruins",
		"completion_unlock_zone_name": "Ruinas Antigas",
		"enemies": ["lobos", "goblins rapidos"],
		"objective": "Testar o esquadrao contra hordas rapidas.",
		"risk": "Medio",
		"unlocked": false,
		"combat": {
			"objective_type": "kill_count",
			"target_kills": 140,
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
	"wolf_cave_alpha_hunt": {
		"id": "wolf_cave_alpha_hunt",
		"name": "Cacada ao Alfa da Caverna",
		"zone": "wolf_cave",
		"zone_name": "Caverna dos Lobos",
		"recommended_level": 4,
		"coin_reward": 210,
		"xp_reward": 95,
		"reputation_reward": 8,
		"material_rewards": {"alpha_hide": 1, "wolf_fang": 2},
		"equipment_reward_chance": 0.65,
		"enemies": ["lobos alfa", "batedores goblins"],
		"objective": "Atrair e derrotar o chefe da alcateia.",
		"risk": "Alto",
		"unlocked": false,
		"combat": {
			"objective_type": "boss_kill",
			"target_kills": 0,
			"target_bosses": 1,
			"duration_seconds": 210.0,
			"completion_coin_reward": 210,
			"wave_offset": 3,
			"spawn_amount_bonus": 2,
			"spawn_interval_multiplier": 0.82,
			"boss_interval": 42.0,
			"enemy_health_multiplier": 1.3,
			"enemy_speed_multiplier": 1.18,
			"enemy_damage_multiplier": 1.2,
			"xp_multiplier": 1.38,
			"coin_multiplier": 1.4
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
		"reputation_reward": 10,
		"material_rewards": {"ancient_relic": 2},
		"completion_unlock_zone": "poison_swamp",
		"completion_unlock_zone_name": "Pantano Venenoso",
		"equipment_reward_chance": 0.7,
		"enemies": ["cultistas", "mortos-vivos"],
		"objective": "Enfrentar inimigos resistentes e buscar reliquias.",
		"risk": "Alto",
		"unlocked": false,
		"combat": {
			"objective_type": "kill_count",
			"target_kills": 190,
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
	},
	"poison_swamp_purge": {
		"id": "poison_swamp_purge",
		"name": "Expurgo no Pantano Venenoso",
		"zone": "poison_swamp",
		"zone_name": "Pantano Venenoso",
		"recommended_level": 6,
		"coin_reward": 330,
		"xp_reward": 170,
		"reputation_reward": 12,
		"material_rewards": {"venom_gland": 2},
		"completion_unlock_zone": "cursed_graveyard",
		"completion_unlock_zone_name": "Cemiterio Maldito",
		"equipment_reward_chance": 0.75,
		"enemies": ["aranhas venenosas", "cultistas do pantano"],
		"objective": "Limpar os ninhos antes que a nevoa toxica se espalhe.",
		"risk": "Alto",
		"unlocked": false,
		"combat": {
			"objective_type": "kill_count",
			"target_kills": 220,
			"duration_seconds": 330.0,
			"completion_coin_reward": 330,
			"wave_offset": 5,
			"spawn_amount_bonus": 4,
			"spawn_interval_multiplier": 0.74,
			"boss_interval": 102.0,
			"enemy_health_multiplier": 1.58,
			"enemy_speed_multiplier": 1.1,
			"enemy_damage_multiplier": 1.38,
			"xp_multiplier": 1.7,
			"coin_multiplier": 1.7
		}
	},
	"cursed_graveyard_hunt": {
		"id": "cursed_graveyard_hunt",
		"name": "Cacada no Cemiterio Maldito",
		"zone": "cursed_graveyard",
		"zone_name": "Cemiterio Maldito",
		"recommended_level": 7,
		"coin_reward": 380,
		"xp_reward": 195,
		"reputation_reward": 14,
		"material_rewards": {"cursed_bone": 2},
		"completion_unlock_zone": "demon_gate",
		"completion_unlock_zone_name": "Portao Demoniaco",
		"equipment_reward_chance": 0.8,
		"enemies": ["mortos-vivos", "necromantes"],
		"objective": "Derrubar os necromantes que alimentam o portao.",
		"risk": "Muito Alto",
		"unlocked": false,
		"combat": {
			"objective_type": "kill_count",
			"target_kills": 240,
			"duration_seconds": 350.0,
			"completion_coin_reward": 380,
			"wave_offset": 6,
			"spawn_amount_bonus": 4,
			"spawn_interval_multiplier": 0.71,
			"boss_interval": 96.0,
			"enemy_health_multiplier": 1.72,
			"enemy_speed_multiplier": 1.08,
			"enemy_damage_multiplier": 1.47,
			"xp_multiplier": 1.85,
			"coin_multiplier": 1.84
		}
	},
	"demon_gate_assault": {
		"id": "demon_gate_assault",
		"name": "Assalto ao Portao Demoniaco",
		"zone": "demon_gate",
		"zone_name": "Portao Demoniaco",
		"recommended_level": 8,
		"coin_reward": 420,
		"xp_reward": 220,
		"reputation_reward": 16,
		"material_rewards": {"demon_ember": 2},
		"completion_unlock_zone": "demon_keep",
		"completion_unlock_zone_name": "Fortaleza do Rei Demonio",
		"equipment_reward_chance": 0.85,
		"enemies": ["demonios", "cavaleiros corrompidos"],
		"objective": "Romper a linha de defesa antes que o portal se estabilize.",
		"risk": "Muito Alto",
		"unlocked": false,
		"combat": {
			"objective_type": "kill_count",
			"target_kills": 260,
			"duration_seconds": 360.0,
			"completion_coin_reward": 420,
			"wave_offset": 7,
			"spawn_amount_bonus": 5,
			"spawn_interval_multiplier": 0.68,
			"boss_interval": 90.0,
			"enemy_health_multiplier": 1.85,
			"enemy_speed_multiplier": 1.14,
			"enemy_damage_multiplier": 1.55,
			"xp_multiplier": 2.0,
			"coin_multiplier": 2.0
		}
	},
	"demon_king_vanguard": {
		"id": "demon_king_vanguard",
		"name": "Vanguarda do Rei Demonio",
		"zone": "demon_keep",
		"zone_name": "Fortaleza do Rei Demonio",
		"recommended_level": 11,
		"coin_reward": 650,
		"xp_reward": 360,
		"reputation_reward": 25,
		"material_rewards": {"infernal_core": 2},
		"completion_unlock_zone": "demon_throne",
		"completion_unlock_zone_name": "Trono do Rei Demonio",
		"equipment_reward_chance": 1.0,
		"enemies": ["generais demoniacos", "guardioes infernais"],
		"objective": "Enfraquecer a guarda pessoal antes do confronto final.",
		"risk": "Extremo",
		"unlocked": false,
		"combat": {
			"objective_type": "kill_count",
			"target_kills": 320,
			"duration_seconds": 420.0,
			"completion_coin_reward": 650,
			"wave_offset": 11,
			"spawn_amount_bonus": 7,
			"spawn_interval_multiplier": 0.58,
			"boss_interval": 75.0,
			"enemy_health_multiplier": 2.35,
			"enemy_speed_multiplier": 1.22,
			"enemy_damage_multiplier": 1.95,
			"xp_multiplier": 2.7,
			"coin_multiplier": 2.6
		}
	},
	"demon_king_final": {
		"id": "demon_king_final",
		"name": "Confronto com o Rei Demonio",
		"zone": "demon_throne",
		"zone_name": "Trono do Rei Demonio",
		"recommended_level": 14,
		"coin_reward": 1200,
		"xp_reward": 600,
		"reputation_reward": 50,
		"material_rewards": {"demon_crown_shard": 1},
		"equipment_reward_chance": 1.0,
		"campaign_completion": true,
		"campaign_completion_name": "O Rei Demonio caiu. A guilda cumpriu seu juramento.",
		"enemies": ["rei demonio", "legiao final"],
		"objective": "Derrotar a guarda final e quebrar o dominio do Rei Demonio.",
		"risk": "Final",
		"unlocked": false,
		"combat": {
			"objective_type": "boss_kill",
			"target_kills": 0,
			"target_bosses": 1,
			"duration_seconds": 540.0,
			"completion_coin_reward": 1200,
			"wave_offset": 16,
			"spawn_amount_bonus": 9,
			"spawn_interval_multiplier": 0.5,
			"boss_interval": 55.0,
			"enemy_health_multiplier": 3.1,
			"enemy_speed_multiplier": 1.28,
			"enemy_damage_multiplier": 2.5,
			"xp_multiplier": 3.6,
			"coin_multiplier": 3.4
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
		"requires_guild_level": 1,
		"base_cost": 180,
		"step": 180,
		"max": 5
	},
	"training_field": {
		"name": "Campo de Treino",
		"category": "Companions",
		"desc": "Melhora a rotina de treino e acelera aprendizado em missoes concluidas.",
		"effect": "+15% XP de missao por melhoria.",
		"requires_guild_level": 2,
		"base_cost": 260,
		"step": 240,
		"max": 5
	},
	"recruiter_network": {
		"name": "Rede de Recrutadores",
		"category": "Recrutamento",
		"desc": "Contatos melhores reduzem custo de reroll e aumentam candidatos raros.",
		"effect": "-10% custo de reroll e +chance de raridade por melhoria.",
		"requires_guild_level": 2,
		"base_cost": 240,
		"step": 230,
		"max": 5
	},
	"supply_cache": {
		"name": "Armazem de Suprimentos",
		"category": "Combate",
		"desc": "Mantem o lider equipado para sobreviver e recolher recursos.",
		"effect": "+10 vida e +8 alcance de coleta do lider por melhoria.",
		"requires_guild_level": 1,
		"base_cost": 160,
		"step": 150,
		"max": 6
	}
}

var equipment_defs := {
	"iron_blade": {
		"name": "Lamina de Ferro",
		"slot": "arma",
		"cost": 140,
		"effect": "+1.3 ataque",
		"bonuses": {"attack": 1.3}
	},
	"reinforced_vest": {
		"name": "Colete Reforcado",
		"slot": "armadura",
		"cost": 160,
		"effect": "+10 vida, +1.5 defesa",
		"bonuses": {"max_health": 10.0, "defense": 1.5}
	},
	"scout_boots": {
		"name": "Botas de Batedor",
		"slot": "acessorio",
		"cost": 150,
		"effect": "+0.6 mobilidade, +12 velocidade",
		"bonuses": {"speed_rating": 0.6, "move_speed": 12.0}
	},
	"focus_charm": {
		"name": "Amuleto de Foco",
		"slot": "acessorio",
		"cost": 180,
		"effect": "+0.15 poder, +12 alcance",
		"bonuses": {"ability_power": 0.15, "range": 12.0}
	},
	"tower_shield": {
		"name": "Escudo Torre",
		"slot": "armadura",
		"cost": 210,
		"effect": "+4 defesa, -0.7 mobilidade, -10 velocidade",
		"bonuses": {"defense": 4.0, "speed_rating": -0.7, "move_speed": -10.0},
		"materials": {"cursed_bone": 1},
		"drop_min_level": 7
	},
	"heavy_plate": {
		"name": "Placas Pesadas",
		"slot": "armadura",
		"cost": 260,
		"effect": "+22 vida, +2 defesa, -1.0 mobilidade, -14 velocidade",
		"bonuses": {"max_health": 22.0, "defense": 2.0, "speed_rating": -1.0, "move_speed": -14.0},
		"materials": {"demon_ember": 2},
		"drop_min_level": 8
	}
}

var achievement_defs := {
	"first_contract": {"name": "Primeiro Contrato", "desc": "Concluir a primeira missao."},
	"first_recruit": {"name": "Nova Assinatura", "desc": "Contratar um companion."},
	"first_equipment": {"name": "Aco da Guilda", "desc": "Obter um equipamento."},
	"first_boss": {"name": "Cacador de Alfas", "desc": "Concluir uma missao de chefe."},
	"full_squad": {"name": "Mesa Cheia", "desc": "Formar um esquadrao com 6 companions."},
	"expanded_roster": {"name": "Guilda Populosa", "desc": "Manter 7 companions no roster."},
	"guild_level_5": {"name": "Sede Restaurada", "desc": "Levar a guilda ao nivel 5."},
	"first_death": {"name": "Preco do Contrato", "desc": "Perder um companion em missao."},
	"first_resurrection": {"name": "Segunda Chance", "desc": "Ressuscitar um companion."},
	"bestiary_25": {"name": "Anotacoes de Campo", "desc": "Registrar 25 inimigos derrotados."},
	"demon_king_defeated": {"name": "Juramento Cumprido", "desc": "Concluir a campanha contra o Rei Demonio."}
}

var trait_defs := {
	"leal": {"name": "Leal", "effect": "+3 vida", "bonuses": {"max_health": 3.0}},
	"corajoso": {"name": "Corajoso", "effect": "+0.6 ataque", "bonuses": {"attack": 0.6}},
	"cuidadoso": {"name": "Cuidadoso", "effect": "+1.25 defesa", "bonuses": {"defense": 1.25}},
	"cuidadosa": {"name": "Cuidadosa", "effect": "+1.25 defesa", "bonuses": {"defense": 1.25}},
	"impulsivo": {"name": "Impulsivo", "effect": "+1 ataque, -6% recarga", "bonuses": {"attack": 1.0, "cooldown_multiplier": 0.94}},
	"observador": {"name": "Observador", "effect": "+32 alcance", "bonuses": {"range": 32.0}},
	"teimoso": {"name": "Teimoso", "effect": "+8 vida, +0.5 defesa", "bonuses": {"max_health": 8.0, "defense": 0.5}},
	"sortudo": {"name": "Sortudo", "effect": "+10% sorte", "bonuses": {"luck": 0.1}},
	"disciplinado": {"name": "Disciplinado", "effect": "-10% recarga", "bonuses": {"cooldown_multiplier": 0.9}},
	"focada": {"name": "Focada", "effect": "+20% poder de habilidade", "bonuses": {"ability_power": 0.2}},
	"curiosa": {"name": "Curiosa", "effect": "+20% poder de habilidade", "bonuses": {"ability_power": 0.2}}
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

func get_upgrade_lock_reason(upgrade_id: String) -> String:
	if not upgrade_defs.has(upgrade_id):
		return "Melhoria desconhecida."
	var def: Dictionary = upgrade_defs[upgrade_id]
	var required_guild_level := int(def.get("requires_guild_level", 1))
	var current_guild_level := int(guild.get("level", 1))
	if current_guild_level < required_guild_level:
		return "Requer Guilda Nv %d." % required_guild_level
	return ""

func can_buy_permanent_upgrade(upgrade_id: String) -> bool:
	if not upgrade_defs.has(upgrade_id):
		return false
	var def: Dictionary = upgrade_defs[upgrade_id]
	var current := int(permanent_upgrades.get(upgrade_id, 0))
	if current >= int(def["max"]):
		return false
	if not get_upgrade_lock_reason(upgrade_id).is_empty():
		return false
	return coins >= get_upgrade_cost(upgrade_id)

func buy_permanent_upgrade(upgrade_id: String) -> bool:
	if not upgrade_defs.has(upgrade_id):
		return false
	var def: Dictionary = upgrade_defs[upgrade_id]
	var current := int(permanent_upgrades.get(upgrade_id, 0))
	if current >= int(def["max"]):
		return false
	if not get_upgrade_lock_reason(upgrade_id).is_empty():
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
	_check_guild_achievements()
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

func get_trait_effect_text(trait_id: String) -> String:
	if not trait_defs.has(trait_id):
		return trait_id.capitalize()
	var trait_definition: Dictionary = trait_defs[trait_id]
	return "%s (%s)" % [str(trait_definition.get("name", trait_id.capitalize())), str(trait_definition.get("effect", ""))]

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
	_check_squad_achievements()
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

func apply_companion_run_results(results: Array) -> Dictionary:
	_ensure_guild_defaults()
	var changed := false
	var summary := {
		"wounded_companions": [],
		"dead_companions": []
	}
	for result_value in results:
		var result: Dictionary = result_value
		var companion_id := str(result.get("id", ""))
		if companion_id.is_empty() or not companion_roster.has(companion_id):
			continue
		var data: Dictionary = companion_roster[companion_id]
		var companion_name := str(data.get("name", companion_id))
		var returned_state := str(result.get("state", data.get("state", "disponivel")))
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
		data["crit"] = maxf(0.0, float(result.get("crit", data.get("crit", 0.0))))
		data["luck"] = maxf(0.0, float(result.get("luck", data.get("luck", 0.0))))
		data["state"] = _normalized_return_state(returned_state)
		if str(data["state"]) == "morto":
			active_squad.erase(companion_id)
			summary["dead_companions"].append(companion_name)
			_unlock_achievement("first_death")
		elif str(data["state"]) == "ferido":
			summary["wounded_companions"].append(companion_name)
		companion_roster[companion_id] = data
		changed = true
	if changed:
		var morale_penalty := int(summary["dead_companions"].size()) * -8 + int(summary["wounded_companions"].size()) * -2
		if morale_penalty != 0:
			_apply_morale_delta(morale_penalty)
		save_data()
		companion_roster_changed.emit()
		squad_changed.emit(get_squad_summary())
	return summary

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
	_unlock_achievement("first_recruit")
	_check_roster_achievements()
	save_data()
	companion_roster_changed.emit()
	recruitment_changed.emit()
	return true

func get_dead_companions() -> Array:
	_ensure_guild_defaults()
	var result := []
	for companion_id in companion_roster.keys():
		var data: Dictionary = companion_roster[companion_id].duplicate(true)
		if str(data.get("state", "disponivel")) != "morto":
			continue
		data["id"] = str(companion_id)
		data["resurrection_cost"] = get_resurrection_cost(str(companion_id))
		result.append(data)
	result.sort_custom(func(a: Dictionary, b: Dictionary): return str(a["name"]) < str(b["name"]))
	return result

func get_wounded_companions() -> Array:
	_ensure_guild_defaults()
	var result := []
	for companion_id in companion_roster.keys():
		var data: Dictionary = companion_roster[companion_id].duplicate(true)
		if str(data.get("state", "disponivel")) != "ferido":
			continue
		data["id"] = str(companion_id)
		data["treatment_cost"] = get_treatment_cost(str(companion_id))
		result.append(data)
	result.sort_custom(func(a: Dictionary, b: Dictionary): return str(a["name"]) < str(b["name"]))
	return result

func get_treatment_cost(companion_id: String) -> int:
	if not companion_roster.has(companion_id):
		return 0
	var data: Dictionary = companion_roster[companion_id]
	var level := int(data.get("level", 1))
	return 55 + level * 25

func treat_companion(companion_id: String) -> bool:
	_ensure_guild_defaults()
	if not (guild.get("unlocked_structures", []) as Array).has("infirmary"):
		return false
	if not companion_roster.has(companion_id):
		return false
	var data: Dictionary = companion_roster[companion_id]
	if str(data.get("state", "disponivel")) != "ferido":
		return false
	var cost := get_treatment_cost(companion_id)
	if cost <= 0 or not spend_coins(cost):
		return false
	data["state"] = "disponivel"
	data["current_health"] = float(data.get("max_health", 1.0))
	companion_roster[companion_id] = data
	save_data()
	companion_roster_changed.emit()
	squad_changed.emit(get_squad_summary())
	return true

func get_resurrection_cost(companion_id: String) -> int:
	if not companion_roster.has(companion_id):
		return 0
	var data: Dictionary = companion_roster[companion_id]
	var level := int(data.get("level", 1))
	var rarity := str(data.get("rarity", "comum"))
	var rarity_cost := 0
	match rarity:
		"incomum":
			rarity_cost = 80
		"raro":
			rarity_cost = 180
		"epico":
			rarity_cost = 360
		"lendario":
			rarity_cost = 700
	return 220 + max(0, level - 1) * 90 + rarity_cost

func resurrect_companion(companion_id: String) -> bool:
	_ensure_guild_defaults()
	if not companion_roster.has(companion_id):
		return false
	var data: Dictionary = companion_roster[companion_id]
	if str(data.get("state", "disponivel")) != "morto":
		return false
	var cost := get_resurrection_cost(companion_id)
	if not spend_coins(cost):
		return false
	data["state"] = "ferido"
	data["current_health"] = maxf(1.0, float(data.get("max_health", 1.0)) * 0.35)
	data["xp"] = int(floor(max(0, int(data.get("xp", 0))) * 0.75))
	companion_roster[companion_id] = data
	_unlock_achievement("first_resurrection")
	save_data()
	companion_roster_changed.emit()
	squad_changed.emit(get_squad_summary())
	return true

func get_companion_upgrade_choices(companion_id: String) -> Array:
	_ensure_guild_defaults()
	if not companion_roster.has(companion_id):
		return []
	var data: Dictionary = companion_roster[companion_id]
	if int(data.get("pending_upgrades", 0)) <= 0 or str(data.get("state", "disponivel")) == "morto":
		return []
	var choices: Array = (_companion_upgrade_choices(str(data.get("class", "shield"))) as Array).slice(0, 3)
	var rarity := str(data.get("rarity", "comum"))
	var level := int(data.get("level", 1))
	var milestone_choice := _companion_milestone_choice(level)
	if not milestone_choice.is_empty():
		choices[2] = milestone_choice
	if rarity == "incomum" and level >= 5:
		choices[1] = {"id": "crit", "name": "Precisao", "desc": "+4% chance critica"}
	elif rarity == "raro":
		choices.append({"id": "crit", "name": "Precisao", "desc": "+4% chance critica"} if level >= 5 else {"id": "ability", "name": "Talento", "desc": "+15% efeito especial"})
	elif rarity == "epico":
		choices.append({"id": "crit", "name": "Precisao Epica", "desc": "+6% chance critica"})
		if level >= 5:
			choices[1] = {"id": "luck", "name": "Fortuna", "desc": "+6% sorte"}
	elif rarity == "lendario":
		choices.append({"id": "crit", "name": "Precisao Lendaria", "desc": "+6% chance critica"})
		choices.append({"id": "luck", "name": "Destino", "desc": "+8% sorte"})
		if level >= 5:
			choices[1] = {"id": "ability", "name": "Dom Lendario", "desc": "+15% efeito especial"}
	return choices

func apply_companion_pending_upgrade(companion_id: String, upgrade_id: String) -> bool:
	_ensure_guild_defaults()
	if not companion_roster.has(companion_id):
		return false
	var data: Dictionary = companion_roster[companion_id]
	if int(data.get("pending_upgrades", 0)) <= 0:
		return false
	if str(data.get("state", "disponivel")) == "morto":
		return false
	var allowed := false
	for choice in get_companion_upgrade_choices(companion_id):
		if str(choice.get("id", "")) == upgrade_id:
			allowed = true
			break
	if not allowed:
		return false
	if not _apply_companion_upgrade_to_data(data, upgrade_id):
		return false
	data["pending_upgrades"] = max(0, int(data.get("pending_upgrades", 0)) - 1)
	companion_roster[companion_id] = data
	save_data()
	companion_roster_changed.emit()
	squad_changed.emit(get_squad_summary())
	return true

func get_training_options() -> Array:
	return [
		{"id": "attack", "name": "Ataque", "desc": "+6% ataque permanente"},
		{"id": "health", "name": "Vigor", "desc": "+6 vida maxima"},
		{"id": "speed", "name": "Mobilidade", "desc": "+0.25 mobilidade e +7 velocidade"},
		{"id": "defense", "name": "Defesa", "desc": "+1 defesa"}
	]

func get_training_cost(companion_id: String) -> int:
	_ensure_guild_defaults()
	if not companion_roster.has(companion_id):
		return 0
	var data: Dictionary = companion_roster[companion_id]
	var level := int(data.get("level", 1))
	var sessions := int(data.get("training_sessions", 0))
	return 90 + level * 35 + sessions * 45

func train_companion(companion_id: String, training_id: String) -> bool:
	_ensure_guild_defaults()
	if not (guild.get("unlocked_structures", []) as Array).has("training_field"):
		return false
	if not companion_roster.has(companion_id):
		return false
	var data: Dictionary = companion_roster[companion_id]
	if str(data.get("state", "disponivel")) == "morto":
		return false
	var allowed := false
	for option in get_training_options():
		if str(option.get("id", "")) == training_id:
			allowed = true
			break
	if not allowed:
		return false
	var cost := get_training_cost(companion_id)
	if cost <= 0 or not spend_coins(cost):
		return false
	match training_id:
		"attack":
			data["attack"] = float(data.get("attack", 0.0)) * 1.06
		"health":
			data["max_health"] = float(data.get("max_health", 1.0)) + 6.0
			data["current_health"] = float(data.get("max_health", 1.0))
		"speed":
			data["move_speed"] = float(data.get("move_speed", 1.0)) + 7.0
			data["speed_rating"] = float(data.get("speed_rating", 0.0)) + 0.25
		"defense":
			data["defense"] = float(data.get("defense", 0.0)) + 1.0
	data["training_sessions"] = int(data.get("training_sessions", 0)) + 1
	companion_roster[companion_id] = data
	save_data()
	companion_roster_changed.emit()
	squad_changed.emit(get_squad_summary())
	training_changed.emit(companion_id)
	return true

func add_bestiary_kills(kill_counts: Dictionary) -> void:
	_ensure_guild_defaults()
	var changed := false
	for enemy_type in kill_counts.keys():
		var key := str(enemy_type)
		var amount := int(kill_counts[enemy_type])
		if key.is_empty() or amount <= 0:
			continue
		bestiary[key] = int(bestiary.get(key, 0)) + amount
		changed = true
	if changed:
		_check_bestiary_achievements()
		save_data()
		bestiary_changed.emit()

func get_bestiary() -> Dictionary:
	_ensure_guild_defaults()
	return bestiary.duplicate(true)

func get_achievements() -> Dictionary:
	return achievements.duplicate(true)

func get_achievement_defs() -> Dictionary:
	return achievement_defs.duplicate(true)

func get_settings() -> Dictionary:
	return settings.duplicate(true)

func set_game_setting(setting_id: String, value: Variant) -> bool:
	if not settings.has(setting_id):
		return false
	match setting_id:
		"master_volume", "music_volume", "sfx_volume":
			settings[setting_id] = clampf(float(value), 0.0, 1.0)
		"fullscreen":
			settings[setting_id] = bool(value)
		_:
			return false
	_apply_settings()
	save_data()
	settings_changed.emit(get_settings())
	return true

func get_equipment_defs() -> Dictionary:
	return equipment_defs.duplicate(true)

func get_materials() -> Dictionary:
	_ensure_guild_defaults()
	return materials.duplicate(true)

func get_material_name(material_id: String) -> String:
	var names := {
		"forest_herbs": "Ervas da Floresta",
		"wolf_fang": "Presa de Lobo",
		"alpha_hide": "Couro do Alfa",
		"ancient_relic": "Reliquia Antiga",
		"venom_gland": "Glandula Venenosa",
		"cursed_bone": "Osso Amaldicoado",
		"demon_ember": "Brasa Demoniaca",
		"infernal_core": "Nucleo Infernal",
		"demon_crown_shard": "Fragmento da Coroa"
	}
	return str(names.get(material_id, material_id.replace("_", " ").capitalize()))

func get_equipment_inventory() -> Array:
	_ensure_guild_defaults()
	return equipment_inventory

func can_craft_equipment(equipment_id: String) -> bool:
	_ensure_guild_defaults()
	if not equipment_defs.has(equipment_id):
		return false
	var def: Dictionary = equipment_defs[equipment_id]
	if coins < int(def.get("cost", 0)):
		return false
	for material_id in (def.get("materials", {}) as Dictionary).keys():
		if int(materials.get(str(material_id), 0)) < int(def["materials"][material_id]):
			return false
	return true

func get_equipment_material_cost_text(equipment_id: String) -> String:
	if not equipment_defs.has(equipment_id):
		return ""
	var required: Dictionary = equipment_defs[equipment_id].get("materials", {})
	var parts := []
	for material_id in required.keys():
		parts.append("%s x%d" % [get_material_name(str(material_id)), int(required[material_id])])
	return ", ".join(parts)

func craft_equipment(equipment_id: String) -> bool:
	_ensure_guild_defaults()
	if not can_craft_equipment(equipment_id):
		return false
	var def: Dictionary = equipment_defs[equipment_id]
	var cost := int(def.get("cost", 0))
	if not spend_coins(cost):
		return false
	for material_id in (def.get("materials", {}) as Dictionary).keys():
		var key := str(material_id)
		materials[key] = int(materials.get(key, 0)) - int(def["materials"][material_id])
	equipment_inventory.append(_create_equipment_item(equipment_id))
	_unlock_achievement("first_equipment")
	save_data()
	materials_changed.emit()
	equipment_changed.emit()
	return true

func award_random_equipment(recommended_level: int = 1) -> String:
	_ensure_guild_defaults()
	return award_equipment_candidate(roll_random_equipment_candidate(recommended_level))

func roll_random_equipment_candidate(recommended_level: int = 1) -> Dictionary:
	var ids := _drop_equipment_ids(recommended_level)
	if ids.is_empty():
		return {}
	return {
		"equipment_id": str(ids.pick_random()),
		"rarity": _roll_mission_equipment_rarity(recommended_level)
	}

func award_equipment_candidate(candidate: Dictionary) -> String:
	_ensure_guild_defaults()
	var equipment_id := str(candidate.get("equipment_id", ""))
	if not equipment_defs.has(equipment_id):
		return ""
	var item_name := _add_equipment_reward(equipment_id, str(candidate.get("rarity", "comum")))
	_unlock_achievement("first_equipment")
	save_data()
	equipment_changed.emit()
	return item_name

func equip_companion_item(companion_id: String, item_uid: String) -> bool:
	_ensure_guild_defaults()
	if not companion_roster.has(companion_id):
		return false
	var data: Dictionary = companion_roster[companion_id]
	if str(data.get("state", "disponivel")) == "morto":
		return false
	var equipment: Array = data.get("equipment", [])
	if equipment.has(item_uid) or equipment.size() >= MAX_COMPANION_EQUIPMENT:
		return false
	var item_index := _equipment_index(item_uid)
	if item_index < 0:
		return false
	var item: Dictionary = equipment_inventory[item_index]
	if not str(item.get("equipped_to", "")).is_empty():
		return false
	var equipment_id := str(item.get("equipment_id", ""))
	if not equipment_defs.has(equipment_id):
		return false
	var def: Dictionary = equipment_defs[equipment_id]
	_apply_equipment_bonus(data, def, item, 1.0)
	equipment.append(item_uid)
	data["equipment"] = equipment
	item["equipped_to"] = companion_id
	equipment_inventory[item_index] = item
	companion_roster[companion_id] = data
	save_data()
	companion_roster_changed.emit()
	squad_changed.emit(get_squad_summary())
	equipment_changed.emit()
	return true

func unequip_companion_item(item_uid: String) -> bool:
	_ensure_guild_defaults()
	var item_index := _equipment_index(item_uid)
	if item_index < 0:
		return false
	var item: Dictionary = equipment_inventory[item_index]
	var companion_id := str(item.get("equipped_to", ""))
	if companion_id.is_empty() or not companion_roster.has(companion_id):
		return false
	var data: Dictionary = companion_roster[companion_id]
	var equipment: Array = data.get("equipment", [])
	if not equipment.has(item_uid):
		return false
	var equipment_id := str(item.get("equipment_id", ""))
	if not equipment_defs.has(equipment_id):
		return false
	var def: Dictionary = equipment_defs[equipment_id]
	_apply_equipment_bonus(data, def, item, -1.0)
	equipment.erase(item_uid)
	data["equipment"] = equipment
	item["equipped_to"] = ""
	equipment_inventory[item_index] = item
	companion_roster[companion_id] = data
	save_data()
	companion_roster_changed.emit()
	squad_changed.emit(get_squad_summary())
	equipment_changed.emit()
	return true

func get_equipment_upgrade_cost(item_uid: String) -> int:
	_ensure_guild_defaults()
	var item_index := _equipment_index(item_uid)
	if item_index < 0:
		return 0
	var item: Dictionary = equipment_inventory[item_index]
	var equipment_id := str(item.get("equipment_id", ""))
	if not equipment_defs.has(equipment_id):
		return 0
	var def: Dictionary = equipment_defs[equipment_id]
	var level := int(item.get("level", 1))
	if level >= MAX_EQUIPMENT_LEVEL:
		return 0
	var rarity_multiplier := _equipment_rarity_cost_multiplier(str(item.get("rarity", "comum")))
	return int(round((int(def.get("cost", 0)) * 0.55 + level * 70) * rarity_multiplier))

func get_equipment_reforge_cost(item_uid: String) -> int:
	_ensure_guild_defaults()
	var item_index := _equipment_index(item_uid)
	if item_index < 0:
		return 0
	var item: Dictionary = equipment_inventory[item_index]
	var equipment_id := str(item.get("equipment_id", ""))
	if not equipment_defs.has(equipment_id):
		return 0
	var def: Dictionary = equipment_defs[equipment_id]
	var level := int(item.get("level", 1))
	var rarity_multiplier := _equipment_rarity_cost_multiplier(str(item.get("rarity", "comum")))
	return int(round((int(def.get("cost", 0)) * 0.8 + level * 55) * rarity_multiplier))

func upgrade_equipment(item_uid: String) -> bool:
	_ensure_guild_defaults()
	var item_index := _equipment_index(item_uid)
	if item_index < 0:
		return false
	var item: Dictionary = equipment_inventory[item_index]
	var level := int(item.get("level", 1))
	if level >= MAX_EQUIPMENT_LEVEL:
		return false
	var equipment_id := str(item.get("equipment_id", ""))
	if not equipment_defs.has(equipment_id):
		return false
	var cost := get_equipment_upgrade_cost(item_uid)
	if cost <= 0 or not spend_coins(cost):
		return false
	var def: Dictionary = equipment_defs[equipment_id]
	var companion_id := str(item.get("equipped_to", ""))
	if not companion_id.is_empty() and companion_roster.has(companion_id):
		var data: Dictionary = companion_roster[companion_id]
		_apply_equipment_bonus(data, def, item, -1.0)
		item["level"] = level + 1
		_apply_equipment_bonus(data, def, item, 1.0)
		companion_roster[companion_id] = data
	else:
		item["level"] = level + 1
	equipment_inventory[item_index] = item
	save_data()
	companion_roster_changed.emit()
	squad_changed.emit(get_squad_summary())
	equipment_changed.emit()
	return true

func reforge_equipment(item_uid: String) -> bool:
	_ensure_guild_defaults()
	var item_index := _equipment_index(item_uid)
	if item_index < 0:
		return false
	var item: Dictionary = equipment_inventory[item_index]
	var equipment_id := str(item.get("equipment_id", ""))
	if not equipment_defs.has(equipment_id):
		return false
	var cost := get_equipment_reforge_cost(item_uid)
	if cost <= 0 or not spend_coins(cost):
		return false
	var def: Dictionary = equipment_defs[equipment_id]
	var companion_id := str(item.get("equipped_to", ""))
	if not companion_id.is_empty() and companion_roster.has(companion_id):
		var data: Dictionary = companion_roster[companion_id]
		_apply_equipment_bonus(data, def, item, -1.0)
		item["rarity"] = _roll_reforge_rarity(str(item.get("rarity", "comum")))
		_apply_equipment_bonus(data, def, item, 1.0)
		companion_roster[companion_id] = data
	else:
		item["rarity"] = _roll_reforge_rarity(str(item.get("rarity", "comum")))
	equipment_inventory[item_index] = item
	save_data()
	companion_roster_changed.emit()
	squad_changed.emit(get_squad_summary())
	equipment_changed.emit()
	return true

func get_travel_zones() -> Array:
	_ensure_guild_defaults()
	var zones := {}
	var portal_unlocked := is_fast_travel_unlocked()
	for mission_id in missions.keys():
		var mission: Dictionary = missions[mission_id]
		var zone_id := str(mission.get("zone", ""))
		if zone_id.is_empty():
			continue
		var recommended := int(mission.get("recommended_level", 1))
		if not zones.has(zone_id):
			zones[zone_id] = {
				"id": zone_id,
				"name": str(mission.get("zone_name", zone_id)),
				"recommended_level": recommended,
				"mission_count": 0,
				"unlocked": _is_zone_unlocked(zone_id),
				"travel_available": _is_zone_unlocked(zone_id) and (portal_unlocked or zone_id == selected_travel_zone)
			}
		zones[zone_id]["mission_count"] = int(zones[zone_id]["mission_count"]) + 1
		zones[zone_id]["recommended_level"] = mini(int(zones[zone_id]["recommended_level"]), recommended)
	var result := []
	for zone_id in zones.keys():
		result.append(zones[zone_id])
	result.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["recommended_level"]) < int(b["recommended_level"]))
	return result

func get_selected_travel_zone() -> String:
	_ensure_guild_defaults()
	return selected_travel_zone

func is_fast_travel_unlocked() -> bool:
	return (guild.get("unlocked_structures", []) as Array).has("portal")

func select_travel_zone(zone_id: String) -> bool:
	_ensure_guild_defaults()
	if not _zone_exists(zone_id):
		return false
	if not _is_zone_unlocked(zone_id):
		return false
	if zone_id != selected_travel_zone and not is_fast_travel_unlocked():
		return false
	selected_travel_zone = zone_id
	save_data()
	travel_zone_changed.emit(selected_travel_zone)
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
		"average_luck": float(squad["average_luck"]),
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
		"recommended_level": int(mission.get("recommended_level", 1)),
		"objective_type": "survive",
		"target_kills": 0,
		"target_bosses": 0,
		"target_resources": 0,
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
		"coin_multiplier": 1.0,
		"enemy_sprites": _mission_enemy_sprites(str(mission.get("id", selected_mission_id)), false),
		"boss_sprites": _mission_enemy_sprites(str(mission.get("id", selected_mission_id)), true)
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
		"reputation_reward": 0,
		"leveled_companions": [],
		"unlocked_zones": [],
		"unlocked_zone_names": [],
		"equipment_rewards": [],
		"material_rewards": [],
		"unlocked_achievements": [],
		"campaign_completed": false,
		"campaign_completion_name": "",
		"morale_delta": 0,
		"reroll_reset": false
	}
	if int(recruitment.get("reroll_count", 0)) != 0:
		recruitment["reroll_count"] = 0
		summary["reroll_reset"] = true
	if result_reason == "vitoria":
		_apply_mission_victory_rewards(mission, summary)
		_add_achievement_to_summary(summary, "first_contract")
		if str((mission.get("combat", {}) as Dictionary).get("objective_type", "survive")) == "boss_kill":
			_add_achievement_to_summary(summary, "first_boss")
		_apply_morale_delta(5, summary)
	elif result_reason == "fuga":
		_apply_morale_delta(-3, summary)
	else:
		_apply_morale_delta(-6, summary)
	save_data()
	if result_reason == "vitoria":
		companion_roster_changed.emit()
		squad_changed.emit(get_squad_summary())
		guild_changed.emit()
		if not summary["equipment_rewards"].is_empty():
			equipment_changed.emit()
		if not summary["material_rewards"].is_empty():
			materials_changed.emit()
		mission_changed.emit(selected_mission_id)
	if bool(summary["reroll_reset"]):
		recruitment_changed.emit()
	return summary

func get_squad_summary() -> Dictionary:
	_ensure_guild_defaults()
	var total_level := 0.0
	var total_speed := 0.0
	var total_luck := 0.0
	var count := 0
	for companion_id in active_squad:
		if not companion_roster.has(companion_id):
			continue
		var data: Dictionary = companion_roster[companion_id]
		if str(data.get("state", "disponivel")) == "morto":
			continue
		total_level += float(data.get("level", 1))
		total_speed += float(data.get("speed_rating", 0.0))
		total_luck += float(data.get("luck", 0.0))
		count += 1
	var average_level := total_level / count if count > 0 else 0.0
	var average_speed := total_speed / count if count > 0 else 0.0
	var average_luck := total_luck / count if count > 0 else 0.0
	return {
		"size": count,
		"max_size": MAX_SQUAD_SIZE,
		"average_level": average_level,
		"average_speed": average_speed,
		"average_luck": average_luck,
		"speed_label": classify_squad_speed(average_speed),
		"mobility_warning": get_mobility_warning(average_speed)
	}

func get_morale_label() -> String:
	var morale := int(guild.get("morale", 50))
	if morale < 25:
		return "Abalada"
	if morale < 50:
		return "Tensa"
	if morale < 75:
		return "Estavel"
	return "Inspirada"

func _apply_morale_delta(delta: int, summary: Dictionary = {}) -> void:
	var before := int(guild.get("morale", 50))
	var after: int = clampi(before + delta, 0, 100)
	guild["morale"] = after
	if not summary.is_empty():
		summary["morale_delta"] = after - before

func _unlock_achievement(achievement_id: String) -> bool:
	if not achievement_defs.has(achievement_id):
		return false
	if bool(achievements.get(achievement_id, false)):
		return false
	achievements[achievement_id] = true
	achievement_unlocked.emit(achievement_id)
	return true

func _add_achievement_to_summary(summary: Dictionary, achievement_id: String) -> void:
	if not _unlock_achievement(achievement_id):
		return
	var def: Dictionary = achievement_defs[achievement_id]
	(summary["unlocked_achievements"] as Array).append(str(def.get("name", achievement_id)))

func _check_bestiary_achievements() -> void:
	var total := 0
	for enemy_type in bestiary.keys():
		total += int(bestiary[enemy_type])
	if total >= 25:
		_unlock_achievement("bestiary_25")

func _check_squad_achievements() -> void:
	if active_squad.size() >= MAX_SQUAD_SIZE:
		_unlock_achievement("full_squad")

func _check_roster_achievements() -> void:
	if companion_roster.size() >= 7:
		_unlock_achievement("expanded_roster")

func _check_guild_achievements() -> void:
	if int(guild.get("level", 1)) >= 5:
		_unlock_achievement("guild_level_5")

func _mission_enemy_sprites(mission_id: String, boss: bool) -> Array:
	match mission_id:
		"wolf_cave_scout":
			return ["orc_green_staff", "goblin_green_heavy"] if boss else ["goblin_green_spear", "bat_purple", "goblin_green_heavy"]
		"wolf_cave_alpha_hunt":
			return ["orc_green_staff"] if boss else ["goblin_green_spear", "bat_purple", "goblin_green_heavy"]
		"ancient_ruins_contract":
			return ["necromancer_purple", "dark_knight_red"] if boss else ["cultist_purple_bow", "necromancer_purple", "spider_red"]
		"poison_swamp_purge":
			return ["spider_red", "orc_green_staff"] if boss else ["spider_red", "bat_purple", "cultist_purple_bow"]
		"cursed_graveyard_hunt":
			return ["necromancer_purple", "dark_knight_red"] if boss else ["necromancer_purple", "cultist_purple_bow", "dark_knight_red"]
		"demon_gate_assault":
			return ["demon_red_axe", "dark_knight_red"] if boss else ["demon_red_axe", "cultist_purple_bow", "dark_knight_red"]
		"demon_king_vanguard":
			return ["demon_red_axe", "dark_knight_red"] if boss else ["demon_red_axe", "dark_knight_red", "necromancer_purple"]
		"demon_king_final":
			return ["demon_red_axe"] if boss else ["demon_red_axe", "dark_knight_red", "necromancer_purple"]
	return ["orc_green_staff", "goblin_green_heavy"] if boss else ["goblin_green_spear", "slime_orange", "goblin_green_sword"]

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

func get_lucky_reward_chance(base_chance: float) -> float:
	var average_luck := float(get_squad_summary()["average_luck"])
	return clampf(base_chance * (1.0 + average_luck), 0.0, 1.0)

func _apply_mission_victory_rewards(mission: Dictionary, summary: Dictionary) -> void:
	var active_ids := _rewardable_active_companion_ids()
	var xp_reward := int(round(int(mission.get("xp_reward", 0)) * get_mission_xp_multiplier()))
	var xp_per_companion := int(ceil(float(xp_reward) / max(1, active_ids.size()))) if active_ids.size() > 0 else 0
	var reputation_reward := int(mission.get("reputation_reward", int(mission.get("recommended_level", 1))))
	summary["xp_reward"] = xp_reward
	summary["xp_per_companion"] = xp_per_companion
	summary["reputation_reward"] = reputation_reward
	guild["reputation"] = max(0, int(guild.get("reputation", 0)) + reputation_reward)
	var material_rewards: Dictionary = mission.get("material_rewards", {})
	for material_id in material_rewards.keys():
		var amount := int(material_rewards[material_id])
		if amount <= 0:
			continue
		materials[str(material_id)] = int(materials.get(str(material_id), 0)) + amount
		(summary["material_rewards"] as Array).append("%s x%d" % [get_material_name(str(material_id)), amount])
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
	if bool(mission.get("campaign_completion", false)):
		guild["campaign_completed"] = true
		summary["campaign_completed"] = true
		summary["campaign_completion_name"] = str(mission.get("campaign_completion_name", "Campanha concluida."))
		_add_achievement_to_summary(summary, "demon_king_defeated")
	_roll_mission_equipment_reward(mission, summary)

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
		data["pending_upgrades"] = int(data.get("pending_upgrades", 0)) + 1
		levels_gained += 1
	companion_roster[companion_id] = data
	return {
		"name": str(data.get("name", companion_id)),
		"levels_gained": levels_gained
	}

func _companion_upgrade_choices(class_type: String) -> Array:
	var choices := []
	if class_type == "cleric":
		choices = [
			{"id": "damage", "name": "Cura", "desc": "+12% cura e dano da classe"},
			{"id": "cooldown", "name": "Prece Rapida", "desc": "-7% cooldown da habilidade"},
			{"id": "health", "name": "Vigor", "desc": "+8 vida maxima"},
			{"id": "range", "name": "Area Sagrada", "desc": "+18 alcance"},
			{"id": "speed", "name": "Passos Leves", "desc": "+velocidade do esquadrao"},
			{"id": "ability", "name": "Graca", "desc": "+15% eficiencia da habilidade"}
		]
	else:
		choices = [
			{"id": "damage", "name": "Dano", "desc": "+12% dano da classe"},
			{"id": "cooldown", "name": "Ritmo", "desc": "-7% cooldown de habilidade"},
			{"id": "health", "name": "Vigor", "desc": "+8 vida maxima"},
			{"id": "range", "name": "Alcance", "desc": "+18 alcance de ataque"},
			{"id": "speed", "name": "Mobilidade", "desc": "+velocidade do esquadrao"},
			{"id": "ability", "name": "Tecnica", "desc": "+15% efeito especial"}
		]
	return choices

func _companion_milestone_choice(level: int) -> Dictionary:
	if level >= 20:
		return {"id": "ultimate", "name": "Habilidade Definitiva", "desc": "+40% habilidade e -10% recarga"}
	if level >= 15:
		return {"id": "advanced_power", "name": "Poder Avancado", "desc": "+30% habilidade e +4% critico"}
	if level >= 10:
		return {"id": "specialization", "name": "Especializacao", "desc": "+18% ataque e +1 defesa"}
	if level >= 5:
		return {"id": "ability", "name": "Poder de Classe", "desc": "+15% efeito especial"}
	return {}

func _apply_companion_upgrade_to_data(data: Dictionary, upgrade_id: String) -> bool:
	match upgrade_id:
		"damage":
			data["attack"] = float(data.get("attack", 0.0)) * 1.12
		"cooldown":
			data["cooldown"] = maxf(0.1, float(data.get("cooldown", 1.0)) * 0.93)
		"health":
			data["max_health"] = float(data.get("max_health", 1.0)) + 8.0
			data["current_health"] = float(data.get("max_health", 1.0))
		"range":
			data["range"] = float(data.get("range", 0.0)) + 18.0
		"speed":
			data["move_speed"] = float(data.get("move_speed", 1.0)) + 10.0
			data["speed_rating"] = float(data.get("speed_rating", 0.0)) + 0.35
		"ability":
			data["ability_power"] = float(data.get("ability_power", 1.0)) * 1.15
		"crit":
			data["crit"] = float(data.get("crit", 0.0)) + (0.06 if str(data.get("rarity", "comum")) in ["epico", "lendario"] else 0.04)
		"luck":
			data["luck"] = float(data.get("luck", 0.0)) + (0.08 if str(data.get("rarity", "comum")) == "lendario" else 0.06)
		"specialization":
			data["attack"] = float(data.get("attack", 0.0)) * 1.18
			data["defense"] = float(data.get("defense", 0.0)) + 1.0
		"advanced_power":
			data["ability_power"] = float(data.get("ability_power", 1.0)) * 1.3
			data["crit"] = float(data.get("crit", 0.0)) + 0.04
		"ultimate":
			data["ability_power"] = float(data.get("ability_power", 1.0)) * 1.4
			data["cooldown"] = maxf(0.1, float(data.get("cooldown", 1.0)) * 0.9)
		_:
			return false
	return true

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
	cfg.set_value("guild", "equipment_inventory", equipment_inventory)
	cfg.set_value("guild", "equipment_serial", equipment_serial)
	cfg.set_value("guild", "materials", materials)
	cfg.set_value("guild", "bestiary", bestiary)
	cfg.set_value("guild", "achievements", achievements)
	cfg.set_value("guild", "selected_travel_zone", selected_travel_zone)
	cfg.set_value("guild", "selected_mission_id", selected_mission_id)
	cfg.set_value("settings", "data", settings)
	var err := cfg.save(SAVE_PATH)
	if err == OK:
		save_feedback.emit("Progresso salvo.")

func load_data() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		_backup_corrupt_save_if_needed()
		return
	coins = int(cfg.get_value("save", "coins", coins))
	selected_character = str(cfg.get_value("save", "selected_character", selected_character))
	unlocked_characters = cfg.get_value("save", "unlocked_characters", unlocked_characters)
	permanent_upgrades = cfg.get_value("save", "permanent_upgrades", permanent_upgrades)
	guild = cfg.get_value("guild", "data", guild)
	companion_roster = cfg.get_value("guild", "companion_roster", companion_roster)
	active_squad = cfg.get_value("guild", "active_squad", active_squad)
	recruitment = cfg.get_value("guild", "recruitment", recruitment)
	equipment_inventory = cfg.get_value("guild", "equipment_inventory", equipment_inventory)
	equipment_serial = int(cfg.get_value("guild", "equipment_serial", equipment_serial))
	materials = cfg.get_value("guild", "materials", materials)
	bestiary = cfg.get_value("guild", "bestiary", bestiary)
	achievements = cfg.get_value("guild", "achievements", achievements)
	selected_travel_zone = str(cfg.get_value("guild", "selected_travel_zone", selected_travel_zone))
	selected_mission_id = str(cfg.get_value("guild", "selected_mission_id", selected_mission_id))
	settings = cfg.get_value("settings", "data", settings)
	_ensure_guild_defaults()
	_apply_settings()

func _backup_corrupt_save_if_needed() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
	var backup_path := "%s.corrupt" % absolute_path
	DirAccess.rename_absolute(absolute_path, backup_path)

func _apply_settings() -> void:
	_set_bus_volume("Master", float(settings.get("master_volume", 0.8)))
	_set_bus_volume("Music", float(settings.get("music_volume", 0.8)))
	_set_bus_volume("SFX", float(settings.get("sfx_volume", 0.8)))
	if bool(settings.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var volume := clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, volume <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))

func _ensure_guild_defaults() -> void:
	var needs_trait_migration := not companion_roster.is_empty() and int(guild.get("trait_effects_revision", 0)) < 1
	if guild.is_empty():
		guild = {
			"name": "Guilda Falida",
			"level": 1,
			"reputation": 0,
			"companion_capacity": 12,
			"unlocked_structures": ["hall", "recruitment", "mission_board"],
			"unlocked_zones": ["initial_forest"]
		}
	for key in ["name", "level", "reputation", "morale", "companion_capacity", "campaign_completed", "unlocked_structures", "unlocked_zones"]:
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
	if needs_trait_migration:
		_migrate_legacy_trait_effects()
	guild["trait_effects_revision"] = 1
	for companion_id in companion_roster.keys():
		var companion_data: Dictionary = companion_roster[companion_id]
		if not companion_data.has("pending_upgrades"):
			companion_data["pending_upgrades"] = 0
		if not companion_data.has("equipment"):
			companion_data["equipment"] = []
		if not companion_data.has("training_sessions"):
			companion_data["training_sessions"] = 0
		companion_roster[companion_id] = companion_data
	active_squad = active_squad.filter(func(companion_id):
		var resolved_id := str(companion_id)
		return companion_roster.has(resolved_id) and str(companion_roster[resolved_id].get("state", "disponivel")) != "morto"
	)
	if recruitment.is_empty():
		recruitment = {"available": _generate_recruitment_queue(), "reroll_count": 0}
	if not recruitment.has("available") or recruitment.get("available", []).is_empty():
		recruitment["available"] = _generate_recruitment_queue()
	if not recruitment.has("reroll_count"):
		recruitment["reroll_count"] = 0
	for i in range(equipment_inventory.size()):
		var item: Dictionary = equipment_inventory[i]
		if not item.has("rarity"):
			item["rarity"] = "comum"
		if not item.has("level"):
			item["level"] = 1
		if not item.has("equipped_to"):
			item["equipped_to"] = ""
		equipment_inventory[i] = item
	if not missions.has(selected_mission_id) or not _is_mission_unlocked(missions[selected_mission_id]):
		selected_mission_id = "initial_forest_survival"
	if not _zone_exists(selected_travel_zone) or not _is_zone_unlocked(selected_travel_zone):
		selected_travel_zone = str(missions[selected_mission_id].get("zone", "initial_forest"))
	if not is_fast_travel_unlocked() and selected_travel_zone != "initial_forest":
		selected_travel_zone = "initial_forest"

func _migrate_legacy_trait_effects() -> void:
	for companion_id in companion_roster.keys():
		var data: Dictionary = companion_roster[companion_id]
		var traits: Array = data.get("traits", [])
		if traits.has("cuidadosa"):
			data["defense"] = float(data.get("defense", 0.0)) + 1.25
		if traits.has("curiosa"):
			data["ability_power"] = float(data.get("ability_power", 0.0)) + 0.2
		companion_roster[companion_id] = data

func _default_guild_value(key: String) -> Variant:
	match key:
		"name":
			return "Guilda Falida"
		"level":
			return 1
		"reputation":
			return 0
		"morale":
			return 50
		"companion_capacity":
			return 12
		"campaign_completed":
			return false
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
	if hall_level >= 1:
		structures.append("infirmary")
		structures.append("warehouse")
	if hall_level >= 2:
		structures.append("graveyard")
		structures.append("portal")
		structures.append("blacksmith")
	guild["unlocked_structures"] = structures

func _equipment_index(item_uid: String) -> int:
	for i in range(equipment_inventory.size()):
		var item: Dictionary = equipment_inventory[i]
		if str(item.get("uid", "")) == item_uid:
			return i
	return -1

func _create_equipment_item(equipment_id: String, rarity: String = "") -> Dictionary:
	equipment_serial += 1
	return {
		"uid": "%s_%03d" % [equipment_id, equipment_serial],
		"equipment_id": equipment_id,
		"rarity": _roll_equipment_rarity() if rarity.is_empty() else rarity,
		"level": 1,
		"equipped_to": ""
	}

func _add_equipment_reward(equipment_id: String, rarity: String) -> String:
	if not equipment_defs.has(equipment_id):
		return ""
	var item := _create_equipment_item(equipment_id, rarity)
	equipment_inventory.append(item)
	var def: Dictionary = equipment_defs[equipment_id]
	return "%s %s" % [
		str(def.get("name", equipment_id)),
		str(item.get("rarity", "comum")).capitalize()
	]

func _roll_mission_equipment_reward(mission: Dictionary, summary: Dictionary) -> void:
	var chance := get_lucky_reward_chance(float(mission.get("equipment_reward_chance", 0.0)))
	if chance <= 0.0 or randf() > chance:
		return
	var ids := _drop_equipment_ids(int(mission.get("recommended_level", 1)))
	if ids.is_empty():
		return
	var equipment_id := str(ids.pick_random())
	var item_name := _add_equipment_reward(equipment_id, _roll_mission_equipment_rarity(int(mission.get("recommended_level", 1))))
	if not item_name.is_empty():
		summary["equipment_rewards"].append(item_name)

func _drop_equipment_ids(recommended_level: int) -> Array:
	var result := []
	for equipment_id in equipment_defs.keys():
		var definition: Dictionary = equipment_defs[equipment_id]
		if recommended_level >= int(definition.get("drop_min_level", 1)):
			result.append(equipment_id)
	return result

func _apply_equipment_bonus(data: Dictionary, def: Dictionary, item: Dictionary, direction: float) -> void:
	var bonuses: Dictionary = def.get("bonuses", {})
	var multiplier := _equipment_power_multiplier(item)
	for stat in bonuses.keys():
		var amount := float(bonuses[stat]) * multiplier * direction
		match str(stat):
			"attack":
				data["attack"] = maxf(0.0, float(data.get("attack", 0.0)) + amount)
			"defense":
				data["defense"] = maxf(0.0, float(data.get("defense", 0.0)) + amount)
			"max_health":
				data["max_health"] = maxf(1.0, float(data.get("max_health", 1.0)) + amount)
				if direction > 0.0:
					data["current_health"] = minf(float(data.get("max_health", 1.0)), float(data.get("current_health", data.get("max_health", 1.0))) + amount)
				else:
					data["current_health"] = minf(float(data.get("current_health", data.get("max_health", 1.0))), float(data.get("max_health", 1.0)))
			"move_speed":
				data["move_speed"] = maxf(1.0, float(data.get("move_speed", 1.0)) + amount)
			"speed_rating":
				data["speed_rating"] = maxf(0.0, float(data.get("speed_rating", 0.0)) + amount)
			"range":
				data["range"] = maxf(0.0, float(data.get("range", 0.0)) + amount)
			"ability_power":
				data["ability_power"] = maxf(0.0, float(data.get("ability_power", 0.0)) + amount)
			"cooldown":
				data["cooldown"] = maxf(0.1, float(data.get("cooldown", 1.0)) + amount)

func _equipment_power_multiplier(item: Dictionary) -> float:
	var level_bonus := 1.0 + maxi(0, int(item.get("level", 1)) - 1) * 0.25
	return level_bonus * _equipment_rarity_power_multiplier(str(item.get("rarity", "comum")))

func _equipment_rarity_power_multiplier(rarity: String) -> float:
	match rarity:
		"incomum":
			return 1.12
		"raro":
			return 1.28
		"epico":
			return 1.5
		"lendario":
			return 1.85
	return 1.0

func _equipment_rarity_cost_multiplier(rarity: String) -> float:
	match rarity:
		"incomum":
			return 1.2
		"raro":
			return 1.45
		"epico":
			return 1.8
		"lendario":
			return 2.35
	return 1.0

func _roll_equipment_rarity() -> String:
	var roll := randf()
	var guild_level := int(guild.get("level", 1))
	var legendary_threshold := 0.005 + guild_level * 0.002
	var epic_threshold := 0.035 + guild_level * 0.006
	var rare_threshold := 0.12 + guild_level * 0.015
	var uncommon_threshold := 0.36 + guild_level * 0.025
	if roll < legendary_threshold:
		return "lendario"
	if roll < epic_threshold:
		return "epico"
	if roll < rare_threshold:
		return "raro"
	if roll < uncommon_threshold:
		return "incomum"
	return "comum"

func _roll_mission_equipment_rarity(recommended_level: int) -> String:
	var roll := randf()
	var level_bonus := maxi(0, recommended_level - 1)
	if roll < 0.01 + level_bonus * 0.004:
		return "lendario"
	if roll < 0.05 + level_bonus * 0.012:
		return "epico"
	if roll < 0.18 + level_bonus * 0.03:
		return "raro"
	if roll < 0.48 + level_bonus * 0.04:
		return "incomum"
	return "comum"

func _roll_reforge_rarity(current_rarity: String) -> String:
	var roll := randf()
	match current_rarity:
		"lendario":
			if roll < 0.75:
				return "lendario"
			return "epico"
		"epico":
			if roll < 0.18:
				return "lendario"
			if roll < 0.7:
				return "epico"
			return "raro"
		"raro":
			if roll < 0.08:
				return "epico"
			if roll < 0.5:
				return "raro"
			return "incomum"
		"incomum":
			if roll < 0.08:
				return "raro"
			if roll < 0.58:
				return "incomum"
			return "comum"
	if roll < 0.1:
		return "raro"
	if roll < 0.45:
		return "incomum"
	return "comum"

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
	var data := {
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
		"training_sessions": 0,
		"pending_upgrades": 0,
		"state": "disponivel"
	}
	for trait_id in traits:
		_apply_trait_bonus(data, str(trait_id))
	data["current_health"] = float(data["max_health"])
	return data

func _apply_trait_bonus(data: Dictionary, trait_id: String) -> void:
	if not trait_defs.has(trait_id):
		return
	var bonuses: Dictionary = trait_defs[trait_id].get("bonuses", {})
	for bonus_id in bonuses.keys():
		var amount := float(bonuses[bonus_id])
		match str(bonus_id):
			"cooldown_multiplier":
				data["cooldown"] = float(data.get("cooldown", 1.0)) * amount
			_:
				data[bonus_id] = float(data.get(bonus_id, 0.0)) + amount

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
	var persistent_max_health := maxf(1.0, float(companion_data.get("max_health", base["health"])))
	var runtime_max_health := persistent_max_health * (1.0 + (level - 1) * 0.08) * rarity_multiplier
	var health_ratio := clampf(float(companion_data.get("current_health", persistent_max_health)) / persistent_max_health, 0.01, 1.0)
	result["max_health"] = runtime_max_health
	result["health"] = runtime_max_health * health_ratio
	result["speed"] = float(companion_data.get("move_speed", base["speed"]))
	result["speed_rating"] = float(companion_data.get("speed_rating", base.get("speed_rating", 5.0)))
	result["damage"] = float(companion_data.get("attack", base["damage"])) * (1.0 + (level - 1) * 0.07) * rarity_multiplier
	result["defense"] = float(companion_data.get("defense", base.get("defense", 0.0)))
	result["range"] = float(companion_data.get("range", base["range"]))
	result["cooldown"] = float(companion_data.get("cooldown", base["cooldown"]))
	result["ability_power"] = float(companion_data.get("ability_power", base.get("ability_power", 1.0)))
	result["crit"] = float(companion_data.get("crit", base.get("crit", 0.0)))
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
	return _is_zone_unlocked(zone)

func _is_zone_unlocked(zone_id: String) -> bool:
	var unlocked_zones: Array = guild.get("unlocked_zones", [])
	return unlocked_zones.has(zone_id)

func _zone_exists(zone_id: String) -> bool:
	for mission_id in missions.keys():
		if str(missions[mission_id].get("zone", "")) == zone_id:
			return true
	return false

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
