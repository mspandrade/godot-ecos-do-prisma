extends Control

@onready var coins_label: Label = %CoinsLabel
@onready var status_label: Label = %StatusLabel
@onready var dead_list: VBoxContainer = %DeadList

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.coins_changed.connect(func(_coins: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	for child in dead_list.get_children():
		child.queue_free()
	var dead_companions := GameData.get_dead_companions()
	status_label.text = "Mortos registrados: %d" % dead_companions.size()
	if dead_companions.is_empty():
		var empty := Label.new()
		empty.text = "Nenhum companion no cemiterio."
		dead_list.add_child(empty)
		return
	for companion in dead_companions:
		_add_dead_row(companion)

func _add_dead_row(companion: Dictionary) -> void:
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 126)
	var title := Label.new()
	title.text = "%s | %s %s | Lv %d" % [
		str(companion.get("name", "Companion")),
		str(companion.get("class_name", companion.get("class", ""))),
		str(companion.get("rarity", "comum")).capitalize(),
		int(companion.get("level", 1))
	]
	title.add_theme_font_size_override("font_size", 18)
	var details := Label.new()
	details.text = "Ataque %.1f | Defesa %.1f | Vel %.1f | XP %d/%d" % [
		float(companion.get("attack", 0.0)),
		float(companion.get("defense", 0.0)),
		float(companion.get("speed_rating", 0.0)),
		int(companion.get("xp", 0)),
		int(companion.get("xp_required", 10))
	]
	var button := Button.new()
	var cost := int(companion.get("resurrection_cost", 0))
	button.text = "Ressuscitar - %d moedas" % cost
	button.disabled = GameData.coins < cost
	button.pressed.connect(_resurrect.bind(str(companion["id"])))
	row.add_child(title)
	row.add_child(details)
	row.add_child(button)
	dead_list.add_child(row)

func _resurrect(companion_id: String) -> void:
	if not GameData.resurrect_companion(companion_id):
		_refresh()
