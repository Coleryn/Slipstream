class_name HUD
extends CanvasLayer

## Minimal in-run readout: score, combo multiplier, combo timer, best.

const BAR_WIDTH: float = 96.0
const BAR_HEIGHT: float = 4.0
const BAR_Y: float = 108.0

@onready var _score_label: Label = $Root/ScoreLabel
@onready var _multiplier_label: Label = $Root/MultiplierLabel
@onready var _combo_bar: ColorRect = $Root/ComboBar
@onready var _best_label: Label = $Root/BestLabel

var _shown_score: int = -1
var _shown_best: int = -1
var _shown_combo: int = -1
var _pop_tween: Tween


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


func _update_bar() -> void:
	if not _combo_bar.visible:
		return
	var ratio: float = clampf(GameState.combo_time_left / maxf(GameState.combo_window, 0.01), 0.0, 1.0)
	var width: float = BAR_WIDTH * ratio
	var field_width: float = get_viewport().get_visible_rect().size.x
	_combo_bar.size = Vector2(width, BAR_HEIGHT)
	_combo_bar.position = Vector2((field_width - width) * 0.5, BAR_Y)


func _pop() -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	_multiplier_label.scale = Vector2.ONE * 1.3
	_pop_tween = create_tween()
	_pop_tween.tween_property(_multiplier_label, "scale", Vector2.ONE, 0.12)
