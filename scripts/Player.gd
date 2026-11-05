class_name Player
extends Area2D

## The white circle. Fixed Y near the bottom, dragged left/right on X only.

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

@export_group("Trail")
@export_range(0.05, 1.0, 0.01) var trail_lifetime: float = 0.22
@export_range(0.01, 0.2, 0.01) var trail_interval: float = 0.035
@export_range(0.0, 1.0, 0.01) var trail_alpha: float = 0.25
@export_range(0.0, 1.0, 0.05) var trail_shrink: float = 0.4

var _target_x: float = 0.0
var _dragging: bool = false
var _touch_index: int = -1
var _trail_points: Array[Vector2] = []
var _trail_ages: Array[float] = []
var _trail_timer: float = 0.0


func _ready() -> void:
	var field: Vector2 = get_viewport_rect().size
	position = Vector2(field.x * 0.5, field.y - bottom_margin)
	_target_x = position.x
	_sync_hitbox()


func _process(delta: float) -> void:
	if _dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging = false
	position.x = lerpf(position.x, _target_x, 1.0 - exp(-smoothing * delta))
	_update_trail(delta)
	queue_redraw()


func _draw() -> void:
	for i in _trail_points.size():
		var t: float = clampf(_trail_ages[i] / trail_lifetime, 0.0, 1.0)
		var fade: float = (1.0 - t) * trail_alpha
		var trail_radius: float = radius * (1.0 - trail_shrink * t)
		draw_circle(to_local(_trail_points[i]), trail_radius, Color(Palette.PLAYER, fade), true, -1.0, true)
	draw_circle(Vector2.ZERO, radius, Palette.PLAYER, true, -1.0, true)


func _unhandled_input(event: InputEvent) -> void:
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


func _drag(relative_x: float) -> void:
	_target_x = clampf(_target_x + relative_x * drag_sensitivity, radius, _max_x())


func _max_x() -> float:
	return get_viewport_rect().size.x - radius


func _update_trail(delta: float) -> void:
	for i in _trail_ages.size():
		_trail_ages[i] += delta
	while not _trail_ages.is_empty() and _trail_ages[-1] >= trail_lifetime:
		_trail_ages.pop_back()
		_trail_points.pop_back()
	_trail_timer -= delta
	if _trail_timer > 0.0:
		return
	_trail_timer = trail_interval
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
