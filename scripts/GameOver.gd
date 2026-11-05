class_name GameOver
extends CanvasLayer

## Nearly empty game over screen: score, best, Restart and Menu.

signal restart_pressed
signal menu_pressed

@export var feedback: FeedbackConfig

@onready var _root: Control = $Root
@onready var _score_label: Label = $Root/ScoreLabel
@onready var _best_label: Label = $Root/BestLabel
@onready var _new_best_label: Label = $Root/NewBestLabel
@onready var _restart_button: Button = $Root/RestartButton
@onready var _menu_button: Button = $Root/MenuButton

var _tween: Tween
var _pop_tween: Tween


func _ready() -> void:
	if feedback == null:
		feedback = FeedbackConfig.new()
	_sync_pivots()
	_restart_button.resized.connect(_sync_pivots)
	_menu_button.resized.connect(_sync_pivots)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_restart_button.button_down.connect(_pop.bind(_restart_button, feedback.button_press_scale))
	_restart_button.button_up.connect(_pop.bind(_restart_button, 1.0))
	_menu_button.button_down.connect(_pop.bind(_menu_button, feedback.button_press_scale))
	_menu_button.button_up.connect(_pop.bind(_menu_button, 1.0))
	hide_result()


func show_result(score: int, best: int, new_best: bool, fade_time: float) -> void:
	_score_label.text = str(score)
	_best_label.text = "best %d" % best
	_new_best_label.visible = new_best
	_root.modulate = Color(1, 1, 1, 0)
	visible = true
	if _restart_button.is_inside_tree():
		_restart_button.grab_focus()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_root, "modulate", Color(1, 1, 1, 1), fade_time)


func hide_result() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_root.modulate = Color(1, 1, 1, 1)
	_restart_button.scale = Vector2.ONE
	_menu_button.scale = Vector2.ONE
	_new_best_label.visible = false
	visible = false


func _on_restart_pressed() -> void:
	AudioManager.play_click()
	restart_pressed.emit()


func _on_menu_pressed() -> void:
	AudioManager.play_click()
	menu_pressed.emit()


func _pop(button: Button, target_scale: float) -> void:
	if not visible:
		return
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_pop_tween = create_tween()
	_pop_tween.tween_property(button, "scale", Vector2.ONE * target_scale, feedback.button_pop_time)


func _sync_pivots() -> void:
	_restart_button.pivot_offset = _restart_button.size * 0.5
	_menu_button.pivot_offset = _menu_button.size * 0.5
