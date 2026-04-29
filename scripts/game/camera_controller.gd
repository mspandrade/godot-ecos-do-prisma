extends Camera2D
class_name CameraController

@export var target_path: NodePath
@export var follow_speed := 8.0

var target: Node2D

func _ready() -> void:
	target = get_node_or_null(target_path)
	position_smoothing_enabled = false

func set_target(node: Node2D) -> void:
	target = node

func _process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, 1.0 - exp(-follow_speed * delta))
