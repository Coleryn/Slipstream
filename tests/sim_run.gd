extends Node

## Headless balance probe. Plays Main with a ghost player and prints where crashes
## happen and how dense the field gets over time.
## Run: godot --headless --fixed-fps 60 --path "<project>" res://tests/sim_run.tscn

const RUN_SECONDS: float = 90.0
const SAMPLE_EVERY: float = 15.0

var _main: Node
var _spawner: Spawner
var _crash_y: Array[float] = []
var _crash_times: Array[float] = []
var _next_sample: float = 0.0
var _next_pulse: float = 3.0
var _pulse_credit_crashes: int = 0


func _ready() -> void:
	_main = (load("res://scenes/Main.tscn") as PackedScene).instantiate()
	add_child(_main)
	await get_tree().process_frame
	_spawner = _main.get_node("Spawner") as Spawner
	(_main.get_node("Player") as Player).monitoring = false
	_spawner.squares_crashed.connect(_on_crash)


func _on_crash(first: Square, second: Square) -> void:
	if first.has_pulse_credit() or second.has_pulse_credit():
		_pulse_credit_crashes += 1
	_crash_y.append((first.position.y + second.position.y) * 0.5)
	_crash_times.append(GameState.time)


## Plays like a careful human: slides under a square that has another square
## stacked just above it, then pulses so the lower one is shoved into the upper.
func _aimed_pulse() -> void:
	var player: Player = _main.get_node("Player") as Player
	if not player.pulse_ready():
		return
	var squares: Array[Square] = _spawner.active_squares()
	for low in squares:
		if low.is_pickup() or low.position.y < 560.0 or low.position.y > 780.0:
			continue
		for high in squares:
			if high == low or high.is_pickup():
				continue
			var above: float = low.position.y - high.position.y
			if above > 40.0 and above < 260.0 and absf(high.position.x - low.position.x) < 50.0:
				player.position.x = low.position.x
				_main.call("_try_pulse")
				return


func _process(_delta: float) -> void:
	if _spawner == null:
		return
	_aimed_pulse()
	if GameState.time >= _next_sample:
		var live: int = 0
		for square in _spawner.active_squares():
			if square.position.y > 0.0 and square.position.y < 960.0:
				live += 1
		print("t=%5.0fs speed=%4.0f on_screen=%2d crashes=%3d walls n/r/tol=%d/%d/%d" % [GameState.time, GameState.speed, live, _crash_y.size(), _spawner.wall_nudges, _spawner.wall_removals, _spawner.get("wall_tolerated")])
		_next_sample += SAMPLE_EVERY
	if GameState.time >= RUN_SECONDS:
		var low: float = 1.0e9
		var high: float = -1.0e9
		var total: float = 0.0
		for y in _crash_y:
			low = minf(low, y)
			high = maxf(high, y)
			total += y
		var mean: float = total / maxf(float(_crash_y.size()), 1.0)
		var buckets: Array[int] = [0, 0, 0, 0, 0, 0]
		for y in _crash_y:
			buckets[clampi(int(y / 160.0), 0, 5)] += 1
		print("crash y histogram (160px bands, top to bottom): %s" % str(buckets))
		print("pulse-credit crashes: %d" % _pulse_credit_crashes)
		print("CRASHES %d  y mean=%.0f min=%.0f max=%.0f  (screen 960)" % [_crash_y.size(), mean, low, high])
		get_tree().quit(0)
