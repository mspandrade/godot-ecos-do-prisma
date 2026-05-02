extends CharacterBody2D
class_name Enemy

const EntitySpriteAtlas := preload("res://scripts/core/entity_sprite_atlas.gd")

const AVOIDANCE_DURATION := 0.7
const AVOIDANCE_WEIGHT := 1.35
const STUCK_TIME_TO_SWITCH_SIDE := 0.28
const OBSTACLE_LAYER_MASK := 1 << 4
const OBSTACLE_LOOK_AHEAD := 180.0
const OBSTACLE_RAY_OFFSET := 34.0

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
var avoidance_dir := Vector2.ZERO
var avoidance_time := 0.0
var avoidance_side := 1.0
var stuck_time := 0.0
var burn_damage_per_second := 0.0
var burn_time := 0.0
var sprite_type := "goblin_green_sword"
var sprite_facing := "front"
var sprite_action := "walk"
var walk_frame := 0:
	set(value):
		walk_frame = int(value)
		_apply_sprite_frame()

@onready var body: Sprite2D = $Body
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	add_to_group("enemies")
	animation_player.animation_finished.connect(_on_animation_finished)
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
	sprite_action = "walk"
	animation_player.play("walk")
	knockback_velocity = Vector2.ZERO
	avoidance_dir = Vector2.ZERO
	avoidance_time = 0.0
	stuck_time = 0.0
	burn_damage_per_second = 0.0
	burn_time = 0.0
	set_physics_process(true)

func deactivate() -> void:
	visible = false
	is_active = false
	set_physics_process(false)
	animation_player.play("idle")
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
	var move_dir := _get_steered_direction(dir, _delta)
	var previous_position := global_position
	velocity = move_dir * speed + knockback_velocity
	if velocity.x != 0.0:
		body.flip_h = velocity.x < 0.0
	_update_sprite_facing(velocity)
	_update_walk_animation(velocity.length() > 5.0)
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * _delta)
	move_and_slide()
	_update_obstacle_learning(dir, previous_position, _delta)

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

func _get_steered_direction(desired_dir: Vector2, delta: float) -> Vector2:
	avoidance_time = max(0.0, avoidance_time - delta)
	if desired_dir == Vector2.ZERO:
		return Vector2.ZERO
	var clear_dir := _pick_clear_direction(desired_dir)
	if clear_dir != desired_dir:
		avoidance_dir = clear_dir
		avoidance_time = AVOIDANCE_DURATION
		return clear_dir
	if avoidance_time <= 0.0 or avoidance_dir == Vector2.ZERO:
		return desired_dir
	var steered_dir := (desired_dir + avoidance_dir * AVOIDANCE_WEIGHT).normalized()
	return _pick_clear_direction(steered_dir)

func _pick_clear_direction(desired_dir: Vector2) -> Vector2:
	if not _has_obstacle_ahead(desired_dir, OBSTACLE_LOOK_AHEAD):
		return desired_dir
	var candidate_angles := [
		0.45 * avoidance_side,
		-0.45 * avoidance_side,
		0.9 * avoidance_side,
		-0.9 * avoidance_side,
		1.35 * avoidance_side,
		-1.35 * avoidance_side
	]
	var best_dir := Vector2.ZERO
	var best_score := -INF
	for angle: float in candidate_angles:
		var candidate_dir := desired_dir.rotated(angle).normalized()
		if _has_obstacle_ahead(candidate_dir, OBSTACLE_LOOK_AHEAD * 0.85):
			continue
		var side_bonus := 0.05 if signf(angle) == avoidance_side else 0.0
		var score := candidate_dir.dot(desired_dir) + side_bonus
		if score > best_score:
			best_score = score
			best_dir = candidate_dir
	if best_dir != Vector2.ZERO:
		return best_dir
	return desired_dir.rotated(1.65 * avoidance_side).normalized()

