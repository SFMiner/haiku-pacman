extends RefCounted

# Each test_* method runs under tests/run_tests.gd. Counts are checked by expect().
# Tests SoundSynth only. Playback and what the sounds actually sound like need a windowed run.

# === STATE ===

var passes: int = 0
var fails: int = 0


# === HELPERS ===

func expect(condition: bool, message: String) -> void:
	if condition:
		passes += 1
	else:
		fails += 1
		print("  FAIL: %s" % message)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001


# === TESTS: STREAMS ===

func test_one_shot_length_and_format() -> void:
	var stream: AudioStreamWAV = SoundSynth.synth(0.1, SoundSynth.glide(440.0, 440.0), SoundSynth.Wave.SQUARE, 1.0, false, false)
	var count: int = int(0.1 * SoundSynth.MIX_RATE)
	expect(stream.data.size() == count * 2, "0.1 s gives %d 16-bit samples (got %d bytes)" % [count, stream.data.size()])
	expect(stream.format == AudioStreamWAV.FORMAT_16_BITS, "samples are 16-bit")
	expect(stream.mix_rate == SoundSynth.MIX_RATE, "mix rate is %d" % SoundSynth.MIX_RATE)
	expect(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "a one-shot does not loop")


func test_loop_flags_are_set() -> void:
	var count: int = int(0.5 * SoundSynth.MIX_RATE)
	var stream: AudioStreamWAV = SoundSynth.synth(0.5, SoundSynth.glide(440.0, 600.0), SoundSynth.Wave.TRIANGLE, 0.2, false, true)
	expect(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "a looping sound uses forward looping")
	expect(stream.loop_end == count, "the loop covers the whole sound (got %d)" % stream.loop_end)


func test_attack_starts_silent_and_fade_ends_silent() -> void:
	var count: int = int(0.2 * SoundSynth.MIX_RATE)
	var stream: AudioStreamWAV = SoundSynth.synth(0.2, SoundSynth.glide(440.0, 440.0), SoundSynth.Wave.SQUARE, 1.0, true, false)
	expect(stream.data.decode_s16(0) == 0, "the first sample is silent, so there is no click")
	var last: int = stream.data.decode_s16((count - 1) * 2)
	expect(absi(last) < 100, "a fading sound ends near silence (last sample %d)" % last)


func test_samples_stay_in_range() -> void:
	var stream: AudioStreamWAV = SoundSynth.synth(0.1, SoundSynth.glide(100.0, 2000.0), SoundSynth.Wave.SQUARE, 2.0, false, false)
	var worst: int = 0
	for i: int in int(stream.data.size() / 2):
		worst = maxi(worst, absi(stream.data.decode_s16(i * 2)))
	expect(worst <= 32767, "even with volume 2 the samples clip inside 16 bits (peak %d)" % worst)
	expect(worst > 20000, "a full-volume square reaches near full scale (peak %d)" % worst)


# === TESTS: WAVES AND FREQUENCIES ===

func test_wave_values() -> void:
	expect(_near(SoundSynth.wave_value(SoundSynth.Wave.SQUARE, 0.25), 1.0), "square is high in its first half")
	expect(_near(SoundSynth.wave_value(SoundSynth.Wave.SQUARE, 0.75), -1.0), "square is low in its second half")
	expect(_near(SoundSynth.wave_value(SoundSynth.Wave.TRIANGLE, 0.0), 1.0), "triangle starts at its peak")
	expect(_near(SoundSynth.wave_value(SoundSynth.Wave.TRIANGLE, 0.5), -1.0), "triangle reaches its trough at half a cycle")
	expect(_near(SoundSynth.wave_value(SoundSynth.Wave.TRIANGLE, 0.25), 0.0), "triangle crosses zero at a quarter cycle")


func test_glide_and_arpeggio() -> void:
	var glide: Callable = SoundSynth.glide(100.0, 200.0)
	expect(_near(float(glide.call(0.5)), 150.0), "glide is halfway at 0.5")
	var notes: Callable = SoundSynth.arpeggio([1.0, 2.0, 3.0, 4.0])
	expect(_near(float(notes.call(0.6)), 3.0), "arpeggio picks note 3 at 0.6")
	expect(_near(float(notes.call(0.99)), 4.0), "arpeggio picks the last note near the end")
	expect(_near(float(notes.call(1.0)), 4.0), "arpeggio does not run past the last note")


func test_siren_pitch_rises_as_pellets_go() -> void:
	expect(_near(SoundSynth.siren_pitch(1.0), SoundSynth.SIREN_BASE_PITCH), "full level starts at the base pitch")
	expect(_near(SoundSynth.siren_pitch(0.0), SoundSynth.SIREN_TOP_PITCH), "an empty level is at the top pitch")
	expect(SoundSynth.siren_pitch(0.25) > SoundSynth.siren_pitch(0.5), "fewer pellets means a higher siren")
	expect(_near(SoundSynth.siren_pitch(2.0), SoundSynth.SIREN_BASE_PITCH), "a ratio above 1 is clamped to the base pitch")
