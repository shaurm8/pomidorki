extends Node2D

func _ready() -> void:
	Engine.time_scale = 1

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://test_map.tscn")

func _on_button_quit_pressed() -> void:
	get_tree().quit()

func _on_button_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://credits.tscn")
