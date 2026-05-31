extends Control

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

@onready var list: VBoxContainer = %MissionList
@onready var fast_travel_list: HBoxContainer = %FastTravelList
@onready var title_label: Label = %TitleLabel
@onready var travel_label: Label = %TravelLabel

func _ready() -> void:
	MedievalUI.apply_tree(self)
	MedievalUI.transition_in(self)
	for label in [title_label, travel_label]:
		MedievalUI.apply_body_label(label)
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	GameData.squad_changed.connect(func(_summary: Dictionary): _refresh())
	GameData.mission_changed.connect(func(_mission_id: String): _refresh())
	GameData.travel_zone_changed.connect(func(_zone_id: String): _refresh())
	_refresh()

func _refresh() -> void:
	var selected := GameData.get_selected_mission()
	var selected_zone := GameData.get_selected_travel_zone()
	title_label.text = "Missao selecionada: %s" % str(selected.get("name", "-"))
	travel_label.text = "Regiao atual: %s" % _zone_name(selected_zone)
	if not GameData.is_fast_travel_unlocked():
		travel_label.text += " | Portal disponivel na Guilda Nv 3"
	_refresh_fast_travel(selected_zone)
	for child in list.get_children():
		child.queue_free()
	for mission in GameData.get_missions():
		if str(mission.get("zone", "")) != selected_zone:
			continue
		_add_mission_row(mission)

func _refresh_fast_travel(selected_zone: String) -> void:
	for child in fast_travel_list.get_children():
		child.queue_free()
	for zone in GameData.get_travel_zones():
		var button := Button.new()
		var zone_id := str(zone.get("id", ""))
		button.text = str(zone.get("name", zone_id))
		if bool(zone.get("unlocked", false)) and not bool(zone.get("travel_available", false)):
			button.text += " (Portal)"
		button.disabled = not bool(zone.get("travel_available", false)) or zone_id == selected_zone
		button.custom_minimum_size = Vector2(128, 44)
		MedievalUI.apply_button(button)
		button.pressed.connect(_select_travel_zone.bind(zone_id))
		fast_travel_list.add_child(button)

