class_name GameSound
extends Node

var voices: Array[AudioStreamPlayer] = []
var cues: Dictionary = {}
var limits: Dictionary = {}
var clock: float = 0.0
var volume: float = 0.55

func _ready() -> void:
	for i in 8:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	var notes := {"sword": [130, 0.08], "bolt": [380, 0.055], "orbit": [220, 0.07], "hit": [80, 0.065], "hurt": [65, 0.14], "pickup": [650, 0.04], "level": [540, 0.22], "select": [420, 0.08], "elite": [85, 0.55], "boss": [55, 0.75], "victory": [700, 0.65], "defeat": [90, 0.65]}
	for id in notes:
		cues[id] = synth(float(notes[id][0]), float(notes[id][1]))
	cues.gold = synth(980, 0.045)
	cues.arrow = synth(310, 0.06)
	cues.wave = synth(160, 0.28)
	cues.portal = synth(46, 0.95)
	cues.summon = synth(210, 0.22)
	cues.fire = synth(180, 0.12)
	cues.thunder = synth(75, 0.23)
	cues.ice = synth(990, 0.18)

func _process(delta: float) -> void:
	clock += delta

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	cues.clear()

func synth(hz: float, length: float) -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	var count := int(length * 22050)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		var t := float(i) / 22050.0
		var envelope := pow(1.0 - float(i) / count, 2.0) * minf(t * 150, 1)
		var tone := sin(TAU * hz * t * (1.0 - 0.22 * t / length))
		var value := int((tone + sin(TAU * hz * 1.5 * t) * 0.2) * envelope * 6500)
		bytes.encode_s16(i * 2, value)
	sample.data = bytes
	return sample

func play_cue(id: String) -> void:
	if not cues.has(id) or volume <= 0:
		return
	var interval := 0.10 if id in ["hit", "pickup", "orbit", "gold", "arrow"] else 0.04
	if clock - float(limits.get(id, -99.0)) < interval:
		return
	for voice in voices:
		if not voice.playing:
			voice.stream = cues[id]
			voice.volume_db = linear_to_db(volume * 0.65)
			voice.pitch_scale = randf_range(0.96, 1.04)
			voice.play()
			limits[id] = clock
			return
