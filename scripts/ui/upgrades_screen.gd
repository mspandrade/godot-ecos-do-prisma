extends Control

@onready var list: VBoxContainer = %UpgradeList
@onready var coins_label: Label = %CoinsLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.coins_changed.connect(func(_c: int): _refresh())
	GameData.guild_changed.connect(_refresh)
	GameData.permanent_upgrade_changed.connect(func(_upgrade_id: String, _level: int): _refresh())
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d | Guilda Nv %d | Capacidade %d" % [
		GameData.coins,
		int(GameData.guild.get("level", 1)),
		int(GameData.guild.get("companion_capacity", 12))
	]
	for child in list.get_children():
		child.queue_free()
	for id in GameData.upgrade_defs.keys():
		var def: Dictionary = GameData.upgrade_defs[id]
		var level := int(GameData.permanent_upgrades.get(id, 0))
		var max_level := int(def["max"])
		var row := VBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 118)
		var header := HBoxContainer.new()
		var title := Label.new()
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.text = "%s | %s  %d/%d" % [
			str(def.get("category", "Guilda")),
			str(def["name"]),
			level,
			max_level
		]
		title.add_theme_font_size_override("font_size", 18)
		var button := Button.new()
		button.text = "Max" if level >= max_level else "Comprar %d" % GameData.get_upgrade_cost(id)
		button.disabled = level >= max_level or GameData.coins < GameData.get_upgrade_cost(id)
		button.pressed.connect(_buy.bind(id))
		header.add_child(title)
		header.add_child(button)
		var desc := Label.new()
		desc.text = str(def.get("desc", ""))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var effect := Label.new()
		effect.text = str(def.get("effect", ""))
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(header)
		row.add_child(desc)
		row.add_child(effect)
		list.add_child(row)

func _buy(id: String) -> void:
	GameData.buy_permanent_upgrade(id)
	_refresh()
