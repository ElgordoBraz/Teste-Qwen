extends Area2D
## asteroid.gd — colocar no nó raiz "Asteroid" (Area2D) da cena asteroid.tscn.
## Pedras AGORA SÃO PERIGOSAS: cada uma precisa levar 3 tiros do canhão
## para ser destruída (+25 pts). Se escapar pela parte de baixo, a nave
## perde 1 de 3 vidas (-50 pts). Sem vidas => Game Over.
##
## OBS: usamos Area2D (e não RigidBody2D) de propósito:
## - o movimento é 100% controlado pelo script via _process();
## - a nave detecta colisão via area_entered (Area2D não dispara body_entered).

signal passed          # asteroide escapou pela parte de baixo
signal destroyed       # asteroide foi destruído por um tiro
signal damaged(count: int)

var min_speed: float = 160.0   # px/s
var max_speed: float = 340.0   # px/s
var hp_max: int = 3            # tiros necessários para destruir

var _hp: int = 3
var _fall_speed: float = 200.0
var _vx: float = 0.0           # deriva lateral (trajetórias variadas)
var _spin: float = 0.0
var _size: float = 20.0        # raio visual/colisão
var _counted: bool = false


func _ready() -> void:
	add_to_group("asteroids")
	_hp = hp_max
	_fall_speed = randf_range(min_speed, max_speed)
	_spin = randf_range(-2.5, 2.5)
	_size = randf_range(14.0, 26.0)
	# Pedras grandes são mais lentas mas exigem mais tiros.
	hp_max = 2 if _size < 17.0 else (3 if _size < 23.0 else 4)
	_hp = hp_max
	# ~40% das pedras derivam na diagonal.
	if randf() < 0.4:
		_vx = randf_range(-70.0, 70.0)
	queue_redraw()


func _process(delta: float) -> void:
	position.y += _fall_speed * delta
	position.x += _vx * delta
	rotation += _spin * delta
	queue_redraw()

	# Rebote suave nas bordas laterais para a pedra não "sumir" na diagonal.
	var vp := get_viewport_rect().size
	if position.x < _size or position.x > vp.x - _size:
		_vx = -_vx
		position.x = clampf(position.x, _size, vp.x - _size)

	# Ponto de sobrevivência: quando a pedra ultrapassa a zona da nave.
	if not _counted and position.y > 560.0:
		_counted = true
		passed.emit()

	# Auto-destruição fora da tela.
	if position.y > vp.y + 80.0:
		queue_free()


## Chamada pelo bullet.gd quando a bala encosta na pedra.
func hit() -> void:
	if not is_inside_tree():
		return
	_hp -= 1
	damaged.emit(_hp)
	if _hp <= 0:
		destroyed.emit()
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	# Asteroide procedural com rachaduras indicando dano (mais escuro a cada tiro).
	var t := 1.0 - float(hp_max - _hp) / float(hp_max)  # 1 => intacto
	var base := Color(0.62, 0.55, 0.48).lerp(Color(0.30, 0.22, 0.18), 1.0 - t)
	var points := PackedVector2Array()
	var n := 9
	for i in n:
		var angle := TAU * float(i) / float(n)
		var radius := _size * (0.78 + 0.09 * float(i % 3))
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, base)
	# Crateras
	draw_circle(Vector2(-_size * 0.25, -_size * 0.1), _size * 0.18, base.darkened(0.3))
	draw_circle(Vector2(_size * 0.3, _size * 0.2), _size * 0.13, base.darkened(0.3))
	# Rachaduras de dano
	var dmg := hp_max - _hp
	for k in dmg:
		var a := TAU * float(k) / 3.0 + 0.7
		draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * _size * 0.85,
			Color(0.1, 0.08, 0.06), 2.0)
