extends Control

@onready var guild_label: Label = %GuildLabel
@onready var coins_label: Label = %CoinsLabel
@onready var morale_label: Label = %MoraleLabel
@onready var squad_label: Label = %SquadLabel
@onready var mobility_label: Label = %MobilityLabel
@onready var roster_label: Label = %RosterLabel
@onready var equipment_label: Label = %EquipmentLabel
@onready var mission_label: Label = %MissionLabel
@onready var save_label: Label = %SaveLabel
@onready var particles: CPUParticles2D = %Particles

func _ready() -> void:
	%MissionButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MissionSelect.tscn"))
	%RosterButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/CharactersScreen.tscn"))
	%LeaderButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/LeaderScreen.tscn"))
	%RecruitmentButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/RecruitmentScene.tscn"))
	%TrainingButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/TrainingScreen.tscn"))
	%InfirmaryButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/InfirmaryScreen.tscn"))
	%WarehouseButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/WarehouseScreen.tscn"))
	%UpgradesButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/UpgradesScreen.tscn"))
	%CodexButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/CodexScreen.tscn"))
	%GraveyardButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GraveyardScene.tscn"))
	%BlacksmithButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/BlacksmithScreen.tscn"))
	%SettingsButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/SettingsScreen.tscn"))
	GameData.coins_changed.connect(func(_coins: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	GameData.squad_changed.connect(func(_summary: Dictionary): _refresh())
	GameData.recruitment_changed.connect(_refresh)
	GameData.mission_changed.connect(func(_mission_id: String): _refresh())
	GameData.guild_changed.connect(_refresh)
	GameData.save_feedback.connect(_show_save_feedback)
	particles.emitting = true
	_refresh()

func _process(_delta: float) -> void:
	%Background.position.x = sin(Time.get_ticks_msec() * 0.00035) * 18.0
	%Background.position.y = cos(Time.get_ticks_msec() * 0.00025) * 10.0

func _refresh() -> void:
	var summary := GameData.get_squad_summary()
	var mission := GameData.get_selected_mission()
	var roster_size := GameData.get_companion_roster().size()
	guild_label.text = "%s  Nv %d | Rep %d" % [
		str(GameData.guild.get("name", "Guilda")),
		int(GameData.guild.get("level", 1)),
		int(GameData.guild.get("reputation", 0))
	]
	coins_label.text = "Moedas: %d" % GameData.coins
	morale_label.text = "Moral: %d - %s" % [int(GameData.guild.get("morale", 50)), GameData.get_morale_label()]
	squad_label.text = "Esquadrao: %d/%d | Level medio %.1f" % [
		int(summary["size"]),
		int(summary["max_size"]),
		float(summary["average_level"])
	]
	mobility_label.text = "Velocidade %.1f - %s" % [float(summary["average_speed"]), str(summary["speed_label"])]
	mission_label.text = "Missao: %s | Risco %s" % [
		str(mission.get("name", "-")),
		str(GameData.get_mission_readiness(str(mission["id"]))["risk"])
	]
	roster_label.text = "Companions: %d/%d | %s" % [
		roster_size,
		int(GameData.guild.get("companion_capacity", 12)),
		str(summary["mobility_warning"])
	]
	equipment_label.text = "Equipamentos: %d no inventario" % GameData.get_equipment_inventory().size()
	%MissionButton.disabled = int(summary["size"]) <= 0
	var graveyard_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("graveyard")
	%GraveyardButton.disabled = not graveyard_unlocked
	%GraveyardButton.text = "Cemiterio" if graveyard_unlocked else "Cemiterio bloqueado"
	var blacksmith_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("blacksmith")
	%BlacksmithButton.disabled = not blacksmith_unlocked
	%BlacksmithButton.text = "Ferreiro" if blacksmith_unlocked else "Ferreiro bloqueado"
	var training_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("training_field")
	%TrainingButton.disabled = not training_unlocked
	%TrainingButton.text = "Treinamento" if training_unlocked else "Treinamento bloqueado"
	var infirmary_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("infirmary")
	%InfirmaryButton.disabled = not infirmary_unlocked
	%InfirmaryButton.text = "Enfermaria" if infirmary_unlocked else "Enfermaria bloqueada"
	var warehouse_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("warehouse")
	%WarehouseButton.disabled = not warehouse_unlocked
	%WarehouseButton.text = "Armazem" if warehouse_unlocked else "Armazem bloqueado"

func _show_save_feedback(message: String) -> void:
	save_label.text = message
	save_label.visible = true
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func(): save_label.visible = false)
