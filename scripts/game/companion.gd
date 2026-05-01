extends CharacterBody2D

const EntitySpriteAtlas := preload("res://scripts/core/entity_sprite_atlas.gd")

signal leveled_up(companion: Node, choices: Array)
signal health_changed(companion: Node, current: float, maximum: float)

var companion_id := "shield_warrior"
var display_name := "Guerreiro do Escudo"
var class_type := "shield"
var level := 1
var xp := 0
var xp_required := 10
var max_health := 34.0
var health := 34.0
var move_speed := 210.0
var attack_damage := 5.0
var attack_range := 115.0
var attack_cooldown := 1.35
var attack_timer := 0.0
var ability_power := 1.0
var follow_offset := Vector2.ZERO
var player: Node2D
var contact_tick := 0.0
var is_down := false
var is_recruited := false
var is_invulnerable := false
var shield_charge_state := "idle"
var shield_charge_target := Vector2.ZERO
var spawn_grace_time := 0.0
var base_collision_layer := 0
var base_collision_mask := 0
const MAX_LEASH_DISTANCE := 420.0
var sprite_type := "knight_blue_shield"
var sprite_facing := "front"
var walk_frame := 0:
	set(value):
		walk_frame = int(value)
		_apply_walk_frame()

@onready var body: Sprite2D = $Body
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func setup(data: Dictionary, p_player: Node2D, offset: Vector2) -> void:
	companion_id = str(data["id"])
	display_name = str(data["name"])
	class_type = str(data["class"])
	player = p_player
	follow_offset = offset
	max_health = float(data["health"])
	health = max_health
	move_speed = float(data["speed"])
	attack_damage = float(data["damage"])
	attack_range = float(data["range"])
	attack_cooldown = float(data["cooldown"])
	attack_timer = randf_range(0.12, 0.45)
	ability_power = float(data.get("ability_power", 1.0))
	scale = Vector2.ONE
	base_collision_layer = collision_layer
	base_collision_mask = collision_mask

func _ready() -> void:
	_apply_class_sprite()
	add_to_group("companions")
	body.modulate = Color(1.0, 1.0, 1.0, 0.62)
	animation_player.play("idle")

func _class_sprite_type() -> String:
	match class_type:
		"shield":
			return "knight_blue_shield"
		"mage":
			return "mage_blue"
		"archer":
			return "ranger_blue_bow"
		"bard":
			return "necromancer_purple"
		"cleric":
			return "mage_blue"
	return "knight_blue_shield"

func _apply_class_sprite() -> void:
	sprite_type = _class_sprite_type()
	_apply_walk_frame()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if not is_recruited:
		velocity = Vector2.ZERO
		_update_walk_animation(false)
		return
	if is_down:
		_update_walk_animation(false)
		return
	spawn_grace_time = max(0.0, spawn_grace_time - delta)
	_keep_in_formation()
	if shield_charge_state != "idle":
		_process_shield_charge(delta)
	else:
		_follow_player(delta)
	contact_tick -= delta
	if contact_tick <= 0.0:
		_apply_contact_damage()
		contact_tick = 0.6
	attack_timer -= delta
	if attack_timer <= 0.0 and shield_charge_state == "idle":
		_use_class_action()
		attack_timer = max(0.25, attack_cooldown)

func _follow_player(_delta: float) -> void:
	var target_pos := player.global_position + follow_offset
	var dist := global_position.distance_to(target_pos)
	if dist > 12.0:
		velocity = global_position.direction_to(target_pos) * min(move_speed, dist * 5.0)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	if velocity.x != 0.0:
		body.flip_h = velocity.x < 0.0
	_update_sprite_facing(velocity)
	_update_walk_animation(velocity.length() > 5.0)

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

func add_xp(amount: int) -> void:
	if is_down or not is_recruited:
		return
	xp += amount
	if xp >= xp_required:
		xp -= xp_required
		level += 1
		xp_required = int(xp_required * 1.28 + 6)
		health = max_health
		health_changed.emit(self, health, max_health)
		leveled_up.emit(self, get_upgrade_choices())