func _has_obstacle_ahead(direction: Vector2, distance: float) -> bool:
	if direction == Vector2.ZERO:
		return false
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var forward := direction.normalized()
	var side := Vector2(-forward.y, forward.x)
	for offset: float in [0.0, -OBSTACLE_RAY_OFFSET, OBSTACLE_RAY_OFFSET]:
		var ray_start := global_position + side * offset
		var ray_end := ray_start + forward * distance
		var query := PhysicsRayQueryParameters2D.create(ray_start, ray_end, OBSTACLE_LAYER_MASK, [get_rid()])
		var hit: Dictionary = space_state.intersect_ray(query)
		if not hit.is_empty():
			return true
	return false

func _update_obstacle_learning(desired_dir: Vector2, previous_position: Vector2, delta: float) -> void:
	if desired_dir == Vector2.ZERO:
		stuck_time = 0.0
		return
	var expected_move: float = maxf(1.0, speed * delta * 0.18)
	var moved: float = global_position.distance_to(previous_position)
	if get_slide_collision_count() == 0:
		stuck_time = stuck_time + delta if moved < expected_move else 0.0
		return
	stuck_time += delta
	var learned_dir := Vector2.ZERO
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		if not _is_obstacle_collision(collision):
			continue
		var normal: Vector2 = collision.get_normal()
		var tangent := Vector2(-normal.y, normal.x)
		if tangent.dot(desired_dir) < 0.0:
			tangent = -tangent
		learned_dir += tangent + normal * 0.45
	if learned_dir == Vector2.ZERO:
		stuck_time = 0.0
		return
	if stuck_time >= STUCK_TIME_TO_SWITCH_SIDE:
		avoidance_side *= -1.0
		learned_dir = learned_dir.rotated(0.65 * avoidance_side)
		stuck_time = 0.0
	avoidance_dir = learned_dir.normalized()
	avoidance_time = AVOIDANCE_DURATION

func _is_obstacle_collision(collision: KinematicCollision2D) -> bool:
	var collider := collision.get_collider()
	if collider == null or not collider.has_method("get_collision_layer"):
		return false
	return (int(collider.get_collision_layer()) & OBSTACLE_LAYER_MASK) != 0

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
	sprite_type = "goblin_green_sword"
	if boss:
		sprite_type = "demon_red_axe" if wave % 2 == 0 else "dark_knight_red"
	elif wave >= 10:
		sprite_type = ["cultist_purple_bow", "necromancer_purple", "spider_red"].pick_random()
	elif wave >= 6:
		sprite_type = ["orc_green_staff", "goblin_green_heavy", "bat_purple"].pick_random()
	elif wave >= 3:
		sprite_type = ["goblin_green_spear", "slime_orange", "goblin_green_sword"].pick_random()
	walk_frame = 0
	_apply_sprite_frame()

func _apply_sprite_frame() -> void:
	if body:
		EntitySpriteAtlas.apply_entity_frame(body, sprite_type, sprite_facing, sprite_action, walk_frame)

func _update_sprite_facing(move_velocity: Vector2) -> void:
	var next_facing := "back" if move_velocity.x < -5.0 and move_velocity.y < -5.0 else "front"
	if sprite_facing == next_facing:
		return
	sprite_facing = next_facing
	_apply_sprite_frame()

func _update_walk_animation(is_moving: bool) -> void:
	if sprite_action == "attack":
		return
	var target_animation := "walk" if is_moving else "idle"
	if animation_player.current_animation != target_animation:
		sprite_action = "walk"
		animation_player.play(target_animation)

func play_attack_animation() -> void:
	if not is_active:
		return
	sprite_action = "attack"
	walk_frame = 0
	animation_player.play("attack")

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != &"attack":
		return
	sprite_action = "walk"
	_apply_sprite_frame()
	_update_walk_animation(velocity.length() > 5.0)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.owner and area.owner.has_method("get_damage"):
		take_damage(area.owner.get_damage())
		if area.owner.has_method("on_hit"):
			area.owner.on_hit(self)
