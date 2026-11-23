extends Node
## Autoload "Sfx": tutti i suoni sono sintetizzati in codice (nessun file audio).

const RATE := 22050
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _idx := 0
var _music: AudioStreamPlayer
var _last_play := {}

func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -14.0
	add_child(_music)
	_build_sfx()
	_build_music_threaded()

func play(name: String, pitch := 1.0, vol_db := 0.0) -> void:
	if not G.sfx_on or not _streams.has(name):
		return
	# limita la frequenza di ripetizione
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(name, 0)) < 30:
		return
	_last_play[name] = now
	var p := _players[_idx]
	_idx = (_idx + 1) % _players.size()
	p.stream = _streams[name]
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.volume_db = vol_db
	p.play()

func set_music(on: bool) -> void:
	G.music_on = on
	if on and _music.stream and not _music.playing:
		_music.play()
	elif not on:
		_music.stop()

# ------------------------------------------------------------------ SINTESI
func _wave(kind: String, ph: float) -> float:
	match kind:
		"sine": return sin(ph * TAU)
		"square": return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
		"tri": return 4.0 * abs(fmod(ph, 1.0) - 0.5) - 1.0
		"saw": return 2.0 * fmod(ph, 1.0) - 1.0
	return 0.0

func _tone(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, kind := "square", vol := 0.3, attack := 0.004, vib := 0.0) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	if buf.size() < s0 + n:
		buf.resize(s0 + n)
	var ph := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		if vib > 0:
			f *= 1.0 + vib * sin(i * 0.0025)
		ph += f / RATE
		var env := minf(1.0, float(i) / (attack * RATE + 1.0)) * pow(1.0 - t, 1.6)
		buf[s0 + i] += _wave(kind, ph) * vol * env

func _noise(buf: PackedFloat32Array, start: float, dur: float, vol := 0.3, lowpass := 0.5) -> void:
	var s0 := int(start * RATE)
	var n := int(dur * RATE)
	if buf.size() < s0 + n:
		buf.resize(s0 + n)
	var last := 0.0
	for i in n:
		var t := float(i) / n
		var v := randf_range(-1, 1)
		last = lerpf(last, v, lowpass)
		buf[s0 + i] += last * vol * pow(1.0 - t, 2.0)

