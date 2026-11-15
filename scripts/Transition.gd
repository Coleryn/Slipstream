extends CanvasLayer

## Full-screen fade used for every scene change.

const FADE_COLOR: Color = Palette.BACKGROUND

var _veil: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_veil = ColorRect.new()
	_veil.color = FADE_COLOR
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_veil)
	fade_in()


func fade_in(duration: float = 0.2) -> void:
	_veil.color = Color(FADE_COLOR, 1.0)
	_run(0.0, duration)


func fade_out(duration: float = 0.15) -> void:
	_run(1.0, duration)


func change_scene(path: String, duration: float = 0.15) -> void:
	fade_out(duration)
	await get_tree().create_timer(duration, false, false, false).timeout
	get_tree().change_scene_to_file(path)
	get_tree().paused = false
	await get_tree().process_frame
	fade_in(duration)


func _run(alpha: float, duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_veil, "color", Color(FADE_COLOR, alpha), duration)
