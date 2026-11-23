extends Control
## Pannello "Il Banco" v2: contiene 4 minigiochi (Gratta, Slot, Dadi, Ruota del Destino),
## selettore puntata (x1 / x5 / x25 / ALL-IN), tabella premi e "Raddoppia o Lascia".

const ScratchCard := preload("res://scripts/ui/scratch_card.gd")
const SlotMachine := preload("res://scripts/ui/slot_machine.gd")
const DiceTable := preload("res://scripts/ui/dice_table.gd")
const WheelOfFate := preload("res://scripts/ui/wheel_of_fate.gd")

var fx: Control
var game_tab := 0
var tab_btns: Array[Button] = []
var stake_btns: Array[Button] = []
var scratch: Control
var slot: Control
var dice: Control
var wheel: Control
var action_btn: Button
var reveal_btn: Button
var collect_btn: Button
var double_btn: Button

var pending_win := 0.0
var pending_stake := 0.0
var double_streak := 0
var _coin_anim := 0.0
var _coin_res := false

func setup(p_fx: Control) -> void:
	fx = p_fx
	var tabs := ["GRATTA E VINCI", "SLOT 777", "TAVOLO DADI", "RUOTA DESTINO"]
	var tcols := [S.GOLD, S.RED, S.TEAL, S.PURPLE]
	for i in 4:
		var b := S.make_button(tabs[i], tcols[i], 18, S.INK if i == 0 else S.PAPER)
		add_child(b)
		var idx := i
		b.pressed.connect(func(): _select_game(idx))
		tab_btns.append(b)
	var mults := [1.0, 5.0, 25.0, 9999.0]
	var mlabels := ["x1", "x5", "x25", "ALL-IN"]
	for i in 4:
		var b := S.make_button(mlabels[i], S.PAPER, 15)
		add_child(b)
		var m: float = mults[i]
		b.pressed.connect(_set_stake.bind(m))
		stake_btns.append(b)
	scratch = ScratchCard.new(); add_child(scratch); scratch.finished.connect(_on_scratch_done)
	slot = SlotMachine.new(); add_child(slot); slot.finished.connect(_on_slot_done); slot.lever_clicked.connect(_on_action)
	dice = DiceTable.new(); add_child(dice); dice.finished.connect(_on_dice_done)
	wheel = WheelOfFate.new(); add_child(wheel); wheel.finished.connect(_on_wheel_done); wheel.wheel_clicked.connect(_on_action)
	action_btn = S.make_button("COMPRA", S.GOLD, 20)
	add_child(action_btn); action_btn.pressed.connect(_on_action)
	reveal_btn = S.make_button("GRATTA TUTTO", S.TEAL, 17, S.PAPER)
	add_child(reveal_btn); reveal_btn.pressed.connect(func(): scratch.reveal_all())
	collect_btn = S.make_button("INCASSA", S.GREEN, 19)
	add_child(collect_btn); collect_btn.pressed.connect(_collect_pending)
	double_btn = S.make_button("RADDOPPIA!", S.RED, 19, S.PAPER)
	add_child(double_btn); double_btn.pressed.connect(_try_double)
	G.auto_result.connect(_on_auto)
	resized.connect(_layout)
	_select_game(0)
	_update_stake_styles()

func _layout() -> void:
	for i in 4:
		tab_btns[i].position = Vector2(18 + i * 182, 8)
		tab_btns[i].size = Vector2(174, 42)
	var area := Rect2(18, 58, size.x - 36, size.y - 68)
	var stage_w := area.size.x * 0.58
	for g in [scratch, slot, dice, wheel]:
		g.position = Vector2(area.position.x + 8, area.position.y + 8)
		g.size = Vector2(stage_w - 16, area.size.y - 16)
	var rx := area.position.x + stage_w + 18
	var rw := area.size.x - stage_w - 36
	var bw := (rw - 24) / 4.0
	for i in 4:
		stake_btns[i].position = Vector2(rx + i * (bw + 8), area.position.y + 52)
		stake_btns[i].size = Vector2(bw, 36)
	action_btn.position = Vector2(rx, area.end.y - 74)
	action_btn.size = Vector2(rw if game_tab != 0 else rw * 0.58, 56)
	reveal_btn.position = Vector2(rx + rw * 0.61, area.end.y - 74)
	reveal_btn.size = Vector2(rw * 0.39, 56)
	collect_btn.position = Vector2(rx, area.end.y - 74)
	collect_btn.size = Vector2(rw * 0.48, 56)
	double_btn.position = Vector2(rx + rw * 0.51, area.end.y - 74)
	double_btn.size = Vector2(rw * 0.49, 56)

