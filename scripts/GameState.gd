extends Node

## Global run state plus the persisted high score.

const SETTINGS_PATH: String = "user://slipstream.cfg"

var score: float = 0.0
var combo: int = 1
var combo_time_left: float = 0.0
var combo_window: float = 2.0
var speed: float = 0.0
var high_score: int = 0
var new_best: bool = false


func _ready() -> void:
	load_high_score()


func add_score(amount: float) -> void:
	score += amount


func register_crash(window: float, cap: int) -> int:
	combo = 1 if combo_time_left <= 0.0 else mini(combo + 1, cap)
	combo_window = maxf(window, 0.01)
	combo_time_left = combo_window
	return combo


func tick_combo(delta: float) -> void:
	if combo_time_left <= 0.0:
		return
	combo_time_left = maxf(combo_time_left - delta, 0.0)
	if is_zero_approx(combo_time_left):
		combo = 1


func reset_combo() -> void:
	combo = 1
	combo_time_left = 0.0


func commit_high_score() -> bool:
	new_best = int(score) > high_score
	if new_best:
		high_score = int(score)
		save_high_score()
	return new_best


func reset() -> void:
	score = 0.0
	speed = 0.0
	new_best = false
	reset_combo()


func load_high_score() -> void:
	high_score = 0
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var stored: Variant = config.get_value("score", "high_score", 0)
	if typeof(stored) == TYPE_INT or typeof(stored) == TYPE_FLOAT:
		high_score = maxi(int(stored), 0)


func save_high_score() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("score", "high_score", high_score)
	config.save(SETTINGS_PATH)
