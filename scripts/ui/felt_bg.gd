extends Control
## Panno verde da tavolo con lampada sospesa (disegnato via _draw per resa identica su ogni GPU).

var _tint := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func set_tint(v: float) -> void:
	if not is_equal_approx(_tint, v):
		_tint = v
		queue_redraw()

func _draw() -> void:
	var base_dark := Color("07261b").lerp(Color("28080e"), _tint)
	var base_mid := Color("125c40").lerp(Color("5c1220"), _tint)
	var base_lit := Color("1d855c").lerp(Color("8a1e32"), _tint)
	draw_rect(Rect2(Vector2.ZERO, size), base_dark)
	# cono di luce ellittico della lampada sul tavolo
	var c := Vector2(size.x * 0.5, size.y * 0.42)
	var steps := 24
	for i in steps:
		var k := 1.0 - float(i) / steps
		var col := base_dark.lerp(base_mid, 1.0 - k * k).lerp(base_lit, pow(1.0 - k, 2.2) * 0.65)
		draw_set_transform(c, 0, Vector2(1.45, 0.95))
		draw_circle(Vector2.ZERO, size.y * 0.78 * k, col)
	draw_set_transform(Vector2.ZERO)
	# trama a rombi tipica dei tappeti da casinò
	var step := 64.0
	var line_col := Color(1, 0.95, 0.75, 0.035)
	var x := -size.y
	while x < size.x + size.y:
		draw_line(Vector2(x, 0), Vector2(x + size.y, size.y), line_col, 1.0)
		draw_line(Vector2(x, size.y), Vector2(x + size.y, 0), line_col, 1.0)
		x += step
	# piccoli punti di fibra sul panno
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in 350:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var br := rng.randf()
		draw_circle(p, 1.2, Color(1, 1, 1, 0.03) if br > 0.5 else Color(0, 0, 0, 0.06))
	# cornice interna cucita sul panno
	var r := Rect2(26, 26, size.x - 52, size.y - 52)
	draw_rect(r, Color(S.GOLD, 0.14), false, 2.0)
