extends CharacterBody2D
class_name Player

const EntitySpriteAtlas := preload("res://scripts/core/entity_sprite_atlas.gd")

signal health_changed(current: float, maximum: float)
signal died

@export var joystick_path: NodePath

var max_health := 100.0
var health := 100.0
var move_speed := 240.0
var pickup_range := 120.0
var damage_multiplier := 1.0
var run_state: RunState
var last_pickup_bonus := -1.0
var last_health_bonus := -1.0
var contact_tick := 0.0
var invulnerable_time := 0.0
var damage_grace := 1.5
var bard_buff_time := 0.0
var bard_damage_bonus := 0.0
var bard_speed_bonus := 0.0
var base_collision_layer := 0
var base_collision_mask := 0
var base_hit_area_mask := 0
var is_intangible := false
var sprite_type := "rogue_blue_hood"
var sprite_facing := "front"
var walk_frame := 0:
	set(value):
		walk_frame = int(value)
		_apply_walk_frame()

@onready var body: Sprite2D = $Body
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_area: Area2D = $HitArea
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_shape: CollisionShape2D = $PickupArea/CollisionShape2D

func setup(state: RunState) -> void:
	run_state = state
	var stats := GameData.get_selected_stats()
	max_health = float(stats["max_health"])
	health = max_health
	move_speed = float(stats["speed"])
	damage_multiplier = float(stats["damage"])
	pickup_range = float(stats["pickup_range"])
	_update_pickup_range()
	health_changed.emit(health, max_health)

func _ready() -> void:
	add_to_group("heroes")
	base_collision_layer = collision_layer
	base_collision_mask = collision_mask
	base_hit_area_mask = hit_area.collision_mask
	_apply_character_sprite()
	animation_player.play("idle")
	hit_area.area_entered.connect(_on_hit_area_entered)
	pickup_area.area_entered.connect(_on_pickup_area_entered)

func _physics_process(_delta: float) -> void:
	invulnerable_time = max(0.0, invulnerable_time - _delta)
	if is_intangible and invulnerable_time <= 0.0:
		_restore_collision()
	contact_tick -= _delta
	if contact_tick <= 0.0:
		_apply_contact_damage()
		contact_tick = 0.45
	if run_state and last_pickup_bonus != run_state.pickup_bonus:
		_update_pickup_range()
	if run_state and last_health_bonus != run_state.max_health_bonus:
		_update_max_health_bonus()
	if run_state and run_state.regen_per_second > 0.0 and health > 0.0:
		heal(run_state.regen_per_second * _delta)
	bard_buff_time = max(0.0, bard_buff_time - _delta)
	var input := _read_input()
	if input.length() > 1.0:
		input = input.normalized()
	var iso := Vector2(input.x - input.y, (input.x + input.y) * 0.5)
	if iso.length() > 1.0:
		iso = iso.normalized()
	var bonus := run_state.speed_bonus if run_state else 0.0
	velocity = iso * (move_speed + bonus + get_bard_speed_bonus())
	move_and_slide()
	if velocity.x != 0.0:
		body.flip_h = velocity.x < 0.0
	_update_sprite_facing(velocity)
	_update_walk_animation(velocity.length() > 5.0)

func _apply_character_sprite() -> void:
	sprite_type = "rogue_blue_hood"
	match GameData.selected_character:
		"warden":
			sprite_type = "knight_blue_shield"
		"spark":
			sprite_type = "mage_blue"
	_apply_walk_frame()

func _apply_walk_frame() -> void:
	if body:
		EntitySpriteAtlas.apply_entity_frame(body, sprite_type, sprite_facing, "walk", walk_frame)

func _update_sprite_facing(move_velocity: Vector2) -> void:
	var next_facing := "back" if move_velocity.x < -5.0 and move_velocity.y < -5.0 else "front"
	if sprite_facing == next_facing:
		return
	sprite_facing = next_facing
	_apply_walk_frame()

func _update_walk_animation(is_moving: bool) -> void:
	var target_animation := "walk" if is_moving else "idle"
	if animation_player.current_animation != target_animation:
		animation_player.play(target_animation)

