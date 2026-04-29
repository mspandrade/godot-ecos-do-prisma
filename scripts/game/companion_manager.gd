extends Node2D

signal companion_leveled(companion: Node, choices: Array)
signal companion_recruited(companion: Node)

const GameBalanceScript := preload("res://scripts/game/game_balance.gd")

@export var companion_scene: PackedScene
@export var recruit_distance := 92.0

var player: Node2D
var companions: Array[Node] = []
var recruited_companions: Array[Node] = []

var companion_defs := GameBalanceScript.get_companion_defs()
var offsets := GameBalanceScript.get_companion_offsets()

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
