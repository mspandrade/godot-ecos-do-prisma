extends Button
class_name MedievalButton

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

@export var accent_color := MedievalUI.GOLD

func _ready() -> void:
	MedievalUI.apply_button(self, accent_color)
	pressed.connect(_pulse)

func _pulse() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.97, 0.97), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
