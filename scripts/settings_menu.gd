extends Control

@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/Close
@onready var reset_button: Button = $Panel/MarginContainer/VBoxContainer/ResetRow/Reset
# @onready var quit_button: Button = $Panel/MarginContainer/VBoxContainer/QuitRow/Quit
@onready var master_slider: HSlider = $Panel/MarginContainer/VBoxContainer/Rows/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/MarginContainer/VBoxContainer/Rows/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/MarginContainer/VBoxContainer/Rows/SfxRow/SfxSlider

@onready var master_value: Label = $Panel/MarginContainer/VBoxContainer/Rows/MasterRow/Value
@onready var music_value: Label = $Panel/MarginContainer/VBoxContainer/Rows/MusicRow/Value
@onready var sfx_value: Label = $Panel/MarginContainer/VBoxContainer/Rows/SfxRow/Value

func _ready() -> void:
	visible = false
	close_button.pressed.connect(func() -> void: visible = false)
	reset_button.pressed.connect(_on_reset_pressed)
	# quit_button.pressed.connect(_on_quit_pressed)

	setup_slider(master_slider)
	setup_slider(music_slider)
	setup_slider(sfx_slider)

	load_bus_value("Master", master_slider, master_value)
	load_bus_value("Music", music_slider, music_value)
	load_bus_value("SFX", sfx_slider, sfx_value)

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

func setup_slider(slider: HSlider) -> void:
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1

func load_bus_value(bus_name: String, slider: HSlider, value_label: Label) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		slider.value = 100
		slider.editable = false
		value_label.text = "N/A"
		return

	slider.value = AudioManager.get_volume_percent(bus_name)
	value_label.text = "%d%%" % int(slider.value)

func apply_volume(bus_name: String, value: float, value_label: Label) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		value_label.text = "N/A"
		return

	AudioManager.set_volume_percent(bus_name, value)
	value_label.text = "%d%%" % int(value)

func _on_master_changed(value: float) -> void:
	apply_volume("Master", value, master_value)

func _on_music_changed(value: float) -> void:
	apply_volume("Music", value, music_value)

func _on_sfx_changed(value: float) -> void:
	apply_volume("SFX", value, sfx_value)

func _on_reset_pressed() -> void:
	var game_manager: Node = get_tree().get_first_node_in_group("GameManager")
	if game_manager and game_manager.has_method("reset_progress"):
		game_manager.reset_progress()
	else:
		var save_dir := DirAccess.open("user://")
		if save_dir and save_dir.file_exists("progress.cfg"):
			save_dir.remove("progress.cfg")

# func _on_quit_pressed() -> void:
# 	get_tree().quit()
