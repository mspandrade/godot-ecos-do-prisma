extends PanelContainer
class_name UpgradeOptionCard

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

signal buy_requested(upgrade_id: String)

var upgrade_id := ""

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %DescLabel
@onready var effect_label: Label = %EffectLabel
@onready var buy_button: Button = %BuyButton

func _ready() -> void:
	MedievalUI.apply_panel(self)
	MedievalUI.apply_button(buy_button)
	MedievalUI.apply_compact_label(title_label, true)
	for label in [desc_label, effect_label]:
		MedievalUI.apply_body_label(label, true)
	buy_button.pressed.connect(func(): buy_requested.emit(upgrade_id))

func setup(id: String, def: Dictionary, level: int, max_level: int, cost: int, lock_reason: String, can_buy: bool) -> void:
	upgrade_id = id
	title_label.text = "%s | %s %d/%d" % [
		str(def.get("category", "Guilda")),
		str(def.get("name", id)),
		level,
		max_level
	]
	desc_label.text = str(def.get("desc", ""))
	effect_label.text = str(def.get("effect", ""))
	if not lock_reason.is_empty():
		effect_label.text += " | %s" % lock_reason
	if level >= max_level:
		buy_button.text = "Max"
	elif not lock_reason.is_empty():
		buy_button.text = "Bloqueado"
	else:
		buy_button.text = "Comprar %d" % cost
	buy_button.disabled = not can_buy
