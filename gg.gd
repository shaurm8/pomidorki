extends CharacterBody2D

@export var speed: float = 300.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("a", "d", "w", "s")
	velocity = direction * speed
	move_and_slide()
