extends Area2D

@export var speed: float = 300.0
@export var damage: int = 1
@export var lifetime: float = 5.0

# Направление полета (по умолчанию вправо)
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Сигнал касания с телом
	body_entered.connect(_on_body_entered)
	
	# Автоматически удаляем фаербол, если он долго ни во что не врезается
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Двигаем снаряд вперед
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Проверяем, умеет ли объект принимать урон (наш игрок)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	# Если врезались в стенку или препятствие (но не в самого врага)
	elif not body.is_in_group("enemies"):
		queue_free()
