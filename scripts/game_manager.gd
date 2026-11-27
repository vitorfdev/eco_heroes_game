extends Node

signal state_changed

# === BALANCE ===
const ENEMIES_PER_LEVEL: int = 10
const BOSS_INTERVAL: int = 5
const BOSS_DURATION_SECONDS: float = 30.0
const MAX_LEVEL: int = 100
const BOSS_REWARD_MULTIPLIER: float = 4.0
const MAX_STAT_VALUE: float = 1.0e10
const MAX_HEALTH_VALUE: float = 1.0e12

@export var base_enemy_health: float = 12.0
@export var enemy_health_growth: float = 1.20
@export var base_boss_health: float = 140.0
@export var boss_health_growth: float = 1.23
@export var base_reward: float = 6.0
@export var reward_growth: float = 1.16

# === PLAYER ===
var points: int = 0
var dpc: float = 1.0
var dps: float = 0.0

# === PROGRESS ===
var level: int = 1
var enemies_killed_in_level: int = 0
var total_enemies_defeated: int = 0
var total_bosses_defeated: int = 0
var total_points_earned: int = 0
var total_clicks: int = 0
var total_upgrades_bought: int = 0
var auto_advance_level: bool = true
var level_goal_completed: bool = false
var highest_level_reached: int = 1
var game_finished: bool = false
var boss_levels_cleared: Dictionary = {}

var upgrades: Array[Dictionary] = []
var upgrade_levels: Dictionary = {}

# === REFERENCES ===
@onready var enemy_holder: Node2D = $"../EnemyHolder"
@onready var dps_timer: Timer = $"../DpsTimer"
@onready var boss_timer: Timer = $"../BossTimer"

var current_enemy: Area2D = null
var is_boss_active: bool = false
var _suppress_save: bool = false

const SAVE_PATH: String = "user://progress.cfg"

var enemy_scene: PackedScene = preload("res://scenes/entities/enemy.tscn")
var boss_scene: PackedScene = preload("res://scenes/entities/boss.tscn")

# === START ===
func _ready() -> void:
	setup_upgrades()

	for child in enemy_holder.get_children():
		child.queue_free()

	dps_timer.timeout.connect(_on_dps_tick)
	boss_timer.timeout.connect(_on_boss_timeout)
	boss_timer.one_shot = true
	boss_timer.wait_time = BOSS_DURATION_SECONDS

	if dps_timer.is_stopped():
		dps_timer.start()

	AudioManager.start_wind()
	if not load_progress():
		spawn_enemy()
	emit_state()

func setup_upgrades() -> void:
	upgrades = [
		{"id": "dpc_school_campaign", "name": "Campanha Escolar", "type": "dpc", "value": 1.0, "effect_growth": 1.15, "base_cost": 15.0, "cost_growth": 1.25},
		{"id": "dpc_social_media", "name": "Conscientização Digital", "type": "dpc", "value": 3.0, "effect_growth": 1.15, "base_cost": 60.0, "cost_growth": 1.28},
		{"id": "dpc_policy_pressure", "name": "Pressão por Políticas Verdes", "type": "dpc", "value": 8.0, "effect_growth": 1.16, "base_cost": 250.0, "cost_growth": 1.30},
		{"id": "dps_recycling_bins", "name": "Lixeiras de Reciclagem", "type": "dps", "value": 1.0, "effect_growth": 1.14, "base_cost": 20.0, "cost_growth": 1.22},
		{"id": "dps_tree_planting", "name": "Mutirão de Reflorestamento", "type": "dps", "value": 2.0, "effect_growth": 1.14, "base_cost": 45.0, "cost_growth": 1.23},
		{"id": "dps_clean_energy", "name": "Energia Limpa", "type": "dps", "value": 4.0, "effect_growth": 1.15, "base_cost": 120.0, "cost_growth": 1.24},
		{"id": "dps_electric_cars", "name": "Carros Elétricos", "type": "dps", "value": 7.0, "effect_growth": 1.15, "base_cost": 320.0, "cost_growth": 1.25},
		{"id": "dps_smart_irrigation", "name": "Irrigação Inteligente", "type": "dps", "value": 12.0, "effect_growth": 1.16, "base_cost": 800.0, "cost_growth": 1.26},
		{"id": "dps_solar_city", "name": "Bairro Solar", "type": "dps", "value": 18.0, "effect_growth": 1.16, "base_cost": 1600.0, "cost_growth": 1.27},
		{"id": "dps_green_industry", "name": "Indústria Carbono Zero", "type": "dps", "value": 30.0, "effect_growth": 1.17, "base_cost": 3500.0, "cost_growth": 1.28}
	]

	upgrade_levels.clear()
	for upgrade in upgrades:
		upgrade_levels[upgrade["id"]] = 0

