extends CharacterBody2D

@export var speed: float = 80.0
@export var follow_distance: float = 40.0

# Перетащи сюда сцену лечащей пули в Инспекторе
@export var heal_bullet_scene: PackedScene
# Интервал лечения в секундах
@export var heal_interval: float = 3.0

var target: Node2D

# Ссылка на узел с анимациями
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	setup_heal_timer()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
		velocity = Vector2.ZERO
		update_animation()
		return

	var distance = global_position.distance_to(target.global_position)

	if distance > follow_distance:
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 0.1)

	move_and_slide()
	update_animation()

func setup_heal_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = heal_interval
	timer.autostart = true
	timer.timeout.connect(shoot_heal)
	add_child(timer)

func shoot_heal() -> void:
	if not heal_bullet_scene or not is_instance_valid(target):
		return
		
	# Пуляем только если игрок ранен
	if "current_hp" in target and "max_hp" in target:
		if target.current_hp >= target.max_hp:
			return

	var bullet = heal_bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = global_position.direction_to(target.global_position)
	get_parent().add_child(bullet)

# Функция обновления анимаций
func update_animation() -> void:
	if not animated_sprite:
		return

	if velocity.length() > 5.0:
		animated_sprite.play("walk")
		
		if velocity.x < 0:
			animated_sprite.flip_h = true
		elif velocity.x > 0:
			animated_sprite.flip_h = false
	else:
		animated_sprite.play("idle")
