extends ColorRect
## background.gd — colocar no nó "Background" (ColorRect) da cena main.tscn.
## Fundo ANIMADO do espaço: gradiente com cores vibrantes que mudam com o
## tempo, nebulosas coloridas à deriva, estrelas em 3 camadas com parallax
## e planetas com anel que atravessam a tela lentamente.

var _time: float = 0.0
var _stars: Array[Dictionary] = []      # {pos, layer}
var _nebula: Array[Dictionary] = []     # {base, radius, hue, phase, speed}
var _planets: Array[Dictionary] = []    # {x, y, radius, hue, speed, ring}


func _ready() -> void:
	var w := size.x
	var h := size.y

	# 3 camadas de estrelas: quanto menor/mais escura, mais devagar (parallax).
	for i in 90:
		var layer := 1 + (i % 3)
		_stars.append({
			"pos": Vector2(randf() * w, randf() * h),
			"layer": float(layer),
		})

	# Nebulosas: nuvens de gás coloridas que derivam horizontalmente.
	for i in 5:
		_nebula.append({
			"base": Vector2(randf() * w, randf_range(h * 0.1, h * 0.9)),
			"radius": randf_range(90.0, 170.0),
			"hue": randf(),
			"phase": randf() * TAU,
			"speed": randf_range(6.0, 14.0),
		})

	# Planetas que cruzam o fundo lentamente.
	for i in 2:
		_planets.append({
			"x": randf() * w,
			"y": randf_range(h * 0.15, h * 0.75),
			"radius": randf_range(26.0, 48.0),
			"hue": randf(),
			"speed": randf_range(9.0, 18.0),
			"ring": randf() < 0.5,
		})
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var w := size.x

	# Estrelas descem (sensação de a nave voar para cima) + parallax.
	for s in _stars:
		s["pos"].y += (10.0 + 22.0 * s["layer"]) * delta
		if s["pos"].y > size.y:
			s["pos"].y = -2.0
			s["pos"].x = randf() * w

	# Planetas atravessam a tela.
	for p in _planets:
		p["x"] += p["speed"] * delta
		if p["x"] > w + p["radius"] + 60.0:
			p["x"] = -p["radius"] - 60.0
			p["y"] = randf_range(size.y * 0.15, size.y * 0.75)
			p["hue"] = randf()

	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y

	# --- Gradiente vertical com matizes que evoluem lentamente (espaço vivo) ---
	var steps := 24
	var sh := h / float(steps)
	for i in steps:
		var t := float(i) / float(steps)
		var hue1 := fmod(0.62 + 0.10 * sin(_time * 0.07) + t * 0.14, 1.0)
		var c := Color.from_hsv(hue1, 0.75, 0.16 + 0.10 * t)
		draw_rect(Rect2(0.0, float(i) * sh, w, sh + 1.0), c)

	# --- Nebulosas ("nuvens" de gás) com brilho pulsante ---
	for n in _nebula:
		var drift := fmod(n["base"].x + _time * n["speed"], w + 400.0) - 200.0
		var pulse := 0.5 + 0.5 * sin(_time * 0.6 + n["phase"])
		var col := Color.from_hsv(fmod(n["hue"] + _time * 0.02, 1.0), 0.85, 0.9)
		var center := Vector2(drift, n["base"].y)
		var r: float = n["radius"]
		# 3 anéis concêntricos translúcidos => aparência de nuvem suave
		for k in 3:
			var rr := r * (1.0 - 0.28 * float(k))
			draw_circle(center, rr, Color(col.r, col.g, col.b, 0.05 + 0.03 * float(k) + 0.03 * pulse))

	# --- Planetas (com sombra e alguns com anel) ---
	for p in _planets:
		var pos := Vector2(p["x"], p["y"])
		var r: float = p["radius"]
		var col := Color.from_hsv(p["hue"], 0.65, 0.85)
		if p["ring"]:
			draw_set_transform(pos, 0.35, Vector2.ONE)
			draw_arc(Vector2.ZERO, r * 1.6, 0.0, TAU, 40,
				Color.from_hsv(fmod(p["hue"] + 0.5, 1.0), 0.5, 0.95, 0.55), 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(pos, r, col)
		# Sombra do planeta (lado escuro)
		draw_circle(pos + Vector2(r * 0.35, r * 0.25), r * 0.9,
			Color(col.r * 0.35, col.g * 0.35, col.b * 0.4, 0.6))
		# Faixa atmosférica
		draw_line(pos + Vector2(-r * 0.7, -r * 0.2), pos + Vector2(r * 0.7, -r * 0.2),
			Color(1, 1, 1, 0.12), r * 0.25)

	# --- Estrelas cintilantes ---
	for s in _stars:
		var b := 0.35 + 0.65 * absf(sin(_time * (1.5 + s["layer"]) + s["pos"].x))
		var sz: float = 0.7 + 0.5 * s["layer"]
		draw_circle(s["pos"], sz, Color(b, b, minf(1.0, b + 0.15)))
