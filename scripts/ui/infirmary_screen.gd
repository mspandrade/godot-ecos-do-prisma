extends Control

@onready var coins_label: Label = %CoinsLabel
@onready var status_label: Label = %StatusLabel
@onready var wounded_list: VBoxContainer = %WoundedList

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.coins_changed.connect(func(_coins: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	for child in wounded_list.get_children():
		child.queue_free()
	var wounded_companions := GameData.get_wounded_companions()
	status_label.text = "Feridos aguardando tratamento: %d" % wounded_companions.size()
	if wounded_companions.is_empty():
		var empty := Label.new()
		empty.text = "Nenhum companion precisa de tratamento."
		wounded_list.add_child(empty)
		return
	for companion in wounded_companions:
		_add_wounded_row(companion)

func _add_wounded_row(companion: Dictionary) -> void:
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
	var current_health := float(companion.get("current_health", 0.0))
	var max_health := float(companion.get("max_health", 1.0))
	var details := Label.new()
	details.text = "Vida %.0f/%.0f | Ataque %.1f | Vel %.1f" % [
		current_health,
		max_health,
		float(companion.get("attack", 0.0)),
		float(companion.get("speed_rating", 0.0))
	]
	var button := Button.new()
	var cost := int(companion.get("treatment_cost", 0))
	button.text = "Tratar - %d moedas" % cost
	button.disabled = GameData.coins < cost
	button.pressed.connect(_treat.bind(str(companion["id"])))
	row.add_child(title)
	row.add_child(details)
	row.add_child(button)
	wounded_list.add_child(row)

func _treat(companion_id: String) -> void:
	if not GameData.treat_companion(companion_id):
		_refresh()
