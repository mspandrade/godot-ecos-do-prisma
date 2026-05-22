extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var companion_health_list: VBoxContainer = %CompanionHealthList
@onready var xp_bar: ProgressBar = %XPBar
@onready var level_label: Label = %LevelLabel
@onready var timer_label: Label = %TimerLabel
@onready var coins_label: Label = %CoinsLabel
@onready var weapons_label: Label = %WeaponsLabel
@onready var pause_button: Button = %PauseButton
@onready var flee_button: Button = %FleeButton

func bind(player: Player, run_state: RunState) -> void:
	player.health_changed.connect(_on_health_changed)
	run_state.xp_changed.connect(_on_xp_changed)
	run_state.coins_changed.connect(func(c: int): coins_label.text = "Moedas: %d" % c)
	pause_button.pressed.connect(get_tree().current_scene.pause_game)
	flee_button.pressed.connect(get_tree().current_scene.flee_run)
	_on_health_changed(player.health, player.max_health)
	_on_xp_changed(run_state.xp, run_state.xp_required)
	set_level(run_state.level)
	set_weapons(run_state.get_weapon_summary())

func bind_companions(companion_manager: Node) -> void:
	for child in companion_health_list.get_children():
		child.queue_free()
	companion_manager.companion_recruited.connect(_add_companion_health_bar)
	for companion in companion_manager.recruited_companions:
		_add_companion_health_bar(companion)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func _add_companion_health_bar(companion: Node) -> void:
	var row := HBoxContainer.new()
	row.modulate.a = 0.68
	row.custom_minimum_size = Vector2(0, 8)
	var label := Label.new()
	label.custom_minimum_size = Vector2(86, 8)
	label.add_theme_font_size_override("font_size", 9)
	label.text = _short_companion_name(str(companion.display_name))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(170, 5)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(bar)
	companion_health_list.add_child(row)
	_update_companion_health_bar(bar, companion.health, companion.max_health)
	companion.health_changed.connect(func(_companion: Node, current: float, maximum: float): _update_companion_health_bar(bar, current, maximum))

func _update_companion_health_bar(bar: ProgressBar, current: float, maximum: float) -> void:
	bar.max_value = maximum
	bar.value = current

func _short_companion_name(name: String) -> String:
	match name:
		"Guerreiro do Escudo":
			return "Escudo"
	return name

func _on_xp_changed(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current

func set_level(level: int) -> void:
	level_label.text = "Nv %d" % level

func set_timer(seconds: float) -> void:
	var total := int(seconds)
	timer_label.text = "%02d:%02d" % [int(total / 60), total % 60]

func set_weapons(summary: Array) -> void:
	var parts := []
	for item in summary:
		parts.append("%s %d" % [str(item["id"]).capitalize(), int(item["level"])])
	weapons_label.text = "Armas: " + (", ".join(parts) if parts.size() > 0 else "-")
