extends Control

@onready var game_manager: Node = $"../../GameManager"
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/Close
@onready var stats_label: Label = $Panel/MarginContainer/VBoxContainer/StatsText

func _ready() -> void:
	visible = false
	close_button.pressed.connect(func() -> void: visible = false)
	game_manager.state_changed.connect(refresh_stats)
	refresh_stats()

func refresh_stats() -> void:
	var state: Dictionary = game_manager.get_state()
	var lines: PackedStringArray = []
	lines.append("Fase atual: %d" % state["level"])
	lines.append("Pontos atuais: %d" % state["points"])
	lines.append("Pontos totais ganhos: %d" % state["total_points_earned"])
	lines.append("Inimigos derrotados: %d" % state["total_enemies_defeated"])
	lines.append("Bosses derrotados: %d" % state["total_bosses_defeated"])
	lines.append("Cliques totais: %d" % state["total_clicks"])
	lines.append("Dano por click atual: %.1f" % state["dpc"])
	lines.append("Dano por segundo atual: %.1f" % state["dps"])
	lines.append("Melhorias compradas: %d" % state["total_upgrades_bought"])
	lines.append("Progresso da fase: %d/%d" % [state["enemies_killed_in_level"], state["enemies_per_level"]])

	if state["is_boss_active"]:
		lines.append("Boss ativo: sim")
		lines.append("Tempo restante do boss: %.1fs" % state["boss_time_left"])
	else:
		lines.append("Boss ativo: não")

	stats_label.text = "\n".join(lines)
