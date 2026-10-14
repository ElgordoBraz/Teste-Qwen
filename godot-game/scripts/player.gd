extends Area2D
## player.gd — colocar no nó raiz "Player" (Area2D) da cena player.tscn.
## Movimento horizontal com A/D ou setas, limitado às bordas da tela.

signal died

@export var speed: float = 420.0  # pixels por segundo

var _half_width: float = 18.0     # metade da largura da nave (para clamp)
var _alive: bool = true


func _ready() -> void:
	# Conecta o sinal de colisão da Area2D com o corpo do asteroide.
	body_entered.connect(_on_body_entered)
	position = Vector2(400.0, 520.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not _alive:
		return

	var direction := Input.get_axis("move_left", "move_right")
	position.x += direction * speed * delta

	# Mantém a nave dentro da área visível.
	var vw := get_viewport_rect().size.x
	position.x = clampf(position.x, _half_width, vw - _half_width)

	# Redesenha a chama do motor a cada quadro.
	queue_redraw()


func _draw() -> void:
	# Nave desenhada proceduralmente (sem necessidade de sprites).
	var body := PackedVector2Array([
		Vector2(0, -22),   # ponta (nariz)
		Vector2(16, 14),   # asa direita
		Vector2(8, 8),     # entalhe direito
		Vector2(-8, 8),    # entalhe esquerdo
		Vector2(-16, 14),  # asa esquerda
	])
	draw_colored_polygon(body, Color(0.2, 0.85, 1.0))
	# Cabine
	draw_circle(Vector2(0, -4), 5.0, Color(1.0, 1.0, 1.0))
	# Chama do motor
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, 10), Vector2(5, 10), Vector2(0, 20 + randf() * 6.0),
	]), Color(1.0, 0.55, 0.1))


func _on_body_entered(body: Node) -> void:
	if not _alive or body == null:
		return
	if body.is_in_group("asteroids"):
		_alive = false
		visible = false
		set_process(false)
		# Desliga a colisão para não disparar mais de uma vez.
		get_node("CollisionShape2D").set_deferred("disabled", true)
		died.emit()
