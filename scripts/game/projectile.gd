extends Node2D
class_name Projectile

signal recycled(projectile: Projectile)

var velocity := Vector2.ZERO
var damage := 5.0
var pierce := 0
var lifetime := 1.8
var active := false
var hit_ids := {}

@onready var body: Polygon2D = $Body
@onready var area: Area2D = $Area2D

func _ready() -> void:
	body.polygon = PackedVector2Array([Vector2(16, 0), Vector2(-8, -7), Vector2(-4, 0), Vector2(-8, 7)])
	body.color = Color(1.0, 0.85, 0.25)
	deactivate()

func fire(pos: Vector2, dir: Vector2, p_damage: float, p_speed: float, p_pierce: int) -> void:
	global_position = pos
	velocity = dir.normalized() * p_speed
	damage = p_damage
	pierce = p_pierce
	lifetime = 1.8
	rotation = velocity.angle()
	hit_ids.clear()
	active = true
	visible = true
	set_process(true)

func _process(delta: float) -> void:
	if not active:
		return
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		recycled.emit(self)

func deactivate() -> void:
	active = false
	visible = false
	set_process(false)

func get_damage() -> float:
	return damage

func on_hit(enemy: Node) -> void:
	if hit_ids.has(enemy.get_instance_id()):
		return
	hit_ids[enemy.get_instance_id()] = true
	pierce -= 1
	if pierce < 0:
		recycled.emit(self)

