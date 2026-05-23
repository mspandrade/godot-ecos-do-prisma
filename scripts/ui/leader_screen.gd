extends Control

@onready var list: VBoxContainer = %LeaderList
@onready var coins_label: Label = %CoinsLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.coins_changed.connect(func(_coins: int): _refresh())
	GameData.character_changed.connect(func(_character_id: String): _refresh())
	GameData.guild_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	for child in list.get_children():
		child.queue_free()
	for character_id in GameData.characters.keys():
		var data: Dictionary = GameData.characters[character_id]
		_add_leader_row(str(character_id), data)

func _add_leader_row(character_id: String, data: Dictionary) -> void:
	var unlocked := bool(GameData.unlocked_characters.get(character_id, false))
	var selected := GameData.selected_character == character_id
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 112)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "%s%s" % [str(data.get("name", character_id)), "  Selecionado" if selected else ""]
	title.add_theme_font_size_override("font_size", 18)
	var stats := Label.new()
	stats.text = "Vida %.0f | Vel %.0f | Dano %.2f | Coleta %.0f" % [
		float(data.get("max_health", 0.0)),
		float(data.get("speed", 0.0)),
		float(data.get("damage", 0.0)),
		float(data.get("pickup_range", 0.0))
	]
	var button := Button.new()
	var cost := int(data.get("cost", 0))
	var missing_coins: int = maxi(0, cost - int(GameData.coins))
	button.text = _leader_button_text(unlocked, selected, cost, missing_coins)
	button.disabled = selected or (not unlocked and missing_coins > 0)
	if not unlocked and missing_coins > 0:
		button.tooltip_text = "Faltam %d moedas." % missing_coins
	button.pressed.connect(_select_leader.bind(character_id))
	row.add_child(title)
	row.add_child(stats)
	row.add_child(button)
	list.add_child(row)

func _leader_button_text(unlocked: bool, selected: bool, cost: int, missing_coins: int) -> String:
	if selected:
		return "Selecionado"
	if unlocked:
		return "Selecionar"
	if missing_coins > 0:
		return "Faltam %d moedas" % missing_coins
	return "Desbloquear - %d moedas" % cost

func _select_leader(character_id: String) -> void:
	GameData.unlock_character(character_id)
	_refresh()
