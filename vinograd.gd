extends CharacterBody2D

@export var speed: float = 65
@export var damage: int = 10

@onready var hitbox: Area2D = $Hitbox

var player: Node2D = null

func _ready() -> void:
	print("1. Враг появился на сцене!")
	player = get_tree().get_first_node_in_group("player") as Node2D
	
	if hitbox:
		print("2. Узел Hitbox найден успешно!")
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	else:
		print("ОШИБКА: Узел Hitbox не найден! Проверь имя узла в дереве сцены.")

func _physics_process(_delta: float) -> void:
	if is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func _on_hitbox_body_entered(body: Node2D) -> void:
	print("3. В зону вошел объект: ", body.name)
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		print("4. Урон нанесен! Здоровье игрока: ", body.current_hp)