# === SPAWN ===
func spawn_enemy(remaining_health: float = -1.0) -> void:
	clear_current_enemy()

	var enemy = enemy_scene.instantiate()
	enemy_holder.add_child(enemy)
	current_enemy = enemy
	enemy.death.connect(_on_enemy_killed)
	enemy.set_health(calculate_enemy_health())
	if remaining_health > 0.0:
		enemy.set_remaining_health(remaining_health)
	emit_state()

func spawn_boss(remaining_health: float = -1.0, time_left: float = -1.0) -> void:
	clear_current_enemy()

	is_boss_active = true
	var boss = boss_scene.instantiate()
	enemy_holder.add_child(boss)
	current_enemy = boss
	boss.death.connect(_on_boss_killed)
	boss.set_health(calculate_boss_health())
	if remaining_health > 0.0:
		boss.set_remaining_health(remaining_health)
	if time_left > 0.0:
		boss_timer.start(time_left)
	else:
		boss_timer.start()
	emit_state()

func clear_current_enemy() -> void:
	if current_enemy and is_instance_valid(current_enemy):
		current_enemy.queue_free()
	current_enemy = null

# === DAMAGE ===
func apply_click_damage() -> void:
	if game_finished:
		return
	if not current_enemy or not is_instance_valid(current_enemy):
		return
	total_clicks += 1
	AudioManager.play_attack()
	current_enemy.take_damage(dpc)
	emit_state()

func _on_dps_tick() -> void:
	if game_finished:
		return

	var should_emit: bool = is_boss_active

	if not current_enemy or not is_instance_valid(current_enemy):
		if should_emit:
			emit_state()
		return
	if dps <= 0:
		if should_emit:
			emit_state()
		return
	current_enemy.take_damage(dps)
	emit_state()

# === ENEMY FLOW ===
func _on_enemy_killed() -> void:
	if game_finished:
		return

	var reward: int = calculate_reward()
	points += reward
	total_points_earned += reward
	total_enemies_defeated += 1
	enemies_killed_in_level += 1

	if enemies_killed_in_level >= ENEMIES_PER_LEVEL:
		level_goal_completed = true
		if auto_advance_level:
			next_level()
			return

	spawn_enemy()
	emit_state()

func next_level() -> void:
	if game_finished:
		return
	if level >= MAX_LEVEL:
		finish_game()
		return

	is_boss_active = false
	boss_timer.stop()
	level += 1
	highest_level_reached = max(highest_level_reached, level)
	enemies_killed_in_level = 0
	level_goal_completed = false

	if level % BOSS_INTERVAL == 0:
		spawn_boss()
	else:
		spawn_enemy()

	emit_state()

# === BOSS FLOW ===
func _on_boss_killed() -> void:
	if game_finished:
		return

	var reward: int = int(round(calculate_reward() * BOSS_REWARD_MULTIPLIER))
	points += reward
	total_points_earned += reward
	total_bosses_defeated += 1
	boss_levels_cleared[level] = true

	is_boss_active = false
	boss_timer.stop()
	level_goal_completed = true

	if auto_advance_level:
		next_level()
		return

	spawn_boss()
	emit_state()

func _on_boss_timeout() -> void:
	if game_finished:
		return

	is_boss_active = false
	level_goal_completed = false
	clear_current_enemy()
	spawn_boss()
	emit_state()

# === CALCULATIONS ===
func calculate_enemy_health() -> float:
	return minf(base_enemy_health * pow(enemy_health_growth, max(level - 1, 0)), MAX_HEALTH_VALUE)

func calculate_boss_health() -> float:
	return minf(base_boss_health * pow(boss_health_growth, max(level - 1, 0)), MAX_HEALTH_VALUE)

func calculate_reward() -> int:
	return int(round(base_reward * pow(reward_growth, max(level - 1, 0))))

# === DATA FOR UI ===
func get_state() -> Dictionary:
	return {
		"points": points,
		"level": level,
		"dpc": dpc,
		"dps": dps,
		"is_boss_active": is_boss_active,
		"enemies_killed_in_level": enemies_killed_in_level,
		"enemies_per_level": ENEMIES_PER_LEVEL,
		"total_enemies_defeated": total_enemies_defeated,
		"total_bosses_defeated": total_bosses_defeated,
		"total_points_earned": total_points_earned,
		"total_clicks": total_clicks,
		"total_upgrades_bought": total_upgrades_bought,
		"boss_time_left": boss_timer.time_left,
		"upgrade_count": upgrades.size(),
		"level_goal_completed": level_goal_completed,
		"auto_advance_level": auto_advance_level,
		"highest_level_reached": highest_level_reached,
		"game_finished": game_finished,
		"max_level": MAX_LEVEL
	}

