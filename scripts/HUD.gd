class_name HUD
extends CanvasLayer

## Minimal in-run readout: score, combo multiplier, combo timer, best, pause, pulse.

signal pulse_pressed
signal pause_pressed

const BAR_WIDTH: float = 96.0
const BAR_HEIGHT: float = 4.0
const BAR_Y: float = 108.0

@export var feedback: FeedbackConfig

@onready var _root: Control = $Root
@onready var _score_label: Label = $Root/ScoreLabel
@onready var _multiplier_label: Label = $Root/MultiplierLabel
@onready var _combo_bar: ColorRect = $Root/ComboBar
@onready var _best_label: Label = $Root/BestLabel
@onready var _pause_button: Button = $Root/PauseButton
@onready var _pulse_button: Button = $Root/PulseButton
@onready var _pulse_fill: ColorRect = $Root/PulseButton/CooldownFill

var _shown_score: int = -1
var _shown_best: int = -1
var _shown_combo: int = -1
var _shown_pulse: float = -1.0
var _bar_y: float = BAR_Y
var _pop_tween: Tween
var _intro_tween: Tween
var _pulse_tween: Tween
var _pause_tween: Tween


func _ready() -> void:
	if feedback == null:
		feedback = FeedbackConfig.new()
	_combo_bar.color = Color(Palette.TEXT, 0.8)
	_best_label.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_pulse_fill.color = Color(Palette.BACKGROUND, 0.55)
	_apply_safe_area()
	_pause_button.pressed.connect(_on_pause_pressed)
	_pulse_button.pressed.connect(_on_pulse_pressed)
	_pause_button.button_down.connect(_pause_pop.bind(0.94))
	_pause_button.button_up.connect(_pause_pop.bind(1.0))
	_pulse_button.button_down.connect(_pulse_pop.bind(0.94))
	_pulse_button.button_up.connect(_pulse_pop.bind(1.0))
	_pulse_button.resized.connect(_sync_pulse_pivot)
	_sync_pause_pivot()
	_pause_button.resized.connect(_sync_pause_pivot)
	_sync_pulse_pivot()
	set_pulse_state(0.0)
	play_intro()


func play_intro() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_root.modulate = Color(1, 1, 1, 0)
	_intro_tween = create_tween()
	_intro_tween.tween_property(_root, "modulate", Color(1, 1, 1, 1), feedback.hud_fade_in_time)


func set_pulse_state(ratio: float) -> void:
	var clamped: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(clamped, _shown_pulse):
		return
	_shown_pulse = clamped
	var height: float = _pulse_button.size.y * clamped
	_pulse_fill.visible = clamped > 0.0
	_pulse_fill.position = Vector2(0.0, _pulse_button.size.y - height)
	_pulse_fill.size = Vector2(_pulse_button.size.x, height)
	_pulse_button.modulate = Color(1, 1, 1, 1.0 - 0.45 * clamped)


func show_pulse_button(shown: bool) -> void:
	_pulse_button.visible = shown


func show_pause_button(shown: bool) -> void:
	_pause_button.visible = shown


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	var score: int = int(GameState.score)
	if score != _shown_score:
		_shown_score = score
		_score_label.text = str(score)

	if GameState.high_score != _shown_best:
		_shown_best = GameState.high_score
		_best_label.text = "best %d" % _shown_best

	var combo: int = GameState.combo
	if combo != _shown_combo:
		var increased: bool = combo > _shown_combo
		_shown_combo = combo
		var show_combo: bool = combo > 1
		_multiplier_label.visible = show_combo
		_combo_bar.visible = show_combo
		if show_combo:
			_multiplier_label.text = "x%d" % combo
			_multiplier_label.pivot_offset = _multiplier_label.size * 0.5
			if increased:
				_pop()

	_update_bar()


func _apply_safe_area() -> void:
	var insets: Vector2 = UiMetrics.safe_insets(get_viewport().get_visible_rect().size)
	if insets == Vector2.ZERO:
		return
	_bar_y = BAR_Y + insets.x
	_score_label.offset_top += insets.x
	_score_label.offset_bottom += insets.x
	_multiplier_label.offset_top += insets.x
	_multiplier_label.offset_bottom += insets.x
	_best_label.offset_top += insets.x
	_best_label.offset_bottom += insets.x
	_pause_button.offset_top += insets.x
	_pause_button.offset_bottom += insets.x
	_pulse_button.offset_top -= insets.y
	_pulse_button.offset_bottom -= insets.y


func _update_bar() -> void:
	if not _combo_bar.visible:
		return
	var ratio: float = clampf(GameState.combo_time_left / maxf(GameState.combo_window, 0.01), 0.0, 1.0)
	var width: float = BAR_WIDTH * ratio
	var field_width: float = get_viewport().get_visible_rect().size.x
	_combo_bar.size = Vector2(width, BAR_HEIGHT)
	_combo_bar.position = Vector2((field_width - width) * 0.5, _bar_y)


func _on_pause_pressed() -> void:
	AudioManager.play_click()
	pause_pressed.emit()


func _on_pulse_pressed() -> void:
	AudioManager.play_click()
	pulse_pressed.emit()


func _pop() -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_multiplier_label.scale = Vector2.ONE * feedback.combo_pop_scale
	_pop_tween = create_tween()
	_pop_tween.tween_property(_multiplier_label, "scale", Vector2.ONE, feedback.combo_pop_time)


func _pulse_pop(target_scale: float) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(_pulse_button, "scale", Vector2.ONE * target_scale, feedback.button_pop_time)


func _pause_pop(target_scale: float) -> void:
	if _pause_tween != null and _pause_tween.is_valid():
		_pause_tween.kill()
	_pause_tween = create_tween()
	_pause_tween.tween_property(_pause_button, "scale", Vector2.ONE * target_scale, feedback.button_pop_time)


func _sync_pulse_pivot() -> void:
	_pulse_button.pivot_offset = _pulse_button.size * 0.5


func _sync_pause_pivot() -> void:
	_pause_button.pivot_offset = _pause_button.size * 0.5
