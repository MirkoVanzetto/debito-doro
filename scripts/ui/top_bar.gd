extends Control
## Barra superiore: soldi, entrate/s, quadrifogli, buff attivi, e lo Squalo con barra del debito.

var fx: Control
var pay_btn: Button
var money_anchor: Control
var _bump := 0.0

func setup(p_fx: Control) -> void:
	fx = p_fx
	custom_minimum_size = Vector2(0, 92)
	pay_btn = S.make_button("PAGA", S.RED, 16, S.PAPER)
	add_child(pay_btn)
	pay_btn.pressed.connect(_on_pay)
	money_anchor = Control.new()
	money_anchor.position = Vector2(56, 46)
	add_child(money_anchor)
	fx.target = money_anchor
	fx.coin_arrived.connect(func(): _bump = 1.0)
	resized.connect(_layout)

func _layout() -> void:
	pay_btn.position = Vector2(size.x - 166, 20)
	pay_btn.size = Vector2(142, 52)

func _on_pay() -> void:
	var p := G.pay_debt()
	if p > 0 and fx:
		fx.popup(pay_btn.global_position + Vector2(60, 0), "-" + G.fmt(p), S.RED, 22)

func _process(delta: float) -> void:
	_bump = maxf(0.0, _bump - delta * 6.0)
	var pay := minf(G.money, G.debt_left())
	pay_btn.disabled = pay < 1.0
	pay_btn.text = "PAGA DEBITO\n" + (G.fmt(pay) if pay >= 1.0 else "€0")
	queue_redraw()

func _draw() -> void:
	# cartellino portafoglio (sinistra)
	var wl := Rect2(20, 12, 340, 70)
	S.draw_card(self, wl, S.PAPER, 16, Vector2(6, 7))
	var sc := 1.0 + 0.14 * _bump
	draw_set_transform(Vector2(54, 47), 0, Vector2(sc, sc))
	S.draw_chip(self, Vector2.ZERO, 24, S.GOLD, false)
	S.text_in(self, Rect2(-24, -24, 48, 48), "€", 26, S.INK, 1, S.f_title)
	draw_set_transform(Vector2.ZERO)
	S.text(self, Vector2(90, 48), G.fmt(G.money), 34, S.INK, 0, S.f_title, 0, S.INK, 256)
	var ips := G.ips_cached()
	S.text(self, Vector2(92, 70), "+%s/sec" % G.fmt(ips), 16, S.GREEN.darkened(0.35), 0, S.f_num)
	# cartellino quadrifogli / buff (centro)
	var cl := Rect2(372, 12, 230, 70)
	S.draw_card(self, cl, S.PAPER, 16, Vector2(6, 7))
	S.draw_symbol(self, "clover", Vector2(404, 47), 40)
	S.text(self, Vector2(434, 44), "%s Q." % G.num(G.clovers), 22, S.INK, 0, S.f_title)
	S.text(self, Vector2(434, 68), "Bonus x%s" % G.num(G.global_mult()), 15, S.RED_DARK, 0, S.f_num)
	# barra del debito dello Squalo (destra)
	var dr := Rect2(614, 12, size.x - 634, 70)
	S.draw_card(self, dr, S.PAPER, 16, Vector2(6, 7))
	S.draw_shark(self, Vector2(dr.position.x + 38, dr.get_center().y), 58)
	var cd := G.city_data()
	var tot: float = cd["debt"]
	var k := clampf(G.debt_paid / tot, 0.0, 1.0)
	var bx := dr.position.x + 74
	var bw := dr.size.x - 74 - 166
	S.text(self, Vector2(bx, 34), "%s (%s)" % [cd["boss"], cd["name"]], 17, S.INK, 0, S.f_title, 0, S.INK, bw)
	var br := Rect2(bx, 42, bw, 28)
	S.draw_card(self, br, Color("2a2230"), 8, Vector2(0, 2), 2.5)
	if k > 0:
		var fr := Rect2(br.position + Vector2(3, 3), Vector2((br.size.x - 6) * k, br.size.y - 6))
		if fr.size.x > 4:
			S.draw_round_rect(self, fr, S.RED, 6)
	S.text_in(self, br, "Debito: %s / %s  (%d%%)" % [G.fmt(G.debt_paid), G.fmt(tot), int(k * 100)], 14, S.PAPER, 1, S.f_num, 4, S.INK)
	# banner buff attivi
	var buff := ""
	if G.frenzy_time > 0:
		buff += "FRENESIA x7 (%ds)  " % int(ceil(G.frenzy_time))
	if G.luckboost_time > 0:
		buff += "FORTUNA x5 (%ds)" % int(ceil(G.luckboost_time))
	if buff != "":
		var wr := Rect2(size.x * 0.5 - 180, 84, 360, 24)
		S.draw_card(self, wr, S.GOLD, 8, Vector2(2, 3), 2)
		S.text_in(self, wr, buff.strip_edges(), 14, S.INK, 1, S.f_title)