func get_upgrade_choices() -> Array:
	var choices := []
	if class_type == "cleric":
		choices = [
			{"id": "damage", "name": "Cura", "desc": "+12% quantidade de cura"},
			{"id": "cooldown", "name": "Prece Rapida", "desc": "-7% cooldown de cura"},
			{"id": "health", "name": "Vigor", "desc": "+8 vida maxima"},
			{"id": "range", "name": "Area Sagrada", "desc": "+18 area de cura"},
			{"id": "ability", "name": "Graca", "desc": "+15% eficiencia da cura"}
		]
	else:
		choices = [
			{"id": "damage", "name": "Dano", "desc": "+12% dano da classe"},
			{"id": "cooldown", "name": "Ritmo", "desc": "-7% cooldown de habilidade"},
			{"id": "health", "name": "Vigor", "desc": "+8 vida maxima"},
			{"id": "range", "name": "Alcance", "desc": "+18 alcance de ataque"}
		]
	if class_type == "bard":
		choices.append({"id": "ability", "name": "Inspiracao", "desc": "+15% forca do buff"})
	elif class_type != "cleric":
		choices.append({"id": "ability", "name": "Tecnica", "desc": "+15% efeito especial"})
	choices.shuffle()
	return choices.slice(0, 3)

func apply_upgrade(upgrade_id: String) -> void:
	if is_down or not is_recruited:
		return
	match upgrade_id:
		"damage":
			attack_damage *= 1.12
		"cooldown":
			attack_cooldown *= 0.93
		"health":
			max_health += 8.0
			health = max_health
		"range":
			attack_range += 18.0
		"ability":
			ability_power *= 1.15

func _use_class_action() -> void:
	match class_type:
		"shield":
			_shield_attack()
		"mage":
			_mage_attack()
		"archer":
			_archer_attack()
		"bard":
			_bard_buff()
		"cleric":
			_cleric_heal()

func take_damage(amount: float) -> void:
	if is_down or not is_recruited or spawn_grace_time > 0.0 or is_invulnerable:
		return
	health = max(0.0, health - amount)
	if health <= 0.0:
		_fall()
	else:
		body.modulate = Color(1.0, 0.4, 0.4, 0.85)
		var tween := create_tween()
		tween.tween_property(body, "modulate", Color.WHITE, 0.16)
	health_changed.emit(self, health, max_health)

func heal(amount: float) -> void:
	if is_down or not is_recruited or health >= max_health:
		return
	health = min(max_health, health + amount)
	if body:
		body.modulate = Color(0.95, 1.0, 0.55, 0.9)
		var tween := create_tween()
		tween.tween_property(body, "modulate", Color.WHITE, 0.18)
	health_changed.emit(self, health, max_health)

func is_damage_target() -> bool:
	return is_recruited and not is_down and health > 0.0 and visible

func _apply_contact_damage() -> void:
	if is_down:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_active and enemy.global_position.distance_to(global_position) < 46.0:
			take_damage(enemy.get_contact_damage())
			return

func _fall() -> void:
	is_down = true
	velocity = Vector2.ZERO
	visible = false
	collision_layer = 0
	collision_mask = 0
	remove_from_group("heroes")
	health_changed.emit(self, health, max_health)

func recruit(new_offset: Vector2) -> void:
	if is_recruited or is_down:
		return
	is_recruited = true
	follow_offset = new_offset
	health = max_health
	_snap_to_formation()
	body.modulate = Color.WHITE
	animation_player.play("idle")
	add_to_group("heroes")
	spawn_grace_time = 1.2
	attack_timer = randf_range(0.12, 0.45)
	health_changed.emit(self, health, max_health)

func _keep_in_formation() -> void:
	if global_position.distance_to(player.global_position) > MAX_LEASH_DISTANCE:
		_snap_to_formation()

func _snap_to_formation() -> void:
	global_position = player.global_position + follow_offset
	velocity = Vector2.ZERO

