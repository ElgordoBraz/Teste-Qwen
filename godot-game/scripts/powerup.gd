extends Node2D
## powerup.gd — Power-up criado por código (pool do Main). Flutua para baixo
## com leve balanço; coletado por distância até a nave.
## Tipos: TRIPLE (tiro triplo 12s), RAPID (cadência dobrada 10s),
## SHIELD (escudo 8s), LIFE (+1 vida), MAGNET? (não — mantemos 4 limpos).

enum Type { TRIPLE, RAPID, SHIELD, LIFE }

var ptype: int = Type.TRIPLE
var fall_speed := 130.0
var collected := false
var _t := 0.0
var _base_x := 0.0

const COLORS := {
Type.TRIPLE: Color(1.0, 0.85, 0.2),
Type.RAPID:  Color(0.3, 1.0, 0.5),
Type.SHIELD: Color(0.35, 0.7, 1.0),
Type.LIFE:   Color(1.0, 0.35, 0.55),
}
const LABELS := {
Type.TRIPLE: "T",
Type.RAPID:  "R",
Type.SHIELD: "S",
Type.LIFE:   "+",
}


func launch(t: int, pos: Vector2) -> void:
ptype = t
position = pos
_base_x = pos.x
collected = false
_t = 0.0
visible = true


func deactivate() -> void:
visible = false
if get_parent():
get_parent().remove_child(self)


func _process(delta: float) -> void:
_t += delta
position.y += fall_speed * delta
position.x = _base_x + sin(_t * 2.4) * 22.0
queue_redraw()
var vp := get_viewport_rect().size
if position.y > vp.y + 40.0:
get_tree().call_group("main", "release_powerup", self)


func _draw() -> void:
var c: Color = COLORS[ptype]
var pulse := 1.0 + 0.12 * sin(_t * 6.0)
draw_circle(Vector2.ZERO, 15.0 * pulse, Color(c.r, c.g, c.b, 0.22))
draw_circle(Vector2.ZERO, 11.0, Color(0.05, 0.06, 0.12, 0.92))
draw_arc(Vector2.ZERO, 11.0, 0, TAU, 24, c, 2.0)
# Letra desenhada por linhas (sem fonte no Node2D)
var s := 6.0
match ptype:
Type.TRIPLE:
for dx in [-3.0, 0.0, 3.0]:
draw_line(Vector2(dx, -s), Vector2(dx, s), c, 1.6)
Type.RAPID:
draw_line(Vector2(-2, -s), Vector2(3, -1), c, 1.8)
draw_line(Vector2(3, -1), Vector2(-3, 1), c, 1.8)
draw_line(Vector2(-3, 1), Vector2(2, s), c, 1.8)
Type.SHIELD:
draw_polyline(PackedVector2Array([
Vector2(-5, -5), Vector2(0, -7), Vector2(5, -5),
Vector2(4, 3), Vector2(0, 7), Vector2(-4, 3), Vector2(-5, -5)]), c, 1.8)
Type.LIFE:
draw_line(Vector2(0, -s), Vector2(0, s), c, 2.0)
draw_line(Vector2(-s, 0), Vector2(s, 0), c, 2.0)
