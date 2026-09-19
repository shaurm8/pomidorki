extends Node2D




#сцены уровня нет так что рабочим будет только кнопка выхода

func _on_button_quit_pressed() -> void:
	get_tree().quit()
