extends Control

@onready var list: VBoxContainer = %CodexList
@onready var summary_label: Label = %SummaryLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.bestiary_changed.connect(_refresh)
	GameData.achievement_unlocked.connect(func(_achievement_id: String): _refresh())
	_refresh()

func _refresh() -> void:
	for child in list.get_children():
		child.queue_free()
	var bestiary := GameData.get_bestiary()
	var achievements := GameData.get_achievements()
	var achievement_defs := GameData.get_achievement_defs()
	var total := 0
	for enemy_type in bestiary.keys():
		total += int(bestiary[enemy_type])
	summary_label.text = "Inimigos registrados: %d | Tipos: %d | Conquistas: %d/%d" % [
		total,
		bestiary.size(),
		achievements.size(),
		achievement_defs.size()
	]
	_add_section_title("Bestiario")
	if bestiary.is_empty():
		var empty := Label.new()
		empty.text = "Nenhum inimigo registrado."
		list.add_child(empty)
	else:
		var keys := bestiary.keys()
		keys.sort()
		for enemy_type in keys:
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 34)
			var name := Label.new()
			name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name.text = _enemy_display_name(str(enemy_type))
			var count := Label.new()
			count.text = "%d" % int(bestiary[enemy_type])
			row.add_child(name)
			row.add_child(count)
			list.add_child(row)
	_add_section_title("Conquistas")
	for achievement_id in achievement_defs.keys():
		var def: Dictionary = achievement_defs[achievement_id]
		var unlocked := bool(achievements.get(achievement_id, false))
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "%s%s - %s" % [
			"[OK] " if unlocked else "[--] ",
			str(def.get("name", achievement_id)),
			str(def.get("desc", ""))
		]
		list.add_child(label)

func _add_section_title(text: String) -> void:
	var title := Label.new()
	title.text = text
	title.add_theme_font_size_override("font_size", 20)
	list.add_child(title)

func _enemy_display_name(enemy_type: String) -> String:
	return enemy_type.replace("_", " ").capitalize()
