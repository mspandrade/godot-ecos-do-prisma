extends Control

@onready var list: VBoxContainer = %CharacterList
@onready var coins_label: Label = %CoinsLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.coins_changed.connect(func(_c: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	GameData.squad_changed.connect(func(_summary: Dictionary): _refresh())
	GameData.recruitment_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	for child in list.get_children():
		child.queue_free()
	_add_section_title("Lider")
	for id in GameData.characters.keys():
		var data: Dictionary = GameData.characters[id]
		var unlocked := bool(GameData.unlocked_characters.get(id, false))
		var row := VBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 98)
		var title := Label.new()
		title.text = "%s%s" % [data["name"], "  Selecionado" if GameData.selected_character == id else ""]
		var stats := Label.new()
		stats.text = "Vida %.0f | Vel %.0f | Dano %.2f | Coleta %.0f" % [data["max_health"], data["speed"], data["damage"], data["pickup_range"]]
		var button := Button.new()
		button.text = "Selecionar" if unlocked else "Desbloquear %d" % int(data["cost"])
		button.disabled = (not unlocked and GameData.coins < int(data["cost"])) or GameData.selected_character == id
		button.pressed.connect(_select.bind(id))
		row.add_child(title)
		row.add_child(stats)
		row.add_child(button)
		list.add_child(row)
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
	_add_section_title("Recrutamento")
	_add_recruitment_controls()

func _select(id: String) -> void:
	GameData.unlock_character(id)
	_refresh()

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
	row.add_child(button)
	list.add_child(row)

func _toggle_companion(companion_id: String) -> void:
	GameData.toggle_companion_in_squad(companion_id)

func _add_recruitment_controls() -> void:
	var reroll_button := Button.new()
	reroll_button.text = "Rolar candidatos - %d moedas" % GameData.get_reroll_cost()
	reroll_button.disabled = GameData.coins < GameData.get_reroll_cost()
	reroll_button.pressed.connect(_reroll_recruits)
	list.add_child(reroll_button)
	var queue := GameData.get_recruitment_queue()
	for i in range(queue.size()):
		_add_recruit_row(i, queue[i])

func _add_recruit_row(index: int, candidate: Dictionary) -> void:
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 112)
	var traits: Array = candidate.get("traits", [])
	var title := Label.new()
	title.text = "%s | %s %s" % [
		str(candidate.get("name", "Recruta")),
		str(candidate.get("class_name", candidate.get("class", ""))),
		str(candidate.get("rarity", "comum")).capitalize()
	]
	var details := Label.new()
	details.text = "Lv %d | Vel %.1f | Habilidade: %s | Traco: %s" % [
		int(candidate.get("level", 1)),
		float(candidate.get("speed_rating", 0.0)),
		str(candidate.get("ability", "-")),
		", ".join(traits)
	]
	var button := Button.new()
	button.text = "Contratar - %d moedas" % int(candidate.get("cost", 0))
	button.disabled = GameData.coins < int(candidate.get("cost", 0)) or GameData.get_companion_roster().size() >= int(GameData.guild.get("companion_capacity", 12))
	button.pressed.connect(_hire_recruit.bind(index))
	row.add_child(title)
	row.add_child(details)
	row.add_child(button)
	list.add_child(row)

func _reroll_recruits() -> void:
	GameData.reroll_recruits()

func _hire_recruit(index: int) -> void:
	GameData.hire_recruit(index)
