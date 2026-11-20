extends Node

const SETTINGS := "user://audio.cfg"
const VOLUMES := [&"Master", &"Music", &"Ambience", &"SFX", &"UI"]
const EFFECTS := {
	"click": [540, 210, 0.085, 0.04], "warn": [330, 440, 0.24, 0.04],
	"charge": [205, 350, 0.19, 0.09], "return": [120, 410, 0.40, 0.04],
	"open": [220, 410, 0.17, 0.08], "arc_miss": [155, 91, 0.13, 0.27],
	"arc_hit": [123, 45, 0.22, 0.43], "probe_miss": [880, 254, 0.10, 0.08],
	"probe_hit": [760, 153, 0.15, 0.35], "guard": [1120, 490, 0.115, 0.25],
	"break": [118, 34, 0.35, 0.48], "slam": [92, 29, 0.29, 0.48],
	"sweep": [240, 54, 0.24, 0.35], "dash": [470, 130, 0.12, 0.28],
	"evade": [500, 940, 0.13, 0.10], "hurt": [190, 58, 0.18, 0.40],
	"fall": [87, 33, 0.26, 0.33], "weight": [76, 32, 0.14, 0.20],
	"nailer_miss": [460, 92, 0.07, 0.40], "nailer_hit": [360, 65, 0.12, 0.50],
	"heartbeat": [67, 34, 0.20, 0.03], "step": [102, 54, 0.09, 0.24],
}
const RATE := 16000
var voices: Dictionary
var volumes: Dictionary
var music: AudioStreamPlayer
var atmosphere: AudioStreamPlayer
var score: AudioStreamSynchronized
var mix_tween: Tween
var duck_tween: Tween
var context := ""

func _ready() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS)
	for bus in VOLUMES:
		set_level(bus, float(config.get_value("volume", bus, 1.0)))
	for id in EFFECTS:
		var bus := &"Ambience" if id == "heartbeat" else &"UI" if id in ["click", "open"] else &"SFX"
		var gain := -18.0 if id in ["step", "heartbeat"] else -12.0 if id in ["weight", "charge"] else -7.0
		var voice := make_player(bus, gain)
		var args: Array = EFFECTS[id]
		var sound := make_effect(args, 4499)
		if id == "step" or id.ends_with("_miss") or id.ends_with("_hit"):
			var variants := AudioStreamRandomizer.new()
			variants.add_stream(0, sound)
			variants.add_stream(1, make_effect(args, 8131))
			variants.random_pitch = 1.035
			variants.random_volume_offset_db = 0.8
			voice.stream = variants
			voice.max_polyphony = 2
		else:
			voice.stream = sound
		voices[id] = voice
	music = make_player(&"MusicDuck", -11.0)
	score = AudioStreamSynchronized.new()
	score.stream_count = 2
	score.set_sync_stream(0, make_loop(0))
	score.set_sync_stream(1, make_loop(1))
	score.set_sync_stream_volume(1, -48.0)
	music.stream = score
	music.play()
	atmosphere = make_player(&"Ambience", -8.0)
	atmosphere.stream = make_loop(2)
	atmosphere.play()

func make_player(bus: StringName, gain: float) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.bus = bus
	voice.volume_db = gain
	add_child(voice)
	return voice

