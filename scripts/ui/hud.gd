extends Control

@onready var health_bar: ProgressBar = %HealthBar
@onready var companion_health_list: VBoxContainer = %CompanionHealthList
@onready var xp_bar: ProgressBar = %XPBar
@onready var level_label: Label = %LevelLabel
@onready var timer_label: Label = %TimerLabel
@onready var objective_label: Label = %ObjectiveLabel
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
	set_flee_status(false, 0.0)

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
	if companion.has_signal("state_changed"):
		companion.state_changed.connect(func(_companion: Node, state: String, seconds_remaining: float): _update_companion_state_label(label, companion.display_name, state, seconds_remaining))

func _update_companion_health_bar(bar: ProgressBar, current: float, maximum: float) -> void:
	bar.max_value = maximum
	bar.value = current

func _update_companion_state_label(label: Label, companion_name: String, state: String, seconds_remaining: float) -> void:
	var base_name := _short_companion_name(str(companion_name))
	match state:
		"caido":
			label.text = "%s Caido %ds" % [base_name, int(ceil(seconds_remaining))]
		"morto":
			label.text = "%s Morto" % base_name
		_:
			label.text = base_name

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
	timer_label.text = "Fim %02d:%02d" % [int(total / 60), total % 60]

func set_objective(objective_type: String, current: int, target: int) -> void:
	if objective_type == "kill_count" and target > 0:
		objective_label.text = "Abates: %d/%d" % [current, target]
	elif objective_type == "boss_kill" and target > 0:
		objective_label.text = "Chefes: %d/%d" % [current, target]
	elif objective_type == "collect_resources" and target > 0:
		objective_label.text = "Suprimentos: %d/%d" % [current, target]
	elif objective_type == "defense" and target > 0:
		objective_label.text = "Defesa: %d/%d" % [current, target]
	else:
		objective_label.text = "Objetivo: sobreviver"

func set_flee_status(is_preparing: bool, seconds: float) -> void:
	if is_preparing:
		flee_button.disabled = true
		flee_button.text = "Fuga %ds" % int(ceil(seconds))
	else:
		flee_button.disabled = false
		flee_button.text = "Fugir"

func set_weapons(summary: Array) -> void:
	var parts := []
	for item in summary:
		parts.append("%s %d" % [str(item["id"]).capitalize(), int(item["level"])])
	weapons_label.text = "Armas: " + (", ".join(parts) if parts.size() > 0 else "-")
