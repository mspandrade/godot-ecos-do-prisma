extends Control
class_name VirtualJoystick

var pointer_id := -1
var mouse_active := false
var direction := Vector2.ZERO
var radius := 82.0

@onready var base: ColorRect = $Base
@onready var knob: ColorRect = $Knob

func _ready() -> void:
	base.size = Vector2(radius * 2.0, radius * 2.0)
	knob.size = Vector2(62, 62)
	_reset_knob()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and pointer_id == -1:
			pointer_id = event.index
			_update_touch(event.position)
		elif not event.pressed and event.index == pointer_id:
			_release()
	elif event is InputEventScreenDrag and event.index == pointer_id:
		_update_touch(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_active = event.pressed
		if mouse_active:
			_update_touch(event.position)
		else:
			_release()
	elif event is InputEventMouseMotion and mouse_active:
		_update_touch(event.position)

func get_direction() -> Vector2:
	return direction

func is_pressed() -> bool:
	return pointer_id != -1 or mouse_active

func _update_touch(local_pos: Vector2) -> void:
	var center := size * 0.5
	var offset := local_pos - center
	direction = offset.limit_length(radius) / radius
	knob.position = center + direction * radius - knob.size * 0.5

func _reset_knob() -> void:
	knob.position = size * 0.5 - knob.size * 0.5

func _release() -> void:
	pointer_id = -1
	mouse_active = false
	direction = Vector2.ZERO
	_reset_knob()
