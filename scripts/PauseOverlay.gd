class_name PauseOverlay
extends CanvasLayer

## Full pause screen. Always processes so its buttons work while paused.

signal resumed
signal menu_requested

@onready var _resume_button: Button = $Root/ResumeButton
@onready var _menu_button: Button = $Root/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume)
	_menu_button.pressed.connect(_on_menu)
	visible = false


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func _on_resume() -> void:
	AudioManager.play_click()
	resumed.emit()


func _on_menu() -> void:
	AudioManager.play_click()
	menu_requested.emit()
