extends Control
## Pannello "Migliorie": mostra le prossime migliorie acquistabili + bottone "Compra tutte quelle che puoi".

class UpgradeRow extends Control:
	var u := {}
	var btn: Button
	signal bought
	func _ready() -> void:
		custom_minimum_size = Vector2(360, 86)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn = S.make_button("COMPRA", S.GOLD, 17)
		add_child(btn)
		btn.pressed.connect(func():
			if G.buy_upgrade(u):
				bought.emit())
		resized.connect(_layout)
	func _layout() -> void:
		btn.position = Vector2(size.x - 166, 16)
		btn.size = Vector2(150, size.y - 38)
	func set_data(d: Dictionary) -> void:
		u = d
		visible = not d.is_empty()
		queue_redraw()
	func _process(_d: float) -> void:
		if u.is_empty():
			return
		btn.text = "COMPRA\n" + G.fmt(u["cost"])
		btn.disabled = G.money < u["cost"]
		queue_redraw()
	func _draw() -> void:
		if u.is_empty():
			return
		var r := Rect2(Vector2(4, 2), size - Vector2(14, 12))
		S.draw_card(self, r, S.PAPER, 14, Vector2(5, 6))
		var t := int(u["target"])
		var col: Color = S.GOLD if t < 0 else G.BUSINESSES[t]["color"]
		var ic := Vector2(46, r.get_center().y)
		S.draw_chip(self, ic, 30, col)
		if t >= 0:
			S.draw_icon(self, G.BUSINESSES[t]["icon"], ic, 34)
		elif t == -1:
			S.draw_star(self, ic, 16, S.PAPER)
		elif t == -2:
			S.draw_symbol(self, "seven", ic, 30)
		else:
			S.draw_symbol(self, "clover", ic, 30)
		S.text(self, Vector2(92, 34), u["name"], 21, S.INK, 0, S.f_title)
		S.text(self, Vector2(92, 58), G.upgrade_desc(u), 16, S.RED_DARK, 0, S.f_num)

const SLOTS := 18
var rows: Array[UpgradeRow] = []
var buy_all_btn: Button
var _sc: ScrollContainer

func _ready() -> void:
	buy_all_btn = S.make_button("COMPRA TUTTE QUELLE CHE PUOI", S.GREEN, 18)
	add_child(buy_all_btn)
	buy_all_btn.pressed.connect(_buy_all)
	_sc = ScrollContainer.new()
	_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_sc)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	_sc.add_child(grid)
	for i in SLOTS:
		var r := UpgradeRow.new()
		grid.add_child(r)
		r.bought.connect(_refresh)
		rows.append(r)
	G.state_reset.connect(_refresh)
	visibility_changed.connect(_refresh)
	resized.connect(_layout)
	_refresh()

func _layout() -> void:
	buy_all_btn.position = Vector2(size.x - 350, 6)
	buy_all_btn.size = Vector2(326, 38)
	_sc.position = Vector2(20, 50)
	_sc.size = size - Vector2(40, 58)

func _buy_all() -> void:
	var n := 0
	for u in G.available_upgrades():
		if G.money >= u["cost"]:
			G.buy_upgrade(u)
			n += 1
	if n > 0:
		_refresh()

func _refresh() -> void:
	var av := G.available_upgrades()
	for i in SLOTS:
		rows[i].set_data(av[i] if i < av.size() else {})

func _process(_d: float) -> void:
	var av := G.available_upgrades()
	buy_all_btn.disabled = av.is_empty() or G.money < av[0]["cost"]
	queue_redraw()

func _draw() -> void:
	S.text(self, Vector2(24, 34), "CATALOGO MIGLIORIE — (%d/%d sbloccate)" % [G.upgrades_bought.size(), G.UPGRADES.size()], 20, S.GOLD, 0, S.f_title, 5, S.INK)
