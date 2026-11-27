class_name EnemySprites

const TEXTURE_PATHS: Array[String] = [
	"res://assets/enemies/axe.png",
	"res://assets/enemies/fire.png",
	"res://assets/enemies/malboro.png",
	"res://assets/enemies/toxic.png",
	"res://assets/enemies/trash.png",
]

const ENEMY_IMAGE_SCALE: Vector2 = Vector2(0.5, 0.5)
const BOSS_SCALE_MULTIPLIER: float = 1.5


static func pick_random_texture() -> Texture2D:
	return load(TEXTURE_PATHS.pick_random()) as Texture2D


static func apply_random_sprite(entity: Node2D, is_boss: bool = false) -> void:
	var enemy_image := entity.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not enemy_image:
		return

	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.add_frame("idle", pick_random_texture())

	enemy_image.sprite_frames = frames
	enemy_image.play("idle")

	var image_scale := ENEMY_IMAGE_SCALE
	if is_boss:
		image_scale *= BOSS_SCALE_MULTIPLIER
	enemy_image.scale = image_scale
