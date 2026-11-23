extends Control
## Gatto portafortuna dorato che attraversa il tavolo a sorpresa.

var fx: Control
var _wait := 35.0
var _active := false
var _pos := Vector2.ZERO
var _dir := 1.0
var _t := 0.0
var _dur := 10.0

func setup(p_fx: Control) -> void:
	fx = p_fx
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func spawn() -> void:
	_active = true
	_t = 0.0
	_dur = G.cat_duration()
	_dir = 1.0 if randf() < 0.5 else -1.0
	_pos = Vector2(-60 if _dir > 0 else size.x + 60, randf_range(210, size.y - 100))
	mouse_filter = Control.MOUSE_FILTER_PASS
	Sfx.play("cat")

func _process(delta: float) -> void:
	if not _active:
		_wait -= delta
		if _wait <= 0:
			_wait = G.cat_interval()
			spawn()
		return
	_t += delta
	var spd := (size.x + 120) / _dur
	_pos.x += _dir * spd * delta
	_pos.y += sin(_t * 5.0) * 35.0 * delta
	if _t >= _dur:
		_active = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if not _active:
		return
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.position.distance_to(_pos) < 56:
			_active = false
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			G.claim_cat()
			if fx:
				fx.confetti(_pos, 60)
				fx.coins(_pos, 14)
			accept_event()
			queue_redraw()

func _draw() -> void:
	if not _active:
		return
	for i in 8:
		var a := _t * 3.0 + TAU * i / 8.0
		draw_circle(_pos + Vector2.from_angle(a) * 48, 4, Color(S.GOLD, 0.7))
	S.draw_cat(self, _pos, 78, _t * 10.0)
	S.text(self, _pos + Vector2(0, 56), "CLICCAMI!", 16, S.GOLD, 1, S.f_title, 5, S.INK)
