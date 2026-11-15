extends Node

## Headless check for MusicBuilder: build time, loop length and loop-seam smoothness.
## Run: godot --headless --path "<project>" res://tests/check_music.tscn

func _ready() -> void:
	var started: int = Time.get_ticks_msec()
	var stream: AudioStreamWAV = MusicBuilder.build()
	var elapsed: int = Time.get_ticks_msec() - started
	var samples: int = stream.data.size() / 2
	var seconds: float = float(samples) / float(stream.mix_rate)
	var first: int = stream.data.decode_s16(0)
	var last: int = stream.data.decode_s16((samples - 1) * 2)
	var peak: int = 0
	var worst_step: int = 0
	var previous: int = last
	for i in samples:
		var value: int = stream.data.decode_s16(i * 2)
		peak = maxi(peak, absi(value))
		worst_step = maxi(worst_step, absi(value - previous))
		previous = value
	print("built in %d ms, %.2f s loop, %d Hz, loop_end=%d" % [elapsed, seconds, stream.mix_rate, stream.loop_end])
	print("peak=%d first=%d last=%d seam_step=%d worst_step=%d" % [peak, first, last, absi(first - last), worst_step])
	if OS.get_environment("DUMP_WAV") != "":
		stream.save_to_wav(OS.get_environment("DUMP_WAV"))
	AudioManager.call("_on_music_ready", stream)
	var music: AudioStreamPlayer = AudioManager.get("_music") as AudioStreamPlayer
	var playing: bool = music != null and music.playing
	AudioManager.set_music_enabled(false)
	var stopped: bool = not music.playing
	AudioManager.set_music_enabled(true)
	var resumed: bool = music.playing
	AudioManager.set_music_ducked(true)
	AudioManager.set_music_ducked(false)
	print("player playing=%s, stops when disabled=%s, resumes=%s" % [playing, stopped, resumed])
	var ok: bool = playing and stopped and resumed and stream.loop_end == samples and peak > 1000 and absi(first - last) <= worst_step
	print("OK" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
