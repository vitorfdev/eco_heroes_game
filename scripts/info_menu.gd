extends Control

@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/Header/Close

func _ready() -> void:
	visible = false
	close_button.pressed.connect(func() -> void: visible = false)

func _on_article_1_pressed() -> void:
	OS.shell_open("https://brasil.un.org/pt-br/175180-o-que-s%C3%A3o-mudan%C3%A7as-clim%C3%A1ticas")

func _on_article_2_pressed() -> void:
	OS.shell_open("https://www.wwf.org.br/")

func _on_article_3_pressed() -> void:
	OS.shell_open("https://www.nationalgeographicbrasil.com/meio-ambiente")

func _on_ong_1_pressed() -> void:
	OS.shell_open("https://www.greenpeace.org/brasil/")

func _on_ong_2_pressed() -> void:
	OS.shell_open("https://www.wwf.org.br/")

func _on_ong_3_pressed() -> void:
	OS.shell_open("https://www.sosma.org.br/")
