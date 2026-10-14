extends Area2D
## bullet.gd — a bala do canhão é criada 100% por código pelo player.gd
## (não precisa de cena nem de nó no editor). Tiro forte: destrói o asteroide.

var direction := Vector2.UP   # direção do disparo (já sai com a inclinação da nave)
var speed := 720.0            # px/s


func _ready() -> void:
	add_to_group("bullets")
	# Colisão circular simples, feita à mão (distância entre centros):
	# mais robusto que depender de area_entered em nós criados dinamicamente.
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	cs.shape = shape
	add_child(cs)
	rotation = direction.angle() + PI / 2.0
	queue_redraw()


func _process(delta: float) -> void:
	position += direction * speed * delta
	queue_redraw()

	# Destrói ao sair da tela.
	var vp := get_viewport_rect().size
	if position.y < -40.0 or position.y > vp.y + 40.0 \
			or position.x < -40.0 or position.x > vp.x + 40.0:
		queue_free()
		return

	# Verifica acerto nos asteroides (círculo da bala 5px + raio do asteroide 16px).
	for area in get_tree().get_nodes_in_group("asteroids"):
		if not is_instance_valid(area):
			continue
		if global_position.distance_squared_to(area.global_position) <= 21.0 * 21.0:
			area.hit()   # aplica dano no asteroide
			queue_free()
			return


func _draw() -> void:
	# Projétil: núcleo brilhante + halo.
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.9, 0.3, 0.35))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 0.6))
