extends Control

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

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
@onready var facility_grid: GridContainer = %FacilityGrid
var summary_panel: PanelContainer
var summary_text: Label

func _ready() -> void:
	MedievalUI.apply_tree(self)
	MedievalUI.transition_in(self)
	for label in [guild_label, coins_label, morale_label, squad_label, mobility_label, roster_label, equipment_label, mission_label]:
		MedievalUI.apply_body_label(label)
	_setup_summary_panel()
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
	facility_grid.columns = 1 if size.x < 860.0 else 2

func _refresh() -> void:
	var summary := GameData.get_squad_summary()
	var mission := GameData.get_selected_mission()
	var roster_size := GameData.get_companion_roster().size()
	var readiness := GameData.get_mission_readiness(str(mission["id"]))
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
	mobility_label.text = "Velocidade %.1f - %s | Sorte %.0f%%" % [float(summary["average_speed"]), str(summary["speed_label"]), float(summary["average_luck"]) * 100.0]
	mission_label.text = "Missao: %s | Risco %s (%d%%)" % [
		str(mission.get("name", "-")),
		str(readiness["risk"]),
		int(readiness.get("risk_percent", 100))
	]
	roster_label.text = "C Companions: %d/%d | %s" % [
		roster_size,
		int(GameData.guild.get("companion_capacity", 12)),
		str(summary["mobility_warning"])
	]
	equipment_label.text = "Equipamentos: %d no inventario" % GameData.get_equipment_inventory().size()
	_refresh_summary_text()
	%MissionButton.disabled = int(summary["size"]) <= 0
	var graveyard_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("graveyard")
	%GraveyardButton.disabled = not graveyard_unlocked
	%GraveyardButton.text = "Cemiterio" if graveyard_unlocked else "Cemiterio (bloq.)"
	var blacksmith_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("blacksmith")
	%BlacksmithButton.disabled = not blacksmith_unlocked
	%BlacksmithButton.text = "Ferreiro" if blacksmith_unlocked else "Ferreiro (bloq.)"
	var training_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("training_field")
	%TrainingButton.disabled = not training_unlocked
	%TrainingButton.text = "Treinamento" if training_unlocked else "Treinamento (bloq.)"
	var infirmary_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("infirmary")
	%InfirmaryButton.disabled = not infirmary_unlocked
	%InfirmaryButton.text = "Enfermaria" if infirmary_unlocked else "Enfermaria (bloq.)"
	var warehouse_unlocked: bool = (GameData.guild.get("unlocked_structures", []) as Array).has("warehouse")
	%WarehouseButton.disabled = not warehouse_unlocked
	%WarehouseButton.text = "Armazem" if warehouse_unlocked else "Armazem (bloq.)"

func _setup_summary_panel() -> void:
	if is_instance_valid(summary_panel):
		return
	var summary_title := get_node("MenuBox/SummaryTitle") as Label
	var menu_box := summary_title.get_parent()
	summary_panel = PanelContainer.new()
	summary_panel.name = "SummaryPanel"
	summary_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MedievalUI.apply_panel(summary_panel, true)
	summary_text = Label.new()
	summary_text.name = "SummaryText"
	summary_text.custom_minimum_size = Vector2(0, 126)
	summary_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_text.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	summary_text.clip_text = false
	summary_text.add_theme_font_size_override("font_size", 16)
	summary_text.add_theme_color_override("font_color", Color("#f3dfb8"))
	summary_panel.add_child(summary_text)
	menu_box.add_child(summary_panel)
	menu_box.move_child(summary_panel, summary_title.get_index() + 1)
	for label in [guild_label, coins_label, morale_label, squad_label, mobility_label, roster_label, equipment_label, mission_label]:
		label.visible = false

func _refresh_summary_text() -> void:
	if not is_instance_valid(summary_text):
		return
	summary_text.text = "\n".join([
		guild_label.text,
		"%s | %s" % [coins_label.text, morale_label.text],
		"%s | %s" % [squad_label.text, mobility_label.text],
		roster_label.text,
		"%s | %s" % [equipment_label.text, mission_label.text]
	])

func _show_save_feedback(message: String) -> void:
	save_label.text = message
	save_label.visible = true
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func(): save_label.visible = false)
