extends Control
## Pannello "La Fuga": resetta l'impero per incassare Quadrifogli d'Oro (+% globale)
## e spenderli in Talismani permanenti (come gli Angeli di AdCap).

class TalRow extends Control:
	var id := ""
	var btn: Button
	func setup(p_id: String) -> void:
		id = p_id
		custom_minimum_size = Vector2(360, 88)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn = S.make_button("COMPRA", S.GREEN, 16)
		add_child(btn)
		btn.pressed.connect(func(): G.buy_talisman(id))
		resized.connect(_layout)
	func _layout() -> void:
		btn.position = Vector2(size.x - 148, 16)
		btn.size = Vector2(132, size.y - 38)
	func _process(_d: float) -> void:
		var d := G.tal_def(id)
		var lvl := G.tal(id)
		var maxed: bool = lvl >= d["max"]
		var c := G.tal_cost(id)
		btn.text = "MAX" if maxed else ("POTENZIA\n%s Q." % G.num(c))
		btn.disabled = maxed or G.clovers < c
		queue_redraw()
	func _draw() -> void:
		var d := G.tal_def(id)
		var lvl := G.tal(id)
		var r := Rect2(Vector2(4, 2), size - Vector2(14, 12))
		S.draw_card(self, r, S.PAPER, 13, Vector2(5, 6))
		var ic := Vector2(42, r.get_center().y)
		S.draw_chip(self, ic, 28, S.GREEN)
		S.draw_symbol(self, "clover", ic, 28)
		S.text(self, Vector2(82, 28), "%s  (Lv %d/%d)" % [d["name"], lvl, d["max"]], 18, S.INK, 0, S.f_title)
		S.text(self, Vector2(82, 48), d["desc"], 13, Color(S.INK, 0.7), 0, S.f_body)
		S.text(self, Vector2(82, 68), G.tal_effect_text(id, lvl), 15, S.RED_DARK, 0, S.f_num)

var fx: Control
var flee_btn: Button
var _sc: ScrollContainer

func setup(p_fx: Control) -> void:
	fx = p_fx
	flee_btn = S.make_button("CAMBIA IDENTITÀ E SCAPPA!", S.RED, 22, S.PAPER)
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
	flee_btn.position = Vector2(size.x - 420, 96)
	flee_btn.size = Vector2(380, 74)
	_sc.position = Vector2(20, 212)
	_sc.size = size - Vector2(40, 220)

func _on_flee() -> void:
	var gain := G.clovers_claimable()
	if gain < 1:
		return
	Sfx.play("jackpot")
	G.prestige()
	if fx:
		fx.banner("NUOVA IDENTITÀ!", "+%s Quadrifogli d'Oro" % G.num(gain), S.GREEN)
		fx.confetti(size * 0.5, 100)

func _process(_d: float) -> void:
	var gain := G.clovers_claimable()
	flee_btn.disabled = gain < 1
	flee_btn.text = ("SCAPPA CON +%s QUADRIFOGLI!" % G.num(gain)) if gain >= 1 else "Serve almeno €1M guadagnato per scappare"
	queue_redraw()

func _draw() -> void:
	var top := Rect2(22, 10, size.x - 44, 174)
	S.draw_card(self, top, S.PAPER, 16, Vector2(6, 7))
	S.draw_symbol(self, "clover", Vector2(76, 97), 78)
	S.text(self, Vector2(132, 46), "LA FUGA COL BOTTINO (Prestigio)", 28, S.INK, 0, S.f_title)
	S.text(self, Vector2(132, 74), "Baffi finti, passaporto nuovo: ricominci le attività, ma TIENI il progresso sul debito e incassi Quadrifogli!", 15, Color(S.INK, 0.75), 0, S.f_body)
	var eff := int(round(G.clover_eff() * 100))
	S.text(self, Vector2(132, 114), "Quadrifogli attivi: %s   (+%d%% l'uno = x%s a TUTTO)" % [G.num(G.clovers), eff, G.num(G.clover_mult())], 21, S.GREEN.darkened(0.25), 0, S.f_num)
	var gain := G.clovers_claimable()
	S.text(self, Vector2(132, 148), "Pronti da riscuotere se scappi ora: +%s" % G.num(gain), 22, S.RED if gain >= 1 else S.GREY, 0, S.f_title)
	S.text(self, Vector2(26, 204), "BOTTEGA DEI TALISMANI (attenzione: spende Quadrifogli attivi!)", 18, S.GOLD, 0, S.f_title, 5, S.INK)
