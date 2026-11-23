extends Node
## Autoload "S": palette, font e helper di disegno.
## Stile: panno da casinò verde illuminato da una lampada, oggetti di carta/plastica
## con contorno d'inchiostro spesso e ombra netta (niente sfocatura) = look "ritaglio".

const INK := Color("1b1420")
const PAPER := Color("f6ead0")
const PAPER_DARK := Color("e0cba0")
const FELT := Color("11573d")
const FELT_DARK := Color("06261b")
const RED := Color("d6344a")
const RED_DARK := Color("8e1c2e")
const GOLD := Color("f2b632")
const GOLD_DARK := Color("b9801c")
const TEAL := Color("2bb3a3")
const BLUE := Color("3a6fd8")
const PURPLE := Color("8a4fd1")
const ORANGE := Color("f07f2e")
const GREEN := Color("5ac35a")
const PINK := Color("ff6fae")
const WOOD := Color("4a2614")
const WOOD_LIGHT := Color("7a3f1f")
const SHADOW := Color(0, 0, 0, 0.42)
const GREY := Color("8d8478")

var f_title: Font
var f_num: Font
var f_body: Font
var theme: Theme

var _sb_cache := {}

func _ready() -> void:
	f_title = load("res://assets/fonts/LuckiestGuy-Regular.ttf")
	f_num = load("res://assets/fonts/LilitaOne-Regular.ttf")
	var rub: FontFile = load("res://assets/fonts/Rubik.ttf")
	var fv := FontVariation.new()
	fv.base_font = rub
	var ts := TextServerManager.get_primary_interface()
	fv.variation_opentype = {ts.name_to_tag("wght"): 650}
	f_body = fv
	theme = _build_theme()

# ---------------------------------------------------------------- THEME
func sb(fill: Color, border := INK, bw := 3, radius := 12, shadow_off := Vector2(0, 5), shadow_col := SHADOW) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.shadow_color = shadow_col
	s.shadow_offset = shadow_off
	s.shadow_size = 1 if shadow_off != Vector2.ZERO else 0
	s.anti_aliasing = true
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func button_styles(btn: Button, fill: Color, font_col := INK) -> void:
	var n := sb(fill)
	var h := sb(fill.lightened(0.15))
	var p := sb(fill.darkened(0.12), INK, 3, 12, Vector2(0, 1))
	p.content_margin_top = 10
	p.content_margin_bottom = 2
	var d := sb(fill.lerp(GREY, 0.65), INK.lerp(GREY, 0.5), 3, 12, Vector2(0, 3))
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("disabled", d)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_hover_color", font_col)
	btn.add_theme_color_override("font_pressed_color", font_col)
	btn.add_theme_color_override("font_disabled_color", INK.lerp(GREY, 0.6))

func make_button(text: String, fill := GOLD, size := 20, font_col := INK) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", f_num)
	b.add_theme_font_size_override("font_size", size)
	button_styles(b, fill, font_col)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func(): Sfx.play("click"))
	return b

func make_label(text: String, size := 18, col := INK, font: Font = null, outline := 0, outline_col := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font else f_body)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", outline_col)
	return l

func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = f_body
	t.default_font_size = 16
	t.set_color("font_color", "Label", INK)
	# Scrollbar sottile stile fiche
	var grab := sb(GOLD, INK, 2, 8, Vector2.ZERO)
	var grab_h := sb(GOLD.lightened(0.2), INK, 2, 8, Vector2.ZERO)
	var track := sb(Color(0, 0, 0, 0.25), Color(0, 0, 0, 0), 0, 8, Vector2.ZERO)
	for c in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("grabber", c, grab)
		t.set_stylebox("grabber_highlight", c, grab_h)
		t.set_stylebox("grabber_pressed", c, grab_h)
		t.set_stylebox("scroll", c, track)
		t.set_stylebox("scroll_focus", c, track)
	var tip := sb(PAPER, INK, 3, 8, Vector2(0, 4))
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_font("font", "TooltipLabel", f_body)
	t.set_font_size("font_size", "TooltipLabel", 15)
	return t

