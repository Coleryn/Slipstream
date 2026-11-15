extends Node

## Audio hooks. Uses a real file if one exists, otherwise a generated blip.
## Does nothing at all when no stream is available.
## Background music: drop a loop at assets/audio/bgm.ogg to replace the
## generated track (see MusicBuilder). The player survives scene changes.

const SAMPLE_RATE: int = 22050
const VOICE_COUNT: int = 6

const PATHS: Dictionary = {
	"crash": "res://assets/audio/crash.wav",
	"death": "res://assets/audio/death.wav",
	"click": "res://assets/audio/click.wav",
	"near_miss": "res://assets/audio/near_miss.wav",
	"pulse": "res://assets/audio/pulse.wav",
}

const TONES: Dictionary = {
	"crash": {"frequency": 220.0, "duration": 0.12, "volume": 0.35},
	"death": {"frequency": 70.0, "duration": 0.35, "volume": 0.45},
	"click": {"frequency": 880.0, "duration": 0.05, "volume": 0.25},
	"near_miss": {"frequency": 1320.0, "duration": 0.05, "volume": 0.12},
	"pulse": {"frequency": 520.0, "duration": 0.18, "volume": 0.3},
}

const SETTINGS_PATH: String = "user://settings.cfg"
const MUSIC_PATH: String = "res://assets/audio/bgm.ogg"
const MUSIC_DUCK_DB: float = -9.0
const MUSIC_DUCK_TIME: float = 0.2

var placeholder_enabled: bool = true
var procedural_music: bool = true
var music_volume_db: float = -14.0
var sound_enabled: bool = true
var music_enabled: bool = true

var _voices: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next_voice: int = 0
var _music: AudioStreamPlayer
var _music_task: int = -1
var _music_tween: Tween
var _music_ducked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	for i in VOICE_COUNT:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	_music = AudioStreamPlayer.new()
	_music.volume_db = music_volume_db
	add_child(_music)
	_load_music()


func set_sound_enabled(value: bool) -> void:
	sound_enabled = value
	save_settings()


func set_music_enabled(value: bool) -> void:
	music_enabled = value
	save_settings()
	_refresh_music()


## Lowers the music under pause and game over, and restores it afterwards.
func set_music_ducked(ducked: bool) -> void:
	if _music == null or ducked == _music_ducked:
		return
	_music_ducked = ducked
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	var target: float = music_volume_db + (MUSIC_DUCK_DB if ducked else 0.0)
	_music_tween.tween_property(_music, "volume_db", target, MUSIC_DUCK_TIME)


func toggle_sound() -> void:
	set_sound_enabled(not sound_enabled)


func toggle_music() -> void:
	set_music_enabled(not music_enabled)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	sound_enabled = bool(config.get_value("audio", "sound", true))
	music_enabled = bool(config.get_value("audio", "music", true))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "sound", sound_enabled)
	config.set_value("audio", "music", music_enabled)
	config.save(SETTINGS_PATH)


func _exit_tree() -> void:
	if _music_task != -1:
		WorkerThreadPool.wait_for_task_completion(_music_task)
		_music_task = -1
	if _music != null:
		_music.stop()
		_music.stream = null
	for voice in _voices:
		voice.stop()
		voice.stream = null
	_streams.clear()
	_voices.clear()


func play_crash(combo_level: int) -> void:
	var pitch: float = clampf(1.0 + 0.06 * float(maxi(combo_level, 1) - 1), 1.0, 1.6)
	_play("crash", pitch)


func play_death() -> void:
	_play("death", 1.0)


func play_click() -> void:
	_play("click", 1.0)


func play_near_miss() -> void:
	_play("near_miss", 1.0)


func play_pulse() -> void:
	_play("pulse", 1.0)


func _play(kind: String, pitch: float) -> void:
	if not sound_enabled:
		return
	if AudioServer.get_driver_name() == "Dummy":
		return
	var stream: AudioStream = _stream_for(kind)
	if stream == null:
		return
	var voice: AudioStreamPlayer = _voice()
	voice.stream = stream
	voice.pitch_scale = pitch
	voice.play()


func _voice() -> AudioStreamPlayer:
	for i in _voices.size():
		var index: int = (_next_voice + i) % _voices.size()
		if not _voices[index].playing:
			_next_voice = (index + 1) % _voices.size()
			return _voices[index]
	_next_voice = (_next_voice + 1) % _voices.size()
	return _voices[_next_voice]


func _stream_for(kind: String) -> AudioStream:
	if _streams.has(kind):
		return _streams[kind]
	var stream: AudioStream = null
	var path: String = PATHS.get(kind, "")
	if path != "" and ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	elif placeholder_enabled and TONES.has(kind):
		var tone: Dictionary = TONES[kind]
		stream = _build_tone(tone["frequency"], tone["duration"], tone["volume"])
	_streams[kind] = stream
	return stream


func _build_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var count: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var envelope: float = 1.0 - float(i) / float(count)
		var sample: float = sin(TAU * frequency * t) * envelope * envelope * volume
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _load_music() -> void:
	if AudioServer.get_driver_name() == "Dummy":
		return
	if ResourceLoader.exists(MUSIC_PATH):
		_on_music_ready(load(MUSIC_PATH) as AudioStream)
	elif procedural_music:
		_music_task = WorkerThreadPool.add_task(_build_music_task)


func _build_music_task() -> void:
	var stream: AudioStream = MusicBuilder.build()
	_on_music_ready.call_deferred(stream)


func _on_music_ready(stream: AudioStream) -> void:
	if _music_task != -1:
		WorkerThreadPool.wait_for_task_completion(_music_task)
		_music_task = -1
	if stream == null or _music == null:
		return
	if "loop" in stream:
		stream.set("loop", true)
	_music.stream = stream
	_refresh_music()


func _refresh_music() -> void:
	if _music == null or _music.stream == null:
		return
	if music_enabled:
		if not _music.playing:
			_music.play()
	else:
		_music.stop()
