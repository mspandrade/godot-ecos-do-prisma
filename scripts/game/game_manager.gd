extends Node2D
class_name GameManager

@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene

var run_state := RunState.new()
var projectile_pool: Array[Projectile] = []
var orb_pool: Array[XPOrb] = []
var elapsed := 0.0
var run_finished := false

@onready var player: Player = $Player
@onready var camera: CameraController = $Camera2D
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var weapons: WeaponSystem = $WeaponSystem
@onready var upgrades: UpgradeManager = $UpgradeManager
@onready var companion_manager: Node = $CompanionManager
@onready var hud: Control = $CanvasLayer/HUD
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var game_over: Control = $CanvasLayer/GameOver
@onready var level_choices: Control = $CanvasLayer/LevelChoices
@onready var companion_choices: Control = $CanvasLayer/CompanionChoices
@onready var joystick: Control = $CanvasLayer/VirtualJoystick

func _ready() -> void:
	randomize()
	add_child(run_state)
	run_state.add_to_group("run_state")
	player.joystick_path = joystick.get_path()
	player.setup(run_state)
	camera.set_target(player)
	spawner.setup(player)
	weapons.setup(player, run_state)
	upgrades.setup(run_state, weapons)
	companion_manager.setup(player)
	_build_pools()
	_connect_signals()
	hud.call("bind", player, run_state)
	hud.call("bind_companions", companion_manager)
	pause_menu.hide()
	game_over.hide()
	level_choices.hide()
	companion_choices.hide()

func _process(delta: float) -> void:
	if run_finished:
		return
	elapsed += delta
	hud.call("set_timer", elapsed)
	if elapsed >= 20.0 * 60.0:
		_finish_run()

func _build_pools() -> void:
	for i in range(70):
		var projectile: Projectile = projectile_scene.instantiate()
		add_child(projectile)
		projectile.recycled.connect(_recycle_projectile)
		projectile_pool.append(projectile)
	for i in range(160):
		var orb: XPOrb = xp_orb_scene.instantiate()
		add_child(orb)
		orb.collected.connect(_on_orb_collected)
		orb.recycled.connect(_recycle_orb)
		orb_pool.append(orb)

func _connect_signals() -> void:
	player.died.connect(_finish_run)
	spawner.enemy_killed.connect(_drop_orb)
	weapons.projectile_requested.connect(_fire_projectile)
	run_state.level_changed.connect(_on_level_changed)
	run_state.weapon_changed.connect(func(summary: Array): hud.call("set_weapons", summary))
	upgrades.choices_ready.connect(_show_level_choices)
	companion_manager.companion_leveled.connect(_show_companion_choices)
	pause_menu.call("bind", self)
	game_over.call("bind", self)
	level_choices.call("bind", upgrades)
	companion_choices.call("bind", companion_manager)

func _fire_projectile(pos: Vector2, dir: Vector2, damage: float, speed: float, pierce: int) -> void:
	for projectile in projectile_pool:
		if not projectile.active:
			projectile.fire(pos, dir, damage, speed, pierce)
			return

func _recycle_projectile(projectile: Projectile) -> void:
	projectile.deactivate()

func _drop_orb(pos: Vector2, xp_value: int, coin_value: int) -> void:
	for orb in orb_pool:
		if not orb.active:
			orb.drop(pos, xp_value, coin_value)
			return

func _recycle_orb(orb: XPOrb) -> void:
	orb.deactivate()

func _on_orb_collected(value: int) -> void:
	companion_manager.distribute_xp(value)
	if run_state.add_xp(value):
		get_tree().paused = true
		upgrades.request_choices()

func _on_level_changed(level: int) -> void:
	hud.call("set_level", level)

func _show_level_choices(choices: Array) -> void:
	level_choices.call("show_choices", choices)

func _show_companion_choices(companion: Node, choices: Array) -> void:
	if run_finished:
		return
	get_tree().paused = true
	companion_choices.call("show_choices", companion, choices)

func pause_game() -> void:
	get_tree().paused = true
	pause_menu.show()

func resume_game() -> void:
	pause_menu.hide()
	get_tree().paused = false

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func back_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func continue_after_upgrade() -> void:
	level_choices.hide()
	get_tree().paused = false

func continue_after_companion_upgrade() -> void:
	companion_choices.hide()
	get_tree().paused = false

func _finish_run() -> void:
	if run_finished:
		return
	run_finished = true
	get_tree().paused = true
	GameData.add_coins(run_state.coins)
	game_over.call("show_results", elapsed, run_state.level, run_state.coins)
