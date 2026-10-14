extends Area2D
## asteroid.gd — colocar no nó raiz "Asteroid" (Area2D) da cena asteroid.tscn.
## O asteroide cai em linha reta com velocidade própria e se auto-destrói
## quando sai pela parte inferior/lateral da tela.
##
## OBS: usamos Area2D (e não RigidBody2D) de propósito:
## - o movimento é 100% controlado pelo script, independente do motor físico;
## - a nave (também Area2D) detecta a colisão via area_entered, pois
##   Area2D NÃO detecta outros Area2D através de body_entered.

signal passed  # emitido uma única vez quando o asteroide ultrapassa a nave

var min_speed: float = 160.0   # px/s (velocidade mínima)
var max_speed: float = 340.0   # px/s (velocidade máxima)

var _fall_speed: float = 200.0
var _spin: float = 0.0
var _counted: bool = false


func _ready() -> void:
	add_to_group("asteroids")
	_fall_speed = randf_range(min_speed, max_speed)
	_spin = randf_range(-2.0, 2.0)  # rotação apenas visual
	queue_redraw()


func _process(delta: float) -> void:
	position.y += _fall_speed * delta
	rotation += _spin * delta
	queue_redraw()

	# Ponto por sobrevivência: quando o asteroide passa abaixo da linha da nave.
	if not _counted and position.y > 560.0:
		_counted = true
		passed.emit()

	# Auto-destruição fora da tela.
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
