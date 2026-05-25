extends Control

@onready var list: VBoxContainer = %MissionList
@onready var fast_travel_list: HBoxContainer = %FastTravelList
@onready var title_label: Label = %TitleLabel
@onready var travel_label: Label = %TravelLabel

func _ready() -> void:
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
		button.pressed.connect(_select_travel_zone.bind(zone_id))
		fast_travel_list.add_child(button)

func _add_mission_row(mission: Dictionary) -> void:
	var readiness := GameData.get_mission_readiness(str(mission["id"]))
	var selected := str(mission["id"]) == str(GameData.get_selected_mission()["id"])
	var row := VBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 182)
	var title := Label.new()
	title.text = "%s%s" % [str(mission["name"]), "  Selecionada" if selected else ""]
	title.add_theme_font_size_override("font_size", 18)
	var meta := Label.new()
	meta.text = "%s | Level recomendado %d | Risco %s" % [
		str(mission["zone_name"]),
		int(mission["recommended_level"]),
		str(readiness["risk"])
	]
	var squad := Label.new()
	squad.text = "Seu esquadrao: Lv %.1f | Vel %.1f - %s" % [
		float(readiness["average_level"]),
		float(readiness["average_speed"]),
		str(readiness["speed_label"])
	]
	var enemies := Label.new()
	enemies.text = "Inimigos previstos: %s" % ", ".join(mission.get("enemies", []))
	var rewards := Label.new()
	var combat: Dictionary = mission.get("combat", {})
	rewards.text = "Objetivo: %s | Duracao: %s | Recompensas: %d moedas | %d XP | %d Rep%s" % [
		_format_objective(combat),
		_format_duration(float(combat.get("duration_seconds", 180.0))),
		int(mission["coin_reward"]),
		int(mission["xp_reward"]),
		int(mission.get("reputation_reward", 0)),
		_format_material_rewards(mission.get("material_rewards", {}))
	]
	rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var warning := Label.new()
	var warnings: Array = readiness["warnings"]
	warning.text = "Aviso: %s" % " ".join(warnings)
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var actions := HBoxContainer.new()
	var select_button := Button.new()
	select_button.text = "Selecionar"
	select_button.disabled = selected or not bool(readiness["unlocked"])
	select_button.pressed.connect(_select_mission.bind(str(mission["id"])))
	var start_button := Button.new()
	start_button.text = "Iniciar"
	start_button.disabled = not selected or not bool(readiness["can_start"])
	start_button.pressed.connect(_start_selected_mission)
	actions.add_child(select_button)
	actions.add_child(start_button)
	row.add_child(title)
	row.add_child(meta)
	row.add_child(squad)
	row.add_child(enemies)
	row.add_child(rewards)
	row.add_child(warning)
	row.add_child(actions)
	list.add_child(row)

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
	return "sobreviver ao timer"

func _format_material_rewards(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return ""
	var parts := []
	for material_id in rewards.keys():
		parts.append("%s x%d" % [GameData.get_material_name(str(material_id)), int(rewards[material_id])])
	return " | " + ", ".join(parts)

func _zone_name(zone_id: String) -> String:
	for zone in GameData.get_travel_zones():
		if str(zone.get("id", "")) == zone_id:
			return str(zone.get("name", zone_id))
	return zone_id
