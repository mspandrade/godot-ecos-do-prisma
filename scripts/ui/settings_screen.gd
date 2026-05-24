extends Control

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SfxValue
@onready var fullscreen_check: CheckBox = %FullscreenCheck
@onready var save_label: Label = %SaveLabel

func _ready() -> void:
	%BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn"))
	master_slider.value_changed.connect(_set_volume.bind("master_volume", master_value))
	music_slider.value_changed.connect(_set_volume.bind("music_volume", music_value))
	sfx_slider.value_changed.connect(_set_volume.bind("sfx_volume", sfx_value))
	fullscreen_check.toggled.connect(func(enabled: bool): GameData.set_game_setting("fullscreen", enabled))
	GameData.settings_changed.connect(func(_settings: Dictionary): _refresh())
	GameData.save_feedback.connect(_show_save_feedback)
	_refresh()

func _refresh() -> void:
	var current := GameData.get_settings()
	_set_slider_without_signal(master_slider, float(current.get("master_volume", 0.8)))
	_set_slider_without_signal(music_slider, float(current.get("music_volume", 0.8)))
	_set_slider_without_signal(sfx_slider, float(current.get("sfx_volume", 0.8)))
	fullscreen_check.set_pressed_no_signal(bool(current.get("fullscreen", false)))
	_update_value_label(master_value, master_slider.value)
	_update_value_label(music_value, music_slider.value)
	_update_value_label(sfx_value, sfx_slider.value)

func _set_volume(value: float, setting_id: String, value_label: Label) -> void:
	_update_value_label(value_label, value)
	GameData.set_game_setting(setting_id, value)

func _set_slider_without_signal(slider: HSlider, value: float) -> void:
	slider.set_value_no_signal(clampf(value, 0.0, 1.0))

func _update_value_label(label: Label, value: float) -> void:
	label.text = "%d%%" % int(round(clampf(value, 0.0, 1.0) * 100.0))

func _show_save_feedback(message: String) -> void:
	save_label.text = message
	save_label.visible = true
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func(): save_label.visible = false)
