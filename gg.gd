extends CharacterBody2D

@export var max_hp: int = 100
@export var speed: float = 150

var current_hp: int

func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("a", "d", "w", "s")
	velocity = direction * speed
	move_and_slide()

func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, max_hp)
	print("Ой! Текущее здоровье: ", current_hp) # Чтобы точно видеть урон в консоли
	if current_hp <= 0:
		die()

func die() -> void:
	queue_free()
