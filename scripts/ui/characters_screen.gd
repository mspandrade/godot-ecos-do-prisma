extends Control

@onready var list: VBoxContainer = %CharacterList
@onready var coins_label: Label = %CoinsLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.coins_changed.connect(func(_c: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	GameData.squad_changed.connect(func(_summary: Dictionary): _refresh())
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	for child in list.get_children():
		child.queue_free()
	_add_section_title("Esquadrao")
	var summary := GameData.get_squad_summary()
	var squad_label := Label.new()
	squad_label.text = "%d/%d ativos | Level medio %.1f | Velocidade %.1f - %s" % [
		int(summary["size"]),
		int(summary["max_size"]),
		float(summary["average_level"]),
		float(summary["average_speed"]),
		str(summary["speed_label"])
	]
	list.add_child(squad_label)
	var warning := Label.new()
	warning.text = str(summary["mobility_warning"])
	list.add_child(warning)
	var roster := GameData.get_companion_roster()
	for companion_id in roster.keys():
		_add_companion_row(str(companion_id), roster[companion_id], summary)

func _add_section_title(text: String) -> void:
	var title := Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", 20)
	list.add_child(title)

func _add_companion_row(companion_id: String, data: Dictionary, summary: Dictionary) -> void:
	var in_squad := GameData.is_companion_in_squad(companion_id)
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 106)
	var title := Label.new()
	title.text = "%s%s" % [data["name"], "  No esquadrao" if in_squad else ""]
	var details := Label.new()
	details.text = "%s | %s | Lv %d | Estado: %s" % [
		str(data.get("class_name", data.get("class", ""))),
		str(data.get("rarity", "comum")).capitalize(),
		int(data.get("level", 1)),
		str(data.get("state", "disponivel")).capitalize()
	]
	var pending_upgrades := int(data.get("pending_upgrades", 0))
	if pending_upgrades > 0:
		details.text += " | Melhorias pendentes: %d" % pending_upgrades
	var stats := Label.new()
	stats.text = "Vida %.0f | Ataque %.1f | Defesa %.1f | Vel %.1f | Alcance %.0f" % [
		float(data.get("max_health", 0.0)),
		float(data.get("attack", 0.0)),
		float(data.get("defense", 0.0)),
		float(data.get("speed_rating", 0.0)),
		float(data.get("range", 0.0))
	]
	var button := Button.new()
	button.text = "Remover do esquadrao" if in_squad else "Adicionar ao esquadrao"
	var state := str(data.get("state", "disponivel"))
	button.disabled = not in_squad and (int(summary["size"]) >= int(summary["max_size"]) or state in ["morto", "treinando"])
	button.pressed.connect(_toggle_companion.bind(companion_id))
	row.add_child(title)
	row.add_child(details)
	row.add_child(stats)
	if pending_upgrades > 0:
		_add_pending_upgrade_buttons(row, companion_id)
	row.add_child(button)
	list.add_child(row)

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
