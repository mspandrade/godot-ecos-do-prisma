extends Control

@onready var guild_label: Label = %GuildLabel
@onready var coins_label: Label = %CoinsLabel
@onready var squad_label: Label = %SquadLabel
@onready var mobility_label: Label = %MobilityLabel
@onready var roster_label: Label = %RosterLabel
@onready var mission_label: Label = %MissionLabel
@onready var particles: CPUParticles2D = %Particles

func _ready() -> void:
	%MissionButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MissionSelect.tscn"))
	%RosterButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/CharactersScreen.tscn"))
	%LeaderButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/LeaderScreen.tscn"))
	%RecruitmentButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/RecruitmentScene.tscn"))
	%UpgradesButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/UpgradesScreen.tscn"))
	%GraveyardButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GraveyardScene.tscn"))
	%BlacksmithButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/BlacksmithScreen.tscn"))
	%SettingsButton.pressed.connect(_show_settings)
	GameData.coins_changed.connect(func(_coins: int): _refresh())
	GameData.companion_roster_changed.connect(_refresh)
	GameData.squad_changed.connect(func(_summary: Dictionary): _refresh())
	GameData.recruitment_changed.connect(_refresh)
	GameData.mission_changed.connect(func(_mission_id: String): _refresh())
	GameData.guild_changed.connect(_refresh)
	particles.emitting = true
	_refresh()

func _process(_delta: float) -> void:
	%Background.position.x = sin(Time.get_ticks_msec() * 0.00035) * 18.0
	%Background.position.y = cos(Time.get_ticks_msec() * 0.00025) * 10.0

func _refresh() -> void:
	var summary := GameData.get_squad_summary()
	var mission := GameData.get_selected_mission()
	var roster_size := GameData.get_companion_roster().size()
	guild_label.text = "%s  Nv %d" % [str(GameData.guild.get("name", "Guilda")), int(GameData.guild.get("level", 1))]
	coins_label.text = "Moedas: %d" % GameData.coins
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
	%MissionButton.disabled = int(summary["size"]) <= 0
	var graveyard_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("graveyard")
	%GraveyardButton.disabled = not graveyard_unlocked
	%GraveyardButton.text = "Cemiterio" if graveyard_unlocked else "Cemiterio bloqueado"
	var blacksmith_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("blacksmith")
	%BlacksmithButton.disabled = not blacksmith_unlocked
	%BlacksmithButton.text = "Ferreiro" if blacksmith_unlocked else "Ferreiro bloqueado"

func _show_settings() -> void:
	%SettingsLabel.visible = not %SettingsLabel.visible
