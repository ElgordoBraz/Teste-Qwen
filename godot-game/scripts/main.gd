extends Node2D
## main.gd — colocar no nó raiz "Main" (Node2D) da cena main.tscn.
## Orquestra o jogo: spawna asteroides, gerencia placar/vidas/dificuldade,
## adiciona as balas criadas pelo Player e alterna gameplay/Game Over (R).

@export var asteroid_scene: PackedScene  # já ligado a scenes/asteroid.tscn no .tscn

@onready var player: Area2D = $Player
@onready var score_label: Label = $UI/ScoreLabel
@onready var lives_label: Label = $UI/LivesLabel
@onready var game_over_panel: PanelContainer = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/VBox/FinalScoreLabel

const SPAWN_Y := -60.0
const SCORE_PASS := 10    # pedra que escapou pela base (sobrevivência)
const SCORE_KILL := 25    # pedra destruída a tiro
const SCORE_LEAK := -50   # penalidade por deixar uma pedra escapar
const START_LIVES := 3

var _score: int = 0
var _lives: int = START_LIVES
var _game_active: bool = false
var _spawn_timer: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	player.position = Vector2(400.0, 520.0)
	player.died.connect(_on_player_died)
	player.shot_fired.connect(_on_shot_fired)
	_start_game()


func _start_game() -> void:
	_score = 0
	_lives = START_LIVES
	_elapsed = 0.0
	_spawn_timer = 0.0
	_game_active = true
	game_over_panel.visible = false
	player.revive()
	player.position = Vector2(400.0, 520.0)
	_update_hud()
	# Limpa asteroides/balas de uma partida anterior.
	get_tree().call_group("asteroids", "queue_free")
	get_tree().call_group("bullets", "queue_free")


func _process(delta: float) -> void:
	if not _game_active:
		return

	_elapsed += delta

	# Dificuldade progressiva: intervalo de spawn cai de 0,9s até 0,28s.
	var interval := clampf(0.9 - _elapsed * 0.012, 0.28, 0.9)
	_spawn_timer += delta
	if _spawn_timer >= interval:
		_spawn_timer = 0.0
		_spawn_asteroid()


func _unhandled_input(event: InputEvent) -> void:
	if not _game_active and event.is_action_pressed("restart"):
		_start_game()


func _spawn_asteroid() -> void:
	if asteroid_scene == null:
		push_error("asteroid_scene não atribuído! Arraste scenes/asteroid.tscn no Inspetor do nó Main.")
		return
	var asteroid := asteroid_scene.instantiate()
	add_child(asteroid)
	var vw := get_viewport_rect().size.x
	asteroid.position = Vector2(randf_range(30.0, vw - 30.0), SPAWN_Y)
	# Velocidade escala com o tempo de jogo (mais difícil com o passar dos segundos).
	asteroid.min_speed = 170.0 + _elapsed * 3.0
	asteroid.max_speed = 340.0 + _elapsed * 5.0
	asteroid.passed.connect(_on_asteroid_passed)
	asteroid.destroyed.connect(_on_asteroid_destroyed)


func _on_shot_fired(bullet: Node2D) -> void:
	add_child(bullet)


func _on_asteroid_passed() -> void:
	if not _game_active:
		return
	# Pedra escapou => perde vida e pontos. Antes era só "+10 grátis".
	_lives -= 1
	_score = maxi(0, _score + SCORE_LEAK)
	_update_hud()
	if _lives <= 0:
		_on_player_died()


func _on_asteroid_destroyed() -> void:
	if _game_active:
		_score += SCORE_KILL
		_update_hud()


func _update_hud() -> void:
	score_label.text = "Pontos: %d" % _score
	lives_label.text = "Vidas: " + "♥".repeat(maxi(_lives, 0))


func _on_player_died() -> void:
	_game_active = false
	final_score_label.text = "Pontuação final: %d" % _score
	game_over_panel.visible = true
