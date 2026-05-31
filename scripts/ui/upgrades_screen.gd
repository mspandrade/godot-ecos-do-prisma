extends Control

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")
const UpgradeOptionCardScene := preload("res://scenes/ui/components/UpgradeOptionCard.tscn")

@onready var list: VBoxContainer = %UpgradeList
@onready var coins_label: Label = %CoinsLabel

func _ready() -> void:
	MedievalUI.apply_tree(self)
	MedievalUI.transition_in(self)
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
		var lock_reason := GameData.get_upgrade_lock_reason(id)
		var card := UpgradeOptionCardScene.instantiate()
		card.buy_requested.connect(_buy)
		list.add_child(card)
		card.setup(str(id), def, level, max_level, GameData.get_upgrade_cost(str(id)), lock_reason, GameData.can_buy_permanent_upgrade(str(id)))

func _buy(id: String) -> void:
	GameData.buy_permanent_upgrade(id)
	_refresh()
