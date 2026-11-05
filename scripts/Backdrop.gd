class_name Backdrop
extends Node2D

## Very large, very faint squares drifting behind the field. Purely decorative.

@export var enabled: bool = true:
	set(value):
		enabled = value
		set_process(value)
		queue_redraw()
@export_range(0, 12, 1) var square_count: int = 7
@export_range(40.0, 400.0, 10.0) var min_size: float = 150.0
@export_range(40.0, 600.0, 10.0) var max_size: float = 320.0
@export_range(0.0, 40.0, 1.0) var min_speed: float = 5.0
@export_range(0.0, 60.0, 1.0) var max_speed: float = 18.0
@export_range(0.0, 0.06, 0.005) var light_variation: float = 0.03
@export_range(0.0, 0.06, 0.005) var dark_variation: float = 0.03

var _positions: Array[Vector2] = []
var _sizes: Array[float] = []
var _speeds: Array[float] = []
var _colors: Array[Color] = []


func _ready() -> void:
	_build()


func _build() -> void:
	_positions.clear()
	_sizes.clear()
	_speeds.clear()
	_colors.clear()
	var field: Vector2 = get_viewport_rect().size
	for i in square_count:
		var side: float = randf_range(minf(min_size, max_size), maxf(min_size, max_size))
		_positions.append(Vector2(randf_range(-side * 0.3, field.x + side * 0.3), randf_range(-field.y, field.y)))
		_sizes.append(side)
		_speeds.append(randf_range(minf(min_speed, max_speed), maxf(min_speed, max_speed)))
		if i % 2 == 0:
			_colors.append(Palette.lift(Palette.BACKGROUND, light_variation))
		else:
			_colors.append(Palette.shade(Palette.BACKGROUND, 1.0 - dark_variation))
	set_process(enabled)
	queue_redraw()


func _process(delta: float) -> void:
	var field: Vector2 = get_viewport_rect().size
	for i in _positions.size():
		var side: float = _sizes[i]
		_positions[i].y += _speeds[i] * delta
		if _positions[i].y - side * 0.5 > field.y:
			_positions[i].y = -side * 0.5 - randf_range(0.0, 200.0)
			_positions[i].x = randf_range(-side * 0.3, field.x + side * 0.3)
	queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	for i in _positions.size():
		var half: float = _sizes[i] * 0.5
		draw_rect(Rect2(_positions[i] - Vector2(half, half), Vector2(_sizes[i], _sizes[i])), _colors[i])
