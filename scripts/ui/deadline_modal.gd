extends Control
## Modale di Fine Scadenza (stile CloverPit):
## - Se hai pagato la quota: mostra Ticket vinti (base + giorni risparmiati + surplus)
##   e ti permette di spendere subito i Ticket in 3 Amuleti prima della prossima Scadenza!
## - Se il tempo è scaduto (GAME OVER della Run): lo Squalo ti pignora la bisca,
##   ma incassi i Ticket di consolazione e riparti con i Talismani permanenti potenziati!

signal closed_for_shop

var _won := true
var _info := {}
var buy_btns: Array[Button] = []
var reroll_btn: Button
var next_btn: Button
var shop_btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	for i in 3:
		var b := S.make_button("COMPRA", S.GOLD, 16)
		add_child(b)
		var idx := i
		b.pressed.connect(func(): _buy_offer(idx))
		buy_btns.append(b)
	reroll_btn = S.make_button("CAMBIA (1 Ticket)", S.TEAL, 16, S.PAPER)
	add_child(reroll_btn)
	reroll_btn.pressed.connect(func(): G.reroll_shop())
	shop_btn = S.make_button("VAI AI TALISMANI PERMANENTI", S.PURPLE, 16, S.PAPER)
	add_child(shop_btn)
	shop_btn.pressed.connect(_go_to_shop)
	next_btn = S.make_button("PROSSIMA SCADENZA!", S.GREEN, 20)
	add_child(next_btn)
	next_btn.pressed.connect(_continue)
	resized.connect(_layout)

func _eff_size() -> Vector2:
	if size.x > 100 and size.y > 100:
		return size
	var vp := get_viewport_rect().size
	return vp if vp.x > 100 else Vector2(1280, 720)

func open_modal(won: bool, info: Dictionary) -> void:
	_won = won
	_info = info
	visible = true
	_layout()
	queue_redraw()

func _buy_offer(idx: int) -> void:
	if idx < G.shop_offers.size():
		G.buy_charm(G.shop_offers[idx])
		queue_redraw()

func _go_to_shop() -> void:
	if _won:
		G.advance_to_next_deadline()
	else:
		G.start_new_run(false)
	visible = false
	closed_for_shop.emit()

func _continue() -> void:
	if _won:
		G.advance_to_next_deadline()
	else:
		G.start_new_run(false)
	visible = false

func _layout() -> void:
	var sz := _eff_size()
	var c := sz * 0.5
	var r := Rect2(c - Vector2(420, 265), Vector2(840, 530))
	var cw := (r.size.x - 80) / 3.0
	for i in 3:
		var cx := r.position.x + 28 + i * (cw + 12)
		buy_btns[i].position = Vector2(cx + 16, r.position.y + 394)
		buy_btns[i].size = Vector2(cw - 32, 42)
	reroll_btn.position = Vector2(r.position.x + 28, r.end.y - 68)
	reroll_btn.size = Vector2(210, 48)
	shop_btn.position = Vector2(r.position.x + 250, r.end.y - 68)
	shop_btn.size = Vector2(280, 48)
	next_btn.position = Vector2(r.end.x - 288, r.end.y - 68)
	next_btn.size = Vector2(260, 48)

func _process(_d: float) -> void:
	if not visible:
		return
	_layout()
	for i in 3:
		if i < G.shop_offers.size():
			var cd := G.charm_def(G.shop_offers[i])
			buy_btns[i].visible = true
			buy_btns[i].text = "PRENDI (%d Ticket)" % int(cd["cost"])
			buy_btns[i].disabled = G.tickets < int(cd["cost"]) or G.equipped_charms.size() >= G.max_charms()
		else:
			buy_btns[i].visible = false
	reroll_btn.disabled = G.tickets < 1
	next_btn.text = "SCADENZA #%d ->" % (G.deadline_idx + 2) if _won else "NUOVA RUN! (Riprova)"
	S.button_styles(next_btn, S.GREEN if _won else S.RED, S.INK if _won else S.PAPER)
	queue_redraw()

