class_name Spawner
extends Node2D

## Spawns squares from a pool, spread across vertical lanes.

signal squares_crashed(first: Square, second: Square)

const SQUARE_SCENE: PackedScene = preload("res://scenes/Square.tscn")

@export_group("Lanes")
@export_range(1, 12, 1) var lane_count: int = 5

@export_group("Squares")
@export_range(8.0, 120.0, 1.0) var min_size: float = 28.0
@export_range(8.0, 160.0, 1.0) var max_size: float = 52.0
@export_range(20.0, 600.0, 5.0) var min_speed: float = 110.0
@export_range(20.0, 900.0, 5.0) var max_speed: float = 240.0
@export var spawn_margin: float = 8.0

@export_group("Timing")
@export_range(0.1, 3.0, 0.05) var spawn_interval: float = 0.55
@export_range(0.0, 1.0, 0.01) var interval_variation: float = 0.2

@export_group("Crash setup")
@export_range(0.0, 1.0, 0.01) var crash_chance: float = 0.25
@export_range(20.0, 400.0, 5.0) var crash_speed_delta: float = 130.0
@export_range(40.0, 400.0, 5.0) var crash_gap: float = 150.0

var _pool: Array[Square] = []
var _timer: float = 0.0


func _ready() -> void:
	_timer = _next_interval()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer += _next_interval()
	_spawn()


func freeze_all() -> void:
	set_process(false)
	for node in get_children():
		var square := node as Square
		if square != null and square.visible:
			square.set_process(false)


func reset() -> void:
	for node in get_children():
		var square := node as Square
		if square != null and square.visible:
			square.deactivate()
			_pool.push_back(square)
	_timer = _next_interval()
	set_process(true)


func _spawn() -> void:
	var lane_width: float = get_viewport_rect().size.x / float(lane_count)
	var lane: int = randi_range(0, lane_count - 1)
	var x: float = lane_width * (float(lane) + 0.5)
	if randf() < crash_chance:
		_spawn_crash_pair(x)
	else:
		_spawn_single(x)


func _spawn_single(x: float) -> void:
	var square: Square = _acquire()
	if square == null:
		return
	var square_size: float = randf_range(minf(min_size, max_size), maxf(min_size, max_size))
	var square_speed: float = randf_range(minf(min_speed, max_speed), maxf(min_speed, max_speed))
	_place(square, x, -square_size * 0.5 - spawn_margin, square_size, square_speed)


func _spawn_crash_pair(x: float) -> void:
	var slow: Square = _acquire()
	if slow == null:
		return
	var fast: Square = _acquire()
	if fast == null:
		var fallback_size: float = randf_range(minf(min_size, max_size), maxf(min_size, max_size))
		_place(slow, x, -fallback_size * 0.5 - spawn_margin, fallback_size, randf_range(minf(min_speed, max_speed), maxf(min_speed, max_speed)))
		return
	var slow_size: float = randf_range(minf(min_size, max_size), maxf(min_size, max_size))
	var fast_size: float = randf_range(minf(min_size, max_size), maxf(min_size, max_size))
	var slow_speed: float = randf_range(minf(min_speed, max_speed), maxf(min_speed, max_speed) * 0.6)
	var slow_y: float = -slow_size * 0.5 - spawn_margin
	_place(slow, x, slow_y, slow_size, slow_speed)
	_place(fast, x, slow_y - crash_gap - fast_size * 0.5, fast_size, slow_speed + crash_speed_delta)


func _place(square: Square, x: float, y: float, square_size: float, square_speed: float) -> void:
	square.position = Vector2(x, y)
	square.activate(square_size, square_speed, Square.Type.NORMAL, Palette.SQUARE_NORMAL)


func _acquire() -> Square:
	if not _pool.is_empty():
		return _pool.pop_back()
	var square: Square = SQUARE_SCENE.instantiate() as Square
	if square == null:
		return null
	square.escaped.connect(_recycle)
	square.crashed.connect(_on_square_crashed)
	add_child(square)
	return square


func _on_square_crashed(first: Square, second: Square) -> void:
	if first == second:
		return
	if first.is_crashing() or second.is_crashing():
		return
	if not first.visible or not second.visible:
		return
	first.begin_crash()
	second.begin_crash()
	squares_crashed.emit(first, second)
	_recycle(first)
	_recycle(second)


func _recycle(square: Square) -> void:
	if not square.visible:
		return
	square.deactivate()
	_pool.push_back(square)


func _next_interval() -> float:
	var jitter: float = spawn_interval * interval_variation
	return maxf(spawn_interval + randf_range(-jitter, jitter), 0.05)
