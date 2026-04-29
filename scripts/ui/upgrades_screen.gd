extends Control

@onready var list: VBoxContainer = %UpgradeList
@onready var coins_label: Label = %CoinsLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
	GameData.coins_changed.connect(func(_c: int): _refresh())
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	for child in list.get_children():
		child.queue_free()
	for id in GameData.upgrade_defs.keys():
		var def: Dictionary = GameData.upgrade_defs[id]
		var level := int(GameData.permanent_upgrades[id])
		var max_level := int(def["max"])
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 52)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s  %d/%d" % [def["name"], level, max_level]
		var button := Button.new()
		button.text = "Max" if level >= max_level else "Comprar %d" % GameData.get_upgrade_cost(id)
		button.disabled = level >= max_level or GameData.coins < GameData.get_upgrade_cost(id)
		button.pressed.connect(_buy.bind(id))
		row.add_child(label)
		row.add_child(button)
		list.add_child(row)

func _buy(id: String) -> void:
	GameData.buy_permanent_upgrade(id)
	_refresh()