func _read_input() -> Vector2:
	if joystick_path != NodePath():
		var joy := get_node_or_null(joystick_path)
		if joy and joy.has_method("get_direction"):
			var joystick_dir: Vector2 = joy.get_direction()
			if joy.has_method("is_pressed") and joy.is_pressed():
				return joystick_dir
			if joystick_dir.length() > 0.05:
				return joystick_dir
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var to_cursor := get_global_mouse_position() - global_position
		if to_cursor.length() > 18.0:
			return _world_to_iso_input(to_cursor.normalized())
	return Vector2.ZERO

func _world_to_iso_input(world_dir: Vector2) -> Vector2:
	var input := Vector2(
		(world_dir.x + world_dir.y * 2.0) * 0.5,
		(world_dir.y * 2.0 - world_dir.x) * 0.5
	)
	return input.normalized() if input.length() > 1.0 else input

func take_damage(amount: float) -> void:
	if invulnerable_time > 0.0 or health <= 0.0:
		return
	var reduction := run_state.damage_reduction if run_state else 0.0
	var final_damage: float = max(1.0, amount * (1.0 - reduction))
	health = max(0.0, health - final_damage)
	invulnerable_time = damage_grace
	_disable_collision()
	_flash_damage()
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()

func is_damage_target() -> bool:
	return health > 0.0

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)

func get_damage_multiplier() -> float:
	var run_bonus := run_state.damage_multiplier if run_state else 1.0
	return damage_multiplier * run_bonus * (1.0 + get_bard_damage_bonus())

func apply_bard_buff(damage_bonus: float, speed_bonus: float, duration: float) -> void:
	bard_damage_bonus = max(bard_damage_bonus, damage_bonus)
	bard_speed_bonus = max(bard_speed_bonus, speed_bonus)
	bard_buff_time = max(bard_buff_time, duration)

func get_bard_damage_bonus() -> float:
	return bard_damage_bonus if bard_buff_time > 0.0 else 0.0

func get_bard_speed_bonus() -> float:
	return bard_speed_bonus if bard_buff_time > 0.0 else 0.0

func get_nearest_enemy(max_distance: float = 900.0) -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best: Node2D
	var best_dist := max_distance * max_distance
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_active:
			continue
		var d := global_position.distance_squared_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best

func _update_pickup_range() -> void:
	var circle := CircleShape2D.new()
	var bonus := run_state.pickup_bonus if run_state else 0.0
	last_pickup_bonus = bonus
	circle.radius = pickup_range + bonus
	pickup_shape.shape = circle

func _update_max_health_bonus() -> void:
	var previous_max := max_health
	var bonus := run_state.max_health_bonus if run_state else 0.0
	last_health_bonus = bonus
	max_health = float(GameData.get_selected_stats()["max_health"]) + bonus
	if max_health > previous_max:
		health += max_health - previous_max
	health = min(health, max_health)
	health_changed.emit(health, max_health)

func _flash_damage() -> void:
	body.modulate = Color(1.0, 0.35, 0.35, 0.75)
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color(1, 1, 1, 0.45), damage_grace * 0.45)
	tween.tween_property(body, "modulate", Color(1, 1, 1, 1), damage_grace * 0.55)

func _disable_collision() -> void:
	is_intangible = true
	collision_layer = 0
	collision_mask = 0
	hit_area.collision_mask = 0

func _restore_collision() -> void:
	is_intangible = false
	collision_layer = base_collision_layer
	collision_mask = base_collision_mask
	hit_area.collision_mask = base_hit_area_mask

func _on_hit_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.has_method("get_contact_damage"):
		take_damage(area.owner.get_contact_damage())
		contact_tick = 0.45

func _apply_contact_damage() -> void:
	var highest_damage := 0.0
	for area in hit_area.get_overlapping_areas():
		if area.owner and area.owner.has_method("get_contact_damage"):
			highest_damage = max(highest_damage, float(area.owner.get_contact_damage()))
	if highest_damage > 0.0:
		take_damage(highest_damage)

func _on_pickup_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.has_method("magnet_to"):
		area.owner.magnet_to(self)
