extends Control
## Bottone di navigazione a forma di fiche da poker.

signal pressed

var label := ""
var color := S.RED
var icon := ""
var selected := false
var notify := false
var _hover := false
var _lift := 0.0
var _spin := 0.0

func setup(p_label: String, p_color: Color, p_icon: String) -> void:
	label = p_label
	color = p_color
	icon = p_icon
	custom_minimum_size = Vector2(104, 80)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)

func _on_enter() -> void:
	_hover = true
	Sfx.play("tick")

func _on_exit() -> void:
	_hover = false

func _gui_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		Sfx.play("pop")
		pressed.emit()

func _process(delta: float) -> void:
	var target := 8.0 if selected else (4.0 if _hover else 0.0)
	_lift = lerpf(_lift, target, delta * 14.0)
	if _hover or selected:
		_spin += delta * (1.2 if _hover else 0.3)
	queue_redraw()

func _draw() -> void:
	var c := Vector2(size.x * 0.5, 32 - _lift)
	var r := 29.0
	# pila di fiche sotto (effetto 3D)
	for k in 3:
		var off := Vector2(0, 8 - k * 3 + _lift)
		draw_circle(c + off + Vector2(0, 2), r, S.SHADOW if k == 0 else color.darkened(0.45))
	draw_circle(c + Vector2(0, 4), r, color.darkened(0.35))
	draw_arc(c + Vector2(0, 4), r, 0, PI, 20, S.INK, 3, true)
	draw_set_transform(c, sin(_spin) * 0.3)
	S.draw_chip(self, Vector2.ZERO, r, color, false)
	draw_set_transform(Vector2.ZERO)
	_draw_icon(c, r * 1.1)
	if selected:
		draw_arc(c, r + 5, 0, TAU, 32, S.GOLD, 3, true)
	var col := S.GOLD if selected else S.PAPER
	S.text(self, Vector2(size.x * 0.5, 76), label, 15, col, 1, S.f_title, 5, S.INK, size.x - 4)
	if notify:
		var bp := c + Vector2(r * 0.8, -r * 0.7)
		var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.008)
		draw_circle(bp + Vector2(1, 2), 9 * pulse, S.SHADOW)
		draw_circle(bp, 9 * pulse, S.RED)
		draw_arc(bp, 9 * pulse, 0, TAU, 16, S.INK, 2, true)
		S.text_in(self, Rect2(bp - Vector2(9, 9), Vector2(18, 18)), "!", 14, S.PAPER, 1, S.f_title)

func _draw_icon(c: Vector2, s: float) -> void:
	if icon.begins_with("sym:"):
		S.draw_symbol(self, icon.substr(4), c, s * 0.75)
	elif icon.begins_with("icon:"):
		S.draw_icon(self, icon.substr(5), c, s * 0.7)
	elif icon == "star":
		S.draw_star(self, c, s * 0.32, S.GOLD)
	elif icon == "face":
		S.draw_face(self, c + Vector2(0, 3), s * 0.55, {"hat": "fedora", "hat_col": S.PURPLE, "mustache": true})
	elif icon == "cup":
		var pts := PackedVector2Array([c + Vector2(-s * 0.22, -s * 0.22), c + Vector2(s * 0.22, -s * 0.22), c + Vector2(s * 0.14, s * 0.05), c + Vector2(-s * 0.14, s * 0.05)])
		draw_colored_polygon(pts, S.GOLD)
		pts.append(pts[0])
		draw_polyline(pts, S.INK, 2.5, true)
		draw_rect(Rect2(c + Vector2(-s * 0.04, s * 0.05), Vector2(s * 0.08, s * 0.12)), S.GOLD_DARK)
		draw_rect(Rect2(c + Vector2(-s * 0.14, s * 0.16), Vector2(s * 0.28, s * 0.07)), S.INK)
	elif icon == "run":
		S.draw_shark(self, c, s * 0.62)
