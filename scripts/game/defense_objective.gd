extends Node2D
class_name DefenseObjective

signal health_changed(current: float, maximum: float)
signal destroyed

@export var max_health := 180.0
@export var contact_radius := 62.0
@export var damage_tick_seconds := 0.55

var health := 180.0
var _damage_tick := 0.0

func _ready() -> void:
	add_to_group("heroes")
	health = max_health
	queue_redraw()
	health_changed.emit(health, max_health)

func setup(value: float) -> void:
	max_health = maxf(1.0, value)
	health = max_health
	health_changed.emit(health, max_health)
	queue_redraw()

func _process(delta: float) -> void:
	if health <= 0.0:
		return
	_damage_tick = maxf(0.0, _damage_tick - delta)
	if _damage_tick > 0.0:
		return
	var highest_damage := 0.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not bool(enemy.get("is_active")):
			continue
		if enemy.global_position.distance_to(global_position) <= contact_radius and enemy.has_method("get_contact_damage"):
			if enemy.has_method("play_attack_animation"):
				enemy.play_attack_animation()
			highest_damage = maxf(highest_damage, float(enemy.get_contact_damage()))
	if highest_damage > 0.0:
		_damage_tick = damage_tick_seconds
		take_damage(highest_damage)

func _draw() -> void:
	var base := Color(0.16, 0.25, 0.34, 0.9)
	var ward := Color(0.45, 0.8, 1.0, 0.85)
	var core := Color(0.9, 0.98, 1.0, 0.95)
	draw_circle(Vector2(0, 8), 42.0, Color(0, 0, 0, 0.18))
	draw_polygon(PackedVector2Array([
		Vector2(0, -58),
		Vector2(30, -22),
		Vector2(22, 30),
		Vector2(0, 48),
		Vector2(-22, 30),
		Vector2(-30, -22)
	]), PackedColorArray([ward, base, base, ward, base, base]))
	draw_circle(Vector2.ZERO, 14.0, core)
	draw_arc(Vector2.ZERO, contact_radius, 0.0, TAU, 48, Color(0.55, 0.9, 1.0, 0.24), 2.0)

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(0.0, health - maxf(1.0, amount))
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0.0:
		remove_from_group("heroes")
		destroyed.emit()

func is_damage_target() -> bool:
	return health > 0.0 and visible
