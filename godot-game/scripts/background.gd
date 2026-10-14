extends ColorRect
## background.gd — colocar no nó "Background" (ColorRect) da cena main.tscn.
## Desenha estrelas cintilantes sobre o fundo escuro do espaço.

var _stars: Array[Vector2] = []
var _twinkle: float = 0.0


func _ready() -> void:
	for i in 60:
		_stars.append(Vector2(randf() * size.x, randf() * size.y))
	queue_redraw()


func _process(delta: float) -> void:
	_twinkle += delta
	queue_redraw()


func _draw() -> void:
	for s in _stars:
		var b := 0.4 + 0.6 * absf(sin(_twinkle * 2.0 + s.x))
		draw_circle(s, 1.5, Color(b, b, minf(1.0, b + 0.2)))
