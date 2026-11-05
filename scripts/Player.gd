class_name Player
extends Area2D

## The white circle. Fixed Y near the bottom, dragged left/right on X only.

signal died
signal shield_gained(pickup: Square)
signal shield_blocked(square: Square)

@export var feedback: FeedbackConfig

@export_group("Shape")
@export var radius: float = 16.0:
	set(value):
		radius = value
		_sync_hitbox()
@export_range(0.1, 1.0, 0.05) var hitbox_scale: float = 0.8:
	set(value):
		hitbox_scale = value
		_sync_hitbox()

@export_group("Movement")
@export var bottom_margin: float = 120.0
@export_range(1.0, 40.0, 0.5) var smoothing: float = 14.0
@export_range(0.1, 3.0, 0.05) var drag_sensitivity: float = 1.0

var _target_x: float = 0.0
var _dragging: bool = false
var _touch_index: int = -1
var _dead: bool = false
var _death_tween: Tween
var _intro: float = 1.0
var _pulse_left: float = 0.0
var shield_time: float = 0.0
var pulse_cooldown_left: float = 0.0
var _pulse_ring_left: float = 0.0
var _shield_intro: float = 0.0
var _trail_points: Array[Vector2] = []
var _trail_ages: Array[float] = []
var _trail_timer: float = 0.0


func _ready() -> void:
	if feedback == null:
		feedback = FeedbackConfig.new()
	area_entered.connect(_on_area_entered)
	reset()


func _process(delta: float) -> void:
	if _dead:
		return
	if _dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging = false
	position.x = lerpf(position.x, _target_x, 1.0 - exp(-smoothing * delta))
	if _intro < 1.0:
		_intro = minf(_intro + delta / maxf(feedback.player_fade_in_time, 0.001), 1.0)
	if _pulse_left > 0.0:
		_pulse_left = maxf(_pulse_left - delta, 0.0)
	if shield_time > 0.0:
		shield_time = maxf(shield_time - delta, 0.0)
		_shield_intro = minf(_shield_intro + delta / maxf(feedback.shield_expand_time, 0.001), 1.0)
	pulse_cooldown_left = maxf(pulse_cooldown_left - delta, 0.0)
	if _pulse_ring_left > 0.0:
		_pulse_ring_left = maxf(_pulse_ring_left - delta, 0.0)
	_update_trail(delta)
	queue_redraw()


func _draw() -> void:
	var intro_curve: float = 0.85 + 0.15 * _intro
	var pulse_curve: float = 0.0
	if _pulse_left > 0.0:
		pulse_curve = _pulse_left / maxf(feedback.near_miss_pulse_time, 0.001)
	var draw_radius: float = radius * intro_curve * (1.0 + feedback.near_miss_pulse_scale * pulse_curve)
	for i in _trail_points.size():
		var t: float = clampf(_trail_ages[i] / maxf(feedback.trail_lifetime, 0.001), 0.0, 1.0)
		var fade: float = (1.0 - t) * feedback.trail_alpha * _intro
		var trail_radius: float = draw_radius * (1.0 - feedback.trail_shrink * t)
		draw_circle(to_local(_trail_points[i]), trail_radius, Color(Palette.PLAYER, fade), true, -1.0, true)
	draw_circle(Vector2.ZERO, draw_radius, Color(Palette.PLAYER, _intro), true, -1.0, true)
	draw_circle(Vector2.ZERO, draw_radius * feedback.player_inner_ratio, Color(Palette.PLAYER_INNER, _intro), true, -1.0, true)
	if shield_time > 0.0:
		var ring_radius: float = lerpf(radius * 1.9, radius + feedback.shield_ring_gap, ease(_shield_intro, 0.4))
		var flicker: float = 1.0
		if shield_time < feedback.shield_flicker_time:
			flicker = 0.35 + 0.65 * absf(sin(shield_time * feedback.shield_flicker_speed))
		var ring_color: Color = Color(Palette.PLAYER, feedback.shield_alpha * _shield_intro * flicker)
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 48, ring_color, feedback.shield_ring_width, true)

	if _pulse_ring_left > 0.0:
		var ring_t: float = 1.0 - _pulse_ring_left / maxf(feedback.pulse_ring_time, 0.001)
		var pulse_radius: float = lerpf(radius, feedback.pulse_radius, ease(ring_t, 0.35))
		var pulse_color: Color = Color(Palette.PLAYER, feedback.pulse_ring_alpha * (1.0 - ring_t))
		draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 64, pulse_color, feedback.pulse_ring_width, true)


func pulse_ready() -> bool:
	return pulse_cooldown_left <= 0.0


func start_pulse() -> void:
	pulse_cooldown_left = maxf(feedback.pulse_cooldown, 0.0)
	_pulse_ring_left = maxf(feedback.pulse_ring_time, 0.01)
	queue_redraw()

func pulse() -> void:
	_pulse_left = maxf(feedback.near_miss_pulse_time, 0.01)


func activate_shield(duration: float) -> void:
	shield_time = maxf(duration, 0.0)
	_shield_intro = 0.0
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			_touch_index = touch.index
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
		return

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_drag(drag.relative.x)
		return

	if _touch_index != -1:
		return

	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			_dragging = button.pressed
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_drag(motion.relative.x)


func play_death(duration: float) -> void:
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	_death_tween = create_tween()
	_death_tween.tween_property(self, "scale", Vector2.ZERO, maxf(duration, 0.01)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_death_tween.tween_callback(hide)


func reset() -> void:
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	_dead = false
	_dragging = false
	_touch_index = -1
	scale = Vector2.ONE
	_intro = 0.0
	_pulse_left = 0.0
	shield_time = 0.0
	_shield_intro = 0.0
	pulse_cooldown_left = 0.0
	_pulse_ring_left = 0.0
	show()
	set_process(true)
	set_process_unhandled_input(true)
	_trail_points.clear()
	_trail_ages.clear()
	_trail_timer = 0.0
	var field: Vector2 = get_viewport_rect().size
	position = Vector2(field.x * 0.5, field.y - bottom_margin)
	_target_x = position.x
	_sync_hitbox()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	var square := area as Square
	if square == null or not square.visible:
		return
	if square.is_pickup():
		activate_shield(square.shield_duration())
		shield_gained.emit(square)
		return
	if shield_time > 0.0:
		shield_time = 0.0
		_shield_intro = 0.0
		shield_blocked.emit(square)
		return
	_dead = true
	_dragging = false
	set_process_unhandled_input(false)
	died.emit()


func _drag(relative_x: float) -> void:
	_target_x = clampf(_target_x + relative_x * drag_sensitivity, radius, _max_x())


func _max_x() -> float:
	return get_viewport_rect().size.x - radius


func _update_trail(delta: float) -> void:
	for i in _trail_ages.size():
		_trail_ages[i] += delta
	while not _trail_ages.is_empty() and _trail_ages[-1] >= feedback.trail_lifetime:
		_trail_ages.pop_back()
		_trail_points.pop_back()
	_trail_timer -= delta
	if _trail_timer > 0.0:
		return
	_trail_timer = feedback.trail_interval
	if _trail_points.is_empty() or _trail_points[0].distance_squared_to(position) > 1.0:
		_trail_points.push_front(position)
		_trail_ages.push_front(0.0)


func _sync_hitbox() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var circle := shape_node.shape as CircleShape2D
	if circle == null:
		return
	circle.radius = radius * hitbox_scale
