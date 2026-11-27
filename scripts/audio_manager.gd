extends Node

const MUSIC_STREAM: AudioStream = preload("res://assets/sfx/music.ogg")
const WIND_STREAM: AudioStream = preload("res://assets/sfx/wind.wav")
const CLICK_STREAM: AudioStream = preload("res://assets/sfx/click.wav")
const ATTACK_STREAM: AudioStream = preload("res://assets/sfx/attack.wav")
const UPGRADE_STREAM: AudioStream = preload("res://assets/sfx/upgrade.wav")

const CONFIG_PATH: String = "user://audio.cfg"
const WIND_VOLUME_DB: float = -24.0
const SFX_POOL_SIZE: int = 8
const BUS_NAMES: PackedStringArray = ["Master", "Music", "SFX"]

var music_player: AudioStreamPlayer
var wind_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_index: int = 0

func _ready() -> void:
	_load_volumes()

	music_player = _make_looping_player(_looped_copy(MUSIC_STREAM), "Music")
	wind_player = _make_looping_player(_looped_copy(WIND_STREAM), "Music")
	wind_player.volume_db = WIND_VOLUME_DB

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	music_player.play()

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_hook_existing_buttons")


func start_wind() -> void:
	if wind_player.playing:
		return
	wind_player.play()


func play_click() -> void:
	_play_sfx(CLICK_STREAM)


func play_attack() -> void:
	_play_sfx(ATTACK_STREAM)


func play_upgrade() -> void:
	_play_sfx(UPGRADE_STREAM)


func get_volume_percent(bus_name: String) -> float:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return 100.0
	return db_to_percent(AudioServer.get_bus_volume_db(bus_idx))


func set_volume_percent(bus_name: String, percent: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	AudioServer.set_bus_volume_db(bus_idx, percent_to_db(percent))
	_save_volumes()


func db_to_percent(db_value: float) -> float:
	if db_value <= -80.0:
		return 0.0
	return clampf(db_value + 80.0, 0.0, 100.0)


func percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return percent - 80.0


func _play_sfx(stream: AudioStream) -> void:
	var player: AudioStreamPlayer = sfx_players[sfx_pool_index]
	sfx_pool_index = (sfx_pool_index + 1) % sfx_players.size()
	player.stream = stream
	player.play()


func _make_looping_player(stream: AudioStream, bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	player.finished.connect(func() -> void:
		if is_instance_valid(player) and player.stream == stream:
			player.play()
	)
	add_child(player)
	return player


func _looped_copy(stream: AudioStream) -> AudioStream:
	var copy: AudioStream = stream.duplicate()
	if copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	elif copy is AudioStreamWAV:
		var wav := copy as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
	return copy


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node as BaseButton)


func _hook_existing_buttons() -> void:
	_hook_tree(get_tree().root)


func _hook_tree(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node as BaseButton)
	for child in node.get_children():
		_hook_tree(child)


func _hook_button(button: BaseButton) -> void:
	if not button.pressed.is_connected(_on_ui_button_pressed):
		button.pressed.connect(_on_ui_button_pressed)


func _on_ui_button_pressed() -> void:
	play_click()


func _load_volumes() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	for bus_name in BUS_NAMES:
		if config.has_section_key("audio", bus_name):
			var percent: float = float(config.get_value("audio", bus_name, 100.0))
			var bus_idx: int = AudioServer.get_bus_index(bus_name)
			if bus_idx != -1:
				AudioServer.set_bus_volume_db(bus_idx, percent_to_db(percent))


func _save_volumes() -> void:
	var config := ConfigFile.new()
	for bus_name in BUS_NAMES:
		config.set_value("audio", bus_name, get_volume_percent(bus_name))
	config.save(CONFIG_PATH)
