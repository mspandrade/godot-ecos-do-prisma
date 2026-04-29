extends Node2D

signal companion_leveled(companion: Node, choices: Array)
signal companion_recruited(companion: Node)

@export var companion_scene: PackedScene
@export var recruit_distance := 92.0

var player: Node2D
var companions: Array[Node] = []
var recruited_companions: Array[Node] = []

var companion_defs := [
	{"id": "shield_warrior", "name": "Guerreiro do Escudo", "class": "shield", "health": 30.0, "speed": 210.0, "damage": 4.5, "range": 145.0, "cooldown": 1.35, "ability_power": 0.8, "color": Color(0.35, 0.55, 1.0)},
	{"id": "mage", "name": "Mago", "class": "mage", "health": 18.0, "speed": 200.0, "damage": 4.2, "range": 520.0, "cooldown": 2.1, "ability_power": 0.75, "color": Color(0.75, 0.35, 1.0)},
	{"id": "archer", "name": "Arqueiro", "class": "archer", "health": 22.0, "speed": 215.0, "damage": 5.5, "range": 620.0, "cooldown": 1.25, "ability_power": 0.8, "color": Color(0.95, 0.78, 0.28)},
	{"id": "bard", "name": "Bardo", "class": "bard", "health": 16.0, "speed": 210.0, "damage": 0.0, "range": 0.0, "cooldown": 10.0, "ability_power": 0.7, "color": Color(0.25, 0.95, 0.62)},
	{"id": "cleric", "name": "Clerigo", "class": "cleric", "health": 20.0, "speed": 205.0, "damage": 5.0, "range": 210.0, "cooldown": 6.5, "ability_power": 1.0, "color": Color(0.95, 0.9, 0.55)}
]

var offsets := [
	Vector2(-58, 52),
	Vector2(58, 52),
	Vector2(-86, -18),
	Vector2(86, -18),
	Vector2(0, 96)
]

func setup(p_player: Node2D) -> void:
	player = p_player
	for i in range(companion_defs.size()):
		var companion: Node = companion_scene.instantiate()
		companion.setup(companion_defs[i], player, offsets[i])
		companion.global_position = player.global_position + _lost_spawn_offset(i)
		add_child(companion)
		companion.leveled_up.connect(_on_companion_leveled)
		companions.append(companion)

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	for companion in companions:
		if companion.is_recruited or companion.is_down:
			continue
		if companion.global_position.distance_to(player.global_position) <= recruit_distance:
			_recruit_companion(companion)

func distribute_xp(amount: int) -> void:
	for companion in recruited_companions:
		if not companion.is_down:
			companion.add_xp(max(1, int(ceil(amount * 0.45))))

func apply_companion_upgrade(companion: Node, upgrade: Dictionary) -> void:
	if is_instance_valid(companion):
		companion.apply_upgrade(str(upgrade["id"]))
		if companion.has_signal("health_changed"):
			companion.health_changed.emit(companion, companion.health, companion.max_health)

func _on_companion_leveled(companion: Node, choices: Array) -> void:
	companion_leveled.emit(companion, choices)

func _recruit_companion(companion: Node) -> void:
	var slot := recruited_companions.size()
	var offset: Vector2 = offsets[min(slot, offsets.size() - 1)]
	companion.recruit(offset)
	recruited_companions.append(companion)
	companion_recruited.emit(companion)

func _lost_spawn_offset(index: int) -> Vector2:
	var angle: float = TAU * index / max(1, companion_defs.size()) + randf_range(-0.35, 0.35)
	var distance: float = randf_range(720.0, 1350.0)
	return Vector2(cos(angle), sin(angle)) * distance