func _draw() -> void:
	var sz := _eff_size()
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.82))
	var c := sz * 0.5
	var r := Rect2(c - Vector2(420, 265), Vector2(840, 530))
	S.draw_card(self, r, S.PAPER, 20, Vector2(10, 14), 4, S.GOLD if _won else S.RED)
	# Intestazione
	var hdr := Rect2(r.position + Vector2(20, 16), Vector2(r.size.x - 40, 86))
	S.draw_card(self, hdr, S.GREEN.darkened(0.2) if _won else S.RED_DARK, 14, Vector2(0, 4), 3)
	S.draw_shark(self, Vector2(hdr.position.x + 48, hdr.get_center().y), 68)
	if _won:
		S.text(self, Vector2(hdr.position.x + 98, hdr.position.y + 38), "SCADENZA SALDATA! LO SQUALO È SODDISFATTO", 28, S.GOLD, 0, S.f_title, 5, S.INK)
		var sub := "Hai versato %s a %s! Surplus: %s  |  Giorni risparmiati: %d" % [
			G.fmt(_info.get("quota", 0.0)), _info.get("boss", ""), G.fmt(_info.get("surplus", 0.0)), int(_info.get("days_saved", 0))
		]
		S.text(self, Vector2(hdr.position.x + 98, hdr.position.y + 68), sub, 15, S.PAPER, 0, S.f_num, 3, S.INK)
	else:
		S.text(self, Vector2(hdr.position.x + 98, hdr.position.y + 38), "TEMPO SCADUTO! LO SQUALO TI HA PIGNORATO TUTTO!", 26, S.GOLD, 0, S.f_title, 5, S.INK)
		var sub := "Dovevi %s a %s (versato %s). La bisca chiude, ma TIENI Ticket e Talismani!" % [
			G.fmt(_info.get("quota", 0.0)), _info.get("boss", ""), G.fmt(_info.get("paid", 0.0))
		]
		S.text(self, Vector2(hdr.position.x + 98, hdr.position.y + 68), sub, 15, S.PAPER, 0, S.f_num, 3, S.INK)

	# Fascia Ticket guadagnati
	var tr := Rect2(r.position + Vector2(28, 114), Vector2(r.size.x - 56, 52))
	S.draw_card(self, tr, S.GOLD, 12, Vector2(0, 3), 3)
	var t_gain := int(_info.get("tickets", 3))
	var t_msg := "+%d TICKET D'ORO OTTENUTI!   (Totale in tasca: %d Ticket)" % [t_gain, G.tickets]
	S.text_in(self, tr, t_msg, 22, S.INK, 1, S.f_title)

	# 3 Carte Amuleto della Vetrinetta
	S.text(self, Vector2(r.get_center().x, r.position.y + 192), "MERCATO NERO DEGLI AMULETI — Equipaggia subito per potenziare la Run (%d/%d slot)" % [G.equipped_charms.size(), G.max_charms()], 17, S.INK, 1, S.f_title)
	var cw := (r.size.x - 80) / 3.0
	for i in 3:
		var cr := Rect2(r.position.x + 28 + i * (cw + 12), r.position.y + 204, cw, 242)
		S.draw_card(self, cr, S.PAPER_DARK if i >= G.shop_offers.size() else S.PAPER, 14, Vector2(4, 5), 3)
		if i < G.shop_offers.size():
			var cd := G.charm_def(G.shop_offers[i])
			var badge := Rect2(cr.position.x + 14, cr.position.y + 12, cr.size.x - 28, 26)
			S.draw_round_rect(self, badge, cd["col"], 7)
			S.text_in(self, badge, cd["rarity"].to_upper(), 13, S.PAPER, 1, S.f_title, 3, S.INK)
			var ic := Vector2(cr.get_center().x, cr.position.y + 74)
			S.draw_chip(self, ic, 28, cd["col"])
			S.draw_symbol(self, cd["sym"], ic, 30)
			S.text(self, Vector2(cr.get_center().x, cr.position.y + 124), cd["name"], 18, S.INK, 1, S.f_title, 0, S.INK, cr.size.x - 20)
			# descrizione su 2 righe
			var lines := _wrap(cd["desc"], cr.size.x - 28, 14)
			for li in lines.size():
				S.text(self, Vector2(cr.get_center().x, cr.position.y + 148 + li * 18), lines[li], 14, Color(S.INK, 0.8), 1, S.f_body)
		else:
			S.text_in(self, cr, "ACQUISTATO!", 22, S.GREEN.darkened(0.3), 1, S.f_title)

func _wrap(s: String, max_w: float, sz: int) -> Array:
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
