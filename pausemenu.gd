extends Control

func _on_button_pressed() -> void:
	Global.resume = true

func _on_button_2_pressed() -> void:
	get_tree().quit()
