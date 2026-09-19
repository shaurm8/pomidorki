extends CharacterBody2D

@export var max_hp: int = 100
@export var speed: float = 150
@export var katana_damage: int = 25
@export var vfx_scene: PackedScene
@export var vfx_offset_distance: float = 37.0
@export var lunge_speed: float = 240.0

var current_hp: int
var is_attacking: bool = false

@onready var katana_area: Area2D = $KatanaArea
# 1. Ссылка на узел с анимациями (убедитесь, что название совпадает с вашим узлом в дереве сцены)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp
	if katana_area:
		katana_area.monitoring = true

func _physics_process(delta: float) -> void:
	# Считываем вектор движения (используем стандартный ui_ или ваши "a","d","w","s")
	var direction := Input.get_vector("a", "d", "w", "s")

	if is_attacking:
		var target_velocity = direction * speed
		velocity = velocity.move_toward(target_velocity, speed * delta * 10.0)
		move_and_slide()
		update_animation(direction) # Обновляем анимацию во время атаки/рывка
		return

	velocity = direction * speed
	move_and_slide()
	
	# 2. Обновляем анимацию при обычном движении
	update_animation(direction)

# Функция переключения анимаций
func update_animation(direction: Vector2) -> void:
	if not animated_sprite:
		return
		
	if direction != Vector2.ZERO:
		# бегание!!!!!!!!!!!!!!!!
		animated_sprite.play("run")
		
		# попорачивание!!!!!!!!!
		if direction.x < 0:
			animated_sprite.flip_h = true
		elif direction.x > 0:
			animated_sprite.flip_h = false
	else:
		# стояние!!!!!!!!!!
		animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_attacking:
			attack()

func attack() -> void:
	is_attacking = true
	
	var direction_to_mouse = (get_global_mouse_position() - global_position).normalized()
	var attack_angle := direction_to_mouse.angle()
	
	velocity = direction_to_mouse * lunge_speed
	
	if katana_area:
		katana_area.rotation = attack_angle
	
	spawn_vfx(attack_angle, direction_to_mouse)

	var hit_targets: Array[Node] = []
	var attack_timer = get_tree().create_timer(0.25)
	
	while attack_timer.time_left > 0:
		deal_damage(hit_targets)
		await get_tree().physics_frame
	
	is_attacking = false

func deal_damage(hit_targets: Array[Node]) -> void:
	if not katana_area:
		return

	for body in katana_area.get_overlapping_bodies():
		if body != self and not body in hit_targets and body.has_method("take_damage"):
			body.take_damage(katana_damage)
			hit_targets.append(body)

	for area in katana_area.get_overlapping_areas():
		var parent = area.get_parent()
		if not area in hit_targets and area.has_method("take_damage"):
			area.take_damage(katana_damage)
			hit_targets.append(area)
		elif parent and parent != self and not parent in hit_targets and parent.has_method("take_damage"):
			parent.take_damage(katana_damage)
			hit_targets.append(parent)

func spawn_vfx(angle: float, direction: Vector2) -> void:
	if vfx_scene:
		var vfx = vfx_scene.instantiate() as Node2D
		vfx.global_position = global_position + (direction * vfx_offset_distance)
		vfx.rotation = angle
		get_parent().add_child(vfx)

func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, max_hp)
	print("Ой! Текущее здоровье: ", current_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	queue_free()
