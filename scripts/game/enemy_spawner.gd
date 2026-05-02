extends Node2D
class_name EnemySpawner

signal enemy_killed(pos: Vector2, xp_value: int, coin_value: int)

@export var enemy_scene: PackedScene
@export var pool_size := 130
@export var spawn_radius := 760.0
@export var despawn_radius := 1250.0
@export var initial_spawn_count := 18
@export var spawns_enabled := true

var player: Node2D
var wave := 1
var elapsed := 0.0
var spawn_timer := 0.0
var boss_timer := 0.0
var pool: Array[Enemy] = []

func setup(target: Node2D) -> void:
	player = target
	for i in range(pool_size):
		var enemy: Enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.killed.connect(_on_enemy_killed)
		enemy.recycled.connect(_recycle_enemy)
		pool.append(enemy)
	if not spawns_enabled:
		return
	for i in range(initial_spawn_count):
		_spawn_enemy(false)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	elapsed += delta
	wave = 1 + int(elapsed / 45.0)
	if not spawns_enabled:
		_despawn_far_enemies()
		return
	spawn_timer -= delta
	boss_timer += delta
	if spawn_timer <= 0.0:
		var amount: int = clamp(4 + int(wave * 0.8), 4, 14)
		for i in range(amount):
			_spawn_enemy(false)
		spawn_timer = max(0.18, 0.95 - wave * 0.045)
	if boss_timer >= 150.0:
		boss_timer = 0.0
		_spawn_enemy(true)
	_despawn_far_enemies()

func _spawn_enemy(boss: bool) -> void:
	if not spawns_enabled:
		return
	var enemy := _get_enemy()
	if enemy == null:
		return
	var angle := randf() * TAU
	var radius := spawn_radius + randf_range(-80.0, 120.0)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * radius
	enemy.spawn(pos, player, wave, boss)

func _get_enemy() -> Enemy:
	for enemy in pool:
		if not enemy.is_active:
			return enemy
	return null

func _despawn_far_enemies() -> void:
	for enemy in pool:
		if enemy.is_active and enemy.global_position.distance_to(player.global_position) > despawn_radius:
			_recycle_enemy(enemy)

func _recycle_enemy(enemy: Enemy) -> void:
	enemy.deactivate()

func _on_enemy_killed(enemy: Enemy, xp_value: int, coin_value: int) -> void:
	enemy_killed.emit(enemy.global_position, xp_value, coin_value)

func set_spawns_enabled(enabled: bool, clear_active_enemies := false) -> void:
	spawns_enabled = enabled
	if clear_active_enemies:
		for enemy in pool:
			if enemy.is_active:
				_recycle_enemy(enemy)
