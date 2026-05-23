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
	row.custom_minimum_size = Vector2(0, 156)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var traits: Array = candidate.get("traits", [])
	var rarity := str(candidate.get("rarity", "comum"))
	var title := Label.new()
	title.text = "%s | %s %s" % [
		str(candidate.get("name", "Recruta")),
		str(candidate.get("class_name", candidate.get("class", ""))),
		rarity.capitalize()
	]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", _rarity_color(rarity))
	var details := Label.new()
	details.text = "Lv %d | Vel %.1f | Habilidade: %s" % [
		int(candidate.get("level", 1)),
		float(candidate.get("speed_rating", 0.0)),
		str(candidate.get("ability", "-"))
	]
	var comparison := Label.new()
	comparison.text = _candidate_comparison(candidate)
	comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var traits_label := Label.new()
	traits_label.text = "Traco: %s" % ", ".join(traits)
	var button := Button.new()
	var cost := int(candidate.get("cost", 0))
	var disabled_reason := _hire_disabled_reason(cost, roster_size, capacity)
	button.text = _hire_button_text(cost, disabled_reason)
	button.disabled = not disabled_reason.is_empty()
	button.tooltip_text = disabled_reason
	button.pressed.connect(_hire_recruit.bind(index))
	row.add_child(title)
	row.add_child(details)
	row.add_child(comparison)
	row.add_child(traits_label)
	row.add_child(button)
	recruit_list.add_child(row)

func _candidate_comparison(candidate: Dictionary) -> String:
	var summary := GameData.get_squad_summary()
	var class_type := str(candidate.get("class", ""))
	var candidate_level := int(candidate.get("level", 1))
	var candidate_speed := float(candidate.get("speed_rating", 0.0))
	var squad_size := int(summary.get("size", 0))
	var average_level := float(summary.get("average_level", 0.0))
	var average_speed := float(summary.get("average_speed", 0.0))
	var roster_count := _class_count_in_roster(class_type)
	var squad_count := _class_count_in_squad(class_type)
	if squad_size == 0:
		return "Comparacao: sem esquadrao ativo. Classe no roster: %d." % roster_count
	return "Comparacao: nivel %+.1f e mobilidade %+.1f vs esquadrao. Classe no roster: %d | no esquadrao: %d." % [
		float(candidate_level) - average_level,
		candidate_speed - average_speed,
		roster_count,
		squad_count
	]

func _class_count_in_roster(class_type: String) -> int:
	var count := 0
	var roster := GameData.get_companion_roster()
	for companion_id in roster.keys():
		var data: Dictionary = roster[companion_id]
		if str(data.get("class", "")) == class_type:
			count += 1
	return count

func _class_count_in_squad(class_type: String) -> int:
	var count := 0
	var roster := GameData.get_companion_roster()
	for companion_id in GameData.get_active_squad():
		if not roster.has(companion_id):
			continue
		var data: Dictionary = roster[companion_id]
		if str(data.get("class", "")) == class_type:
			count += 1
	return count

func _hire_disabled_reason(cost: int, roster_size: int, capacity: int) -> String:
	if roster_size >= capacity:
		return "Dormitorios cheios. Melhore a capacidade da guilda."
	if GameData.coins < cost:
		return "Faltam %d moedas." % (cost - GameData.coins)
	return ""

func _hire_button_text(cost: int, disabled_reason: String) -> String:
	if disabled_reason.begins_with("Dormitorios"):
		return "Sem vagas"
	if disabled_reason.begins_with("Faltam"):
		return disabled_reason
	return "Contratar - %d moedas" % cost

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"incomum":
			return Color.html("#77d47b")
		"raro":
			return Color.html("#6fb7ff")
		"epico":
			return Color.html("#c990ff")
		"lendario":
			return Color.html("#f2c14e")
	return Color.html("#d8d3c8")

func _reroll_recruits() -> void:
	if not GameData.reroll_recruits():
		_refresh()

func _hire_recruit(index: int) -> void:
	if not GameData.hire_recruit(index):
		_refresh()
