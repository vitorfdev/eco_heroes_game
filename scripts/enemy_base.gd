extends Area2D

signal death

const HEALTH_BAR_TWEEN_DURATION: float = 0.25

var max_health: float = 10.0
var current_health: float = 10.0
var displayed_health: float = 10.0
var is_dead: bool = false
var _has_died: bool = false

var _health_tween: Tween = null

@onready var health_bar: TextureProgressBar = $TextureProgressBar


func set_health(value: float) -> void:
	max_health = value
	current_health = value
	displayed_health = value
	is_dead = false
	_has_died = false
	_stop_health_tween()
	_apply_bar_value(displayed_health)


func set_remaining_health(value: float) -> void:
	current_health = clampf(value, 0.0001, max_health)
	displayed_health = current_health
	is_dead = false
	_has_died = false
	_stop_health_tween()
	_apply_bar_value(displayed_health)


func take_damage(value: float) -> void:
	if is_dead:
		return

	current_health -= value
	if current_health < 0.0001:
		current_health = 0.0

	if current_health <= 0.0:
		is_dead = true
		_animate_bar_to(0.0, die)
		return

	_animate_bar_to(current_health)


func die() -> void:
	if _has_died or not is_instance_valid(self):
		return
	_has_died = true
	death.emit()
	queue_free()


func _animate_bar_to(target: float, on_finished: Callable = Callable()) -> void:
	if not health_bar:
		if on_finished.is_valid():
			on_finished.call()
		return

	var clamped_target: float = clampf(target, 0.0, max_health)
	_stop_health_tween()

	if is_equal_approx(displayed_health, clamped_target):
		_apply_bar_value(clamped_target)
		if on_finished.is_valid():
			on_finished.call()
		return

	_health_tween = create_tween()
	_health_tween.tween_method(_apply_bar_value, displayed_health, clamped_target, HEALTH_BAR_TWEEN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if on_finished.is_valid():
		_health_tween.finished.connect(on_finished, CONNECT_ONE_SHOT)


func _apply_bar_value(value: float) -> void:
	displayed_health = value
	if not health_bar:
		return
	health_bar.min_value = 0.0
	health_bar.max_value = max_health
	health_bar.step = 0.0
	health_bar.value = value


func _stop_health_tween() -> void:
	if _health_tween and _health_tween.is_valid():
		_health_tween.kill()
	_health_tween = null


func _input_event(_viewport, event, _shape_idx) -> void:
	if is_dead:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var gm = get_tree().get_first_node_in_group("GameManager")
		if gm:
			gm.apply_click_damage()