func _select_game(idx: int) -> void:
	if pending_win > 0:
		_collect_pending()
	game_tab = idx
	scratch.visible = idx == 0
	slot.visible = idx == 1
	dice.visible = idx == 2
	wheel.visible = idx == 3
	var cols := [S.GOLD, S.RED, S.TEAL, S.PURPLE]
	for i in 4:
		var fc := S.INK if i == 0 else S.PAPER
		S.button_styles(tab_btns[i], cols[i] if i == idx else cols[i].darkened(0.42), fc)
	_layout()

func _set_stake(m: float) -> void:
	G.stake_mult = m
	_update_stake_styles()

func _update_stake_styles() -> void:
	var mults := [1.0, 5.0, 25.0, 9999.0]
	for i in 4:
		var sel := is_equal_approx(G.stake_mult, mults[i])
		S.button_styles(stake_btns[i], S.RED if (i == 3 and sel) else (S.GOLD if sel else S.PAPER_DARK), S.PAPER if (i == 3 and sel) else S.INK)

func _busy() -> bool:
	return (game_tab == 0 and scratch.state == "scratching") or (game_tab == 1 and slot.spinning) or (game_tab == 2 and dice.rolling) or (game_tab == 3 and wheel.spinning) or _coin_anim > 0

func _on_action() -> void:
	if pending_win > 0:
		_collect_pending()
	if _busy():
		return
	var st := G.stake()
	if G.money < st or st <= 0:
		Sfx.play("lose")
		return
	G.money -= st
	match game_tab:
		0: scratch.new_ticket(st)
		1: slot.spin(st)
		2: dice.roll(st)
		3: wheel.spin_wheel(st)

func _handle_win(win: float, st: float, mult: float, title := "") -> void:
	if win <= 0:
		Sfx.play("lose")
		if G.has_charm("limone"):
			var refund := st * 0.35
			G.earn(refund)
			fx.popup(global_position + Vector2(size.x * 0.3, size.y * 0.5), "Limone: +" + G.fmt(refund), S.GOLD, 24)
		return
	pending_win = win
	pending_stake = st
	double_streak = 0
	if mult >= 50:
		Sfx.play("jackpot")
		fx.banner(title if title != "" else "JACKPOT!", "+" + G.fmt(win), S.GOLD)
		fx.confetti(global_position + size * 0.5, 90)
	else:
		Sfx.play("win")
		fx.popup(global_position + Vector2(size.x * 0.3, size.y * 0.45), "+" + G.fmt(win), S.GOLD, 38)

func _on_scratch_done(win: float, st: float, mult: float) -> void:
	_handle_win(win, st, mult, "BIGLIETTO D'ORO!")

func _on_slot_done(win: float, st: float, res: Dictionary) -> void:
	var t := "777 JACKPOT!" if res.get("sym", "") == "seven" else "TRIS!"
	_handle_win(win, st, res.get("mult", 0.0), t)

func _on_dice_done(win: float, st: float, mult: float) -> void:
	_handle_win(win, st, mult, "COLPO GROSSO!")

func _on_wheel_done(win: float, st: float, sl: Dictionary) -> void:
	var k: String = sl["kind"]
	if k == "tickets":
		Sfx.play("jackpot")
		fx.banner("+3 TICKET D'ORO!", "Puntata rimborsata!", S.GREEN)
		fx.confetti(global_position + size * 0.5, 80)
		G.earn(win)
		return
	elif k == "frenzy":
		Sfx.play("jackpot")
		fx.banner("FRENESIA x7!", "Tutte le attività x7 per 25s!", S.ORANGE)
		G.earn(win)
		return
	elif k == "shark":
		Sfx.play("lose")
		G.earn(win)
		fx.popup(global_position + Vector2(size.x * 0.3, size.y * 0.45), "Lo Squalo si prende il 50%!", S.RED, 28)
		return
	_handle_win(win, st, float(sl["val"]) * (20.0 if float(sl["val"]) >= 8.0 else 1.0), sl["label"])

func _collect_pending() -> void:
	if pending_win <= 0:
		return
	var w := pending_win
	pending_win = 0.0
	G.earn(w)
	G.register_win(w, pending_stake)
	Sfx.play("cash")
	fx.coins(collect_btn.global_position + collect_btn.size * 0.5, clampi(int(log(maxf(10.0, w / maxf(1.0, pending_stake))) * 3.0), 4, 22))
	fx.popup(collect_btn.global_position + Vector2(50, -10), "+" + G.fmt(w), S.GREEN, 32)

