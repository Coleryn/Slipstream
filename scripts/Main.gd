extends Node2D

## Root of the game. Owns the run: scoring, crashes, death, restart.

@export var feedback: FeedbackConfig
@export var difficulty: DifficultyConfig

@export_group("Scoring")
@export_range(1.0, 200.0, 1.0) var points_per_second: float = 12.0
@export_range(1, 500, 1) var crash_bonus: int = 50

@export_range(1.0, 5.0, 0.5) var pulse_crash_multiplier: float = 2.0

@export_group("Input")
@export var second_finger_pulse: bool = true

@export_group("Combo")
@export_range(0.5, 5.0, 0.1) var combo_window: float = 2.0
@export_range(2, 16, 1) var combo_cap: int = 8

@onready var _camera: Camera2D = $Camera
@onready var _spawner: Spawner = $Spawner
@onready var _player: Player = $Player
@onready var _burst: Burst = $Burst
@onready var _shockwaves: Shockwaves = $Shockwaves
@onready var _popups: Popups = $Popups
@onready var _hud: HUD = $HUD
@onready var _game_over: GameOver = $GameOver
@onready var _pause_overlay: PauseOverlay = $PauseOverlay

var _dead: bool = false
var _shake_left: float = 0.0
var _shake_total: float = 0.0
var _shake_strength: float = 0.0
var _slowmo_token: int = 0
var _death_token: int = 0


func _ready() -> void:
	if feedback == null:
		feedback = FeedbackConfig.new()
	if difficulty == null:
		difficulty = DifficultyConfig.new()
	AudioManager.placeholder_enabled = feedback.placeholder_audio
	GameState.reset()
	_player.died.connect(_on_player_died)
	_player.shield_gained.connect(_on_shield_gained)
	_player.shield_blocked.connect(_on_shield_blocked)
	_spawner.squares_crashed.connect(_on_squares_crashed)
	_game_over.restart_pressed.connect(_restart)
	_hud.pulse_pressed.connect(_try_pulse)
	_hud.pause_pressed.connect(_pause_game)
	_game_over.menu_pressed.connect(_to_menu)
	_pause_overlay.resumed.connect(_resume_game)
	_pause_overlay.menu_requested.connect(_to_menu)
	_hud.play_intro()


func _process(delta: float) -> void:
	if not _dead:
		GameState.advance_time(delta, difficulty.base_speed, difficulty.speed_growth, difficulty.max_speed)
		GameState.add_score(points_per_second * delta)
		GameState.tick_combo(delta)
		_check_near_miss()
	_hud.set_pulse_state(_player.pulse_cooldown_left / maxf(feedback.pulse_cooldown, 0.001))
	_update_shake(delta)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Palette.BACKGROUND)


func _check_near_miss() -> void:
	var player_radius: float = _player.radius
	for square in _spawner.active_squares():
		if square.is_pickup():
			continue
		square.track_player(_player.position, player_radius)
		if square.near_miss_done():
			continue
		if not square.has_passed_player(_player.position, player_radius):
			continue
		if square.closest_gap() > 0.0 and square.closest_gap() <= feedback.near_miss_distance:
			square.mark_near_miss()
			_player.pulse()
			AudioManager.play_near_miss()


func _on_squares_crashed(first: Square, second: Square) -> void:
	if _dead:
		return
	var first_color: Color = first.get_draw_color()
	var second_color: Color = second.get_draw_color()
	var first_position: Vector2 = first.position
	var second_position: Vector2 = second.position
	var impact: Vector2 = (first_position + second_position) * 0.5
	var multiplier: int = GameState.register_crash(combo_window, combo_cap)
	var points: float = maxf(first.point_multiplier(), second.point_multiplier())
	var pulse_crash: bool = first.has_pulse_credit() or second.has_pulse_credit()
	var major: bool = pulse_crash or points > 1.0 or multiplier >= feedback.slowmo_major_combo
	if pulse_crash:
		points *= pulse_crash_multiplier
	var awarded: int = int(round(float(crash_bonus) * float(multiplier) * points))
	GameState.add_score(float(awarded))
	_shockwaves.emit(first_position, first_color, first.size)
	_shockwaves.emit(second_position, second_color, second.size)
	_burst.emit_burst(first_position, first_color, feedback.crash_particles, feedback.crash_particle_speed, feedback.particle_size, feedback.particle_lifetime)
	_burst.emit_burst(second_position, second_color, feedback.crash_particles, feedback.crash_particle_speed, feedback.particle_size, feedback.particle_lifetime)
	_popups.show_text(impact, "+%d" % awarded, feedback.popup_rise, feedback.popup_lifetime, feedback.popup_font_size)
	_start_shake(feedback.crash_shake_duration, feedback.crash_shake_strength)
	if major:
		_start_slowmo(feedback.slowmo_scale, feedback.slowmo_duration)
	else:
		_start_slowmo(feedback.slowmo_minor_scale, feedback.slowmo_minor_duration)
	AudioManager.play_crash(multiplier)