func emit_state() -> void:
	state_changed.emit()
	if not _suppress_save:
		save_progress()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		if not _suppress_save:
			save_progress()

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "points", points)
	config.set_value("player", "dpc", dpc)
	config.set_value("player", "dps", dps)
	config.set_value("progress", "level", level)
	config.set_value("progress", "enemies_killed_in_level", enemies_killed_in_level)
	config.set_value("progress", "total_enemies_defeated", total_enemies_defeated)
	config.set_value("progress", "total_bosses_defeated", total_bosses_defeated)
	config.set_value("progress", "total_points_earned", total_points_earned)
	config.set_value("progress", "total_clicks", total_clicks)
	config.set_value("progress", "total_upgrades_bought", total_upgrades_bought)
	config.set_value("progress", "auto_advance_level", auto_advance_level)
	config.set_value("progress", "level_goal_completed", level_goal_completed)
	config.set_value("progress", "highest_level_reached", highest_level_reached)
	config.set_value("progress", "game_finished", game_finished)

	var cleared_levels: PackedInt32Array = PackedInt32Array()
	for key in boss_levels_cleared.keys():
		cleared_levels.append(int(key))
	config.set_value("progress", "boss_levels_cleared", cleared_levels)

	for upgrade_id in upgrade_levels.keys():
		config.set_value("upgrades", str(upgrade_id), int(upgrade_levels[upgrade_id]))

	var remaining_health: float = 0.0
	if current_enemy and is_instance_valid(current_enemy) and not current_enemy.is_dead:
		remaining_health = current_enemy.current_health
	config.set_value("combat", "is_boss_active", is_boss_active)
	config.set_value("combat", "enemy_health", remaining_health)
	config.set_value("combat", "boss_time_left", boss_timer.time_left if is_boss_active else 0.0)
	config.save(SAVE_PATH)

func load_progress() -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false

	_suppress_save = true
	points = int(config.get_value("player", "points", 0))
	dpc = float(config.get_value("player", "dpc", 1.0))
	dps = float(config.get_value("player", "dps", 0.0))
	level = int(config.get_value("progress", "level", 1))
	enemies_killed_in_level = int(config.get_value("progress", "enemies_killed_in_level", 0))
	total_enemies_defeated = int(config.get_value("progress", "total_enemies_defeated", 0))
	total_bosses_defeated = int(config.get_value("progress", "total_bosses_defeated", 0))
	total_points_earned = int(config.get_value("progress", "total_points_earned", 0))
	total_clicks = int(config.get_value("progress", "total_clicks", 0))
	total_upgrades_bought = int(config.get_value("progress", "total_upgrades_bought", 0))
	auto_advance_level = bool(config.get_value("progress", "auto_advance_level", true))
	level_goal_completed = bool(config.get_value("progress", "level_goal_completed", false))
	highest_level_reached = int(config.get_value("progress", "highest_level_reached", 1))
	game_finished = bool(config.get_value("progress", "game_finished", false))

	boss_levels_cleared.clear()
	var cleared_levels: PackedInt32Array = config.get_value("progress", "boss_levels_cleared", PackedInt32Array())
	for cleared_level in cleared_levels:
		boss_levels_cleared[int(cleared_level)] = true

	for upgrade in upgrades:
		var upgrade_id: String = upgrade["id"]
		upgrade_levels[upgrade_id] = int(config.get_value("upgrades", upgrade_id, 0))

	var remaining_health: float = float(config.get_value("combat", "enemy_health", 0.0))
	var saved_boss_active: bool = bool(config.get_value("combat", "is_boss_active", false))
	var saved_boss_time: float = float(config.get_value("combat", "boss_time_left", 0.0))

	if game_finished:
		clear_current_enemy()
		is_boss_active = false
		boss_timer.stop()
	elif saved_boss_active or (level % BOSS_INTERVAL == 0 and not is_current_boss_level_cleared()):
		spawn_boss(remaining_health, saved_boss_time)
	else:
		spawn_enemy(remaining_health)

	_suppress_save = false
	return true

func reset_progress() -> void:
	_suppress_save = true
	points = 0
	dpc = 1.0
	dps = 0.0
	level = 1
	enemies_killed_in_level = 0
	total_enemies_defeated = 0
	total_bosses_defeated = 0
	total_points_earned = 0
	total_clicks = 0
	total_upgrades_bought = 0
	auto_advance_level = true
	level_goal_completed = false
	highest_level_reached = 1
	game_finished = false
	boss_levels_cleared.clear()
	is_boss_active = false
	boss_timer.stop()
	setup_upgrades()
	clear_save_file()
	_suppress_save = false
	spawn_enemy()
	save_progress()

