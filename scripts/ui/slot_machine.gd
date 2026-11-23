extends Control
## Slot Machine con rulli rotanti, rimbalzo, leva cliccabile e lampadine.

signal finished(win: float, stake: float, res: Dictionary)
signal lever_clicked

const STRIP := ["cherry", "lemon", "bell", "clover", "horseshoe", "diamond", "seven", "cherry", "bell", "lemon", "clover", "horseshoe"]

var spinning := false
var _pos := [0.0, 2.0, 4.0]
var _start := [0.0, 0.0, 0.0]
var _target := [0.0, 0.0, 0.0]
var _dur := [0.9, 1.35, 1.85]
var _stopped := [true, true, true]
var _t := 0.0
var _spin_t := 0.0
var _lever := 0.0
var _res := {}
var _stake := 0.0
var _last_cell := [0, 0, 0]

func _ready() -> void:
	custom_minimum_size = Vector2(460, 410)

func spin(p_stake: float) -> void:
	if spinning:
		return
	_stake = p_stake
	_res = G.roll_slot()
	spinning = true
	_spin_t = 0.0
	_lever = 1.0
	var reels: Array = _res["reels"]
	# se primi due sono uguali, rallenta il terzo (suspense)
	var suspense: bool = reels[0] == reels[1]
	_dur = [0.85, 1.3, 2.25 if suspense else 1.75]
	for r in 3:
		_start[r] = fmod(_pos[r], float(STRIP.size()))
		var idx := STRIP.find(reels[r])
		var turns := 3 + r * 2
		_target[r] = float(turns * STRIP.size() + idx)
		if _target[r] <= _start[r] + STRIP.size() * 2:
			_target[r] += STRIP.size() * 2
		_stopped[r] = false
	Sfx.play("whoosh", 1.3, -6)

func _ease_reel(x: float) -> float:
	# rallenta con un piccolo rimbalzo elastico finale
	if x >= 1.0:
		return 1.0
	if x < 0.88:
		var k := x / 0.88
		return (1.0 - pow(1.0 - k, 2.6)) * 1.018
	var b := (x - 0.88) / 0.12
	return 1.0 + 0.018 * cos(b * PI)

func _process(delta: float) -> void:
	_t += delta
	_lever = maxf(0.0, _lever - delta * 3.0)
	if spinning:
		_spin_t += delta
		var all_done := true
		for r in 3:
			var k := clampf(_spin_t / _dur[r], 0.0, 1.0)
			_pos[r] = lerpf(_start[r], _target[r], _ease_reel(k))
			var cell := int(floor(_pos[r]))
			if cell != _last_cell[r] and k < 0.92:
				_last_cell[r] = cell
				if r == 2 or randf() < 0.5:
					Sfx.play("tick", 0.9 + r * 0.15, -6)
			if k >= 1.0 and not _stopped[r]:
				_stopped[r] = true
				Sfx.play("stop", 1.0 + r * 0.12)
			if not _stopped[r]:
				all_done = false
		if all_done:
			spinning = false
			G.stats["spins"] += 1
			if _res["kind"] == "tris" and _res["sym"] == "seven":
				G.stats["jackpots"] += 1
			var win: float = _res["mult"] * _stake * G.game_mult()
			finished.emit(win, _stake, _res)
	queue_redraw()

func _lever_knob() -> Vector2:
	var mr := _machine_rect()
	var base := Vector2(mr.end.x + 6, mr.position.y + 190)
	var a := lerpf(-1.15, 0.65, sin(_lever * PI))
	return base + Vector2(cos(a) * 30 + 18, sin(a) * 85)

func _gui_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.position.distance_to(_lever_knob()) < 34 or _machine_rect().has_point(mb.position):
			lever_clicked.emit()

func _machine_rect() -> Rect2:
	return Rect2((size.x - 390) * 0.5 - 14, 18, 370, 370)