func set_level(bus: StringName, value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	volumes[bus] = value
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(index, value <= 0.0)
	if value > 0.0: AudioServer.set_bus_volume_linear(index, value * value)

func save_levels() -> void:
	var config := ConfigFile.new()
	for bus in VOLUMES: config.set_value("volume", bus, volumes[bus])
	if config.save(SETTINGS) != OK: push_warning("Could not save volume settings.")

func trigger(id: String, heavy: bool, weapon: String, combo: int) -> void:
	var voice: AudioStreamPlayer = voices[id]
	voice.pitch_scale = 1.0 + maxf(0, combo) * 0.025 if id == "arc_hit" else 1.0
	voice.play()
	if id.ends_with("_hit") or heavy:
		var weight: AudioStreamPlayer = voices.weight
		weight.pitch_scale = 0.78 if heavy else 0.95 if weapon == "arc" else 1.25
		weight.volume_db = -10.0 if heavy else -17.0 if weapon == "nailer" else -14.0
		weight.play()
	if id in ["warn", "charge", "slam", "hurt", "break"]: duck(id == "charge" or id == "warn")

func duck(warning: bool) -> void:
	var bus := AudioServer.get_bus_index(&"MusicDuck")
	if duck_tween: duck_tween.kill()
	duck_tween = create_tween()
	var set_gain := func(db: float): AudioServer.set_bus_volume_db(bus, db)
	duck_tween.tween_method(set_gain, AudioServer.get_bus_volume_db(bus), -4.0 if warning else -6.0, 0.055)
	duck_tween.tween_interval(0.12)
	duck_tween.tween_method(set_gain, -4.0 if warning else -6.0, 0.0, 0.42)

func set_context(next: String) -> void:
	if next == context: return
	context = next
	if mix_tween: mix_tween.kill()
	mix_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	var intensity := -2.0 if next == "boss" else -10.0 if next == "combat" else -48.0
	mix_tween.tween_method(func(db: float): score.set_sync_stream_volume(1, db), score.get_sync_stream_volume(1), intensity, 0.85)
	mix_tween.tween_property(atmosphere, "volume_db", -22.0 if next == "menu" else -9.0, 0.5)

func wav(bytes: PackedByteArray, loop := false) -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.mix_rate = RATE
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.data = bytes
	if loop:
		sample.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sample.loop_end = bytes.size() / 2
	return sample

func make_effect(args: Array, seed: int) -> AudioStreamWAV:
	var count := roundi(float(args[2]) * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in count:
		var t := float(i) / count
		phase += TAU * lerpf(args[0], args[1], t) / RATE
		var rise := minf(1.0, i / 65.0)
		var body := (sin(phase) * 0.68 + sin(phase * 2.02) * 0.19 + sin(phase * 3.01) * 0.06) * pow(1.0 - t, 2)
		var grain := rng.randf_range(-1.0, 1.0) * float(args[3]) * exp(-t * 10.0)
		bytes.encode_s16(i * 2, roundi(clampf((body + grain) * rise, -1.0, 1.0) * 27000.0))
	return wav(bytes)

func make_loop(layer: int) -> AudioStreamWAV:
	# All oscillator cycles and envelopes share an eight-second loop.
	const SECONDS := 8
	var bytes := PackedByteArray()
	bytes.resize(SECONDS * RATE * 2)
	for i in SECONDS * RATE:
		var t := float(i) / RATE
		var angle := TAU * t
		var sample: float
		match layer:
			0:
				var sway := 0.66 + 0.34 * cos(angle * 0.25)
				sample = (sin(angle * 55.0) * 0.15 + sin(angle * 82.5) * 0.09 + sin(angle * 110.0) * 0.062) * sway
				sample += sin(angle * 164.75) * pow(maxf(0.0, sin(angle * 0.25)), 2) * 0.06
			1:
				var pulse := pow(maxf(0.0, cos(angle * 2.0)), 5)
				sample = pulse * (sin(angle * 41.25) * 0.18 + sin(angle * 165.0) * 0.07)
				sample += (sin(angle * 103.875) + sin(angle * 104.0)) * 0.046
			_:
				var fan := 0.52 + 0.48 * sin(angle * 0.375)
				sample = (sin(angle * 47.0 + sin(angle * 0.5)) * 0.082 + sin(angle * 94.125) * 0.042) * fan
				sample += sin(angle * 318.75 + sin(angle * 5.0)) * 0.016
		bytes.encode_s16(i * 2, roundi(sample * 32700.0))
	return wav(bytes, true)
