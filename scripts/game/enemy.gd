extends CharacterBody2D
class_name Enemy

const EntitySpriteAtlas := preload("res://scripts/core/entity_sprite_atlas.gd")

signal killed(enemy: Enemy, xp_value: int, coin_value: int)
signal recycled(enemy: Enemy)

var max_health := 12.0
var health := 12.0
var speed := 95.0
var contact_damage := 8.0
var xp_value := 1
var coin_value := 1
var is_boss := false
var is_active := false
var target: Node2D
var knockback_velocity := Vector2.ZERO
var burn_damage_per_second := 0.0
var burn_time := 0.0

@onready var body: Sprite2D = $Body
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	add_to_group("enemies")
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	deactivate()

func spawn(pos: Vector2, player: Node2D, wave: int, boss := false) -> void:
	global_position = pos
	target = player
	is_boss = boss
	var scale_factor := 1.0 + wave * 0.12
	max_health = (75.0 if boss else 10.0) * scale_factor
	health = max_health
	speed = (70.0 if boss else 92.0 + wave * 2.0)
	contact_damage = (18.0 if boss else 7.0 + wave * 0.4)
	xp_value = int(12 + wave * 2) if boss else int(1 + wave * 0.15)
	coin_value = int(35 + wave * 4) if boss else 1
	_apply_spawn_sprite(wave, boss)
	body.modulate = Color.WHITE
	scale = Vector2.ONE * (1.75 if boss else 1.0)
	visible = true
	is_active = true
	knockback_velocity = Vector2.ZERO
	burn_damage_per_second = 0.0
	burn_time = 0.0
	set_physics_process(true)

func deactivate() -> void:
	visible = false
	is_active = false
	set_physics_process(false)
	velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if not is_active:
		return
	var chase_target := _get_chase_target()
	if not is_instance_valid(chase_target):
		return
	if burn_time > 0.0:
		burn_time -= _delta
		take_damage(burn_damage_per_second * _delta)
		body.modulate = Color(1.0, 0.45, 0.18) if not is_boss else Color(1.0, 0.55, 0.2)
	var dir := global_position.direction_to(chase_target.global_position)
	velocity = dir * speed + knockback_velocity
	if velocity.x != 0.0:
		body.flip_h = velocity.x < 0.0
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * _delta)
	move_and_slide()

func take_damage(amount: float) -> void:
	if not is_active:
		return
	health -= amount
	body.modulate = Color(1.0, 1.0, 1.0)
	if health <= 0.0:
		is_active = false
		killed.emit(self, xp_value, coin_value)
		recycled.emit(self)
	else:
		var t := create_tween()
		t.tween_property(body, "modulate", Color(1, 1, 1), 0.04)
		t.tween_property(body, "modulate", Color(1, 1, 1, 1), 0.04)

func get_contact_damage() -> float:
	return contact_damage

func _get_chase_target() -> Node2D:
	var best := target
	var best_dist := INF
	for hero in get_tree().get_nodes_in_group("heroes"):
		if not is_instance_valid(hero):
			continue
		if hero.has_method("is_damage_target") and not hero.is_damage_target():
			continue
		var d := global_position.distance_squared_to(hero.global_position)
		if d < best_dist:
			best_dist = d
			best = hero
	return best

func apply_knockback(direction: Vector2, force: float) -> void:
	if not is_active:
		return
	knockback_velocity += direction.normalized() * force

func apply_burn(damage_per_second: float, duration: float) -> void:
	if not is_active:
		return
	burn_damage_per_second = max(burn_damage_per_second, damage_per_second)
	burn_time = max(burn_time, duration)

func _apply_spawn_sprite(wave: int, boss: bool) -> void:
	var sprite_type := "goblin_green_sword"
	if boss:
		sprite_type = "demon_red_axe" if wave % 2 == 0 else "dark_knight_red"
	elif wave >= 10:
		sprite_type = ["cultist_purple_bow", "necromancer_purple", "spider_red"].pick_random()
	elif wave >= 6:
		sprite_type = ["orc_green_staff", "goblin_green_heavy", "bat_purple"].pick_random()
	elif wave >= 3:
		sprite_type = ["goblin_green_spear", "slime_orange", "goblin_green_sword"].pick_random()
	var names: Array = EntitySpriteAtlas.names_for_type("%s_front_walk" % sprite_type)
	if names.is_empty():
		return
	EntitySpriteAtlas.apply(body, str(names.pick_random()))

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.has_method("get_damage"):
		take_damage(area.owner.get_damage())
		if area.owner.has_method("on_hit"):
			area.owner.on_hit(self)
