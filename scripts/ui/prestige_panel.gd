extends Control
## Pannello "Bottega" (ex La Fuga):
## - Mercato Nero degli Amuleti della Run (3 offerte + Cambia + clicca un amuleto equipaggiato per venderlo)
## - Bottega dei Talismani Permanenti (si comprano coi Ticket d'Oro e restano per sempre, anche se muori!)
## - Bottone "Incassa Ticket e Nuova Run" (soft reset volontario se vuoi ricominciare più forte).

class TalRow extends Control:
	var id := ""
	var btn: Button
	func setup(p_id: String) -> void:
		id = p_id
		custom_minimum_size = Vector2(360, 82)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn = S.make_button("POTENZIA", S.GOLD, 15)
		add_child(btn)
		btn.pressed.connect(func(): G.buy_talisman(id))
		resized.connect(_layout)
	func _layout() -> void:
		btn.position = Vector2(size.x - 144, 14)
		btn.size = Vector2(128, size.y - 34)
	func _process(_d: float) -> void:
		var d := G.tal_def(id)
		var lvl := G.tal(id)
		var maxed: bool = lvl >= d["max"]
		var c := G.tal_cost(id)
		btn.text = "MAX" if maxed else ("POTENZIA\n%d Ticket" % c)
		btn.disabled = maxed or G.tickets < c
		queue_redraw()
	func _draw() -> void:
		var d := G.tal_def(id)
		var lvl := G.tal(id)
		var r := Rect2(Vector2(4, 2), size - Vector2(14, 10))
		S.draw_card(self, r, S.PAPER, 13, Vector2(4, 5))
		var ic := Vector2(40, r.get_center().y)
		S.draw_chip(self, ic, 26, S.GOLD)
		S.draw_symbol(self, "clover", ic, 26)
		S.text(self, Vector2(78, 26), "%s  (Lv %d/%d)" % [d["name"], lvl, d["max"]], 17, S.INK, 0, S.f_title)
		S.text(self, Vector2(78, 45), d["desc"], 13, Color(S.INK, 0.72), 0, S.f_body, 0, S.INK, size.x - 235)
		S.text(self, Vector2(78, 64), G.tal_effect_text(id, lvl), 14, S.RED_DARK, 0, S.f_num)

var fx: Control
var offer_btns: Array[Button] = []
var reroll_btn: Button
var flee_btn: Button
var _sc: ScrollContainer

func setup(p_fx: Control) -> void:
	fx = p_fx
	for i in 3:
		var b := S.make_button("COMPRA", S.GOLD, 15)
		add_child(b)
		var idx := i
		b.pressed.connect(func():
			if idx < G.shop_offers.size():
				G.buy_charm(G.shop_offers[idx]))
		offer_btns.append(b)
	reroll_btn = S.make_button("CAMBIA MERCE\n(1 Ticket)", S.TEAL, 14, S.PAPER)
	add_child(reroll_btn)
	reroll_btn.pressed.connect(func(): G.reroll_shop())
	flee_btn = S.make_button("NUOVA RUN\n(Soft Reset)", S.RED, 15, S.PAPER)
	add_child(flee_btn)
	flee_btn.pressed.connect(_on_flee)
	_sc = ScrollContainer.new()
	_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_sc)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	_sc.add_child(grid)
	for t in G.TALISMANS:
		var r := TalRow.new()
		grid.add_child(r)
		r.setup(t["id"])
	resized.connect(_layout)

func _layout() -> void:
	var w := size.x - 40
	var card_w := (w - 310) / 3.0
	for i in 3:
		var cx := 26 + i * (card_w + 10)
		offer_btns[i].position = Vector2(cx + card_w - 118, 118)
		offer_btns[i].size = Vector2(108, 42)
	reroll_btn.position = Vector2(size.x - 280, 18)
	reroll_btn.size = Vector2(126, 66)
	flee_btn.position = Vector2(size.x - 146, 18)
	flee_btn.size = Vector2(126, 66)
	_sc.position = Vector2(20, 210)
	_sc.size = size - Vector2(40, 216)

func _eq_slot_rect(idx: int) -> Rect2:
	return Rect2(size.x - 280 + idx * 38, 122, 34, 34)

func _gui_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		for idx in G.equipped_charms.size():
			if _eq_slot_rect(idx).has_point(mb.position):
				G.sell_charm(idx)
				return

