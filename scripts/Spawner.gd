extends Node2D

## Spawns squares from a pool, spread across vertical lanes.

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


func _spawn() -> void:
	var square: Square = _acquire()
	if square == null:
		return
	var square_size: float = randf_range(minf(min_size, max_size), maxf(min_size, max_size))
	var lane_width: float = get_viewport_rect().size.x / float(lane_count)
	var lane: int = randi_range(0, lane_count - 1)
	square.position = Vector2(lane_width * (float(lane) + 0.5), -square_size * 0.5 - spawn_margin)
	square.activate(square_size, randf_range(minf(min_speed, max_speed), maxf(min_speed, max_speed)), Square.Type.NORMAL, Palette.SQUARE_NORMAL)


func _acquire() -> Square:
	if not _pool.is_empty():
		return _pool.pop_back()
	var square: Square = SQUARE_SCENE.instantiate() as Square
	if square == null:
		return null
	square.escaped.connect(_recycle)
	add_child(square)
	return square


func _recycle(square: Square) -> void:
	square.deactivate()
	_pool.push_back(square)


func _next_interval() -> float:
	var jitter: float = spawn_interval * interval_variation
	return maxf(spawn_interval + randf_range(-jitter, jitter), 0.05)
