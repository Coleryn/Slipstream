class_name UiMetrics
extends RefCounted

## Shared layout helpers: one 8 px grid and phone safe-area insets.

const GRID: float = 8.0
const MARGIN: float = 24.0


static func snap(value: float) -> float:
	return roundf(value / GRID) * GRID


static func safe_insets(view_size: Vector2) -> Vector2:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return Vector2.ZERO
	var screen: Vector2i = DisplayServer.screen_get_size()
	if screen.x <= 0 or screen.y <= 0:
		return Vector2.ZERO
	var top_px: int = maxi(safe.position.y, 0)
	var bottom_px: int = maxi(screen.y - (safe.position.y + safe.size.y), 0)
	if top_px == 0 and bottom_px == 0:
		return Vector2.ZERO
	var scale_factor: float = view_size.y / float(screen.y)
	return Vector2(snap(float(top_px) * scale_factor), snap(float(bottom_px) * scale_factor))