func _to_stream(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var v := int(clampf(buf[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w

func _build_sfx() -> void:
	var b: PackedFloat32Array
	b = PackedFloat32Array(); _tone(b, 0, 0.05, 1400, 900, "square", 0.18); _streams["click"] = _to_stream(b)
	b = PackedFloat32Array(); _tone(b, 0, 0.07, 988, 988, "square", 0.2); _tone(b, 0.06, 0.16, 1319, 1319, "square", 0.2); _streams["coin"] = _to_stream(b)
	b = PackedFloat32Array(); _tone(b, 0, 0.12, 500, 1200, "tri", 0.35); _tone(b, 0.05, 0.1, 900, 1800, "square", 0.1); _streams["buy"] = _to_stream(b)
	b = PackedFloat32Array(); _noise(b, 0, 0.06, 0.25, 0.9); _streams["scratch"] = _to_stream(b)
	b = PackedFloat32Array(); _tone(b, 0, 0.025, 2200, 1800, "square", 0.08); _streams["tick"] = _to_stream(b)
	b = PackedFloat32Array(); _tone(b, 0, 0.12, 180, 70, "sine", 0.6); _noise(b, 0, 0.04, 0.2, 0.3); _streams["stop"] = _to_stream(b)
	b = PackedFloat32Array()
	var notes := [523.25, 659.25, 783.99, 1046.5]
	for i in notes.size():
		_tone(b, i * 0.08, 0.22, notes[i], notes[i], "square", 0.16)
		_tone(b, i * 0.08, 0.22, notes[i] * 0.5, notes[i] * 0.5, "tri", 0.2)
	_streams["win"] = _to_stream(b)
	b = PackedFloat32Array()
	var jn := [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5, 1318.5, 1568.0]
	for i in jn.size():
		_tone(b, i * 0.09, 0.3, jn[i], jn[i], "square", 0.14, 0.004, 0.01)
		_tone(b, i * 0.09, 0.3, jn[i] * 0.5, jn[i] * 0.5, "tri", 0.2)
	_tone(b, 0.75, 0.9, 1046.5, 1046.5, "square", 0.12, 0.004, 0.02)
	_tone(b, 0.75, 0.9, 1318.5, 1318.5, "tri", 0.18, 0.004, 0.02)
	_streams["jackpot"] = _to_stream(b)
	b = PackedFloat32Array(); _tone(b, 0, 0.18, 330, 300, "square", 0.15); _tone(b, 0.16, 0.35, 247, 200, "square", 0.15); _streams["lose"] = _to_stream(b)
	b = PackedFloat32Array()
	for i in 6:
		_noise(b, i * 0.045 + randf() * 0.01, 0.035, 0.35, 0.6)
		_tone(b, i * 0.045, 0.02, 900 + randf() * 600, 700, "square", 0.06)
	_streams["dice"] = _to_stream(b)
	b = PackedFloat32Array(); _tone(b, 0, 0.12, 600, 950, "tri", 0.3); _tone(b, 0.11, 0.25, 950, 520, "tri", 0.3, 0.004, 0.03); _streams["cat"] = _to_stream(b)
	b = PackedFloat32Array(); _noise(b, 0, 0.08, 0.3, 0.5); _tone(b, 0.05, 0.5, 2093, 2093, "sine", 0.3); _tone(b, 0.05, 0.5, 2637, 2637, "sine", 0.2); _streams["cash"] = _to_stream(b)
	b = PackedFloat32Array(); _tone(b, 0, 0.05, 300, 600, "sine", 0.35); _streams["pop"] = _to_stream(b)
	b = PackedFloat32Array(); _tone(b, 0, 0.6, 200, 60, "saw", 0.25); _noise(b, 0, 0.4, 0.3, 0.2); _streams["whoosh"] = _to_stream(b)

# ------------------------------------------------------------------ MUSICA (lounge procedurale)
func _midi(n: int) -> float:
	return 440.0 * pow(2.0, (n - 69) / 12.0)

func _build_music_threaded() -> void:
	var bpm := 96.0
	var beat := 60.0 / bpm
	# Am7 Dm7 G7 Cmaj7 Fmaj7 Bm7b5 E7 Am7
	var chords := [[57, 60, 64, 67], [50, 53, 57, 60], [55, 59, 62, 65], [48, 52, 55, 59], [53, 57, 60, 64], [47, 50, 53, 57], [52, 56, 59, 62], [57, 60, 64, 67]]
	var bars := chords.size()
	var total := bars * 4 * beat
	var buf := PackedFloat32Array()
	buf.resize(int(total * RATE) + 10)
	for bi in bars:
		var ch: Array = chords[bi]
		var t0 := bi * 4 * beat
		# pad (accordi morbidi)
		for k in ch.size():
			_tone(buf, t0, 4 * beat, _midi(ch[k] + 12), _midi(ch[k] + 12), "sine", 0.05, 0.25, 0.004)
		# stab sincopati
		for st in [1.5, 3.0]:
			for k in ch.size():
				_tone(buf, t0 + st * beat, 0.35, _midi(ch[k] + 12), _midi(ch[k] + 12), "tri", 0.035, 0.01)
		# basso walking
		var root: int = ch[0] - 12
		var walk := [root, root + 7, root + 12, root + 7]
		for q in 4:
			_tone(buf, t0 + q * beat, beat * 0.9, _midi(walk[q]), _midi(walk[q]), "tri", 0.22, 0.01)
		# spazzole / hi-hat swing
		for q in 4:
			_noise(buf, t0 + q * beat, 0.05, 0.05, 0.95)
			_noise(buf, t0 + (q + 0.66) * beat, 0.03, 0.035, 0.95)
	# melodia pentatonica casuale ma deterministica
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var scale := [69, 72, 74, 76, 79, 81, 84]
	var t := 0.0
	while t < total - beat:
		var d: float = beat * [0.5, 1.0, 1.0, 1.5, 2.0][rng.randi() % 5]
		if rng.randf() < 0.7:
			var n: int = scale[rng.randi() % scale.size()]
			_tone(buf, t, d * 0.95, _midi(n), _midi(n), "sine", 0.06, 0.02, 0.006)
		t += d
	buf.resize(int(total * RATE))
	var stream := _to_stream(buf, true)
	call_deferred("_music_ready", stream)

func _music_ready(stream: AudioStreamWAV) -> void:
	_music.stream = stream
	if G.music_on:
		_music.play()
