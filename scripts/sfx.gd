extends Node
## Autoload "Sfx": effetti sonori + 3 tracce musicali dinamiche sintetizzate in codice:
## - "chill": Jazz-Lounge da bisca (94 BPM)
## - "rush":  Panic / Urgenza quando il tempo dello Squalo sta per scadere (152 BPM, basso incalzante + sirena)
## - "hype":  Euforia / Festa quando sei in Frenesia, Fortuna x5 o hai appena fatto una grossa vincita (136 BPM, brass + arpeggi)

const RATE := 22050
var _streams := {}
var _music_streams := {}
var _players: Array[AudioStreamPlayer] = []
var _idx := 0
var _music: AudioStreamPlayer
var _cur_track := ""
var _hype_timer := 0.0
var _last_play := {}
var _heartbeat_t := 0.0

func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -13.0
	add_child(_music)
	_build_sfx()
	_build_all_music()
	switch_music("chill")

func trigger_hype(duration := 14.0) -> void:
	_hype_timer = maxf(_hype_timer, duration)

func current_mood() -> String:
	return _cur_track

func _process(delta: float) -> void:
	if _hype_timer > 0:
		_hype_timer = maxf(0.0, _hype_timer - delta)
	# Scegli la traccia musicale dinamicamente in base allo stato della partita
	var desired := "chill"
	var is_last_day: bool = G.day_in_deadline >= int(G.deadline_data()["days"])
	var is_urgent: bool = not G.deadline_paused and G.intro_seen and (G.day_time_left < 20.0 or (is_last_day and G.day_time_left < 32.0 and G.money + G.debt_paid < float(G.deadline_data()["quota"])))
	if G.frenzy_time > 0 or G.luckboost_time > 0 or _hype_timer > 0:
		desired = "hype"
	elif is_urgent:
		desired = "rush"
	if desired != _cur_track:
		switch_music(desired)
	# Battito / ticchettio d'ansia negli ultimi 10 secondi del giorno
	if not G.deadline_paused and G.intro_seen and G.day_time_left <= 10.0 and G.day_time_left > 0.0:
		_heartbeat_t -= delta
		if _heartbeat_t <= 0.0:
			_heartbeat_t = clampf(G.day_time_left * 0.08, 0.22, 0.75)
			play("heartbeat", 1.0 + (10.0 - G.day_time_left) * 0.04, -2.0)

func switch_music(track: String) -> void:
	if not _music_streams.has(track):
		return
	_cur_track = track
	_music.stream = _music_streams[track]
	_music.volume_db = -11.0 if track != "chill" else -13.5
	if G.music_on:
		_music.play()

func play(name: String, pitch := 1.0, vol_db := 0.0) -> void:
	if not G.sfx_on or not _streams.has(name):
		return
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
		"tri": return 4.0 * absf(fmod(ph, 1.0) - 0.5) - 1.0
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
		var env := minf(1.0, float(i) / (attack * RATE + 1.0)) * pow(1.0 - t, 1.5)
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
	b = PackedFloat32Array(); _tone(b, 0, 0.09, 110, 55, "sine", 0.65); _tone(b, 0.11, 0.07, 130, 65, "sine", 0.45); _streams["heartbeat"] = _to_stream(b)
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

# ------------------------------------------------------------------ 3 TRACCE MUSICALI
func _midi(n: int) -> float:
	return 440.0 * pow(2.0, (n - 69) / 12.0)

func _build_all_music() -> void:
	_music_streams["chill"] = _build_chill_track()
	_music_streams["rush"] = _build_rush_track()
	_music_streams["hype"] = _build_hype_track()

## 1. CHILL: Lounge-Jazz della Bisca (96 BPM)
func _build_chill_track() -> AudioStreamWAV:
	var bpm := 96.0
	var beat := 60.0 / bpm
	var chords := [[57, 60, 64, 67], [50, 53, 57, 60], [55, 59, 62, 65], [48, 52, 55, 59]]
	var bars := chords.size()
	var total := bars * 4 * beat
	var buf := PackedFloat32Array()
	buf.resize(int(total * RATE) + 10)
	for bi in bars:
		var ch: Array = chords[bi]
		var t0 := bi * 4 * beat
		for k in ch.size():
			_tone(buf, t0, 4 * beat, _midi(ch[k] + 12), _midi(ch[k] + 12), "sine", 0.05, 0.25, 0.004)
		for st in [1.5, 3.0]:
			for k in ch.size():
				_tone(buf, t0 + st * beat, 0.35, _midi(ch[k] + 12), _midi(ch[k] + 12), "tri", 0.035, 0.01)
		var root: int = ch[0] - 12
		var walk := [root, root + 7, root + 12, root + 7]
		for q in 4:
			_tone(buf, t0 + q * beat, beat * 0.9, _midi(walk[q]), _midi(walk[q]), "tri", 0.22, 0.01)
			_noise(buf, t0 + q * beat, 0.05, 0.05, 0.95)
			_noise(buf, t0 + (q + 0.66) * beat, 0.03, 0.035, 0.95)
	var rng := RandomNumberGenerator.new(); rng.seed = 777
	var scale := [69, 72, 74, 76, 79, 81, 84]
	var t := 0.0
	while t < total - beat:
		var d: float = beat * [0.5, 1.0, 1.0, 1.5][rng.randi() % 4]
		if rng.randf() < 0.7:
			var n: int = scale[rng.randi() % scale.size()]
			_tone(buf, t, d * 0.95, _midi(n), _midi(n), "sine", 0.06, 0.02, 0.006)
		t += d
	buf.resize(int(total * RATE))
	return _to_stream(buf, true)

