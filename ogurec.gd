extends CharacterBody2D

@export var speed: float = 80.0
@export var follow_distance: float = 40.0

var target: Node2D

# Ссылка на узел с анимациями
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")

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

# Функция обновления анимаций
func update_animation() -> void:
	if not animated_sprite:
		return

	# Если персонаж действительно двигается
	if velocity.length() > 5.0:
		animated_sprite.play("walk")
		
		# Поворачиваем спрайт за направлением движения
		if velocity.x < 0:
			animated_sprite.flip_h = true
		elif velocity.x > 0:
			animated_sprite.flip_h = false
	else:
		animated_sprite.play("idle")