func _try_double() -> void:
	if pending_win <= 0 or _coin_anim > 0:
		return
	_coin_anim = 0.50
	_coin_res = randf() < G.double_chance()
	Sfx.play("coin", 1.3)

func _finish_double() -> void:
	if _coin_res:
		pending_win *= 2.0
		double_streak += 1
		if double_streak > G.stats["best_double"]:
			G.stats["best_double"] = double_streak
		if double_streak >= 10:
			fx.banner("RADDOPPIO x10!", "Il banco suda freddo!", S.GOLD)
			_collect_pending()
			return
		Sfx.play("win", 1.0 + double_streak * 0.08)
		fx.popup(double_btn.global_position + Vector2(60, -20), "RADDOPPIATO! " + G.fmt(pending_win), S.GOLD, 30)
	else:
		if G.has_charm("teschio") and randf() < 0.35:
			Sfx.play("jackpot")
			fx.popup(double_btn.global_position + Vector2(60, -20), "TESCHIO DEL BARO: SALVATO!", S.PURPLE, 26)
			return
		pending_win = 0.0
		double_streak = 0
		Sfx.play("lose")
		fx.popup(double_btn.global_position + Vector2(60, -20), "PERSO TUTTO!", S.RED, 30)

func _on_auto(kind: String, net: float) -> void:
	if not is_visible_in_tree():
		return
	if net > 0:
		fx.popup(global_position + Vector2(140, 90), "Auto-%s +%s" % [kind, G.fmt(net)], S.TEAL, 18)

func _process(delta: float) -> void:
	if _coin_anim > 0:
		_coin_anim -= delta
		if _coin_anim <= 0:
			_finish_double()
	var st := G.stake()
	var has_pending := pending_win > 0
	collect_btn.visible = has_pending
	double_btn.visible = has_pending
	action_btn.visible = not has_pending
	reveal_btn.visible = not has_pending and game_tab == 0
	if has_pending:
		collect_btn.text = "INCASSA\n" + G.fmt(pending_win)
		double_btn.text = "RADDOPPIA (%d%%)\n-> %s" % [int(G.double_chance() * 100), G.fmt(pending_win * 2.0)]
		double_btn.disabled = _coin_anim > 0
	else:
		var verbs := ["COMPRA BIGLIETTO", "GIRA LA SLOT", "LANCIA I DADI", "GIRA LA RUOTA!"]
		action_btn.text = "%s\n%s" % [verbs[game_tab], G.fmt(st)]
		action_btn.disabled = G.money < st or st <= 0 or _busy()
		reveal_btn.disabled = scratch.state != "scratching"
	queue_redraw()

func _draw() -> void:
	var area := Rect2(18, 58, size.x - 36, size.y - 68)
	var stage_w := area.size.x * 0.58
	var rx := area.position.x + stage_w + 18
	var rw := area.size.x - stage_w - 36
	var pr := Rect2(rx - 10, area.position.y + 8, rw + 20, area.size.y - 16)
	S.draw_card(self, pr, S.PAPER, 16, Vector2(6, 7))
	S.text(self, Vector2(rx + 4, area.position.y + 38), "PUNTATA: " + G.fmt(G.stake()), 22, S.INK, 0, S.f_title)
	var mult_str := "Fortuna +%d   Vincite x%s" % [G.luck(), G.num(G.game_mult())]
	S.text(self, Vector2(rx + rw, area.position.y + 38), mult_str, 14, S.RED, 2, S.f_num)
	var box := Rect2(rx, area.position.y + 98, rw, area.size.y - 186)
	S.draw_round_rect(self, box, S.PAPER_DARK, 12)
	draw_rect(box, Color(S.INK, 0.25), false, 2)
	if pending_win > 0:
		_draw_double_box(box)
	else:
		_draw_paytable(box)

func _draw_double_box(b: Rect2) -> void:
	S.text(self, Vector2(b.get_center().x, b.position.y + 34), "RADDOPPIA O LASCIA!", 26, S.RED, 1, S.f_title)
	S.text(self, Vector2(b.get_center().x, b.position.y + 62), "Vincita attuale: " + G.fmt(pending_win), 20, S.INK, 1, S.f_num)
	var c := Vector2(b.get_center().x, b.get_center().y + 12)
	var sx := cos(_coin_anim * 28.0) if _coin_anim > 0 else 1.0
	draw_set_transform(c, 0, Vector2(sx, 1))
	draw_circle(Vector2(3, 5), 48, S.SHADOW)
	draw_circle(Vector2.ZERO, 48, S.GOLD)
	S.circle_outline(self, Vector2.ZERO, 48, S.INK, 3.5)
	S.circle_outline(self, Vector2.ZERO, 36, S.GOLD_DARK, 2)
	S.text(self, Vector2(0, 18), "x2", 42, S.INK, 1, S.f_title)
	draw_set_transform(Vector2.ZERO)
	S.text(self, Vector2(b.get_center().x, b.end.y - 16), "Serie attuale: %d  (record: %d)" % [double_streak, G.stats["best_double"]], 15, Color(S.INK, 0.7), 1, S.f_body)

