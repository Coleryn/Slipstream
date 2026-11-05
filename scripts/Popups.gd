class_name Popups
extends Node2D

## Floating score text. Reused by every crash, no nodes are created per event.

const FONT: Font = preload("res://assets/fonts/Nunito-Bold.ttf")

var _texts: Array[String] = []
var _positions: Array[Vector2] = []
var _ages: Array[float] = []
var _lives: Array[float] = []
var _rises: Array[float] = []
var _sizes: Array[int] = []


func show_text(origin: Vector2, text: String, rise: float, lifetime: float, font_size: int) -> void:
	_texts.append(text)
	_positions.append(origin - global_position)
	_ages.append(0.0)
	_lives.append(maxf(lifetime, 0.05))
	_rises.append(rise)
	_sizes.append(font_size)
	set_process(true)
	queue_redraw()


func clear() -> void:
	_texts.clear()
	_positions.clear()
	_ages.clear()
	_lives.clear()
	_rises.clear()
	_sizes.clear()
	set_process(false)
	queue_redraw()


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
	for i in _texts.size():
		var t: float = clampf(_ages[i] / _lives[i], 0.0, 1.0)
		var font_size: int = _sizes[i]
		var width: float = FONT.get_string_size(_texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var pos: Vector2 = _positions[i] + Vector2(-width * 0.5, -_rises[i] * t)
		draw_string(FONT, pos, _texts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(Palette.TEXT, 1.0 - t * t))


func _remove_at(index: int) -> void:
	_texts.remove_at(index)
	_positions.remove_at(index)
	_ages.remove_at(index)
	_lives.remove_at(index)
	_rises.remove_at(index)
	_sizes.remove_at(index)
