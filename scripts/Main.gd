extends Node2D

## Root of the game. For now it only paints the empty play field.

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Palette.BACKGROUND)
