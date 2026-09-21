extends Node2D

# Сюда в Инспекторе добавь свои 3 сцены врагов (элементы массива)
@export var enemy_scenes: Array[PackedScene] = []

# Зона спавна (перетащи сюда узел CollisionShape2D из инспектора)
@export var spawn_shape: CollisionShape2D

@export_group("Настройки сложности")
@export var initial_spawn_delay: float = 2.0   # Начальный интервал спавна (в секундах)
@export var min_spawn_delay: float = 0.2        # Предел ускорения (чтобы не заспавнило миллион мобов)
@export var spawn_rate_increase: float = 0.03   # На сколько секунд ускоряется спавн с каждым мобом
@export var max_enemies_at_once: int = 100       # Защита от лагов: лимит врагов на экране

var current_delay: float
var spawn_timer: Timer

func _ready() -> void:
	current_delay = initial_spawn_delay
	
	# Настраиваем таймер
	spawn_timer = Timer.new()
	spawn_timer.wait_time = current_delay
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func _on_spawn_timer_timeout() -> void:
	if enemy_scenes.is_empty():
		return

	# Проверяем, сколько сейчас живых врагов на сцене
	var current_enemy_count = get_tree().get_nodes_in_group("enemies").size()
	
	# Спавним нового, только если не превышен лимит
	if current_enemy_count < max_enemies_at_once:
		spawn_enemy()

	# Постепенно уменьшаем задержку (увеличиваем сложность)
	current_delay = maxf(min_spawn_delay, current_delay - spawn_rate_increase)
	spawn_timer.wait_time = current_delay

func spawn_enemy() -> void:
	# Выбираем случайную сцену из твоего списка
	var random_scene: PackedScene = enemy_scenes.pick_random()
	if not random_scene:
		return
		
	var enemy = random_scene.instantiate() as Node2D
	enemy.global_position = get_random_spawn_position()
	
	# Обязательно добавляем в группу "enemies" для подсчета
	enemy.add_to_group("enemies")
	
	# Добавляем врага на уровень (к родителю спавнера)
	get_parent().add_child(enemy)

# Вычисление случайной точки внутри зоны
func get_random_spawn_position() -> Vector2:
	if spawn_shape and spawn_shape.shape is RectangleShape2D:
		var rect_shape = spawn_shape.shape as RectangleShape2D
		var half_size = rect_shape.size / 2.0
		var random_x = randf_range(-half_size.x, half_size.x)
		var random_y = randf_range(-half_size.y, half_size.y)
		return spawn_shape.global_position + Vector2(random_x, random_y)
	
	# Если прямоугольная зона не задана, спавним в радиусе вокруг спавнера
	var random_angle = randf() * TAU
	var random_radius = randf_range(50.0, 250.0)
	return global_position + Vector2.RIGHT.rotated(random_angle) * random_radius
