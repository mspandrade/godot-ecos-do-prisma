extends RefCounted
class_name GameBalance

static func get_companion_defs() -> Array:
	return [
		{"id": "shield_warrior", "name": "Guerreiro", "class": "shield", "rarity": "comum", "level": 1, "state": "disponivel", "health": 32.0, "speed": 218.0, "speed_rating": 6.0, "damage": 4.8, "defense": 4.0, "range": 145.0, "crit": 0.05, "luck": 0.04, "cooldown": 1.35, "ability_power": 0.8, "ability": "Golpe Largo", "passive": "Postura firme", "color": Color(0.35, 0.55, 1.0)},
		{"id": "tank", "name": "Tanque", "class": "tank", "rarity": "comum", "level": 1, "state": "disponivel", "health": 44.0, "speed": 180.0, "speed_rating": 3.0, "damage": 3.4, "defense": 8.0, "range": 110.0, "crit": 0.02, "luck": 0.03, "cooldown": 1.65, "ability_power": 1.1, "ability": "Provocar", "passive": "Armadura pesada", "color": Color(0.55, 0.7, 0.95)},
		{"id": "archer", "name": "Arqueiro", "class": "archer", "rarity": "comum", "level": 1, "state": "disponivel", "health": 22.0, "speed": 230.0, "speed_rating": 7.0, "damage": 5.5, "defense": 2.0, "range": 620.0, "crit": 0.12, "luck": 0.07, "cooldown": 1.25, "ability_power": 0.8, "ability": "Tiro Duplo", "passive": "Olhos atentos", "color": Color(0.95, 0.78, 0.28)},
		{"id": "mage", "name": "Mago", "class": "mage", "rarity": "incomum", "level": 1, "state": "disponivel", "health": 18.0, "speed": 205.0, "speed_rating": 5.0, "damage": 4.2, "defense": 1.0, "range": 520.0, "crit": 0.08, "luck": 0.1, "cooldown": 2.1, "ability_power": 0.75, "ability": "Bola de Fogo", "passive": "Mana instavel", "color": Color(0.75, 0.35, 1.0)},
		{"id": "cleric", "name": "Curandeiro", "class": "cleric", "rarity": "incomum", "level": 1, "state": "disponivel", "health": 20.0, "speed": 205.0, "speed_rating": 5.0, "damage": 5.0, "defense": 2.0, "range": 210.0, "crit": 0.03, "luck": 0.12, "cooldown": 6.5, "ability_power": 1.0, "ability": "Cura Leve", "passive": "Fe serena", "color": Color(0.95, 0.9, 0.55)},
		{"id": "assassin", "name": "Assassino", "class": "assassin", "rarity": "raro", "level": 1, "state": "disponivel", "health": 20.0, "speed": 265.0, "speed_rating": 9.0, "damage": 7.4, "defense": 1.0, "range": 185.0, "crit": 0.24, "luck": 0.08, "cooldown": 1.8, "ability_power": 1.15, "ability": "Investida Sombria", "passive": "Golpe oportunista", "color": Color(0.85, 0.35, 0.48)}
	]

static func get_companion_def_by_class(class_type: String) -> Dictionary:
	for companion_def: Dictionary in get_companion_defs():
		if str(companion_def["class"]) == class_type:
			return companion_def.duplicate(true)
	return get_companion_defs()[0].duplicate(true)

static func get_companion_offsets() -> Array[Vector2]:
	return [
		Vector2(-58, 52),
		Vector2(58, 52),
		Vector2(-86, -18),
		Vector2(86, -18),
		Vector2(0, 96),
		Vector2(0, -82)
	]

static func get_weapon_defs() -> Dictionary:
	return {
		"bolt": {"name": "Dardo Solar", "type": "projectile", "cooldown": 1.1, "damage": 7.0},
		"aura": {"name": "Campo Cinza", "type": "aura", "cooldown": 0.78, "damage": 2.8},
		"orbit": {"name": "Lamina Orbital", "type": "orbit", "cooldown": 0.28, "damage": 3.5},
		"burst": {"name": "Selo de Impacto", "type": "area", "cooldown": 3.25, "damage": 12.0}
	}

static func get_upgrade_defs() -> Array:
	return [
		{"id": "bolt", "kind": "weapon", "name": "Dardo Solar", "desc": "Mais projeteis e dano direcionado."},
		{"id": "aura", "kind": "weapon", "name": "Campo Cinza", "desc": "Pulsa dano ao redor do heroi."},
		{"id": "orbit", "kind": "weapon", "name": "Lamina Orbital", "desc": "Laminas circulam e cortam inimigos."},
		{"id": "burst", "kind": "weapon", "name": "Selo de Impacto", "desc": "Explode uma area perto do alvo."},
		{"id": "might", "kind": "passive", "name": "Foco Marcial", "desc": "Aumenta todo o dano."},
		{"id": "haste", "kind": "passive", "name": "Solado Rapido", "desc": "Aumenta velocidade de movimento."},
		{"id": "magnet", "kind": "passive", "name": "Eco Coletor", "desc": "Aumenta o alcance de coleta."},
		{"id": "vitality", "kind": "passive", "name": "Coracao Prismatico", "desc": "Aumenta a vida maxima durante a run."},
		{"id": "guard", "kind": "passive", "name": "Pele de Pedra", "desc": "Reduz o dano recebido de inimigos."},
		{"id": "renewal", "kind": "passive", "name": "Pulso Vivo", "desc": "Regenera vida aos poucos."}
	]

static func get_weapon_evolutions() -> Dictionary:
	return {
		"bolt": {"passive": "might", "level": 8, "result_name": "Dardo Ascendente"},
		"aura": {"passive": "magnet", "level": 8, "result_name": "Campo Gravitico"},
		"orbit": {"passive": "haste", "level": 8, "result_name": "Danca Cortante"},
		"burst": {"passive": "guard", "level": 8, "result_name": "Selo Cataclismo"}
	}
