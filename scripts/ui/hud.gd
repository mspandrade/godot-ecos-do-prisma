extends Control

const MedievalUI := preload("res://scripts/ui/components/medieval_ui.gd")

@onready var health_bar: ProgressBar = %HealthBar
@onready var companion_health_list: VBoxContainer = %CompanionHealthList
@onready var xp_bar: ProgressBar = %XPBar
@onready var level_label: Label = %LevelLabel
@onready var squad_label: Label = %SquadLabel
@onready var timer_label: Label = %TimerLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var coins_label: Label = %CoinsLabel
@onready var weapons_label: Label = %WeaponsLabel
@onready var pause_button: Button = %PauseButton
@onready var flee_button: Button = %FleeButton

var companion_manager_ref: Node

func bind(player: Player, run_state: RunState) -> void:
	MedievalUI.apply_tree(self)
	for label in [level_label, squad_label, timer_label, objective_label, coins_label, weapons_label]:
		MedievalUI.apply_compact_label(label)
	_prepare_top_coin_label()
	player.health_changed.connect(_on_health_changed)
	run_state.xp_changed.connect(_on_xp_changed)
	run_state.coins_changed.connect(func(c: int): coins_label.text = "M %d" % c)
	pause_button.pressed.connect(get_tree().current_scene.pause_game)
	flee_button.pressed.connect(get_tree().current_scene.flee_run)
	_on_health_changed(player.health, player.max_health)
	_on_xp_changed(run_state.xp, run_state.xp_required)
	set_level(run_state.level)
	set_weapons(run_state.get_weapon_summary())
	set_flee_status(false, 0.0)
	set_squad_summary(GameData.get_squad_summary())

func bind_companions(companion_manager: Node) -> void:
	companion_manager_ref = companion_manager
	for child in companion_health_list.get_children():
		child.queue_free()
	companion_manager.companion_recruited.connect(_add_companion_health_bar)
	for companion in companion_manager.recruited_companions:
		_add_companion_health_bar(companion)
	_update_live_companion_count(companion_manager)

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func _add_companion_health_bar(companion: Node) -> void:
	var row := HBoxContainer.new()
	row.modulate.a = 0.68
	row.custom_minimum_size = Vector2(0, 8)
	var label := Label.new()
	label.custom_minimum_size = Vector2(72, 8)
	label.add_theme_font_size_override("font_size", 9)
	label.text = _short_companion_name(str(companion.display_name))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(110, 5)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(bar)
	companion_health_list.add_child(row)
	_update_companion_health_bar(bar, companion.health, companion.max_health)
	companion.health_changed.connect(func(_companion: Node, current: float, maximum: float): _update_companion_health_bar(bar, current, maximum))
	if companion.has_signal("state_changed"):
		companion.state_changed.connect(func(_companion: Node, state: String, seconds_remaining: float):
			_update_companion_state_label(label, companion.display_name, state, seconds_remaining)
			_update_live_companion_count(companion_manager_ref)
		)

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

func set_squad_summary(summary: Dictionary) -> void:
	squad_label.text = "Eq %.1f Vel %.1f C%d" % [
		float(summary.get("average_level", 0.0)),
		float(summary.get("average_speed", 0.0)),
		int(summary.get("size", 0))
	]

func _prepare_top_coin_label() -> void:
	var top_bar := health_bar.get_parent().get_parent()
	if coins_label.get_parent() != top_bar:
		coins_label.reparent(top_bar)
		top_bar.move_child(coins_label, 3)
	coins_label.custom_minimum_size = Vector2(54, 0)
	coins_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	coins_label.clip_text = true

func _update_live_companion_count(companion_manager: Node) -> void:
	var summary := GameData.get_squad_summary()
	var alive := 0
	for companion in companion_manager.recruited_companions:
		if companion.has_method("is_damage_target") and companion.is_damage_target():
			alive += 1
	summary["size"] = alive
	set_squad_summary(summary)

func set_timer(seconds: float) -> void:
	var total := int(seconds)
	timer_label.text = "%02d:%02d" % [int(total / 60), total % 60]

func set_objective(objective_type: String, current: int, target: int) -> void:
	if objective_type == "kill_count" and target > 0:
		objective_label.text = "Abates %d/%d" % [current, target]
	elif objective_type == "boss_kill" and target > 0:
		objective_label.text = "Chefes %d/%d" % [current, target]
	elif objective_type == "collect_resources" and target > 0:
		objective_label.text = "Sup. %d/%d" % [current, target]
	elif objective_type == "defense" and target > 0:
		objective_label.text = "Def. %d/%d" % [current, target]
	else:
		objective_label.text = "Sobreviver"

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
