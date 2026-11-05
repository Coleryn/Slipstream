class_name Square
extends Area2D

## A falling square. Driven entirely by the Spawner: pooled, reused, never freed.

signal escaped(square: Square)

enum Type { NORMAL, FAST, GOLD }

@export var size: float = 40.0
@export var speed: float = 180.0
@export var type: Type = Type.NORMAL
@export_range(0.0, 0.5, 0.01) var fade_in_time: float = 0.25
@export var cull_margin: float = 48.0

var _color: Color = Palette.SQUARE_NORMAL
var _appear: float = 0.0


func activate(in_size: float, in_speed: float, in_type: Type, in_color: Color) -> void:
	size = in_size
	speed = in_speed
	type = in_type
	_color = in_color
	_appear = 0.0
	show()
	set_deferred("monitorable", true)
	set_process(true)
	_sync_shape()
	queue_redraw()


func deactivate() -> void:
	hide()
	set_process(false)
	set_deferred("monitorable", false)


func _process(delta: float) -> void:
	position.y += speed * delta
	if _appear < 1.0:
		_appear = minf(_appear + delta / maxf(fade_in_time, 0.001), 1.0)
		queue_redraw()
	if position.y - size * 0.5 > get_viewport_rect().size.y + cull_margin:
		escaped.emit(self)


func _draw() -> void:
	var half: float = size * 0.5
	draw_rect(Rect2(Vector2(-half, -half), Vector2(size, size)), Color(_color, _appear))


func _sync_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		return
	rect.size = Vector2(size, size)