func _draw() -> void:
	var mr := _machine_rect()
	# leva
	var lbase := Vector2(mr.end.x - 4, mr.position.y + 200)
	var knob := _lever_knob()
	draw_circle(lbase + Vector2(8, 0), 16, S.GOLD_DARK)
	S.circle_outline(self, lbase + Vector2(8, 0), 16, S.INK, 3)
	draw_line(lbase + Vector2(10, 0), knob, S.INK, 14, true)
	draw_line(lbase + Vector2(10, 0), knob, Color("d4dde4"), 8, true)
	draw_circle(knob + Vector2(3, 5), 22, S.SHADOW)
	draw_circle(knob, 22, S.RED)
	draw_circle(knob + Vector2(-7, -7), 6, Color(1, 1, 1, 0.7))
	S.circle_outline(self, knob, 22, S.INK, 3.5)
	# corpo macchina
	S.draw_card(self, mr, S.RED, 24, Vector2(8, 10), 4)
	S.draw_round_rect(self, Rect2(mr.position + Vector2(8, 8), Vector2(mr.size.x - 16, 30)), Color(1, 1, 1, 0.14), 18)
	# insegna luminosa
	var top := Rect2(mr.position + Vector2(24, 18), Vector2(mr.size.x - 48, 62))
	S.draw_card(self, top, S.INK, 14, Vector2(0, 4), 3, S.GOLD)
	S.text_in(self, top, "FORTUNA 777", 36, S.GOLD, 1, S.f_title, 4, S.RED_DARK)
	# lampadine attorno
	var bulbs := 18
	for i in bulbs:
		var p: Vector2
		if i < 9:
			p = mr.position + Vector2(16 + (i / 8.0) * (mr.size.x - 32), 92)
		else:
			p = mr.position + Vector2(16 + ((i - 9) / 8.0) * (mr.size.x - 32), 322)
		var on := (int(_t * (14.0 if spinning else 4.0)) + i) % 2 == 0
		draw_circle(p, 6, S.GOLD if on else S.RED_DARK)
		S.circle_outline(self, p, 6, S.INK, 2)
	# finestra dei rulli
	var win := Rect2(mr.position + Vector2(24, 106), Vector2(mr.size.x - 48, 200))
	S.draw_card(self, win, S.INK, 12, Vector2.ZERO, 4, S.GOLD_DARK)
	var rw := (win.size.x - 28) / 3.0
	var rh := win.size.y - 16
	for r in 3:
		var rr := Rect2(win.position + Vector2(8 + r * (rw + 6), 8), Vector2(rw, rh))
		S.draw_round_rect(self, rr, S.PAPER, 8)
		var center := rr.get_center()
		var p: float = _pos[r]
		var base := int(floor(p))
		var frac := p - base
		for off in [-1, 0, 1]:
			var idx := posmod(base + off, STRIP.size())
			var y: float = center.y + (off - frac) * 76.0
			var dist := absf(y - center.y) / (rh * 0.5)
			if dist < 1.05:
				var sc := lerpf(1.0, 0.55, clampf(dist, 0.0, 1.0))
				draw_set_transform(Vector2(center.x, y), 0, Vector2(1.0, sc))
				S.draw_symbol(self, STRIP[idx], Vector2.ZERO, 66)
				draw_set_transform(Vector2.ZERO)
		# ombre cilindro sopra/sotto
		S.draw_round_rect(self, Rect2(rr.position, Vector2(rr.size.x, 30)), Color(0, 0, 0, 0.25), 6)
		S.draw_round_rect(self, Rect2(rr.position.x, rr.end.y - 30, rr.size.x, 30), Color(0, 0, 0, 0.25), 6)
		draw_rect(rr, S.INK, false, 2.5)
	# linea di pagamento centrale
	var ly := win.get_center().y
	var win_flash: bool = not spinning and _res.get("mult", 0.0) > 0 and int(_t * 8) % 2 == 0
	var lcol := S.GOLD if win_flash else S.RED
	draw_line(Vector2(win.position.x + 2, ly), Vector2(win.end.x - 2, ly), Color(lcol, 0.7 if win_flash else 0.35), 4 if win_flash else 2)
	for sx in [win.position.x + 2, win.end.x - 2]:
		var dir := 1 if sx < win.get_center().x else -1
		draw_colored_polygon(PackedVector2Array([Vector2(sx, ly - 10), Vector2(sx, ly + 10), Vector2(sx + dir * 14, ly)]), lcol)
	# vassoio monete
	var tray := Rect2(mr.position + Vector2(44, 336), Vector2(mr.size.x - 88, 34))
	S.draw_card(self, tray, Color("2b2330"), 8, Vector2(0, 3), 3)
	var msg := "TIRA LA LEVA!"
	if spinning:
		msg = "Buona fortuna..."
	elif _res.has("mult"):
		msg = ("VINTI x%s!" % G.num(_res["mult"])) if _res["mult"] > 0 else "Riprova!"
	S.text_in(self, tray, msg, 18, S.GOLD if _res.get("mult", 0.0) > 0 else S.PAPER, 1, S.f_num)
