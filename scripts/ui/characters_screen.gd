extends Control

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")
const CompanionCardScene := preload("res://scenes/ui/components/CompanionCard.tscn")

@onready var list: VBoxContainer = %CharacterList
@onready var coins_label: Label = %CoinsLabel

func _ready() -> void:
	MedievalUI.apply_tree(self)
	MedievalUI.transition_in(self)
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.coins_changed.connect(func(_c: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	GameData.squad_changed.connect(func(_summary: Dictionary): _refresh())
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d | Gerenciamento do esquadrao" % GameData.coins
	for child in list.get_children():
		child.queue_free()
	_add_section_title("Esquadrao")
	var summary := GameData.get_squad_summary()
	var squad_label := Label.new()
	MedievalUI.apply_body_label(squad_label)
	squad_label.text = "%d/%d ativos | Level medio %.1f | Velocidade %.1f - %s | Sorte %.0f%%" % [
		int(summary["size"]),
		int(summary["max_size"]),
		float(summary["average_level"]),
		float(summary["average_speed"]),
		str(summary["speed_label"]),
		float(summary["average_luck"]) * 100.0
	]
	list.add_child(squad_label)
	var warning := Label.new()
	MedievalUI.apply_body_label(warning)
	warning.text = str(summary["mobility_warning"])
	warning.visible = not warning.text.is_empty()
	list.add_child(warning)
	var roster := GameData.get_companion_roster()
	for companion_id in roster.keys():
		_add_companion_row(str(companion_id), roster[companion_id], summary)

func _add_section_title(text: String) -> void:
	var title := Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", 20)
	MedievalUI.apply_title(title, 20)
	list.add_child(title)

func _add_companion_row(companion_id: String, data: Dictionary, summary: Dictionary) -> void:
	var in_squad := GameData.is_companion_in_squad(companion_id)
	var pending_upgrades := int(data.get("pending_upgrades", 0))
	var choices := GameData.get_companion_upgrade_choices(companion_id) if pending_upgrades > 0 else []
	var card := CompanionCardScene.instantiate()
	card.toggle_requested.connect(_toggle_companion)
	card.upgrade_requested.connect(_apply_companion_upgrade)
	list.add_child(card)
	card.setup(companion_id, data, summary, in_squad, choices)

func _toggle_companion(companion_id: String) -> void:
	GameData.toggle_companion_in_squad(companion_id)

func _add_pending_upgrade_buttons(row: VBoxContainer, companion_id: String) -> void:
	var choices := GameData.get_companion_upgrade_choices(companion_id)
	if choices.is_empty():
		return
	var label := Label.new()
	label.text = "Escolha uma melhoria:"
	row.add_child(label)
	var actions := HBoxContainer.new()
	for choice in choices:
		var button := Button.new()
		button.text = str(choice.get("name", choice.get("id", "Upgrade")))
		button.tooltip_text = str(choice.get("desc", ""))
		button.pressed.connect(_apply_companion_upgrade.bind(companion_id, str(choice["id"])))
		actions.add_child(button)
	row.add_child(actions)

func _apply_companion_upgrade(companion_id: String, upgrade_id: String) -> void:
	GameData.apply_companion_pending_upgrade(companion_id, upgrade_id)