func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	var touch := event as InputEventScreenTouch
	if second_finger_pulse and touch != null and touch.pressed and touch.index >= 1:
		_try_pulse()
		return
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_SPACE:
		_try_pulse()


func _try_pulse() -> void:
	if _dead:
		return
	if not _player.pulse_ready():
		return
	_player.start_pulse()
	var origin: Vector2 = _player.position
	var radius: float = feedback.pulse_radius
	for square in _spawner.active_squares():
		var offset: Vector2 = square.position - origin
		if offset.length() <= radius + square.size * 0.5:
			square.apply_push(offset, feedback.pulse_push_strength, feedback.pulse_push_duration, feedback.pulse_square_shake, feedback.pulse_credit_time)
	AudioManager.play_pulse()


func _on_shield_gained(pickup: Square) -> void:
	_spawner.recycle_square(pickup)


func _on_shield_blocked(square: Square) -> void:
	_burst.emit_burst(square.position, square.get_draw_color(), feedback.crash_particles, feedback.crash_particle_speed, feedback.particle_size, feedback.particle_lifetime)
	_spawner.recycle_square(square)
	_start_shake(feedback.crash_shake_duration, feedback.crash_shake_strength)
	AudioManager.play_crash(GameState.combo)


func _on_player_died() -> void:
	if _dead:
		return
	_dead = true
	_death_token += 1
	_slowmo_token += 1
	_spawner.freeze_all()
	_hud.show_pulse_button(false)
	_hud.show_pause_button(false)
	AudioManager.set_music_ducked(true)
	_player.play_death(feedback.player_shrink_time)
	_burst.emit_burst(_player.position, Palette.PLAYER, feedback.death_particles, feedback.particle_speed, feedback.particle_size, feedback.particle_lifetime)
	AudioManager.play_death()
	GameState.reset_combo()
	var new_best: bool = GameState.commit_high_score()
	_run_death_sequence(_death_token, new_best)


func _run_death_sequence(token: int, new_best: bool) -> void:
	Engine.time_scale = 0.0
	await get_tree().create_timer(feedback.freeze_frame, false, false, true).timeout
	if token != _death_token:
		return
	Engine.time_scale = 1.0
	_start_shake(feedback.shake_duration, feedback.shake_strength)
	await get_tree().create_timer(feedback.ui_delay, false, false, true).timeout
	if token != _death_token:
		return
	_game_over.show_result(int(GameState.score), GameState.high_score, new_best, feedback.ui_fade_time)


func _start_slowmo(time_scale: float, duration: float) -> void:
	_slowmo_token += 1
	var token: int = _slowmo_token
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, false, false, true).timeout
	if token != _slowmo_token:
		return
	Engine.time_scale = 1.0


func _restart() -> void:
	_death_token += 1
	_slowmo_token += 1
	Engine.time_scale = 1.0
	AudioManager.set_music_ducked(false)
	_dead = false
	_shake_left = 0.0
	_camera.offset = Vector2.ZERO
	_game_over.hide_result()
	_hud.show_pulse_button(true)
	_hud.show_pause_button(true)
	_burst.clear()
	_shockwaves.clear()
	_popups.clear()
	GameState.reset()
	_spawner.reset()
	_player.reset()
	_hud.play_intro()


func _start_shake(duration: float, strength: float) -> void:
	if not feedback.shake_enabled:
		return
	_shake_left = duration
	_shake_total = maxf(duration, 0.001)
	_shake_strength = minf(strength, feedback.max_shake_strength)


func _update_shake(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	if is_zero_approx(_shake_left):
		_camera.offset = Vector2.ZERO
		return
	var falloff: float = _shake_left / _shake_total
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength * falloff

func _pause_game() -> void:
	if _dead or get_tree().paused:
		return
	_pause_overlay.show_overlay()
	AudioManager.set_music_ducked(true)
	get_tree().paused = true


func _resume_game() -> void:
	_pause_overlay.hide_overlay()
	AudioManager.set_music_ducked(false)
	get_tree().paused = false


func _to_menu() -> void:
	AudioManager.set_music_ducked(false)
	Engine.time_scale = 1.0
	get_tree().paused = false
	Transition.change_scene("res://scenes/Menu.tscn")
