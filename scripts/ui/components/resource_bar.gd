extends HBoxContainer
class_name ResourceBar

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

@onready var icon_label: Label = %IconLabel
@onready var value_label: Label = %ValueLabel

func _ready() -> void:
	MedievalUI.apply_panel(self, true)

func setup(icon: String, text: String, tooltip := "") -> void:
	icon_label.text = icon
	value_label.text = text
	tooltip_text = tooltip
