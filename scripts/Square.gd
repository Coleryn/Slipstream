class_name Square
extends Area2D

## A falling square. Driven entirely by the Spawner: pooled, reused, never freed.

signal escaped(square: Square)
signal crashed(first: Square, second: Square)

enum Type { NORMAL, FAST, GOLD, BIG }

@export var size: float = 40.0
@export var speed: float = 180.0
@export var type: Type = Type.NORMAL
@export var cull_margin: float = 48.0

var _color: Color = Palette.SQUARE_NORMAL
var _appear: float = 0.0
var _fade_in_time: float = 0.25
var _crashing: bool = false
var _closest_gap: float = 1.0e20
var _near_miss_done: bool = false
var _point_multiplier: float = 1.0
var _homing_rate: float = 0.0
var _max_drift: float = 0.0
var _drift_used: float = 0.0
var _pickup: bool = false
var _shield_duration: float = 0.0
var _player_x: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func activate(variant: SquareVariant, in_size: float, in_speed: float, in_fade_time: float) -> void:
	type = variant.type
	_color = variant.color
	_point_multiplier = variant.point_multiplier
	_homing_rate = variant.homing_rate
	_max_drift = variant.max_drift
	_pickup = variant.is_pickup
	_shield_duration = variant.shield_duration
	_drift_used = 0.0
	_player_x = position.x
	size = in_size
	speed = in_speed
	_fade_in_time = in_fade_time
	_appear = 0.0
	_crashing = false
	_closest_gap = 1.0e20
	_near_miss_done = false
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	set_process(true)
	_sync_shape()
	queue_redraw()


func deactivate() -> void:
	hide()
	set_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func is_crashing() -> bool:
	return _crashing


func begin_crash() -> void:
	_crashing = true


func appear_ratio() -> float:
	return _appear


func is_pickup() -> bool:
	return _pickup


func shield_duration() -> float:
	return _shield_duration


func point_multiplier() -> float:
	return _point_multiplier


func get_draw_color() -> Color:
	return _color


func track_player(player_position: Vector2, player_radius: float) -> float:
	_player_x = player_position.x
	var nearest := Vector2(
		clampf(player_position.x, position.x - size * 0.5, position.x + size * 0.5),
		clampf(player_position.y, position.y - size * 0.5, position.y + size * 0.5))
	var gap: float = nearest.distance_to(player_position) - player_radius
	_closest_gap = minf(_closest_gap, gap)
	return gap


func closest_gap() -> float:
	return _closest_gap


func has_passed_player(player_position: Vector2, player_radius: float) -> bool:
	return position.y - size * 0.5 > player_position.y + player_radius


func near_miss_done() -> bool:
	return _near_miss_done


func mark_near_miss() -> void:
	_near_miss_done = true


func _process(delta: float) -> void:
	if _homing_rate > 0.0 and _drift_used < _max_drift:
		_apply_homing(delta)
	position.y += speed * delta
	if _appear < 1.0:
		_appear = minf(_appear + delta / maxf(_fade_in_time, 0.001), 1.0)
		queue_redraw()
	if position.y - size * 0.5 > get_viewport_rect().size.y + cull_margin:
		escaped.emit(self)


func _draw() -> void:
	var half: float = size * 0.5
	draw_rect(Rect2(Vector2(-half, -half), Vector2(size, size)), Color(_color, _appear))


func _apply_homing(delta: float) -> void:
	var remaining: float = _max_drift - _drift_used
	var step: float = clampf(_player_x - position.x, -_homing_rate * delta, _homing_rate * delta)
	step = clampf(step, -remaining, remaining)
	position.x += step
	_drift_used += absf(step)
	position.x = clampf(position.x, size * 0.5, get_viewport_rect().size.x - size * 0.5)


func _on_area_entered(area: Area2D) -> void:
	if _crashing:
		return
	var other := area as Square
	if other == null or other == self:
		return
	crashed.emit(self, other)


func _sync_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		return
	rect.size = Vector2(size, size)