func _add_mission_row(mission: Dictionary) -> void:
	var readiness := GameData.get_mission_readiness(str(mission["id"]))
	var selected := str(mission["id"]) == str(GameData.get_selected_mission()["id"])
	var card := PanelContainer.new()
	MedievalUI.apply_panel(card, true)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = "%s%s" % [str(mission["name"]), "  Selecionada" if selected else ""]
	title.add_theme_font_size_override("font_size", 18)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", MedievalUI.GOLD if selected else Color("#f2dfb4"))
	var details := Label.new()
	details.text = _format_mission_details(mission, readiness)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	details.clip_text = false
	details.custom_minimum_size = Vector2(0, 126)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_color_override("font_color", Color("#f3dfb8"))
	var warning := Label.new()
	var warnings: Array = readiness["warnings"]
	warning.text = "Aviso: %s" % " ".join(warnings)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.visible = not warnings.is_empty()
	for label in [warning]:
		MedievalUI.apply_body_label(label, false)
		label.add_theme_color_override("font_color", Color("#ead8b2"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	var select_button := Button.new()
	select_button.text = "Selecionar"
	select_button.custom_minimum_size = Vector2(128, 44)
	select_button.disabled = selected or not bool(readiness["unlocked"])
	MedievalUI.apply_button(select_button)
	select_button.pressed.connect(_select_mission.bind(str(mission["id"])))
	var start_button := Button.new()
	start_button.text = "Iniciar"
	start_button.custom_minimum_size = Vector2(128, 44)
	start_button.disabled = not selected or not bool(readiness["can_start"])
	MedievalUI.apply_button(start_button, MedievalUI.WINE if selected else MedievalUI.GOLD)
	start_button.pressed.connect(_start_selected_mission)
	actions.add_child(select_button)
	actions.add_child(start_button)
	row.add_child(title)
	row.add_child(details)
	row.add_child(warning)
	row.add_child(actions)
	card.add_child(row)
	list.add_child(card)

func _select_mission(mission_id: String) -> void:
	GameData.select_mission(mission_id)
	_refresh()

func _select_travel_zone(zone_id: String) -> void:
	GameData.select_travel_zone(zone_id)
	_refresh()

func _start_selected_mission() -> void:
	var readiness := GameData.get_mission_readiness()
	if not bool(readiness["can_start"]):
		return
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _format_duration(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [int(total / 60), total % 60]

func _format_objective(combat: Dictionary) -> String:
	if str(combat.get("objective_type", "survive")) == "kill_count":
		return "%d abates" % int(combat.get("target_kills", 0))
	if str(combat.get("objective_type", "survive")) == "boss_kill":
		return "derrotar %d chefe" % int(combat.get("target_bosses", 1))
	if str(combat.get("objective_type", "survive")) == "collect_resources":
		return "coletar %d suprimentos" % int(combat.get("target_resources", 1))
	if str(combat.get("objective_type", "survive")) == "defense":
		return "defender %d vida" % int(combat.get("target_defense_health", 1))
	return "sobreviver ao timer"

func _format_mission_details(mission: Dictionary, readiness: Dictionary) -> String:
	var combat: Dictionary = mission.get("combat", {})
	var lines := [
		"Descricao: %s" % str(mission.get("description", mission.get("objective", "-"))),
		"Regiao: %s | Level recomendado: %d | Risco: %s (%d%%)" % [
			str(mission.get("zone_name", "-")),
			int(mission.get("recommended_level", 1)),
			str(readiness.get("risk", "Baixo")),
			int(readiness.get("risk_percent", 100))
		],
		"Esquadrao: Lv %.1f | Vel %.1f - %s | Sorte %.0f%%" % [
			float(readiness.get("average_level", 0.0)),
			float(readiness.get("average_speed", 0.0)),
			str(readiness.get("speed_label", "-")),
			float(readiness.get("average_luck", 0.0)) * 100.0
		],
		"Objetivo: %s | Tempo: %s | Inimigos: %s" % [
			_format_objective(combat),
			_format_duration(float(combat.get("duration_seconds", 180.0))),
			", ".join(mission.get("enemies", []))
		],
		"Pressao: hordas %+d | intervalo x%.2f | chefe a cada %s" % [
			int(combat.get("spawn_amount_bonus", 0)),
			float(combat.get("spawn_interval_multiplier", 1.0)),
			_format_duration(float(combat.get("boss_interval", 150.0)))
		],
		"Recompensas: %d moedas | %d XP | %d Rep%s | Equip. %.0f%%%s" % [
			int(mission.get("coin_reward", 0)),
			int(mission.get("xp_reward", 0)),
			int(mission.get("reputation_reward", 0)),
			_format_material_rewards(mission.get("material_rewards", {})),
			float(mission.get("equipment_reward_chance", 0.0)) * 100.0,
			_format_unlock_reward(mission)
		]
	]
	return "\n".join(lines)

func _format_material_rewards(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return ""
	var parts := []
	for material_id in rewards.keys():
		parts.append("%s x%d" % [GameData.get_material_name(str(material_id)), int(rewards[material_id])])
	return " | Mat. " + ", ".join(parts)

func _format_unlock_reward(mission: Dictionary) -> String:
	if mission.has("completion_unlock_zone_name"):
		return " | Desbloqueia: %s" % str(mission.get("completion_unlock_zone_name", ""))
	if mission.has("campaign_completion_name"):
		return " | Final da campanha"
	return ""

func _zone_name(zone_id: String) -> String:
	for zone in GameData.get_travel_zones():
		if str(zone.get("id", "")) == zone_id:
			return str(zone.get("name", zone_id))
	return zone_id
