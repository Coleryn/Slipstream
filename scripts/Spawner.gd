class_name Spawner
extends Node2D

## Spawns squares from a pool, spread across vertical lanes.

signal squares_crashed(first: Square, second: Square)

const SQUARE_SCENE: PackedScene = preload("res://scenes/Square.tscn")

@export var difficulty: DifficultyConfig
@export var feedback: FeedbackConfig

@export_group("Lanes")
@export_range(1, 12, 1) var lane_count: int = 5

@export_group("Squares")
@export_range(8.0, 120.0, 1.0) var min_size: float = 28.0
@export_range(8.0, 160.0, 1.0) var max_size: float = 52.0
@export_range(20.0, 600.0, 5.0) var min_speed: float = 110.0
@export_range(20.0, 900.0, 5.0) var max_speed: float = 240.0
@export var spawn_margin: float = 8.0

@export_group("Timing")
@export_range(0.0, 1.0, 0.01) var interval_variation: float = 0.2

@export_group("Crash setup")
@export_range(0.0, 1.0, 0.01) var crash_chance: float = 0.25
@export_range(0.2, 10.0, 0.1) var crash_max_gap: float = 3.0
@export_range(20.0, 400.0, 5.0) var crash_speed_delta: float = 130.0
@export_range(40.0, 400.0, 5.0) var crash_gap: float = 150.0

var _pool: Array[Square] = []
var _timer: float = 0.0
var _interval_now: float = 0.0
var _crash_clock: float = 0.0
var _stats_clock: float = 0.0


func _ready() -> void:
	if difficulty == null:
		difficulty = DifficultyConfig.new()
	if feedback == null:
		feedback = FeedbackConfig.new()
	_interval_now = _next_interval()
	_timer = _interval_now


func _process(delta: float) -> void:
	_crash_clock += delta
	if difficulty.debug_stats:
		_stats_clock += delta
		if _stats_clock >= 1.0:
			_stats_clock -= 1.0
			print("t=%.1fs speed=%.0f interval=%.2f" % [GameState.time, GameState.speed, _interval_now])
	_timer -= delta
	if _timer > 0.0:
		return
	_interval_now = _next_interval()
	_timer += _interval_now
	_spawn()


func active_squares() -> Array[Square]:
	var out: Array[Square] = []
	for node in get_children():
		var square := node as Square
		if square != null and square.visible:
			out.append(square)
	return out


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
	_interval_now = _next_interval()
	_timer = _interval_now
	_crash_clock = 0.0
	_stats_clock = 0.0
	set_process(true)


func _spawn() -> void:
	var lane_width: float = get_viewport_rect().size.x / float(lane_count)
	var lane: int = randi_range(0, lane_count - 1)
	var x: float = lane_width * (float(lane) + 0.5)
	var wants_crash: bool = randf() < crash_chance or _crash_clock >= crash_max_gap
	if wants_crash and _spawn_crash_pair(x):
		_crash_clock = 0.0
		return
	_spawn_single(x)


func _spawn_single(x: float) -> void:
	var square_size: float = _random_size()
	var y: float = -square_size * 0.5 - spawn_margin
	_try_place(x, y, square_size, _random_speed())


func _spawn_crash_pair(x: float) -> bool:
	var scale: float = _difficulty_scale()
	var slow_size: float = _random_size()
	var fast_size: float = _random_size()
	var speed_lo: float = minf(min_speed, max_speed)
	var speed_hi: float = maxf(min_speed, max_speed)
	var slow_speed: float = randf_range(speed_lo, maxf(speed_lo, speed_hi * 0.6)) * scale
	var slow_y: float = -slow_size * 0.5 - spawn_margin
	if not _try_place(x, slow_y, slow_size, slow_speed):
		return false
	var fast_y: float = slow_y - crash_gap - fast_size * 0.5
	_try_place(x, fast_y, fast_size, slow_speed + crash_speed_delta * scale)
	return true


func _try_place(x: float, y: float, square_size: float, square_speed: float) -> bool:
	var safe_x: float = _fair_x(x, y, square_size)
	if is_nan(safe_x):
		return false
	var square: Square = _acquire()
	if square == null:
		return false
	square.position = Vector2(safe_x, y)
	square.activate(square_size, square_speed, Square.Type.NORMAL, Palette.SQUARE_NORMAL, feedback.square_fade_in_time)
	return true


func _fair_x(x: float, y: float, square_size: float) -> float:
	var field_width: float = get_viewport_rect().size.x
	var required: float = difficulty.player_diameter + difficulty.gap_margin
	var blocked: Array[Vector2] = _blocked_intervals(y, square_size)
	var with_candidate: Array[Vector2] = blocked.duplicate()
	with_candidate.append(Vector2(x - square_size * 0.5, x + square_size * 0.5))
	if _largest_gap(with_candidate, field_width) >= required:
		return x
	var best: Vector2 = Vector2.ZERO
	var best_width: float = -1.0
	for region in _free_regions(blocked, field_width):
		var width: float = region.y - region.x
		if width > best_width:
			best_width = width
			best = region
	if best_width < square_size + required:
		return NAN
	return best.x + square_size * 0.5


func _blocked_intervals(y: float, square_size: float) -> Array[Vector2]:
	var pad: float = difficulty.band_padding
	var top: float = y - square_size * 0.5 - pad
	var bottom: float = y + square_size * 0.5 + pad
	var blocked: Array[Vector2] = []
	for node in get_children():
		var square := node as Square
		if square == null or not square.visible:
			continue
		var half: float = square.size * 0.5
		if square.position.y + half < top or square.position.y - half > bottom:
			continue
		blocked.append(Vector2(square.position.x - half, square.position.x + half))
	return blocked


func _free_regions(blocked: Array[Vector2], field_width: float) -> Array[Vector2]:
	var sorted: Array[Vector2] = blocked.duplicate()
	sorted.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var regions: Array[Vector2] = []
	var cursor: float = 0.0
	for interval in sorted:
		if interval.x > cursor:
			regions.append(Vector2(cursor, minf(interval.x, field_width)))
		cursor = maxf(cursor, interval.y)
	if cursor < field_width:
		regions.append(Vector2(cursor, field_width))
	return regions


func _largest_gap(blocked: Array[Vector2], field_width: float) -> float:
	var largest: float = 0.0
	for region in _free_regions(blocked, field_width):
		largest = maxf(largest, region.y - region.x)
	return largest


func _difficulty_scale() -> float:
	var base: float = maxf(difficulty.base_speed, 0.001)
	return maxf(GameState.speed, base) / base


func _random_size() -> float:
	var mult: float = 1.0 + difficulty.size_growth * (_difficulty_scale() - 1.0)
	return randf_range(minf(min_size, max_size), maxf(min_size, max_size)) * mult


func _random_speed() -> float:
	return randf_range(minf(min_speed, max_speed), maxf(min_speed, max_speed)) * _difficulty_scale()


func _next_interval() -> float:
	var t: float = maxf(GameState.time, 0.0)
	var curve: float = difficulty.interval_start / (1.0 + difficulty.interval_shrink * sqrt(t))
	var interval: float = maxf(curve, difficulty.interval_min)
	var jitter: float = interval * interval_variation
	return maxf(interval + randf_range(-jitter, jitter), 0.05)


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
