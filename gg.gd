extends CharacterBody2D

@export var max_hp: int = 100
@export var speed: float = 150
@export var katana_damage: int = 25
@export var vfx_scene: PackedScene
@export var vfx_offset_distance: float = 37.0
@export var lunge_speed: float = 240.0

# Настройки рывка (Shift)
@export var dash_speed: float = 450.0      # Скорость рывка
@export var dash_duration: float = 0.2     # Длительность самого рывка в секундах
@export var dash_cooldown: float = 0.5      # Перезарядка рывка (кулдаун)
@export var ghost_interval: float = 0.03    # Как часто создаются копии во время рывка

# Время в секундах, за которое нужно успеть нанести следующий удар для комбо
@export var combo_time_window: float = 0.45 
# Длительность неуязвимости при получении урона (в секундах)
@export var invincibility_duration: float = 1.5

var current_hp: int
var is_attacking: bool = false
var is_invincible: bool = false

# Переменные для рывка
var is_dashing: bool = false
var can_dash: bool = true
var last_move_direction: Vector2 = Vector2.RIGHT

# Переменные для отслеживания скорости серии атак
var last_attack_time: float = 0.0
var is_vfx_flipped: bool = false

@onready var katana_area: Area2D = $KatanaArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp
	
	update_hp_bar()
	
	if katana_area:
		katana_area.monitoring = true

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("a", "d", "w", "s")

	if direction != Vector2.ZERO:
		last_move_direction = direction.normalized()

	if is_dashing:
		move_and_slide()
		return

	if is_attacking:
		var target_velocity = direction * speed
		velocity = velocity.move_toward(target_velocity, speed * delta * 10.0)
		move_and_slide()
		update_animation(direction)
		return

	velocity = direction * speed
	move_and_slide()
	
	update_animation(direction)

func update_animation(direction: Vector2) -> void:
	if not animated_sprite:
		return
		
	if direction != Vector2.ZERO:
		animated_sprite.play("run")
		
		if direction.x < 0:
			animated_sprite.flip_h = true
		elif direction.x > 0:
			animated_sprite.flip_h = false
	else:
		animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	# Разрешаем атаку даже во время рывка!
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_attacking:
			attack()
			
	if event is InputEventKey and event.keycode == KEY_SHIFT and event.pressed and not event.is_echo():
		if can_dash and not is_dashing and not is_attacking:
			dash()

func dash() -> void:
	is_dashing = true
	can_dash = false
	
	var current_direction := Input.get_vector("a", "d", "w", "s")
	var dash_direction = current_direction.normalized() if current_direction != Vector2.ZERO else last_move_direction
	
	velocity = dash_direction * dash_speed
	
	if animated_sprite and not is_invincible:
		animated_sprite.modulate.a = 0.5
	
	# Рывок продолжается только пока флаг is_dashing равен true
	var dash_timer = get_tree().create_timer(dash_duration)
	while dash_timer.time_left > 0 and is_dashing:
		spawn_ghost()
		await get_tree().create_timer(ghost_interval).timeout
	
	# Если дэш не был прерван атакой, выключаем его флаг
	is_dashing = false
	
	if animated_sprite and not is_invincible:
		animated_sprite.modulate.a = 1.0
	
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# Функция создания одной призрачной копии
func spawn_ghost() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
		
	var ghost := Sprite2D.new()
	ghost.texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	ghost.global_position = global_position
	ghost.flip_h = animated_sprite.flip_h
	ghost.scale = animated_sprite.scale
	ghost.rotation = animated_sprite.rotation
	ghost.modulate = Color(1.0, 1.0, 1.0, 0.4)
	
	get_parent().add_child(ghost)
	
	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)

func attack() -> void:
	# Если мы были в процессе рывка — отменяем его
	if is_dashing:
		is_dashing = false
		if animated_sprite and not is_invincible:
			animated_sprite.modulate.a = 1.0

	is_attacking = true
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time <= combo_time_window:
		is_vfx_flipped = !is_vfx_flipped
	else:
		is_vfx_flipped = false
		
	last_attack_time = current_time
	
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
		
		if is_vfx_flipped:
			vfx.scale.y = -1
			
		get_parent().add_child(vfx)

func take_damage(amount: int) -> void:
	if is_invincible or is_dashing:
		return

	current_hp = clampi(current_hp - amount, 0, max_hp)
	update_hp_bar()
	print("Ой! Текущее здоровье: ", current_hp)
	
	if current_hp <= 0:
		die()
		return

	trigger_invincibility()

func trigger_invincibility() -> void:
	is_invincible = true
	
	if animated_sprite:
		var step_duration: float = 0.18
		var loops_count: int = int(invincibility_duration / (step_duration * 2))
		
		var tween = create_tween().set_loops(loops_count)
		tween.tween_property(animated_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.3), step_duration)
		tween.tween_property(animated_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), step_duration)

		await get_tree().create_timer(invincibility_duration).timeout
		
		if tween and tween.is_running():
			tween.kill()
		animated_sprite.modulate = Color.WHITE
	else:
		await get_tree().create_timer(invincibility_duration).timeout
		
	is_invincible = false

func update_hp_bar() -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

func die() -> void:
	queue_free()
