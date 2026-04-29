extends Node2D
class_name WeaponSystem

signal projectile_requested(pos: Vector2, dir: Vector2, damage: float, speed: float, pierce: int)

var player: Player
var run_state: RunState
var cooldowns := {}
var orbit_angle := 0.0

var weapon_defs := {
	"bolt": {"name": "Dardo Solar", "type": "projectile", "cooldown": 1.1, "damage": 7.0},
	"aura": {"name": "Campo Cinza", "type": "aura", "cooldown": 0.78, "damage": 2.8},
	"orbit": {"name": "Lamina Orbital", "type": "orbit", "cooldown": 0.28, "damage": 3.5},
	"burst": {"name": "Selo de Impacto", "type": "area", "cooldown": 3.25, "damage": 12.0}
}

func setup(p_player: Player, state: RunState) -> void:
	player = p_player
	run_state = state
	run_state.add_weapon_level("bolt")

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not run_state:
		return
	orbit_angle += delta * 2.4
	for id in run_state.weapon_levels.keys():
		cooldowns[id] = float(cooldowns.get(id, 0.0)) - delta
		if cooldowns[id] <= 0.0:
			_fire_weapon(id)

func _fire_weapon(id: String) -> void:
	var level := int(run_state.weapon_levels.get(id, 1))
	var def: Dictionary = weapon_defs[id]
	var cd: float = float(def["cooldown"]) * max(0.45, 1.0 - level * 0.035)
	cooldowns[id] = cd
	match str(def["type"]):
		"projectile":
			_fire_projectile(level)
		"aura":
			_fire_aura(level)
		"orbit":
			_fire_orbit(level)
		"area":
			_fire_area(level)

func _fire_projectile(level: int) -> void:
	var shots := 1 + int(level / 3)
	var target := player.get_nearest_enemy()
	var base_dir := Vector2.RIGHT if target == null else player.global_position.direction_to(target.global_position)
	for i in range(shots):
		var spread := deg_to_rad((i - (shots - 1) * 0.5) * 12.0)
		projectile_requested.emit(player.global_position, base_dir.rotated(spread), _scaled_damage(7.0 + level * 1.6), 620.0, int(level / 4))

func _fire_aura(level: int) -> void:
	var radius := 105.0 + level * 8.0
	_damage_enemies_in_radius(radius, _scaled_damage(2.8 + level * 0.85))
	_flash_ring(radius, Color(0.35, 0.75, 1.0, 0.24))

func _fire_orbit(level: int) -> void:
	var blades: int = min(5, 1 + int(level / 2))
	var radius := 82.0 + level * 3.0
	for i in range(blades):
		var pos := player.global_position + Vector2.RIGHT.rotated(orbit_angle + TAU * i / blades) * radius
		_damage_enemies_in_radius_at(pos, 30.0, _scaled_damage(3.5 + level * 0.7))
		_flash_dot(pos, Color(1.0, 0.55, 0.2, 0.7))

func _fire_area(level: int) -> void:
	var target := player.get_nearest_enemy(780.0)
	var pos := target.global_position if target else player.global_position
	var radius := 78.0 + level * 7.0
	_damage_enemies_in_radius_at(pos, radius, _scaled_damage(12.0 + level * 2.4))
	_flash_ring_at(pos, radius, Color(1.0, 0.8, 0.25, 0.28))

func _damage_enemies_in_radius(radius: float, damage: float) -> void:
	_damage_enemies_in_radius_at(player.global_position, radius, damage)

func _damage_enemies_in_radius_at(pos: Vector2, radius: float, damage: float) -> void:
	var r2 := radius * radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_active and enemy.global_position.distance_squared_to(pos) <= r2:
			enemy.take_damage(damage)

func _scaled_damage(base: float) -> float:
	return base * player.get_damage_multiplier()

func _flash_ring(radius: float, color: Color) -> void:
	_flash_ring_at(player.global_position, radius, color)

func _flash_ring_at(pos: Vector2, radius: float, color: Color) -> void:
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array([Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)])
	ring.color = color
	ring.global_position = pos
	get_tree().current_scene.add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE * 1.25, 0.18)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.18)
	tween.tween_callback(ring.queue_free)

func _flash_dot(pos: Vector2, color: Color) -> void:
	var dot := Polygon2D.new()
	dot.polygon = PackedVector2Array([Vector2(0, -14), Vector2(14, 0), Vector2(0, 14), Vector2(-14, 0)])
	dot.color = color
	dot.global_position = pos
	get_tree().current_scene.add_child(dot)
	var tween := dot.create_tween()
	tween.tween_property(dot, "modulate:a", 0.0, 0.12)
	tween.tween_callback(dot.queue_free)
