class_name SoundSynth
extends RefCounted

# Generates 16-bit mono sound as AudioStreamWAV, with no audio files. Pure, so tests can run it headless.

# === CONSTANTS ===

const MIX_RATE: int = 22050
const ATTACK_SECONDS: float = 0.005
const SIREN_BASE_PITCH: float = 1.0
const SIREN_TOP_PITCH: float = 1.35

enum Wave { SQUARE, TRIANGLE }


# === PUBLIC API ===

## Builds a sound `duration` seconds long. `freq` takes the position in the sound (0 to 1) and returns Hz.
## `fade_out` ramps the volume to silence at the end. `loop` makes the stream repeat seamlessly.
static func synth(duration: float, freq: Callable, wave: int, volume: float, fade_out: bool, loop: bool) -> AudioStreamWAV:
	var count: int = int(duration * MIX_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	var attack_samples: float = ATTACK_SECONDS * MIX_RATE
	for i: int in count:
		var t: float = float(i) / float(count)
		phase = fposmod(phase + float(freq.call(t)) / float(MIX_RATE), 1.0)
		var env: float = 1.0
		if not loop:
			env = minf(1.0, float(i) / attack_samples)
		if fade_out:
			env *= 1.0 - t
		var sample: float = clampf(wave_value(wave, phase) * env * volume, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream


## One sample of a waveform at `phase` (0 to 1 over one cycle), from -1 to 1.
static func wave_value(wave: int, phase: float) -> float:
	if wave == Wave.SQUARE:
		return 1.0 if phase < 0.5 else -1.0
	return 4.0 * absf(phase - 0.5) - 1.0


## Frequency that glides from `start` to `end` over the sound.
static func glide(start: float, end: float) -> Callable:
	return func(t: float) -> float: return lerpf(start, end, t)


## Frequency that steps through `notes` evenly over the sound.
static func arpeggio(notes: Array[float]) -> Callable:
	return func(t: float) -> float:
		var index: int = mini(int(t * notes.size()), notes.size() - 1)
		return notes[index]


## Pitch multiplier for the siren: 1.0 with every dot left at the start of a level, rising to the top as the level clears.
## `left_ratio` is pellets left divided by pellets at the start, 0 to 1.
static func siren_pitch(left_ratio: float) -> float:
	return lerpf(SIREN_TOP_PITCH, SIREN_BASE_PITCH, clampf(left_ratio, 0.0, 1.0))
