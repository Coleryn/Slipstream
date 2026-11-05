class_name Burst
extends Node2D

## Small square particles. One instance, reused by every burst.

@export var feedback: FeedbackConfig

var _positions: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _sizes: Array[float] = []
var _colors: Array[Color] = []
var _rotations: Array[float] = []
var _spins: Array[float] = []
var _ages: Array[float] = []
var _lives: Array[float] = []


func _ready() -> void:
	if feedback == null:
		feedback = FeedbackConfig.new()


func emit_burst(origin: Vector2, color: Color, count: int, speed: float, size: float, lifetime: float) -> void:
	for i in maxi(count, 0):
		var direction: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
		_positions.append(origin - global_position)
		_velocities.append(direction * speed * randf_range(0.35, 1.0))
		_sizes.append(size * randf_range(0.6, 1.2))
		_colors.append(color)
		_rotations.append(randf() * TAU)
		_spins.append(randf_range(-1.0, 1.0) * feedback.particle_spin)
		_ages.append(0.0)
		_lives.append(maxf(lifetime, 0.01))
	set_process(true)
	queue_redraw()


func clear() -> void:
	_positions.clear()
	_velocities.clear()
	_sizes.clear()
	_colors.clear()
	_rotations.clear()
	_spins.clear()
	_ages.clear()
	_lives.clear()
	set_process(false)
	queue_redraw()


func particle_count() -> int:
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
		else:
			_velocities[i] = _velocities[i].lerp(Vector2.ZERO, minf(delta * feedback.particle_drag, 1.0))
			_positions[i] += _velocities[i] * delta
			_rotations[i] += _spins[i] * delta
		i -= 1
	queue_redraw()


func _draw() -> void:
	for i in _positions.size():
		var t: float = clampf(_ages[i] / _lives[i], 0.0, 1.0)
		var side: float = _sizes[i] * (1.0 - feedback.particle_shrink * t)
		if side <= 0.0:
			continue
		draw_set_transform(_positions[i], _rotations[i], Vector2.ONE)
		draw_rect(Rect2(Vector2(-side, -side) * 0.5, Vector2(side, side)), Color(_colors[i], 1.0 - t))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _remove_at(index: int) -> void:
	_positions.remove_at(index)
	_velocities.remove_at(index)
	_sizes.remove_at(index)
	_colors.remove_at(index)
	_rotations.remove_at(index)
	_spins.remove_at(index)
	_ages.remove_at(index)
	_lives.remove_at(index)
