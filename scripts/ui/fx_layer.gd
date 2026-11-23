extends Control
## Layer per effetti: testi fluttuanti, monete che volano al contatore, banner jackpot, coriandoli.

signal coin_arrived

var target: Control
var _texts: Array = []
var _coins: Array = []
var _confetti: Array = []
var _banner := {}
var flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func popup(pos: Vector2, txt: String, col := S.GOLD, size := 26) -> void:
	if _texts.size() > 40:
		_texts.pop_front()
	_texts.append({"pos": pos + Vector2(randf_range(-10, 10), 0), "txt": txt, "col": col, "size": size, "t": 0.0, "life": 1.2, "rot": randf_range(-0.12, 0.12)})

func coins(from: Vector2, n: int) -> void:
	n = clampi(n, 1, 24)
	for i in n:
		if _coins.size() > 80:
			break
		_coins.append({"from": from, "ctrl": from + Vector2(randf_range(-160, 160), randf_range(-220, -60)), "t": -i * 0.035, "dur": randf_range(0.55, 0.85), "spin": randf() * TAU})

func confetti(center: Vector2, n := 80) -> void:
	for i in n:
		_confetti.append({"pos": center, "vel": Vector2.from_angle(randf() * TAU) * randf_range(200, 700) + Vector2(0, -300), "rot": randf() * TAU, "vr": randf_range(-10, 10), "col": [S.RED, S.GOLD, S.TEAL, S.BLUE, S.PINK, S.GREEN].pick_random(), "t": 0.0, "life": randf_range(1.5, 2.5)})

func banner(title: String, sub := "", col := S.GOLD) -> void:
	_banner = {"title": title, "sub": sub, "col": col, "t": 0.0, "life": 2.6}
	flash = 0.6

func _target_pos() -> Vector2:
	if target and is_instance_valid(target):
		return target.global_position + Vector2(70, target.size.y * 0.5)
	return Vector2(100, 50)

func _process(delta: float) -> void:
	var busy := false
	for t in _texts:
		t["t"] += delta
		t["pos"].y -= 60 * delta
	_texts = _texts.filter(func(t): return t["t"] < t["life"])
	var tp := _target_pos()
	var arrived := false
	for c in _coins:
		c["t"] += delta
		c["spin"] += delta * 12
		if c["t"] >= c["dur"]:
			arrived = true
	var before := _coins.size()
	_coins = _coins.filter(func(c): return c["t"] < c["dur"])
	if arrived:
		coin_arrived.emit()
		if before - _coins.size() > 0:
			Sfx.play("coin", 1.0 + randf() * 0.3, -6.0)
	for p in _confetti:
		p["t"] += delta
		p["vel"].y += 900 * delta
		p["vel"] *= 0.985
		p["pos"] += p["vel"] * delta
		p["rot"] += p["vr"] * delta
	_confetti = _confetti.filter(func(p): return p["t"] < p["life"])
	if not _banner.is_empty():
		_banner["t"] += delta
		if _banner["t"] > _banner["life"]:
			_banner = {}
	flash = maxf(0.0, flash - delta * 1.5)
	busy = not (_texts.is_empty() and _coins.is_empty() and _confetti.is_empty() and _banner.is_empty() and flash <= 0)
	if busy or _was_busy:
		queue_redraw()
	_was_busy = busy

var _was_busy := false

func _bez(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)

func _draw() -> void:
	if flash > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.95, 0.7, flash * 0.35))
	for p in _confetti:
		var a := 1.0 - maxf(0.0, (p["t"] - p["life"] + 0.5) / 0.5)
		draw_set_transform(p["pos"], p["rot"], Vector2(1, abs(sin(p["rot"] * 2.0)) + 0.2))
		draw_rect(Rect2(-6, -4, 12, 8), Color(p["col"], a))
	draw_set_transform(Vector2.ZERO)
	var tp := _target_pos()
	for c in _coins:
		if c["t"] < 0:
			continue
		var k: float = ease(c["t"] / c["dur"], 2.2)
		var pos := _bez(c["from"], c["ctrl"], tp, k)
		var sx := absf(cos(c["spin"])) * 0.8 + 0.2
		draw_set_transform(pos, 0, Vector2(sx, 1))
		draw_circle(Vector2(2, 3), 11, S.SHADOW)
		draw_circle(Vector2.ZERO, 11, S.GOLD)
		draw_arc(Vector2.ZERO, 11, 0, TAU, 20, S.INK, 2.5, true)
		draw_arc(Vector2.ZERO, 6.5, 0, TAU, 14, S.GOLD_DARK, 2.0, true)
	draw_set_transform(Vector2.ZERO)
	for t in _texts:
		var k: float = t["t"] / t["life"]
		var a := 1.0 - maxf(0.0, (k - 0.6) / 0.4)
		var sc := 1.0 + 0.35 * maxf(0.0, 1.0 - k * 6.0)
		draw_set_transform(t["pos"], t["rot"], Vector2(sc, sc))
		S.text(self, Vector2.ZERO, t["txt"], t["size"], Color(t["col"], a), 1, S.f_title, 7, Color(S.INK, a))
	draw_set_transform(Vector2.ZERO)
	if not _banner.is_empty():
		var bt: float = _banner["t"]
		var center := size * 0.5
		var a := minf(1.0, (_banner["life"] - bt) * 3.0)
		var pop: float = 1.0 + 0.6 * maxf(0.0, 1.0 - bt * 5.0)
		# raggi rotanti
		for i in 16:
			var ang := bt * 0.8 + TAU * i / 16.0
			var pts := PackedVector2Array([center, center + Vector2.from_angle(ang - 0.09) * 900, center + Vector2.from_angle(ang + 0.09) * 900])
			draw_colored_polygon(pts, Color(_banner["col"], 0.18 * a))
		draw_set_transform(center, sin(bt * 6.0) * 0.04, Vector2(pop, pop))
		S.text(self, Vector2(6, 26), _banner["title"], 96, Color(S.INK, 0.6 * a), 1, S.f_title)
		S.text(self, Vector2(0, 20), _banner["title"], 96, Color(_banner["col"], a), 1, S.f_title, 14, Color(S.INK, a))
		if _banner["sub"] != "":
			S.text(self, Vector2(0, 80), _banner["sub"], 44, Color(S.PAPER, a), 1, S.f_num, 10, Color(S.INK, a))
		draw_set_transform(Vector2.ZERO)
