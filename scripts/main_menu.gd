extends Control

const GAME_SCENE_PATH: String = "res://scenes/game.tscn"

@onready var play_button: Button = $CenterContainer/PanelContainer/VBoxContainer/Play
@onready var settings_button: Button = $CenterContainer/PanelContainer/VBoxContainer/Settings
# @onready var exit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/Exit
@onready var settings_menu: Control = $SettingsMenu

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	# exit_button.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_settings_pressed() -> void:
	settings_menu.visible = not settings_menu.visible

# func _on_exit_pressed() -> void:
# 	get_tree().quit()