# ---------------------------------------------------------------- DRAW HELPERS
## Card di carta con ombra netta e contorno d'inchiostro.
func draw_card(ci: CanvasItem, r: Rect2, fill := PAPER, radius := 14.0, shadow := Vector2(6, 7), bw := 3.0, border := INK) -> void:
	var key := "%s|%s|%s|%s" % [fill.to_html(), radius, bw, border.to_html()]
	var s: StyleBoxFlat = _sb_cache.get(key)
	if s == null:
		s = StyleBoxFlat.new()
		s.bg_color = fill
		s.border_color = border
		s.set_border_width_all(int(bw))
		s.set_corner_radius_all(int(radius))
		s.anti_aliasing = true
		_sb_cache[key] = s
	if shadow != Vector2.ZERO:
		var sk := "sh|%s" % radius
		var ss: StyleBoxFlat = _sb_cache.get(sk)
		if ss == null:
			ss = StyleBoxFlat.new()
			ss.bg_color = SHADOW
			ss.set_corner_radius_all(int(radius))
			ss.anti_aliasing = true
			_sb_cache[sk] = ss
		ss.draw(ci.get_canvas_item(), Rect2(r.position + shadow, r.size))
	s.draw(ci.get_canvas_item(), r)

func draw_round_rect(ci: CanvasItem, r: Rect2, fill: Color, radius := 8.0) -> void:
	var key := "rr|%s|%s" % [fill.to_html(), radius]
	var s: StyleBoxFlat = _sb_cache.get(key)
	if s == null:
		s = StyleBoxFlat.new()
		s.bg_color = fill
		s.set_corner_radius_all(int(radius))
		s.anti_aliasing = true
		_sb_cache[key] = s
	s.draw(ci.get_canvas_item(), r)

## Testo con contorno opzionale. align: 0 sinistra, 1 centro, 2 destra. pos = baseline-left/centro.
func text(ci: CanvasItem, pos: Vector2, s: String, size := 18, col := INK, align := 0, font: Font = null, outline := 0, outline_col := INK, width := -1.0) -> void:
	var f: Font = font if font else f_body
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	if width > 0 and w > width:
		# riduci la dimensione per far stare il testo
		size = max(8, int(size * width / w))
		w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos
	if align == 1:
		p.x -= w * 0.5
	elif align == 2:
		p.x -= w
	if outline > 0:
		ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_col)
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

## Testo centrato verticalmente in un rect.
func text_in(ci: CanvasItem, r: Rect2, s: String, size := 18, col := INK, align := 1, font: Font = null, outline := 0, outline_col := INK) -> void:
	var f: Font = font if font else f_body
	var asc := f.get_ascent(size)
	var desc := f.get_descent(size)
	var y := r.position.y + r.size.y * 0.5 + (asc - desc) * 0.5
	var x := r.position.x
	if align == 1:
		x += r.size.x * 0.5
	elif align == 2:
		x += r.size.x
	text(ci, Vector2(x, y), s, size, col, align, f, outline, outline_col, r.size.x)

func circle_outline(ci: CanvasItem, c: Vector2, r: float, col := INK, w := 3.0) -> void:
	ci.draw_arc(c, r, 0, TAU, max(24, int(r * 1.2)), col, w, true)

## Fiche da poker.
func draw_chip(ci: CanvasItem, c: Vector2, r: float, col: Color, shadow := true, stripes := 6) -> void:
	if shadow:
		ci.draw_circle(c + Vector2(3, 5), r, SHADOW)
	ci.draw_circle(c, r, col)
	for i in stripes:
		var a := TAU * i / stripes
		var pts := PackedVector2Array()
		var a0 := a - 0.18
		var a1 := a + 0.18
		pts.append(c + Vector2.from_angle(a0) * r * 0.98)
		pts.append(c + Vector2.from_angle(a1) * r * 0.98)
		pts.append(c + Vector2.from_angle(a1) * r * 0.74)
		pts.append(c + Vector2.from_angle(a0) * r * 0.74)
		ci.draw_colored_polygon(pts, PAPER)
	ci.draw_circle(c, r * 0.66, col.darkened(0.12))
	circle_outline(ci, c, r * 0.66, Color(INK, 0.6), 2.0)
	circle_outline(ci, c, r, INK, 3.0)

