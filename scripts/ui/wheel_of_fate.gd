extends Control
## Ruota del Destino (All-in / Alta Tensione per Streamer):
## 8 spicchi: Jackpot x8, Triplica x3, Raddoppia x2, +3 Ticket, Frenesia x7, Squalo (-50%), o Teschio (perdi la puntata)!

signal finished(win: float, stake: float, slice: Dictionary)
signal wheel_clicked

var spinning := false
var _ang := 0.0
var _start_ang := 0.0
var _target_ang := 0.0
var _spin_t := 0.0
var _dur := 3.2
var _stake := 0.0
var _chosen_idx := 0
var _last_tick := -1

func _ready() -> void:
	custom_minimum_size = Vector2(460, 410)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func spin_wheel(p_stake: float) -> void:
	if spinning:
		return
	_stake = p_stake
	spinning = true
	_spin_t = 0.0
	_start_ang = fmod(_ang, TAU)
	var n := G.WHEEL_SLICES.size()
	_chosen_idx = randi() % n
	# Dadi Truccati / Fortuna aiutano a evitare il Teschio!
	if G.WHEEL_SLICES[_chosen_idx]["val"] == 0.0 and randf() < G.dice_bonus_chance():
		_chosen_idx = [0, 2, 3, 4, 6].pick_random()
	var slice_a := TAU / n
	# La freccia è in alto (-PI/2): calcoliamo l'angolo finale che porta lo spicco _chosen_idx sotto la freccia
	var desired := -PI * 0.5 - (_chosen_idx + 0.5) * slice_a + randf_range(-0.32, 0.32) * slice_a
	var turns := randi_range(5, 7) * TAU
	_target_ang = desired + turns
	while _target_ang < _start_ang + 4.0 * TAU:
		_target_ang += TAU
	Sfx.play("whoosh", 1.1)

func _gui_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		wheel_clicked.emit()

func _process(delta: float) -> void:
	if spinning:
		_spin_t += delta
		var k := clampf(_spin_t / _dur, 0.0, 1.0)
		var ease_k := 1.0 - pow(1.0 - k, 3.4)
		_ang = lerpf(_start_ang, _target_ang, ease_k)
		var n := G.WHEEL_SLICES.size()
		var tick := int(floor((_ang + PI * 0.5) / (TAU / n)))
		if tick != _last_tick:
			_last_tick = tick
			Sfx.play("tick", 1.15, -4)
		if k >= 1.0:
			spinning = false
			G.stats["wheels"] = int(G.stats.get("wheels", 0)) + 1
			var sl: Dictionary = G.WHEEL_SLICES[_chosen_idx]
			var win := 0.0
			match sl["kind"]:
				"mult":
					win = _stake * float(sl["val"]) * G.game_mult()
				"tickets":
					var tg := int(sl["val"])
					G.tickets += tg
					G.total_tickets_earned += tg
					win = _stake
				"frenzy":
					G.frenzy_time = maxf(G.frenzy_time, float(sl["val"]))
					win = _stake * 1.5
				"shark":
					win = _stake * 0.5
			finished.emit(win, _stake, sl)
	queue_redraw()

func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.5 + 16)
	var r := minf(size.x, size.y) * 0.40
	# Ombra e cornice dorata esterna
	draw_circle(c + Vector2(6, 9), r + 14, S.SHADOW)
	draw_circle(c, r + 14, S.WOOD)
	S.circle_outline(self, c, r + 14, S.INK, 4)
	draw_circle(c, r + 4, S.GOLD)
	S.circle_outline(self, c, r + 4, S.INK, 3)

	var n := G.WHEEL_SLICES.size()
	var slice_a := TAU / n
	for i in n:
		var sl: Dictionary = G.WHEEL_SLICES[i]
		var a0 := _ang + i * slice_a
		var a1 := a0 + slice_a
		var pts := PackedVector2Array([c])
		for s in 14:
			var a := lerpf(a0, a1, float(s) / 13.0)
			pts.append(c + Vector2.from_angle(a) * r)
		draw_colored_polygon(pts, sl["col"])
		draw_line(c, c + Vector2.from_angle(a0) * r, S.INK, 3.0)
		# Testo radiale
		var am := (a0 + a1) * 0.5
		var tp := c + Vector2.from_angle(am) * (r * 0.62)
		draw_set_transform(tp, am)
		var fcol := S.GOLD if sl["col"] == S.INK else S.PAPER
		S.text(self, Vector2(0, 6), sl["label"], 14, fcol, 1, S.f_title, 4, S.INK)
		draw_set_transform(Vector2.ZERO)
		# Piolo metallico sul bordo
		var peg := c + Vector2.from_angle(a0) * (r + 8)
		draw_circle(peg, 4.5, S.PAPER)
		S.circle_outline(self, peg, 4.5, S.INK, 1.5)

	# Mozzo centrale
	S.draw_chip(self, c, 32, S.RED)
	S.text_in(self, Rect2(c - Vector2(28, 28), Vector2(56, 56)), "ALL\nIN", 15, S.GOLD, 1, S.f_title, 4, S.INK)

	# Freccia indicatrice in alto
	var tip := c + Vector2(0, -r + 6)
	var arrow := PackedVector2Array([tip, tip + Vector2(-16, -28), tip + Vector2(16, -28)])
	draw_colored_polygon(arrow, S.GOLD)
	arrow.append(arrow[0])
	draw_polyline(arrow, S.INK, 3.5, true)
	S.text(self, Vector2(c.x, 15), "RUOTA DEL DESTINO — CLICCA PER GIRARE!", 17, S.GOLD, 1, S.f_title, 5, S.INK)
