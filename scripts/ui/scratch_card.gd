extends Control
## Gratta e Vinci: si gratta davvero col mouse (maschera su Image), 3 simboli uguali = vinci.

signal finished(win: float, stake: float, mult: float)

const CELL := 84.0
const GAP := 9.0
const GRID := CELL * 3 + GAP * 2
const BRUSH := 17

var state := "idle"  # idle | scratching | done
var grid: Array = []
var win_mult := 0.0
var win_sym := ""
var stake := 0.0
var revealed := []
var _img: Image
var _tex: ImageTexture
var _covered := PackedByteArray()
var _cell_left := []
var _dirty := false
var _last_mouse := Vector2(-1, -1)
var _base_foil: Image
var _t := 0.0
var _scratch_snd_t := 0.0
var _serial := 0

func _ready() -> void:
	custom_minimum_size = Vector2(360, 420)
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	_make_base_foil()
	_img = _base_foil.duplicate()
	_tex = ImageTexture.create_from_image(_img)

func _grid_origin() -> Vector2:
	return Vector2((size.x - GRID) * 0.5, 98)

func _ticket_rect() -> Rect2:
	var o := _grid_origin()
	return Rect2(o.x - 24, 6, GRID + 48, GRID + 132)

func _make_base_foil() -> void:
	var n := int(GRID)
	_base_foil = Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for y in n:
		for x in n:
			var v := 0.68 + 0.1 * sin((x + y) * 0.09) + rng.randf() * 0.08
			var band := 0.06 if int((x - y + 1000) / 14) % 2 == 0 else 0.0
			_base_foil.set_pixel(x, y, Color(v + band, v + band + 0.01, v + band + 0.04, 1.0))
	# stampa "€" a pattern sulla patina (rettangolini scuri per suggerire il logo)
	for cy in 3:
		for cx in 3:
			var c := Vector2i(int(cx * (CELL + GAP) + CELL * 0.5), int(cy * (CELL + GAP) + CELL * 0.5))
			for a in 40:
				var ang := TAU * a / 40.0
				for rr in [26, 27, 28]:
					var p := c + Vector2i(int(cos(ang) * rr), int(sin(ang) * rr))
					if p.x >= 0 and p.y >= 0 and p.x < n and p.y < n:
						_base_foil.set_pixel(p.x, p.y, Color(0.5, 0.52, 0.58))
			for yy in range(-14, 15):
				for xx in [-9, -8, -7]:
					_base_foil.set_pixel(c.x + xx, c.y + yy, Color(0.5, 0.52, 0.58))
			for xx in range(-9, 12):
				for yy in [-14, -13, 0, 1, 13, 14]:
					if xx < 4 or yy <= -13 or yy >= 13:
						_base_foil.set_pixel(c.x + xx, c.y + yy, Color(0.5, 0.52, 0.58))

func new_ticket(p_stake: float) -> void:
	var r := G.roll_scratch()
	grid = r["grid"]
	win_mult = r["win"]
	win_sym = r["sym"]
	stake = p_stake
	state = "scratching"
	_serial = randi() % 900000 + 100000
	revealed = []
	_cell_left = []
	var area := int(CELL * CELL)
	for k in 9:
		revealed.append(false)
		_cell_left.append(area)
	_img = _base_foil.duplicate()
	_tex.update(_img)
	_covered.resize(int(GRID) * int(GRID))
	_covered.fill(1)
	Sfx.play("whoosh", 1.6, -8)
	queue_redraw()

func reveal_all() -> void:
	if state != "scratching":
		return
	_img.fill(Color(0, 0, 0, 0))
	_tex.update(_img)
	for k in 9:
		revealed[k] = true
	Sfx.play("scratch", 0.8)
	_resolve()

func _cell_of(p: Vector2i) -> int:
	var cx := int(p.x / (CELL + GAP))
	var cy := int(p.y / (CELL + GAP))
	if cx > 2 or cy > 2:
		return -1
	if p.x - cx * (CELL + GAP) >= CELL or p.y - cy * (CELL + GAP) >= CELL:
		return -1
	return cy * 3 + cx

func _scratch_at(local: Vector2) -> void:
	var o := _grid_origin()
	var c := Vector2i((local - o).round())
	var n := int(GRID)
	var hit := false
	for dy in range(-BRUSH, BRUSH + 1):
		var y := c.y + dy
		if y < 0 or y >= n:
			continue
		var w := int(sqrt(BRUSH * BRUSH - dy * dy))
		for dx in range(-w, w + 1):
			var x := c.x + dx
			if x < 0 or x >= n:
				continue
			var idx := y * n + x
			if _covered[idx] == 1:
				_covered[idx] = 0
				_img.set_pixel(x, y, Color(0, 0, 0, 0))
				hit = true
				var cell := _cell_of(Vector2i(x, y))
				if cell >= 0:
					_cell_left[cell] -= 1
	if hit:
		_dirty = true
		if _scratch_snd_t <= 0:
			Sfx.play("scratch", randf_range(0.8, 1.3), -4)
			_scratch_snd_t = 0.07
		for k in 9:
			if not revealed[k] and _cell_left[k] < CELL * CELL * 0.45:
				revealed[k] = true
				var cx := k % 3
				var cy := k / 3
				_img.fill_rect(Rect2i(int(cx * (CELL + GAP)), int(cy * (CELL + GAP)), int(CELL), int(CELL)), Color(0, 0, 0, 0))
				Sfx.play("pop", 1.2)
		if not revealed.has(false):
			_resolve()