func draw_star(ci: CanvasItem, c: Vector2, r: float, col: Color, points := 5, inner := 0.45, rot := -PI / 2) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var rr := r if i % 2 == 0 else r * inner
		pts.append(c + Vector2.from_angle(rot + PI * i / points) * rr)
	ci.draw_colored_polygon(pts, col)
	pts.append(pts[0])
	ci.draw_polyline(pts, INK, 2.0, true)

## Simboli usati in slot e gratta e vinci (disegnati, niente emoji).
const SYMBOLS := ["cherry", "lemon", "bell", "clover", "horseshoe", "diamond", "seven"]

func draw_symbol(ci: CanvasItem, sym: String, c: Vector2, s: float) -> void:
	match sym:
		"cherry":
			ci.draw_line(c + Vector2(-s * 0.18, -s * 0.02), c + Vector2(s * 0.08, -s * 0.42), Color("2f7d32"), s * 0.07, true)
			ci.draw_line(c + Vector2(s * 0.22, s * 0.05), c + Vector2(s * 0.08, -s * 0.42), Color("2f7d32"), s * 0.07, true)
			var leaf := PackedVector2Array([c + Vector2(s * 0.08, -s * 0.42), c + Vector2(s * 0.35, -s * 0.5), c + Vector2(s * 0.3, -s * 0.34)])
			ci.draw_colored_polygon(leaf, GREEN)
			for p in [Vector2(-s * 0.2, s * 0.15), Vector2(s * 0.22, s * 0.2)]:
				ci.draw_circle(c + p + Vector2(2, 3), s * 0.21, SHADOW)
				ci.draw_circle(c + p, s * 0.21, RED)
				circle_outline(ci, c + p, s * 0.21, INK, 2.5)
				ci.draw_circle(c + p + Vector2(-s * 0.07, -s * 0.07), s * 0.05, Color(1, 1, 1, 0.8))
		"lemon":
			var pts := PackedVector2Array()
			for i in 32:
				var a := TAU * i / 32.0
				var rx := s * 0.42
				var ry := s * 0.3
				var k := 1.0 + 0.12 * pow(abs(cos(a)), 12.0)
				pts.append(c + Vector2(cos(a) * rx * k, sin(a) * ry))
			ci.draw_colored_polygon(pts, Color("ffe14d"))
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, 2.5, true)
			ci.draw_line(c + Vector2(-s * 0.15, -s * 0.12), c + Vector2(s * 0.1, -s * 0.16), Color(1, 1, 1, 0.7), s * 0.05, true)
		"bell":
			var pts := PackedVector2Array([
				c + Vector2(-s * 0.08, -s * 0.38), c + Vector2(s * 0.08, -s * 0.38),
				c + Vector2(s * 0.2, -s * 0.28), c + Vector2(s * 0.26, s * 0.05),
				c + Vector2(s * 0.42, s * 0.25), c + Vector2(-s * 0.42, s * 0.25),
				c + Vector2(-s * 0.26, s * 0.05), c + Vector2(-s * 0.2, -s * 0.28)])
			ci.draw_colored_polygon(pts, GOLD)
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, 2.5, true)
			ci.draw_circle(c + Vector2(0, s * 0.33), s * 0.09, GOLD_DARK)
			circle_outline(ci, c + Vector2(0, s * 0.33), s * 0.09, INK, 2.0)
			ci.draw_line(c + Vector2(-s * 0.1, -s * 0.22), c + Vector2(-s * 0.16, s * 0.08), Color(1, 1, 1, 0.7), s * 0.05, true)
		"clover":
			ci.draw_line(c, c + Vector2(s * 0.15, s * 0.42), Color("2f7d32"), s * 0.08, true)
			for a in [-PI / 2, 0.0, PI / 2, PI]:
				var o := Vector2.from_angle(a + PI / 4) * s * 0.19
				ci.draw_circle(c + o, s * 0.17, GREEN)
				circle_outline(ci, c + o, s * 0.17, INK, 2.0)
			ci.draw_circle(c, s * 0.06, Color("2f7d32"))
		"horseshoe":
			ci.draw_arc(c + Vector2(0, -s * 0.02), s * 0.3, PI * 0.85, PI * 2.15, 24, INK, s * 0.2, true)
			ci.draw_arc(c + Vector2(0, -s * 0.02), s * 0.3, PI * 0.85, PI * 2.15, 24, Color("b8c4cc"), s * 0.13, true)
			for i in 5:
				var a := PI * 0.95 + i * PI * 0.27
				ci.draw_circle(c + Vector2(0, -s * 0.02) + Vector2.from_angle(a) * s * 0.3, s * 0.025, INK)
		"diamond":
			var pts := PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.12), c + Vector2(-s * 0.2, -s * 0.34), c + Vector2(s * 0.2, -s * 0.34), c + Vector2(s * 0.4, -s * 0.12), c + Vector2(0, s * 0.4)])
			ci.draw_colored_polygon(pts, Color("6fd6ff"))
			var top := PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.12), c + Vector2(-s * 0.2, -s * 0.34), c + Vector2(s * 0.2, -s * 0.34), c + Vector2(s * 0.4, -s * 0.12)])
			ci.draw_colored_polygon(top, Color("b9eeff"))
			ci.draw_line(c + Vector2(-s * 0.12, -s * 0.12), c + Vector2(0, s * 0.4), Color(INK, 0.5), 1.5, true)
			ci.draw_line(c + Vector2(s * 0.12, -s * 0.12), c + Vector2(0, s * 0.4), Color(INK, 0.5), 1.5, true)
			ci.draw_line(c + Vector2(-s * 0.4, -s * 0.12), c + Vector2(s * 0.4, -s * 0.12), Color(INK, 0.5), 1.5, true)
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, 2.5, true)
		"seven":
			text(ci, c + Vector2(3, s * 0.36 + 3), "7", int(s * 0.95), SHADOW, 1, f_title)
			text(ci, c + Vector2(0, s * 0.36), "7", int(s * 0.95), RED, 1, f_title, 5, INK)
		_:
			ci.draw_circle(c, s * 0.3, GREY)

