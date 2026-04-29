extends RefCounted
class_name GameBalance

static func get_companion_defs() -> Array:
	return [
		{"id": "shield_warrior", "name": "Guerreiro do Escudo", "class": "shield", "health": 30.0, "speed": 210.0, "damage": 4.5, "range": 145.0, "cooldown": 1.35, "ability_power": 0.8, "color": Color(0.35, 0.55, 1.0)},
		{"id": "mage", "name": "Mago", "class": "mage", "health": 18.0, "speed": 200.0, "damage": 4.2, "range": 520.0, "cooldown": 2.1, "ability_power": 0.75, "color": Color(0.75, 0.35, 1.0)},
		{"id": "archer", "name": "Arqueiro", "class": "archer", "health": 22.0, "speed": 215.0, "damage": 5.5, "range": 620.0, "cooldown": 1.25, "ability_power": 0.8, "color": Color(0.95, 0.78, 0.28)},
		{"id": "bard", "name": "Bardo", "class": "bard", "health": 16.0, "speed": 210.0, "damage": 0.0, "range": 0.0, "cooldown": 10.0, "ability_power": 0.7, "color": Color(0.25, 0.95, 0.62)},
		{"id": "cleric", "name": "Clerigo", "class": "cleric", "health": 20.0, "speed": 205.0, "damage": 5.0, "range": 210.0, "cooldown": 6.5, "ability_power": 1.0, "color": Color(0.95, 0.9, 0.55)}
	]

static func get_companion_offsets() -> Array[Vector2]:
	return [
		Vector2(-58, 52),
		Vector2(58, 52),
		Vector2(-86, -18),
		Vector2(86, -18),
		Vector2(0, 96)
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
