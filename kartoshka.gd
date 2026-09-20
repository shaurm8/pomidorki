extends CharacterBody2D

@export var max_hp: int = 50
@export var speed: float = 50
@export var damage: int = 13

var current_hp: int
var player: Node2D = null

@onready var hitbox: Area2D = $Hitbox
# Ссылка на узел с анимациями врага
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	current_hp = max_hp
	print("1. Враг появился на сцене! Здоровье: ", current_hp)
	
	player = get_tree().get_first_node_in_group("player") as Node2D
	
	if hitbox:
		print("2. Узел Hitbox найден успешно!")
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	else:
		print("ОШИБКА: Узел Hitbox не найден! Проверь имя узла в дереве сцены.")

func _physics_process(_delta: float) -> void:
	# Если игрок не найден или был удалён, пробуем найти его снова
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	if is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	update_animation()

# Функция управления анимациями и разворотом
func update_animation() -> void:
	if not animated_sprite:
		return

	if velocity.length() > 0.1:
		animated_sprite.play("walk")
		
		# Разворачиваем спрайт в зависимости от движения влево/вправо
		if velocity.x < 0:
			animated_sprite.flip_h = true
		elif velocity.x > 0:
			animated_sprite.flip_h = false
	else:
		animated_sprite.play("idle")

func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, max_hp)
	print("Враг получил урон! Осталось здоровье: ", current_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	print("Враг побеждён!")
	queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	print("3. В зону вошел объект: ", body.name)
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		print("4. Урон нанесен! Здоровье игрока: ", body.current_hp)