const SYMBOL_NAMES := {"cherry": "Ciliegia", "lemon": "Limone", "bell": "Campana", "clover": "Quadrifoglio", "horseshoe": "Ferro di cavallo", "diamond": "Diamante", "seven": "Sette d'oro"}

## Icone delle attività.
func draw_icon(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	match id:
		"ticket":
			var r := Rect2(c - Vector2(s * 0.4, s * 0.26), Vector2(s * 0.8, s * 0.52))
			draw_card(ci, r, PAPER, 4, Vector2(2, 3), 2.5)
			draw_round_rect(ci, r.grow(-s * 0.08), Color("b8c4cc"), 3)
			text_in(ci, r, "€", int(s * 0.38), RED, 1, f_title)
		"slot":
			var r := Rect2(c - Vector2(s * 0.36, s * 0.34), Vector2(s * 0.62, s * 0.7))
			draw_card(ci, r, RED, 6, Vector2(2, 3), 2.5)
			var w := Rect2(r.position + Vector2(s * 0.07, s * 0.16), Vector2(s * 0.48, s * 0.26))
			draw_round_rect(ci, w, PAPER, 3)
			text_in(ci, w, "777", int(s * 0.2), RED, 1, f_title)
			ci.draw_line(c + Vector2(s * 0.3, -s * 0.05), c + Vector2(s * 0.42, -s * 0.38), INK, 3, true)
			ci.draw_circle(c + Vector2(s * 0.42, -s * 0.38), s * 0.07, GOLD)
		"bingo":
			for i in 3:
				var p := c + Vector2((i - 1) * s * 0.26, (i % 2) * s * 0.14 - s * 0.04)
				ci.draw_circle(p + Vector2(2, 3), s * 0.17, SHADOW)
				ci.draw_circle(p, s * 0.17, [RED, BLUE, GOLD][i])
				ci.draw_circle(p, s * 0.1, PAPER)
				circle_outline(ci, p, s * 0.17, INK, 2.0)
				text_in(ci, Rect2(p - Vector2(s * 0.1, s * 0.1), Vector2(s * 0.2, s * 0.2)), str([7, 42, 90][i]), int(s * 0.11), INK, 1, f_num)
		"horse":
			var pts := PackedVector2Array([
				c + Vector2(-s * 0.3, s * 0.38), c + Vector2(-s * 0.22, s * 0.0), c + Vector2(-s * 0.05, -s * 0.22),
				c + Vector2(-s * 0.02, -s * 0.38), c + Vector2(s * 0.08, -s * 0.3), c + Vector2(s * 0.34, -s * 0.12),
				c + Vector2(s * 0.3, -s * 0.02), c + Vector2(s * 0.12, -s * 0.06), c + Vector2(s * 0.14, s * 0.12),
				c + Vector2(s * 0.3, s * 0.38)])
			ci.draw_colored_polygon(pts, Color("8a5a3c"))
			pts.append(pts[0])
			ci.draw_polyline(pts, INK, 2.5, true)
			ci.draw_circle(c + Vector2(s * 0.1, -s * 0.2), s * 0.03, INK)
			ci.draw_line(c + Vector2(-s * 0.04, -s * 0.3), c + Vector2(-s * 0.2, -s * 0.05), INK, 3, true)
		"cards":
			for i in 2:
				var r := Rect2(c + Vector2(-s * 0.32 + i * s * 0.2, -s * 0.36 + i * s * 0.08), Vector2(s * 0.42, s * 0.6))
				draw_card(ci, r, PAPER, 5, Vector2(2, 3), 2.5)
				text_in(ci, r, ["A", "K"][i], int(s * 0.3), [INK, RED][i], 1, f_title)
		"roulette":
			ci.draw_circle(c + Vector2(2, 4), s * 0.4, SHADOW)
			for i in 12:
				var a0 := TAU * i / 12.0
				var pts := PackedVector2Array([c, c + Vector2.from_angle(a0) * s * 0.4, c + Vector2.from_angle(a0 + TAU / 24) * s * 0.4, c + Vector2.from_angle(a0 + TAU / 12) * s * 0.4])
				ci.draw_colored_polygon(pts, RED if i % 2 == 0 else INK)
			ci.draw_circle(c, s * 0.16, GOLD)
			circle_outline(ci, c, s * 0.16, INK, 2)
			circle_outline(ci, c, s * 0.4, INK, 3)
			ci.draw_circle(c + Vector2(s * 0.22, -s * 0.18), s * 0.05, PAPER)
		"lottery":
			var r := Rect2(c - Vector2(s * 0.34, s * 0.3), Vector2(s * 0.68, s * 0.6))
			ci.draw_circle(c + Vector2(2, 4), s * 0.38, SHADOW)
			ci.draw_circle(c, s * 0.38, Color(0.75, 0.9, 1, 0.6))
			for i in 6:
				var p := c + Vector2(cos(i * 1.7) * s * 0.2, sin(i * 2.3) * s * 0.2)
				ci.draw_circle(p, s * 0.08, [RED, GOLD, BLUE, GREEN, PINK, ORANGE][i])
			circle_outline(ci, c, s * 0.38, INK, 3)
		"ship":
			var hull := PackedVector2Array([c + Vector2(-s * 0.42, s * 0.05), c + Vector2(s * 0.42, s * 0.05), c + Vector2(s * 0.28, s * 0.3), c + Vector2(-s * 0.3, s * 0.3)])
			ci.draw_colored_polygon(hull, RED)
			hull.append(hull[0])
			ci.draw_polyline(hull, INK, 2.5, true)
			var cab := Rect2(c + Vector2(-s * 0.26, -s * 0.2), Vector2(s * 0.46, s * 0.25))
			draw_card(ci, cab, PAPER, 3, Vector2.ZERO, 2.5)
			for i in 3:
				ci.draw_circle(cab.position + Vector2(s * 0.09 + i * s * 0.14, s * 0.12), s * 0.04, GOLD)
			ci.draw_rect(Rect2(c + Vector2(s * 0.05, -s * 0.38), Vector2(s * 0.1, s * 0.18)), INK)
		"crypto":
			ci.draw_circle(c + Vector2(2, 4), s * 0.38, SHADOW)
			ci.draw_circle(c, s * 0.38, ORANGE)
			circle_outline(ci, c, s * 0.38, INK, 3)
			text_in(ci, Rect2(c - Vector2(s * 0.3, s * 0.3), Vector2(s * 0.6, s * 0.6)), "B", int(s * 0.46), PAPER, 1, f_title, 4, INK)
		"moon":
			ci.draw_circle(c + Vector2(2, 4), s * 0.38, SHADOW)
			ci.draw_circle(c, s * 0.38, Color("e8e4d8"))
			for p in [Vector2(-0.12, -0.1), Vector2(0.14, 0.08), Vector2(-0.05, 0.18)]:
				ci.draw_circle(c + p * s, s * 0.07, Color("bdb6a4"))
			circle_outline(ci, c, s * 0.38, INK, 3)
		"shark":
			draw_shark(ci, c, s)
		_:
			ci.draw_circle(c, s * 0.3, GREY)

## Lo Squalo: pinna + muso con denti.
func draw_shark(ci: CanvasItem, c: Vector2, s: float) -> void:
	var body := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		body.append(c + Vector2(cos(a) * s * 0.42, sin(a) * s * 0.3 + s * 0.06))
	ci.draw_colored_polygon(body, Color("6d8aa0"))
	var belly := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		belly.append(c + Vector2(cos(a) * s * 0.36, sin(a) * s * 0.2 + s * 0.12))
	ci.draw_colored_polygon(belly, PAPER)
	var fin := PackedVector2Array([c + Vector2(-s * 0.12, -s * 0.2), c + Vector2(s * 0.05, -s * 0.5), c + Vector2(s * 0.14, -s * 0.2)])
	ci.draw_colored_polygon(fin, Color("6d8aa0"))
	fin.append(fin[0])
	ci.draw_polyline(fin, INK, 2.5, true)
	body.append(body[0])
	ci.draw_polyline(body, INK, 2.5, true)
	# denti
	for i in 6:
		var x := -s * 0.25 + i * s * 0.1
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x, s * 0.12), c + Vector2(x + s * 0.1, s * 0.12), c + Vector2(x + s * 0.05, s * 0.22)]), Color.WHITE)
	ci.draw_line(c + Vector2(-s * 0.27, s * 0.12), c + Vector2(s * 0.35, s * 0.12), INK, 2, true)
	# occhio cattivo
	ci.draw_circle(c + Vector2(s * 0.18, -s * 0.04), s * 0.06, Color.WHITE)
	ci.draw_circle(c + Vector2(s * 0.19, -s * 0.03), s * 0.03, INK)
	ci.draw_line(c + Vector2(s * 0.08, -s * 0.14), c + Vector2(s * 0.27, -s * 0.08), INK, 3, true)
	# cappello da gangster
	var hat := Rect2(c + Vector2(-s * 0.2, -s * 0.36), Vector2(s * 0.3, s * 0.12))
	ci.draw_rect(hat, INK)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.28, -s * 0.26), Vector2(s * 0.46, s * 0.05)), INK)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.2, -s * 0.29), Vector2(s * 0.3, s * 0.03)), RED)

