extends Control
## Barra superiore v2: Portafoglio, Ticket d'Oro, Vetrinetta Amuleti,
## Scadenza dello Squalo con Timer dei Giorni e pulsante PAGA QUOTA!

var fx: Control
var pay_btn: Button
var money_anchor: Control
var _bump := 0.0
var _pulse := 0.0
var _hover_charm := -1

func setup(p_fx: Control) -> void:
	fx = p_fx
	custom_minimum_size = Vector2(0, 96)
	pay_btn = S.make_button("VERSA QUOTA", S.RED, 16, S.PAPER)
	add_child(pay_btn)
	pay_btn.pressed.connect(_on_pay)
	money_anchor = Control.new()
	money_anchor.position = Vector2(56, 46)
	add_child(money_anchor)
	fx.target = money_anchor
	fx.coin_arrived.connect(func(): _bump = 1.0)
	resized.connect(_layout)

func _layout() -> void:
	if size.x > 100 and pay_btn:
		pay_btn.position = Vector2(size.x - 168, 18)
		pay_btn.size = Vector2(146, 56)

func _on_pay() -> void:
	var p := G.pay_debt()
	if p > 0 and fx:
		fx.popup(pay_btn.global_position + Vector2(60, 0), "VERSATO " + G.fmt(p), S.GOLD, 24)

func _charm_slot_rect(idx: int) -> Rect2:
	var x0 := 346.0 + 114.0
	return Rect2(x0 + idx * 32.0, 42.0, 28.0, 28.0)

func _gui_input(e: InputEvent) -> void:
	var mm := e as InputEventMouseMotion
	if mm:
		_hover_charm = -1
		for idx in G.max_charms():
			if _charm_slot_rect(idx).has_point(mm.position):
				_hover_charm = idx

func _process(delta: float) -> void:
	_bump = maxf(0.0, _bump - delta * 6.0)
	_pulse += delta
	var pay := minf(G.money, G.debt_left())
	pay_btn.disabled = pay < 1.0
	var can_finish := G.money >= G.debt_left()
	if can_finish:
		pay_btn.text = "SALDA ORA!\n" + G.fmt(pay)
		S.button_styles(pay_btn, S.GREEN, S.INK)
	else:
		pay_btn.text = "VERSA QUOTA\n" + (G.fmt(pay) if pay >= 1.0 else "€0")
		S.button_styles(pay_btn, S.RED, S.PAPER)
	queue_redraw()

