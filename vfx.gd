extends AnimatedSprite2D

func _ready() -> void:
	play() # Запускаем анимацию
	animation_finished.connect(queue_free) # Автоматически удаляем сцену после проигрывания