## 2. RUSH: Ansia / Tempo che scade / Lo Squalo alla porta (154 BPM, basso ottave + arpeggio minore + cassa veloce)
func _build_rush_track() -> AudioStreamWAV:
	var bpm := 154.0
	var beat := 60.0 / bpm
	var roots := [45, 45, 46, 40] # Am, Am, Bb, E
	var arp_notes := [[69, 72, 76, 81], [69, 72, 76, 80], [70, 74, 77, 82], [68, 71, 76, 80]]
	var bars := 4
	var total := bars * 4 * beat
	var buf := PackedFloat32Array()
	buf.resize(int(total * RATE) + 10)
	for bi in bars:
		var t0 := bi * 4 * beat
		var r: int = roots[bi]
		var arp: Array = arp_notes[bi]
		# Basso in ottavi galoppante + cassa e rullante serrati
		for eig in 8:
			var te := t0 + eig * 0.5 * beat
			var bn := r if eig % 2 == 0 else r + 12
			_tone(buf, te, 0.45 * beat, _midi(bn), _midi(bn), "saw", 0.16, 0.004)
			# Arpeggio in sedicesimi d'urgenza
			for s in 2:
				var ts := te + s * 0.25 * beat
				var an: int = arp[(eig * 2 + s) % arp.size()]
				_tone(buf, ts, 0.22 * beat, _midi(an), _midi(an), "square", 0.08, 0.003)
		for q in 4:
			var tq := t0 + q * beat
			_tone(buf, tq, 0.11, 140, 45, "sine", 0.35) # kick
			_noise(buf, tq + 0.5 * beat, 0.05, 0.12, 0.85) # offbeat hat
			if q % 2 == 1:
				_noise(buf, tq, 0.10, 0.22, 0.55) # snare
	buf.resize(int(total * RATE))
	return _to_stream(buf, true)

## 3. HYPE: Frenesia / Jackpot / Grossa vincita (136 BPM, accordi maggiori, fanfara synth e basso funk)
func _build_hype_track() -> AudioStreamWAV:
	var bpm := 136.0
	var beat := 60.0 / bpm
	var chords := [[60, 64, 67, 72], [65, 69, 72, 77], [67, 71, 74, 79], [60, 64, 67, 72]] # C, F, G, C
	var bars := 4
	var total := bars * 4 * beat
	var buf := PackedFloat32Array()
	buf.resize(int(total * RATE) + 10)
	var lead := [72, 76, 79, 84, 79, 76, 79, 84]
	for bi in bars:
		var t0 := bi * 4 * beat
		var ch: Array = chords[bi]
		var r: int = ch[0] - 12
		# Accordi brass in levare
		for st in [0.0, 1.5, 2.5]:
			for k in ch.size():
				_tone(buf, t0 + st * beat, 0.45 * beat, _midi(ch[k]), _midi(ch[k]), "saw", 0.055, 0.008)
		# Basso funk rimbalzante + batteria dance
		for eig in 8:
			var te := t0 + eig * 0.5 * beat
			var bn := r if eig % 2 == 0 else r + 12
			_tone(buf, te, 0.42 * beat, _midi(bn), _midi(bn), "tri", 0.24, 0.005)
			var ln: int = lead[eig] + (2 if bi == 2 else 0)
			_tone(buf, te, 0.40 * beat, _midi(ln), _midi(ln), "square", 0.09, 0.005, 0.01)
		for q in 4:
			var tq := t0 + q * beat
			_tone(buf, tq, 0.12, 150, 50, "sine", 0.35)
			_noise(buf, tq + 0.5 * beat, 0.06, 0.14, 0.9)
	buf.resize(int(total * RATE))
	return _to_stream(buf, true)
