extends Node2D
## main.gd — colocar no nó raiz "Main" (Node2D) da cena main.tscn.
## Orquestra o jogo: spawna asteroides, conta pontos, controla dificuldade,
## alterna entre gameplay e tela de Game Over (R para reiniciar).

@export var asteroid_scene: PackedScene  # arrastar scenes/asteroid.tscn aqui

@onready var player: Area2D = $Player
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_panel: PanelContainer = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/VBox/FinalScoreLabel

var _score: int = 0
var _game_active: bool = false
var _spawn_timer: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	game_over_panel.visible = false
	player.died.connect(_on_player_died)
	_start_game()


func _start_game() -> void:
	_score = 0
	_elapsed = 0.0
	_spawn_timer = 0.0
	_game_active = true
	game_over_panel.visible = false
	score_label.text = "Pontos: 0"
	# Reposiciona e reativa a nave sem recarregar a cena.
	player.position = Vector2(400.0, 520.0)
	player.visible = true
	player.set_process(true)
	var shape := player.get_node_or_null("CollisionShape2D")
	if shape:
		shape.disabled = false
	# Limpa asteroides restantes de uma partida anterior.
	get_tree().call_group("asteroids", "queue_free")


func _process(delta: float) -> void:
	if not _game_active:
		return

	_elapsed += delta
	_score += 1  # sobrevivência gera pontos continuamente
	score_label.text = "Pontos: %d" % _score

	# Dificuldade progressiva: intervalo de spawn cai de 0,9s até 0,25s.
	var interval := clampf(0.9 - _elapsed * 0.01, 0.25, 0.9)
	_spawn_timer += delta
	if _spawn_timer >= interval:
		_spawn_timer = 0.0
		_spawn_asteroid()


func _unhandled_input(event: InputEvent) -> void:
	if not _game_active and event.is_action_pressed("restart"):
		_start_game()


func _spawn_asteroid() -> void:
	if asteroid_scene == null:
		push_error("asteroid_scene não atribuído! Arraste asteroid.tscn na inspetor do nó Main.")
		return
	var asteroid := asteroid_scene.instantiate()
	# Largura da área visível (800 px no projeto).
	var vw := get_viewport_rect().size.x
	asteroid.position = Vector2(randf_range(30.0, vw - 30.0), -60.0)
	add_child(asteroid)


func _on_player_died() -> void:
	_game_active = false
	final_score_label.text = "Pontuação final: %d" % _score
	game_over_panel.visible = true
