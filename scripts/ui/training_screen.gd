extends Control

@onready var coins_label: Label = %CoinsLabel
@onready var companion_option: OptionButton = %CompanionOption
@onready var summary_label: Label = %SummaryLabel
@onready var training_list: VBoxContainer = %TrainingList

var selected_companion_id := ""

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	companion_option.item_selected.connect(_select_companion)
	GameData.coins_changed.connect(func(_coins: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	GameData.training_changed.connect(func(_companion_id: String): _refresh())
	_pick_default_companion()
	_refresh()

func _pick_default_companion() -> void:
	var roster := GameData.get_companion_roster()
	for companion_id in roster.keys():
		var data: Dictionary = roster[companion_id]
		if str(data.get("state", "disponivel")) != "morto":
			selected_companion_id = str(companion_id)
			return
	selected_companion_id = ""

func _refresh() -> void:
	coins_label.text = "Moedas: %d" % GameData.coins
	_refresh_companion_options()
	_refresh_training_list()

func _refresh_companion_options() -> void:
	companion_option.clear()
	var roster := GameData.get_companion_roster()
	var selected_index := -1
	for companion_id in roster.keys():
		var data: Dictionary = roster[companion_id]
		if str(data.get("state", "disponivel")) == "morto":
			continue
		var index := companion_option.get_item_count()
		companion_option.add_item("%s | Lv %d" % [str(data.get("name", companion_id)), int(data.get("level", 1))])
		companion_option.set_item_metadata(index, str(companion_id))
		if str(companion_id) == selected_companion_id:
			selected_index = index
	if selected_index == -1 and companion_option.get_item_count() > 0:
		selected_index = 0
		selected_companion_id = str(companion_option.get_item_metadata(0))
	if selected_index >= 0:
		companion_option.select(selected_index)

func _refresh_training_list() -> void:
	for child in training_list.get_children():
		child.queue_free()
	if selected_companion_id.is_empty():
		summary_label.text = "Nenhum companion disponivel."
		return
	var roster := GameData.get_companion_roster()
	var data: Dictionary = roster[selected_companion_id]
	summary_label.text = "Sessoes: %d | Ataque %.1f | Vida %.0f | Defesa %.1f | Vel %.1f" % [
		int(data.get("training_sessions", 0)),
		float(data.get("attack", 0.0)),
		float(data.get("max_health", 0.0)),
		float(data.get("defense", 0.0)),
		float(data.get("speed_rating", 0.0))
	]
	var cost := GameData.get_training_cost(selected_companion_id)
	for option in GameData.get_training_options():
		var row := VBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 88)
		var title := Label.new()
		title.text = "%s | %s" % [str(option.get("name", "")), str(option.get("desc", ""))]
		title.add_theme_font_size_override("font_size", 17)
		var button := Button.new()
		if GameData.coins < cost:
			button.text = "Faltam %d moedas" % (cost - GameData.coins)
			button.disabled = true
		else:
			button.text = "Treinar - %d moedas" % cost
			button.pressed.connect(_train.bind(str(option.get("id", ""))))
		row.add_child(title)
		row.add_child(button)
		training_list.add_child(row)

func _select_companion(index: int) -> void:
	selected_companion_id = str(companion_option.get_item_metadata(index))
	_refresh_training_list()

func _train(training_id: String) -> void:
	if not GameData.train_companion(selected_companion_id, training_id):
		_refresh()
