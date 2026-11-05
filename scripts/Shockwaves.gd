class_name Shockwaves
extends Node2D

## Thin hollow square frames on crash. One instance, reused by every crash.

@export var feedback: FeedbackConfig

var _positions: Array[Vector2] = []
var _colors: Array[Color] = []
var _sizes: Array[float] = []
var _ages: Array[float] = []
var _lives: Array[float] = []


func _ready() -> void:
	if feedback == null:
		feedback = FeedbackConfig.new()


func emit(origin: Vector2, color: Color, size: float) -> void:
	_positions.append(origin - global_position)
	_colors.append(color)
	_sizes.append(maxf(size, 4.0))
	_ages.append(0.0)
	_lives.append(maxf(feedback.shockwave_time, 0.01))
	set_process(true)
	queue_redraw()


func clear() -> void:
	_positions.clear()
	_colors.clear()
	_sizes.clear()
	_ages.clear()
	_lives.clear()
	set_process(false)
	queue_redraw()


func wave_count() -> int:
	return _ages.size()


func _process(delta: float) -> void:
	if _ages.is_empty():
		set_process(false)
		queue_redraw()
		return
	var i: int = _ages.size() - 1
	while i >= 0:
		_ages[i] += delta
		if _ages[i] >= _lives[i]:
			_remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	for i in _positions.size():
		var t: float = clampf(_ages[i] / _lives[i], 0.0, 1.0)
		var side: float = _sizes[i] * lerpf(1.0, feedback.shockwave_expand, ease(t, 0.45))
		var alpha: float = feedback.shockwave_alpha * (1.0 - t)
		var half: float = side * 0.5
		draw_rect(Rect2(_positions[i] - Vector2(half, half), Vector2(side, side)), Color(_colors[i], alpha), false, feedback.shockwave_width)


func _remove_at(index: int) -> void:
	_positions.remove_at(index)
	_colors.remove_at(index)
	_sizes.remove_at(index)
	_ages.remove_at(index)
	_lives.remove_at(index)
