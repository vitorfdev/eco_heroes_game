extends "res://scripts/enemy_base.gd"


func _ready() -> void:
	EnemySprites.apply_random_sprite(self)
