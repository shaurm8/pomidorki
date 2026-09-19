extends CharacterBody2D

@export var speed: float = 50.0
@export var follow_distance: float = 40

var target: Node2D

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")
		return

	var distance = global_position.distance_to(target.global_position)

	if distance > follow_distance:
		var direction = global_position.direction_to(target.global_position)
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 0.1)

	move_and_slide()
