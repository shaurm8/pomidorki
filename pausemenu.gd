extends Control

func _on_button_pressed() -> void:
	Global.resume = true

func _on_button_2_pressed() -> void:
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://main_menu.tscn")
