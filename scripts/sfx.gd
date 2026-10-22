extends Node

# Plays the game's sound effects. Every sound is generated once at start-up (see SoundSynth).
# One-shot sounds use a small pool of players. The siren is its own looping player, so its pitch can follow the dots left.

# === CONSTANTS ===

const POOL_SIZE: int = 4
const SIREN_SECONDS: float = 0.5
const SIREN_LOW_HZ: float = 440.0
const SIREN_HIGH_HZ: float = 600.0

# === STATE ===

var _sounds: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _siren: AudioStreamPlayer = null


# === LIFECYCLE ===

func _ready() -> void:
	_sounds = {
		"chomp": SoundSynth.synth(0.06, SoundSynth.glide(520.0, 380.0), SoundSynth.Wave.TRIANGLE, 0.5, true, false),
		"power": SoundSynth.synth(0.35, SoundSynth.glide(260.0, 880.0), SoundSynth.Wave.SQUARE, 0.25, true, false),
		"eat_ghost": SoundSynth.synth(0.25, SoundSynth.glide(200.0, 1200.0), SoundSynth.Wave.SQUARE, 0.25, true, false),
		"death": SoundSynth.synth(1.2, SoundSynth.glide(900.0, 120.0), SoundSynth.Wave.TRIANGLE, 0.45, true, false),
		"fruit": SoundSynth.synth(0.3, SoundSynth.arpeggio([523.0, 659.0, 784.0]), SoundSynth.Wave.SQUARE, 0.2, true, false),
		"level_clear": SoundSynth.synth(0.6, SoundSynth.arpeggio([523.0, 659.0, 784.0, 1047.0]), SoundSynth.Wave.SQUARE, 0.2, false, false),
		"siren": SoundSynth.synth(SIREN_SECONDS, _siren_glide(), SoundSynth.Wave.TRIANGLE, 0.2, false, true),
	}
	for i: int in POOL_SIZE:
		_pool.append(_new_player())
	_siren = _new_player()
	_siren.stream = _sounds["siren"]


# === PUBLIC API ===

## Plays a named sound effect once.
func play(sfx_name: String) -> void:
	if not _sounds.has(sfx_name):
		push_warning("Unknown sound: %s" % sfx_name)
		return
	var player: AudioStreamPlayer = _free_player()
	player.stream = _sounds[sfx_name]
	player.play()


func siren_start() -> void:
	if not _siren.playing:
		_siren.play()


func siren_stop() -> void:
	_siren.stop()


## Speeds the siren up as pellets run out. `left_ratio` is pellets left over pellets at the start of the level.
func siren_progress(left_ratio: float) -> void:
	_siren.pitch_scale = SoundSynth.siren_pitch(left_ratio)


## Pauses or resumes every sound. Called when the game is paused.
func set_paused(paused: bool) -> void:
	for player: AudioStreamPlayer in _pool:
		player.stream_paused = paused
	_siren.stream_paused = paused


# === INTERNAL ===

## Triangle up and back down over the loop, so the sound starts and ends on the same pitch.
func _siren_glide() -> Callable:
	return func(t: float) -> float: return lerpf(SIREN_LOW_HZ, SIREN_HIGH_HZ, 1.0 - absf(2.0 * t - 1.0))


func _new_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(player)
	return player


func _free_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _pool:
		if not player.playing:
			return player
	return _pool[0]