## Ritratti procedurali dei manager.
func draw_face(ci: CanvasItem, c: Vector2, s: float, p: Dictionary) -> void:
	var skin: Color = p.get("skin", Color("f1c27d"))
	ci.draw_circle(c + Vector2(3, 5), s * 0.42, SHADOW)
	# capelli dietro
	if p.get("hair", "") == "long":
		ci.draw_circle(c + Vector2(0, s * 0.04), s * 0.44, p.get("hair_col", INK))
	ci.draw_circle(c, s * 0.38, skin)
	circle_outline(ci, c, s * 0.38, INK, 3)
	match p.get("hair", ""):
		"bun":
			ci.draw_circle(c + Vector2(0, -s * 0.42), s * 0.14, Color("d9d9d9"))
			circle_outline(ci, c + Vector2(0, -s * 0.42), s * 0.14, INK, 2)
			ci.draw_arc(c, s * 0.37, PI * 1.1, PI * 1.9, 16, Color("d9d9d9"), s * 0.12, true)
		"slick", "long":
			ci.draw_arc(c, s * 0.34, PI * 1.05, PI * 1.95, 16, p.get("hair_col", INK), s * 0.14, true)
		"bald":
			ci.draw_circle(c + Vector2(-s * 0.12, -s * 0.2), s * 0.05, Color(1, 1, 1, 0.5))
	# occhi
	if p.get("glasses", false):
		for dx in [-0.14, 0.14]:
			ci.draw_circle(c + Vector2(dx * s, -s * 0.04), s * 0.1, Color(1, 1, 1, 0.6))
			circle_outline(ci, c + Vector2(dx * s, -s * 0.04), s * 0.1, INK, 2.5)
		ci.draw_line(c + Vector2(-s * 0.04, -s * 0.04), c + Vector2(s * 0.04, -s * 0.04), INK, 2)
	if p.get("shades", false):
		ci.draw_rect(Rect2(c + Vector2(-s * 0.27, -s * 0.11), Vector2(s * 0.54, s * 0.13)), INK)
	else:
		for dx in [-0.14, 0.14]:
			ci.draw_circle(c + Vector2(dx * s, -s * 0.04), s * 0.035, INK)
	# bocca
	if p.get("mustache", false):
		ci.draw_arc(c + Vector2(-s * 0.08, s * 0.14), s * 0.09, PI * 1.1, PI * 2.0, 10, p.get("hair_col", INK), s * 0.07, true)
		ci.draw_arc(c + Vector2(s * 0.08, s * 0.14), s * 0.09, PI * 1.0, PI * 1.9, 10, p.get("hair_col", INK), s * 0.07, true)
	else:
		ci.draw_arc(c + Vector2(0, s * 0.1), s * 0.12, PI * 0.15, PI * 0.85, 10, INK, 2.5, true)
	ci.draw_circle(c + Vector2(-s * 0.24, s * 0.08), s * 0.05, Color(1, 0.4, 0.4, 0.35))
	ci.draw_circle(c + Vector2(s * 0.24, s * 0.08), s * 0.05, Color(1, 0.4, 0.4, 0.35))
	# cappelli
	match p.get("hat", ""):
		"veil":
			ci.draw_arc(c, s * 0.4, PI * 1.0, PI * 2.0, 20, INK, s * 0.14, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.3, -s * 0.34), Vector2(s * 0.6, s * 0.08)), PAPER)
		"jockey":
			ci.draw_arc(c + Vector2(0, -s * 0.06), s * 0.34, PI * 1.05, PI * 1.95, 16, p.get("hat_col", RED), s * 0.2, true)
			ci.draw_line(c + Vector2(s * 0.1, -s * 0.2), c + Vector2(s * 0.45, -s * 0.2), p.get("hat_col", RED), s * 0.06, true)
		"fedora":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.48, -s * 0.34), Vector2(s * 0.96, s * 0.07)), INK)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.6), Vector2(s * 0.52, s * 0.28)), INK)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.4), Vector2(s * 0.52, s * 0.06)), p.get("hat_col", RED))
		"captain":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.36, -s * 0.52), Vector2(s * 0.72, s * 0.2)), PAPER)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.34), Vector2(s * 0.8, s * 0.07)), INK)
			ci.draw_circle(c + Vector2(0, -s * 0.42), s * 0.06, GOLD)
		"beret":
			ci.draw_circle(c + Vector2(-s * 0.08, -s * 0.34), s * 0.24, p.get("hat_col", RED))
			circle_outline(ci, c + Vector2(-s * 0.08, -s * 0.34), s * 0.24, INK, 2)
		"helmet":
			circle_outline(ci, c, s * 0.48, Color(0.8, 0.9, 1, 0.9), s * 0.1)
			circle_outline(ci, c, s * 0.53, INK, 2.5)
		"tophat":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.34), Vector2(s * 0.8, s * 0.07)), INK)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.24, -s * 0.7), Vector2(s * 0.48, s * 0.38)), INK)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.24, -s * 0.42), Vector2(s * 0.48, s * 0.06)), GOLD)
		"cap":
			ci.draw_arc(c + Vector2(0, -s * 0.06), s * 0.34, PI * 1.05, PI * 1.95, 16, p.get("hat_col", BLUE), s * 0.2, true)
			ci.draw_line(c + Vector2(-s * 0.45, -s * 0.2), c + Vector2(-s * 0.1, -s * 0.2), p.get("hat_col", BLUE), s * 0.06, true)