var _done_t := 0.0

func _resolve() -> void:
	state = "done"
	_done_t = 0.0
	_img.fill(Color(0, 0, 0, 0))
	_dirty = true
	G.stats["scratch"] += 1
	var win := win_mult * stake * G.game_mult()
	finished.emit(win, stake, win_mult)
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if state != "scratching":
		return
	var mm := e as InputEventMouseMotion
	var mb := e as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_last_mouse = mb.position
			_scratch_at(mb.position)
		else:
			_last_mouse = Vector2(-1, -1)
	elif mm and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var from := _last_mouse if _last_mouse.x >= 0 else mm.position
		var dist := from.distance_to(mm.position)
		var steps := int(dist / 6.0) + 1
		for s in steps:
			_scratch_at(from.lerp(mm.position, float(s + 1) / steps))
		_last_mouse = mm.position

func _process(delta: float) -> void:
	_t += delta
	_done_t += delta
	_scratch_snd_t -= delta
	if _dirty:
		_dirty = false
		_tex.update(_img)
	queue_redraw()

func _draw() -> void:
	var tr := _ticket_rect()
	var o := _grid_origin()
	# biglietto
	S.draw_card(self, tr, S.PAPER, 12, Vector2(8, 9), 3)
	# bordo dentellato decorativo
	for k in int(tr.size.x / 16):
		draw_circle(Vector2(tr.position.x + 12 + k * 16, tr.position.y + 8), 3, S.RED)
		draw_circle(Vector2(tr.position.x + 12 + k * 16, tr.end.y - 8), 3, S.RED)
	# intestazione
	var hr := Rect2(tr.position + Vector2(14, 14), Vector2(tr.size.x - 28, 60))
	S.draw_card(self, hr, S.RED, 10, Vector2(0, 4), 3)
	draw_set_transform(hr.get_center(), -0.025 + sin(_t * 2.0) * 0.01)
	S.text(self, Vector2(3, -1 + 3), "IL MILIONARIO", 32, S.SHADOW, 1, S.f_title)
	S.text(self, Vector2(0, -1), "IL MILIONARIO", 32, S.GOLD, 1, S.f_title, 6, S.INK)
	S.text(self, Vector2(0, 21), "Trova 3 simboli uguali!", 14, S.PAPER, 1, S.f_body, 4, S.INK)
	draw_set_transform(Vector2.ZERO)
	# celle con i simboli
	for k in 9:
		var cx := k % 3
		var cy := k / 3
		var cr := Rect2(o + Vector2(cx * (CELL + GAP), cy * (CELL + GAP)), Vector2(CELL, CELL))
		S.draw_round_rect(self, cr, Color("fff8e6"), 8)
		draw_rect(cr, Color(S.INK, 0.35), false, 2)
		if state != "idle" and k < grid.size():
			var is_win: bool = state == "done" and grid[k] == win_sym and win_mult > 0
			if is_win:
				var pulse := 0.5 + 0.5 * sin(_t * 10.0)
				S.draw_round_rect(self, cr.grow(4), Color(S.GOLD, 0.5 + 0.5 * pulse), 10)
				S.draw_round_rect(self, cr, Color("fff8e6"), 8)
			S.draw_symbol(self, grid[k], cr.get_center() - Vector2(0, 6), CELL * 0.62)
			var m := _prize_mult(grid[k])
			S.text(self, Vector2(cr.get_center().x, cr.end.y - 6), "x" + G.num(m), 13, Color(S.INK, 0.7), 1, S.f_num)
	# patina argentata
	if state == "scratching":
		draw_texture(_tex, o)
	elif state == "idle":
		draw_texture(_tex, o, Color(1, 1, 1, 0.92))
	# piè di pagina
	var fy := o.y + GRID + 22
	if state == "idle":
		S.text(self, Vector2(tr.get_center().x, fy), "Compra un biglietto per iniziare", 16, S.INK, 1, S.f_body)
	else:
		S.text(self, Vector2(tr.position.x + 24, fy), "Costo: " + G.fmt(stake), 16, S.INK, 0, S.f_num)
		S.text(self, Vector2(tr.end.x - 24, fy), "N° %06d" % _serial, 13, Color(S.INK, 0.6), 2, S.f_body)
	if state == "done":
		var won := win_mult > 0
		var msg := ("VINCENTE x" + G.num(win_mult)) if won else "NON VINCENTE"
		var col := S.RED if won else Color(S.INK, 0.45)
		var sc := 1.0 + 0.4 * maxf(0.0, 1.0 - _done_t * 6.0)
		draw_set_transform(o + Vector2(GRID * 0.5, GRID * 0.5), -0.22, Vector2(sc, sc))
		var f: Font = S.f_title
		var w := f.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x + 30
		var rr := Rect2(-w * 0.5, -30, w, 56)
		S.draw_round_rect(self, rr, Color(S.PAPER, 0.78), 8)
		draw_rect(rr, col, false, 5)
		draw_rect(rr.grow(-7), col, false, 2)
		S.text(self, Vector2(0, 12), msg, 34, col, 1, f)
		draw_set_transform(Vector2.ZERO)

func _prize_mult(sym: String) -> float:
	for p in G.SCRATCH_PRIZES:
		if p["sym"] == sym:
			return p["mult"]
	return 0.0
