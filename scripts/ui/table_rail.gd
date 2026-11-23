extends Control
## Bordo imbottito del tavolo (cuoio + legno + filetto dorato), disegnato sopra a tutto.

const RAIL := 16.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var w := RAIL
	# legno esterno
	var wood := Color("3a1d0f")
	draw_rect(Rect2(0, 0, size.x, w), wood)
	draw_rect(Rect2(0, size.y - w, size.x, w), wood)
	draw_rect(Rect2(0, 0, w, size.y), wood)
	draw_rect(Rect2(size.x - w, 0, w, size.y), wood)
	# venature
	for i in 6:
		var y := 3.0 + i * 2.2
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 0.7, 0.4, 0.05), 1)
		draw_line(Vector2(0, size.y - y), Vector2(size.x, size.y - y), Color(1, 0.7, 0.4, 0.05), 1)
	# filetto dorato + ombra interna
	var inner := r.grow(-w)
	draw_rect(inner, S.GOLD_DARK, false, 3.0)
	draw_rect(inner.grow(-3), Color(0, 0, 0, 0.35), false, 4.0)
	draw_rect(inner.grow(-7), Color(0, 0, 0, 0.15), false, 6.0)
	# borchie agli angoli
	for c in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
		draw_circle(c, 6, S.GOLD)
		draw_arc(c, 6, 0, TAU, 12, S.INK, 2, true)