func _shield_attack() -> void:
	var enemy := _nearest_enemy(attack_range)
	if not enemy:
		return
	var direction := global_position.direction_to(enemy.global_position)
	shield_charge_target = global_position + direction * min(attack_range, 150.0)
	shield_charge_state = "out"
	is_invulnerable = true
	_flash_line(global_position, shield_charge_target, Color(0.55, 0.75, 1.0, 0.75), 7.0)

func _process_shield_charge(delta: float) -> void:
	var destination := shield_charge_target
	if shield_charge_state == "return":
		destination = player.global_position + follow_offset
	var speed := 520.0 + ability_power * 90.0
	global_position = global_position.move_toward(destination, speed * delta)
	velocity = Vector2.ZERO
	if shield_charge_state == "out":
		_damage_charge_contacts()
		if global_position.distance_to(destination) <= 8.0:
			shield_charge_state = "return"
	elif global_position.distance_to(destination) <= 10.0:
		shield_charge_state = "idle"
		is_invulnerable = false
		_snap_to_formation()

func _damage_charge_contacts() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_active and enemy.global_position.distance_to(global_position) < 58.0:
			enemy.take_damage(attack_damage)
			enemy.apply_knockback(global_position.direction_to(enemy.global_position), 280.0 * ability_power)
			_flash(enemy.global_position, Color(0.55, 0.75, 1.0, 0.5), 24.0)

func _mage_attack() -> void:
	var enemy := _nearest_enemy(attack_range)
	if not enemy:
		return
	var radius := 92.0 + level * 3.0
	for target in get_tree().get_nodes_in_group("enemies"):
		if target.is_active and target.global_position.distance_to(enemy.global_position) <= radius:
			target.take_damage(attack_damage * 0.75)
			target.apply_burn(attack_damage * 0.45 * ability_power, 2.5)
	_flash_line(global_position, enemy.global_position, Color(0.8, 0.35, 1.0, 0.8), 5.0)
	_flash(enemy.global_position, Color(0.75, 0.35, 1.0, 0.35), radius)

func _archer_attack() -> void:
	var enemy := _nearest_enemy(attack_range)
	if not enemy:
		return
	enemy.take_damage(attack_damage * 1.35)
	_flash_line(global_position, enemy.global_position, Color(1.0, 0.86, 0.32, 0.85), 3.0)
	_flash(enemy.global_position, Color(0.9, 0.8, 0.35, 0.55), 16.0)

func _bard_buff() -> void:
	if player:
		player.apply_bard_buff(0.08 * ability_power, 18.0 * ability_power, 4.0)
		_flash(player.global_position, Color(0.35, 1.0, 0.65, 0.28), 90.0)

func _cleric_heal() -> void:
	if not player:
		return
	if _heal_companion_targets(get_tree().get_nodes_in_group("companions")):
		_flash(player.global_position, Color(0.95, 1.0, 0.55, 0.26), attack_range)

func _heal_companion_targets(targets: Array) -> bool:
	var healed_any := false
	var heal_amount := attack_damage * ability_power
	for companion in targets:
		if companion == self or not companion.is_recruited or companion.is_down:
			continue
		if companion.global_position.distance_to(player.global_position) > attack_range:
			continue
		var before: float = companion.health
		companion.heal(heal_amount)
		healed_any = healed_any or companion.health > before
	return healed_any

func _nearest_enemy(max_distance: float) -> Node2D:
	var best: Node2D
	var best_dist := max_distance * max_distance
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_active:
			continue
		var d := global_position.distance_squared_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best

func _flash_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.points = PackedVector2Array([from, to])
	_effect_parent().add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.14)
	tween.tween_callback(line.queue_free)

func _flash(pos: Vector2, color: Color, radius: float) -> void:
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)])
	marker.color = color
	marker.global_position = pos
	_effect_parent().add_child(marker)
	var tween := marker.create_tween()
	tween.tween_property(marker, "modulate:a", 0.0, 0.18)
	tween.tween_callback(marker.queue_free)

func _effect_parent() -> Node:
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_tree().root
