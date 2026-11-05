extends Node2D

## First screen. Starts nothing until Play is pressed.

@onready var _play_button: Button = $UI/Root/PlayButton
@onready var _best_label: Label = $UI/Root/BestLabel
@onready var _sound_button: Button = $UI/Root/SoundButton
@onready var _music_button: Button = $UI/Root/MusicButton


func _ready() -> void:
	_best_label.text = "best %d" % GameState.high_score
	_play_button.pressed.connect(_on_play_pressed)
	_sound_button.pressed.connect(_on_sound_pressed)
	_music_button.pressed.connect(_on_music_pressed)
	_refresh_toggles()


func _on_play_pressed() -> void:
	AudioManager.play_click()
	Transition.change_scene("res://scenes/Main.tscn")


func _on_sound_pressed() -> void:
	AudioManager.toggle_sound()
	AudioManager.play_click()
	_refresh_toggles()


func _on_music_pressed() -> void:
	AudioManager.toggle_music()
	AudioManager.play_click()
	_refresh_toggles()


func _refresh_toggles() -> void:
	_sound_button.text = "Sound %s" % _state(AudioManager.sound_enabled)
	_music_button.text = "Music %s" % _state(AudioManager.music_enabled)


func _state(enabled: bool) -> String:
	return "On" if enabled else "Off"