func _draw() -> void:
	# 1. Cartellino Portafoglio (sinistra)
	var wl := Rect2(18, 10, 318, 74)
	S.draw_card(self, wl, S.PAPER, 16, Vector2(5, 6))
	var sc := 1.0 + 0.14 * _bump
	draw_set_transform(Vector2(52, 47), 0, Vector2(sc, sc))
	S.draw_chip(self, Vector2.ZERO, 24, S.GOLD, false)
	S.text_in(self, Rect2(-24, -24, 48, 48), "€", 26, S.INK, 1, S.f_title)
	draw_set_transform(Vector2.ZERO)
	S.text(self, Vector2(86, 46), G.fmt(G.money), 32, S.INK, 0, S.f_title, 0, S.INK, 238)
	var ips := G.ips_cached()
	S.text(self, Vector2(88, 69), "+%s/sec   (x%s)" % [G.fmt(ips), G.num(G.global_mult())], 15, S.GREEN.darkened(0.35), 0, S.f_num, 0, S.INK, 236)

	# 2. Cartellino Ticket & Vetrinetta Amuleti (centro)
	var cl := Rect2(346, 10, 294, 74)
	S.draw_card(self, cl, S.PAPER, 16, Vector2(5, 6))
	# Ticket dorato
	var tr := Rect2(358, 22, 92, 50)
	S.draw_card(self, tr, S.GOLD, 10, Vector2(2, 3), 2.5)
	S.text(self, Vector2(tr.get_center().x, tr.position.y + 22), "%d" % G.tickets, 24, S.INK, 1, S.f_title)
	S.text(self, Vector2(tr.get_center().x, tr.position.y + 42), "TICKET", 13, S.RED_DARK, 1, S.f_title)
	# Vetrinetta Amuleti della Run
	var max_c := G.max_charms()
	S.text(self, Vector2(460, 32), "AMULETI (%d/%d)" % [G.equipped_charms.size(), max_c], 14, S.INK, 0, S.f_title)
	for idx in max_c:
		var sr := _charm_slot_rect(idx)
		if idx < G.equipped_charms.size():
			var cd := G.charm_def(G.equipped_charms[idx])
			S.draw_card(self, sr, cd["col"], 7, Vector2(1, 2), 2)
			S.draw_symbol(self, cd["sym"], sr.get_center(), 18)
		else:
			S.draw_round_rect(self, sr, S.PAPER_DARK, 7)
			draw_rect(sr, Color(S.INK, 0.3), false, 2)

	# 3. Scadenza dello Squalo + Countdown Giorni (destra)
	var dr := Rect2(650, 10, size.x - 668, 74)
	var urgent := G.day_time_left < 20.0 and G.day_in_deadline >= int(G.deadline_data()["days"])
	var card_col := S.PAPER.lerp(Color("ffd0d0"), 0.5 + 0.5 * sin(_pulse * 10.0)) if urgent else S.PAPER
	S.draw_card(self, dr, card_col, 16, Vector2(5, 6))
	S.draw_shark(self, Vector2(dr.position.x + 36, dr.get_center().y), 56)
	var dd := G.deadline_data()
	var tot: float = dd["quota"]
	var k := clampf(G.debt_paid / maxf(1.0, tot), 0.0, 1.0)
	var bx := dr.position.x + 70
	var bw := dr.size.x - 70 - 166
	var days_tot := int(dd["days"])
	var t_col := S.RED if G.day_time_left < 20.0 else S.INK
	var hdr := "SCADENZA #%d: %s" % [G.deadline_idx + 1, dd["name"]]
	S.text(self, Vector2(bx, 31), hdr, 16, S.INK, 0, S.f_title, 0, S.INK, bw * 0.56)
	var timer_str := "GIORNO %d/%d — %s" % [G.day_in_deadline, days_tot, G.fmt_time(G.day_time_left)]
	S.text(self, Vector2(bx + bw, 31), timer_str, 16, t_col, 2, S.f_title)
	# Barra quota + barra tempo giorno
	var br := Rect2(bx, 38, bw, 28)
	S.draw_card(self, br, Color("2a2230"), 8, Vector2(0, 2), 2.5)
	if k > 0:
		var fr := Rect2(br.position + Vector2(3, 3), Vector2((br.size.x - 6) * k, br.size.y - 6))
		if fr.size.x > 4:
			S.draw_round_rect(self, fr, S.GREEN if k >= 1.0 else S.RED, 6)
	S.text_in(self, br, "Quota: %s / %s  (%d%%)" % [G.fmt(G.debt_paid), G.fmt(tot), int(k * 100)], 14, S.PAPER, 1, S.f_num, 4, S.INK)
	# Sottile barra del tempo del giorno corrente sotto la barra quota
	var tk := clampf(G.day_time_left / G.day_duration(), 0.0, 1.0)
	var tr_bar := Rect2(bx, 70, bw, 6)
	S.draw_round_rect(self, tr_bar, Color(S.INK, 0.2), 3)
	S.draw_round_rect(self, Rect2(bx, 70, bw * tk, 6), S.GOLD if tk > 0.25 else S.RED, 3)

	# Tooltip amuleto in hover
	if _hover_charm >= 0 and _hover_charm < G.equipped_charms.size():
		var cd := G.charm_def(G.equipped_charms[_hover_charm])
		var tip := "%s: %s" % [cd["name"], cd["desc"]]
		var tw := S.f_body.get_string_size(tip, 0, -1, 14).x + 24
		var tip_r := Rect2(clampf(346, 10, size.x - tw - 10), 86, tw, 28)
		S.draw_card(self, tip_r, S.INK, 8, Vector2(2, 3), 2, S.GOLD)
		S.text_in(self, tip_r, tip, 14, S.GOLD, 1, S.f_body)
	else:
		# Banner buff attivi
		var buff := ""
		if G.frenzy_time > 0:
			buff += "FRENESIA x7 (%ds)  " % int(ceil(G.frenzy_time))
		if G.luckboost_time > 0:
			buff += "FORTUNA x5 (%ds)" % int(ceil(G.luckboost_time))
		if buff != "":
			var wr := Rect2(size.x * 0.5 - 180, 86, 360, 24)
			S.draw_card(self, wr, S.GOLD, 8, Vector2(2, 3), 2)
			S.text_in(self, wr, buff.strip_edges(), 14, S.INK, 1, S.f_title)
