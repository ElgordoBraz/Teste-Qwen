extends RigidBody2D
## asteroid.gd — colocar no nó raiz "Asteroid" (RigidBody2D) da cena asteroid.tscn.
## O asteroide cai em linha reta com velocidade própria e se auto-destrói
## quando sai pela parte inferior da tela.

@export var min_speed: float = 140.0   # px/s
@export var max_speed: float = 320.0   # px/s

var _fall_speed: float = 200.0
var _spin: float = 0.0


func _ready() -> void:
	# Grupo usado pelo Player para identificar colisões perigosas.
	add_to_group("asteroids")

	# Física simples: sem gravidade do mundo e sem torque;
	# controlamos a queda manualmente em _physics_process.
	gravity_scale = 0.0
	can_sleep = false

	_fall_speed = randf_range(min_speed, max_speed)
	_spin = randf_range(-2.0, 2.0)  # rotação apenas visual
	queue_redraw()


func _physics_process(delta: float) -> void:
	position.y += _fall_speed * delta
	rotation += _spin * delta

	# Redesenha o asteroide (rotação visual).
	queue_redraw()

	# Auto-destruição fora da tela (abaixo ou laterais).
	var vp := get_viewport_rect().size
	if position.y > vp.y + 80.0 or position.x < -80.0 or position.x > vp.x + 80.0:
		queue_free()


func _draw() -> void:
	# Asteroide desenhado proceduralmente como um polígono irregular.
	var points := PackedVector2Array()
	var n := 8
	for i in n:
		var angle := TAU * float(i) / float(n)
		var radius := 14.0 + float(i % 3) * 3.0  # raio variado => forma irregular
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(0.62, 0.55, 0.48))
	# Crateras
	draw_circle(Vector2(-4, -2), 3.5, Color(0.45, 0.4, 0.35))
	draw_circle(Vector2(5, 4), 2.5, Color(0.45, 0.4, 0.35))
