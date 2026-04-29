extends Control

@onready var list: VBoxContainer = %CharacterList
@onready var coins_label: Label = %CoinsLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
	GameData.coins_changed.connect(func(_c: int): _refresh())
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	for child in list.get_children():
		child.queue_free()
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

func _select(id: String) -> void:
	GameData.unlock_character(id)
	_refresh()
