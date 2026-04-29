extends Node2D
class_name XPOrb

signal collected(value: int)
signal recycled(orb: XPOrb)

var value := 1
var coin_value := 0
var target: Node2D
var active := false
var speed := 0.0

@onready var body: Polygon2D = $Body
@onready var area: Area2D = $Area2D

func _ready() -> void:
	body.polygon = PackedVector2Array([Vector2(0, -8), Vector2(10, 0), Vector2(0, 8), Vector2(-10, 0)])
	body.color = Color(0.3, 1.0, 0.65)
	area.area_entered.connect(_on_area_entered)
	deactivate()

func drop(pos: Vector2, xp: int, coins: int) -> void:
	global_position = pos
	value = xp
	coin_value = coins
	target = null
	speed = 0.0
	active = true
	visible = true
	set_process(true)

func magnet_to(player: Node2D) -> void:
	target = player
	speed = 180.0

func _process(delta: float) -> void:
	if not active or not is_instance_valid(target):
		return
	speed += 900.0 * delta
	global_position = global_position.move_toward(target.global_position, speed * delta)
	if global_position.distance_to(target.global_position) < 20.0:
		_collect()

func deactivate() -> void:
	active = false
	visible = false
	set_process(false)

func _collect() -> void:
	if not active:
		return
	active = false
	collected.emit(value)
	if coin_value > 0:
		var run_state := get_tree().get_first_node_in_group("run_state")
		if run_state:
			run_state.add_coins(coin_value)
	recycled.emit(self)

func _on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		_collect()
