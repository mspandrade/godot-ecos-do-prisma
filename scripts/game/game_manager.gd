extends Node2D
class_name GameManager

@export var projectile_scene: PackedScene
@export var xp_orb_scene: PackedScene
@export var flee_channel_seconds := 5.0

const ScenePoolScript := preload("res://scripts/core/scene_pool.gd")

var run_state := RunState.new()
var projectile_pool := ScenePoolScript.new()
var orb_pool := ScenePoolScript.new()
var elapsed := 0.0
var mission_profile := {}
var mission_duration := 20.0 * 60.0
var run_finished := false
var flee_pending := false
var flee_elapsed := 0.0
var combat_equipment_candidates := []
var kill_count := 0
var boss_kill_count := 0
var resource_count := 0
var bestiary_kills := {}

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
	mission_profile = GameData.get_selected_mission_combat_profile()
	mission_duration = float(mission_profile.get("duration_seconds", mission_duration))
	spawner.configure_mission(mission_profile)
	spawner.setup(player)
	weapons.setup(player, run_state)
	upgrades.setup(run_state, weapons)
	companion_manager.setup(player)
	_build_pools()
	_connect_signals()
	hud.call("bind", player, run_state)
	hud.call("bind_companions", companion_manager)
	_update_objective_hud()
	pause_menu.hide()
	game_over.hide()
	level_choices.hide()
	companion_choices.hide()

func _process(delta: float) -> void:
	if run_finished:
		return
	elapsed += delta
	var remaining := maxf(0.0, mission_duration - elapsed)
	hud.call("set_timer", remaining)
	_process_flee(delta)
	if run_finished:
		return
	if elapsed >= mission_duration:
		_finish_run(_mission_timeout_result())

func _mission_timeout_result() -> String:
	return "vitoria" if str(mission_profile.get("objective_type", "survive")) == "survive" else "derrota"

func _process_flee(delta: float) -> void:
	if not flee_pending:
		return
	flee_elapsed += delta
	var remaining := maxf(0.0, flee_channel_seconds - flee_elapsed)
	hud.call("set_flee_status", true, remaining)
	if flee_elapsed >= flee_channel_seconds:
		var retained_coins := int(floor(run_state.coins * GameData.get_flee_coin_retention()))
		_finish_run("fuga", retained_coins)

func _build_pools() -> void:
	projectile_pool.build(self, projectile_scene, 70, _recycle_projectile)
	orb_pool.build(self, xp_orb_scene, 160, _recycle_orb)
	for orb: XPOrb in orb_pool.items:
		orb.collected.connect(_on_orb_collected)

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
	var projectile: Projectile = projectile_pool.acquire()
	if projectile:
		projectile.fire(pos, dir, damage, speed, pierce)

func _recycle_projectile(projectile: Projectile) -> void:
	projectile.deactivate()

func _drop_orb(pos: Vector2, xp_value: int, coin_value: int, enemy_type: String = "", is_boss: bool = false) -> void:
	kill_count += 1
	if is_boss:
		boss_kill_count += 1
	if not enemy_type.is_empty():
		bestiary_kills[enemy_type] = int(bestiary_kills.get(enemy_type, 0)) + 1
	_update_objective_hud()
	var orb: XPOrb = orb_pool.acquire()
	if orb:
		orb.drop(pos, xp_value, coin_value)
	if str(mission_profile.get("objective_type", "survive")) == "kill_count" and kill_count >= int(mission_profile.get("target_kills", 0)):
		_finish_run("vitoria")
	elif str(mission_profile.get("objective_type", "survive")) == "boss_kill" and boss_kill_count >= int(mission_profile.get("target_bosses", 1)):
		_finish_run("vitoria")

func _update_objective_hud() -> void:
	var objective_type := str(mission_profile.get("objective_type", "survive"))
	if objective_type == "boss_kill":
		hud.call("set_objective", objective_type, boss_kill_count, int(mission_profile.get("target_bosses", 1)))
	elif objective_type == "collect_resources":
		hud.call("set_objective", objective_type, resource_count, int(mission_profile.get("target_resources", 1)))
	else:
		hud.call("set_objective", objective_type, kill_count, int(mission_profile.get("target_kills", 0)))

func _roll_combat_equipment_drop(xp_value: int, coin_value: int) -> void:
	var chance: float = minf(0.08, 0.001 + xp_value * 0.0015 + coin_value * 0.0004)
	chance = GameData.get_lucky_reward_chance(chance)
	if randf() > chance:
		return
	var candidate := GameData.roll_random_equipment_candidate(int(mission_profile.get("recommended_level", 1)))
	if not candidate.is_empty():
		combat_equipment_candidates.append(candidate)

func _recycle_orb(orb: XPOrb) -> void:
	orb.deactivate()

func _on_orb_collected(value: int, coin_value: int) -> void:
	companion_manager.distribute_xp(value)
	var leveled_up := run_state.add_xp(value)
	_roll_combat_equipment_drop(value, coin_value)
	if str(mission_profile.get("objective_type", "survive")) == "collect_resources":
		resource_count += 1
		_update_objective_hud()
		if resource_count >= int(mission_profile.get("target_resources", 1)):
			_finish_run("vitoria")
			return
	if leveled_up:
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
	get_tree().change_scene_to_file("res://scenes/ui/GuildScene.tscn")

func continue_after_upgrade() -> void:
	level_choices.hide()
	get_tree().paused = false

func continue_after_companion_upgrade() -> void:
	companion_choices.hide()
	get_tree().paused = false

func flee_run() -> void:
	if run_finished or flee_pending:
		return
	flee_pending = true
	flee_elapsed = 0.0
	hud.call("set_flee_status", true, flee_channel_seconds)

func _finish_run(result_reason := "derrota", coins_override := -1) -> void:
	if run_finished:
		return
	run_finished = true
	flee_pending = false
	hud.call("set_flee_status", false, 0.0)
	get_tree().paused = true
	var awarded_coins: int = run_state.coins if coins_override < 0 else coins_override
	if result_reason == "vitoria":
		awarded_coins += int(mission_profile.get("completion_coin_reward", 0))
	GameData.add_coins(awarded_coins)
	var companion_result := {}
	if companion_manager.has_method("get_run_results"):
		companion_result = GameData.apply_companion_run_results(companion_manager.call("get_run_results"))
	if not bestiary_kills.is_empty():
		GameData.add_bestiary_kills(bestiary_kills)
	var mission_result := GameData.apply_mission_result(str(mission_profile.get("mission_id", "")), result_reason)
	if result_reason in ["vitoria", "fuga"] and not combat_equipment_candidates.is_empty():
		if not mission_result.has("equipment_rewards"):
			mission_result["equipment_rewards"] = []
		for candidate in combat_equipment_candidates:
			var item_name := GameData.award_equipment_candidate(candidate)
			if not item_name.is_empty():
				mission_result["equipment_rewards"].append(item_name)
	game_over.call("show_results", elapsed, run_state.level, awarded_coins, result_reason, run_state.coins, mission_result, companion_result)
