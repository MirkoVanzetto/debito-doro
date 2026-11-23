extends Control
## Card di un'attività (stile AdVenture Capitalist ma sul tavolo verde).

var i := 0
var fx: Control
var buy_btn: Button
var _pulse := 0.0
var _bump := 0.0

func setup(idx: int, p_fx: Control) -> void:
	i = idx
	fx = p_fx
	custom_minimum_size = Vector2(500, 116)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn = S.make_button("COMPRA", S.GOLD, 17)
	buy_btn.custom_minimum_size = Vector2(138, 0)
	add_child(buy_btn)
	buy_btn.pressed.connect(_on_buy)
	G.cycle_done.connect(_on_cycle)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if buy_btn:
		buy_btn.position = Vector2(size.x - 152, 16)
		buy_btn.size = Vector2(138, size.y - 34)

func _on_buy() -> void:
	var n := G.buy_amount(i)
	if G.buy_business(i):
		_bump = 1.0
		if fx:
			fx.popup(buy_btn.global_position + Vector2(69, 0), "+%d" % n, S.GOLD, 22)

func _on_cycle(idx: int, amt: float) -> void:
	if idx != i or fx == null or not is_visible_in_tree():
		return
	if G.cycle_time(i) >= 0.45:
		fx.popup(global_position + Vector2(_bar_rect().get_center().x, 30), "+" + G.fmt(amt), S.GOLD, 24)
		if G.cycle_time(i) >= 2.0:
			fx.coins(global_position + Vector2(58, size.y * 0.5), 3)

func _emblem_center() -> Vector2:
	return Vector2(60, size.y * 0.5 - 6)

func _bar_rect() -> Rect2:
	return Rect2(118, 42, size.x - 118 - 166, 32)

func _gui_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var hit := mb.position.distance_to(_emblem_center()) < 46 or _bar_rect().grow(6).has_point(mb.position)
		if hit and G.start_cycle(i):
			_bump = 1.0
			Sfx.play("pop", 1.0 + i * 0.05)

func _process(delta: float) -> void:
	_pulse += delta
	_bump = maxf(0.0, _bump - delta * 4.0)
	var n := G.buy_amount(i)
	var c := G.cost_of(i, n)
	var label := "x%d" % n
	buy_btn.text = "COMPRA %s\n%s" % [label, G.fmt(c)]
	buy_btn.disabled = G.money < c
	var can_click: bool = G.owned[i] > 0 and not G.running[i] and not G.managers[i]
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_click else Control.CURSOR_ARROW
	queue_redraw()

