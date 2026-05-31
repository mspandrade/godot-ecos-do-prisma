extends PanelContainer
class_name CompanionCard

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

signal toggle_requested(companion_id: String)
signal upgrade_requested(companion_id: String, upgrade_id: String)

var companion_id := ""

@onready var title_label: Label = %TitleLabel
@onready var meta_label: Label = %MetaLabel
@onready var stats_label: Label = %StatsLabel
@onready var traits_label: Label = %TraitsLabel
@onready var upgrade_list: GridContainer = %UpgradeList
@onready var action_button: Button = %ActionButton

func _ready() -> void:
	MedievalUI.apply_panel(self, true)
	MedievalUI.apply_button(action_button)
	MedievalUI.apply_compact_label(title_label, false)
	for label in [meta_label, stats_label, traits_label]:
		MedievalUI.apply_body_label(label, false)
		label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		label.clip_text = false
	action_button.pressed.connect(func(): toggle_requested.emit(companion_id))

func setup(id: String, data: Dictionary, summary: Dictionary, in_squad: bool, choices: Array) -> void:
	companion_id = id
	var rarity := str(data.get("rarity", "comum"))
	title_label.text = "%s%s" % [str(data.get("name", "Companion")), "  Em campo" if in_squad else ""]
	title_label.add_theme_color_override("font_color", MedievalUI.rarity_color(rarity))
	meta_label.text = "%s | %s | Lv %d | %s" % [
		str(data.get("class_name", data.get("class", ""))),
		rarity.capitalize(),
		int(data.get("level", 1)),
		str(data.get("state", "disponivel")).capitalize()
	]
	stats_label.text = "Vida %.0f | Atq %.1f | Def %.1f | Vel %.1f | Alc %.0f | Crit %.0f%% | Sorte %.0f%%" % [
		float(data.get("max_health", 0.0)),
		float(data.get("attack", 0.0)),
		float(data.get("defense", 0.0)),
		float(data.get("speed_rating", 0.0)),
		float(data.get("range", 0.0)),
		float(data.get("crit", 0.0)) * 100.0,
		float(data.get("luck", 0.0)) * 100.0
	]
	var trait_text := []
	for trait_id in data.get("traits", []):
		trait_text.append(GameData.get_trait_effect_text(str(trait_id)))
	traits_label.text = "Traits: %s" % (", ".join(trait_text) if not trait_text.is_empty() else "-")
	action_button.text = "Remover" if in_squad else "Adicionar"
	var state := str(data.get("state", "disponivel"))
	action_button.disabled = not in_squad and (int(summary["size"]) >= int(summary["max_size"]) or state in ["morto", "treinando"])
	if action_button.disabled:
		action_button.tooltip_text = "Sem vaga no esquadrao ou companion indisponivel."
	else:
		action_button.tooltip_text = ""
	_set_upgrade_choices(choices)

func _set_upgrade_choices(choices: Array) -> void:
	for child in upgrade_list.get_children():
		child.queue_free()
	upgrade_list.visible = not choices.is_empty()
	for choice in choices:
		var button := Button.new()
		button.text = str(choice.get("name", choice.get("id", "Upgrade")))
		button.tooltip_text = str(choice.get("desc", ""))
		button.custom_minimum_size = Vector2(128, 44)
		MedievalUI.apply_button(button, MedievalUI.PARCHMENT_DARK)
		button.pressed.connect(func(upgrade_id := str(choice["id"])): upgrade_requested.emit(companion_id, upgrade_id))
		upgrade_list.add_child(button)
