extends PanelContainer
class_name MenuPanel

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

@export var dark := false

func _ready() -> void:
	MedievalUI.apply_panel(self, dark)
