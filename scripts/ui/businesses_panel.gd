extends Control
## Pannello "La Sala": griglia 2x5 delle attività + selettore x1/x10/x100/MAX + sinergia.

const BusinessCard := preload("res://scripts/ui/business_card.gd")

var fx: Control
var mode_btns: Array[Button] = []
var cards: Array[Control] = []
var scroll: ScrollContainer
var grid: GridContainer

func setup(p_fx: Control) -> void:
	fx = p_fx
	var labels := ["COMPRA x1", "x10", "x100", "MAX"]
	for i in 4:
		var b := S.make_button(labels[i], S.PAPER, 16)
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

func _set_mode(m: int) -> void:
	G.buy_mode = m
	_update_modes()

func _update_modes() -> void:
	for i in 4:
		S.button_styles(mode_btns[i], S.GOLD if G.buy_mode == i else S.PAPER_DARK)

func _layout() -> void:
	var x := size.x - 360
	var w := [112.0, 68.0, 74.0, 76.0]
	for i in 4:
		mode_btns[i].position = Vector2(x, 6)
		mode_btns[i].size = Vector2(w[i], 36)
		x += w[i] + 6
	scroll.position = Vector2(18, 48)
	scroll.size = Vector2(size.x - 36, size.y - 54)

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var mn: int = G.owned.min()
	var nxt := 1000
	for m in G.SYNERGY_MILESTONES:
		if mn < m:
			nxt = m
			break
	var syn := "IMPERO: tutte a %d/%d -> bonus globale x2 (attuale x%d)" % [mn, nxt, int(pow(2, G.synergy_level()))]
	S.text(self, Vector2(24, 30), syn, 16, S.GOLD, 0, S.f_num, 5, S.INK)
