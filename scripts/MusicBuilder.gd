class_name MusicBuilder
extends RefCounted

## Builds the looping background track as 16-bit PCM. Pure code, no assets.
## Four bars (Am - F - C - G): soft detuned pad, sparse bass, plucked arpeggio.
## Every note wraps around the loop end, so the loop point has no click.

const SAMPLE_RATE: int = 16000
const BPM: float = 92.0
const BEATS_PER_BAR: int = 4
const PAD_TAIL: float = 0.7
const PAD_ATTACK: float = 0.7

## bass and chord notes are MIDI numbers.
const CHORDS: Array = [
	{"bass": 45, "notes": [57, 60, 64]},
	{"bass": 41, "notes": [57, 60, 65]},
	{"bass": 48, "notes": [55, 60, 64]},
	{"bass": 43, "notes": [55, 59, 62]},
]
const ARP_A: PackedInt32Array = [0, 1, 2, 1, 2, 1, 0, 1]
const ARP_B: PackedInt32Array = [0, 2, 1, 2, 0, 2, 1, 2]

const PAD_LEVEL: float = 0.07
const BASS_LEVEL: float = 0.22
const ARP_LEVEL: float = 0.12


## volume is the peak amplitude of the finished loop (0..1).
static func build(volume: float = 0.6) -> AudioStreamWAV:
	var beat: float = 60.0 / BPM
	var bar_samples: int = int(round(beat * float(BEATS_PER_BAR) * float(SAMPLE_RATE)))
	var total: int = bar_samples * CHORDS.size()
	var mix := PackedFloat32Array()
	mix.resize(total)
	for bar in CHORDS.size():
		var chord: Dictionary = CHORDS[bar]
		var start: int = bar * bar_samples
		var notes: Array = chord["notes"]
		for note in notes:
			_add_pad(mix, start, bar_samples, _hz(int(note)))
		_add_bass(mix, start, int(chord["bass"]), beat)
		_add_arp(mix, start, notes, beat, ARP_A if bar % 2 == 0 else ARP_B)
	return _to_stream(mix, volume)


static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, float(midi - 69) / 12.0)


static func _add(mix: PackedFloat32Array, index: int, value: float) -> void:
	var wrapped: int = index % mix.size()
	mix[wrapped] += value


static func _add_pad(mix: PackedFloat32Array, start: int, bar_samples: int, hz: float) -> void:
	var length: int = bar_samples + int(PAD_TAIL * float(SAMPLE_RATE))
	var attack: float = PAD_ATTACK * float(SAMPLE_RATE)
	var release: float = PAD_TAIL * float(SAMPLE_RATE)
	for i in length:
		var t: float = float(i) / float(SAMPLE_RATE)
		var rise: float = minf(float(i) / attack, 1.0)
		var fall: float = minf(float(length - i) / release, 1.0)
		var env: float = rise * rise * (3.0 - 2.0 * rise) * fall * fall * (3.0 - 2.0 * fall)
		var tone: float = sin(TAU * hz * t) + sin(TAU * hz * 1.004 * t)
		_add(mix, start + i, tone * env * PAD_LEVEL)


static func _add_bass(mix: PackedFloat32Array, start: int, midi: int, beat: float) -> void:
	var hz: float = _hz(midi)
	var length: int = int(beat * 1.8 * float(SAMPLE_RATE))
	for hit in 2:
		var offset: int = start + int(float(hit) * beat * 2.0 * float(SAMPLE_RATE))
		for i in length:
			var t: float = float(i) / float(SAMPLE_RATE)
			var env: float = minf(float(i) / 120.0, 1.0) * exp(-3.2 * t / (beat * 1.8))
			_add(mix, offset + i, sin(TAU * hz * t) * env * BASS_LEVEL)


static func _add_arp(mix: PackedFloat32Array, start: int, notes: Array, beat: float, pattern: PackedInt32Array) -> void:
	var step: int = int(beat * 0.5 * float(SAMPLE_RATE))
	var length: int = int(beat * 1.3 * float(SAMPLE_RATE))
	for n in pattern.size():
		var hz: float = _hz(int(notes[pattern[n]]) + 12)
		var offset: int = start + n * step
		for i in length:
			var t: float = float(i) / float(SAMPLE_RATE)
			var env: float = minf(float(i) / 60.0, 1.0) * exp(-5.5 * t / (beat * 1.3))
			var tone: float = sin(TAU * hz * t) + 0.25 * sin(TAU * hz * 2.0 * t)
			_add(mix, offset + i, tone * env * ARP_LEVEL)


static func _to_stream(mix: PackedFloat32Array, volume: float) -> AudioStreamWAV:
	var peak: float = 0.0001
	for sample in mix:
		peak = maxf(peak, absf(sample))
	var gain: float = clampf(volume, 0.0, 1.0) / peak
	var data := PackedByteArray()
	data.resize(mix.size() * 2)
	for i in mix.size():
		data.encode_s16(i * 2, int(clampf(mix[i] * gain, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = mix.size()
	return stream
