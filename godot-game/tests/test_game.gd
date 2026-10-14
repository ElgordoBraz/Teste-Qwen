extends SceneTree
## test_game.gd — suíte headless: carrega main.tscn, roda frames reais do jogo
## e verifica cada requisito novo. Executar com:
##   godot --headless --path godot-game -s res://tests/test_game.gd

const MAIN_SCENE := preload("res://scenes/main.tscn")

var _fails: int = 0


func _initialize() -> void:
	print("=== INICIANDO TESTES ===")
	# Sem viewport em modo headless, força o tamanho da tela para os clamps.
	root.size = Vector2i(800, 600)
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	for i in 5:
		await process_frame
	_test_idle_no_free_score(main)
	await _test_asteroids_move(main)
	# Input real (push_input) não é processado no modo headless => injetamos o eixo.
	Input.action_press("move_up")
	var axis_ok := absf(Input.get_axis("move_left", "move_right")) < 0.01 \
		and Input.get_axis("move_up", "move_down") < -0.9
	Input.action_release("move_up")
	_check("Input.get_axis respeita a ordem (up,-1)", axis_ok, "")
	InputMap.action_erase_events("move_up")
	InputMap.action_erase_events("move_down")
	InputMap.action_erase_events("shoot")
	await _test_ship_4dir_and_tilt(main)
	await _test_shooting_cadence(main)
	await _test_bullet_kills_asteroid(main)
	await _test_leak_costs_life(main)
	await _test_background_animates(main)
	await _test_restart(main)
	if _fails == 0:
		print("=== TODOS OS TESTES PASSARAM ===")
	else:
		print("=== FALHAS: %d ===" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(name: String, ok: bool, info: String = "") -> void:
	if ok:
		print("PASS  %s  (%s)" % [name, info])
	else:
		_fails += 1
		print("FAIL  %s  (%s)" % [name, info])


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _restart_main(main: Node) -> void:
	main._start_game()
	await _frames(3)


# 1) Ficar parado NÃO pode render pontos grátis (jogo mais desafiador).
func _test_idle_no_free_score(main: Node) -> void:
	await _frames(60)
	var score: int = main._score
	_check("parado nao ganha pontos", score == 0, "score=%d apos ~1s parado" % score)


# 2) Asteroides caem (dinâmica) mesmo sem input.
func _test_asteroids_move(main: Node) -> void:
	var ast: Array = get_nodes_in_group("asteroids")
	while ast.is_empty():
		await process_frame
		ast = get_nodes_in_group("asteroids")
	var a = ast[0]
	while a.position.y < -50.0:  # espera sair da área de spawn acima da tela
		await process_frame
	var y0: float = a.position.y
	await _frames(30)
	if not is_instance_valid(a):
		a = get_nodes_in_group("asteroids")[0]
	_check("asteroides caem", a.position.y > y0, "y %.1f -> %.1f" % [y0, a.position.y])


# 3) Nave anda para cima/baixo/esquerda/direita e inclina ao andar de lado.
# (headless ignora push_input => usamos Input.action_press diretamente)
func _test_ship_4dir_and_tilt(main: Node) -> void:
	var p: Area2D = main.player

	# --- teste A: sem atrito, isola o efeito da tecla em janelas curtas ---
	p.friction = 0.0
	await _restart_main(main)
	p.position = Vector2(400, 300)

	Input.action_press("move_up"); await _frames(15)
	var up_ok: bool = p._velocity.y < -10.0 and p.position.y < 300.0
	Input.action_release("move_up")
	p._velocity = Vector2.ZERO; p.position = Vector2(400, 300); await _frames(2)

	Input.action_press("move_down"); await _frames(15)
	var down_ok: bool = p._velocity.y > 10.0 and p.position.y > 300.0
	Input.action_release("move_down")
	p._velocity = Vector2.ZERO; p.position = Vector2(400, 300); await _frames(2)

	Input.action_press("move_left"); await _frames(15)
	var left_ok: bool = p._velocity.x < -10.0 and p.position.x < 400.0
	var tilt_left_ok := p.rotation > 0.05  # banca para esquerda
	Input.action_release("move_left")
	p._velocity = Vector2.ZERO; p.position = Vector2(400, 300); p.rotation = 0.0
	await _frames(2)

	Input.action_press("move_right"); await _frames(15)
	var right_ok: bool = p._velocity.x > 10.0 and p.position.x > 400.0
	var tilt_right_ok := p.rotation < -0.05
	Input.action_release("move_right")
	p._velocity = Vector2.ZERO

	# --- teste B: com atrito realista, a nave PARA ao soltar as teclas ---
	p.friction = 1400.0
	Input.action_press("move_right"); await _frames(20)
	Input.action_release("move_right"); await _frames(60)
	var stop_ok: bool = p._velocity.length() < 1.0

	_check("mover para cima (W)", up_ok, "vel.y=%.0f y=%.0f" % [p._velocity.y, p.position.y])
	_check("mover para baixo (S)", down_ok, "")
	_check("mover para esquerda (A)", left_ok, "")
	_check("inclina a esquerda", tilt_left_ok, "rot=%.2f" % rot_l)
	_check("mover para direita (D)", right_ok, "")
	_check("inclina a direita", tilt_right_ok, "rot=%.2f" % rot_r)
	_check("atrito faz a nave parar", stop_ok, "vel=%.1f" % p._velocity.length())


# 4) Canhão: segurar ação não vira metralhadora (cadência >= cooldown).
func _test_shooting_cadence(main: Node) -> void:
	await _restart_main(main)
	main.player.fire_cooldown = 0.4  # acelera p/ medir cadência; produção usa 0.75
	Input.action_press("shoot")
	var times: Array[float] = []
	for f in 90:  # ~1.5 s segurando o tiro
		await process_frame
		for b in get_nodes_in_group("bullets"):
			if not b.get_meta("seen", false):
				b.set_meta("seen", true)
				times.append(float(f))
	Input.action_release("shoot")
	var count := times.size()
	var min_gap := 999.0
	for i in range(1, count):
		min_gap = minf(min_gap, times[i] - times[i - 1])
	_check("tiro existe", count >= 2, "%d balas em ~1.5s" % count)
	_check("cadencia baixa (nao metralhadora)", min_gap >= 30.0,
		"gap min entre tiros=%.0f frames (~%.2fs)" % [min_gap, min_gap / 60.0])
	main.player.fire_cooldown = 0.75


# 5) Tiro forte: uma bala tira HP; acertos suficientes destroem a pedra (+25 pts).
func _test_bullet_kills_asteroid(main: Node) -> void:
	await _restart_main(main)
	var asts: Array = get_nodes_in_group("asteroids")
	while asts.is_empty():
		await process_frame
		asts = get_nodes_in_group("asteroids")
	var a = asts[0]
	var hp0: int = a.hp_max
	a.hit()
	var hp1: int = a._hp
	for i in hp0 - 1:
		if is_instance_valid(a):
			a.hit()
	await _frames(2)
	var dead := not is_instance_valid(a)
	_check("hit reduz hp", hp1 == hp0 - 1, "hp %d->%d" % [hp0, hp1])
	_check("pedra destruida apos %d tiros" % hp0, dead, "hp_max=%d" % hp0)
	_check("abate deu +25 pontos", main._score == 25, "score=%d" % main._score)


# 6) Pedra que escapa pela base custa vida e pontos (fim do farming parado).
func _test_leak_costs_life(main: Node) -> void:
	await _restart_main(main)
	var lives0: int = main._lives
	main._score = 100
	var asts: Array = get_nodes_in_group("asteroids")
	while asts.is_empty():
		await process_frame
		asts = get_nodes_in_group("asteroids")
	var a = asts[0]
	a.position = Vector2(100, 555)  # força a travessia da linha de escape
	a._fall_speed = 600.0
	await _frames(15)
	_check("escapar custa 1 vida", main._lives == lives0 - 1,
		"vidas %d->%d" % [lives0, main._lives])
	_check("escapar da -50 pontos", main._score <= 50, "score=%d" % main._score)


# 7) Fundo animado: gradiente/nebulosas/planetas redesenham a cada frame.
func _test_background_animates(main: Node) -> void:
	var bg: ColorRect = main.get_node("Background")
	var t0: float = bg._time
	await _frames(30)
	var planets_moved := false
	for p in bg._planets:
		if absf(p["speed"]) > 0.0:
			planets_moved = true
	_check("fundo anima (tempo avanca)", bg._time > t0, "t=%.2f" % bg._time)
	_check("fundo tem planetas/nebulosas",
		bg._planets.size() >= 2 and bg._nebula.size() >= 3,
		"%d planetas, %d nebulosas, %d estrelas" % [bg._planets.size(), bg._nebula.size(), bg._stars.size()])
	_check("planetas tem velocidade", planets_moved, "")


# 8) Game over por perda de vidas + reinício com R restaura tudo.
func _test_restart(main: Node) -> void:
	await _restart_main(main)
	main._lives = 1
	main._on_asteroid_passed()  # última vida => game over
	await _frames(2)
	_check("sem vidas => game over",
		not main._game_active and main.game_over_panel.visible, "")
	main._start_game()  # mesma rotina que a tecla R dispara via _unhandled_input
	await _frames(3)
	_check("R reinicia partida", main._game_active and main._lives == 3,
		"lives=%d score=%d" % [main._lives, main._score])
