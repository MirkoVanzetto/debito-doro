extends Control
## Pannello "Manager": assumi i personaggi che automatizzano le attività.

class ManagerRow extends Control:
	var i := 0
	var btn: Button
	func setup(idx: int) -> void:
		i = idx
		custom_minimum_size = Vector2(400, 96)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn = S.make_button("ASSUMI", S.GOLD, 18)
		add_child(btn)
		btn.pressed.connect(func(): G.hire_manager(i))
		resized.connect(_layout)
	func _layout() -> void:
		btn.position = Vector2(size.x - 178, 18)
		btn.size = Vector2(160, size.y - 42)
	func _process(_d: float) -> void:
		var hired: bool = G.managers[i]
		var c := G.manager_cost(i)
		btn.visible = not hired
		if not hired:
			btn.text = "ASSUMI\n" + G.fmt(c)
			btn.disabled = G.money < c or G.owned[i] <= 0
		queue_redraw()
	func _draw() -> void:
		var m: Dictionary = G.MANAGERS[i]
		var b: Dictionary = G.BUSINESSES[i]
		var r := Rect2(Vector2(4, 2), size - Vector2(14, 12))
		S.draw_card(self, r, S.PAPER, 14, Vector2(6, 7))
		var fc := Vector2(54, r.get_center().y)
		draw_circle(fc, 34, b["color"].lerp(S.PAPER, 0.5))
		S.circle_outline(self, fc, 34, S.INK, 2.5)
		S.draw_face(self, fc + Vector2(0, 4), 56, m["face"])
		S.text(self, Vector2(106, 32), m["name"], 24, S.INK, 0, S.f_title)
		S.text(self, Vector2(106, 54), "Automatizza: " + b["name"], 15, S.RED_DARK, 0, S.f_num)
		S.text(self, Vector2(106, 74), "\"" + m["line"] + "\"", 14, Color(S.INK, 0.7), 0, S.f_body)
		if G.managers[i]:
			draw_set_transform(Vector2(size.x - 102, r.get_center().y), -0.15)
			var sr := Rect2(-64, -20, 128, 40)
			draw_rect(sr, S.GREEN, false, 4)
			S.text_in(self, sr, "ASSUNTO", 22, S.GREEN.darkened(0.25), 1, S.f_title)
			draw_set_transform(Vector2.ZERO)
		elif G.owned[i] <= 0:
			S.text(self, Vector2(size.x - 188, r.get_center().y + 6), "(Sblocca prima l'attività)", 13, S.RED, 2, S.f_body)

func _ready() -> void:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(vb)
	for i in G.BUSINESSES.size():
		var row := ManagerRow.new()
		vb.add_child(row)
		row.setup(i)
	resized.connect(_on_resize)
	_sc = sc

var _sc: ScrollContainer
func _on_resize() -> void:
	_sc.position = Vector2(24, 48)
	_sc.size = size - Vector2(48, 56)

func _draw() -> void:
	S.text(self, Vector2(28, 34), "UFFICIO COLLOCAMENTO — Assumi gente fidata (più o meno) per far girare tutto da solo", 18, S.GOLD, 0, S.f_title, 5, S.INK)
