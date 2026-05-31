extends Control

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

@onready var coins_label: Label = %CoinsLabel
@onready var character_label: Label = %CharacterLabel
@onready var particles: CPUParticles2D = %Particles

func _ready() -> void:
	MedievalUI.apply_tree(self)
	MedievalUI.transition_in(self)
	%PlayButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	%UpgradesButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/UpgradesScreen.tscn"))
	%CharactersButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/CharactersScreen.tscn"))
	%SettingsButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/SettingsScreen.tscn"))
	GameData.coins_changed.connect(_refresh)
	GameData.character_changed.connect(func(_id: String): _refresh(GameData.coins))
	particles.emitting = true
	_refresh(GameData.coins)

func _process(delta: float) -> void:
	%Background.position.x = sin(Time.get_ticks_msec() * 0.00035) * 18.0
	%Background.position.y = cos(Time.get_ticks_msec() * 0.00025) * 10.0

func _refresh(_coins: int) -> void:
	coins_label.text = "M Moedas: %d" % GameData.coins
	character_label.text = "L Lider: %s" % GameData.characters[GameData.selected_character]["name"]
