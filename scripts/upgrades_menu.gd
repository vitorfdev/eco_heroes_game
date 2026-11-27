extends Control

@onready var game_manager: Node = $"../../GameManager"
@onready var rows_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/RowsContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/Close
@onready var template_row: HBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/RowsContainer/TemplateRow

func _ready() -> void:
	visible = false
	close_button.pressed.connect(func() -> void: visible = false)
	game_manager.state_changed.connect(refresh_upgrades)
	refresh_upgrades()

func refresh_upgrades() -> void:
	for child in rows_container.get_children():
		if child == template_row:
			continue
		child.queue_free()

	var upgrades: Array[Dictionary] = game_manager.get_upgrades_view()
	for upgrade in upgrades:
		var row: HBoxContainer = template_row.duplicate()
		row.visible = true

		var name_label: Label = row.get_node("Name")
		var level_label: Label = row.get_node("Level")
		var price_label: Label = row.get_node("Price")
		var buy_button: Button = row.get_node("Buy")

		var damage_type: String = "click" if upgrade["type"] == "dpc" else "dps"
		name_label.text = "%s (+%.1f %s)" % [upgrade["name"], upgrade["next_gain"], damage_type]
		level_label.text = "Lv %d" % upgrade["level"]
		price_label.text = "Custo: %d" % upgrade["price"]
		buy_button.text = "Comprar"
		buy_button.disabled = not upgrade["can_buy"]
		if not upgrade["unlocked"]:
			price_label.text = "Bloqueado"
			buy_button.text = "Trancado"
			buy_button.disabled = true
		buy_button.pressed.connect(_on_buy_pressed.bind(upgrade["id"]))

		rows_container.add_child(row)

func _on_buy_pressed(upgrade_id: String) -> void:
	var bought: bool = game_manager.buy_upgrade(upgrade_id)
	if bought:
		AudioManager.play_upgrade()
		refresh_upgrades()
