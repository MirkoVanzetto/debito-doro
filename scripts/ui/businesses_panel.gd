extends Control
## Pannello "La Sala": griglia 2x5 delle attività + selettore x1/x10/x100/MAX + sinergia.

const BusinessCard := preload("res://scripts/ui/business_card.gd")

var fx: Control
var mode_btns: Array[Button] = []
var soft_reset_btn: Button
var hard_reset_btn: Button
var _confirm_hard := 0.0
var cards: Array[Control] = []
var scroll: ScrollContainer
var grid: GridContainer

func setup(p_fx: Control) -> void:
	fx = p_fx
	soft_reset_btn = S.make_button("NUOVA RUN", S.TEAL, 14, S.PAPER)
	soft_reset_btn.tooltip_text = "Ricomincia la Run con attività da 0, tenendo Ticket e Talismani Permanenti"
	add_child(soft_reset_btn)
	soft_reset_btn.pressed.connect(_on_soft_reset)

	hard_reset_btn = S.make_button("RESET DA 0", S.RED_DARK, 14, S.PAPER)
	hard_reset_btn.tooltip_text = "Cancella TUTTO (attività, soldi, Ticket, Talismani) e riparti da zero assoluto"
	add_child(hard_reset_btn)
	hard_reset_btn.pressed.connect(_on_hard_reset)

	var labels := ["COMPRA x1", "x10", "x100", "MAX"]
	for i in 4:
		var b := S.make_button(labels[i], S.PAPER, 15)
		add_child(b)
		b.pressed.connect(_set_mode.bind(i))
		mode_btns.append(b)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)
	for i in G.BUSINESSES.size():
		var c := BusinessCard.new()
		grid.add_child(c)
		c.setup(i, fx)
		cards.append(c)
	resized.connect(_layout)
	_update_modes()

func _on_soft_reset() -> void:
	G.start_new_run(false)
	if fx:
		fx.banner("NUOVA RUN!", "Attività resettate a 0 — Talismani attivi!", S.TEAL)

func _on_hard_reset() -> void:
	if _confirm_hard <= 0.0:
		_confirm_hard = 4.0
		hard_reset_btn.text = "SICURO? (0)"
		S.button_styles(hard_reset_btn, S.RED, S.PAPER)
		return
	_confirm_hard = 0.0
	hard_reset_btn.text = "RESET DA 0"
	S.button_styles(hard_reset_btn, S.RED_DARK, S.PAPER)
	G.full_reset_to_zero()
	if fx:
		fx.banner("RESET DA ZERO!", "Tutto azzerato — Buona fortuna!", S.RED)

func _set_mode(m: int) -> void:
	G.buy_mode = m
	_update_modes()

func _update_modes() -> void:
	for i in 4:
		S.button_styles(mode_btns[i], S.GOLD if G.buy_mode == i else S.PAPER_DARK)

func _layout() -> void:
	soft_reset_btn.position = Vector2(size.x - 600, 6)
	soft_reset_btn.size = Vector2(114, 36)
	hard_reset_btn.position = Vector2(size.x - 480, 6)
	hard_reset_btn.size = Vector2(114, 36)
	var x := size.x - 356
	var w := [110.0, 66.0, 72.0, 74.0]
	for i in 4:
		mode_btns[i].position = Vector2(x, 6)
		mode_btns[i].size = Vector2(w[i], 36)
		x += w[i] + 6
	scroll.position = Vector2(18, 48)
	scroll.size = Vector2(size.x - 36, size.y - 54)

func _process(delta: float) -> void:
	if _confirm_hard > 0.0:
		_confirm_hard -= delta
		if _confirm_hard <= 0.0:
			hard_reset_btn.text = "RESET DA 0"
			S.button_styles(hard_reset_btn, S.RED_DARK, S.PAPER)
	queue_redraw()

func _draw() -> void:
	var mn: int = G.owned.min()
	var nxt := 1000
	for m in G.SYNERGY_MILESTONES:
		if mn < m:
			nxt = m
			break
	var mood_lbl := ""
	match Sfx.current_mood():
		"rush": mood_lbl = "   |   [RUSH: LO SQUALO ARRIVA!]"
		"hype": mood_lbl = "   |   [FEBBRE D'ORO!]"
	var syn := "IMPERO: tutte a %d/%d -> bonus x2 (x%d)%s" % [mn, nxt, int(pow(2, G.synergy_level())), mood_lbl]
	var col := S.RED if Sfx.current_mood() == "rush" else S.GOLD
	S.text(self, Vector2(24, 30), syn, 16, col, 0, S.f_num, 5, S.INK)
