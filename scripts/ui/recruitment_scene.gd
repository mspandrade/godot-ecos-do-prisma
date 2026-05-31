extends Control

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

@onready var coins_label: Label = %CoinsLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var reroll_button: Button = %RerollButton
@onready var recruit_list: VBoxContainer = %RecruitList

func _ready() -> void:
	MedievalUI.apply_tree(self)
	MedievalUI.transition_in(self)
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
	var card := PanelContainer.new()
	MedievalUI.apply_panel(card, true)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var traits: Array = candidate.get("traits", [])
	var rarity := str(candidate.get("rarity", "comum"))
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "%s | %s %s" % [
		str(candidate.get("name", "Recruta")),
		str(candidate.get("class_name", candidate.get("class", ""))),
		rarity.capitalize()
	]
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	title.add_theme_color_override("font_color", MedievalUI.rarity_color(rarity))
	var button := Button.new()
	var cost := int(candidate.get("cost", 0))
	var disabled_reason := _hire_disabled_reason(cost, roster_size, capacity)
	button.text = _hire_button_text(cost, disabled_reason)
	button.custom_minimum_size = Vector2(150, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.disabled = not disabled_reason.is_empty()
	button.tooltip_text = disabled_reason
	MedievalUI.apply_button(button, MedievalUI.GOLD)
	button.pressed.connect(_hire_recruit.bind(index))
	header.add_child(title)
	header.add_child(button)
	var details := Label.new()
	details.text = _format_candidate_details(candidate, traits)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	details.clip_text = false
	details.custom_minimum_size = Vector2(0, 74)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_color_override("font_color", Color("#f3dfb8"))
	row.add_child(header)
	row.add_child(details)
	card.add_child(row)
	recruit_list.add_child(card)

func _format_candidate_details(candidate: Dictionary, traits: Array) -> String:
	var trait_effects := []
	for trait_id in traits:
		trait_effects.append(GameData.get_trait_effect_text(str(trait_id)))
	return "\n".join([
		"Lv %d | Vel %.1f | Habilidade: %s" % [
			int(candidate.get("level", 1)),
			float(candidate.get("speed_rating", 0.0)),
			str(candidate.get("ability", "-"))
		],
		_candidate_comparison(candidate),
		"Traco: %s" % (", ".join(trait_effects) if not trait_effects.is_empty() else "-")
	])

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
		return "Faltam %d" % max(0, cost - GameData.coins)
	return "Contratar %d" % cost

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