static func clear_save_file() -> void:
	var save_dir := DirAccess.open("user://")
	if save_dir and save_dir.file_exists("progress.cfg"):
		save_dir.remove("progress.cfg")

func get_upgrades_view() -> Array[Dictionary]:
	var view: Array[Dictionary] = []
	for upgrade in upgrades:
		var upgrade_id: String = upgrade["id"]
		var level_bought: int = upgrade_levels.get(upgrade_id, 0)
		var current_price: int = get_upgrade_price(upgrade_id)
		var next_gain: float = get_upgrade_effect(upgrade_id)
		var unlocked: bool = is_upgrade_unlocked(upgrade_id)
		view.append({
			"id": upgrade_id,
			"name": upgrade["name"],
			"type": upgrade["type"],
			"value": upgrade["value"],
			"next_gain": next_gain,
			"level": level_bought,
			"price": current_price,
			"unlocked": unlocked,
			"can_buy": unlocked and points >= current_price
		})
	return view

func get_upgrade_price(upgrade_id: String) -> int:
	var upgrade := get_upgrade_by_id(upgrade_id)
	if upgrade.is_empty():
		return 0

	var level_bought: int = upgrade_levels.get(upgrade_id, 0)
	var base_cost: float = upgrade["base_cost"]
	var cost_growth: float = upgrade["cost_growth"]
	return int(round(base_cost * pow(cost_growth, level_bought)))

func buy_upgrade(upgrade_id: String) -> bool:
	var upgrade := get_upgrade_by_id(upgrade_id)
	if upgrade.is_empty():
		return false
	if not is_upgrade_unlocked(upgrade_id):
		return false

	var price: int = get_upgrade_price(upgrade_id)
	if points < price:
		return false

	points -= price
	upgrade_levels[upgrade_id] = upgrade_levels.get(upgrade_id, 0) + 1
	total_upgrades_bought += 1
	var gain: float = get_upgrade_effect(upgrade_id, upgrade_levels.get(upgrade_id, 0) - 1)

	if upgrade["type"] == "dpc":
		dpc = minf(dpc + gain, MAX_STAT_VALUE)
	else:
		dps = minf(dps + gain, MAX_STAT_VALUE)

	emit_state()
	return true

func get_upgrade_by_id(upgrade_id: String) -> Dictionary:
	for upgrade in upgrades:
		if upgrade["id"] == upgrade_id:
			return upgrade
	return {}

func is_upgrade_unlocked(upgrade_id: String) -> bool:
	var upgrade_index: int = get_upgrade_index(upgrade_id)
	if upgrade_index <= 0:
		return true

	var previous_upgrade_id: String = upgrades[upgrade_index - 1]["id"]
	return upgrade_levels.get(previous_upgrade_id, 0) >= 1

func get_upgrade_index(upgrade_id: String) -> int:
	for i in upgrades.size():
		if upgrades[i]["id"] == upgrade_id:
			return i
	return -1

func get_upgrade_effect(upgrade_id: String, current_level: int = -1) -> float:
	var upgrade := get_upgrade_by_id(upgrade_id)
	if upgrade.is_empty():
		return 0.0

	var level_bought: int = current_level
	if level_bought < 0:
		level_bought = upgrade_levels.get(upgrade_id, 0)

	var base_value: float = upgrade["value"]
	var effect_growth: float = upgrade["effect_growth"]
	return base_value * pow(effect_growth, level_bought)

func set_auto_advance(enabled: bool) -> void:
	auto_advance_level = enabled
	emit_state()

func toggle_auto_advance() -> void:
	auto_advance_level = not auto_advance_level
	emit_state()

func is_current_boss_level_cleared() -> bool:
	if level % BOSS_INTERVAL != 0:
		return false
	return boss_levels_cleared.get(level, false)

func can_go_next_level() -> bool:
	if game_finished:
		return false
	if is_boss_active:
		return is_current_boss_level_cleared()
	if level < highest_level_reached:
		return true
	return level_goal_completed

func go_to_next_level_manually() -> bool:
	if not can_go_next_level():
		return false
	next_level()
	return true

func can_go_previous_level() -> bool:
	if game_finished:
		return false
	return level > 1

func is_boss_running() -> bool:
	return is_boss_active

func get_boss_time_left() -> float:
	return boss_timer.time_left

func go_to_previous_level() -> bool:
	if not can_go_previous_level():
		return false

	level -= 1
	enemies_killed_in_level = 0
	level_goal_completed = level < highest_level_reached
	is_boss_active = false
	boss_timer.stop()

	if level % BOSS_INTERVAL == 0:
		spawn_boss()
	else:
		spawn_enemy()

	emit_state()
	return true

func finish_game() -> void:
	game_finished = true
	is_boss_active = false
	boss_timer.stop()
	clear_current_enemy()
	emit_state()