## Gatto portafortuna dorato (maneki-neko).
func draw_cat(ci: CanvasItem, c: Vector2, s: float, wave: float) -> void:
	ci.draw_circle(c + Vector2(4, 6), s * 0.45, SHADOW)
	# corpo
	ci.draw_circle(c + Vector2(0, s * 0.18), s * 0.36, GOLD)
	circle_outline(ci, c + Vector2(0, s * 0.18), s * 0.36, INK, 3)
	# zampa che saluta
	var paw := c + Vector2(s * 0.34, -s * 0.12 + sin(wave) * s * 0.12)
	ci.draw_line(c + Vector2(s * 0.22, s * 0.1), paw, INK, s * 0.2, true)
	ci.draw_line(c + Vector2(s * 0.22, s * 0.1), paw, GOLD, s * 0.13, true)
	ci.draw_circle(paw, s * 0.1, GOLD)
	circle_outline(ci, paw, s * 0.1, INK, 2.5)
	# testa
	for sx in [-1, 1]:
		var ear := PackedVector2Array([c + Vector2(sx * s * 0.32, -s * 0.22), c + Vector2(sx * s * 0.28, -s * 0.52), c + Vector2(sx * s * 0.08, -s * 0.36)])
		ci.draw_colored_polygon(ear, GOLD)
		ear.append(ear[0])
		ci.draw_polyline(ear, INK, 2.5, true)
	ci.draw_circle(c + Vector2(0, -s * 0.18), s * 0.3, GOLD)
	circle_outline(ci, c + Vector2(0, -s * 0.18), s * 0.3, INK, 3)
	ci.draw_arc(c + Vector2(-s * 0.11, -s * 0.2), s * 0.06, PI, TAU, 8, INK, 2.5, true)
	ci.draw_arc(c + Vector2(s * 0.11, -s * 0.2), s * 0.06, PI, TAU, 8, INK, 2.5, true)
	ci.draw_circle(c + Vector2(0, -s * 0.1), s * 0.03, RED)
	# collare e moneta
	ci.draw_line(c + Vector2(-s * 0.22, s * 0.06), c + Vector2(s * 0.22, s * 0.06), RED, s * 0.07, true)
	ci.draw_circle(c + Vector2(0, s * 0.26), s * 0.13, Color("ffe27a"))
	circle_outline(ci, c + Vector2(0, s * 0.26), s * 0.13, INK, 2.5)
	text_in(ci, Rect2(c + Vector2(-s * 0.13, s * 0.13), Vector2(s * 0.26, s * 0.26)), "€", int(s * 0.18), GOLD_DARK, 1, f_title)
