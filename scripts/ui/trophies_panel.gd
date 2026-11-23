extends Control
## Pannello "Trofei": statistiche + lista trofei (ogni trofeo dà +2% a tutti i guadagni).

class AchBadge extends Control:
	var a := {}
	func setup(d: Dictionary) -> void:
		a = d
		custom_minimum_size = Vector2(280, 62)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var got := G.achievements.has(a["id"])
		var r := Rect2(Vector2(3, 2), size - Vector2(10, 8))
		S.draw_card(self, r, S.PAPER if got else S.PAPER_DARK.darkened(0.15), 11, Vector2(3, 4), 2.5)
		var ic := Vector2(30, r.get_center().y)
		draw_circle(ic, 19, S.GOLD if got else S.GREY)
		S.circle_outline(self, ic, 19, S.INK, 2)
		if got:
			S.draw_star(self, ic, 11, S.PAPER)
		else:
			S.text_in(self, Rect2(ic - Vector2(12, 12), Vector2(24, 24)), "?", 18, S.PAPER, 1, S.f_title)
		S.text(self, Vector2(58, 30), a["name"], 15, S.INK if got else Color(S.INK, 0.55), 0, S.f_num, 0, S.INK, size.x - 70)
		S.text(self, Vector2(58, 48), "+2% guadagni" if got else "Bloccato", 12, S.GREEN.darkened(0.3) if got else S.GREY, 0, S.f_body)

var _sc: ScrollContainer
var sfx_btn: Button
var mus_btn: Button
var reset_btn: Button
var _confirm := false

func _ready() -> void:
	sfx_btn = S.make_button("SFX: ON", S.TEAL, 15, S.PAPER)
	mus_btn = S.make_button("MUSICA: ON", S.TEAL, 15, S.PAPER)
	reset_btn = S.make_button("CANCELLA SALVATAGGIO", S.RED_DARK, 14, S.PAPER)
	add_child(sfx_btn); add_child(mus_btn); add_child(reset_btn)
	sfx_btn.pressed.connect(func(): G.sfx_on = not G.sfx_on)
	mus_btn.pressed.connect(func(): Sfx.set_music(not G.music_on))
	reset_btn.pressed.connect(_on_reset)
	_sc = ScrollContainer.new()
	_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	_sc.add_child(grid)
	for a in G.ACHIEVEMENTS:
		var b := AchBadge.new()
		grid.add_child(b)
		b.setup(a)
	resized.connect(_layout)

func _on_reset() -> void:
	if not _confirm:
		_confirm = true
		reset_btn.text = "SICURO? CLICCA ANCORA"
		return
	G.hard_reset()

func _layout() -> void:
	sfx_btn.position = Vector2(size.x - 450, 20); sfx_btn.size = Vector2(110, 36)
	mus_btn.position = Vector2(size.x - 332, 20); mus_btn.size = Vector2(130, 36)
	reset_btn.position = Vector2(size.x - 194, 20); reset_btn.size = Vector2(170, 36)
	_sc.position = Vector2(20, 148)
	_sc.size = size - Vector2(40, 156)

func _process(_d: float) -> void:
	sfx_btn.text = "SFX: " + ("ON" if G.sfx_on else "OFF")
	mus_btn.text = "MUSICA: " + ("ON" if G.music_on else "OFF")
	queue_redraw()

func _draw() -> void:
	var top := Rect2(20, 10, size.x - 40, 124)
	S.draw_card(self, top, S.PAPER, 16, Vector2(6, 7))
	S.text(self, Vector2(40, 44), "BACHECA DEI TROFEI  (%d/%d = x%.2f a tutto)" % [G.achievements.size(), G.ACHIEVEMENTS.size(), G.achievement_mult()], 24, S.INK, 0, S.f_title)
	var st := G.stats
	var line1 := "Guadagnato totale: %s   |   Vincita max: %s   |   Squali ripagati: %d   |   Fughe: %d" % [G.fmt(G.all_earned), G.fmt(st["biggest_win"]), G.cities_cleared, int(st["prestiges"])]
	var line2 := "Biglietti: %d   |   Giri slot: %d   |   Dadi: %d   |   Jackpot: %d   |   Gatti: %d   |   Record raddoppio: x%d" % [int(st["scratch"]), int(st["spins"]), int(st["rolls"]), int(st["jackpots"]), int(st["cats"]), int(st["best_double"])]
	S.text(self, Vector2(40, 78), line1, 15, S.INK, 0, S.f_num)
	S.text(self, Vector2(40, 106), line2, 14, Color(S.INK, 0.75), 0, S.f_body)
