extends Node2D

## Root of the game. Owns the run: score ticking, crashes, death, restart.

@export var feedback: FeedbackConfig
@export_range(1, 500, 1) var crash_bonus: int = 50

@onready var _camera: Camera2D = $Camera
@onready var _spawner: Spawner = $Spawner
@onready var _player: Player = $Player
@onready var _burst: Burst = $Burst
@onready var _popups: Popups = $Popups
@onready var _game_over: GameOver = $GameOver

var _dead: bool = false
var _score_accumulator: float = 0.0
var _shake_left: float = 0.0
var _shake_total: float = 0.0
var _shake_strength: float = 0.0
var _slowmo_token: int = 0
var _death_token: int = 0


func _ready() -> void:
	if feedback == null:
		feedback = FeedbackConfig.new()
	GameState.reset()
	_player.died.connect(_on_player_died)
	_spawner.squares_crashed.connect(_on_squares_crashed)
	_game_over.restart_pressed.connect(_restart)


func _process(delta: float) -> void:
	if not _dead:
		_tick_score(delta)
	_update_shake(delta)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Palette.BACKGROUND)


func _on_squares_crashed(first: Square, second: Square) -> void:
	if _dead:
		return
	var first_color: Color = first.get_draw_color()
	var second_color: Color = second.get_draw_color()
	var first_position: Vector2 = first.position
	var second_position: Vector2 = second.position
	var impact: Vector2 = (first_position + second_position) * 0.5
	GameState.score += crash_bonus
	_burst.emit_burst(first_position, first_color, feedback.crash_particles, feedback.crash_particle_speed, feedback.particle_size, feedback.particle_lifetime)
	_burst.emit_burst(second_position, second_color, feedback.crash_particles, feedback.crash_particle_speed, feedback.particle_size, feedback.particle_lifetime)
	_popups.show_text(impact, "+%d" % crash_bonus, feedback.popup_rise, feedback.popup_lifetime, feedback.popup_font_size)
	_start_shake(feedback.crash_shake_duration, feedback.crash_shake_strength)
	_start_slowmo()


func _on_player_died() -> void:
	if _dead:
		return
	_dead = true
	_death_token += 1
	_slowmo_token += 1
	_spawner.freeze_all()
	_player.play_death(feedback.player_shrink_time)
	_burst.emit_burst(_player.position, Palette.PLAYER, feedback.death_particles, feedback.particle_speed, feedback.particle_size, feedback.particle_lifetime)
	GameState.commit_high_score()
	_run_death_sequence(_death_token)


func _run_death_sequence(token: int) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(feedback.freeze_frame, true, false, true).timeout
	if token != _death_token:
		return
	Engine.time_scale = 1.0
	_start_shake(feedback.shake_duration, feedback.shake_strength)
	await get_tree().create_timer(feedback.ui_delay, true, false, true).timeout
	if token != _death_token:
		return
	_game_over.show_result(GameState.score, GameState.high_score, feedback.ui_fade_time)


func _start_slowmo() -> void:
	_slowmo_token += 1
	var token: int = _slowmo_token
	Engine.time_scale = feedback.slowmo_scale
	await get_tree().create_timer(feedback.slowmo_duration, true, false, true).timeout
	if token != _slowmo_token:
		return
	Engine.time_scale = 1.0


func _restart() -> void:
	_death_token += 1
	_slowmo_token += 1
	Engine.time_scale = 1.0
	_dead = false
	_score_accumulator = 0.0
	_shake_left = 0.0
	_camera.offset = Vector2.ZERO
	_game_over.hide_result()
	_burst.clear()
	_popups.clear()
	GameState.reset()
	_spawner.reset()
	_player.reset()


func _tick_score(delta: float) -> void:
	_score_accumulator += delta
	while _score_accumulator >= 1.0:
		_score_accumulator -= 1.0
		GameState.score += 1


func _start_shake(duration: float, strength: float) -> void:
	if not feedback.shake_enabled:
		return
	_shake_left = duration
	_shake_total = maxf(duration, 0.001)
	_shake_strength = strength


func _update_shake(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	if is_zero_approx(_shake_left):
		_camera.offset = Vector2.ZERO
		return
	var falloff: float = _shake_left / _shake_total
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * falloff