func _draw_paytable(b: Rect2) -> void:
	S.text(self, Vector2(b.get_center().x, b.position.y + 26), "TABELLA PREMI", 20, S.INK, 1, S.f_title)
	var gm := G.game_mult()
	if game_tab == 0:
		var y := b.position.y + 52
		var h := (b.size.y - 60) / 7.0
		var zm := 1.5 if G.has_charm("zampa") else 1.0
		for i in G.SCRATCH_PRIZES.size():
			var p: Dictionary = G.SCRATCH_PRIZES[G.SCRATCH_PRIZES.size() - 1 - i]
			var cy := y + i * h
			for k in 3:
				S.draw_symbol(self, p["sym"], Vector2(b.position.x + 24 + k * 24, cy), 22)
			S.text(self, Vector2(b.position.x + 102, cy + 6), S.SYMBOL_NAMES[p["sym"]], 15, S.INK, 0, S.f_body)
			S.text(self, Vector2(b.end.x - 16, cy + 6), G.fmt(p["mult"] * zm * G.stake() * gm), 17, S.RED if p["mult"] >= 50 else S.INK, 2, S.f_num)
	elif game_tab == 1:
		var syms := ["seven", "diamond", "horseshoe", "clover", "bell", "lemon", "cherry"]
		var y := b.position.y + 48
		var h := (b.size.y - 72) / 7.0
		for i in syms.size():
			var s: String = syms[i]
			var cy := y + i * h
			for k in 3:
				S.draw_symbol(self, s, Vector2(b.position.x + 24 + k * 24, cy), 22)
			S.text(self, Vector2(b.position.x + 102, cy + 6), "Tris " + S.SYMBOL_NAMES[s], 14, S.INK, 0, S.f_body)
			S.text(self, Vector2(b.end.x - 16, cy + 6), G.fmt(G.SLOT_PAY[s] * G.stake() * gm), 17, S.RED if G.SLOT_PAY[s] >= 100 else S.INK, 2, S.f_num)
		S.text(self, Vector2(b.get_center().x, b.end.y - 10), "Qualsiasi coppia paga " + G.fmt(2.5 * G.stake() * gm), 14, Color(S.INK, 0.75), 1, S.f_num)
	elif game_tab == 2:
		var dm := 4.0 if G.has_charm("dado_piombo") else 2.0
		var lines := [
			["Sotto 7 (2-6)", 2.5],
			["Sopra 7 (8-12)", 2.5],
			["Sotto/Sopra + Doppi", 2.5 * dm],
			["Sette esatto (7)", 6.0],
		]
		for i in lines.size():
			var cy := b.position.y + 62 + i * 38
			S.text(self, Vector2(b.position.x + 18, cy), lines[i][0], 16, S.INK, 0, S.f_body)
			S.text(self, Vector2(b.end.x - 18, cy), G.fmt(lines[i][1] * G.stake() * gm), 18, S.RED if i == 3 else S.INK, 2, S.f_num)
		S.text(self, Vector2(b.get_center().x, b.end.y - 18), "Dado Piombato + Fortuna aiutano sui lanci sfortunati!", 13, Color(S.INK, 0.7), 1, S.f_body)
	else:
		var wlines := [
			["JACKPOT x8", G.fmt(8.0 * G.stake() * gm)],
			["TRIPLICA x3", G.fmt(3.0 * G.stake() * gm)],
			["RADDOPPIA x2", G.fmt(2.0 * G.stake() * gm)],
			["+3 TICKET D'ORO", "+3 Ticket + Rimborso"],
			["FRENESIA x7", "Attività x7 (25s) + 1.5x"],
			["TESCHIO / SQUALO", "Perdi o Dimezzi!"],
		]
		for i in wlines.size():
			var cy := b.position.y + 54 + i * 30
			S.text(self, Vector2(b.position.x + 16, cy), wlines[i][0], 15, S.INK, 0, S.f_title)
			S.text(self, Vector2(b.end.x - 16, cy), wlines[i][1], 15, S.RED if i == 0 else S.INK, 2, S.f_num)
