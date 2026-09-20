extends Node

var resume = false

# в твоём Autoload скрипте
func reset_pause_state() -> void:
	get_tree().paused = false
	Engine.time_scale = 1
