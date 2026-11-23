extends Control
## Gatto portafortuna dorato che attraversa il tavolo a sorpresa.
## Intercetta il click in _input() così si può sempre cliccare anche sopra bottoni/carte!

var fx: Control
var _wait := 18.0
var _active := false
var _pos := Vector2.ZERO
var _dir := 1.0
var _t := 0.0
var _dur := 11.0
var _hover := false

func setup(p_fx: Control) -> void:
	fx = p_fx
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func spawn() -> void:
	_active = true
	_t = 0.0
	_dur = G.cat_duration()
	_dir = 1.0 if randf() < 0.5 else -1.0
	var w := size.x if size.x > 100 else 1280.0
	var h := size.y if size.y > 100 else 720.0
	_pos = Vector2(-50 if _dir > 0 else w + 50, randf_range(220, h - 110))
	Sfx.play("cat")

func _process(delta: float) -> void:
	if not _active:
		if not G.deadline_paused and G.intro_seen:
			_wait -= delta
			if _wait <= 0:
				_wait = G.cat_interval()
				spawn()
		return
	_t += delta
	var w := size.x if size.x > 100 else 1280.0
	var spd := (w + 100.0) / _dur
	_pos.x += _dir * spd * delta
	_pos.y += sin(_t * 5.0) * 35.0 * delta
	_hover = get_local_mouse_position().distance_to(_pos) < 68.0
	if _t >= _dur:
		_active = false
		_hover = false
	queue_redraw()

func _input(e: InputEvent) -> void:
	if not _active:
		return
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var local_p := get_local_mouse_position()
		if local_p.distance_to(_pos) < 72.0:
			_active = false
			_hover = false
			G.claim_cat()
			if fx:
				fx.confetti(_pos, 70)
				fx.coins(_pos, 16)
			get_viewport().set_input_as_handled()
			queue_redraw()

func _draw() -> void:
	if not _active:
		return
	var sc := 1.15 if _hover else 1.0
	draw_circle(_pos, 54 * sc, Color(S.GOLD, 0.25 + 0.15 * sin(_t * 8.0)))
	for i in 8:
		var a := _t * 3.5 + TAU * i / 8.0
		draw_circle(_pos + Vector2.from_angle(a) * 50 * sc, 4.5, Color(S.GOLD, 0.85))
	S.draw_cat(self, _pos, 82 * sc, _t * 10.0)
	S.text(self, _pos + Vector2(0, 58), "CLICCAMI! (+BONUS)", 16, S.GOLD, 1, S.f_title, 5, S.INK)