func _on_flee() -> void:
	var bonus_t := maxi(1, int(floor(log(maxf(1.0, G.run_earned)) / log(10.0))) - 2)
	G.tickets += bonus_t
	G.total_tickets_earned += bonus_t
	G.clovers += 1.0
	Sfx.play("jackpot")
	G.start_new_run(false)
	if fx:
		fx.banner("NUOVA RUN!", "+%d Ticket & +1 Quadrifoglio!" % bonus_t, S.GOLD)
		fx.confetti(size * 0.5, 90)

func _process(_d: float) -> void:
	for i in 3:
		if i < G.shop_offers.size():
			var cd := G.charm_def(G.shop_offers[i])
			offer_btns[i].visible = true
			offer_btns[i].text = "PRENDI\n%d Ticket" % int(cd["cost"])
			offer_btns[i].disabled = G.tickets < int(cd["cost"]) or G.equipped_charms.size() >= G.max_charms()
		else:
			offer_btns[i].visible = false
	reroll_btn.disabled = G.tickets < 1
	var bonus_t := maxi(1, int(floor(log(maxf(1.0, G.run_earned)) / log(10.0))) - 2)
	flee_btn.text = "FUGGI ORA\n(+%d Ticket)" % bonus_t
	flee_btn.disabled = G.run_earned < 500.0
	queue_redraw()

func _draw() -> void:
	var w := size.x - 40
	var card_w := (w - 310) / 3.0
	for i in 3:
		var cr := Rect2(22 + i * (card_w + 10), 12, card_w, 158)
		S.draw_card(self, cr, S.PAPER if i < G.shop_offers.size() else S.PAPER_DARK, 14, Vector2(5, 6))
		if i < G.shop_offers.size():
			var cd := G.charm_def(G.shop_offers[i])
			var ic := Vector2(cr.position.x + 36, cr.position.y + 44)
			S.draw_chip(self, ic, 24, cd["col"])
			S.draw_symbol(self, cd["sym"], ic, 24)
			S.text(self, Vector2(cr.position.x + 70, cr.position.y + 34), cd["name"], 17, S.INK, 0, S.f_title, 0, S.INK, cr.size.x - 80)
			S.text(self, Vector2(cr.position.x + 70, cr.position.y + 54), "Amuleto " + cd["rarity"], 13, cd["col"].darkened(0.2), 0, S.f_num)
			var dlines := _wrap_str(cd["desc"], cr.size.x - 24, 13)
			for li in mini(2, dlines.size()):
				S.text(self, Vector2(cr.position.x + 14, cr.position.y + 82 + li * 17), dlines[li], 13, Color(S.INK, 0.82), 0, S.f_body)
			S.text(self, Vector2(cr.position.x + 14, cr.position.y + 142), "Costo: %d Ticket" % int(cd["cost"]), 16, S.RED_DARK, 0, S.f_title)
		else:
			S.text_in(self, cr, "PRESA!", 20, S.GREEN.darkened(0.3), 1, S.f_title)

	# Box vetrinetta a destra
	var vr := Rect2(size.x - 284, 92, 264, 78)
	S.draw_card(self, vr, S.PAPER, 12, Vector2(4, 5))
	S.text(self, Vector2(vr.position.x + 10, vr.position.y + 20), "VETRINETTA (clicca per vendere):", 12, S.INK, 0, S.f_title)
	for idx in G.max_charms():
		var sr := _eq_slot_rect(idx)
		if idx < G.equipped_charms.size():
			var cd := G.charm_def(G.equipped_charms[idx])
			S.draw_card(self, sr, cd["col"], 7, Vector2(1, 2), 2)
			S.draw_symbol(self, cd["sym"], sr.get_center(), 20)
		else:
			S.draw_round_rect(self, sr, S.PAPER_DARK, 7)
			draw_rect(sr, Color(S.INK, 0.25), false, 2)

	var htxt := "TALISMANI PERMANENTI (si comprano coi Ticket, NON si perdono mai!)  —  Ticket: %d  |  Record Scadenza: #%d" % [G.tickets, G.best_deadline]
	S.text(self, Vector2(24, 200), htxt, 17, S.GOLD, 0, S.f_title, 5, S.INK)

func _wrap_str(s: String, max_w: float, sz: int) -> Array:
	var out := []
	var cur := ""
	for w in s.split(" "):
		var test := w if cur == "" else cur + " " + w
		if S.f_body.get_string_size(test, 0, -1, sz).x > max_w and cur != "":
			out.append(cur)
			cur = w
		else:
			cur = test
	if cur != "":
		out.append(cur)
	return out
