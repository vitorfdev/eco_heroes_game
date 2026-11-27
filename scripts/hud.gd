extends CanvasLayer

@onready var points_label: Label = $Control/TopBar/HUDContent/Points
@onready var level_label: Label = $Control/TopBar/HUDContent/Level
@onready var dpc_label: Label = $Control/TopBar/HUDContent/DPC
@onready var dps_label: Label = $Control/TopBar/HUDContent/DPS
@onready var progress_label: Label = $Control/TopBar/HUDContent/Progress
@onready var top_bar: MarginContainer = $Control/TopBar
@onready var end_game_panel: ColorRect = $Control/EndGamePanel

@onready var upgrades_button: Button = $Control/TopBar/HUDContent/Upgrades
@onready var stats_button: Button = $Control/TopBar/HUDContent/Stats
@onready var info_button: Button = $Control/TopBar/HUDContent/Info
@onready var settings_button: Button = $Control/TopBar/HUDContent/Settings
@onready var prev_level_button: Button = $Control/TopBar/HUDContent/PrevLevel
@onready var next_level_button: Button = $Control/TopBar/HUDContent/NextLevel
@onready var auto_button: Button = $Control/TopBar/HUDContent/AutoAdvance

@onready var game_manager: Node = $"../GameManager"
@onready var upgrades_menu: Control = $UpgradesMenu
@onready var stats_menu: Control = $StatsMenu
@onready var info_menu: Control = $InfoMenu
@onready var settings_menu: Control = $SettingsMenu

func _ready() -> void:
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	info_button.pressed.connect(_on_info_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	prev_level_button.pressed.connect(_on_prev_level_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	auto_button.pressed.connect(_on_auto_pressed)

	game_manager.state_changed.connect(update_view)
	update_view()

func _process(_delta: float) -> void:
	top_bar.visible = not (upgrades_menu.visible or stats_menu.visible or info_menu.visible or settings_menu.visible)
	if game_manager.is_boss_running():
		progress_label.text = "Progresso da fase: BOSS!\nTempo restante: %.1fs" % game_manager.get_boss_time_left()

func update_view() -> void:
	var state: Dictionary = game_manager.get_state()

	points_label.text = "Pontos: %s" % format_number(state["points"])
	level_label.text = "Fase: %d" % state["level"]
	dpc_label.text = "Dano/Click: %s" % format_number(state["dpc"])
	dps_label.text = "Dano por segundo: %s" % format_number(state["dps"])
	auto_button.text = "Auto: ON" if state["auto_advance_level"] else "Auto: OFF"
	prev_level_button.disabled = not game_manager.can_go_previous_level()
	next_level_button.disabled = not game_manager.can_go_next_level()
	end_game_panel.visible = state["game_finished"]

	if state["game_finished"]:
		progress_label.text = "Progresso da fase:\nFim de jogo - fase máxima (%d) alcançada" % state["max_level"]
		return

	if state["is_boss_active"]:
		progress_label.text = "Progresso da fase: BOSS!\nTempo restante: %.1fs" % state["boss_time_left"]
	else:
		var ready_text: String = ""
		if state["level"] < state["highest_level_reached"]:
			ready_text = " (JÁ CONCLUÍDA)"
		elif state["level_goal_completed"]:
			ready_text = " (META OK)"
		progress_label.text = "Progresso da fase:\n%d/%d%s" % [state["enemies_killed_in_level"], state["enemies_per_level"], ready_text]

func _on_upgrades_pressed() -> void:
	toggle_menu(upgrades_menu)

func _on_stats_pressed() -> void:
	toggle_menu(stats_menu)

func _on_info_pressed() -> void:
	toggle_menu(info_menu)

func _on_settings_pressed() -> void:
	toggle_menu(settings_menu)

func _on_prev_level_pressed() -> void:
	game_manager.go_to_previous_level()

func _on_next_level_pressed() -> void:
	game_manager.go_to_next_level_manually()

func _on_auto_pressed() -> void:
	game_manager.toggle_auto_advance()

func toggle_menu(target: Control) -> void:
	var should_show: bool = not target.visible
	upgrades_menu.visible = false
	stats_menu.visible = false
	info_menu.visible = false
	settings_menu.visible = false
	target.visible = should_show

func format_number(value: float) -> String:
	var abs_value: float = absf(value)
	if abs_value >= 1.0e9:
		return "%.2fB" % (value / 1.0e9)
	if abs_value >= 1.0e6:
		return "%.2fM" % (value / 1.0e6)
	if abs_value >= 1.0e3:
		return "%.2fK" % (value / 1.0e3)
	return "%.1f" % value
