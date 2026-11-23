extends Control
## Modale a forma di lettera intimidatoria dello Squalo (intro, città saldata, guadagni offline).

var _queue: Array = []
var _title := ""
var _body := ""
var _btn_txt := ""
var btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	btn = S.make_button("HO CAPITO", S.RED, 22, S.PAPER)
	add_child(btn)
	btn.pressed.connect(_next)
	resized.connect(_layout)

func _eff_size() -> Vector2:
	if size.x > 100 and size.y > 100:
		return size
	var vp := get_viewport_rect().size
	return vp if vp.x > 100 else Vector2(1280, 720)

func show_modal(title: String, body: String, button := "OK") -> void:
	_queue.append([title, body, button])
	if not visible:
		_next()

func _next() -> void:
	if _queue.is_empty():
		visible = false
		return
	var it: Array = _queue.pop_front()
	_title = it[0]
	_body = it[1]
	_btn_txt = it[2]
	btn.text = _btn_txt
	visible = true
	_layout()
	queue_redraw()

func _layout() -> void:
	var c := _eff_size() * 0.5
	if btn:
		btn.position = c + Vector2(-140, 140)
		btn.size = Vector2(280, 56)

func _process(_d: float) -> void:
	if visible:
		_layout()
		queue_redraw()

func _draw() -> void:
	var sz := _eff_size()
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0, 0, 0, 0.76))
	var c := sz * 0.5
	var r := Rect2(c - Vector2(320, 225), Vector2(640, 450))
	draw_set_transform(c, -0.012)
	S.draw_card(self, Rect2(-320, -225, 640, 450), S.PAPER, 18, Vector2(10, 14), 4)
	draw_set_transform(Vector2.ZERO)
	S.draw_shark(self, Vector2(r.position.x + 68, r.position.y + 62), 78)
	S.text(self, Vector2(r.position.x + 124, r.position.y + 72), _title, 34, S.RED, 0, S.f_title, 4, S.INK, r.size.x - 145)
	draw_line(r.position + Vector2(30, 108), Vector2(r.end.x - 30, r.position.y + 108), Color(S.INK, 0.25), 2)
	var y := r.position.y + 138
	for para in _body.split("\n"):
		if para == "":
			y += 12
			continue
		for line in _wrap(para, r.size.x - 68, 17):
			S.text(self, Vector2(r.position.x + 34, y), line, 17, S.INK, 0, S.f_body)
			y += 23

func _wrap(s: String, max_w: float, sz: int) -> Array:
	var out := []
	var cur := ""
	for w in s.split(" "):
		var test := w if cur == "" else cur + " " + w
		if S.f_body.get_string_size(test, 0, -1, sz).x > max_w and cur != "":
			out.append(cur)
			cur = w
		else:
			cur = test
	if cur != "":
		out.append(cur)
	return out