func _draw() -> void:
	var b: Dictionary = G.BUSINESSES[i]
	var col: Color = b["color"]
	var o: int = G.owned[i]
	var locked := o == 0
	var r := Rect2(Vector2(4, 2), size - Vector2(14, 14))
	S.draw_card(self, r, S.PAPER if not locked else S.PAPER_DARK, 16, Vector2(6, 7))
	# strisce colorate sul bordo sinistro (come una carta da gioco)
	S.draw_round_rect(self, Rect2(r.position + Vector2(3, 3), Vector2(110, r.size.y - 6)), col.lerp(S.PAPER, 0.75), 13)
	# emblema
	var ec := _emblem_center()
	var er := 40.0 * (1.0 + 0.08 * _bump)
	var can_click: bool = o > 0 and not G.running[i] and not G.managers[i]
	if can_click:
		er *= 1.0 + 0.05 * sin(_pulse * 7.0)
		draw_circle(ec, er + 8, Color(S.GOLD, 0.35 + 0.25 * sin(_pulse * 7.0)))
	if locked:
		S.draw_chip(self, ec, er, S.GREY, true, 8)
		S.text_in(self, Rect2(ec - Vector2(20, 20), Vector2(40, 40)), "?", 34, S.PAPER, 1, S.f_title, 5)
	else:
		S.draw_chip(self, ec, er, col, true, 8)
		draw_circle(ec, er * 0.62, S.PAPER)
		S.circle_outline(self, ec, er * 0.62, S.INK, 2.5)
		S.draw_icon(self, b["icon"], ec, er * 1.1)
	# nastro col numero posseduto
	var rib := Rect2(ec.x - 34, ec.y + 30, 68, 24)
	S.draw_card(self, rib, S.INK, 7, Vector2(2, 3), 2, S.INK)
	S.text_in(self, rib, str(o), 18, S.GOLD, 1, S.f_num)
	if G.managers[i]:
		draw_set_transform(ec + Vector2(-30, -36), -0.35)
		S.draw_card(self, Rect2(-24, -11, 50, 22), S.RED, 5, Vector2(2, 2), 2)
		S.text_in(self, Rect2(-24, -11, 50, 22), "AUTO", 14, S.PAPER, 1, S.f_title)
		draw_set_transform(Vector2.ZERO)
	# nome
	S.text(self, Vector2(118, 32), b["name"], 22, S.INK, 0, S.f_title, 0, S.INK, _bar_rect().size.x)
	# barra di progresso
	var br := _bar_rect()
	S.draw_card(self, br, Color("2a2230"), 9, Vector2(0, 3), 3)
	var t := G.cycle_time(i)
	var p: float = G.progress[i]
	var fast: bool = t < 0.25 and G.running[i]
	if fast:
		p = 1.0
	if p > 0.0 and not locked:
		var fr := Rect2(br.position + Vector2(3, 3), Vector2((br.size.x - 6) * clampf(p, 0, 1), br.size.y - 6))
		if fr.size.x > 4:
			S.draw_round_rect(self, fr, col.lightened(0.1), 7)
			S.draw_round_rect(self, Rect2(fr.position, Vector2(fr.size.x, fr.size.y * 0.4)), Color(1, 1, 1, 0.25), 6)
			if fast:
				# strisce animate quando la produzione è continua
				var off := fmod(_pulse * 60.0, 24.0)
				var x := fr.position.x - 24 + off
				while x < fr.end.x:
					var a := maxf(fr.position.x, x)
					var bb := minf(fr.end.x, x + 10)
					if bb > a:
						draw_rect(Rect2(a, fr.position.y, bb - a, fr.size.y), Color(1, 1, 1, 0.12))
					x += 24
	var rev: float = G.cycle_revenue(i) if not locked else b["rev"] * G.global_mult()
	var rtxt: String = (G.fmt(rev / t) + "/s") if fast else G.fmt(rev)
	S.text_in(self, br, rtxt, 20, S.PAPER, 1, S.f_num, 5, S.INK)
	# riga info sotto la barra
	var y := br.end.y + 22
	if locked:
		S.text(self, Vector2(118, y), b["desc"], 14, Color(S.INK, 0.7), 0, S.f_body, 0, S.INK, br.size.x)
	else:
		var tl: float = t * (1.0 - G.progress[i]) if G.running[i] else t
		var ttxt := "Continuo" if fast else G.fmt_time(tl)
		if can_click:
			ttxt = "Clicca l'emblema!"
		S.text(self, Vector2(118, y), ttxt, 15, S.RED if can_click else S.INK, 0, S.f_num)
		var nm := G.next_milestone(i)
		var mtxt := "%d/%d " % [o, nm] + ("vel. x2" if nm <= 400 else "profitto x2")
		S.text(self, Vector2(br.end.x, y), mtxt, 14, Color(S.INK, 0.65), 2, S.f_body)
		# mini barra traguardo
		var prev := 0
		for m in G.SPEED_MILESTONES:
			if m <= o:
				prev = m
		if o >= 400:
			prev = int(floor(o / 100.0)) * 100
		var mk := clampf(float(o - prev) / float(maxi(1, nm - prev)), 0, 1)
		var mr := Rect2(br.position.x + 130, y - 9, br.size.x - 130 - S.f_body.get_string_size(mtxt, 0, -1, 14).x - 10, 6)
		if mr.size.x > 20:
			S.draw_round_rect(self, mr, Color(S.INK, 0.15), 3)
			S.draw_round_rect(self, Rect2(mr.position, Vector2(mr.size.x * mk, mr.size.y)), S.GOLD_DARK, 3)
