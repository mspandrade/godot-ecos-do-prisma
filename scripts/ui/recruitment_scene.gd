extends Control

@onready var coins_label: Label = %CoinsLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var reroll_button: Button = %RerollButton
@onready var recruit_list: VBoxContainer = %RecruitList

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	reroll_button.pressed.connect(_reroll_recruits)
	GameData.coins_changed.connect(func(_coins: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	GameData.recruitment_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var roster_size := GameData.get_companion_roster().size()
	var capacity := int(GameData.guild.get("companion_capacity", 12))
	var reroll_cost := GameData.get_reroll_cost()
	coins_label.text = "Moedas: %d" % GameData.coins
	capacity_label.text = "Vagas: %d/%d" % [roster_size, capacity]
	reroll_button.text = "Rolar candidatos - %d moedas" % reroll_cost
	reroll_button.disabled = GameData.coins < reroll_cost
	for child in recruit_list.get_children():
		child.queue_free()
	if roster_size >= capacity:
		var warning := Label.new()
		warning.text = "Dormitorios cheios. Aumente a capacidade antes de contratar."
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		recruit_list.add_child(warning)
	var queue := GameData.get_recruitment_queue()
	for i in range(queue.size()):
		_add_recruit_row(i, queue[i], roster_size, capacity)

func _add_recruit_row(index: int, candidate: Dictionary, roster_size: int, capacity: int) -> void:
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 128)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var traits: Array = candidate.get("traits", [])
	var title := Label.new()
	title.text = "%s | %s %s" % [
		str(candidate.get("name", "Recruta")),
		str(candidate.get("class_name", candidate.get("class", ""))),
		str(candidate.get("rarity", "comum")).capitalize()
	]
	title.add_theme_font_size_override("font_size", 18)
	var details := Label.new()
	details.text = "Lv %d | Vel %.1f | Habilidade: %s" % [
		int(candidate.get("level", 1)),
		float(candidate.get("speed_rating", 0.0)),
		str(candidate.get("ability", "-"))
	]
	var traits_label := Label.new()
	traits_label.text = "Traco: %s" % ", ".join(traits)
	var button := Button.new()
	var cost := int(candidate.get("cost", 0))
	button.text = "Contratar - %d moedas" % cost
	button.disabled = GameData.coins < cost or roster_size >= capacity
	button.pressed.connect(_hire_recruit.bind(index))
	row.add_child(title)
	row.add_child(details)
	row.add_child(traits_label)
	row.add_child(button)
	recruit_list.add_child(row)

func _reroll_recruits() -> void:
	if not GameData.reroll_recruits():
		_refresh()

func _hire_recruit(index: int) -> void:
	if not GameData.hire_recruit(index):
		_refresh()
