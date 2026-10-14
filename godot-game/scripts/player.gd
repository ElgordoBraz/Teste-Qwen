extends Area2D
## player_new.gd — colocar no nó raiz "Player" (Area2D) da cena player.tscn.
## Movimento em 4 direções (WASD / setas) com aceleração e atrito,
## inclinação visual ao mover para os lados e canhão com cadência baixa.

signal died
signal shot_fired(bullet: Node2D)   # o Main usa para adicionar a bala à cena

@export var accel: float = 1800.0     # px/s²  (aceleração)
@export var max_speed: float = 430.0  # px/s   (velocidade máxima)
@export var friction: float = 1400.0  # px/s²  (atrito quando solta as teclas)
@export var fire_cooldown: float = 0.75 # segundos entre tiros (cadência baixa)

const TILT_MAX := 0.35  # ~20 graus de inclinação máxima

var _velocity := Vector2.ZERO
var _alive: bool = true
var _fire_timer: float = 0.0
var _tilt: float = 0.0


func _ready() -> void:
	# Area2D detecta OUTRA Area2D pelo sinal area_entered (não body_entered!).
	area_entered.connect(_on_area_entered)
	queue_redraw()


func _process(delta: float) -> void:
	if not _alive:
		return

	# --- Direção desejada (eixo Y negativo = para cima na tela) ---
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_dir.length_squared() > 1.0:
		input_dir = input_dir.normalized()

	# --- Física simples: aceleração + atrito => movimento natural ---
	if input_dir != Vector2.ZERO:
		_velocity += input_dir * accel * delta
	else:
		# Atrito: reduz a velocidade até zero, sem "frear" bruscamente.
		var speed := _velocity.length()
		if speed > 0.0:
			var new_speed := maxf(0.0, speed - friction * delta)
			_velocity = _velocity.normalized() * new_speed
	_velocity = _velocity.limit_length(max_speed)

	position += _velocity * delta

	# --- Limites da tela (com quique suave nas bordas) ---
	var vp := get_viewport_rect().size
	var half := Vector2(20.0, 24.0)
	if position.x < half.x:
		position.x = half.x
		_velocity.x = maxf(_velocity.x, 0.0)
	elif position.x > vp.x - half.x:
		position.x = vp.x - half.x
		_velocity.x = minf(_velocity.x, 0.0)
	if position.y < half.y + 40.0:
		position.y = half.y + 40.0   # não sobe por baixo da barra de pontos
		_velocity.y = maxf(_velocity.y, 0.0)
	elif position.y > vp.y - half.y:
		position.y = vp.y - half.y
		_velocity.y = minf(_velocity.y, 0.0)

	# --- Inclinação natural: a nave "banca" conforme a velocidade horizontal ---
	var target_tilt := clampf(_velocity.x / max_speed, -1.0, 1.0) * TILT_MAX
	_tilt = lerpf(_tilt, target_tilt, 10.0 * delta)
	rotation = _tilt

	# --- Canhão: tiro forte, cadência baixa ---
	_fire_timer -= delta
	if Input.is_action_pressed("shoot") and _fire_timer <= 0.0:
		_fire_timer = fire_cooldown
		_shoot()

	queue_redraw()  # chama do motor animada


func _shoot() -> void:
	var bullet := Area2D.new()
	bullet.set_script(load("res://scripts/bullet.gd"))
	bullet.position = global_position + Vector2(0.0, -26.0).rotated(rotation)
	bullet.direction = Vector2.UP.rotated(rotation)
	shot_fired.emit(bullet)


func _draw() -> void:
	# Nave desenhada proceduralmente (sem sprites).
	var body := PackedVector2Array([
		Vector2(0, -22),   # ponta (nariz)
		Vector2(16, 14),   # asa direita
		Vector2(8, 8),     # entalhe direito
		Vector2(-8, 8),    # entalhe esquerdo
		Vector2(-16, 14),  # asa esquerda
	])
	draw_colored_polygon(body, Color(0.2, 0.85, 1.0))
	# Canhão (tubo na frente)
	draw_rect(Rect2(-2.5, -30, 5.0, 10.0), Color(0.9, 0.9, 0.95))
	# Cabine
	draw_circle(Vector2(0, -4), 5.0, Color(1.0, 1.0, 1.0))
	# Chama do motor — mais forte quando a nave acelera
	var thrust := 8.0 + 12.0 * clampf(_velocity.length() / max_speed, 0.0, 1.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, 10), Vector2(5, 10), Vector2(0, 10.0 + thrust + randf() * 4.0),
	]), Color(1.0, 0.55, 0.1))


func revive() -> void:
	_alive = true
	visible = true
	_velocity = Vector2.ZERO
	_tilt = 0.0
	rotation = 0.0
	_fire_timer = 0.0
	set_process(true)
	var shape := get_node_or_null("CollisionShape2D")
	if shape:
		shape.set_deferred("disabled", false)


func _on_area_entered(area: Area2D) -> void:
	if not _alive or area == null:
		return
	if area.is_in_group("asteroids"):
		_alive = false
		visible = false
		set_process(false)
		get_node("CollisionShape2D").set_deferred("disabled", true)
		died.emit()
